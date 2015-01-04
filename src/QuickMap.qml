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
import QtLocation 5.3
import QtPositioning 5.2

Map {
    id: map
    focus: true

    property alias markerStart: markerStart
    property alias markerDestination: markerDestination
    property alias homeCircle: homeCircle

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
                    geocodeModel.update()
                }
            }
            MenuItem {
                text: qsTr("Directions from this place")
                onTriggered: {
                    goNavigateAction.checked = true
                    var here = map.toCoordinate(Qt.point(mapMouseArea.mouseX, mapMouseArea.mouseY))
                    start = here
                    currentSearchField = "start"
                    geocodeModel.query = here
                    geocodeModel.update()
                }
            }
            MenuItem {
                text: qsTr("Directions to this place")
                onTriggered: {
                    goNavigateAction.checked = true
                    var here = map.toCoordinate(Qt.point(mapMouseArea.mouseX, mapMouseArea.mouseY))
                    destination = here
                    currentSearchField = "destination"
                    geocodeModel.query = here
                    geocodeModel.update()
                }
            }
        }
    }

    MapQuickItem {
        id: markerStart
        anchorPoint.x: imageStart.width/4
        anchorPoint.y: imageStart.height
        coordinate: start
        visible: start.isValid && directionsMode

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
        visible: destination.isValid && directionsMode

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
        z: parent.z + 1
        visible: parent.visible
        implicitWidth: 200
        onCurrentIndexChanged: {
            map.activeMapType = model.get(currentIndex).data
            map.update()
        }
    }
    
    Component.onDestruction: {
        settings.latitude = map.center.latitude
        settings.longitude = map.center.longitude
    }
    
    Component.onCompleted: {
        var maps = map.supportedMapTypes
        print("Supported map types: " + maps.length)
        for (var i = 0; i < maps.length; i++) {
            print(maps[i].name + " (" + maps[i].description + ")")
            print("\tNight mode: " + maps[i].night + ", mobile: " + maps[i].mobile)
            print("\tStyle: " + maps[i].style)
            if (mobile) {
                if (maps[i].mobile) {
                    mapTypeModel.append({"name": maps[i].name, "data": maps[i]})
                }
            } else {
                mapTypeModel.append({"name": maps[i].name, "data": maps[i]})
            }
        }

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

    function zoomIn() {
        zoomLevel += 1
    }

    function zoomOut() {
        zoomLevel -= 1
    }

    function switchMapType(travelMode, night, mobile) {
        print("Travel mode: " + travelMode)
        print("Night: " + night)
        print("Mobile: " + mobile)

        var style
        if (travelMode === RouteQuery.PedestrianTravel || travelMode === RouteQuery.BicycleTravel)
            style = MapType.PedestrianMap
        else if (travelMode === RouteQuery.PublicTransitTravel)
            style = MapType.TransitMap
        else if (travelMode === RouteQuery.CarTravel)
            style = MapType.CarNavigationMap
        else
            style = MapType.StreetMap

        for (var i = 0; i < mapTypeModel.count; i++) {
            var aMap = mapTypeModel.get(i).data
            if (style === aMap.style && aMap.night === night && aMap.mobile === mobile) {
                print("Found requested style " + style + " at index " + i)
                print("Name: " + aMap.name)
                mapTypeCombo.currentIndex = i
                break
            }
        }
    }
}
