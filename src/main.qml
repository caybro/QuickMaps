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

    Settings {
        id: settings
        // save window size and position
        property alias x: mainWindow.x
        property alias y: mainWindow.y
        property alias width: mainWindow.width
        property alias height: mainWindow.height
    }

    //    Component.onDestruction: {
    //        settings.volume = player.volume
    //        settings.lastDirUrl = fileDialog.folder
    //    }

    Component.onCompleted: {
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

        print("Supported map types:")
        for (var i = 0; i<map.supportedMapTypes.length; i++){
            print("\t" + map.supportedMapTypes[i].name + "(" + map.supportedMapTypes[i].description + ")");
            mapTypeModel.append({"name": map.supportedMapTypes[i].name, "data": map.supportedMapTypes[i]});
        }
    }

    SystemPalette {
        id: palette
    }

    Plugin {
        id: plugin
        preferred: ["nokia", "osm"]
        name: "osm"
        //required: Plugin.GeocodingFeature | Plugin.ReverseGeocodingFeature | Plugin.MappingFeature // read-only, wtf? :)
        PluginParameter {name: "useragent"; value: "QuickMaps" }
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
        onCurrentIndexChanged: {
            if (currentText != "")
                map.activeMapType = model.get(currentIndex).data
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
                    addMarker(currentPlace);
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

    PositionSource {
        id: positionSource
        active: true

        onPositionChanged: {
            var coord = position.coordinate;
            console.log("Coordinate:", coord.longitude, coord.latitude);
        }
    }

    Map {
        id: map
        anchors.fill: parent
        plugin: plugin
        center: QtPositioning.coordinate(49.6843842, 17.2190358)
        zoomLevel: (maximumZoomLevel - minimumZoomLevel)/2
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
    }


    GeocodeModel {
        id: geocodeModel
        plugin: plugin
        autoUpdate: false

        onStatusChanged: {
            if (status == GeocodeModel.Ready) {
                print("Query returned " + count + " items")
                if (count == 1) {
                    var currentPlace = get(0);
                    map.clearMapItems();
                    print("Selecting " + currentPlace.address.text);
                    messageLabel.text = currentPlace.address.text;
                    addMarker(currentPlace);
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

    //    Timer {
    //        id: messageTimer
    //        interval: 3000 // 3 seconds
    //        onTriggered: messageLabel.text = player.source
    //    }

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
        id: goForwardAction
        text: qsTr("&Forward")
        tooltip: text.replace('&', '') + " (" + shortcut + ")"
        iconName: "go-next"
        shortcut: StandardKey.Forward
    }

    Action {
        id: goHomeAction
        text: qsTr("&Home")
        tooltip: text.replace('&', '') + " (" + shortcut + ")"
        iconName: "go-home"
        shortcut: "Ctrl+Home"
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
    }

    toolBar: ToolBar {
        //visible: mainWindow.visibility != Window.FullScreen
        RowLayout {
            anchors.fill: parent
            ToolButton {
                action: goHomeAction
            }
            ToolButton {
                action: goBackAction
            }
//            ToolButton {
//                action: goForwardAction
//            }
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
                action: fullscreenAction
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

    function addMarker(loc) {
        marker.coordinate = loc.coordinate
        map.addMapItem(marker);
        print("Added marker for location: " + loc.address.text)
    }
}
