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
import QtQuick.Controls 1.4
import QtQuick.Controls.Styles 1.4
import QtQuick.Layouts 1.3
import QtQuick.Window 2.2
import QtQuick.Dialogs 1.2
import QtLocation 5.5
import QtPositioning 5.3
import Qt.labs.settings 1.0
import QtSensors 5.3

import "qrc:/"

ApplicationWindow {
    id: mainWindow
    visible: true
    width: 640
    height: 480
    title: "Quick Maps"

    property int windowVisibility

    readonly property bool mobile: ["android", "ios", "blackberry", "wince"].some(function(element) {
        return element === Qt.platform.os
    })

    property string currentSearchField // "start" or "destination"
    property bool directionsMode: directionsAction.checked
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
        console.warn("App name/version: " + Qt.application.name + " " + Qt.application.version)
        console.warn("Platform: " + Qt.platform.os)
        console.warn("Mobile: " + mobile)
        console.warn("Available services: " + plugin.availableServiceProviders)
        console.warn("Actual mapping plugin: " + plugin.name)
        console.warn("Min/max zooms: " + map.minimumZoomLevel + "/" + map.maximumZoomLevel)

        console.warn("\n\Here.com plugin\n--------------")
        console.warn("Supports online maps: " + plugin.supportsMapping(Plugin.OnlineMappingFeature))
        console.warn("Supports offline maps: " + plugin.supportsMapping(Plugin.OfflineMappingFeature))
        console.warn("Supports localized maps: " + plugin.supportsMapping(Plugin.LocalizedMappingFeature))
        console.warn("Supports online routing: " + plugin.supportsRouting(Plugin.OnlineRoutingFeature))
        console.warn("Supports offline routing: " + plugin.supportsRouting(Plugin.OfflineRoutingFeature))
        console.warn("Supports localized routing: " + plugin.supportsRouting(Plugin.LocalizedRoutingFeature))
        console.warn("Supports dynamic routing, based on current position: " + plugin.supportsRouting(Plugin.RouteUpdatesFeature))
        console.warn("Supports routing alternatives: " + plugin.supportsRouting(Plugin.AlternativeRoutesFeature))

        console.warn("\n\nOSM plugin\n--------------")
        console.warn("Supports online maps: " + geocodePlugin.supportsMapping(Plugin.OnlineMappingFeature))
        console.warn("Supports online routing: " + geocodePlugin.supportsRouting(Plugin.OnlineRoutingFeature))
        console.warn("Supports dynamic routing, based on current position: " + geocodePlugin.supportsRouting(Plugin.RouteUpdatesFeature))
        console.warn("Supports geocoding: " + geocodePlugin.supportsGeocoding(Plugin.OnlineGeocodingFeature))
        console.warn("Supports reverse geocoding: " + geocodePlugin.supportsGeocoding(Plugin.ReverseGeocodingFeature))
        console.warn("Supports places: " + geocodePlugin.supportsPlaces(Plugin.OnlinePlacesFeature))

        var types = QmlSensors.sensorTypes();
        console.warn("Supported sensors: " + types.join(", "));
        console.warn("Light sensor: " + lightSensor.identifier + " " + lightSensor.description)
        if (mobile) {
            lightSensor.start()
        }

        map.forceActiveFocus()
    }

    AmbientLightSensor {
        id: lightSensor
        skipDuplicates: true
        onReadingChanged: {
            print("Ambient light level: " + reading.lightLevel)
        }
    }

    SystemPalette {
        id: palette
    }

    MessageDialog {
        id: placeDetailsDlg
        title: qsTr("Place Details")
        icon: StandardIcon.Information
        standardButtons: StandardButton.Ok
        onAccepted: {
            close()
        }
    }

    Plugin {
        id: plugin
        preferred: ["here", "osm"]
        PluginParameter { name: "here.app_id"; value: "KvjgeyL7z4SoEo3WpDlr" }
        PluginParameter { name: "here.token"; value: "silNtd28g7LA6L_hSDwBMQ" }
        PluginParameter { name: "osm.useragent"; value: "QuickMaps" }
    }

    Plugin {
        id: geocodePlugin
        name: "osm" // BUG the nokia geocode plugin seems to always return only 1 result...
        PluginParameter { name: "osm.useragent"; value: "QuickMaps" }
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

            MapItemView {
                id: mapItemView
                model: routing
                delegate: MapRoute {
                    route: routeData
                    line.color: palette.highlight
                    line.width: 5
                    smooth: true
                    opacity: 0.7
                }
            }

            MapItemView {
                id: placesView
                model: placeSearchModel
                delegate: MapQuickItem {
                    id: placeDelegate
                    anchorPoint.x: image.width/2
                    anchorPoint.y: image.height
                    coordinate: place.location.coordinate

                    sourceItem: Column {
                        Text {
                            id: placeText
                            text: title
                            anchors.horizontalCenter: image.horizontalCenter
                        }
                        Image {
                            id: image
                            source: place.icon.url()
                            width: 24
                            height: 24
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            //print("Clicked place ID: " + place.placeId)
                            messageLabel.text = place.name + " (" + place.location.address.text.replace(/<br\/>/g, ", ") + ")"
                            placeMenu.popup()
                        }

                        Menu {
                            id: placeMenu
                            MenuItem {
                                text: qsTr("&Details...")
                                onTriggered: {
                                    print("Details for place (ID): " + place.name + " (" + place.placeId + ")")

                                    placeDetailsDlg.text = "<b>" + place.name + "</b><br><br>" +
                                            qsTr("Address: %1").arg(place.location.address.text.replace(/<br\/>/g, ", ")) + "<br>" +
                                            qsTr("Categories: %1").arg(listCategories(place.categories)) + "<br>" +
                                            qsTr("Rating: %L1 stars").arg(place.ratings.average)
                                    placeDetailsDlg.informativeText = "<small>" + printCoords(place.location.coordinate) + "</small><br>" +
                                            place.attribution
                                    placeDetailsDlg.open()
                                }
                            }
                            MenuItem {
                                text: qsTr("Directions &here")
                                iconSource: "qrc:/icons/ic_directions_24px.svg"
                                enabled: place.location
                                onTriggered: {
                                    destination = makeCoords(place.location)
                                    inputDestination.text = place.name + ", " + place.location.address.text.replace(/<br\/>/g, ", ")
                                    start = QtPositioning.coordinate()
                                    input.text = ""
                                    input.forceActiveFocus()
                                    directionsAction.checked = true
                                }
                            }
                        }
                    }
                }
            }

            onCenterChanged: {
                if (!directionsMode) {
                    if (placeSearchModel.searchTerm != "") // FIXME needs a timer or something
                        placeSearchModel.update()
                }
            }
        }
    }

    GeocodeModel {
        id: geocodeModel
        plugin: geocodePlugin
        onStatusChanged: {
            if (status == GeocodeModel.Ready) {
                print("Got " + count + " reverse geocode results")
                if (count > 0) {
                    selectPlace(get(0))

                    if (directionsMode) {
                        findDirections()
                    }
                }
            } else if (status == GeocodeModel.Error) {
                print("Geocode error: " + errorString())
            }
        }
    }

    PlaceSearchModel {
        id: placeSearchModel
        plugin: plugin
        limit: 30
        searchArea: QtPositioning.circle(map.center)

        onStatusChanged: {
            if (status == PlaceSearchModel.Ready) {
                searchTerm = ""
                console.warn("Got " + count + " place search results")
                if (count == 1) {
                    selectPlace(data(0, "place").location)
                } else if (count > 1) {
                    messageLabel.text = qsTranslate("main", "Query returned %n item(s)", "", count)
                    switchToResults()
                } else {
                    console.warn("Got no results from " + currentSearchField)
                    messageLabel.text = qsTranslate("main", "Query returned %n item(s)", "", count)
                }

                if (count > 0 && directionsMode) {
                    findDirections()
                }
            } else if (status == PlaceSearchModel.Error) {
                console.error("Places search error:", errorString())
            }
        }
    }

    QuickRouting {
        id: routing
        plugin: plugin
        query: routeQuery
    }

    RouteQuery {
        id: routeQuery
        travelModes: directionsGroup.current.travelMode
        routeOptimizations: fastestOptionItem.checked ? RouteQuery.FastestRoute : RouteQuery.ShortestRoute
        //numberAlternativeRoutes: 2
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
        onTriggered: Qt.quit()
    }

    Action {
        id: goAction
        text: qsTr("&Find")
        tooltip: text.replace('&', '') + " (" + shortcut + ")"
        iconSource: "qrc:/icons/ic_search_24px.svg"
        shortcut: StandardKey.Find
        enabled: false
        onTriggered: {
            var text = currentSearchField == "destination" ? inputDestination.text : input.text
            print("Current query: " + text + " (searching for " + currentSearchField + ")")
            if (directionsMode) {
                geocodeModel.query = text
                geocodeModel.update()
            } else {
                placeSearchModel.searchTerm = text
                placeSearchModel.update()
            }
        }
    }

    Action {
        id: goBackAction
        text: qsTr("&Back")
        tooltip: text.replace('&', '') + " (" + shortcut + ")"
        iconSource: "qrc:/icons/ic_arrow_back_24px.svg"
        shortcut: StandardKey.Back
        enabled: resultsView.visible || placeSearchModel.count > 1
        onTriggered: {
            if (resultsView.visible)
                switchToMap()
            else if (placeSearchModel.count > 1)
                switchToResults()
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
                messageLabel.text = GeoLocation.description
                map.visibleRegion = QtPositioning.circle(map.homeCircle.center, map.homeCircle.radius)
            } else {
                messageLabel.text = ""
                if (directionsMode && routing.count > 0) {
                    map.visibleRegion = routing.get(0).bounds
                } else if (placeSearchModel.count > 0) {
                    map.visibleRegion = QtPositioning.circle(placeSearchModel.data(0, "place").location.coordinate, 100)
                }
            }
        }
    }

    Action {
        id: directionsAction
        text: qsTr("Directions")
        iconSource: "qrc:/icons/ic_directions_24px.svg"
        shortcut: "Ctrl+N"
        checkable: true
        onCheckedChanged: {
            if (checked) {
                placeSearchModel.reset()
                if (start.isValid && destination.isValid) {
                    routing.update()
                    map.switchMapType(routeQuery.travelModes, isNight(), mobile)
                }
            } else {
                routing.reset()
                messageLabel.text = ""
                map.switchMapType(-1, false, mobile)
            }
        }
    }

    Action {
        id: fullscreenAction
        text: qsTr("View &Fullscreen")
        tooltip: text.replace('&', '') + " (" + shortcut + ")"
        iconSource: checked ? "qrc:/icons/ic_fullscreen_exit_24px.svg" : "qrc:/icons/ic_fullscreen_24px.svg"
        shortcut: StandardKey.FullScreen
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
                    goAction.enabled = text != "" &&
                            (placeSearchModel.status != PlaceSearchModel.Loading || geocodeModel.status != GeocodeModel.Loading)
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
                    visible: input.text != "" && placeSearchModel.count == 0
                             && currentSearchField == "start" && placeSearchModel.status == PlaceSearchModel.Ready
                }
                BusyIndicator {
                    running: (placeSearchModel.status == PlaceSearchModel.Loading || geocodeModel.status == GeocodeModel.Loading)
                             && currentSearchField != "destination"
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
                    var tmpLoc = start
                    start = destination
                    destination = tmpLoc
                    var tmpText = input.text
                    input.text = inputDestination.text
                    inputDestination.text = tmpText
                    if (start.isValid && destination.isValid)
                        routing.update()
                }
            }

            TextField {
                id: inputDestination
                Layout.fillWidth: true
                placeholderText: qsTr("Destination")
                visible: directionsMode
                onAccepted: {
                    if (text != "") {
                        destination = QtPositioning.coordinate()
                        currentSearchField = "destination"
                        goAction.trigger()
                    }
                }
                onTextChanged: {
                    goAction.enabled = text != "" &&
                            (placeSearchModel.status != PlaceSearchModel.Loading || geocodeModel.status != GeocodeModel.Loading)
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
                    running: (placeSearchModel.status == PlaceSearchModel.Loading  || geocodeModel.status == GeocodeModel.Loading)
                             && currentSearchField == "destination"
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
                action: directionsAction
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
            Item { Layout.preferredWidth: 10; visible: !mobile }
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
            property int travelMode: RouteQuery.CarTravel
            onTriggered: {
                directionsGroup.current = carModeItem
                print("Drive!!!")
                findDirections()
            }
        }
        MenuItem {
            id: pedestrianModeItem
            text: qsTr("Walk")
            iconSource: "qrc:/icons/ic_directions_walk_24px.svg"
            exclusiveGroup: directionsGroup
            property int travelMode: RouteQuery.PedestrianTravel
            onTriggered: {
                directionsGroup.current = pedestrianModeItem
                print("Walk!!!")
                findDirections()
            }
        }
        MenuItem {
            id: transitModeItem
            text: qsTr("Public Transport")
            iconSource: "qrc:/icons/ic_directions_transit_24px.svg"
            exclusiveGroup: directionsGroup
            property int travelMode: RouteQuery.PublicTransitTravel
            onTriggered: {
                directionsGroup.current = transitModeItem
                print("Transit!!!")
                findDirections()
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
        }
        MenuItem {
            id: shortestOptionItem
            text: qsTr("&Shortest route")
            checkable: true
            exclusiveGroup: directionsOptionGroup
        }
        MenuSeparator {}
        MenuItem {
            id: featureToll
            text: qsTr("Toll roads")
            checkable: true
            checked: true
            onTriggered: routeQuery.setFeatureWeight(RouteQuery.TollFeature,
                                                     checked ? RouteQuery.NeutralFeatureWeight : RouteQuery.DisallowFeatureWeight)
        }
        MenuItem {
            id: featureHighway
            text: qsTr("Highways")
            checkable: true
            checked: true
            onTriggered: routeQuery.setFeatureWeight(RouteQuery.HighwayFeature,
                                                     checked ? RouteQuery.NeutralFeatureWeight : RouteQuery.AvoidFeatureWeight)
        }
        MenuItem {
            id: featureTunnel
            text: qsTr("Tunnels")
            checkable: true
            checked: true
            onTriggered: routeQuery.setFeatureWeight(RouteQuery.TunnelFeature,
                                                     checked ? RouteQuery.NeutralFeatureWeight : RouteQuery.AvoidFeatureWeight)
        }
        MenuItem {
            id: featureDirtRoad
            text: qsTr("Unpaved roads")
            checkable: true
            checked: true
            onTriggered: routeQuery.setFeatureWeight(RouteQuery.DirtRoadFeature,
                                                     checked ? RouteQuery.NeutralFeatureWeight : RouteQuery.AvoidFeatureWeight)
        }
        MenuItem {
            id: featureFerry
            text: qsTr("Ferries")
            checkable: true
            checked: true
            onTriggered: routeQuery.setFeatureWeight(RouteQuery.FerryFeature,
                                                     checked ? RouteQuery.NeutralFeatureWeight : RouteQuery.AvoidFeatureWeight)
        }
    }

    statusBar: StatusBar {
        id: statusBar
        visible: !fullscreenAction.checked
        style: StatusBarStyle {
            padding {
                left: 8
                right: 8
                top: 3
                bottom: 3
            }
            background: Rectangle {
                implicitHeight: 16
                implicitWidth: 200
                gradient: Gradient{
                    GradientStop{color: palette.light ; position: 0}
                    GradientStop{color: palette.mid ; position: 1}
                }
            }
        }

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
            mainWindow.visibility = windowVisibility
        else {
            windowVisibility = mainWindow.visibility
            mainWindow.visibility = Window.FullScreen
            map.forceActiveFocus()
        }
    }

    function switchToResults() {
        resultsView.visible = true
        resultsView.width = 200
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

    function findDirections() {
        if (!start.isValid || !destination.isValid) {
            print("Invalid start/destination, aborting directions")
            return
        }

        routing.reset()
        routeQuery.clearWaypoints()
        print("Adding " + printCoords(start) + " as start")
        routeQuery.addWaypoint(start)
        print("Adding " + printCoords(destination) + " as destination")
        routeQuery.addWaypoint(destination)

        map.switchMapType(routeQuery.travelModes, isNight(), mobile)
    }

    function listCategories(categories) {
        var result = []
        for (var i = 0; i < categories.length; i++) {
            result.push(categories[i].name)
        }
        return result.join(', ')
    }

    function selectPlace(location) {
        var address = location.address.text.replace(/<br\/>/g, ", ")

        if (currentSearchField == "start") {
            start = makeCoords(location)
            input.text = address
        } else if (currentSearchField == "destination") {
            destination = makeCoords(location)
            inputDestination.text = address
        } else {
            messageLabel.text = address
        }

        if (location.boundingBox.isValid)
            map.visibleRegion = location.boundingBox
        else
            map.visibleRegion = QtPositioning.circle(makeCoords(location), 100)
        switchToMap()
    }

    function isNight() {
        if (mobile) {
            return lightSensor.reading.lightLevel === AmbientLightReading.Dark || lightSensor.reading.lightLevel === AmbientLightReading.Twilight
        } else {
            var date = new Date()
            var hour = date.getHours()
            return (hour < 7 || hour >= 17)
        }
    }
}
