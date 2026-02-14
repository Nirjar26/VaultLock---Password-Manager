import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: loginPage
    anchors.fill: parent
    color: "#0A0A0A"
    
    // Radial background
    Rectangle {
        anchors.fill: parent
        z: -1
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#1A1A1A" }
            GradientStop { position: 1.0; color: "#0A0A0A" }
        }
    }

    // Smooth entrance
    opacity: 0
    Component.onCompleted: entranceAnim.start()
    SequentialAnimation {
        id: entranceAnim
        NumberAnimation { 
            target: loginPage
            property: "opacity"
            to: 1
            duration: 600
            easing.type: Easing.OutCubic 
        }
    }


    ColumnLayout {
        id: mainColumn
        anchors.centerIn: parent
        width: 460
        spacing: 32

        // Header
        ColumnLayout {
            Layout.alignment: Qt.AlignLeft
            Layout.fillWidth: true
            spacing: 8
            
            Text {
                text: uiBridge && uiBridge.activeUserId !== 0 ? "Unlock Vault" : "Select Account"
                font.family: "Segoe UI"
                font.pixelSize: 32
                font.weight: Font.Bold
                color: "#FFFFFF"
                Layout.alignment: Qt.AlignLeft
            }
            
            Text {
                text: uiBridge && uiBridge.activeUserId !== 0 ? "Enter master password for " + uiBridge.userName : "Choose an account to continue"
                font.family: "Segoe UI"
                font.pixelSize: 15
                color: "#8B949E"
                Layout.alignment: Qt.AlignLeft
            }
        }

        // Main Card
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: uiBridge && uiBridge.activeUserId !== 0 ? 300 : 400
            radius: 16
            color: "#161B22"
            border.width: 1
            border.color: "#30363D"

            // --- ACCOUNT SELECTION VIEW ---
            ColumnLayout {
                id: userListColumn
                anchors.fill: parent
                anchors.margins: 24
                visible: uiBridge && uiBridge.activeUserId === 0
                spacing: 16

                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: uiBridge ? uiBridge.allUsers : []
                    spacing: 12
                    clip: true
                    
                    Text {
                        anchors.centerIn: parent
                        text: "No vaults found."
                        color: "#8B949E"
                        font.pixelSize: 16
                        visible: parent.count === 0
                    }
                    
                    delegate: Rectangle {
                        width: parent.width
                        height: 72
                        color: userArea.containsMouse ? "#1C2128" : "transparent"
                        radius: 12
                        border.color: userArea.containsMouse ? "#58A6FF" : "#30363D"
                        border.width: userArea.containsMouse ? 2 : 1
                        
                        Behavior on color { ColorAnimation { duration: 150 } }
                        
                        MouseArea {
                            id: userArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (uiBridge) {
                                    uiBridge.selectUser(modelData.id)
                                }
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 16
                            
                            Rectangle {
                                width: 40; height: 40; radius: 20; color: "#238636"
                                Text {
                                    text: modelData.full_name.charAt(0).toUpperCase()
                                    color: "white"
                                    font.pixelSize: 18; font.weight: Font.Bold
                                    anchors.centerIn: parent
                                }
                            }
                            
                            ColumnLayout {
                                spacing: 2
                                Layout.fillWidth: true
                                Text { 
                                    text: modelData.full_name
                                    color: "#FFFFFF"; font.pixelSize: 16; font.weight: Font.DemiBold 
                                    elide: Text.ElideRight
                                }
                                Text { 
                                    text: modelData.email
                                    color: "#8B949E"; font.pixelSize: 13
                                    elide: Text.ElideRight
                                }
                            }
                            
                            Text {
                                text: "→"
                                color: "#8B949E"
                                font.pixelSize: 20
                                visible: userArea.containsMouse
                            }
                        }
                    }
                }

                Button {
                    text: "+ Register New Vault"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52
                    flat: true
                    background: Rectangle {
                        color: parent.hovered ? "#161B22" : "transparent"
                        radius: 8
                        border.color: parent.hovered ? "#30363D" : "transparent"
                    }
                    contentItem: Text {
                        text: "+ Register New Vault"
                        color: "#58A6FF"
                        font.pixelSize: 15; font.weight: Font.Medium
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: uiBridge.enterRegistrationMode()
                }
            }

            // --- PASSWORD UNLOCK VIEW ---
            ColumnLayout {
                id: unlockColumn
                anchors.fill: parent
                anchors.margins: 32
                visible: uiBridge && uiBridge.activeUserId !== 0
                spacing: 24

                // Password Field
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Text { text: "Master Password"; color: "#E6EDF3"; font.family: "Segoe UI"; font.pixelSize: 13; font.weight: Font.Medium }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 46
                        color: "#0D1117"
                        radius: 8
                        border.width: passwordInput.activeFocus ? 2 : 1
                        border.color: passwordInput.activeFocus ? "#58A6FF" : "#30363D"
                        
                        TextField {
                            id: passwordInput
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            echoMode: TextInput.Password
                            color: "#FFFFFF"
                            font.family: "Segoe UI"; font.pixelSize: 14
                            background: Item {}
                            onAccepted: unlockBtn.clicked()
                            placeholderText: "••••••••"
                            placeholderTextColor: "#484F58"
                            focus: uiBridge && uiBridge.activeUserId !== 0
                        }
                    }
                }

                Text {
                    id: errorText
                    color: "#F85149"
                    font.pixelSize: 12
                    visible: false
                    Layout.alignment: Qt.AlignLeft
                }

                // Unlock Button
                Button {
                    id: unlockBtn
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52
                    enabled: passwordInput.text.length > 0 && uiBridge && uiBridge.lockoutRemaining <= 0
                    
                    contentItem: Text {
                        text: (uiBridge && uiBridge.lockoutRemaining > 0) ? "Locked (" + uiBridge.lockoutRemaining + "s)" : "Unlock Vault"
                        color: "#FFFFFF"
                        font.family: "Segoe UI"; font.pixelSize: 16; font.weight: Font.Bold
                        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                    }
                    
                    background: Rectangle {
                        radius: 26
                        color: unlockBtn.enabled ? (unlockBtn.hovered ? "#409eff" : "#58A6FF") : "#21262D"
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }
                    onClicked: {
                        errorText.visible = false
                        if (uiBridge) {
                            var success = uiBridge.unlockVault(passwordInput.text)
                            if (!success) {
                                errorText.text = uiBridge.lockoutRemaining > 0 ? "Account Locked" : "Invalid master password"
                                errorText.visible = true
                                passwordInput.text = ""
                            }
                        }
                    }
                }

                Button {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    flat: true
                    contentItem: Text {
                        text: "← Back to Select Account"
                        color: "#8B949E"
                        font.family: "Segoe UI"; font.pixelSize: 13
                        horizontalAlignment: Text.AlignLeft
                    }
                    onClicked: {
                        passwordInput.text = ""
                        errorText.visible = false
                        uiBridge.selectUser(0)
                    }
                }
            }
        }
    }
}
