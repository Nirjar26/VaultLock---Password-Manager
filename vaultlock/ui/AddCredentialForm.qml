import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Flickable {
    id: root
    contentHeight: mainLayout.height
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    
    signal saveRequested()
    
    function resetFields() {
        labelTextField.text = ""
        usernameTextField.text = ""
        emailTextField.text = ""
        websiteTextField.text = ""
        passwordInput.text = ""
        notesTextArea.text = ""
        folderComboBox.currentIndex = 0
        passwordInput.showPassword = false
    }

    function setFields(item) {
        if (!item) return
        labelTextField.text = item.service_name || ""
        usernameTextField.text = item.username || ""
        emailTextField.text = item.email || ""
        websiteTextField.text = item.website || ""
        passwordInput.text = item.password || ""
        
        var notes = item.notes || ""
        if (notes === "[Decryption Failed]" || notes === "[Locked]") {
            notesTextArea.text = ""
        } else {
            notesTextArea.text = notes
        }

        if (item.folder) {
            for (var i = 0; i < folderComboBox.model.length; i++) {
                if (folderComboBox.model[i].name === item.folder) {
                    folderComboBox.currentIndex = i
                    break
                }
            }
        }
    }
    
    function focusFirstField() {
        labelTextField.forceActiveFocus()
    }
    
    ScrollBar.vertical: ScrollBar { 
        policy: ScrollBar.AsNeeded
        width: 6
        background: null
        contentItem: Rectangle {
            color: "#30363D"
            radius: 3
        }
    }

    ColumnLayout {
        id: mainLayout
        width: parent.width
        spacing: 16
        
        // Container 1: Login Credentials
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: container1Layout.implicitHeight + 40
            color: "#1C2128"
            radius: 12
            
            ColumnLayout {
                id: container1Layout
                anchors.fill: parent
                anchors.margins: 20
                spacing: 16
                

                
                ColumnLayout {
                    spacing: 8
                    Layout.fillWidth: true
                    Label { text: "Label"; color: "#8B949E"; font.pixelSize: 12 }
                    TextField {
                        id: labelTextField
                        Layout.fillWidth: true
                        color: "#E6EDF3"
                        padding: 12
                        text: ""
                        background: Rectangle { color: "#0D1117"; radius: 6; border.color: parent.activeFocus ? "#58A6FF" : "#30363D" }
                    }
                }

                ColumnLayout {
                    spacing: 8
                    Layout.fillWidth: true
                    Label { text: "Username"; color: "#8B949E"; font.pixelSize: 12 }
                    TextField {
                        id: usernameTextField
                        Layout.fillWidth: true
                        color: "#E6EDF3"
                        padding: 12
                        text: ""
                        background: Rectangle { color: "#0D1117"; radius: 6; border.color: parent.activeFocus ? "#58A6FF" : "#30363D" }
                    }
                }
                
                ColumnLayout {
                    spacing: 8
                    Layout.fillWidth: true
                    Label { text: "Email"; color: "#8B949E"; font.pixelSize: 12 }
                    TextField {
                        id: emailTextField
                        Layout.fillWidth: true
                        color: "#E6EDF3"
                        padding: 12
                        text: ""
                        background: Rectangle { color: "#0D1117"; radius: 6; border.color: parent.activeFocus ? "#58A6FF" : "#30363D" }
                    }
                }

                ColumnLayout {
                    spacing: 8
                    Layout.fillWidth: true
                    Label { text: "Website"; color: "#8B949E"; font.pixelSize: 12 }
                    TextField {
                        id: websiteTextField
                        Layout.fillWidth: true
                        color: "#E6EDF3"
                        padding: 12
                        text: ""
                        background: Rectangle { color: "#0D1117"; radius: 6; border.color: parent.activeFocus ? "#58A6FF" : "#30363D" }
                    }
                }
            }
        }
        
        // Container 2: Security and Organizations
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: container2Layout.implicitHeight + 40
            color: "#1C2128"
            radius: 12
            
            ColumnLayout {
                id: container2Layout
                anchors.fill: parent
                anchors.margins: 20
                spacing: 16
                


                ColumnLayout {
                    spacing: 8
                    Layout.fillWidth: true
                    Label { text: "Folder"; color: "#8B949E"; font.pixelSize: 12 }
                    ComboBox {
                        id: folderComboBox
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44
                        textRole: "name"
                        model: (uiBridge) ? uiBridge.folders : []
                        currentIndex: 0

                        delegate: ItemDelegate {
                            id: folderDelegate
                            width: folderComboBox.width
                            height: 40
                            leftPadding: 12
                            background: Rectangle {
                                color: folderDelegate.highlighted ? "#1C2128" : "transparent"
                                radius: 4
                                anchors.margins: 2
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                acceptedButtons: Qt.NoButton
                            }
                            contentItem: RowLayout {
                                spacing: 12
                                SharpIcon {
                                    source: Qt.resolvedUrl("../assets/folder.svg")
                                    color: modelData.color
                                    iconSize: 13
                                    Layout.alignment: Qt.AlignVCenter
                                }
                                Text {
                                    text: modelData.name
                                    color: "#E6EDF3"
                                    font.pixelSize: 14
                                    verticalAlignment: Text.AlignVCenter
                                    Layout.fillWidth: true
                                }
                            }
                        }
                        contentItem: RowLayout {
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 12
                            SharpIcon {
                                source: Qt.resolvedUrl("../assets/folder.svg")
                                color: (folderComboBox.currentIndex >= 0 && folderComboBox.model[folderComboBox.currentIndex]) 
                                       ? folderComboBox.model[folderComboBox.currentIndex].color 
                                       : "#4B5563"
                                iconSize: 13
                            }
                            Text {
                                text: folderComboBox.currentText
                                color: "#E6EDF3"
                                font.pixelSize: 14
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignLeft
                                Layout.fillWidth: true
                            }
                        }
                        background: Rectangle {
                            color: "#0D1117"
                            radius: 6
                            border.color: parent.activeFocus ? "#58A6FF" : "#30363D"
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.NoButton
                        }
                    }
                }
                
                ColumnLayout {
                    spacing: 8
                    Layout.fillWidth: true
                    Label { text: "Password"; color: "#8B949E"; font.pixelSize: 12 }
                    
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        TextField {
                            id: passwordInput
                            Layout.fillWidth: true
                            echoMode: showPassword ? TextInput.Normal : TextInput.Password
                            property bool showPassword: false
                            color: "#E6EDF3"
                            padding: 12
                            rightPadding: 40
                            text: ""
                            background: Rectangle { 
                                color: "#0D1117"
                                radius: 6 
                                border.color: parent.activeFocus ? "#58A6FF" : "#30363D" 
                            }
                            
                            Button {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.rightMargin: 8
                                width: 28; height: 28
                                flat: true
                                onClicked: passwordInput.showPassword = !passwordInput.showPassword
                                background: null
                                contentItem: SharpIcon {
                                    source: passwordInput.showPassword 
                                            ? Qt.resolvedUrl("../assets/eye-off-svgrepo-com.svg")
                                            : Qt.resolvedUrl("../assets/eye-svgrepo-com.svg")
                                    color: "#FFFFFF"
                                    iconSize: 14
                                    anchors.centerIn: parent
                                }
                                
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    acceptedButtons: Qt.NoButton
                                }
                            }
                        }
                        
                        Button {
                            Layout.preferredWidth: 44
                            Layout.preferredHeight: 44
                            flat: true
                            onClicked: passwordInput.text = root.generatePassword(16)
                            background: Rectangle {
                                color: parent.hovered ? "#30363D" : "#21262D"
                                radius: 6
                                border.color: "#30363D"
                                border.width: 1
                            }
                            contentItem: SharpIcon {
                                source: Qt.resolvedUrl("../assets/magic-wand.svg")
                                color: "#8B949E"
                                iconSize: 18
                                anchors.centerIn: parent
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                acceptedButtons: Qt.NoButton
                            }
                        }
                    }
                    
                    Rectangle {
                        Layout.fillWidth: true
                        height: 4
                        color: "#0D1117"
                        radius: 2
                        Rectangle {
                            width: parent.width * root.getStrength(passwordInput.text)
                            height: 4
                            radius: 2
                            color: root.getStrengthColor(root.getStrength(passwordInput.text))
                            Behavior on width { NumberAnimation { duration: 300 } }
                        }
                    }
                    
                    Label {
                        text: root.getStrengthText(root.getStrength(passwordInput.text))
                        color: root.getStrengthColor(root.getStrength(passwordInput.text))
                        font.pixelSize: 11
                    }
                }


            }
        }

        // Container 3: Additional Details
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: container3Layout.implicitHeight + 40
            color: "#1C2128"
            radius: 12
            
            ColumnLayout {
                id: container3Layout
                anchors.fill: parent
                anchors.margins: 20
                spacing: 16
                

                
                ColumnLayout {
                    spacing: 8
                    Layout.fillWidth: true
                    Label { text: "Notes"; color: "#8B949E"; font.pixelSize: 12 }
                    TextArea {
                        id: notesTextArea
                        Layout.fillWidth: true
                        Layout.preferredHeight: 100
                        color: "#E6EDF3"
                        padding: 12
                        wrapMode: TextEdit.Wrap
                        text: ""
                        placeholderText: "Enter notes here..."
                        background: Rectangle { color: "#0D1117"; radius: 6; border.color: parent.activeFocus ? "#58A6FF" : "#30363D" }
                    }
                }
            }
        }
        
        Button {
            id: saveBtn
            Layout.preferredWidth: 220
            Layout.preferredHeight: 44
            Layout.alignment: Qt.AlignHCenter
            text: (uiBridge && uiBridge.isEditing) ? "Update Credential" : "Save Credential"
            contentItem: Text {
                text: parent.text
                color: "white"
                font.weight: Font.Bold
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                color: parent.pressed ? "#238636" : "#2EA043"
                radius: 6
            }
            
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.NoButton
            }
            onClicked: {
                if (uiBridge) {
                    var formData = {
                        "service_name": labelTextField.text,
                        "username": usernameTextField.text,
                        "email": emailTextField.text,
                        "website": websiteTextField.text,
                        "folder": folderComboBox.currentText,
                        "password": passwordInput.text,
                        "notes": notesTextArea.text,

                        "favourite": uiBridge.isEditing ? (uiBridge.selectedItem ? uiBridge.selectedItem.favourite : false) : false
                    }
                    
                    if (uiBridge.isEditing) {
                        formData["id"] = uiBridge.selectedId
                        uiBridge.updateCredential(formData)
                    } else {
                        uiBridge.addCredential(formData)
                    }
                    uiBridge.isEditing = false
                    root.saveRequested()
                }
            }
        }

        Item { Layout.preferredHeight: 20 }
    }

    function getStrength(pass) {
        if (!pass) return 0
        var s = 0
        if (pass.length >= 8) s += 0.2
        if (pass.length >= 12) s += 0.2
        if (/[A-Z]/.test(pass)) s += 0.15
        if (/[0-9]/.test(pass)) s += 0.15
        if (/[^A-Za-z0-9]/.test(pass)) s += 0.3
        return Math.min(1.0, s)
    }

    function getStrengthColor(val) {
        if (val < 0.3) return "#F85149"
        if (val < 0.7) return "#EAC54F"
        return "#2EA043"
    }

    function getStrengthText(val) {
        if (val === 0) return ""
        if (val < 0.3) return "Weak password"
        if (val < 0.7) return "Medium strength"
        return "Strong password"
    }

    function generatePassword(length) {
        if (uiBridge && uiBridge.generateSecurePassword) {
            return uiBridge.generateSecurePassword(length, true, true, true)
        }
        var charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()_+"
        var retVal = ""
        for (var i = 0; i < length; ++i) {
            retVal += charset.charAt(Math.floor(Math.random() * charset.length))
        }
        return retVal
    }
}
