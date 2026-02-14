import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Dialog {
    id: root
    width: 680
    height: 680
    modal: true
    
    anchors.centerIn: parent
    
    padding: 0
    
    background: Rectangle {
        color: "#161B22"
        radius: 16
        border.color: "#30363D"
        border.width: 1
    }

    Overlay.modal: Rectangle {
        color: "#AA000000"
    }

    // Detect when dialog opens to populate form
    onOpened: {
        if (contentForm) {
            contentForm.resetFields()
            
            // If editing, explicitly set the fields since user input might have broken previous bindings
            if (uiBridge && uiBridge.isEditing && uiBridge.selectedItem) {
                var item = uiBridge.selectedItem
                contentForm.setFields(item)
            }
            
            contentForm.focusFirstField()
        }
    }
    
    onClosed: {
        // Reset the flag when popup closes
        if (uiBridge) {
            uiBridge.isAddingCredential = false
            uiBridge.isEditing = false
        }
    }

    contentItem: ColumnLayout {
        spacing: 0

        // Header
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 60
            Layout.leftMargin: 24
            Layout.rightMargin: 24
            Layout.topMargin: 20
            spacing: 0
            
            Label {
                text: (uiBridge && uiBridge.isEditing) ? "Edit Credential" : "Add New Credential"
                color: "#FFFFFF"
                font.pixelSize: 22
                font.weight: Font.Bold
                Layout.fillWidth: true
            }
            
            Button {
                id: closeBtn
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                flat: true
                padding: 8
                onClicked: root.close()
                
                contentItem: SharpIcon {
                    source: Qt.resolvedUrl("../assets/close.svg")
                    color: "#8A94A6"
                    iconSize: 18
                    anchors.centerIn: parent
                }
                background: Rectangle {
                    color: closeBtn.hovered ? "#30363D" : "transparent"
                    radius: 6
                    
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.NoButton
                    }
                }
            }
        }

        // Separator
        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: 24
            Layout.rightMargin: 24
            height: 1
            color: "#30363D"
        }

        // Form Content
        AddCredentialForm {
            id: contentForm
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 24
            
            onSaveRequested: {
                root.close()
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
