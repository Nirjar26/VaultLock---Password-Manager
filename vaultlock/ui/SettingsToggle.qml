import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

ColumnLayout {
    id: toggleRoot
    property string label: ""
    property string description: ""
    property bool checked: false
    signal toggled(bool checked)

    Layout.fillWidth: true
    spacing: 0
    
    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 20
        Layout.bottomMargin: 20
        Layout.leftMargin: 32  // Internal padding
        Layout.rightMargin: 32 // Internal padding
        spacing: 20
        
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            Text { text: label; color: "white"; font.family: "Segoe UI"; font.pixelSize: 14; font.weight: Font.Medium }
            Text { text: description; color: "#8B949E"; font.family: "Segoe UI"; font.pixelSize: 12; wrapMode: Text.WordWrap; Layout.fillWidth: true }
        }
        
        Switch {
            id: sw
            checked: toggleRoot.checked
            onCheckedChanged: toggleRoot.toggled(checked)
            indicator: Rectangle {
                implicitWidth: 36; implicitHeight: 20; radius: 10
                color: sw.checked ? "#238636" : "#30363D"
                Rectangle {
                    x: sw.checked ? parent.width - width - 2 : 2; y: 2
                    width: 16; height: 16; radius: 8; color: "white"
                    Behavior on x { NumberAnimation { duration: 150 } }
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: sw.checked = !sw.checked
                }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: "#21262D"
        opacity: 0.6
    }
}
