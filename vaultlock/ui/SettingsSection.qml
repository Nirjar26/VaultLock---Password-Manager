import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

ScrollView {
    id: scrollRoot
    property string title: ""
    default property alias content: innerColumn.data 
    
    Layout.fillWidth: true
    Layout.fillHeight: true
    clip: true
    
    // Explicitly kill the horizontal scrollbar to prevent "popping"
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
    
    // Custom vertical ScrollBar style
    ScrollBar.vertical: ScrollBar {
        width: 8
        active: scrollRoot.hovered
        policy: ScrollBar.AsNeeded
        contentItem: Rectangle {
            implicitWidth: 6
            radius: 3
            color: parent.hovered || parent.pressed ? "#484F58" : "#30363D"
        }
    }
    
    ColumnLayout {
        id: rootColumn
        // Use a fixed width slightly less than available to be safe, 
        // or just availableWidth. AvailableWidth is usually best.
        width: scrollRoot.availableWidth
        spacing: 0
        
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: titleText.implicitHeight + 64 
            
            Text {
                id: titleText
                text: scrollRoot.title
                color: "white"
                font.family: "Segoe UI"; font.pixelSize: 24; font.weight: Font.DemiBold
                anchors.left: parent.left
                anchors.leftMargin: 32
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 24
            }
        }
        
        ColumnLayout {
            id: innerColumn
            Layout.fillWidth: true
            spacing: 0
        }
    }
}
