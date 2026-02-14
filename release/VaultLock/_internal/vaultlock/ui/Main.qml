import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15

ApplicationWindow {
    id: window
    visible: true
    width: 1280
    height: 850
    title: "VaultLock"
    color: "transparent" // Must be transparent for Mica to show through
    
    // 1. Open Maximized
    visibility: Window.Maximized
    
    // 2. Standard System Window (Native Title Bar)
    flags: Qt.Window

    // --- Backend Bridge ---
    // Injected from Python as "uiBridge" context property
    // MockBridge { id: mockBridge } removed
    
    font.family: "Segoe UI"
    font.pixelSize: 14
    
    // --- MAIN CONTENT BACKGROUND ---
    // Places app UI inside solid container, sitting on top of Mica surface (which frames the window)
    // --- MAIN APP CONTENT ---
    Rectangle {
        id: mainAppContent
        anchors.fill: parent
        color: "#0D1117"
        visible: uiBridge && uiBridge.isRegistered && !uiBridge.isLocked
        focus: true

        // Background MouseArea to clear focus from text fields when clicking empty space
        MouseArea {
            anchors.fill: parent
            z: -1 // Ensure it sits behind interactive elements
            onClicked: {
                mainAppContent.forceActiveFocus()
                if (uiBridge) uiBridge.selectedId = ""
            }
        }
        
        RowLayout {
            anchors.fill: parent
            spacing: 0
            
            Sidebar {
                id: sidebar
                Layout.fillHeight: true
                Layout.preferredWidth: width
                onCreateFolderRequested: {
                    var activeFolder = null;
                    if (typeof uiBridge !== 'undefined' && uiBridge && uiBridge.folders) {
                        for (var i = 0; i < uiBridge.folders.length; i++) {
                            if (uiBridge.folders[i].name === uiBridge.currentFilter && uiBridge.folders[i].name !== "No Folder") {
                                activeFolder = uiBridge.folders[i];
                                break;
                            }
                        }
                    }
                    
                    if (activeFolder) {
                        folderDialog.currentParentId = activeFolder.id
                        folderDialog.parentName = activeFolder.name
                    } else {
                        folderDialog.currentParentId = 0
                        folderDialog.parentName = "Root"
                    }
                    folderDialog.open()
                }
                onCreateSubFolderRequested: (folderData) => {
                    folderDialog.currentParentId = folderData.id
                    folderDialog.parentName = folderData.name
                    folderDialog.open()
                }
                onMoreFolderClicked: (folderData) => {
                    folderDetails.folder = folderData
                    folderDetails.open()
                }
                onSettingsRequested: settingsPopup.open()
            }
            
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 17
                    
                    CredentialList {
                        Layout.preferredWidth: 420
                        Layout.minimumWidth: 420
                        Layout.maximumWidth: 420
                        Layout.fillHeight: true
                    }
                    
                    DetailsPanel {
                        id: detailsPanel
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        onDeleteRequested: (id, name) => {
                            credDeleteConfirm.targetId = id
                            credDeleteConfirm.messageText = "Move '" + name + "' to trash? You can restore it later."
                            credDeleteConfirm.open()
                        }
                        onPermanentDeleteRequested: (id, name) => {
                            permDeleteConfirm.targetId = id
                            permDeleteConfirm.messageText = "Permanently delete '" + name + "'? This action cannot be undone."
                            permDeleteConfirm.open()
                        }
                    }
                }
            }
        }
    }

    // --- LOGIN PAGE (LOCK SCREEN) ---
    LoginPage {
        anchors.fill: parent
        visible: uiBridge && uiBridge.isRegistered && uiBridge.isLocked && !uiBridge.registrationMode
        z: 100
    }

    // --- REGISTER PAGE OVERLAY ---
    RegisterPage {
        anchors.fill: parent
        visible: uiBridge && (!uiBridge.isRegistered || uiBridge.registrationMode)
        z: 101
    }

    // --- SETTINGS POPUP ---
    SettingsPopup {
        id: settingsPopup
        anchors.fill: parent
    }
    
    // --- ADD/EDIT CREDENTIAL POPUP ---
    AddCredentialPopup {
        id: credentialPopup
    }
    
    // Auto-open popup when isAddingCredential changes
    Connections {
        target: uiBridge
        function onIsAddingCredentialChanged() {
            if (uiBridge && uiBridge.isAddingCredential) {
                credentialPopup.open()
            } else {
                credentialPopup.close()
                mainAppContent.forceActiveFocus()
            }
        }
    }

    // --- Add Folder Dialog ---
    Dialog {
        id: folderDialog
        anchors.centerIn: parent
        width: 380 // Slightly wider for breathing room
        modal: true
        padding: 24 
        
        property int currentParentId: 0
        property string parentName: "Root"
        property string assignedColor: "#3B82F6" // Default blue
        
        readonly property var colorPalette: ['#3B82F6', '#EF4444', '#10B981', '#F59E0B', '#8B5CF6', '#EC4899', '#06B6D4', '#F97316', '#6366F1', '#14B8A6']

        property bool isDuplicate: {
            if (!uiBridge || !uiBridge.folders) return false;
            var name = folderNameInput.text.trim().toLowerCase();
            // Only check for duplicates among siblings (same parent)
            for (var i = 0; i < uiBridge.folders.length; i++) {
                var folder = uiBridge.folders[i];
                var folderParentId = folder.parent_id || 0;
                if (folder.name.toLowerCase() === name && folderParentId === folderDialog.currentParentId) {
                    return true;
                }
            }
            return false;
        }
        property bool isNameValid: folderNameInput.text.trim().length > 0 && folderNameInput.text.length <= 32 && !isDuplicate
        
        onOpened: {
            folderNameInput.text = ""
            // Pick a random color from the palette when first appearing
            assignedColor = colorPalette[Math.floor(Math.random() * colorPalette.length)]
            folderNameInput.forceActiveFocus()
        }

        background: Rectangle {
            color: "#161B22"
            radius: 16
            border.color: "#30363D"
            border.width: 1
            
            // Soft inner glow/drop shadow effect simulation
            Rectangle {
                anchors.fill: parent
                color: "transparent"
                radius: 16
                border.color: "#FFFFFF"
                opacity: 0.03
                anchors.margins: -1
            }
        }
        
        Overlay.modal: Rectangle {
            color: "#AA000000" // Dimmed backdrop
        }

        contentItem: ColumnLayout {
            spacing: 0
            
            // 1. Header Section
            ColumnLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: 24
                spacing: 4
                
                Label {
                    text: "Create New Folder"
                    color: "white"
                    font.family: "Segoe UI"
                    font.pixelSize: 20
                    font.weight: Font.DemiBold
                    Layout.alignment: Qt.AlignLeft
                }
                
                Label {
                    text: folderDialog.currentParentId === 0 ? "You can create up to 10 folders" : "Creating subfolder inside: " + folderDialog.parentName
                    color: folderDialog.currentParentId === 0 ? "#8B949E" : "#58A6FF"
                    font.pixelSize: 13
                    opacity: 0.8
                    Layout.alignment: Qt.AlignLeft
                }
            }

            // 2. Input Field Section (Including Color Picker)
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 12
                
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    
                    // Folder Icon Preview (Click to Cycle Color)
                    Rectangle {
                        width: 48; height: 48
                        radius: 10
                        color: "#0D1117"
                        border.color: "#30363D"
                        
                        SharpIcon {
                            source: Qt.resolvedUrl("../assets/folder.svg")
                            color: folderDialog.assignedColor
                            iconSize: 22
                            anchors.centerIn: parent
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                // Cycle through the palette
                                var idx = folderDialog.colorPalette.indexOf(folderDialog.assignedColor)
                                folderDialog.assignedColor = folderDialog.colorPalette[(idx + 1) % folderDialog.colorPalette.length]
                            }
                        }
                        
                        ToolTip.visible: mouseAddColor.containsMouse
                        ToolTip.text: "Change Folder Color"
                        MouseArea { id: mouseAddColor; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        
                        TextField {
                            id: folderNameInput
                            Layout.fillWidth: true
                            Layout.preferredHeight: 48
                            placeholderText: "Folder name"
                            color: "white"
                            leftPadding: 16; rightPadding: 16
                            verticalAlignment: TextInput.AlignVCenter
                            
                            background: Rectangle {
                                color: "#0D1117"
                                radius: 8
                                border.color: folderDialog.isDuplicate ? "#FF4444" : (folderNameInput.activeFocus ? "#58A6FF" : "#30363D")
                                border.width: (folderNameInput.activeFocus || folderDialog.isDuplicate) ? 1.5 : 1
                            }

                            Keys.onEnterPressed: folderDialog.createFolderAction()
                            Keys.onReturnPressed: folderDialog.createFolderAction()
                            Keys.onEscapePressed: folderDialog.close()
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    visible: folderNameInput.text.length > 0 || folderDialog.isDuplicate
                    
                    Label {
                        text: "This folder name already exists"
                        color: "#FF4444"
                        font.pixelSize: 11
                        visible: folderDialog.isDuplicate
                        Layout.fillWidth: true
                    }
                    
                    Text { 
                        text: folderNameInput.text.length + " / 32"
                        color: folderNameInput.text.length > 32 ? "#FF4444" : "#4B5563"
                        font.pixelSize: 11
                        visible: folderNameInput.text.length > 0
                    }
                }

                // Small Swatches for quick selection
                Flow {
                    Layout.fillWidth: true
                    Layout.topMargin: 8
                    spacing: 8
                    Repeater {
                        model: folderDialog.colorPalette
                        Rectangle {
                            width: 20; height: 20; radius: 10
                            color: modelData
                            border.color: "white"
                            border.width: folderDialog.assignedColor === modelData ? 2 : 0
                            
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: folderDialog.assignedColor = modelData
                            }
                        }
                    }
                }
            }

            // 3. Button Row
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 32
                spacing: 16
                
                Button {
                    id: cancelBtn
                    text: "Cancel"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 42
                    onClicked: folderDialog.close()
                    
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
                }
                
                Button {
                    id: createBtn
                    text: "Create"
                    enabled: folderDialog.isNameValid
                    Layout.fillWidth: true
                    Layout.preferredHeight: 42
                    onClicked: folderDialog.createFolderAction()
                    
                    contentItem: Text {
                        text: createBtn.text
                        color: "white"
                        font.family: "Segoe UI"
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        opacity: createBtn.enabled ? 1.0 : 0.5
                    }
                    
                    background: Rectangle {
                        color: createBtn.enabled ? (createBtn.hovered ? "#2EA043" : "#238636") : "#1F2328"
                        radius: 10
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }
                }
            }
        }

        function createFolderAction() {
            if (folderDialog.isNameValid && folderNameInput.text) {
                // Count actual folders (excluding "No Folder")
                var folderCount = 0;
                if (uiBridge && uiBridge.folders) {
                    for (var i = 0; i < uiBridge.folders.length; i++) {
                        if (uiBridge.folders[i].name !== "No Folder") {
                            folderCount++;
                        }
                    }
                }
                
                if (folderCount < 10) {
                    uiBridge.createNewFolder(folderNameInput.text, folderDialog.assignedColor, folderDialog.currentParentId)
                    folderDialog.close()
                } else {
                    folderNameInput.placeholderText = "Limit reached (10)!"
                    folderNameInput.text = ""
                }
            }
        }

        // --- Animations ---
        enter: Transition {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 180 }
            NumberAnimation { property: "scale"; from: 0.96; to: 1.0; duration: 180; easing.type: Easing.OutQuart }
        }
        
        exit: Transition {
            NumberAnimation { property: "opacity"; to: 0; duration: 150 }
            NumberAnimation { property: "scale"; to: 0.96; duration: 150; easing.type: Easing.InQuart }
        }
    }

    // --- CONFIRMATION DIALOGS ---
    ConfirmDialog {
        id: credDeleteConfirm
        property string targetId: ""
        titleText: "Move to Trash"
        confirmButtonText: "Move to Trash"
        onConfirmed: {
            if (uiBridge && targetId) {
                uiBridge.deleteCredential(targetId)
            }
        }
    }

    ConfirmDialog {
        id: permDeleteConfirm
        property string targetId: ""
        titleText: "Permanent Delete"
        confirmButtonText: "Permanently Delete"
        onConfirmed: {
            if (uiBridge && targetId) {
                uiBridge.permanentlyDeleteCredential(targetId)
            }
        }
    }

    FolderDetailsPopup {
        id: folderDetails
    }
}
