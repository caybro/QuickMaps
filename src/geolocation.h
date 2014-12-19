#ifndef GEOLOCATION_H
#define GEOLOCATION_H

#include <QObject>
#include <QDBusInterface>
#include <QPointer>

class QString;

class GeoLocation : public QObject
{
    Q_OBJECT
    Q_PROPERTY(double latitude READ latitude NOTIFY locationUpdated)
    Q_PROPERTY(double longitude READ longitude NOTIFY locationUpdated)
    Q_PROPERTY(double accuracy READ accuracy NOTIFY locationUpdated)
    Q_PROPERTY(bool isValid READ isValid NOTIFY locationUpdated)
public:
    explicit GeoLocation(QObject *parent = 0);
    ~GeoLocation();

    double latitude() const;
    double longitude() const;
    double accuracy() const;

    bool isValid() const;

signals:
    void locationUpdated(double latitude, double longitude, double accuracy, const QString & description);

private slots:
    void slotLocationUpdated(const QDBusObjectPath & oldPath, const QDBusObjectPath & newPath);

private:
    void init();
    double m_lat = -1;
    double m_lon = -1;
    double m_acc = -1;
    QString m_desc;
    QDBusInterface m_masterIface;
    QPointer<QDBusInterface> m_clientIface;
};

#endif // GEOLOCATION_H
