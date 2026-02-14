import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

ColumnLayout {
    id: itemRoot
    property string label: ""
    property string description: ""
    property string actionText: ""
    property bool isDanger: false
    property bool showAction: true
    signal clicked()

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
            Text { text: label; color: isDanger ? "#F85149" : "white"; font.family: "Segoe UI"; font.pixelSize: 14; font.weight: Font.Medium }
            Text { text: description; color: "#8B949E"; font.family: "Segoe UI"; font.pixelSize: 12; wrapMode: Text.WordWrap; Layout.fillWidth: true }
        }
        
        Button {
            id: actionBtn
            visible: showAction
            text: actionText
            onClicked: itemRoot.clicked()
            Layout.preferredHeight: 32
            Layout.preferredWidth: 80
            background: Rectangle {
                color: isDanger ? (actionBtn.hovered ? "#492323" : "transparent") : (actionBtn.hovered ? "#21262D" : "transparent")
                border.color: isDanger ? "#F85149" : "#30363D"
                border.width: 1
                radius: 6
            }
            contentItem: Text {
                text: actionText; color: isDanger ? "#F85149" : "white"
                horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                font.pixelSize: 12
            }
            
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: actionBtn.clicked()
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
