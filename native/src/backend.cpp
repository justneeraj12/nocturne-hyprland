#include "backend.h"
#include "traywatcher.h"

#include <QCoreApplication>
#include <QDir>
#include <QDirIterator>
#include <QDateTime>
#include <QDBusArgument>
#include <QDBusInterface>
#include <QDBusReply>
#include <QDBusVariant>
#include <QFile>
#include <QFileInfo>
#include <QFileSystemWatcher>
#include <QGuiApplication>
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <QJSEngine>
#include <QProcess>
#include <QLocalSocket>
#include <QTimer>
#include <QRegularExpression>
#include <QSet>
#include <QSettings>
#include <algorithm>
#include <cmath>
#include <utility>
#include <signal.h>
#include <unistd.h>

Backend::Backend(QString surface, QString page, QObject *parent)
    : QObject(parent)
    , m_surface(std::move(surface))
    , m_page(std::move(page))
{
    updateTargetScreen();
    connect(qGuiApp, &QGuiApplication::screenAdded, this, [this](QScreen *) {
        emit screensChanged();
    });
    connect(qGuiApp, &QGuiApplication::screenRemoved, this, [this](QScreen *) {
        emit screensChanged();
    });
    if (m_surface == QStringLiteral("bar")) {
        m_eventTimer = new QTimer(this);
        m_eventTimer->setSingleShot(true);
        connect(m_eventTimer, &QTimer::timeout, this, &Backend::flushShellEvents);
        m_trayWatcher = std::make_unique<TrayWatcher>(this);
        connect(m_trayWatcher.get(), &TrayWatcher::registeredItemsChanged, this,
            [this]() { queueShellEvent(QStringLiteral("tray")); });
        startShellEvents();
    }

    // The persistent bar never searches or launches desktop files. Building
    // this catalogue there retained every QSettings object and icon string for
    // no benefit; only the on-demand launcher needs it.
    if (m_surface == QStringLiteral("launcher")) {
        const QStringList roots = {
            home() + QStringLiteral("/.local/share/applications"),
            home() + QStringLiteral("/.local/share/flatpak/exports/share/applications"),
            QStringLiteral("/var/lib/flatpak/exports/share/applications"),
            QStringLiteral("/var/lib/snapd/desktop/applications"),
            QStringLiteral("/usr/local/share/applications"),
            QStringLiteral("/usr/share/applications")
        };
        QSet<QString> seen;
        for (const auto &root : roots) {
            QDir directory(root);
            for (const auto &fileName : directory.entryList({QStringLiteral("*.desktop")}, QDir::Files, QDir::Name)) {
                if (seen.contains(fileName)) continue;
                seen.insert(fileName);
                const auto path = directory.filePath(fileName);
                QSettings desktop(path, QSettings::IniFormat);
                desktop.beginGroup(QStringLiteral("Desktop Entry"));
                auto desktops = [](const QVariant &value) {
                    auto text = value.toString();
                    text.replace(QLatin1Char(';'), QLatin1Char(':'));
                    return text.split(QLatin1Char(':'), Qt::SkipEmptyParts);
                };
                const auto currentDesktops = qEnvironmentVariable("XDG_CURRENT_DESKTOP", QStringLiteral("Hyprland"))
                                                 .split(QLatin1Char(':'), Qt::SkipEmptyParts);
                const auto onlyShowIn = desktops(desktop.value(QStringLiteral("OnlyShowIn")));
                const auto notShowIn = desktops(desktop.value(QStringLiteral("NotShowIn")));
                const bool allowedDesktop = onlyShowIn.isEmpty() || std::any_of(onlyShowIn.cbegin(), onlyShowIn.cend(), [&](const QString &name) {
                    return currentDesktops.contains(name, Qt::CaseInsensitive);
                });
                const bool blockedDesktop = std::any_of(notShowIn.cbegin(), notShowIn.cend(), [&](const QString &name) {
                    return currentDesktops.contains(name, Qt::CaseInsensitive);
                });
                if (desktop.value(QStringLiteral("Type")).toString() != QStringLiteral("Application")
                    || desktop.value(QStringLiteral("Hidden"), false).toBool()
                    || desktop.value(QStringLiteral("NoDisplay"), false).toBool()
                    || !allowedDesktop || blockedDesktop) {
                    continue;
                }
                const auto name = desktop.value(QStringLiteral("Name")).toString().trimmed();
                const auto command = desktop.value(QStringLiteral("Exec")).toString().trimmed();
                if (name.isEmpty() || command.isEmpty()) continue;
                m_applications.push_back(QVariantMap{
                    {QStringLiteral("name"), name},
                    {QStringLiteral("generic"), desktop.value(QStringLiteral("GenericName")).toString()},
                    {QStringLiteral("icon"), desktop.value(QStringLiteral("Icon")).toString()},
                    {QStringLiteral("path"), path},
                    {QStringLiteral("search"), (name + QLatin1Char(' ') + desktop.value(QStringLiteral("GenericName")).toString()
                        + QLatin1Char(' ') + desktop.value(QStringLiteral("Keywords")).toString()).toLower()}
                });
            }
        }
        std::sort(m_applications.begin(), m_applications.end(), [](const QVariant &left, const QVariant &right) {
            return left.toMap().value(QStringLiteral("name")).toString().localeAwareCompare(
                       right.toMap().value(QStringLiteral("name")).toString()) < 0;
        });
    }
}

Backend::~Backend()
{
    m_shuttingDown = true;
    if (m_audioEvents) {
        m_audioEvents->disconnect(this);
        m_audioEvents->terminate();
        m_audioEvents->waitForFinished(250);
    }
}

void Backend::startShellEvents()
{
    auto session = QDBusConnection::sessionBus();
    session.connect(QString(), QString(), QStringLiteral("org.freedesktop.DBus.Properties"),
        QStringLiteral("PropertiesChanged"), this,
        SLOT(onPropertiesChanged(QString,QVariantMap,QStringList)));
    auto system = QDBusConnection::systemBus();
    system.connect(QString(), QString(), QStringLiteral("org.freedesktop.DBus.Properties"),
        QStringLiteral("PropertiesChanged"), this,
        SLOT(onPropertiesChanged(QString,QVariantMap,QStringList)));

    m_hyprEvents = std::make_unique<QLocalSocket>(this);
    connect(m_hyprEvents.get(), &QLocalSocket::readyRead, this, &Backend::readHyprEvents);
    connect(m_hyprEvents.get(), &QLocalSocket::disconnected, this, [this]() {
        if (!m_shuttingDown) QTimer::singleShot(900, this, &Backend::reconnectHyprEvents);
    });
    QTimer::singleShot(0, this, &Backend::reconnectHyprEvents);

    m_audioEvents = std::make_unique<QProcess>(this);
    connect(m_audioEvents.get(), &QProcess::readyReadStandardOutput, this, [this]() {
        m_audioBuffer += m_audioEvents->readAllStandardOutput();
        bool relevant = false;
        qsizetype newline = -1;
        while ((newline = m_audioBuffer.indexOf('\n')) >= 0) {
            const auto event = m_audioBuffer.left(newline);
            m_audioBuffer.remove(0, newline + 1);
            // Ignore client lifecycle noise. The status commands used by the
            // bar are PulseAudio clients themselves; reacting to those events
            // created a self-sustaining refresh loop under PipeWire.
            relevant = relevant || event.contains(" on sink #") || event.contains(" on source #")
                || event.contains(" on sink-input #") || event.contains(" on source-output #")
                || event.contains(" on card #") || event.contains(" on server #");
        }
        if (relevant) queueShellEvent(QStringLiteral("audio"));
    });
    connect(m_audioEvents.get(), &QProcess::finished, this, [this]() {
        if (!m_shuttingDown) QTimer::singleShot(1200, this, &Backend::startAudioEvents);
    });
    startAudioEvents();

    m_fileEvents = std::make_unique<QFileSystemWatcher>(this);
    const QDir backlights(QStringLiteral("/sys/class/backlight"));
    for (const auto &device : backlights.entryList(QDir::Dirs | QDir::NoDotAndDotDot)) {
        const auto path = backlights.filePath(device + QStringLiteral("/brightness"));
        if (QFileInfo::exists(path)) m_fileEvents->addPath(path);
    }
    connect(m_fileEvents.get(), &QFileSystemWatcher::fileChanged, this, [this](const QString &path) {
        queueShellEvent(QStringLiteral("brightness"));
        if (QFileInfo::exists(path) && !m_fileEvents->files().contains(path)) m_fileEvents->addPath(path);
    });
}

void Backend::onPropertiesChanged(const QString &interface, const QVariantMap &, const QStringList &)
{
    if (interface.startsWith(QStringLiteral("org.mpris.MediaPlayer2")))
        queueShellEvent(QStringLiteral("media"));
    else if (interface.startsWith(QStringLiteral("org.freedesktop.NetworkManager")))
        queueShellEvent(QStringLiteral("connectivity"));
    else if (interface.startsWith(QStringLiteral("org.bluez")))
        queueShellEvent(QStringLiteral("connectivity"));
    else if (interface.startsWith(QStringLiteral("org.freedesktop.UPower")))
        queueShellEvent(QStringLiteral("power"));
}

void Backend::reconnectHyprEvents()
{
    if (m_shuttingDown || !m_hyprEvents || m_hyprEvents->state() != QLocalSocket::UnconnectedState) return;
    const auto signature = qEnvironmentVariable("HYPRLAND_INSTANCE_SIGNATURE");
    if (signature.isEmpty()) return;
    m_hyprEvents->connectToServer(runtime() + QStringLiteral("/hypr/") + signature
        + QStringLiteral("/.socket2.sock"), QIODevice::ReadOnly);
}

void Backend::readHyprEvents()
{
    m_hyprBuffer += m_hyprEvents->readAll();
    qsizetype newline = -1;
    while ((newline = m_hyprBuffer.indexOf('\n')) >= 0) {
        const auto event = QString::fromUtf8(m_hyprBuffer.left(newline));
        m_hyprBuffer.remove(0, newline + 1);
        if (event.startsWith(QStringLiteral("workspace")) || event.startsWith(QStringLiteral("focusedmon"))
            || event.startsWith(QStringLiteral("monitor"))) queueShellEvent(QStringLiteral("workspace"), 70);
        if (event.startsWith(QStringLiteral("openwindow")) || event.startsWith(QStringLiteral("closewindow"))
            || event.startsWith(QStringLiteral("movewindow")) || event.startsWith(QStringLiteral("activewindow")))
            queueShellEvent(QStringLiteral("windows"), 70);
    }
}

void Backend::queueShellEvent(const QString &topic, int delayMs)
{
    if (!m_eventTimer) {
        emit shellEvent(topic);
        return;
    }
    m_pendingShellEvents.insert(topic);
    if (!m_eventTimer->isActive()) m_eventTimer->start(delayMs);
}

void Backend::flushShellEvents()
{
    const auto topics = std::exchange(m_pendingShellEvents, {});
    for (const auto &topic : topics) emit shellEvent(topic);
}

void Backend::startAudioEvents()
{
    if (m_shuttingDown || !m_audioEvents || m_audioEvents->state() != QProcess::NotRunning) return;
    m_audioEvents->start(QStringLiteral("pactl"), {QStringLiteral("subscribe")}, QIODevice::ReadOnly);
}

QString Backend::surface() const { return m_surface; }
QString Backend::page() const { return m_page; }
QString Backend::home() const { return QDir::homePath(); }
QString Backend::runtime() const
{
    const auto configured = qEnvironmentVariable("XDG_RUNTIME_DIR");
    return configured.isEmpty() ? QStringLiteral("/run/user/%1").arg(getuid()) : configured;
}
QScreen *Backend::targetScreen() const { return m_targetScreen; }
QVariantList Backend::screens() const
{
    QVariantList result;
    for (auto *screen : QGuiApplication::screens()) result.push_back(QVariant::fromValue(screen));
    return result;
}
QString Backend::baseColor() const { return paletteValue("base", "#07090a"); }
QString Backend::surfaceColor() const { return paletteValue("surface", "#0b0f10"); }
QString Backend::overlayColor() const { return paletteValue("overlay", "#111719"); }
QString Backend::lineColor() const { return paletteValue("line", "#1b2925"); }
QString Backend::textColor() const { return paletteValue("text", "#a7b8b1"); }
QString Backend::mutedColor() const { return paletteValue("muted", "#4d5d58"); }
QString Backend::accentColor() const { return paletteValue("accent", "#5f8f76"); }
QString Backend::accent2Color() const { return paletteValue("accent2", "#477463"); }

QString Backend::paletteValue(const QString &name, const QString &fallback) const
{
    for (const auto &fileName : {QStringLiteral("accent.css"), QStringLiteral("palette.css")}) {
        const auto contents = readText(home() + QStringLiteral("/.config/nocturne/") + fileName);
        const QRegularExpression expression(
            QStringLiteral("^@define-color\\s+(?:nocturne_)?%1\\s+(#[0-9a-fA-F]{6});").arg(name),
            QRegularExpression::MultilineOption);
        const auto match = expression.match(contents);
        if (match.hasMatch()) {
            return match.captured(1);
        }
    }
    return fallback;
}

QStringList Backend::stringList(const QVariantList &arguments)
{
    QStringList result;
    result.reserve(arguments.size());
    for (const auto &argument : arguments) {
        result.push_back(argument.toString());
    }
    return result;
}

QString Backend::run(const QVariantList &arguments, int timeoutMs) const
{
    const auto values = stringList(arguments);
    if (values.isEmpty()) {
        return {};
    }
    QProcess process;
    process.start(values.first(), values.mid(1));
    if (!process.waitForStarted(1000) || !process.waitForFinished(timeoutMs)) {
        process.kill();
        return {};
    }
    return QString::fromUtf8(process.readAllStandardOutput()).trimmed();
}

QVariant Backend::json(const QVariantList &arguments, int timeoutMs) const
{
    QJsonParseError error;
    const auto document = QJsonDocument::fromJson(run(arguments, timeoutMs).toUtf8(), &error);
    if (error.error != QJsonParseError::NoError) {
        return {};
    }
    return document.toVariant();
}

QVariantList Backend::audioStreams() const
{
    const auto graph = json({"pw-dump"}, 5000).toList();
    QVariantList streams;
    for (const auto &entry : graph) {
        const auto object = entry.toMap();
        if (object.value("type").toString() != QStringLiteral("PipeWire:Interface:Node")) {
            continue;
        }
        const auto info = object.value("info").toMap();
        const auto properties = info.value("props").toMap();
        if (properties.value("media.class").toString() != QStringLiteral("Stream/Output/Audio")) {
            continue;
        }
        bool validId = false;
        const int id = object.value("id").toInt(&validId);
        if (!validId || id < 0) {
            continue;
        }
        QString name = properties.value("application.name").toString();
        if (name.isEmpty()) name = properties.value("node.description").toString();
        if (name.isEmpty()) name = properties.value("media.name").toString();
        if (name.isEmpty()) name = properties.value("node.name").toString();

        const auto volumeText = run({"wpctl", "get-volume", QString::number(id)}, 1200);
        const auto match = QRegularExpression(QStringLiteral("Volume:\\s*([0-9.]+)")).match(volumeText);
        QVariantMap stream;
        stream.insert("id", id);
        stream.insert("name", name.isEmpty() ? QStringLiteral("Audio stream") : name);
        stream.insert("volume", match.hasMatch() ? qRound(match.captured(1).toDouble() * 100.0) : 100);
        stream.insert("muted", volumeText.contains(QStringLiteral("[MUTED]")));
        streams.push_back(stream);
    }
    return streams;
}

bool Backend::microphoneInUse() const
{
    const auto document = QJsonDocument::fromJson(
        run({"pactl", "-f", "json", "list", "source-outputs"}, 1500).toUtf8());
    if (!document.isArray()) return false;

    for (const auto &value : document.array()) {
        const auto stream = value.toObject();
        if (stream.value(QStringLiteral("corked")).toBool()) continue;

        const auto properties = stream.value(QStringLiteral("properties")).toObject();
        // Visualizers such as Cava capture a speaker sink monitor and therefore
        // appear as source outputs even though the microphone is untouched.
        if (properties.value(QStringLiteral("stream.capture.sink")).toString() == QStringLiteral("true")) {
            continue;
        }

        const auto binary = properties.value(QStringLiteral("application.process.binary")).toString().toLower();
        const auto application = properties.value(QStringLiteral("application.name")).toString().toLower();
        if (binary.contains(QStringLiteral("cava")) || binary.contains(QStringLiteral("easyeffects"))
            || application.contains(QStringLiteral("cava")) || application.contains(QStringLiteral("easyeffects"))) {
            continue;
        }
        return true;
    }
    return false;
}

QVariantList Backend::windowItems() const
{
    QVariantList result;
    const auto clients = json({"hyprctl", "clients", "-j"}, 1400).toList();
    for (const auto &value : clients) {
        const auto client = value.toMap();
        if (!client.value("mapped").toBool()) continue;
        const auto windowClass = client.value("class").toString();
        if (windowClass.compare(QStringLiteral("nocturne-native"), Qt::CaseInsensitive) == 0) continue;
        result.push_back(QVariantMap{
            {"address", client.value("address")}, {"title", client.value("title")},
            {"class", windowClass}, {"workspace", client.value("workspace").toMap().value("id")},
            {"monitor", client.value("monitor")}, {"floating", client.value("floating")},
            {"fullscreen", client.value("fullscreen")}
        });
    }
    return result;
}

bool Backend::windowAction(const QString &address, const QString &action, int workspace) const
{
    if (!QRegularExpression(QStringLiteral("^0x[0-9a-fA-F]+$")).match(address).hasMatch()) return false;
    QString dispatcher;
    if (action == QStringLiteral("focus")) dispatcher = QStringLiteral("hl.dsp.focus({ window = \"address:%1\" })").arg(address);
    else if (action == QStringLiteral("close")) dispatcher = QStringLiteral("hl.dsp.window.close({ window = \"address:%1\" })").arg(address);
    else if (action == QStringLiteral("move") && workspace >= 1 && workspace <= 99)
        dispatcher = QStringLiteral("hl.dsp.window.move({ window = \"address:%1\", workspace = %2, silent = true })").arg(address).arg(workspace);
    else return false;
    return QProcess::execute(QStringLiteral("hyprctl"), {QStringLiteral("dispatch"), dispatcher}) == 0;
}

QVariantList Backend::privacyItems() const
{
    QVariantList result;
    const auto outputs = json({"pactl", "-f", "json", "list", "source-outputs"}, 1500).toList();
    for (const auto &value : outputs) {
        const auto stream = value.toMap();
        if (stream.value("corked").toBool()) continue;
        const auto properties = stream.value("properties").toMap();
        if (properties.value("stream.capture.sink").toString() == QStringLiteral("true")) continue;
        const auto binary = properties.value("application.process.binary").toString();
        if (binary.contains(QStringLiteral("cava"), Qt::CaseInsensitive)
            || binary.contains(QStringLiteral("easyeffects"), Qt::CaseInsensitive)) continue;
        result.push_back(QVariantMap{{"kind", "microphone"},
            {"app", properties.value("application.name").toString()},
            {"pid", properties.value("application.process.id").toInt()}, {"active", true}});
    }
    const auto nodes = json({"pw-dump"}, 2200).toList();
    for (const auto &value : nodes) {
        const auto object = value.toMap();
        const auto props = object.value("info").toMap().value("props").toMap();
        const auto mediaClass = props.value("media.class").toString();
        if (mediaClass != QStringLiteral("Stream/Input/Video") && mediaClass != QStringLiteral("Stream/Output/Video")) continue;
        result.push_back(QVariantMap{{"kind", "camera"},
            {"app", props.value("application.name").toString()},
            {"pid", props.value("application.process.id").toInt()}, {"active", true}});
    }
    return result;
}

bool Backend::stopPrivacyClient(int pid) const
{
    if (pid <= 1) return false;
    return ::kill(pid, SIGTERM) == 0;
}

QVariantList Backend::applications(const QString &query) const
{
    const auto needle = query.simplified().toLower();
    if (needle.isEmpty()) {
        return m_applications.mid(0, 80);
    }
    struct Match { int score; QVariant value; };
    QList<Match> matches;
    for (const auto &application : m_applications) {
        const auto object = application.toMap();
        const auto name = object.value(QStringLiteral("name")).toString().toLower();
        const auto search = object.value(QStringLiteral("search")).toString();
        int score = -1;
        if (name == needle) score = 1000;
        else if (name.startsWith(needle)) score = 800 - name.size();
        else if (name.contains(needle)) score = 600 - name.indexOf(needle);
        else if (search.contains(needle)) score = 400 - search.indexOf(needle);
        else {
            int position = 0;
            for (const auto character : needle) {
                position = search.indexOf(character, position);
                if (position < 0) break;
                ++position;
            }
            if (position >= 0) score = 100 - position;
        }
        if (score >= 0) matches.push_back({score, application});
    }
    std::sort(matches.begin(), matches.end(), [](const Match &left, const Match &right) {
        if (left.score != right.score) return left.score > right.score;
        return left.value.toMap().value(QStringLiteral("name")).toString().localeAwareCompare(
                   right.value.toMap().value(QStringLiteral("name")).toString()) < 0;
    });
    QVariantList result;
    for (const auto &match : matches) {
        result.push_back(match.value);
        if (result.size() == 80) break;
    }
    return result;
}

QVariantList Backend::launcherResults(const QString &query, const QString &requestedMode) const
{
    auto mode = requestedMode.toLower();
    auto needle = query.simplified();
    if (needle.startsWith(QLatin1Char('='))) {
        auto expression = needle.mid(1).trimmed();
        if (expression.isEmpty() || expression.size() > 100
            || !QRegularExpression(QStringLiteral("^[0-9+\\-*/%().\\s^]+$")).match(expression).hasMatch()) return {};
        expression.replace(QLatin1Char('^'), QStringLiteral("**"));
        QJSEngine calculator;
        const auto value = calculator.evaluate(expression);
        if (value.isError() || !value.isNumber() || !std::isfinite(value.toNumber())) return {};
        const auto answer = QString::number(value.toNumber(), 'g', 14);
        return {QVariantMap{{"kind", "calculation"}, {"name", answer}, {"generic", expression}, {"icon", "accessories-calculator-symbolic"}}};
    } else if (needle.startsWith(QLatin1Char('~'))) {
        const auto wanted = needle.mid(1).trimmed();
        QVariantList files;
        int visited = 0;
        for (const auto &root : {home() + QStringLiteral("/Documents"), home() + QStringLiteral("/Downloads"), home() + QStringLiteral("/Pictures")}) {
            QDirIterator iterator(root, QDir::Files, QDirIterator::Subdirectories);
            while (iterator.hasNext() && files.size() < 60 && visited < 4000) {
                ++visited;
                const QFileInfo info(iterator.next());
                if (!wanted.isEmpty() && !info.fileName().contains(wanted, Qt::CaseInsensitive)) continue;
                files.push_back(QVariantMap{{"kind", "file"}, {"name", info.fileName()}, {"generic", info.absolutePath()},
                    {"path", info.absoluteFilePath()}, {"icon", "text-x-generic-symbolic"}});
            }
            if (visited >= 4000) break;
        }
        return files;
    } else if (needle.startsWith(QLatin1Char('@'))) {
        mode = QStringLiteral("windows");
        needle = needle.mid(1).trimmed();
    } else if (needle.startsWith(QLatin1Char('>'))) {
        mode = QStringLiteral("actions");
        needle = needle.mid(1).trimmed();
    }
    if (mode != QStringLiteral("apps") && mode != QStringLiteral("windows")
        && mode != QStringLiteral("actions")) mode = QStringLiteral("all");

    QVariantList result;
    auto matches = [&needle](const QString &text) {
        if (needle.isEmpty()) return true;
        const auto haystack = text.toLower();
        const auto wanted = needle.toLower();
        if (haystack.contains(wanted)) return true;
        int position = 0;
        for (const auto character : wanted) {
            position = haystack.indexOf(character, position);
            if (position < 0) return false;
            ++position;
        }
        return true;
    };

    if (mode == QStringLiteral("all") || mode == QStringLiteral("actions")) {
        const QVariantList actions = {
            QVariantMap{{"kind", "action"}, {"id", "settings"}, {"name", "Open Nocturne Settings"},
                {"generic", "Appearance, displays and system controls"}, {"icon", "preferences-system-symbolic"}},
            QVariantMap{{"kind", "action"}, {"id", "notifications"}, {"name", "Open Notifications"},
                {"generic", "Alerts, history and focus mode"}, {"icon", "preferences-system-notifications-symbolic"}},
            QVariantMap{{"kind", "action"}, {"id", "clipboard"}, {"name", "Open Clipboard History"},
                {"generic", "Search recently copied items"}, {"icon", "edit-paste-symbolic"}},
            QVariantMap{{"kind", "action"}, {"id", "connectivity"}, {"name", "Open Connectivity"},
                {"generic", "Wi-Fi, Bluetooth and VPN"}, {"icon", "network-wireless-symbolic"}},
            QVariantMap{{"kind", "action"}, {"id", "power"}, {"name", "Open Power Controls"},
                {"generic", "Battery, profiles and session"}, {"icon", "battery-symbolic"}},
            QVariantMap{{"kind", "action"}, {"id", "wallpaper"}, {"name", "Choose Wallpaper"},
                {"generic", "Static and day-cycle backgrounds"}, {"icon", "preferences-desktop-wallpaper-symbolic"}},
            QVariantMap{{"kind", "action"}, {"id", "caffeine"}, {"name", "Toggle Caffeine"},
                {"generic", "Pause or resume idle locking"}, {"icon", "coffee-symbolic"}},
            QVariantMap{{"kind", "action"}, {"id", "dnd"}, {"name", "Toggle Do Not Disturb"},
                {"generic", "Silence or resume notification popups"}, {"icon", "notifications-disabled-symbolic"}},
            QVariantMap{{"kind", "action"}, {"id", "screenshot"}, {"name", "Capture a Screen Region"},
                {"generic", "Save to Screenshots and copy to clipboard"}, {"icon", "camera-photo-symbolic"}},
            QVariantMap{{"kind", "action"}, {"id", "record"}, {"name", "Record the Screen"},
                {"generic", "Open Kooha screen recorder"}, {"icon", "media-record-symbolic"}},
            QVariantMap{{"kind", "action"}, {"id", "lock"}, {"name", "Lock the Session"},
                {"generic", "Show the Nocturne lock screen"}, {"icon", "system-lock-screen-symbolic"}},
            QVariantMap{{"kind", "action"}, {"id", "overview"}, {"name", "Workspace Overview"},
                {"generic", "See every workspace and move windows"}, {"icon", "view-grid-symbolic"}},
            QVariantMap{{"kind", "action"}, {"id", "scenes"}, {"name", "Session Scenes"},
                {"generic", "Save and restore an application layout"}, {"icon", "document-save-symbolic"}},
            QVariantMap{{"kind", "action"}, {"id", "privacy"}, {"name", "Privacy Dashboard"},
                {"generic", "See applications using microphones and cameras"}, {"icon", "security-high-symbolic"}},
            QVariantMap{{"kind", "action"}, {"id", "gaming"}, {"name", "Gaming Dashboard"},
                {"generic", "GPU metrics, automatic mode and MangoHud"}, {"icon", "applications-games-symbolic"}}
        };
        for (const auto &value : actions) {
            const auto action = value.toMap();
            if (matches(action.value("name").toString() + QLatin1Char(' ') + action.value("generic").toString())) {
                result.push_back(action);
            }
        }
    }

    if (mode == QStringLiteral("all") || mode == QStringLiteral("windows")) {
        const auto clients = json({"hyprctl", "clients", "-j"}, 1200).toList();
        for (const auto &value : clients) {
            const auto client = value.toMap();
            const auto title = client.value("title").toString().trimmed();
            const auto windowClass = client.value("class").toString().trimmed();
            const auto address = client.value("address").toString();
            if (title.isEmpty() || windowClass == QStringLiteral("nocturne-native")
                || !matches(title + QLatin1Char(' ') + windowClass)) continue;
            result.push_back(QVariantMap{{"kind", "window"}, {"name", title},
                {"generic", windowClass + QStringLiteral(" · running window")},
                {"icon", windowClass.toLower()}, {"address", address}});
            if (result.size() >= 80) return result;
        }
    }

    if (mode == QStringLiteral("all") || mode == QStringLiteral("apps")) {
        const auto favoriteValues = json({QStringLiteral("jq"), QStringLiteral("-c"), QStringLiteral("."),
            home() + QStringLiteral("/.config/nocturne/launcher-favorites.json")}, 800).toList();
        const auto recentValues = json({QStringLiteral("jq"), QStringLiteral("-c"), QStringLiteral("."),
            home() + QStringLiteral("/.local/state/nocturne/launcher-recents.json")}, 800).toList();
        auto applicationValues = applications(needle);
        std::stable_sort(applicationValues.begin(), applicationValues.end(), [&](const QVariant &left, const QVariant &right) {
            const auto leftPath = left.toMap().value(QStringLiteral("path")).toString();
            const auto rightPath = right.toMap().value(QStringLiteral("path")).toString();
            const int leftFavorite = favoriteValues.indexOf(leftPath), rightFavorite = favoriteValues.indexOf(rightPath);
            if ((leftFavorite >= 0) != (rightFavorite >= 0)) return leftFavorite >= 0;
            if (leftFavorite >= 0 && rightFavorite >= 0) return leftFavorite < rightFavorite;
            const int leftRecent = recentValues.indexOf(leftPath), rightRecent = recentValues.indexOf(rightPath);
            if ((leftRecent >= 0) != (rightRecent >= 0)) return leftRecent >= 0;
            return leftRecent >= 0 && rightRecent >= 0 && leftRecent < rightRecent;
        });
        for (const auto &value : applicationValues) {
            auto application = value.toMap();
            application.insert(QStringLiteral("kind"), QStringLiteral("application"));
            application.insert(QStringLiteral("favorite"), favoriteValues.contains(application.value(QStringLiteral("path"))));
            result.push_back(application);
            if (result.size() >= 80) break;
        }
    }
    return result;
}

bool Backend::activateLauncherResult(const QVariantMap &result)
{
    const auto kind = result.value(QStringLiteral("kind")).toString();
    if (kind == QStringLiteral("application")) {
        return launchApplication(result.value(QStringLiteral("path")).toString());
    }
    if (kind == QStringLiteral("calculation")) return copyText(result.value(QStringLiteral("name")).toString());
    if (kind == QStringLiteral("file")) {
        const bool launched = QProcess::startDetached(QStringLiteral("xdg-open"), {result.value(QStringLiteral("path")).toString()});
        if (launched) QCoreApplication::quit();
        return launched;
    }
    if (kind == QStringLiteral("window")) {
        const auto address = result.value(QStringLiteral("address")).toString();
        if (!QRegularExpression(QStringLiteral("^0x[0-9a-fA-F]+$")).match(address).hasMatch()) return false;
        QProcess process;
        process.start(QStringLiteral("hyprctl"), {QStringLiteral("dispatch"),
            QStringLiteral("hl.dsp.focus({ window = \"address:%1\" })").arg(address)});
        const bool focused = process.waitForStarted(800) && process.waitForFinished(1200) && process.exitCode() == 0;
        if (focused) QCoreApplication::quit();
        return focused;
    }
    if (kind != QStringLiteral("action")) return false;

    const auto id = result.value(QStringLiteral("id")).toString();
    QStringList command;
    if (id == QStringLiteral("settings")) command = {home() + QStringLiteral("/.local/bin/nocturne-settings")};
    else if (id == QStringLiteral("notifications")) { dispatch(QStringLiteral("notifications"), {}); return true; }
    else if (id == QStringLiteral("clipboard")) { dispatch(QStringLiteral("clipboard"), {}); return true; }
    else if (id == QStringLiteral("connectivity")) { dispatch(QStringLiteral("connectivity"), QStringLiteral("wifi")); return true; }
    else if (id == QStringLiteral("power")) { dispatch(QStringLiteral("power"), {}); return true; }
    else if (id == QStringLiteral("wallpaper")) { dispatch(QStringLiteral("background"), {}); return true; }
    else if (id == QStringLiteral("caffeine")) command = {home() + QStringLiteral("/.config/hypr/scripts/caffeine"), QStringLiteral("toggle")};
    else if (id == QStringLiteral("dnd")) command = {QStringLiteral("makoctl"), QStringLiteral("mode"), QStringLiteral("-t"), QStringLiteral("do-not-disturb")};
    else if (id == QStringLiteral("screenshot")) command = {home() + QStringLiteral("/.local/bin/hyprshot"), QStringLiteral("-o"), home() + QStringLiteral("/Pictures/Screenshots"), QStringLiteral("-m"), QStringLiteral("region")};
    else if (id == QStringLiteral("record")) command = {QStringLiteral("flatpak"), QStringLiteral("run"), QStringLiteral("io.github.seadve.Kooha")};
    else if (id == QStringLiteral("lock")) command = {home() + QStringLiteral("/.config/hypr/scripts/lock-screen")};
    else if (id == QStringLiteral("overview")) command = {home() + QStringLiteral("/.config/hypr/scripts/overview")};
    else if (id == QStringLiteral("scenes")) { dispatch(QStringLiteral("scenes"), {}); return true; }
    else if (id == QStringLiteral("privacy")) { dispatch(QStringLiteral("privacy"), {}); return true; }
    else if (id == QStringLiteral("gaming")) { dispatch(QStringLiteral("gaming"), {}); return true; }
    else return false;

    const bool launched = QProcess::startDetached(command.takeFirst(), command);
    if (launched) QCoreApplication::quit();
    return launched;
}

QVariantList Backend::trayItems() const
{
    QDBusInterface watcher(QStringLiteral("org.kde.StatusNotifierWatcher"),
        QStringLiteral("/StatusNotifierWatcher"), QStringLiteral("org.kde.StatusNotifierWatcher"),
        QDBusConnection::sessionBus());
    const auto references = watcher.property("RegisteredStatusNotifierItems").toStringList();
    QDBusInterface bus(QStringLiteral("org.freedesktop.DBus"), QStringLiteral("/org/freedesktop/DBus"),
        QStringLiteral("org.freedesktop.DBus"), QDBusConnection::sessionBus());
    struct Entry { int priority; QVariantMap data; };
    QList<Entry> entries;
    QVariantMap updateEntry;
    for (const auto &reference : references) {
        const int slash = reference.indexOf(QLatin1Char('/'));
        if (slash <= 0) continue;
        const auto service = reference.left(slash);
        const auto path = reference.mid(slash);
        QDBusInterface item(service, path, QStringLiteral("org.kde.StatusNotifierItem"), QDBusConnection::sessionBus());
        if (!item.isValid()) continue;
        const auto id = item.property("Id").toString();
        auto title = item.property("Title").toString();
        auto icon = item.property("IconName").toString();
        const auto category = item.property("Category").toString();
        const auto identity = (id + QLatin1Char(' ') + path).toLower();

        QString processName;
        const QDBusReply<uint> processReply = bus.call(QStringLiteral("GetConnectionUnixProcessID"), service);
        if (processReply.isValid()) {
            processName = readText(QStringLiteral("/proc/%1/comm").arg(processReply.value())).trimmed().toLower();
        }

        const bool updater = identity.contains(QStringLiteral("software_update_available"))
            || identity.contains(QStringLiteral("livepatch"))
            || identity.contains(QStringLiteral("unattended_upgrade"));
        if (updater) {
            QVariantMap candidate{
                {QStringLiteral("reference"), reference},
                {QStringLiteral("title"), QStringLiteral("System Security")},
                {QStringLiteral("icon"), QStringLiteral("livepatch_on")},
                {QStringLiteral("status"), item.property("Status").toString()}
            };
            if (updateEntry.isEmpty() || identity.contains(QStringLiteral("livepatch"))) updateEntry = candidate;
            continue;
        }

        int priority = 10;
        if (processName.contains(QStringLiteral("chatgpt"))) {
            title = QStringLiteral("ChatGPT");
            icon = QStringLiteral("chatgpt");
            priority = 1;
        } else if (processName.contains(QStringLiteral("steam"))) {
            title = QStringLiteral("Steam");
            icon = QStringLiteral("steam");
            priority = 2;
        } else if (processName.contains(QStringLiteral("easyeffects"))) {
            title = QStringLiteral("EasyEffects");
            if (icon.isEmpty()) icon = QStringLiteral("com.github.wwmm.easyeffects");
            priority = 3;
        } else if (processName.contains(QStringLiteral("qpwgraph"))) {
            title = QStringLiteral("QPWGraph");
            if (icon.isEmpty()) icon = QStringLiteral("org.rncbc.qpwgraph");
            priority = 4;
        } else if (identity.startsWith(QStringLiteral("chrome_status_icon"))) {
            if (title.isEmpty()) title = QStringLiteral("Chrome");
            if (icon.isEmpty()) icon = QStringLiteral("google-chrome");
        }
        if (title.isEmpty()) title = id;
        if (title.isEmpty()) title = service;
        const auto menuPath = item.property("Menu").value<QDBusObjectPath>().path();
        entries.push_back({priority, QVariantMap{
            {QStringLiteral("reference"), reference},
            {QStringLiteral("title"), title},
            {QStringLiteral("icon"), icon},
            {QStringLiteral("status"), item.property("Status").toString()},
            {QStringLiteral("category"), category},
            {QStringLiteral("process"), processName},
            {QStringLiteral("hasMenu"), !menuPath.isEmpty() && menuPath != QStringLiteral("/")}
        }});
    }
    if (!updateEntry.isEmpty()) entries.push_back({0, updateEntry});
    std::sort(entries.begin(), entries.end(), [](const Entry &left, const Entry &right) {
        if (left.priority != right.priority) return left.priority < right.priority;
        return left.data.value(QStringLiteral("title")).toString().localeAwareCompare(
                   right.data.value(QStringLiteral("title")).toString()) < 0;
    });
    QVariantList result;
    for (const auto &entry : entries) {
        result.push_back(entry.data);
        if (result.size() == 12) break;
    }
    return result;
}

namespace {
void appendMenuLayout(const QDBusArgument &value, QVariantList &rows, int depth)
{
    if (depth > 3) return;
    int id = 0;
    QVariantMap properties;
    value.beginStructure();
    value >> id >> properties;
    QVariantList children;
    value >> children;
    value.endStructure();
    const auto label = properties.value(QStringLiteral("label")).toString();
    const auto type = properties.value(QStringLiteral("type")).toString();
    if (id != 0 && properties.value(QStringLiteral("visible"), true).toBool()) {
        rows.push_back(QVariantMap{
            {QStringLiteral("id"), id},
            {QStringLiteral("label"), label.isEmpty() && type != QStringLiteral("separator") ? QStringLiteral("Action") : label},
            {QStringLiteral("enabled"), properties.value(QStringLiteral("enabled"), true).toBool()},
            {QStringLiteral("separator"), type == QStringLiteral("separator")},
            {QStringLiteral("toggle"), properties.value(QStringLiteral("toggle-type")).toString()},
            {QStringLiteral("checked"), properties.value(QStringLiteral("toggle-state"), 0).toInt() == 1},
            {QStringLiteral("icon"), properties.value(QStringLiteral("icon-name")).toString()},
            {QStringLiteral("depth"), depth}
        });
    }
    for (const auto &childValue : children) {
        if (childValue.canConvert<QDBusArgument>()) appendMenuLayout(childValue.value<QDBusArgument>(), rows, depth + 1);
    }
}

bool trayCoordinates(const QString &reference, QString &service, QString &path)
{
    const int slash = reference.indexOf(QLatin1Char('/'));
    if (slash <= 0) return false;
    service = reference.left(slash);
    path = reference.mid(slash);
    return true;
}
}

QVariantList Backend::trayMenu(const QString &reference) const
{
    QString service, itemPath;
    if (!trayCoordinates(reference, service, itemPath)) return {};
    QDBusInterface item(service, itemPath, QStringLiteral("org.kde.StatusNotifierItem"), QDBusConnection::sessionBus());
    const auto menuPath = item.property("Menu").value<QDBusObjectPath>().path();
    if (menuPath.isEmpty() || menuPath == QStringLiteral("/")) return {};
    QDBusInterface menu(service, menuPath, QStringLiteral("com.canonical.dbusmenu"), QDBusConnection::sessionBus());
    menu.call(QStringLiteral("AboutToShow"), 0);
    const auto reply = menu.call(QStringLiteral("GetLayout"), 0, 4,
        QStringList{QStringLiteral("label"), QStringLiteral("enabled"), QStringLiteral("visible"),
            QStringLiteral("type"), QStringLiteral("toggle-type"), QStringLiteral("toggle-state"),
            QStringLiteral("icon-name"), QStringLiteral("children-display")});
    if (reply.type() == QDBusMessage::ErrorMessage || reply.arguments().size() < 2
        || !reply.arguments().at(1).canConvert<QDBusArgument>()) return {};
    QVariantList rows;
    appendMenuLayout(reply.arguments().at(1).value<QDBusArgument>(), rows, -1);
    return rows;
}

bool Backend::activateTrayMenuItem(const QString &reference, int id) const
{
    if (id <= 0) return false;
    QString service, itemPath;
    if (!trayCoordinates(reference, service, itemPath)) return false;
    QDBusInterface item(service, itemPath, QStringLiteral("org.kde.StatusNotifierItem"), QDBusConnection::sessionBus());
    const auto menuPath = item.property("Menu").value<QDBusObjectPath>().path();
    if (menuPath.isEmpty() || menuPath == QStringLiteral("/")) return false;
    QDBusInterface menu(service, menuPath, QStringLiteral("com.canonical.dbusmenu"), QDBusConnection::sessionBus());
    const auto reply = menu.call(QStringLiteral("Event"), id, QStringLiteral("clicked"),
        QVariant::fromValue(QDBusVariant(0)), static_cast<uint>(QDateTime::currentSecsSinceEpoch()));
    return reply.type() != QDBusMessage::ErrorMessage;
}

QVariantList Backend::notifications(const QString &collection) const
{
    const auto command = collection == QStringLiteral("history") ? QStringLiteral("history") : QStringLiteral("list");
    const auto lines = run({QStringLiteral("makoctl"), command}, 1600).split(QLatin1Char('\n'));
    const QRegularExpression heading(QStringLiteral("^Notification\\s+(\\d+):\\s*(.*)$"));
    QVariantList result;
    QVariantMap current;
    bool readingActions = false;
    for (const auto &line : lines) {
        const auto match = heading.match(line);
        if (match.hasMatch()) {
            if (!current.isEmpty()) result.push_back(current);
            current = QVariantMap{
                {QStringLiteral("id"), match.captured(1).toInt()},
                {QStringLiteral("summary"), match.captured(2)},
                {QStringLiteral("history"), command == QStringLiteral("history")}
            };
            readingActions = false;
        } else if (line.trimmed().startsWith(QStringLiteral("App name:"))) {
            current.insert(QStringLiteral("app"), line.section(QLatin1Char(':'), 1).trimmed());
        } else if (line.trimmed().startsWith(QStringLiteral("Desktop entry:"))) {
            current.insert(QStringLiteral("desktop"), line.section(QLatin1Char(':'), 1).trimmed());
        } else if (line.trimmed().startsWith(QStringLiteral("Urgency:"))) {
            current.insert(QStringLiteral("urgency"), line.section(QLatin1Char(':'), 1).trimmed());
        } else if (line.trimmed().startsWith(QStringLiteral("Body:"))) {
            current.insert(QStringLiteral("body"), line.section(QLatin1Char(':'), 1).trimmed());
        } else if (line.trimmed().startsWith(QStringLiteral("Progress:"))) {
            current.insert(QStringLiteral("progress"), line.section(QLatin1Char(':'), 1).trimmed().toInt());
        } else if (line.trimmed() == QStringLiteral("Actions:")) {
            readingActions = true;
        } else if (readingActions && line.startsWith(QStringLiteral("    ")) && line.contains(QLatin1Char(':'))) {
            current.insert(QStringLiteral("hasAction"), true);
        }
    }
    if (!current.isEmpty()) result.push_back(current);

    for (auto &value : result) {
        auto notification = value.toMap();
        const auto desktopId = notification.value(QStringLiteral("desktop")).toString();
        const auto sourceApp = notification.value(QStringLiteral("app")).toString();
        QString displayApp;
        QString icon;

        if (!desktopId.isEmpty()) {
            auto fileName = desktopId;
            if (!fileName.endsWith(QStringLiteral(".desktop"))) fileName += QStringLiteral(".desktop");
            QString desktopPath;
            for (const auto &root : {home() + QStringLiteral("/.local/share/applications"),
                     QStringLiteral("/usr/local/share/applications"), QStringLiteral("/usr/share/applications")}) {
                const auto candidate = QDir(root).filePath(fileName);
                if (QFileInfo::exists(candidate)) { desktopPath = candidate; break; }
            }
            if (!desktopPath.isEmpty()) {
                QSettings desktop(desktopPath, QSettings::IniFormat);
                desktop.beginGroup(QStringLiteral("Desktop Entry"));
                displayApp = desktop.value(QStringLiteral("Name")).toString();
                icon = desktop.value(QStringLiteral("Icon")).toString();
            }
        }

        if (displayApp.isEmpty() || icon.isEmpty()) {
            for (const auto &applicationValue : m_applications) {
                const auto application = applicationValue.toMap();
                const bool nameMatches = application.value(QStringLiteral("name")).toString().compare(sourceApp, Qt::CaseInsensitive) == 0;
                const bool desktopMatches = !desktopId.isEmpty()
                    && QFileInfo(application.value(QStringLiteral("path")).toString()).completeBaseName().compare(desktopId, Qt::CaseInsensitive) == 0;
                if (!nameMatches && !desktopMatches) continue;
                if (displayApp.isEmpty()) displayApp = application.value(QStringLiteral("name")).toString();
                if (icon.isEmpty()) icon = application.value(QStringLiteral("icon")).toString();
                break;
            }
        }

        if (desktopId.compare(QStringLiteral("steam"), Qt::CaseInsensitive) == 0) displayApp = QStringLiteral("Steam");
        if (sourceApp.compare(QStringLiteral("notify-send"), Qt::CaseInsensitive) == 0) displayApp = QStringLiteral("System");
        if (displayApp.isEmpty()) displayApp = sourceApp.isEmpty() ? QStringLiteral("System") : sourceApp;
        if (icon.isEmpty()) {
            const auto identity = (displayApp + QLatin1Char(' ') + sourceApp).toLower();
            if (identity.contains(QStringLiteral("chatgpt"))) icon = QStringLiteral("chatgpt");
            else if (identity.contains(QStringLiteral("steam"))) icon = QStringLiteral("steam");
            else if (identity.contains(QStringLiteral("chrome")) || identity.contains(QStringLiteral("chromium"))) icon = QStringLiteral("google-chrome");
            else if (identity.contains(QStringLiteral("capture")) || identity.contains(QStringLiteral("screenshot"))) icon = QStringLiteral("camera-photo-symbolic");
            else if (displayApp == QStringLiteral("System")) icon = QStringLiteral("preferences-system-notifications");
        }
        notification.insert(QStringLiteral("displayApp"), displayApp);
        notification.insert(QStringLiteral("icon"), icon);
        const auto searchable = notification.value(QStringLiteral("summary")).toString() + QLatin1Char(' ')
            + notification.value(QStringLiteral("body")).toString();
        const auto codeMatch = QRegularExpression(QStringLiteral("(?:^|\\D)(\\d{4,8})(?:\\D|$)")).match(searchable);
        if (codeMatch.hasMatch()) notification.insert(QStringLiteral("code"), codeMatch.captured(1));
        value = notification;
    }
    QMap<QString, int> counts;
    for (const auto &value : result) counts[value.toMap().value(QStringLiteral("displayApp")).toString()]++;
    for (auto &value : result) {
        auto notification = value.toMap();
        notification.insert(QStringLiteral("groupCount"), counts.value(notification.value(QStringLiteral("displayApp")).toString()));
        value = notification;
    }
    return result;
}

QVariantList Backend::clipboardItems(const QString &query) const
{
    const auto needle = query.simplified();
    QVariantList result;
    const auto lines = run({QStringLiteral("cliphist"), QStringLiteral("list")}, 1600).split(QLatin1Char('\n'));
    for (const auto &entry : lines) {
        if (entry.isEmpty() || (!needle.isEmpty() && !entry.contains(needle, Qt::CaseInsensitive))) continue;
        auto preview = entry.section(QLatin1Char('\t'), 1);
        if (preview.isEmpty()) preview = entry;
        result.push_back(QVariantMap{{QStringLiteral("entry"), entry}, {QStringLiteral("preview"), preview}});
        if (result.size() == 100) break;
    }
    return result;
}

bool Backend::copyClipboardItem(const QString &entry) const
{
    if (entry.isEmpty()) return false;
    QProcess decode;
    decode.start(QStringLiteral("cliphist"), {QStringLiteral("decode")});
    if (!decode.waitForStarted(1000)) return false;
    decode.write(entry.toUtf8());
    decode.closeWriteChannel();
    if (!decode.waitForFinished(2000) || decode.exitCode() != 0) return false;
    QProcess copy;
    copy.start(QStringLiteral("wl-copy"));
    if (!copy.waitForStarted(1000)) return false;
    copy.write(decode.readAllStandardOutput());
    copy.closeWriteChannel();
    const bool copied = copy.waitForFinished(2000) && copy.exitCode() == 0;
    if (copied) QCoreApplication::quit();
    return copied;
}

bool Backend::activateTrayItem(const QString &reference, const QString &action) const
{
    const int slash = reference.indexOf(QLatin1Char('/'));
    if (slash <= 0) return false;
    QDBusInterface item(reference.left(slash), reference.mid(slash),
        QStringLiteral("org.kde.StatusNotifierItem"), QDBusConnection::sessionBus());
    if (!item.isValid()) return false;
    const auto cursor = json({"hyprctl", "cursorpos", "-j"}, 1000).toMap();
    const int x = cursor.value(QStringLiteral("x")).toInt();
    const int y = cursor.value(QStringLiteral("y")).toInt();
    const auto id = item.property("Id").toString().toLower();

    auto call = [&](const QString &method) {
        return item.call(method, x, y).type() != QDBusMessage::ErrorMessage;
    };
    auto launchFallback = [&]() {
        if (id.contains(QStringLiteral("steam"))) {
            return QProcess::startDetached(home() + QStringLiteral("/.local/bin/steam"),
                {QStringLiteral("steam://open/main")});
        }
        if (id.contains(QStringLiteral("easyeffects")))
            return QProcess::startDetached(QStringLiteral("easyeffects"), {});
        if (id.contains(QStringLiteral("qpwgraph")))
            return QProcess::startDetached(QStringLiteral("qpwgraph"), {});
        return false;
    };

    if (action == QStringLiteral("context")) {
        if (call(QStringLiteral("ContextMenu"))) return true;
        return launchFallback();
    }
    if (action == QStringLiteral("secondary")) {
        if (call(QStringLiteral("SecondaryActivate"))) return true;
        return launchFallback();
    }
    if (call(QStringLiteral("Activate"))) return true;
    // Ayatana-only items such as Steam export a DBusMenu but no standard
    // Activate method. A normal application URI is the least surprising
    // left-click fallback and focuses the already-running client.
    if (launchFallback()) return true;
    return call(QStringLiteral("SecondaryActivate"));
}

bool Backend::launchApplication(const QString &desktopFile)
{
    QSettings desktop(QDir::cleanPath(desktopFile), QSettings::IniFormat);
    desktop.beginGroup(QStringLiteral("Desktop Entry"));
    auto command = desktop.value(QStringLiteral("Exec")).toString();
    if (command.isEmpty()) return false;
    command.replace(QStringLiteral("%%"), QStringLiteral("%"));
    command.remove(QRegularExpression(QStringLiteral("\\s*%[fFuUdDnNickvm]")));
    auto arguments = QProcess::splitCommand(command);
    if (arguments.isEmpty()) return false;
    const auto program = arguments.takeFirst();
    if (desktop.value(QStringLiteral("Terminal"), false).toBool()) {
        arguments.prepend(program);
        arguments.prepend(QStringLiteral("-e"));
        arguments.prepend(QStringLiteral("kitty"));
        const auto terminal = arguments.takeFirst();
        const bool launched = QProcess::startDetached(terminal, arguments);
        if (launched) {
            const auto stateDirectory = home() + QStringLiteral("/.local/state/nocturne");
            QDir().mkpath(stateDirectory);
            auto recents = json({QStringLiteral("jq"), QStringLiteral("-c"), QStringLiteral("."), stateDirectory + QStringLiteral("/launcher-recents.json")}, 500).toList();
            recents.removeAll(desktopFile); recents.prepend(desktopFile); while (recents.size() > 20) recents.removeLast();
            writeText(stateDirectory + QStringLiteral("/launcher-recents.json"), QString::fromUtf8(QJsonDocument::fromVariant(recents).toJson(QJsonDocument::Compact)) + QLatin1Char('\n'));
            QCoreApplication::quit();
        }
        return launched;
    }
    const auto workingDirectory = desktop.value(QStringLiteral("Path")).toString();
    const bool launched = QProcess::startDetached(program, arguments, workingDirectory);
    if (launched) {
        const auto stateDirectory = home() + QStringLiteral("/.local/state/nocturne");
        QDir().mkpath(stateDirectory);
        auto recents = json({QStringLiteral("jq"), QStringLiteral("-c"), QStringLiteral("."), stateDirectory + QStringLiteral("/launcher-recents.json")}, 500).toList();
        recents.removeAll(desktopFile); recents.prepend(desktopFile); while (recents.size() > 20) recents.removeLast();
        writeText(stateDirectory + QStringLiteral("/launcher-recents.json"), QString::fromUtf8(QJsonDocument::fromVariant(recents).toJson(QJsonDocument::Compact)) + QLatin1Char('\n'));
        QCoreApplication::quit();
    }
    return launched;
}

bool Backend::toggleFavorite(const QString &desktopFile)
{
    if (desktopFile.isEmpty()) return false;
    const auto path = home() + QStringLiteral("/.config/nocturne/launcher-favorites.json");
    auto values = json({QStringLiteral("jq"), QStringLiteral("-c"), QStringLiteral("."), path}, 800).toList();
    const int index = values.indexOf(desktopFile);
    if (index >= 0) values.removeAt(index); else values.prepend(desktopFile);
    return writeText(path, QString::fromUtf8(QJsonDocument::fromVariant(values).toJson(QJsonDocument::Compact)) + QLatin1Char('\n'));
}

bool Backend::copyText(const QString &text) const
{
    QProcess copy;
    copy.start(QStringLiteral("wl-copy"));
    if (!copy.waitForStarted(800)) return false;
    copy.write(text.toUtf8()); copy.closeWriteChannel();
    return copy.waitForFinished(1400) && copy.exitCode() == 0;
}

QVariantList Backend::wallpapers() const
{
    const QStringList roots = {
        home() + QStringLiteral("/Pictures/Wallpapers"),
        home() + QStringLiteral("/.local/share/backgrounds")
    };
    const QSet<QString> extensions = {"jpg", "jpeg", "png", "webp", "avif"};
    QSet<QString> seen;
    QVariantList images;
    for (const auto &root : roots) {
        QDirIterator iterator(root, QDir::Files, QDirIterator::Subdirectories);
        while (iterator.hasNext() && images.size() < 240) {
            const QFileInfo info(iterator.next());
            if (!extensions.contains(info.suffix().toLower())) continue;
            const auto path = info.canonicalFilePath().isEmpty() ? info.absoluteFilePath() : info.canonicalFilePath();
            if (seen.contains(path)) continue;
            seen.insert(path);
            images.push_back(QVariantMap{{"path", path}, {"name", info.completeBaseName()}});
        }
    }
    return images;
}

bool Backend::start(const QVariantList &arguments) const
{
    const auto values = stringList(arguments);
    return !values.isEmpty() && QProcess::startDetached(values.first(), values.mid(1));
}

QString Backend::readText(const QString &path) const
{
    QFile file(QDir::cleanPath(path));
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        return {};
    }
    return QString::fromUtf8(file.readAll());
}

QString Backend::readFirst(const QString &directory, const QString &fileName) const
{
    QDir root(directory);
    const auto entries = root.entryList(QDir::Dirs | QDir::NoDotAndDotDot, QDir::Name);
    for (const auto &entry : entries) {
        const auto value = readText(root.filePath(entry + QLatin1Char('/') + fileName));
        if (!value.isEmpty()) {
            return value;
        }
    }
    return {};
}

bool Backend::writeText(const QString &path, const QString &contents) const
{
    QFile file(QDir::cleanPath(path));
    QDir().mkpath(QFileInfo(file).absolutePath());
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text | QIODevice::Truncate)) {
        return false;
    }
    return file.write(contents.toUtf8()) == contents.toUtf8().size();
}

int Backend::rightMargin(int width) const
{
    const auto cursor = json({"hyprctl", "cursorpos", "-j"}).toMap();
    const auto monitors = json({"hyprctl", "monitors", "-j"}).toList();
    const int cursorX = cursor.value("x").toInt();
    for (const auto &item : monitors) {
        const auto monitor = item.toMap();
        const int left = monitor.value("x").toInt();
        const int monitorWidth = monitor.value("width").toInt();
        if (cursorX >= left && cursorX < left + monitorWidth) {
            return qBound(8, monitorWidth - (cursorX - left) - width / 2, monitorWidth - width - 8);
        }
    }
    return 8;
}

void Backend::refreshTheme()
{
    emit paletteChanged();
}

void Backend::close()
{
    QCoreApplication::quit();
}

void Backend::dispatch(const QString &surface, const QString &page)
{
    if (surface == m_surface && (page.isEmpty() || page == m_page)) {
        close();
        return;
    }
    updateTargetScreen();
    if (m_surface != surface) {
        m_surface = surface;
        emit surfaceChanged();
    }
    if (m_page != page) {
        m_page = page;
        emit pageChanged();
    }
}

void Backend::updateTargetScreen()
{
    const auto cursor = json({"hyprctl", "cursorpos", "-j"}).toMap();
    const auto monitors = json({"hyprctl", "monitors", "-j"}).toList();
    const int cursorX = cursor.value("x").toInt();
    const int cursorY = cursor.value("y").toInt();
    QString connector;
    for (const auto &item : monitors) {
        const auto monitor = item.toMap();
        const int x = monitor.value("x").toInt();
        const int y = monitor.value("y").toInt();
        const int width = monitor.value("width").toInt();
        const int height = monitor.value("height").toInt();
        if (cursorX >= x && cursorX < x + width && cursorY >= y && cursorY < y + height) {
            connector = monitor.value("name").toString();
            break;
        }
    }
    QScreen *selected = QGuiApplication::primaryScreen();
    for (auto *screen : QGuiApplication::screens()) {
        if (screen->name() == connector) {
            selected = screen;
            break;
        }
    }
    if (selected != m_targetScreen) {
        m_targetScreen = selected;
        emit targetScreenChanged();
    }
}
