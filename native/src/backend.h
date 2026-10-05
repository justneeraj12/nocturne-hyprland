#pragma once

#include <QObject>
#include <QSet>
#include <QScreen>
#include <QString>
#include <QVariant>
#include <memory>

class TrayWatcher;
class QFileSystemWatcher;
class QLocalSocket;
class QProcess;
class QTimer;

class Backend final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString surface READ surface NOTIFY surfaceChanged)
    Q_PROPERTY(QString page READ page NOTIFY pageChanged)
    Q_PROPERTY(QString home READ home CONSTANT)
    Q_PROPERTY(QString runtime READ runtime CONSTANT)
    Q_PROPERTY(QScreen *targetScreen READ targetScreen NOTIFY targetScreenChanged)
    Q_PROPERTY(QVariantList screens READ screens NOTIFY screensChanged)
    Q_PROPERTY(QString baseColor READ baseColor NOTIFY paletteChanged)
    Q_PROPERTY(QString surfaceColor READ surfaceColor NOTIFY paletteChanged)
    Q_PROPERTY(QString overlayColor READ overlayColor NOTIFY paletteChanged)
    Q_PROPERTY(QString lineColor READ lineColor NOTIFY paletteChanged)
    Q_PROPERTY(QString textColor READ textColor NOTIFY paletteChanged)
    Q_PROPERTY(QString mutedColor READ mutedColor NOTIFY paletteChanged)
    Q_PROPERTY(QString accentColor READ accentColor NOTIFY paletteChanged)
    Q_PROPERTY(QString accent2Color READ accent2Color NOTIFY paletteChanged)

public:
    explicit Backend(QString surface, QString page, QObject *parent = nullptr);
    ~Backend() override;

    QString surface() const;
    QString page() const;
    QString home() const;
    QString runtime() const;
    QScreen *targetScreen() const;
    QVariantList screens() const;
    QString baseColor() const;
    QString surfaceColor() const;
    QString overlayColor() const;
    QString lineColor() const;
    QString textColor() const;
    QString mutedColor() const;
    QString accentColor() const;
    QString accent2Color() const;

    Q_INVOKABLE QString run(const QVariantList &arguments, int timeoutMs = 5000) const;
    Q_INVOKABLE QVariant json(const QVariantList &arguments, int timeoutMs = 5000) const;
    Q_INVOKABLE QVariantList audioStreams() const;
    Q_INVOKABLE bool microphoneInUse() const;
    Q_INVOKABLE bool screenSharing() const;
    Q_INVOKABLE QVariantList windowItems() const;
    Q_INVOKABLE bool windowAction(const QString &address, const QString &action, int workspace = 0) const;
    Q_INVOKABLE QVariantList privacyItems() const;
    Q_INVOKABLE bool stopPrivacyClient(int pid) const;
    Q_INVOKABLE QVariantList applications(const QString &query = QString()) const;
    Q_INVOKABLE QVariantList launcherResults(const QString &query = QString(),
        const QString &mode = QStringLiteral("all")) const;
    Q_INVOKABLE bool activateLauncherResult(const QVariantMap &result);
    Q_INVOKABLE QVariantList trayItems() const;
    Q_INVOKABLE QVariantList trayMenu(const QString &reference) const;
    Q_INVOKABLE bool activateTrayMenuItem(const QString &reference, int id) const;
    Q_INVOKABLE QVariantList notifications(const QString &collection = QStringLiteral("list")) const;
    Q_INVOKABLE int notificationCount() const;
    Q_INVOKABLE QVariantList clipboardItems(const QString &query = QString()) const;
    Q_INVOKABLE QVariantList wallpapers() const;
    Q_INVOKABLE bool launchApplication(const QString &desktopFile);
    Q_INVOKABLE bool toggleFavorite(const QString &desktopFile);
    Q_INVOKABLE bool copyText(const QString &text) const;
    Q_INVOKABLE bool activateTrayItem(const QString &reference, const QString &action = QStringLiteral("activate")) const;
    Q_INVOKABLE bool copyClipboardItem(const QString &entry) const;
    Q_INVOKABLE bool start(const QVariantList &arguments) const;
    Q_INVOKABLE QString readText(const QString &path) const;
    Q_INVOKABLE QString readFirst(const QString &directory, const QString &fileName) const;
    Q_INVOKABLE bool writeText(const QString &path, const QString &contents) const;
    Q_INVOKABLE int rightMargin(int width) const;
    Q_INVOKABLE void refreshTheme();
    Q_INVOKABLE void close();

    void dispatch(const QString &surface, const QString &page);

signals:
    void surfaceChanged();
    void pageChanged();
    void targetScreenChanged();
    void screensChanged();
    void paletteChanged();
    void shellEvent(const QString &topic);

private slots:
    void onPropertiesChanged(const QString &interface, const QVariantMap &changed,
        const QStringList &invalidated);
    void reconnectHyprEvents();
    void readHyprEvents();
    void startAudioEvents();

private:
    static QStringList stringList(const QVariantList &arguments);
    void updateTargetScreen();
    void startShellEvents();
    void ensureApplications() const;
    void queueShellEvent(const QString &topic, int delayMs = 140);
    void flushShellEvents();
    QString paletteValue(const QString &name, const QString &fallback) const;

    QString m_surface;
    QString m_page;
    QScreen *m_targetScreen = nullptr;
    mutable QVariantList m_applications;
    mutable bool m_applicationsLoaded = false;
    std::unique_ptr<TrayWatcher> m_trayWatcher;
    std::unique_ptr<QLocalSocket> m_hyprEvents;
    std::unique_ptr<QProcess> m_audioEvents;
    std::unique_ptr<QFileSystemWatcher> m_fileEvents;
    QTimer *m_eventTimer = nullptr;
    QSet<QString> m_pendingShellEvents;
    QByteArray m_hyprBuffer;
    QByteArray m_audioBuffer;
    bool m_shuttingDown = false;
};
