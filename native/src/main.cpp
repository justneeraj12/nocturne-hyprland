#include "backend.h"

#include <QGuiApplication>
#include <QLocalServer>
#include <QLocalSocket>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QTimer>
#include <iostream>
#include <unistd.h>

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
