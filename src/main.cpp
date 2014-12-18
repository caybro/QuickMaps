#include <QApplication>
#include <QQmlApplicationEngine>
#include <QIcon>
#include <QTranslator>
#include <QQmlContext>
#include <QStandardPaths>
#include <QCommandLineParser>
#include <QDebug>

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

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("initialLatitude", parser.isSet("latitude") ? parser.value("latitude").toDouble() : 49.6843842);
    engine.rootContext()->setContextProperty("initialLongitude", parser.isSet("longitude") ? parser.value("longitude").toDouble() : 17.2190358);

    engine.load(QUrl(QStringLiteral("qrc:/main.qml")));

    return app.exec();
}
