/*
    Copyright (C) 2014 Lukáš Tinkl <lukas@kde.org>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

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
    Q_PROPERTY(QString description READ description NOTIFY locationUpdated)

public:
    explicit GeoLocation(QObject *parent = 0);
    ~GeoLocation();

    double latitude() const;
    double longitude() const;
    double accuracy() const;
    QString description() const;

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
