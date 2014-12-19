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

import QtQuick 2.4
import QtQuick.Controls 1.2
import QtQuick.Layouts 1.1
import QtQuick.Window 2.2
//import QtQuick.Dialogs 1.2
import QtLocation 5.3
import QtPositioning 5.2
import Qt.labs.settings 1.0

ApplicationWindow {
    id: mainWindow
    visible: true
    width: 640
    height: 480
    title: "Quick Maps"

    property bool mobile: ["android", "ios", "blackberry", "wince"].some(function(element) {
        return element === Qt.platform.os;
    });

    Settings {
        id: settings
        // save window size and position
        property alias x: mainWindow.x
        property alias y: mainWindow.y
        property alias width: mainWindow.width
        property alias height: mainWindow.height
        // startup coords
        property real latitude: initialLatitude
        property real longitude: initialLongitude
        // zoom level
        property alias zoom: map.zoomLevel
    }

    Component.onCompleted: {
        print("Platform: " + Qt.platform.os)
        print("Mobile: " + mobile);
        print("Available services: " + plugin.availableServiceProviders)
        print("Actual plugin: " + plugin.name)
        print("Min/max zooms: " + map.minimumZoomLevel + "/" + map.maximumZoomLevel)
        print("Supports online maps: " + plugin.supportsMapping(Plugin.OnlineMappingFeature))
        print("Supports offline maps: " + plugin.supportsMapping(Plugin.OfflineMappingFeature))
        print("Supports localized maps: " + plugin.supportsMapping(Plugin.LocalizedMappingFeature))
        print("Supports online routing: " + plugin.supportsRouting(Plugin.OnlineRoutingFeature))
        print("Supports localized routing: " + plugin.supportsRouting(Plugin.LocalizedRoutingFeature))
        print("Supports dynamic routing, based on current position: " + plugin.supportsRouting(Plugin.RouteUpdatesFeature))
        print("Supports routing alternatives: " + plugin.supportsRouting(Plugin.AlternativeRoutesFeature))

        var maps = map.supportedMapTypes;
        print("Supported map types: " + maps.length)
        for (var i = 0; i < maps.length; i++){
            print(maps[i].name + " (" + maps[i].description + ")");
            print("\tNight mode: " + maps[i].night + ", mobile: " + maps[i].mobile)
            if (mobile) {
                if (maps[i].mobile) {
                    mapTypeModel.append({"name": maps[i].name, "data": maps[i]});
                }
            } else {
                mapTypeModel.append({"name": maps[i].name, "data": maps[i]});
            }
        }

        map.forceActiveFocus()
    }

    SystemPalette {
        id: palette
    }

    Plugin {
        id: plugin
        preferred: ["nokia", "osm"]
        PluginParameter { name: "app_id"; value: "KvjgeyL7z4SoEo3WpDlr" }
        PluginParameter { name: "token"; value: "silNtd28g7LA6L_hSDwBMQ" }
        PluginParameter { name: "useragent"; value: "QuickMaps" }
    }

    Plugin {
        id: geocodePlugin
        name: "osm" // the nokia geocode plugin seems to always return only 1 result...
        PluginParameter { name: "useragent"; value: "QuickMaps" }
    }

    ListModel {
        id: mapTypeModel
    }

    ComboBox {
        id: mapTypeCombo
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 5
        model: mapTypeModel
        textRole: "name"
        z: map.z + 1
        visible: map.visible
        implicitWidth: 200
        onCurrentIndexChanged: {
            if (currentText != "") {
                map.activeMapType = model.get(currentIndex).data
                map.update()
            }
        }
    }

    ScrollView {
        id: resultsScrollView
        anchors.fill: parent

        ListView {
            id: resultsView
            focus: true
            model: geocodeModel
            delegate: placeDelegate
            highlight: highlightDelegate
            highlightFollowsCurrentItem: false
            spacing: 5
            clip: true
            section.property: "locationData.address.country"
            section.delegate: sectionHeading

            function selectPlace(index) {
                var currentPlace = model.get(currentIndex);
                map.clearMapItems();
                print("Selecting " + currentPlace.address.text);
                messageLabel.text = currentPlace.address.text;
                addMarker(currentPlace.coordinate);
                map.fitViewportToGeoShape(currentPlace.boundingBox)
                switchToMap()
            }

            Keys.onPressed: {
                if (event.key === Qt.Key_Up) {
                    decrementCurrentIndex()
                } else if (event.key === Qt.Key_Down) {
                    incrementCurrentIndex()
                } else if (event.key === Qt.Key_Home) {
                    currentIndex = 0
                } else if (event.key == Qt.Key_End) {
                    currentIndex = count - 1
                } else if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                    print("Activated item at index: " + currentIndex)
                    if (currentIndex != -1) {
                        selectPlace(currentIndex)
                    }
                } else if (event.key === Qt.Key_Escape) {
                    switchToMap()
                }
            }

            MouseArea {
                anchors.fill: parent
                focus: true
                onClicked: {
                    resultsView.currentIndex = resultsView.indexAt(mouse.x, mouse.y) // FIXME
                }
                onDoubleClicked: {
                    resultsView.selectPlace(resultsView.currentIndex)
                }
            }

            Component {
                id: placeDelegate
                Column {
                    spacing: 5
                    Text {
                        id: locationDelegate
                        text: locationData.address.text;
                    }
                    Text {
                        text: locationData.coordinate.latitude + ", "
                              + locationData.coordinate.longitude
                        font.pointSize: locationDelegate.font.pointSize - 2
                    }
                }
            }

            Component {
                id: highlightDelegate
                Rectangle {
                    width: resultsView.currentItem.width; height: resultsView.currentItem.height
                    color: palette.highlight; radius: 5
                    y: resultsView.currentItem.y
                    Behavior on y {
                        SpringAnimation {
                            spring: 4
                            damping: 0.2
                        }
                    }
                }
            }

            Component {
                id: sectionHeading
                Rectangle {
                    width: ListView.width
                    height: childrenRect.height
                    color: "lightsteelblue"

                    Text {
                        text: section
                        font.bold: true
                        font.pixelSize: 15
                    }
                }
            }

            Component.onCompleted: {
                currentIndex = 0;
            }
        }
    }

    Map {
        id: map
        anchors.fill: parent
        plugin: plugin
        focus: true

        MouseArea {
            id: mapMouseArea
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onWheel: {
                print("Current mouse pos: " + wheel.x + ";" + wheel.y)
                print("Translated to map coords: " + map.toCoordinate(Qt.point(wheel.x, wheel.y)))
                //map.center = map.toCoordinate(Qt.point(wheel.x, wheel.y)) // TODO need to change the viewport, not center
                if (wheel.angleDelta.y > 0)
                    map.zoomLevel += 1
                else
                    map.zoomLevel -= 1
            }
            onDoubleClicked: {
                if (mouse.button == Qt.LeftButton) { // zoom in
                    map.zoomLevel += 1
                } else if (mouse.button == Qt.RightButton) { // zoom out
                    map.zoomLevel -= 1
                }
            }
        }

        MapQuickItem {
            id: marker
            anchorPoint.x: image.width/4
            anchorPoint.y: image.height

            sourceItem: Image {
                id: image
                source: "qrc:/marker.png"
            }
        }

        MapCircle {
            id: homeCircle
            color: "lightblue"
            opacity: 0.4
        }

        Component.onDestruction: {
            settings.latitude = map.center.latitude
            settings.longitude = map.center.longitude
        }

        Component.onCompleted: {
            map.center.latitude = settings.latitude
            map.center.longitude = settings.longitude
        }

        Keys.onPressed: {
            if (event.key == Qt.Key_Right) {
                pan(10, 0)
            } else if (event.key == Qt.Key_Left) {
                pan(-10, 0)
            } else if (event.key == Qt.Key_Up) {
                pan(0, 10)
            } else if (event.key == Qt.Key_Down) {
                pan(0, -10)
            } else if (event.key == Qt.Key_Plus) {
                zoomLevel += 1
            } else if (event.key == Qt.Key_Minus) {
                zoomLevel -= 1
            }
        }
    }

    GeocodeModel {
        id: geocodeModel
        plugin: geocodePlugin
        autoUpdate: false
        limit: 50

        onStatusChanged: {
            if (status == GeocodeModel.Ready) {
                print("Query returned " + count + " items")
                if (count == 1) {
                    var currentPlace = get(0);
                    map.clearMapItems();
                    print("Selecting " + currentPlace.address.text);
                    messageLabel.text = currentPlace.address.text;
                    addMarker(currentPlace.coordinate);
                    map.fitViewportToGeoShape(currentPlace.boundingBox)
                    switchToMap()
                } else if (count > 1) {
                    messageLabel.text = qsTranslate("main", "Query returned %n item(s)", "", count)
                    switchToResults()
                }
            } else if (status == GeocodeModel.Error) {
                print("Query error: " + errorString + " (" + error + ")")
            }
        }
    }

    Action {
        id: quitAction
        text: qsTr("&Quit")
        tooltip: qsTr("Exit Application") + " (" + shortcut + ")"
        iconName: "application-exit"
        shortcut: StandardKey.Quit
        onTriggered: Qt.quit();
    }

    Action {
        id: goAction
        text: qsTr("&Go")
        tooltip: text.replace('&', '') + " (" + shortcut + ")"
        iconName: "go-jump-locationbar"
        shortcut: "Ctrl+G"
        enabled: input.text != ""
        onTriggered: {
            geocodeModel.reset();
            print("Current query: " + input.text);
            geocodeModel.query = input.text;
            geocodeModel.update();
        }
    }

    Action {
        id: goBackAction
        text: qsTr("&Back")
        tooltip: text.replace('&', '') + " (" + shortcut + ")"
        iconName: "go-previous"
        shortcut: StandardKey.Back
        enabled: (map.visible && geocodeModel.count > 0) || !map.visible
        onTriggered: {
            if (map.visible)
                switchToResults()
            else
                switchToMap()
        }
    }

    Action {
        id: goHomeAction
        text: qsTr("&Home")
        tooltip: text.replace('&', '') + " (" + shortcut + ")"
        iconName: "go-home"
        shortcut: "Ctrl+Home"
        enabled: GeoLocation.isValid
        onTriggered: {
            map.clearMapItems()
            addCircle(QtPositioning.coordinate(GeoLocation.latitude, GeoLocation.longitude), GeoLocation.accuracy)
            map.fitViewportToMapItems()
            messageLabel.text = ""
        }
    }

    Action {
        id: fullscreenAction
        text: qsTr("View &Fullscreen")
        tooltip: text.replace('&', '') + " (" + shortcut + ")"
        iconName: "view-fullscreen"
        shortcut: "F11"
        checkable: true
        checked: mainWindow.visibility == Window.FullScreen
        onTriggered: toggleFullscreen()
        enabled: !mobile
    }

    toolBar: ToolBar {
        //visible: mainWindow.visibility != Window.FullScreen
        RowLayout {
            anchors.fill: parent

            ToolButton {
                action: goBackAction
            }
            Item { Layout.preferredWidth: 10 }
            Label {
                text: qsTr("Query:")
            }
            TextField {
                id: input
                Layout.fillWidth: true
                onAccepted: {
                    if (text != "") {
                        goAction.trigger()
                    }
                }
            }
            ToolButton {
                id: goButton
                action: goAction

                BusyIndicator {
                    running: geocodeModel.status == GeocodeModel.Loading
                    anchors.fill: parent
                }
            }
            Item { Layout.preferredWidth: 10 }
            ToolButton {
                action: goHomeAction
            }
            ToolButton {
                action: fullscreenAction
                visible: !mobile
            }
        }
    }

    statusBar: StatusBar {
        id: statusBar
        visible: !fullscreenAction.checked
        RowLayout {
            anchors.fill: parent
            Label {
                id: messageLabel
                elide: Text.ElideMiddle
            }
            Label {
                id: posLabel
                visible: map.visible
                text: map.center.latitude.toFixed(4) + ", " + map.center.longitude.toFixed(4) + " (@" + map.zoomLevel + ")"
                Layout.alignment: Qt.AlignRight
            }
        }
    }

    function toggleFullscreen() {
        if (mainWindow.visibility == Window.FullScreen)
            mainWindow.visibility = Window.Windowed
        else {
            mainWindow.visibility = Window.FullScreen
            map.forceActiveFocus()
        }
    }

    function addMarker(coord) {
        marker.coordinate = coord
        map.addMapItem(marker);
        print("Added marker for location: " + coord.latitude + "," + coord.longitude)
    }

    function addCircle(coord, radius) {
        homeCircle.center = coord;
        homeCircle.radius = radius;
        map.addMapItem(homeCircle);
        print("Added circle for home location: " + coord.latitude + "," + coord.longitude + " and radius: " + radius)
    }

    function switchToResults() {
        map.visible = false
        resultsView.visible = true
        resultsView.forceActiveFocus()
    }

    function switchToMap() {
        resultsView.visible = false
        map.visible = true
        map.forceActiveFocus()
    }
}
