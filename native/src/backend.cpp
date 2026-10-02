#include "backend.h"

#include <QCoreApplication>
#include <QDir>
#include <QDirIterator>
#include <QFile>
#include <QFileInfo>
#include <QGuiApplication>
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <QProcess>
#include <QRegularExpression>
#include <QSet>
#include <unistd.h>

Backend::Backend(QString surface, QString page, QObject *parent)
    : QObject(parent)
    , m_surface(std::move(surface))
    , m_page(std::move(page))
{
    updateTargetScreen();
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
