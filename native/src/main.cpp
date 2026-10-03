#include "backend.h"

#include <QGuiApplication>
#include <QDir>
#include <QDirIterator>
#include <QFileInfo>
#include <QIcon>
#include <QLocalServer>
#include <QLocalSocket>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickImageProvider>
#include <QTimer>
#include <QUrl>
#include <iostream>
#include <unistd.h>

class ThemeIconProvider final : public QQuickImageProvider
{
public:
    ThemeIconProvider()
        : QQuickImageProvider(QQuickImageProvider::Image)
    {
    }

    QImage requestImage(const QString &id, QSize *size, const QSize &requestedSize) override
    {
        const auto name = QUrl::fromPercentEncoding(id.toUtf8());
        const QSize target = requestedSize.isValid() ? requestedSize : QSize(32, 32);
        QIcon icon = QFileInfo::exists(name) ? QIcon(name) : QIcon::fromTheme(name);
        if (icon.isNull() && !name.isEmpty()) {
            const QStringList roots = {
                QDir::homePath() + QStringLiteral("/.local/share/icons"),
                QDir::homePath() + QStringLiteral("/.icons"),
                QStringLiteral("/usr/local/share/icons"),
                QStringLiteral("/usr/share/icons"),
                QStringLiteral("/usr/share/pixmaps")
            };
            const QStringList names = {name + QStringLiteral(".svg"), name + QStringLiteral(".png"),
                name + QStringLiteral(".xpm")};
            for (const auto &root : roots) {
                QDirIterator candidates(root, names, QDir::Files, QDirIterator::Subdirectories);
                if (candidates.hasNext()) {
                    icon = QIcon(candidates.next());
                    break;
                }
            }
        }
        const auto image = icon.pixmap(target).toImage();
        if (size) *size = image.size();
        return image;
    }
};

int main(int argc, char *argv[])
{
    if (argc == 2 && QString::fromLocal8Bit(argv[1]) == QStringLiteral("--self-test")) {
        std::cout << "NOCTURNE // native shell binary ready\n";
        return 0;
    }
    qputenv("QT_QUICK_CONTROLS_STYLE", "Basic");
    const QString surface = argc > 1 ? QString::fromLocal8Bit(argv[1]) : QStringLiteral("audio");
    const QString page = argc > 2 ? QString::fromLocal8Bit(argv[2]) : QString();
    const bool settings = surface == QStringLiteral("settings");
    const bool bar = surface == QStringLiteral("bar");
    QCoreApplication::setApplicationName(QStringLiteral("Nocturne Native"));
    QCoreApplication::setOrganizationName(QStringLiteral("Nocturne"));
    QGuiApplication::setDesktopFileName(settings ? QStringLiteral("nocturne-settings") : QStringLiteral("nocturne-native"));
    QGuiApplication application(argc, argv);
    const QString socketName = QStringLiteral("nocturne-native-%1-%2")
                                   .arg(settings ? QStringLiteral("settings") : (bar ? QStringLiteral("bar") : QStringLiteral("shell")))
                                   .arg(getuid());

    QLocalSocket client;
    client.connectToServer(socketName);
    if (client.waitForConnected(120)) {
        if (bar) return 0;
        client.write((surface + QLatin1Char('\t') + page + QLatin1Char('\n')).toUtf8());
        client.waitForBytesWritten(500);
        return 0;
    }

    QLocalServer::removeServer(socketName);
    QLocalServer server;
    if (!server.listen(socketName)) {
        return 2;
    }

    Backend backend(surface, page);
    QObject::connect(&server, &QLocalServer::newConnection, &application, [&]() {
        while (auto *connection = server.nextPendingConnection()) {
            if (connection->waitForReadyRead(300)) {
                const auto fields = QString::fromUtf8(connection->readAll()).trimmed().split(QLatin1Char('\t'));
                backend.dispatch(fields.value(0), fields.value(1));
            }
            connection->disconnectFromServer();
            connection->deleteLater();
        }
    });

    QQmlApplicationEngine engine;
    engine.addImageProvider(QStringLiteral("theme"), new ThemeIconProvider);
    engine.rootContext()->setContextProperty(QStringLiteral("backend"), &backend);
    const QUrl source(settings
                          ? QStringLiteral("qrc:/qt/qml/Nocturne/Native/qml/Settings.qml")
                          : (bar ? QStringLiteral("qrc:/qt/qml/Nocturne/Native/qml/Bar.qml")
                                 : QStringLiteral("qrc:/qt/qml/Nocturne/Native/qml/Shell.qml")));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed, &application, []() {
        QCoreApplication::exit(3);
    }, Qt::QueuedConnection);
    engine.load(source);
    return application.exec();
}
