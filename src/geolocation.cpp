#include <QDBusReply>
#include <QDBusObjectPath>
#include <QDBusConnectionInterface>
#include <QDebug>

#include "geolocation.h"

#define GEOCLUE_MASTER "org.freedesktop.GeoClue2"
#define GEOCLUE_MASTER_PATH "/org/freedesktop/GeoClue2/Manager"
#define GEOCLUE_MASTER_IFACE GEOCLUE_MASTER".Manager"
#define GEOCLUE_CLIENT_IFACE GEOCLUE_MASTER".Client"
#define GEOCLUE_LOCATION_IFACE GEOCLUE_MASTER".Location"
#define DBUS_INTERFACE_PROPS "org.freedesktop.DBus.Properties"

GeoLocation::GeoLocation(QObject *parent)
    : QObject(parent),
      m_masterIface(GEOCLUE_MASTER, GEOCLUE_MASTER_PATH, GEOCLUE_MASTER_IFACE, QDBusConnection::systemBus(), this),
      m_clientIface(Q_NULLPTR)
{
    if (QDBusConnection::systemBus().interface()->isServiceRegistered(GEOCLUE_MASTER)) {
        QDBusConnection::systemBus().interface()->startService(GEOCLUE_MASTER);
    }

    init();
}

GeoLocation::~GeoLocation()
{
    if (!m_clientIface.isNull()) {
        m_clientIface->call("Stop");
    }
    m_clientIface.clear();
}

void GeoLocation::init()
{
    QDBusReply<QDBusObjectPath> clientPath = m_masterIface.asyncCall("GetClient");
    if (clientPath.isValid()) {
        const QString path = clientPath.value().path();
        qDebug() << "Got client path" << path;
        m_clientIface = new QDBusInterface(GEOCLUE_MASTER, path, GEOCLUE_CLIENT_IFACE, QDBusConnection::systemBus());
        m_clientIface->setProperty("DesktopId", "QuickMaps");
        m_clientIface->setProperty("DistanceThreshold", 500); // in meters
        m_clientIface->setProperty("RequestedAccuracyLevel", 8); // city

        if (!QDBusConnection::systemBus().connect(GEOCLUE_MASTER, path, GEOCLUE_CLIENT_IFACE,
                                                  QStringLiteral("LocationUpdated"), this,
                                                  SLOT(slotLocationUpdated(QDBusObjectPath,QDBusObjectPath)))) {
            qCritical() << Q_FUNC_INFO << "Error connecting to location updates via dbus";
        }
        QDBusReply<void> startReply = m_clientIface->asyncCall("Start");
        if (!startReply.isValid()) {
            qWarning() << Q_FUNC_INFO << "Failed to start the client" << startReply.error().message();
        }
    } else {
        qCritical() << Q_FUNC_INFO << "Couldn't obtain valid client path";
    }
}

double GeoLocation::accuracy() const
{
    return m_acc;
}

bool GeoLocation::isValid() const
{
    return m_lat != -1 && m_lon != -1;
}

double GeoLocation::latitude() const
{
    return m_lat;
}

double GeoLocation::longitude() const
{
    return m_lon;
}

void GeoLocation::slotLocationUpdated(const QDBusObjectPath &oldPath, const QDBusObjectPath &newPath)
{
    Q_UNUSED(oldPath)
    const QString path = newPath.path();
    qDebug() << "Got new location" << newPath.path();

    QDBusInterface locIface(GEOCLUE_MASTER, path, GEOCLUE_LOCATION_IFACE, QDBusConnection::systemBus());
    if (!locIface.isValid()) {
        qWarning() << "Location iface not valid!";
        return;
    }

    QVariant lat = locIface.property("Latitude");
    if (lat.isValid())
        m_lat = lat.toDouble();

    QVariant lon = locIface.property("Longitude");
    if (lon.isValid())
        m_lon = lon.toDouble();

    QVariant acc = locIface.property("Accuracy");
    if (acc.isValid())
        m_acc = acc.toDouble();

    QVariant desc = locIface.property("Description");
    if (desc.isValid())
        m_desc = desc.toString();

    qDebug() << "New location:" << lat << lon << acc << desc;

    if (lat.isValid() && lon.isValid()) {
        emit locationUpdated(m_lat, m_lon, m_acc, m_desc);
    }
}
