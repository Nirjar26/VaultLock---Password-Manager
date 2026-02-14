import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: detailsPanel
    color: "#161B22" // Dark background
    radius: 14
    
    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: {
            detailsPanel.forceActiveFocus()
        }
    }

    // Data Binding
    property var item: (uiBridge && uiBridge.selectedItem) ? uiBridge.selectedItem : {}
    
    // Resolved Logo Path
    property string resolvedLogoPath: {
        if (uiBridge && uiBridge.resolveLogo && item && item.service_name) {
            return uiBridge.resolveLogo(item.service_name, item.website || "")
        }
        return ""
    }

    // Helper to check if we have a valid item selected
    property bool hasItem: (item && item.service_name !== undefined && item.service_name !== "")
    property bool isItemDeleted: (item && item.is_deleted) ? true : false
    
    signal deleteRequested(string id, string name)
    signal permanentDeleteRequested(string id, string name)

    Connections {
        target: uiBridge
        function onLogoUpdated(name, path) {
            if (item && name === item.service_name) {
                resolvedLogoPath = "file:///" + path.replace(/\\/g, "/")
            }
        }
        ignoreUnknownSignals: true
    }

    // Trigger animation when the item changes (only for new IDs)
    property string lastItemId: ""
    onItemChanged: {
        var newId = (item && item.id) ? item.id : ""
        if (newId !== lastItemId) {
            // Reset and refresh logo path to prevent stale logos from sticking
            if (newId !== "" && uiBridge && uiBridge.resolveLogo && item && item.service_name) {
                resolvedLogoPath = uiBridge.resolveLogo(item.service_name, item.website || "")
                triggerEntranceAnimation()
            } else {
                resolvedLogoPath = ""
            }
            lastItemId = newId
        }
    }
    Component.onCompleted: {
        if (item && item.id) {
            triggerEntranceAnimation()
            lastItemId = item.id
        }
    }

    function triggerEntranceAnimation() {
        // 1. Header (Immediate)
        animateItem(headerRow, headerTrans, 0)

        // 2. Content Rows (Staggered)
        // Start delay for rows: 50ms
        var currentDelay = 50
        var stagger = 70

        for (var i = 0; i < fieldsLayout.children.length; i++) {
            var child = fieldsLayout.children[i]
            if (child.animateIn) {
                child.animateIn(currentDelay)
                currentDelay += stagger
            }
        }

        // 3. Notes Section (Continues sequence)
        animateItem(notesSection, notesTrans, currentDelay)
        currentDelay += stagger

        // 4. Footer (Last)
        animateItem(footerSection, footerTrans, currentDelay)
    }

    // Helper to animate generic internal items
    function animateItem(itemObj, transObj, delay) {
        // Reset
        itemObj.opacity = 0
        if (transObj) transObj.y = 15

        // Create a transient animation context or reuse a dedicated one?
        // Since we have fixed IDs for Header/Notes/Footer, we can just use a shared logic 
        // or dedicated animations. Dedicated is smoother.
        
        if (itemObj === headerRow) {
            headerAnim.delayVal = delay
            headerAnim.restart()
        } else if (itemObj === notesSection) {
            notesAnim.delayVal = delay
            notesAnim.restart()
        } else if (itemObj === footerSection) {
            footerAnim.delayVal = delay
            footerAnim.restart()
        }
    }

    // --- EMPTY STATE (Logo Centered) ---
    Item {
        anchors.fill: parent
        visible: !hasItem
        
        Item {
            anchors.centerIn: parent
            width: 350
            height: 350
            
            // Standard Image with Opacity/Scale Animation
            Image {
                id: emptyLogo
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
                source: Qt.resolvedUrl(Qt.resolvedUrl("../assets/VaultLock.png"))
                mipmap: true
                
                // State properties
                opacity: logoHover.containsMouse ? 1.0 : 0.4
                scale: logoHover.containsMouse ? 1.1 : 1.0
                
                // Smooth Transitions
                Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 500; easing.type: Easing.OutBack } }
            }

            MouseArea {
                id: logoHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.ArrowCursor
            }
        }
        
        // Label "Select an item..." removed
    }

    // --- CONTENT LAYOUT ---
    ColumnLayout {
        id: contentLayout
        visible: hasItem
        anchors.fill: parent
        anchors.margins: 32
        spacing: 24
        


        // --- STEP 1: HEADER SECTION ---
        RowLayout {
            id: headerRow
            Layout.fillWidth: true
            Layout.preferredHeight: 64 // Fixed height for header area
            spacing: 16
            
            opacity: 0
            transform: Translate { id: headerTrans; y: 15 }

            SequentialAnimation {
                id: headerAnim
                property int delayVal: 0
                
                ScriptAction { script: { headerRow.opacity = 0; headerTrans.y = 15 } }
                PauseAnimation { duration: headerAnim.delayVal }
                ParallelAnimation {
                    NumberAnimation { target: headerRow; property: "opacity"; to: 1; duration: 500; easing.type: Easing.OutCubic }
                    NumberAnimation { target: headerTrans; property: "y"; to: 0; duration: 500; easing.type: Easing.OutCubic }
                }
            }
            
            // 1. App/Service Icon (48x48)
            CredentialIcon {
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                logoSource: resolvedLogoPath
                name: item.service_name || "Unknown"
                folderColor: (uiBridge && uiBridge.getFolderColor && item.folder) 
                             ? uiBridge.getFolderColor(item.folder) 
                             : "transparent"
                // No parentBackgroundColor needed here as it likely uses its own or transparent? 
                // Let's assume it handles itself.
                // Wait, CredentialIcon usually needs a background for the generic text fallback.
                parentBackgroundColor: "#161B22"
                
                // Override size props internally if needed, but CredentialIcon 
                // might be hardcoded to 40 or 48. Let's check CredentialIcon later.
                // Assuming it scales or we can force it.
            }
            
            // 2. Service Name
            Label {
                text: item.service_name || "Select an Item"
                color: "#E6EAF0"
                font.family: "Segoe UI"
                font.pixelSize: 26
                font.weight: Font.Bold
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                elide: Text.ElideRight
            }
            
            // 3. Right Side Actions
            RowLayout {
                spacing: 12
                Layout.alignment: Qt.AlignVCenter
                
                // Favorite Star
                Button {
                    id: favButton
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    flat: true
                    background: null
                    contentItem: SharpIcon {
                        id: favIcon
                        source: Qt.resolvedUrl("../assets/star (1).svg")
                        color: (item && item.favourite) ? "#EAC54F" : "#8A94A6"
                        iconSize: 16
                        anchors.centerIn: parent
                        
                        transform: Scale {
                            id: favScale
                            origin.x: 10
                            origin.y: 10
                        }
                    }
                    
                    SequentialAnimation {
                        id: favClickAnim
                        NumberAnimation { target: favScale; property: "xScale"; to: 1.4; duration: 100; easing.type: Easing.OutQuad }
                        NumberAnimation { target: favScale; property: "yScale"; to: 1.4; duration: 100; easing.type: Easing.OutQuad }
                        NumberAnimation { target: favScale; property: "xScale"; to: 1.0; duration: 150; easing.type: Easing.InOutQuad }
                        NumberAnimation { target: favScale; property: "yScale"; to: 1.0; duration: 150; easing.type: Easing.InOutQuad }
                    }

                    onClicked: {
                        if (uiBridge && item && item.id) {
                            favClickAnim.restart()
                            uiBridge.toggleFavourite(item.id)
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.NoButton
                    }
                }
                
                // Edit Button
                Button {
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36
                    flat: true
                    visible: !isItemDeleted
                    
                    background: Rectangle {
                        color: parent.hovered ? "#30363D" : "#21262D"
                        radius: 6 
                        border.color: "#30363D"
                        border.width: 1
                    }
                    
                    contentItem: SharpIcon {
                        source: Qt.resolvedUrl("../assets/edit-fill-1480-svgrepo-com.svg")
                        color: "#E6EDF3"
                        iconSize: 13
                        anchors.centerIn: parent
                    }
                    
                    onClicked: {
                        if (uiBridge) {
                            uiBridge.isEditing = true
                            uiBridge.isAddingCredential = true
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.NoButton
                    }
                }

                // Delete Button (Soft)
                Button {
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36
                    flat: true
                    visible: !isItemDeleted
                    
                    background: Rectangle {
                        color: parent.hovered ? "#3E1E1E" : "#21262D"
                        radius: 6 
                        border.color: parent.hovered ? "#F85149" : "#30363D"
                        border.width: 1
                    }
                    
                    contentItem: SharpIcon {
                        source: Qt.resolvedUrl("../assets/trash-arrow-up.svg")
                        color: parent.hovered ? "#F85149" : "#8B949E"
                        iconSize: 13
                        anchors.centerIn: parent
                    }

                    onClicked: {
                        if (item && item.id) {
                            detailsPanel.deleteRequested(item.id, item.service_name)
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.NoButton
                    }
                }

                // --- DELETED MODE BUTTONS ---
                // Restore Button
                Button {
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36
                    flat: true
                    visible: isItemDeleted
                    
                    background: Rectangle {
                        color: parent.hovered ? "#30363D" : "#21262D"
                        radius: 6 
                        border.color: parent.hovered ? "#2EA043" : "#30363D"
                        border.width: 1
                    }
                    
                    contentItem: SharpIcon {
                        source: Qt.resolvedUrl("../assets/trash-arrow-up.svg")
                        color: parent.hovered ? "#2EA043" : "#8B949E"
                        iconSize: 13
                        rotation: 180 // Flip it to point up/restore
                        anchors.centerIn: parent
                    }

                    onClicked: {
                        if (uiBridge && item && item.id) {
                            uiBridge.restoreCredential(item.id)
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.NoButton
                    }
                }

                // Permanent Delete Button
                Button {
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36
                    flat: true
                    visible: isItemDeleted
                    
                    background: Rectangle {
                        color: parent.hovered ? "#490606" : "#21262D"
                        radius: 6 
                        border.color: "#F85149"
                        border.width: 1
                    }
                    
                    contentItem: SharpIcon {
                        source: Qt.resolvedUrl("../assets/trash-arrow-up.svg")
                        color: "#F85149"
                        iconSize: 13
                        anchors.centerIn: parent
                    }

                    onClicked: {
                        if (item && item.id) {
                            detailsPanel.permanentDeleteRequested(item.id, item.service_name)
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.NoButton
                    }
                }
            }
        }
        
        // --- STEP 2: CREDENTIAL FIELDS LIST ---
        ColumnLayout {
            id: fieldsLayout
            Layout.fillWidth: true
            Layout.topMargin: 24
            spacing: 0
            
            DetailRow {
                label: "Username"
                value: (item && item.username) ? item.username : ""
                visible: value !== ""
            }
            
            DetailRow {
                label: "Email"
                value: (item && item.email) ? item.email : ""
                visible: value !== ""
            }
            
            DetailRow {
                label: "Password"
                value: (item && item.password) ? item.password : "********"
                visible: (item && item.password !== undefined)
                isPassword: true
            }


            
            DetailRow {
                label: "Website"
                value: (item && item.website) ? item.website : ""
                visible: value !== ""
                isLink: true
            }
            
            DetailRow {
                id: folderRow
                label: "Folder"
                value: (item && item.folder) ? item.folder : "No Folder"
                isDropdown: true
                onDropdownClicked: folderMenu.open()
                
                Menu {
                    id: folderMenu
                    width: 180
                    y: folderRow.height + 4
                    x: folderRow.width - width
                    
                    background: Rectangle {
                        color: "#161B22"
                        border.color: "#30363D"
                        radius: 10
                        layer.enabled: true
                        // Basic shadow effect simulation
                        Rectangle {
                            anchors.fill: parent
                            color: "transparent"
                            border.color: "#0DFFFFFF"
                            radius: 10
                        }
                    }
                    
                    Repeater {
                        model: (uiBridge && uiBridge.folders) ? uiBridge.folders : []
                        MenuItem {
                            id: mItem
                            height: 36
                            onTriggered: {
                                if (uiBridge && item && item.id) {
                                    uiBridge.updateCredentialFolder(item.id, modelData.name)
                                }
                            }
                            
                            contentItem: RowLayout {
                                spacing: 12
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                
                                SharpIcon {
                                    source: Qt.resolvedUrl("../assets/folder.svg")
                                    color: modelData.color || "#4B5563"
                                    iconSize: 16
                                    Layout.alignment: Qt.AlignVCenter
                                }
                                
                                Text {
                                    text: modelData.name
                                    color: mItem.hovered ? "#FFFFFF" : "#E6EDF3"
                                    font.pixelSize: 13
                                    font.family: "Segoe UI"
                                    verticalAlignment: Text.AlignVCenter
                                    Layout.fillWidth: true
                                }

                                SharpIcon {
                                    source: Qt.resolvedUrl("../assets/check.svg")
                                    color: "#58A6FF"
                                    iconSize: 14
                                    visible: (item && item.folder === modelData.name)
                                    Layout.alignment: Qt.AlignVCenter
                                }
                            }

                            background: Rectangle {
                                color: mItem.hovered ? "#21262D" : "transparent"
                                radius: 6
                                anchors.fill: parent
                                anchors.margins: 4
                            }
                        }
                    }
                }
            }
        }
        
        // Step 8: Notes Section
        ColumnLayout {
            id: notesSection
            Layout.fillWidth: true
            spacing: 8
            
            opacity: 0
            transform: Translate { id: notesTrans; y: 15 }

            SequentialAnimation {
                id: notesAnim
                property int delayVal: 0
                ScriptAction { script: { notesSection.opacity = 0; notesTrans.y = 15 } }
                PauseAnimation { duration: notesAnim.delayVal }
                ParallelAnimation {
                    NumberAnimation { target: notesSection; property: "opacity"; to: 1; duration: 500; easing.type: Easing.OutCubic }
                    NumberAnimation { target: notesTrans; property: "y"; to: 0; duration: 500; easing.type: Easing.OutCubic }
                }
            }
            Layout.topMargin: 0 // Reduced spacing
            
            Label {
                text: "Notes"
                color: "#8B949E"
                font.family: "Segoe UI"
                font.pixelSize: 12
            }
            
            Label {
                text: (item && item.notes) ? item.notes : "No notes available"
                color: (item && item.notes) ? "#E6EDF3" : "#484F58"
                font.family: "Segoe UI"
                font.pixelSize: 14
                font.italic: (item && item.notes) ? false : true
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                lineHeight: 1.4
                visible: !!(item && item.notes && item.notes !== "")
            }
        }
        
        // Spacer to push footer to bottom
        Item { Layout.fillHeight: true } 
        
        // Step 9: Footer Divider (Restored to separate element)
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#21262D"
        }
        
        // Metadata Footer (Height 56px)
        RowLayout {
            id: footerSection
            Layout.fillWidth: true
            Layout.preferredHeight: 56 // Requested height
            Layout.bottomMargin: 0

            opacity: 0
            transform: Translate { id: footerTrans; y: 15 }

            SequentialAnimation {
                id: footerAnim
                property int delayVal: 0
                ScriptAction { script: { footerSection.opacity = 0; footerTrans.y = 15 } }
                PauseAnimation { duration: footerAnim.delayVal }
                ParallelAnimation {
                    NumberAnimation { target: footerSection; property: "opacity"; to: 1; duration: 500; easing.type: Easing.OutCubic }
                    NumberAnimation { target: footerTrans; property: "y"; to: 0; duration: 500; easing.type: Easing.OutCubic }
                }
            }
            
            ColumnLayout {
                Layout.alignment: Qt.AlignVCenter
                spacing: 2
                Label { 
                    text: (item && item.created_at) ? "Created: " + item.created_at : "Created: ---"
                    color: "#8B949E"; font.pixelSize: 12 
                }
                Label { 
                    text: (item && item.updated_at) ? "Modified: " + item.updated_at : "Modified: ---"
                    color: "#8B949E"; font.pixelSize: 12 
                }
            }
            
            Item { Layout.fillWidth: true }
        }
    }
}

