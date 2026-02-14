import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

AbstractButton {
    id: control
    property string iconSource: ""
    property bool isActive: false
    property int count: 0
    property bool isFolder: false
    property color folderColor: "transparent"
    property bool isExpanded: true
    property bool hasChildren: false
    property bool isFolderExpanded: false
    property bool showArrow: true
    property bool isLastChild: false
    property bool canAddSubfolder: true // Controls whether + button is visible
    focusPolicy: Qt.NoFocus
    
    // Layout Metrics
    Layout.fillWidth: true
    Layout.preferredHeight: isFolder ? 36 : 40
    
    onClicked: {
        control.clickedWithModifiers(Qt.keyboardModifiers)
    }
    
    signal clickedWithModifiers(int modifiers)
    signal arrowClicked()
    signal addClicked()
    
    background: Rectangle {
        color: isActive ? "#14FFFFFF" : (control.hovered ? "#0AFFFFFF" : "transparent")
        radius: 6
        
        // Slide Animation
        Behavior on color { ColorAnimation { duration: 150 } }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.NoButton // Let the button handle clicks
        }
    }
    
    contentItem: Item {
        // Slide content right by 4px on selection
        x: isActive ? 4 : 0
        Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.OutQuart } }
        
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 8 // Tighter spacing for tree look
            
            // 1. Expansion Arrow
            Item {
                visible: control.isFolder && control.hasChildren && control.isExpanded && control.showArrow
                Layout.preferredWidth: 12
                Layout.preferredHeight: 12
                
                SharpIcon {
                    anchors.centerIn: parent
                    source: Qt.resolvedUrl(Qt.resolvedUrl("../assets/chevron-right-svgrepo-com.svg"))
                    iconSize: 10
                    color: control.hovered ? "#FFFFFF" : "#4B5563"
                    rotation: control.isFolderExpanded ? 90 : 0
                    Behavior on rotation { NumberAnimation { duration: 150 } }
                }
                
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -10
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        control.arrowClicked()
                    }
                }
            }
            
            // Spacer if no children but it's a folder to keep icons aligned
            Item {
                visible: control.isFolder && !control.hasChildren && control.isExpanded
                Layout.preferredWidth: 12
                Layout.preferredHeight: 12
            }
            
            // 2. Icon
            Item {
                Layout.preferredWidth: 20 // Widget size
                Layout.preferredHeight: 20
                
                SharpIcon {
                    anchors.centerIn: parent
                    source: control.iconSource
                    iconSize: control.isFolder ? 14 : 16
                    color: control.isFolder ? control.folderColor : "#FFFFFF"
                    Behavior on color { ColorAnimation { duration: 250 } }
                }
            }
            
            // 3. Label (Visible only when sidebar is expanded)
            Label {
                text: control.text
                color: "#E6EDF3"
                font.family: "Segoe UI"
                font.pixelSize: 15
                visible: control.isExpanded
                Layout.fillWidth: true
                elide: Text.ElideRight
                
                // Animate text appearance change (subtle crossfade simulation)
                Behavior on text { 
                    SequentialAnimation {
                        NumberAnimation { target: folderLabel; property: "opacity"; to: 0; duration: 100 }
                        PropertyAction { target: folderLabel; property: "text" }
                        NumberAnimation { target: folderLabel; property: "opacity"; to: 1; duration: 100 }
                    }
                }
                id: folderLabel
            }
            
            // 4. Badge
            Rectangle {
                visible: (count > 0 || !isFolder) && control.isExpanded
                Layout.preferredHeight: isFolder ? 16 : 18
                Layout.preferredWidth: isFolder ? 28 : 32
                radius: 6
                color: control.isActive ? "#2563EB" : "#14FFFFFF"
                
                Label {
                    anchors.centerIn: parent
                    text: control.count.toString()
                    color: control.isActive ? "#FFFFFF" : "#8A94A6"
                    font.pixelSize: 11
                    font.family: "Segoe UI"
                }
            }

            // 5. Add Subfolder Button (+) - Hover-only
            Item {
                visible: isFolder && control.isExpanded && canAddSubfolder
                Layout.preferredWidth: 20
                Layout.preferredHeight: 32
                
                Label {
                    anchors.centerIn: parent
                    text: "+"
                    color: addArea.containsMouse ? "#FFFFFF" : "#8B949E"
                    font.pixelSize: 20 // Slightly larger for clarity
                    opacity: (control.hovered || addArea.containsMouse) ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 120 } }
                }

                MouseArea {
                    id: addArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        control.addClicked()
                    }
                }
            }

            // 6. Overflow Menu (Vertical Dots) - Now inside RowLayout for perfect spacing
            Item {
                visible: isFolder && control.isExpanded
                Layout.preferredWidth: 20
                Layout.preferredHeight: 32
                
                SharpIcon {
                    anchors.centerIn: parent
                    source: Qt.resolvedUrl("../assets/more-vert.svg")
                    color: moreArea.containsMouse ? "#FFFFFF" : "#8B949E"
                    iconSize: 16
                    opacity: (control.hovered || moreArea.containsMouse) ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 120 } }
                }

                MouseArea {
                    id: moreArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        control.moreClicked()
                    }
                }
            }
        }
    }

    signal moreClicked()
}
