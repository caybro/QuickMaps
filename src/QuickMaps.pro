TEMPLATE = app

CONFIG += c++11

QT += qml quick widgets dbus

SOURCES += main.cpp \
    geolocation.cpp

lupdate_only{
SOURCES += main.qml
}

RESOURCES += qml.qrc

TRANSLATIONS = translations/quickmaps_cs.ts

# Additional import path used to resolve QML modules in Qt Creator's code model
QML_IMPORT_PATH =

# Default rules for deployment.
include(deployment.pri)

HEADERS += \
    geolocation.h

VERSION = 0.1
DEFINES     += VERSION_NUMBER=\\\"$${VERSION}\\\"
