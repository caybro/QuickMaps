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
import QtLocation 5.3
import QtPositioning 5.2

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
                    map.removeMapItem(map.markerPlace);
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
                map.removeMapItem(map.markerPlace);
                messageLabel.text = qsTranslate("main", "Query returned %n item(s)", "", count)
            }
        } else if (status == GeocodeModel.Error) {
            print("Query error: " + errorString + " (" + error + ")")
        }
    }
}
