import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Dialog {
    id: root
    width: 480 
    height: 600
    modal: true
    anchors.centerIn: parent
    
    // ✅ POPUP CONTAINER (ROOT)
    padding: 24 
    
    property var folder: null
    property string selectedColor: folder ? (folder.color || "#4B5563") : "#4B5563"
    property int selectedParentId: folder ? (folder.parent_id || 0) : 0
    
    // State Intelligence
    property bool isNameChanged: folder ? (nameInput.text !== folder.name) : false
    property bool isColorChanged: folder ? (selectedColor !== folder.color) : false
    property bool isParentChanged: folder ? (selectedParentId !== (folder.parent_id || 0)) : false
    property bool isChanged: isNameChanged || isColorChanged || isParentChanged
    property bool isNameValid: nameInput.text.trim().length > 0 && nameInput.text.length <= 32

    function saveAction() {
        if (root.folder && isChanged && isNameValid) {
            uiBridge.renameFolder(root.folder.id, nameInput.text)
            uiBridge.updateFolderColor(root.folder.id, root.selectedColor)
            if (isParentChanged) {
                uiBridge.moveFolder(root.folder.id, selectedParentId)
            }
            root.close()
        }
    }

    onOpened: {
        nameInput.forceActiveFocus()
        if (root.folder) {
            selectedParentId = root.folder.parent_id || 0
        }
    }

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

        // 1. Header (Title + Close)
        RowLayout {
            Layout.fillWidth: true
            Layout.bottomMargin: 16
            spacing: 0
            
            Text {
                text: "Folder Details"
                color: "white"
                font.family: "Segoe UI"
                font.pixelSize: 18
                font.bold: true
                Layout.fillWidth: true
            }
            
            Button {
                id: closeBtn
                Layout.preferredWidth: 32; Layout.preferredHeight: 32 
                flat: true
                padding: 8 
                onClicked: root.close()
                
                contentItem: SharpIcon {
                    source: Qt.resolvedUrl("../assets/close.svg")
                    color: "#8A94A6"
                    iconSize: 14
                    anchors.centerIn: parent
                }
                background: Rectangle { color: closeBtn.hovered ? "#30363D" : "transparent"; radius: 6 }
            }
        }

        // 2. Scrollable Content Area
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: -1
            clip: true
            
            ColumnLayout {
                width: parent.width
                spacing: 0 

                // 2. Folder Name Section
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.bottomMargin: 20
                    spacing: 8 
                    
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Folder Name"; color: "#8B949E"; font.pixelSize: 13; Layout.fillWidth: true }
                        Text { 
                            text: nameInput.text.length + "/32"
                            color: nameInput.text.length > 32 ? "#FF4444" : "#4B5563"
                            font.pixelSize: 11
                            Layout.rightMargin: 12 
                        }
                    }

                    TextField {
                        id: nameInput
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44 
                        text: root.folder ? root.folder.name : ""
                        color: "white"
                        topPadding: 12; bottomPadding: 12
                        leftPadding: 16; rightPadding: 40 
                        
                        placeholderText: "Enter name..."
                        focus: true
                        
                        background: Rectangle {
                            color: "#0D1117"
                            radius: 8
                            border.color: !root.isNameValid ? "#FF4444" : (nameInput.activeFocus ? "#58A6FF" : "#30363D")
                            border.width: nameInput.activeFocus || !root.isNameValid ? 1.5 : 1
                            
                            SharpIcon {
                                anchors.right: parent.right
                                anchors.rightMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                source: !root.isNameValid ? Qt.resolvedUrl("../assets/warning.svg") : (root.isNameChanged ? Qt.resolvedUrl("../assets/edit-fill-1480-svgrepo-com.svg") : Qt.resolvedUrl("../assets/check.svg"))
                                color: !root.isNameValid ? "#FF4444" : (root.isNameChanged ? "#58A6FF" : "#2EA043")
                                iconSize: 12
                                visible: nameInput.text.length > 0
                            }
                        }
                    }
                }
                
                // 3. Top Separator
                Rectangle { 
                    Layout.fillWidth: true; height: 1; color: "#30363D" 
                    Layout.bottomMargin: 20 
                }

                // 4. Details Section (Times + Passwords)
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 12 
                    Layout.bottomMargin: 20 
                    
                    RowLayout {
                        spacing: 8
                        Text { text: "Created:"; color: "#8B949E"; font.pixelSize: 12; Layout.preferredWidth: 110 }
                        Text { text: (root.folder ? root.folder.created_at.split(' ')[0] : "---"); color: "#E6EDF3"; font.pixelSize: 13; font.bold: true }
                    }
                    RowLayout {
                        spacing: 8
                        Text { text: "Last Modified:"; color: "#8B949E"; font.pixelSize: 12; Layout.preferredWidth: 110 }
                        Text { text: (root.folder ? root.folder.updated_at.split(' ')[0] : "---"); color: "#E6EDF3"; font.pixelSize: 13; font.bold: true }
                    }
                    RowLayout {
                        spacing: 8
                        Text { text: "Passwords:"; color: "#8B949E"; font.pixelSize: 12; Layout.preferredWidth: 110 }
                        Text { text: (root.folder ? root.folder.item_count : "0"); color: "#E6EDF3"; font.pixelSize: 13; font.bold: true }
                    }
                }

                // 5. Move To Section (Category Selector matching Input Style)
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Layout.bottomMargin: 20
                    
                    Text { text: "Parent Category"; color: "#8B949E"; font.pixelSize: 13 }
                    
                    ComboBox {
                        id: parentCombo
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44 
                        model: {
                            var list = [{id: 0, name: "Root", color: "#8B949E"}]
                            if (uiBridge && uiBridge.folders) {
                                for (var i = 0; i < uiBridge.folders.length; i++) {
                                    var f = uiBridge.folders[i]
                                    if (root.folder && f.id !== root.folder.id && f.name !== "No Folder") {
                                        list.push({id: f.id, name: f.name, color: f.color})
                                    }
                                }
                            }
                            return list
                        }
                        
                        textRole: "name"
                        
                        currentIndex: {
                            for (var i = 0; i < model.length; i++) {
                                if (model[i].id === root.selectedParentId) return i
                            }
                            return 0
                        }
                        
                        onActivated: (index) => {
                            root.selectedParentId = model[index].id
                        }

                        delegate: ItemDelegate {
                            width: parentCombo.width
                            height: 40
                            contentItem: Item {
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 20
                                    anchors.rightMargin: 20
                                    spacing: 12
                                    SharpIcon {
                                        source: Qt.resolvedUrl("../assets/folder.svg")
                                        iconSize: 10
                                        color: modelData.color
                                        width: 10; height: 10
                                    }
                                    Text { 
                                        text: modelData.name
                                        color: "white"
                                        font.family: "Segoe UI"
                                        font.pixelSize: 14
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }
                            }
                            background: Rectangle {
                                color: hovered ? "#21262D" : "transparent"
                                radius: 4
                            }
                        }

                        contentItem: Item {
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 20
                                anchors.rightMargin: 20
                                spacing: 12
                                SharpIcon {
                                    source: Qt.resolvedUrl("../assets/folder.svg")
                                    iconSize: 10
                                    color: parentCombo.model[parentCombo.currentIndex] ? parentCombo.model[parentCombo.currentIndex].color : "#8B949E"
                                    width: 10; height: 10
                                    Layout.alignment: Qt.AlignVCenter
                                }
                                Text {
                                    text: parentCombo.displayText
                                    color: "white"
                                    font.pixelSize: 14
                                    verticalAlignment: Text.AlignVCenter
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }
                        }

                        background: Rectangle {
                            color: "#0D1117"
                            radius: 8
                            border.color: parentCombo.activeFocus ? "#58A6FF" : "#30363D"
                            border.width: parentCombo.activeFocus ? 1.5 : 1
                        }

                        popup: Popup {
                            y: parentCombo.height + 4
                            width: parentCombo.width
                            padding: 4
                            contentItem: ListView {
                                clip: true
                                implicitHeight: contentHeight > 240 ? 240 : contentHeight
                                model: parentCombo.delegateModel
                            }
                            background: Rectangle {
                                color: "#161B22"
                                radius: 8
                                border.color: "#30363D"
                                border.width: 1
                            }
                        }
                    }
                }

                // 6. Bottom Separator
                Rectangle { 
                    Layout.fillWidth: true; height: 1; color: "#30363D" 
                    Layout.bottomMargin: 20 
                }

                // 7. Color Picker Section
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.bottomMargin: 16
                    spacing: 12
                    
                    Text { text: "Folder Icon & Color"; color: "#8B949E"; font.pixelSize: 13 }
                    
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16
                        
                        // Icon Preview
                        Rectangle {
                            width: 40; height: 40 
                            radius: 10
                            color: "#0D1117"
                            border.color: "#30363D"
                            
                            SharpIcon {
                                source: Qt.resolvedUrl("../assets/folder.svg")
                                color: root.selectedColor
                                iconSize: 18
                                anchors.centerIn: parent
                                width: 18; height: 18
                            }
                        }
                        
                        // Color Dots (Swatches)
                        Flow {
                            Layout.fillWidth: true
                            spacing: 12 
                            Repeater {
                                id: colorRepeater
                                model: ['#3B82F6', '#EF4444', '#10B981', '#F59E0B', '#8B5CF6', '#EC4899', '#06B6D4', '#F97316', '#6366F1', '#14B8A6']
                                delegate: Rectangle {
                                    id: swatch
                                    width: 24; height: 24; radius: 12 
                                    color: modelData
                                    border.color: "white"
                                    border.width: root.selectedColor === modelData ? 2 : 0 
                                    activeFocusOnTab: true
                                    
                                    scale: (swatchArea.containsMouse || swatch.activeFocus) ? 1.1 : 1.0 
                                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                                    
                                    Rectangle {
                                        anchors.fill: parent
                                        anchors.margins: -4 
                                        radius: width/2
                                        color: "transparent"
                                        border.color: modelData
                                        border.width: 1
                                        opacity: root.selectedColor === modelData ? 0.3 : 0
                                        visible: root.selectedColor === modelData
                                    }

                                    MouseArea {
                                        id: swatchArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.selectedColor = modelData
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // 8. Action Button Row
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 16 
            spacing: 16 
            
            Button {
                id: deleteBtn
                Layout.preferredHeight: 38 
                onClicked: {
                    deleteConfirm.open()
                }
                
                ConfirmDialog {
                    id: deleteConfirm
                    titleText: "Delete Folder"
                    messageText: folder ? "Permanently delete folder '" + folder.name + "' and its contents? Content will be moved to 'No Folder'." : ""
                    confirmButtonText: "Delete Folder"
                    onConfirmed: {
                        if (root.folder) uiBridge.deleteFolder(root.folder.id)
                        root.close()
                    }
                }
                
                contentItem: Text { 
                    text: "Delete Folder"
                    color: "#FF4444"
                    font.bold: true; font.pixelSize: 13
                    horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                }
                
                background: Rectangle { 
                    color: "transparent"
                    radius: 8; border.color: "#FF4444"; border.width: 1 
                    opacity: deleteBtn.hovered ? 1.0 : 0.8
                }
            }
            
            Item { Layout.fillWidth: true }
            
            Button {
                id: saveBtn
                text: "Save"
                enabled: root.isChanged && root.isNameValid
                Layout.preferredWidth: 100
                Layout.preferredHeight: 38 
                leftPadding: 20; rightPadding: 20
                topPadding: 8; bottomPadding: 8
                
                onClicked: root.saveAction()
                
                contentItem: Text { 
                    text: saveBtn.text
                    color: saveBtn.enabled ? "white" : "#4B5563"
                    font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                }
                
                background: Rectangle { 
                    color: saveBtn.enabled ? (saveBtn.hovered ? "#215EBE" : "#1E60D2") : "#1F2328"
                    radius: 8 
                }
            }
        }
    }
    
    // Transitions
    enter: Transition {
        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200 }
        NumberAnimation { property: "scale"; from: 0.96; to: 1; duration: 250; easing.type: Easing.OutBack }
    }
    
    exit: Transition {
        NumberAnimation { property: "opacity"; to: 0; duration: 150 }
        NumberAnimation { property: "scale"; to: 0.96; duration: 150 }
    }
}
