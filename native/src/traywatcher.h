#pragma once

#include <QDBusContext>
#include <QObject>
#include <QStringList>

class QDBusServiceWatcher;

class TrayWatcher final : public QObject, protected QDBusContext
{
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.kde.StatusNotifierWatcher")
    Q_PROPERTY(QStringList RegisteredStatusNotifierItems READ registeredItems NOTIFY registeredItemsChanged)
    Q_PROPERTY(bool IsStatusNotifierHostRegistered READ hostRegistered CONSTANT)
    Q_PROPERTY(int ProtocolVersion READ protocolVersion CONSTANT)

public:
    explicit TrayWatcher(QObject *parent = nullptr);
    QStringList registeredItems() const;
    bool hostRegistered() const;
    int protocolVersion() const;

public slots:
    Q_SCRIPTABLE void RegisterStatusNotifierItem(const QString &serviceOrPath);
    Q_SCRIPTABLE void RegisterStatusNotifierHost(const QString &service);

signals:
    Q_SCRIPTABLE void StatusNotifierItemRegistered(const QString &service);
    Q_SCRIPTABLE void StatusNotifierItemUnregistered(const QString &service);
    Q_SCRIPTABLE void StatusNotifierHostRegistered();
    Q_SCRIPTABLE void StatusNotifierHostUnregistered();
    void registeredItemsChanged();

private slots:
    void claimService();
    void removeService(const QString &service);

private:
    QStringList m_items;
    QDBusServiceWatcher *m_watcher = nullptr;
};
