#pragma once

#include <QObject>
#include <QScreen>
#include <QVariant>

class Backend final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString surface READ surface NOTIFY surfaceChanged)
    Q_PROPERTY(QString page READ page NOTIFY pageChanged)
    Q_PROPERTY(QString home READ home CONSTANT)
    Q_PROPERTY(QString runtime READ runtime CONSTANT)
    Q_PROPERTY(QScreen *targetScreen READ targetScreen NOTIFY targetScreenChanged)
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

    QString surface() const;
    QString page() const;
    QString home() const;
    QString runtime() const;
    QScreen *targetScreen() const;
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
    Q_INVOKABLE QVariantList wallpapers() const;
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
    void paletteChanged();

private:
    static QStringList stringList(const QVariantList &arguments);
    void updateTargetScreen();
    QString paletteValue(const QString &name, const QString &fallback) const;

    QString m_surface;
    QString m_page;
    QScreen *m_targetScreen = nullptr;
};
