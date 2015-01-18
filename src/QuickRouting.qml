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

RouteModel {
    autoUpdate: true
    onStatusChanged: {
        if (status == RouteModel.Ready) {
            print("Routing query returned " + count + " results")
            if (count != 0) {
                var route = get(0)
                map.fitViewportToGeoShape(route.bounds)
                print("Route measures " + route.distance + " meters and will take " + route.travelTime + " seconds")
                messageLabel.text = qsTr("Route measures %1 and will take %2.").arg(formatMeters(route.distance)).arg(formatSeconds(route.travelTime))
                printRoute(route)
            }
        } else if (status == RouteModel.Error) {
            print("Routing error: " + errorString + " (" + error + ")")
            messageLabel.text = qsTr("Error occurred: %1").arg(errorString)
        }
    }

    function formatMeters(meters) {
        return qsTranslate("", "%n kilometer(s)", "", meters/1000)
    }

    function formatSeconds(seconds) {
        var numdays = Math.floor((seconds % 31536000) / 86400)
        var numhours = Math.floor(((seconds % 31536000) % 86400) / 3600)
        var numminutes = Math.ceil((((seconds % 31536000) % 86400) % 3600) / 60)

        var result = ""
        if (numdays > 0)
            result += qsTranslate("", "%n day(s)", "", numdays) + ", "
        if (numhours > 0)
            result += qsTranslate("", "%n hour(s)", "", numhours) + ", "
        if (numminutes > 0)
            result += qsTranslate("", "%n minute(s)", "", numminutes)

        return result
    }

    function printRoute(route) {
        print("\n\n--- Route details ---")
        for (var i = 0; i < route.segments.length; i++) {
            var segment = route.segments[i]
            print("Segment " + i + ": " + segment.distance + " meters")
            if (segment.maneuver.valid) {
                print("Maneuver: " + segment.maneuver.instructionText)
                print("Distance to next: " + segment.maneuver.distanceToNextInstruction + "m")
                print("Time to next: " + segment.maneuver.timeToNextInstruction + "s")
                print("Position: " + printCoords(segment.maneuver.position))
                if (segment.maneuver.waypointValid)
                    print("Waypoint: " + printCoords(segment.maneuver.waypoint))
            }
            print("---")
        }
    }
}
