import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: detailRow
    Layout.fillWidth: true
    Layout.preferredHeight: 56
    color: "transparent"
    
    // Properties
    property string label: ""
    property string value: ""
    property bool isPassword: false
    property bool isLink: false
    property bool isDropdown: false
    property string actionIcon: "" // Optional icon name for the right side
    property bool showDivider: true
    property string fontFamily: ""
    property string colorOverride: ""
    
    // Internal State
    property bool passwordVisible: (uiBridge) ? !uiBridge.hidePasswordsDefault : false

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 0
        anchors.rightMargin: 0
        spacing: 16
        
        // Left: Label
        Label {
            text: detailRow.label
            color: "#FFFFFF"
            font.family: "Segoe UI"
            font.pixelSize: 15
            font.weight: Font.Normal
            Layout.preferredWidth: 120 
            Layout.alignment: Qt.AlignVCenter
        }
        
        // Spacer to push Value to right
        Item { Layout.fillWidth: true }
        
        // Right: Value
        Label {
            text: detailRow.isPassword ? (detailRow.passwordVisible ? detailRow.value : "••••••••") : detailRow.value
            color: detailRow.colorOverride !== "" ? detailRow.colorOverride : (detailRow.isLink ? "#58A6FF" : "#8A94A6")
            font.family: detailRow.fontFamily !== "" ? detailRow.fontFamily : (detailRow.isPassword ? "Consolas" : "Segoe UI")
            font.pixelSize: 15
            font.weight: Font.Normal
            Layout.alignment: Qt.AlignVCenter
            
            MouseArea {
                anchors.fill: parent
                enabled: detailRow.isLink || detailRow.isDropdown
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (detailRow.isLink) {
                        Qt.openUrlExternally("https://" + detailRow.value)
                    } else if (detailRow.isDropdown) {
                        detailRow.dropdownClicked()
                    }
                }
            }
        }
        
        
        // Action Icon (Eye, External Link, Chevron)
        Item {
            visible: detailRow.isPassword || detailRow.isLink || detailRow.isDropdown
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20
            Layout.alignment: Qt.AlignVCenter
            
            // Password Eye
            SharpIcon {
                visible: detailRow.isPassword
                source: detailRow.passwordVisible 
                        ? Qt.resolvedUrl("../assets/eye-off-svgrepo-com.svg")
                        : Qt.resolvedUrl("../assets/eye-svgrepo-com.svg") 
                color: "#58A6FF"
                iconSize: 16
                anchors.centerIn: parent
                
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: detailRow.passwordVisible = !detailRow.passwordVisible
                }
            }
            
            // External Link
            SharpIcon {
                visible: detailRow.isLink
                source: Qt.resolvedUrl("../assets/launch-1-svgrepo-com.svg")
                color: "#58A6FF"
                iconSize: 14
                anchors.centerIn: parent
            }
            
            // Dropdown Indicator
            SharpIcon {
                visible: detailRow.isDropdown
                source: Qt.resolvedUrl("../assets/chevron-up-chevron-down-svgrepo-com.svg")
                color: "#8B949E"
                iconSize: 12
                anchors.centerIn: parent
                
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: detailRow.dropdownClicked()
                }
            }
        }
    }
    
    signal dropdownClicked()
    
    // Bottom Divider
    Rectangle {
        visible: detailRow.showDivider
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: "#21262D"
    }

    // --- Animation Support ---
    opacity: 0 // Default hidden for animation start
    transform: Translate { id: contentTrans; y: 15 }

    function animateIn(delay) {
        // Reset state immediately
        opacity = 0
        contentTrans.y = 15
        
        // Configure and play
        entranceAnim.stop()
        entranceAnim.delayValue = delay
        entranceAnim.start()
    }

    SequentialAnimation {
        id: entranceAnim
        property int delayValue: 0

        PauseAnimation { duration: entranceAnim.delayValue }
        ParallelAnimation {
            NumberAnimation { 
                target: detailRow
                property: "opacity"
                to: 1
                duration: 500
                easing.type: Easing.OutCubic 
            }
            NumberAnimation { 
                target: contentTrans
                property: "y"
                to: 0
                duration: 500
                easing.type: Easing.OutCubic 
            }
        }
    }
}
