import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Dialog {
    id: root
    width: 400
    modal: true
    anchors.centerIn: parent
    padding: 24

    property string titleText: "Confirm Action"
    property string messageText: "Are you sure you want to proceed?"
    property string confirmButtonText: "Confirm"
    property color confirmButtonColor: "#F85149"
    
    signal confirmed()

    background: Rectangle {
        color: "#161B22"
        radius: 16
        border.color: "#30363D"
        border.width: 1
    }

    Overlay.modal: Rectangle {
        color: "#AA000000"
    }

    contentItem: ColumnLayout {
        spacing: 0
        
        ColumnLayout {
            Layout.fillWidth: true
            Layout.bottomMargin: 24
            spacing: 8
            
            Label {
                text: root.titleText
                color: "white"
                font.family: "Segoe UI"
                font.pixelSize: 20
                font.weight: Font.DemiBold
                Layout.alignment: Qt.AlignLeft
            }
            
            Label {
                text: root.messageText
                color: "#8B949E"
                font.pixelSize: 14
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignLeft
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 16
            spacing: 16
            
            Button {
                id: cancelBtn
                text: "Cancel"
                Layout.fillWidth: true
                Layout.preferredHeight: 42
                onClicked: root.close()
                
                contentItem: Text {
                    text: cancelBtn.text
                    color: "white"
                    font.family: "Segoe UI"
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                
                background: Rectangle {
                    color: cancelBtn.hovered ? "#30363D" : "#21262D"
                    radius: 10
                    Behavior on color { ColorAnimation { duration: 120 } }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.NoButton
                }
            }
            
            Button {
                id: confirmBtn
                text: root.confirmButtonText
                Layout.fillWidth: true
                Layout.preferredHeight: 42
                onClicked: {
                    root.confirmed()
                    root.close()
                }
                
                contentItem: Text {
                    text: confirmBtn.text
                    color: "white"
                    font.family: "Segoe UI"
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                
                background: Rectangle {
                    color: confirmBtn.hovered ? Qt.lighter(root.confirmButtonColor, 1.1) : root.confirmButtonColor
                    radius: 10
                    Behavior on color { ColorAnimation { duration: 120 } }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.NoButton
                }
            }
        }
    }

    enter: Transition {
        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 180 }
        NumberAnimation { property: "scale"; from: 0.96; to: 1.0; duration: 180; easing.type: Easing.OutQuart }
    }
    
    exit: Transition {
        NumberAnimation { property: "opacity"; to: 0; duration: 150 }
        NumberAnimation { property: "scale"; to: 0.96; duration: 150; easing.type: Easing.InQuart }
    }
}
