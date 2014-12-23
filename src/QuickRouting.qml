import QtQuick 2.4
import QtLocation 5.3

RouteModel {
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

    function formatSeconds(seconds) {
        var numdays = Math.floor((seconds % 31536000) / 86400);
        var numhours = Math.floor(((seconds % 31536000) % 86400) / 3600);
        var numminutes = Math.floor((((seconds % 31536000) % 86400) % 3600) / 60);
        var numseconds = (((seconds % 31536000) % 86400) % 3600) % 60;

        var result = "";
        if (numdays > 0)
            result += qsTranslate("", "%n day(s)", "", numdays) + ", ";
        if (numhours > 0)
            result += qsTranslate("", "%n hour(s)", "", numhours) + ", ";
        if (numminutes > 0)
            result += qsTranslate("", "%n minute(s)", "", numminutes) + ", ";
        if (numseconds > 0)
            result += qsTranslate("", "%n second(s)", "", numseconds);

        return result;
    }
}
