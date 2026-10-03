#include "backend.h"
#include "traywatcher.h"

#include <QCoreApplication>
#include <QDir>
#include <QDirIterator>
#include <QDBusInterface>
#include <QDBusReply>
#include <QFile>
#include <QFileInfo>
#include <QGuiApplication>
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <QProcess>
#include <QRegularExpression>
#include <QSet>
#include <QSettings>
#include <algorithm>
#include <unistd.h>

Backend::Backend(QString surface, QString page, QObject *parent)
    : QObject(parent)
    , m_surface(std::move(surface))
    , m_page(std::move(page))
{
    updateTargetScreen();
    if (m_surface == QStringLiteral("bar")) m_trayWatcher = std::make_unique<TrayWatcher>(this);

    const QStringList roots = {
        home() + QStringLiteral("/.local/share/applications"),
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
            if (desktop.value(QStringLiteral("Type")).toString() != QStringLiteral("Application")
                || desktop.value(QStringLiteral("Hidden"), false).toBool()
                || desktop.value(QStringLiteral("NoDisplay"), false).toBool()) {
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

Backend::~Backend() = default;

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

QVariantList Backend::trayItems() const
{
    QDBusInterface watcher(QStringLiteral("org.kde.StatusNotifierWatcher"),
        QStringLiteral("/StatusNotifierWatcher"), QStringLiteral("org.kde.StatusNotifierWatcher"),
        QDBusConnection::sessionBus());
    const auto references = watcher.property("RegisteredStatusNotifierItems").toStringList();
    QVariantList result;
    for (const auto &reference : references) {
        const int slash = reference.indexOf(QLatin1Char('/'));
        if (slash <= 0) continue;
        const auto service = reference.left(slash);
        const auto path = reference.mid(slash);
        QDBusInterface item(service, path, QStringLiteral("org.kde.StatusNotifierItem"), QDBusConnection::sessionBus());
        if (!item.isValid()) continue;
        auto title = item.property("Title").toString();
        if (title.isEmpty()) title = item.property("Id").toString();
        if (title.isEmpty()) title = service;
        result.push_back(QVariantMap{
            {QStringLiteral("reference"), reference},
            {QStringLiteral("title"), title},
            {QStringLiteral("icon"), item.property("IconName").toString()},
            {QStringLiteral("status"), item.property("Status").toString()}
        });
    }
    return result;
}

QVariantList Backend::notifications(const QString &collection) const
{
    const auto command = collection == QStringLiteral("history") ? QStringLiteral("history") : QStringLiteral("list");
    const auto lines = run({QStringLiteral("makoctl"), command}, 1600).split(QLatin1Char('\n'));
    const QRegularExpression heading(QStringLiteral("^Notification\\s+(\\d+):\\s*(.*)$"));
    QVariantList result;
    QVariantMap current;
    for (const auto &line : lines) {
        const auto match = heading.match(line);
        if (match.hasMatch()) {
            if (!current.isEmpty()) result.push_back(current);
            current = QVariantMap{
                {QStringLiteral("id"), match.captured(1).toInt()},
                {QStringLiteral("summary"), match.captured(2)},
                {QStringLiteral("history"), command == QStringLiteral("history")}
            };
        } else if (line.trimmed().startsWith(QStringLiteral("App name:"))) {
            current.insert(QStringLiteral("app"), line.section(QLatin1Char(':'), 1).trimmed());
        } else if (line.trimmed().startsWith(QStringLiteral("Urgency:"))) {
            current.insert(QStringLiteral("urgency"), line.section(QLatin1Char(':'), 1).trimmed());
        }
    }
    if (!current.isEmpty()) result.push_back(current);
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
    QString method = QStringLiteral("Activate");
    if (action == QStringLiteral("context")) method = QStringLiteral("ContextMenu");
    else if (action == QStringLiteral("secondary")) method = QStringLiteral("SecondaryActivate");
    return item.call(method, 0, 0).type() != QDBusMessage::ErrorMessage;
}

bool Backend::launchApplication(const QString &desktopFile) const
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
        if (launched) QCoreApplication::quit();
        return launched;
    }
    const auto workingDirectory = desktop.value(QStringLiteral("Path")).toString();
    const bool launched = QProcess::startDetached(program, arguments, workingDirectory);
    if (launched) QCoreApplication::quit();
    return launched;
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
