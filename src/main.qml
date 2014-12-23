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
import QtLocation 5.3
import QtPositioning 5.2
import Qt.labs.settings 1.0

import "qrc:/"

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
        print("Supports offline routing: " + plugin.supportsRouting(Plugin.OfflineRoutingFeature))
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
        name: "osm" // BUG the nokia geocode plugin seems to always return only 1 result...
        PluginParameter { name: "useragent"; value: "QuickMaps" }
    }

    SplitView {
        id: splitView
        anchors.fill: parent

        ResultsView {
            id: resultsView
        }

        QuickMap {
            id: map
            plugin: plugin

            ComboBox {
                id: mapTypeCombo
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.margins: 5
                model: mapTypeModel
                textRole: "name"
                z: parent.z + 1
                visible: parent.visible
                implicitWidth: 200
                onActivated: {
                    map.activeMapType = model.get(index).data
                    map.update()
                }
            }

            MapItemView {
                id: mapItemView
                model: routing
                delegate: MapRoute {
                    route: routeData
                    line.color: "maroon"
                    line.width: 5
                    smooth: true
                    opacity: 0.7
                }
            }
        }
    }

    QuickGeocodeModel {
        id: geocodeModel
    }

    QuickRouting {
        id: routing
        plugin: plugin
        query: routeQuery
    }

    RouteQuery {
        id: routeQuery
        travelModes: RouteQuery.CarTravel
        routeOptimizations: RouteQuery.FastestRoute
        //numberAlternativeRoutes: 2
    }

    ListModel {
        id: mapTypeModel
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

    Button {
        id: zoomOutButton
        z: map.z + 1
        iconSource: "qrc:/icons/ic_remove_24px.svg"
        enabled: map.zoomLevel > map.minimumZoomLevel
        tooltip: qsTr("Zoom Out")
        anchors {
            right: parent.right
            top: zoomInButton.bottom
            margins: 5
        }
        onClicked: map.zoomOut()
        opacity: hovered ? 0.9 : 0.4
    }

    Button {
        id: zoomInButton
        z: map.z + 1
        iconSource: "qrc:/icons/ic_add_24px.svg"
        enabled: map.zoomLevel < map.maximumZoomLevel
        tooltip: qsTr("Zoom In")
        anchors {
            right: parent.right
            top: parent.top
            margins: 5
        }
        onClicked: map.zoomIn()
        opacity: hovered ? 0.9 : 0.4
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
                map.markerPlace.messageText = messageLabel.text
                messageLabel.text = GeoLocation.description
                map.fitViewportToGeoShape(QtPositioning.circle(map.homeCircle.center, map.homeCircle.radius))
            } else {
                messageLabel.text = map.markerPlace.messageText
                if (directionsMode)
                    map.fitViewportToGeoShape(QtPositioning.circle(map.markerStart.coordinate, 100))
                else
                    map.fitViewportToGeoShape(QtPositioning.circle(map.markerPlace.coordinate, 1000))
            }
        }
    }

    Action {
        id: goNavigateAction
        text: qsTr("Directions")
        iconSource: "qrc:/icons/ic_directions_24px.svg"
        checkable: true
        onCheckedChanged: {
            if (!checked) {
                map.clearMapItems()
                routing.reset()
            }
        }
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
                BusyIndicator {
                    running: geocodeModel.status == GeocodeModel.Loading && currentSearchField == "start"
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    height: parent.childrenRect.height - 5
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
                BusyIndicator {
                    running: geocodeModel.status == GeocodeModel.Loading && currentSearchField == "destination"
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    height: parent.childrenRect.height - 5
                }
            }
            ToolButton {
                id: goButton
                action: goAction
                visible: !directionsMode
            }
            ToolButton {
                id: directionsButton
                action: goNavigateAction
            }
            ToolButton {
                id: directionsModeButton
                iconSource: directionsGroup.current.iconSource
                tooltip: directionsGroup.current.text
                visible: directionsMode
                enabled: start.isValid && destination.isValid
                menu: directionsModeMenu

                BusyIndicator {
                    running: routing.status == RouteModel.Loading
                    anchors.fill: parent
                }
            }
            Item { Layout.preferredWidth: 10 }
            ToolButton {
                action: fullscreenAction
                visible: !mobile
            }
        }
    }

    Menu {
        id: directionsModeMenu
        ExclusiveGroup {
            id: directionsGroup
            current: carModeItem
        }
        MenuItem {
            id: carModeItem
            text: qsTr("Drive")
            iconSource: "qrc:/icons/ic_directions_car_24px.svg"
            exclusiveGroup: directionsGroup
            onTriggered: {
                directionsGroup.current = carModeItem
                print("Go by car!!!")
                routing.reset()
                routeQuery.clearWaypoints()
                routeQuery.travelModes = RouteQuery.CarTravel
                print("Adding " + printCoords(start) + " as start")
                routeQuery.addWaypoint(start)
                print("Adding " + printCoords(destination) + " as destination")
                routeQuery.addWaypoint(destination)
                routing.update()
            }
        }
        MenuItem {
            id: pedestrianModeItem
            text: qsTr("Walk")
            iconSource: "qrc:/icons/ic_directions_walk_24px.svg"
            exclusiveGroup: directionsGroup
            onTriggered: {
                directionsGroup.current = pedestrianModeItem
                print("Walk!!!")
                routing.reset()
                routeQuery.clearWaypoints()
                routeQuery.travelModes = RouteQuery.PedestrianTravel
                print("Adding " + printCoords(start) + " as start")
                routeQuery.addWaypoint(start)
                print("Adding " + printCoords(destination) + " as destination")
                routeQuery.addWaypoint(destination)
                routing.update()
            }
        }
        //        MenuItem { // BUG broken in here.com
        //            id: bicycleModeItem
        //            text: qsTr("Bicycle directions")
        //            iconSource: "qrc:/icons/ic_directions_bike_24px.svg"
        //            exclusiveGroup: directionsGroup
        //            onTriggered: {
        //                directionsGroup.current = bicycleModeItem
        //                print("Bike!!!")
        //                routing.reset()
        //                routeQuery.clearWaypoints()
        //                routeQuery.travelModes = RouteQuery.BicycleTravel
        //                print("Adding " + printCoords(start) + " as start")
        //                routeQuery.addWaypoint(start)
        //                print("Adding " + printCoords(destination) + " as destination")
        //                routeQuery.addWaypoint(destination)
        //                routing.update()
        //            }
        //        }
        MenuItem {
            id: transitModeItem
            text: qsTr("Public Transport")
            iconSource: "qrc:/icons/ic_directions_transit_24px.svg"
            exclusiveGroup: directionsGroup
            onTriggered: {
                directionsGroup.current = transitModeItem
                print("Transit!!!")
                routing.reset()
                routeQuery.clearWaypoints()
                routeQuery.travelModes = RouteQuery.PublicTransitTravel
                print("Adding " + printCoords(start) + " as start")
                routeQuery.addWaypoint(start)
                print("Adding " + printCoords(destination) + " as destination")
                routeQuery.addWaypoint(destination)
                routing.update()
            }
        }
        MenuSeparator {}
        ExclusiveGroup {
            id: directionsOptionGroup
        }
        MenuItem {
            id: fastestOptionItem
            text: qsTr("&Fastest route")
            checkable: true
            checked: true
            exclusiveGroup: directionsOptionGroup
            onTriggered: {
                if (checked)
                    routeQuery.routeOptimizations = RouteQuery.FastestRoute
            }
        }
        MenuItem {
            id: shortestOptionItem
            text: qsTr("&Shortest route")
            checkable: true
            exclusiveGroup: directionsOptionGroup
            onTriggered: {
                if (checked)
                    routeQuery.routeOptimizations = RouteQuery.ShortestRoute
            }
        }
        //        MenuItem { // FIXME those 2 options not supported by here.com
        //            id: economicOptionItem
        //            text: qsTr("Most &economic route")
        //            checkable: true
        //            exclusiveGroup: directionsOptionGroup
        //            onTriggered: {
        //                if (checked)
        //                    routeQuery.routeOptimizations = RouteQuery.MostEconomicRoute
        //            }
        //        }
        //        MenuItem {
        //            id: scenicOptionItem
        //            text: qsTr("Most s&cenic route")
        //            checkable: true
        //            exclusiveGroup: directionsOptionGroup
        //            onTriggered: {
        //                if (checked)
        //                    routeQuery.routeOptimizations = RouteQuery.MostScenicRoute
        //            }
        //        }
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
        map.markerPlace.coordinate = coord
        map.addMapItem(map.markerPlace);
        print("Added marker for place: " + printCoords(coord))
    }

    function switchToResults() {
        resultsView.width = 400
        resultsView.forceActiveFocus()
    }

    function switchToMap() {
        resultsView.width = 0
        map.forceActiveFocus()
    }

    function makeCoords(place) {
        return QtPositioning.coordinate(place.coordinate.latitude, place.coordinate.longitude)
    }

    function printCoords(coord) {
        return coord.latitude + "," + coord.longitude
    }
}
