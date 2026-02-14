import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

ColumnLayout {
    id: dropdownRoot
    property string label: ""
    property string description: ""
    property var options: []
    property alias currentIndex: combo.currentIndex
    signal optionSelected(string option)

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
        
        ComboBox {
            id: combo
            model: options
            Layout.preferredWidth: 120
            Layout.preferredHeight: 32
            onActivated: dropdownRoot.optionSelected(currentText)
            
            // Custom smaller indicator
            indicator: SharpIcon {
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                source: Qt.resolvedUrl("../assets/chevron-up-chevron-down-svgrepo-com.svg")
                color: "#9CA3AF"
                iconSize: 10 // Smaller size
            }

            background: Rectangle {
                color: "#21262D"; border.color: "#30363D"; radius: 6
                
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.NoButton
                }
            }
            contentItem: Text {
                text: parent.currentText; color: "white"
                font.pixelSize: 12; verticalAlignment: Text.AlignVCenter; 
                leftPadding: 10; rightPadding: 24 // More right padding for indicator
            }
            delegate: ItemDelegate {
                width: parent.width
                contentItem: Text { text: modelData; color: "white"; font.pixelSize: 12 }
                background: Rectangle { color: highlighted ? "#30363D" : "#161B22" }
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
