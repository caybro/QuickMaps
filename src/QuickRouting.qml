import QtQuick 2.4
import QtLocation 5.3

RouteModel {
    id: routeModel
    autoUpdate: false
    onStatusChanged: {
        if (status == RouteModel.Ready) {
            print("Routing query returned " + count + " results")
            if (count != 0) {
                var route = get(0)
                map.fitViewportToGeoShape(route.bounds)
                print("Route measures " + route.distance + " meters and will take " + route.travelTime + " seconds")
                messageLabel.text = qsTr("Route measures %1 kilometers and will take %2.").arg(formatMeters(route.distance)).arg(formatSeconds(route.travelTime))
            }
        } else if (status == RouteModel.Error) {
            print("Routing error: " + errorString + " (" + error + ")")
            messageLabel.text = qsTr("Error occurred: %1").arg(errorString)
        }
    }

    function formatMeters(meters) {
        return Number(meters / 1000).toLocaleString(Qt.locale(), "f")
    }

    function formatSeconds(secs) {
        var date = new Date(0, 0, 0, 0, 0, secs)
        return date.toLocaleTimeString(Qt.locale(), "hh'h':mm'm':ss's'")
    }
}
