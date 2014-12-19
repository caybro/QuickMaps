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

        //positionSource.active = true
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

    ListView {
        id: resultsView
        model: geocodeModel
        anchors.fill: parent
        focus: true
        delegate: placeDelegate
        highlight: highlightDelegate
        highlightFollowsCurrentItem: false
        spacing: 5
        header: headerDelegate
        headerPositioning: ListView.PullBackHeader
        clip: true

        Keys.onPressed: {
            if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                print("Activated item at index: " + currentIndex)
                if (currentIndex != -1) {
                    var currentPlace = model.get(currentIndex);
                    map.clearMapItems();
                    print("Selecting " + currentPlace.address.text);
                    messageLabel.text = currentPlace.address.text;
                    addMarker(currentPlace.coordinate);
                    map.fitViewportToGeoShape(currentPlace.boundingBox)
                    resultsView.visible = false;
                    map.visible = true;
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            focus: true
            onClicked: {
                resultsView.currentIndex = resultsView.indexAt(mouse.x, mouse.y)
            }
        }

        Component {
            id: headerDelegate
            Column {
                anchors.bottomMargin: 10
                spacing: 5
                Text {
                    text: qsTr("Location")
                    font.bold: true
                }
                Text {
                    text: qsTr("Coordinates")
                    font.bold: true
                }
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

        Component.onCompleted: {
            currentIndex = 0;
        }
    }

//    PositionSource {
//        id: positionSource
//        active: false

//        onPositionChanged: {
//            var coord = position.coordinate;
//            console.log("Coordinate:", coord.latitude, coord.longitude);
//        }
//    }

    Map {
        id: map
        anchors.fill: parent
        plugin: plugin
//        property bool lastZoomWasIn: true
//        onZoomLevelChanged: {
//            print("Current zoom level: " + zoomLevel)
//            if (lastZoomWasIn) {
//                print("Ceiling to: " + Math.ceil(zoomLevel))
//                map.zoomLevel = Math.ceil(zoomLevel);
//            } else {
//                print("Flooring to: " + Math.floor(zoomLevel));
//                map.zoomLevel = Math.floor(zoomLevel);
//            }
//        }
//        onWheelAngleChanged: {
//            //print("Wheel:" + angleDelta)
//            lastZoomWasIn = angleDelta.y > 0
//        }

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
    }

    GeocodeModel {
        id: geocodeModel
        plugin: geocodePlugin
        autoUpdate: false
        limit: 20

        onStatusChanged: {
            if (status == GeocodeModel.Ready) {
                print("Query returned " + count + " items")
                if (count == 1) {
                    map.visible = true
                    resultsView.visible = false
                    var currentPlace = get(0);
                    map.clearMapItems();
                    print("Selecting " + currentPlace.address.text);
                    messageLabel.text = currentPlace.address.text;
                    addMarker(currentPlace.coordinate);
                    map.fitViewportToGeoShape(currentPlace.boundingBox)
                } else if (count > 1) {
                    map.visible = false;
                    messageLabel.text = qsTranslate("main", "Query returned %n item(s)", "", count)
                    resultsView.visible = true;
                    resultsView.forceActiveFocus();
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
    }

    Action {
        id: goHomeAction
        text: qsTr("&Home")
        tooltip: text.replace('&', '') + " (" + shortcut + ")"
        iconName: "go-home"
        shortcut: "Ctrl+Home"
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
                text: map.center.latitude.toFixed(4) + ", " + map.center.longitude.toFixed(4) + " (@" + map.zoomLevel.toFixed() + ")"
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
}
