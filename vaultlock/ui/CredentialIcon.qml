import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Shapes 1.15

Item {
    id: root
    width: 40
    height: 40
    implicitWidth: 40
    implicitHeight: 40
    
    // Inputs
    property string logoSource: ""
    property string name: ""
    property color folderColor: "transparent"
    property color parentBackgroundColor: "#0D1117" // For the badge "cutout" effect
    
    // Logic: Fallback Initials
    property string initials: {
        if (!name) return "??"
        var parts = name.split(" ")
        if (parts.length >= 2) return (parts[0][0] + parts[1][0]).toUpperCase()
        return name.substring(0, 2).toUpperCase()
    }
    
    // 1. Main Background (Gradient if no logo)
    Rectangle {
        id: bgRect
        anchors.fill: parent
        radius: 10
        visible: srcImg.status !== Image.Ready
        
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#4B5563" }
            GradientStop { position: 1.0; color: "#1F2937" }
        }
        
        // Initials Text (DRAW text)
        Label {
            anchors.centerIn: parent
            text: root.initials
            color: "#FFFFFF"
            font.pixelSize: 16
            font.bold: true
            font.family: "Segoe UI"
        }
    }
    
    // 2. Logo Layer
    Item {
        id: logoContainer
        anchors.fill: parent
        clip: true // Basic clip for security
        
        Image {
            id: srcImg
            anchors.fill: parent
            source: root.logoSource
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
            visible: status === Image.Ready
        }

        // --- PURE QML ROUNDED CLIP TRICK ---
        // Instead of a mask, we overlay a "frame" that matches the background color.
        // This covers the square corners of the logo perfectly.
        Rectangle {
            id: inverseMask
            anchors.centerIn: parent
            // Make the rectangle huge but with a hole in the middle
            width: root.width + 100
            height: root.height + 100
            radius: 50 + 10 // borderWidth + targetRadius
            color: "transparent"
            border.width: 50
            border.color: root.parentBackgroundColor
            visible: srcImg.status === Image.Ready
        }
    }
    
    // 3. Badge Layer (Rounded Folder Badge)
    Item {
        id: badgeLayer
        // Geometry Constants based on parent width (sq_size)
        // badge_radius = self.sq_size * 0.18
        readonly property real badgeRadius: root.width * 0.18
        readonly property real badgeDiameter: badgeRadius * 2
        
        // Stroke Width = self.sq_size * 0.04
        readonly property real strokeWidth: root.width * 0.04
        
        // Badge Center Offset = 1px each side from bottom-right (handled by positioning)
        // Position: The center of the badge is at (W - R - 1, H - R - 1)
        // Top-Left of Badge Rect = Center - Radius
        // X = (W - R - 1) - R = W - 2R - 1
        readonly property real badgeX: root.width - (2 * badgeRadius) - 1
        readonly property real badgeY: root.height - (2 * badgeRadius) - 1
        
        x: badgeX
        y: badgeY
        width: badgeDiameter
        height: badgeDiameter
        z: 10 // On top
        
        visible: false // Hidden as per user request (moved to list row right side)
        
        // 3a. Cutout Border (Outer Ring)
        Rectangle {
            anchors.centerIn: parent
            width: parent.width + (parent.strokeWidth * 2)
            height: parent.height + (parent.strokeWidth * 2)
            radius: width / 2
            color: root.parentBackgroundColor // Matches panel background to create "cutout" look
        }
        
        // 3b. Badge Background
        Rectangle {
            id: badgeBg
            anchors.fill: parent
            radius: width / 2
            color: root.folderColor
            
            // 3c. Folder Icon (Shape for native color control)
            Shape {
                id: folderIconShape
                anchors.centerIn: parent
                // SVG ViewBox is 20x20.
                // Target width is badgeRadius * 1.2 (~11px).
                // Scale = Target / 20.
                width: 20
                height: 20
                scale: (badgeLayer.badgeRadius * 1.2) / 20
                
                // Use preferredRendererType: Shape.CurveRenderer if available/needed, 
                // but default or GeometryRenderer is fine.
                
                ShapePath {
                    strokeWidth: 0
                    // Lighter tint for contrast
                    fillColor: Qt.lighter(root.folderColor, 1.8) 
                    
                    // SVG Path Data: M0 4c0-1.1.9-2 2-2h7l2 2h7a2 2 0 0 1 2 2v10a2 2 0 0 1-2 2H2a2 2 0 0 1-2-2V4z
                    // Converted to QML Path commands manually? 
                    // No, PathSvg is available in QtQuick.Shapes 1.x!
                   
                    PathSvg {
                        path: "M0 4c0-1.1.9-2 2-2h7l2 2h7a2 2 0 0 1 2 2v10a2 2 0 0 1-2 2H2a2 2 0 0 1-2-2V4z"
                    }
                }
            }
        }
    }
}
