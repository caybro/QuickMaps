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

    property string currentSearchField // "start" or "destination"
    property bool directionsMode: goNavigateAction.checked
    property var start: QtPositioning.coordinate()
    property var destination: QtPositioning.coordinate()

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
        print("App name/version: " + Qt.application.name + " " + Qt.application.version)
        print("Platform: " + Qt.platform.os)
        print("Mobile: " + mobile);
        print("Available services: " + plugin.availableServiceProviders)
        print("Actual mapping plugin: " + plugin.name)
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
        anchors.left: parent.left
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
                if (currentSearchField == "" || !directionsMode) {
                    map.removeMapItem(markerPlace);
                    addMarker(currentPlace.coordinate)
                }
                print("Selecting " + currentPlace.address.text + " as " + currentSearchField);
                messageLabel.text = currentPlace.address.text;
                if (currentSearchField == "start") {
                    start = makeCoords(currentPlace)
                } else if (currentSearchField == "destination") {
                    destination = makeCoords(currentPlace)
                }
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
                } else if (event.key === Qt.Key_End) {
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

    ToolButton {
        action: goHomeAction
        z: map.z + 1
        anchors {
            right: parent.right
            bottom: parent.bottom
            margins: 5
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
                //print("Current mouse pos: " + wheel.x + ";" + wheel.y)
                //print("Translated to map coords: " + map.toCoordinate(Qt.point(wheel.x, wheel.y)))
                //map.center = map.toCoordinate(Qt.point(wheel.x, wheel.y)) // TODO need to change the viewport, not center
                if (wheel.angleDelta.y > 0)
                    zoomIn()
                else
                    zoomOut()
            }
            onPressAndHold: {
                if (mouse.button == Qt.RightButton) {
                    //print("Right clicked at: " + map.toCoordinate(Qt.point(mouse.x, mouse.y)))
                    contextMenu.popup()
                }
            }
            onDoubleClicked: {
                if (mouse.button == Qt.LeftButton) { // zoom in
                    zoomIn()
                } else if (mouse.button == Qt.RightButton) { // zoom out
                    zoomOut()
                }
            }

            Menu {
                id: contextMenu
                MenuItem {
                    text: qsTr("What's here?")
                    onTriggered: {
                        //print("Coord: " + map.toCoordinate(Qt.point(mapMouseArea.mouseX, mapMouseArea.mouseY)))
                        currentSearchField = ""
                        geocodeModel.query = map.toCoordinate(Qt.point(mapMouseArea.mouseX, mapMouseArea.mouseY))
                        geocodeModel.update();
                    }
                }
                MenuItem {
                    text: qsTr("Directions from this place")
                    onTriggered: {
                        goNavigateAction.checked = true
                        var here = map.toCoordinate(Qt.point(mapMouseArea.mouseX, mapMouseArea.mouseY))
                        start = here
                        currentSearchField = "start"
                        input.text = printCoords(here)
                    }
                }
                MenuItem {
                    text: qsTr("Directions to this place")
                    onTriggered: {
                        goNavigateAction.checked = true
                        var here = map.toCoordinate(Qt.point(mapMouseArea.mouseX, mapMouseArea.mouseY))
                        destination = here
                        currentSearchField = "destination"
                        inputDestination.text = printCoords(here)
                    }
                }
            }
        }

        MapQuickItem {
            id: markerPlace
            anchorPoint.x: image.width/4
            anchorPoint.y: image.height

            property string messageText

            sourceItem: Image {
                id: image
                source: "qrc:/icons/ic_pin_drop_24px.svg"
            }
        }

        MapQuickItem {
            id: markerStart
            anchorPoint.x: imageStart.width/4
            anchorPoint.y: imageStart.height
            coordinate: start
            visible: start.isValid

            sourceItem: Image {
                id: imageStart
                source: "qrc:/icons/ic_place_24px.svg"
            }
        }

        MapQuickItem {
            id: markerDestination
            anchorPoint.x: imageDest.width/4
            anchorPoint.y: imageDest.height
            coordinate: destination
            visible: destination.isValid

            sourceItem: Image {
                id: imageDest
                source: "qrc:/icons/ic_place_24px.svg"
            }
        }

        MapCircle {
            id: homeCircle
            color: palette.highlight
            opacity: 0.4
            center: QtPositioning.coordinate(GeoLocation.latitude, GeoLocation.longitude)
            radius: GeoLocation.accuracy
            visible: goHomeAction.checked
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
            if (event.key === Qt.Key_Right) {
                pan(10, 0)
            } else if (event.key === Qt.Key_Left) {
                pan(-10, 0)
            } else if (event.key === Qt.Key_Up) {
                pan(0, -10)
            } else if (event.key === Qt.Key_Down) {
                pan(0, 10)
            } else if (event.key === Qt.Key_Plus) {
                zoomIn()
            } else if (event.key === Qt.Key_Minus) {
                zoomOut()
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
                    print ("Got one result from " + currentSearchField)
                    var currentPlace = get(0);
                    print("Selecting " + currentPlace.address.text + " as " + currentSearchField);
                    messageLabel.text = currentPlace.address.text;
                    if (currentSearchField == "" || !directionsMode) {
                        map.removeMapItem(markerPlace);
                        addMarker(currentPlace.coordinate);
                    }
                    if (currentPlace.boundingBox.isValid)
                        map.fitViewportToGeoShape(currentPlace.boundingBox)
                    else
                        map.fitViewportToGeoShape(QtPositioning.circle(makeCoords(currentPlace), 100))
                    if (currentSearchField == "start")
                        start = makeCoords(currentPlace)
                    else if (currentSearchField == "destination")
                        destination = makeCoords(currentPlace)
                    switchToMap()
                } else if (count > 1) {
                    print ("Got " + count + " results from " + currentSearchField)
                    messageLabel.text = qsTranslate("main", "Query returned %n item(s)", "", count)
                    switchToResults()
                } else { // 0 items
                    print ("Got no results from " + currentSearchField)
                    map.removeMapItem(markerPlace);
                    messageLabel.text = qsTranslate("main", "Query returned %n item(s)", "", count)
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
        text: qsTr("&Find")
        tooltip: text.replace('&', '') + " (" + shortcut + ")"
        iconSource: "qrc:/icons/ic_search_24px.svg"
        shortcut: StandardKey.Find
        enabled: false
        onTriggered: {
            geocodeModel.reset()
            var text = currentSearchField == "destination" ? inputDestination.text : input.text
            print("Current query: " + text + " (searching for " + currentSearchField + ")");
            geocodeModel.query = text;
            geocodeModel.update();
        }
    }

    Action {
        id: goBackAction
        text: qsTr("&Back")
        tooltip: text.replace('&', '') + " (" + shortcut + ")"
        iconSource: "qrc:/icons/ic_arrow_back_24px.svg"
        shortcut: StandardKey.Back
        enabled: (map.visible && geocodeModel.count > 1) || !map.visible
        onTriggered: {
            if (map.visible)
                switchToResults()
            else
                switchToMap()
        }
    }

    Action {
        id: goHomeAction
        text: qsTr("My Location")
        tooltip: qsTr("Display my location on the map") + " (" + shortcut + ")"
        iconSource: GeoLocation.isValid ? "qrc:/icons/ic_my_location_24px.svg" : "qrc:/icons/ic_location_searching_24px.svg"
        shortcut: "Ctrl+Home"
        enabled: GeoLocation.isValid
        checkable: true
        onTriggered: {
            if (checked) {
                markerPlace.messageText = messageLabel.text
                messageLabel.text = GeoLocation.description
                map.fitViewportToGeoShape(QtPositioning.circle(homeCircle.center, homeCircle.radius))
            } else {
                messageLabel.text = markerPlace.messageText
                if (directionsMode)
                    map.fitViewportToGeoShape(QtPositioning.circle(markerStart.coordinate, 100))
                else
                    map.fitViewportToGeoShape(QtPositioning.circle(markerPlace.coordinate, 1000))
            }
        }
    }

    Action {
        id: goNavigateAction
        text: qsTr("Directions")
        iconSource: "qrc:/icons/ic_directions_24px.svg"
        checkable: true
    }

    Action {
        id: fullscreenAction
        text: qsTr("View &Fullscreen")
        tooltip: text.replace('&', '') + " (" + shortcut + ")"
        iconSource: checked ? "qrc:/icons/ic_fullscreen_exit_24px.svg" : "qrc:/icons/ic_fullscreen_24px.svg"
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
            TextField {
                id: input
                Layout.fillWidth: true
                placeholderText: directionsMode ? qsTr("Start") : qsTr("Search for places, addresses and locations")
                onAccepted: {
                    if (text != "") {
                        start = QtPositioning.coordinate()
                        currentSearchField = "start"
                        goAction.trigger()
                    }
                }
                onTextChanged: {
                    goAction.enabled = text != "" && geocodeModel.status != GeocodeModel.Loading
                }
                Image {
                    anchors.right: parent.right
                    anchors.margins: 3
                    source: "qrc:/icons/ic_done_24px.svg"
                    visible: start.isValid
                }
                Image {
                    anchors.right: parent.right
                    anchors.margins: 3
                    source: "qrc:/icons/ic_warning_24px.svg"
                    visible: input.text != "" && geocodeModel.count == 0
                             && currentSearchField == "start" && geocodeModel.status == GeocodeModel.Ready
                }
            }
            ToolButton {
                id: switchButton
                iconSource: "qrc:/icons/ic_swap_horiz_24px.svg"
                visible: directionsMode
                text: qsTr("Swap")
                tooltip: qsTr("Swap Start and Destination")
                enabled: start.isValid || destination.isValid
                onClicked: {
                    var tmpLoc = start;
                    start = destination;
                    destination = tmpLoc;
                    var tmpText = input.text;
                    input.text = inputDestination.text;
                    inputDestination.text = tmpText;
                }
            }
            TextField {
                id: inputDestination
                Layout.fillWidth: true
                placeholderText: qsTr("Destination")
                visible: directionsMode
                onAccepted: {
                    if (text != "") {
                        if (directionsMode) {
                            destination = QtPositioning.coordinate()
                            currentSearchField = "destination"
                        }
                        goAction.trigger()
                    }
                }
                onTextChanged: {
                    goAction.enabled = text != "" && geocodeModel.status != GeocodeModel.Loading
                }
                Image {
                    anchors.right: parent.right
                    anchors.margins: 3
                    source: "qrc:/icons/ic_done_24px.svg"
                    visible: destination.isValid
                }
                Image {
                    anchors.right: parent.right
                    anchors.margins: 3
                    source: "qrc:/icons/ic_warning_24px.svg"
                    visible: input.text != "" && geocodeModel.count == 0 &&
                             currentSearchField == "destination" && geocodeModel.status == GeocodeModel.Ready
                }
            }
            ToolButton {
                id: goButton
                action: goAction
                visible: !directionsMode

                BusyIndicator {
                    running: geocodeModel.status == GeocodeModel.Loading
                    anchors.fill: parent
                }
            }
            ToolButton {
                id: directionsButton
                action: goNavigateAction

            }
            Item { Layout.preferredWidth: 10 }
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
                Layout.fillWidth: true
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
        markerPlace.coordinate = coord
        map.addMapItem(markerPlace);
        print("Added marker for place: " + printCoords(coord))
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

    function makeCoords(place) {
        return QtPositioning.coordinate(place.coordinate.latitude, place.coordinate.longitude)
    }

    function printCoords(coord) {
        return coord.latitude + "," + coord.longitude
    }

    function zoomIn() {
        map.zoomLevel += 1
    }

    function zoomOut() {
        map.zoomLevel -= 1
    }
}
