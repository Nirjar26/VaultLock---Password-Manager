import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Menu {
    id: root
    
    property var folderData: null
    
    signal renameRequested()
    signal subfolderRequested()
    signal moveRequested()
    signal detailsRequested()
    signal deleteRequested()

    width: 200
    padding: 6
    
    background: Rectangle {
        color: "#161B22"
        radius: 10
        border.color: "#30363D"
        border.width: 1
        
        layer.enabled: true
        // Shadow sim
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.color: "#0DFFFFFF"
            radius: 10
        }
    }

    delegate: MenuItem {
        id: menuItem
        height: 36
        
        contentItem: Text {
            text: menuItem.text
            color: menuItem.hovered ? "#FFFFFF" : "#E6EDF3"
            font.pixelSize: 13
            font.family: "Segoe UI"
            verticalAlignment: Text.AlignVCenter
            leftPadding: 8
        }
        
        background: Rectangle {
            color: menuItem.hovered ? "#21262D" : "transparent"
            radius: 6
            anchors.fill: parent
            anchors.margins: 2
            
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.NoButton
            }
        }
    }

    MenuItem {
        text: "Rename"
        onTriggered: root.renameRequested()
    }
    MenuItem {
        text: "Create Subfolder"
        onTriggered: root.subfolderRequested()
    }
    MenuItem {
        text: "Move Folder"
        onTriggered: root.moveRequested()
    }
    MenuItem {
        text: "Change Icon & Color"
        onTriggered: root.detailsRequested()
    }
    
    MenuSeparator {
        contentItem: Rectangle {
            implicitHeight: 1
            color: "#30363D"
        }
    }
    
    MenuItem {
        text: "Delete Folder"
        onTriggered: root.deleteRequested()
        contentItem: Text {
            text: "Delete Folder"
            color: "#FF4444"
            font.pixelSize: 13
            font.family: "Segoe UI"
            verticalAlignment: Text.AlignVCenter
            leftPadding: 8
        }
    }
    
    // Animation
    enter: Transition {
        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 120 }
        NumberAnimation { property: "scale"; from: 0.95; to: 1; duration: 120; easing.type: Easing.OutBack }
    }
    exit: Transition {
        NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 100 }
    }
}
