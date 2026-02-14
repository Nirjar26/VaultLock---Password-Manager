import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: root
    property string source: ""
    property color color: "transparent"
    property int iconSize: 16

    width: 24
    height: 24

    // Use ToolButton for its native icon tinting capabilities
    // This bypasses 'IconImage' availability issues and manual shader failures
    ToolButton {
        id: iconBtn
        anchors.centerIn: parent
        width: root.iconSize
        height: root.iconSize
        
        icon.source: root.source
        icon.width: root.iconSize
        icon.height: root.iconSize
        icon.color: root.color
        
        display: AbstractButton.IconOnly
        background: null // Remove button chrome
        padding: 0
        enabled: false // Prevent interaction, purely visual
        opacity: 1.0 // Ensure icon is fully visible even when disabled
    }
}
