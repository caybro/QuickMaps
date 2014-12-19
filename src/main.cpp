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

#include <QApplication>
#include <QQmlApplicationEngine>
#include <QIcon>
#include <QTranslator>
#include <QQmlContext>
#include <QStandardPaths>
#include <QCommandLineParser>
#include <QDebug>

#include "geolocation.h"

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);
    app.setWindowIcon(QIcon(":/osm.png"));
    app.setOrganizationName("KDE");
    app.setOrganizationDomain("kde.org");
    app.setApplicationName("QuickMaps");
    app.setApplicationVersion("0.1");

    QTranslator appTrans;
    appTrans.load(QStringLiteral(":/translations/quickmaps_") + QLocale::system().name());
    app.installTranslator(&appTrans);

    QCommandLineParser parser;
    parser.setApplicationDescription(QApplication::tr("Simple maps application based on QML") + "\n(c) 2014 Lukáš Tinkl <lukas@kde.org>");
    parser.addHelpOption();
    parser.addVersionOption();
    parser.addOption(QCommandLineOption("latitude",
                                        QApplication::tr("Latitude to start with, in decimal degrees"),
                                        "latitude"));
    parser.addOption(QCommandLineOption("longitude",
                                        QApplication::tr("Longitude to start with, in decimal degrees"),
                                        "longitude"));
    parser.process(app);

    GeoLocation * loc = new GeoLocation(qApp);

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("initialLatitude", parser.isSet("latitude") ? parser.value("latitude").toDouble() : 49.6843842);
    engine.rootContext()->setContextProperty("initialLongitude", parser.isSet("longitude") ? parser.value("longitude").toDouble() : 17.2190358);
    engine.rootContext()->setContextProperty("GeoLocation", loc);

    engine.load(QUrl(QStringLiteral("qrc:/main.qml")));

    return app.exec();
}
