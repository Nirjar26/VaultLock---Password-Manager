import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: sidebarRoot
    width: expanded ? 260 : 70
    color: "#161B22"
    
    // External Property or State
    property bool expanded: true
    property bool foldersOpen: true
    
    signal createFolderRequested()
    signal createSubFolderRequested(var folderData)
    signal moreFolderClicked(var folderData)
    signal settingsRequested()
    
    // Border Right
    Rectangle {
        anchors.right: parent.right
        width: 1
        height: parent.height
        color: "#0DFFFFFF"
    }
    
    // Animation for Width
    Behavior on width { NumberAnimation { duration: 350; easing.type: Easing.OutQuart } }

    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: {
            sidebarRoot.forceActiveFocus()
            if (uiBridge) uiBridge.selectedId = ""
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 24
        anchors.bottomMargin: 20
        // Margins change based on state
        anchors.leftMargin: sidebarRoot.expanded ? 16 : 0
        anchors.rightMargin: sidebarRoot.expanded ? 16 : 0
        spacing: 24
        
        // 1. Toggle Button
        Button {
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            Layout.alignment: sidebarRoot.expanded ? Qt.AlignLeft : Qt.AlignHCenter
            
            flat: true
            background: Rectangle {
                color: parent.hovered ? "#14FFFFFF" : "transparent"
                radius: 8
            }
            contentItem: SharpIcon {
                source: Qt.resolvedUrl("../assets/menu.svg")
                color: "white"
                iconSize: 20
                anchors.centerIn: parent
            }
            onClicked: sidebarRoot.expanded = !sidebarRoot.expanded
            
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.NoButton
            }
        }
        
        // 2. Main Content (Library + Folders) - Visible when EXPANDED
        ColumnLayout {
            visible: sidebarRoot.expanded
            opacity: sidebarRoot.expanded ? 1.0 : 0.0
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 24
            
            // Fade animation
            Behavior on opacity { NumberAnimation { duration: 200 } }
            
            // LIBRARY SECTION
            ColumnLayout {
                spacing: 8
                Layout.fillWidth: true
                
                Label {
                    text: "LIBRARY"
                    color: "#4B5563"
                    font.family: "Segoe UI"
                    font.pixelSize: 13
                    font.bold: true
                    font.letterSpacing: 1.2
                }
                
                ColumnLayout {
                    spacing: 2
                    Layout.fillWidth: true
                    
                    SidebarItem {
                        text: "All Items"
                        iconSource: Qt.resolvedUrl(Qt.resolvedUrl("../assets/key.svg"))
                        count: (uiBridge && uiBridge.counts) ? (uiBridge.counts["All"] || 0) : 0
                        isActive: (uiBridge && uiBridge.currentFilter) ? (uiBridge.currentFilter === "All") : false
                        onClickedWithModifiers: (modifiers) => { if (uiBridge) uiBridge.setFilter("All") }
                    }
                    SidebarItem {
                        text: "Favourites"
                        iconSource: Qt.resolvedUrl(Qt.resolvedUrl("../assets/star (1).svg"))
                        count: (uiBridge && uiBridge.counts) ? (uiBridge.counts["Favourites"] || 0) : 0
                        isActive: (uiBridge && uiBridge.currentFilter) ? (uiBridge.currentFilter === "Favourites") : false
                        onClickedWithModifiers: (modifiers) => { if (uiBridge) uiBridge.setFilter("Favourites") }
                    }
                    SidebarItem {
                        text: "Deleted"
                        iconSource: Qt.resolvedUrl(Qt.resolvedUrl("../assets/trash-arrow-up.svg"))
                        count: (uiBridge && uiBridge.counts) ? (uiBridge.counts["Deleted"] || 0) : 0
                        isActive: (uiBridge && uiBridge.currentFilter) ? (uiBridge.currentFilter === "Deleted") : false
                        onClickedWithModifiers: (modifiers) => { if (uiBridge) uiBridge.setFilter("Deleted") }
                    }
                }
            }
            
            // FOLDERS SECTION
            ColumnLayout {
                spacing: 8
                Layout.fillWidth: true
                
                // Header
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    
                    // Arrow (Rotates)
                    SharpIcon {
                        source: Qt.resolvedUrl(Qt.resolvedUrl("../assets/chevron-right-svgrepo-com.svg"))
                        iconSize: 12
                        color: "#4B5563"
                        rotation: sidebarRoot.foldersOpen ? 90 : 0
                        Behavior on rotation { NumberAnimation { duration: 200 } }
                    }
                    
                    Text {
                        text: "FOLDERS"
                        color: "#4B5563"
                        font.family: "Segoe UI"
                        font.pixelSize: 13
                        font.bold: true
                        Layout.fillWidth: true
                        
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: sidebarRoot.foldersOpen = !sidebarRoot.foldersOpen
                        }
                    }
                    
                    Button {
                        text: "+"
                        flat: true
                        focusPolicy: Qt.NoFocus
                        Layout.preferredWidth: 30; Layout.preferredHeight: 30
                        background: null
                        contentItem: SharpIcon {
                            source: Qt.resolvedUrl("../assets/plus.svg")
                            color: "#9CA3AF"
                            iconSize: 16
                            anchors.centerIn: parent
                        }
                        onClicked: sidebarRoot.createFolderRequested()
                        ToolTip.visible: hovered; ToolTip.text: "Create Root Folder"
                        
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.NoButton
                        }
                    }
                }
                
                // Folders List Container
                Item {
                    id: folderContainer
                    Layout.fillWidth: true
                    height: sidebarRoot.foldersOpen ? childrenRect.height : 0
                    clip: true
                    Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutQuart } }
                    
                    ColumnLayout {
                        width: parent.width
                        spacing: 2
                        
                        // Recursive Folder Tree
                        Repeater {
                            model: (uiBridge && uiBridge.folderTree) ? uiBridge.folderTree : []
                            delegate: FolderTreeItem {
                                folderData: modelData
                                onAddSubFolderRequested: (data) => {
                                    sidebarRoot.createSubFolderRequested(data)
                                }
                            }
                        }
                    }
                }
            }
            
            Item { Layout.fillHeight: true } // Spacer
        }
        
        // --- USER PROFILE FOOTER ---
        Rectangle {
            visible: sidebarRoot.expanded
            Layout.fillWidth: true
            Layout.preferredHeight: 60
            color: profileMouse.containsMouse ? "#14FFFFFF" : "transparent"
            radius: 8
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 12
                
                // Avatar Circle
                Rectangle {
                    width: 32; height: 32
                    radius: 16
                    color: "#4F5B66"
                    Text {
                        anchors.centerIn: parent
                        text: {
                            if (!uiBridge || !uiBridge.userName) return "U"
                            var parts = uiBridge.userName.split(" ")
                            if (parts.length >= 2) return (parts[0][0] + parts[1][0]).toUpperCase()
                            return uiBridge.userName.substring(0, 2).toUpperCase()
                        }
                        color: "#FFFFFF"
                        font.pixelSize: 12; font.weight: Font.Bold
                    }
                }
                
                // Info
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    
                    Text {
                        text: (uiBridge) ? uiBridge.userEmail : "user@example.com"
                        color: "#E6EDF3"
                        font.pixelSize: 13
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    
                    Text {
                        text: "vaultlock.local"
                        color: "#8B949E"
                        font.pixelSize: 12
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
                
                // Settings Icon
                SharpIcon {
                    source: Qt.resolvedUrl("../assets/settings.svg")
                    color: "#8B949E"
                    iconSize: 18
                }
            }
            
            MouseArea {
                id: profileMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: sidebarRoot.settingsRequested()
            }
        }
        
        // 3. Collapsed Content - Visible when COLLAPSED (Icon Only)
        ColumnLayout {
            visible: !sidebarRoot.expanded
            opacity: !sidebarRoot.expanded ? 1.0 : 0.0
            Layout.alignment: Qt.AlignHCenter
            spacing: 16
            
            // Basic replications for icons
            Repeater {
                model: [
                    {n: "All", i: "key.svg"},
                    {n: "Favourites", i: "star (1).svg"},
                    {n: "Trash", i: "trash-arrow-up.svg"},
                    {n: "Personal", i: "folder.svg"} // Example folder
                ]
                delegate: Button {
                    Layout.preferredWidth: 48
                    Layout.preferredHeight: 48
                    flat: true
                    background: Rectangle {
                        color: (uiBridge && uiBridge.currentFilter === modelData.n) ? "#14FFFFFF" : "transparent"
                        radius: 8
                    }
                    contentItem: SharpIcon {
                        source: Qt.resolvedUrl("../assets/" + modelData.i)
                        color: "#FFFFFF"
                        anchors.centerIn: parent
                    }
                    onClicked: uiBridge.setFilter(modelData.n)
                    
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.NoButton
                    }
                }
            }
            
            Item { Layout.fillHeight: true }
        }
    }

}
