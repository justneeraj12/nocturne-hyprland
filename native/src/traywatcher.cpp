#include "traywatcher.h"

#include <QDBusConnection>
#include <QDBusMessage>
#include <QDBusServiceWatcher>
#include <QTimer>

TrayWatcher::TrayWatcher(QObject *parent)
    : QObject(parent)
    , m_watcher(new QDBusServiceWatcher(this))
{
    auto bus = QDBusConnection::sessionBus();
    bus.registerObject(QStringLiteral("/StatusNotifierWatcher"), this,
        QDBusConnection::ExportAllSlots | QDBusConnection::ExportAllSignals | QDBusConnection::ExportAllProperties);
    m_watcher->setConnection(bus);
    m_watcher->setWatchMode(QDBusServiceWatcher::WatchForUnregistration);
    connect(m_watcher, &QDBusServiceWatcher::serviceUnregistered, this, &TrayWatcher::removeService);
    QTimer::singleShot(0, this, &TrayWatcher::claimService);
}

QStringList TrayWatcher::registeredItems() const { return m_items; }
bool TrayWatcher::hostRegistered() const { return true; }
int TrayWatcher::protocolVersion() const { return 0; }

void TrayWatcher::claimService()
{
    auto bus = QDBusConnection::sessionBus();
    if (!bus.registerService(QStringLiteral("org.kde.StatusNotifierWatcher"))) {
        auto *owner = new QDBusServiceWatcher(QStringLiteral("org.kde.StatusNotifierWatcher"), bus,
            QDBusServiceWatcher::WatchForUnregistration, this);
        connect(owner, &QDBusServiceWatcher::serviceUnregistered, this, [this, owner]() {
            owner->deleteLater();
            QTimer::singleShot(80, this, &TrayWatcher::claimService);
        });
        return;
    }
    emit StatusNotifierHostRegistered();
}

void TrayWatcher::RegisterStatusNotifierItem(const QString &serviceOrPath)
{
    QString service = serviceOrPath;
    QString path = QStringLiteral("/StatusNotifierItem");
    if (serviceOrPath.startsWith(QLatin1Char('/'))) {
        service = calledFromDBus() ? message().service() : QString();
        path = serviceOrPath;
    }
    if (service.isEmpty()) return;
    const QString reference = service + path;
    if (m_items.contains(reference)) return;
    m_items.push_back(reference);
    m_watcher->addWatchedService(service);
    emit StatusNotifierItemRegistered(reference);
    emit registeredItemsChanged();
}

void TrayWatcher::RegisterStatusNotifierHost(const QString &service)
{
    Q_UNUSED(service)
    emit StatusNotifierHostRegistered();
}

void TrayWatcher::removeService(const QString &service)
{
    const auto before = m_items;
    m_items.removeIf([&service](const QString &item) { return item.startsWith(service + QLatin1Char('/')); });
    for (const auto &item : before) {
        if (!m_items.contains(item)) emit StatusNotifierItemUnregistered(item);
    }
    if (before != m_items) emit registeredItemsChanged();
}
