TEMPLATE = app

QT += qml quick widgets

SOURCES += main.cpp

lupdate_only{
SOURCES += main.qml
}

RESOURCES += qml.qrc

TRANSLATIONS = translations/quickmaps_cs.ts

# Additional import path used to resolve QML modules in Qt Creator's code model
QML_IMPORT_PATH =

# Default rules for deployment.
include(deployment.pri)
