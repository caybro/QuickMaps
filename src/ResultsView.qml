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
import QtQuick.Layouts 1.3
import QtPositioning 5.3

ScrollView {
    visible: false
    width: 0
    Layout.maximumWidth: map*.4

    Behavior on width {
        enabled: !splitView.resizing
        NumberAnimation { duration: 300 }
    }

    onWidthChanged: {
        if (width == 0)
            visible = false
    }

    ListView {
        id: resultsView
        focus: true
        model: placeSearchModel
        delegate: placeDelegate
        highlight: highlightDelegate
        highlightFollowsCurrentItem: false
        spacing: 5
        clip: true
        section.property: "place.location.address.countryCode"  // FIXME sections don't work this way
        section.delegate: sectionHeading
        
        function selectPlace(index) {
            var currentPlace = model.data(currentIndex, "place").location
            var address = currentPlace.address.text.replace(/<br\/>/g, ", ")
            print("Selecting " + currentPlace.address.text + " as " + currentSearchField)
            messageLabel.text = model.data(currentIndex, "title") + " (" + currentPlace.address.text.replace(/<br\/>/g, ", ") + ")"

            if (currentSearchField == "start") {
                start = makeCoords(currentPlace)
                input.text = address
            } else if (currentSearchField == "destination") {
                destination = makeCoords(currentPlace)
                inputDestination.text = address
            }

            if (currentPlace.boundingBox.isValid)
                map.visibleRegion = currentPlace.boundingBox
            else
                map.visibleRegion = QtPositioning.circle(makeCoords(currentPlace), 100)

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
                    text: title
                    font.bold: true
                }
                Text {
                    id: locationDelegate
                    text: place.location.address.text
                }
                Text {
                    text: printCoords(place.location.coordinate)
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
            currentIndex = 0
        }
    }
}
