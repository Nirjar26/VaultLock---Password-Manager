import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: registerPage
    anchors.fill: parent
    color: "#0A0A0A"

    // Radial gradient background
    Rectangle {
        anchors.fill: parent
        z: -1
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#1A1A1A" }
            GradientStop { position: 1.0; color: "#0A0A0A" }
        }
    }
    
    // Smooth entrance animation
    opacity: 0
    Component.onCompleted: entranceAnim.start()
    SequentialAnimation {
        id: entranceAnim
        NumberAnimation { target: registerPage; property: "opacity"; to: 1; duration: 600; easing.type: Easing.OutCubic }
    }

    function getStrength(pass) {
        if (!pass) return 0
        var strength = 0
        if (pass.length > 8) strength += 0.25
        if (pass.length > 12) strength += 0.25
        if (/[A-Z]/.test(pass)) strength += 0.25
        if (/[0-9]/.test(pass)) strength += 0.15
        if (/[^A-Za-z0-9]/.test(pass)) strength += 0.1
        return Math.min(strength, 1.0)
    }

    function getStrengthColor(strength) {
        if (strength < 0.3) return "#F85149"
        if (strength < 0.6) return "#D29922"
        return "#3FB950"
    }

    function getStrengthText(strength) {
        if (strength === 0) return ""
        if (strength < 0.3) return "WEAK"
        if (strength < 0.6) return "FAIR"
        if (strength < 0.9) return "STRONG"
        return "VERY SECURE"
    }


    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        contentHeight: mainColumn.height + 80 
        ScrollBar.vertical.policy: ScrollBar.AsNeeded

        ColumnLayout {
            id: mainColumn
            width: Math.min(520, parent.width - 40)
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 40
            spacing: 24

            // === APP HEADER ===
            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 12
                
                Text {
                    text: "VaultLock"
                    font.family: "Segoe UI"
                    font.pixelSize: 28 
                    font.weight: Font.Bold
                    color: "#FFFFFF"
                    Layout.alignment: Qt.AlignHCenter
                }
            }

            // === MAIN CARD ===
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: contentColumn.implicitHeight + 48
                radius: 16
                color: "#161B22"
                border.width: 1
                border.color: "#30363D"

                ColumnLayout {
                    id: contentColumn
                    anchors.fill: parent
                    anchors.margins: 24
                    spacing: 16

                    // Card Header
                    ColumnLayout {
                        spacing: 4 
                        Layout.fillWidth: true
                        
                        Text {
                            text: "Create your Master Vault"
                            font.family: "Segoe UI"
                            font.pixelSize: 20
                            font.weight: Font.DemiBold
                            color: "#FFFFFF"
                        }
                        
                        Text {
                            text: "Your vault is encrypted with your master password."
                            font.family: "Segoe UI"
                            font.pixelSize: 13
                            color: "#7D8590"
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }

                    // === FORM FIELDS ===
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 16

                        // Full Name
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Text { text: "Full Name"; color: "#E6EDF3"; font.family: "Segoe UI"; font.pixelSize: 13; font.weight: Font.Medium }
                            TextField {
                                id: fullNameInput
                                Layout.fillWidth: true
                                Layout.preferredHeight: 46
                                placeholderText: "John Doe"
                                color: "#FFFFFF"
                                font.family: "Segoe UI"; font.pixelSize: 14
                                placeholderTextColor: "#484F58"
                                background: Rectangle { color: "#0D1117"; radius: 8; border.width: parent.activeFocus ? 2 : 1; border.color: parent.activeFocus ? "#58A6FF" : "#30363D" }
                                leftPadding: 10
                            }
                        }

                        // Email
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Text { text: "Email Address"; color: "#E6EDF3"; font.family: "Segoe UI"; font.pixelSize: 13; font.weight: Font.Medium }
                            TextField {
                                id: emailInput
                                Layout.fillWidth: true
                                Layout.preferredHeight: 46
                                placeholderText: "john@example.com"
                                color: "#FFFFFF"
                                font.family: "Segoe UI"; font.pixelSize: 14
                                placeholderTextColor: "#484F58"
                                background: Rectangle { color: "#0D1117"; radius: 8; border.width: parent.activeFocus ? 2 : 1; border.color: parent.activeFocus ? "#58A6FF" : "#30363D" }
                                leftPadding: 10
                            }
                        }

                        // Master Password
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
                                
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    TextField {
                                        id: passwordInput
                                        Layout.fillWidth: true
                                        echoMode: TextInput.Password
                                        color: "#FFFFFF"
                                        font.family: "Segoe UI"; font.pixelSize: 14
                                        background: Item {}
                                        placeholderTextColor: "#484F58"
                                    }
                                }
                            }
                            
                            // Strength Indicator
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "STRENGTH"; font.pixelSize: 9; font.weight: Font.Bold; color: "#8B949E" }
                                    Item { Layout.fillWidth: true }
                                    Text { 
                                        text: getStrengthText(getStrength(passwordInput.text))
                                        font.pixelSize: 9; font.weight: Font.Bold
                                        color: getStrengthColor(getStrength(passwordInput.text))
                                    }
                                }
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 4
                                    Repeater {
                                        model: 4
                                        Rectangle {
                                            Layout.fillWidth: true
                                            height: 3
                                            radius: 1.5
                                            color: {
                                                var s = getStrength(passwordInput.text)
                                                if (s === 0) return "#30363D"
                                                var threshold = (index + 1) * 0.25
                                                return s >= threshold ? getStrengthColor(s) : "#30363D"
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Confirm Password
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Text { text: "Confirm Master Password"; color: "#E6EDF3"; font.family: "Segoe UI"; font.pixelSize: 13; font.weight: Font.Medium }
                            TextField {
                                id: confirmInput
                                Layout.fillWidth: true
                                Layout.preferredHeight: 46
                                echoMode: TextInput.Password
                                color: "#FFFFFF"
                                font.family: "Segoe UI"; font.pixelSize: 14
                                placeholderTextColor: "#484F58"
                                background: Rectangle { 
                                    color: "#0D1117"; radius: 8; 
                                    border.width: parent.activeFocus ? 2 : 1; 
                                    border.color: parent.activeFocus ? (confirmInput.text === passwordInput.text ? "#58A6FF" : "#F85149") : "#30363D" 
                                }
                                leftPadding: 10
                            }
                        }
                    }

                    // === WARNING BOX ===
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: warnLayout.implicitHeight + 24
                        color: "#2C1A1A"
                        radius: 8
                        border.width: 1
                        border.color: "#492323"
                        
                        RowLayout {
                            id: warnLayout
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 12
                            SharpIcon {
                                source: Qt.resolvedUrl("../assets/warning.svg")
                                color: "#F85149"
                                iconSize: 18
                                Layout.alignment: Qt.AlignTop
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                Text { text: "Wait, read this carefully"; color: "#FFFFFF"; font.pixelSize: 13; font.weight: Font.Bold }
                                Text { 
                                    text: "We cannot recover your Master Password. If you forget it, you will lose access to your vault permanently."; 
                                    color: "#E6EDF3"; font.pixelSize: 11; wrapMode: Text.WordWrap; Layout.fillWidth: true; opacity: 0.8
                                }
                            }
                        }
                    }

                    // === CHECKBOX ===
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        CheckBox {
                            id: agreeCheck
                            indicator: Rectangle {
                                implicitWidth: 18; implicitHeight: 18; radius: 4; color: "#0D1117"; border.color: agreeCheck.checked ? "#3FB950" : "#30363D"
                                SharpIcon {
                                    source: Qt.resolvedUrl("../assets/check.svg")
                                    color: "#3FB950"
                                    iconSize: 10
                                    anchors.centerIn: parent
                                    visible: agreeCheck.checked
                                }
                            }
                        }
                        Text { 
                            text: "I understand that VaultLock cannot recover my password and I have written it down securely."; 
                            color: "#8B949E"; font.pixelSize: 12; wrapMode: Text.WordWrap; Layout.fillWidth: true 
                            MouseArea { anchors.fill: parent; onClicked: agreeCheck.checked = !agreeCheck.checked }
                        }
                    }
                    
                    Text {
                        id: regErrorText
                        color: "#F85149"
                        font.pixelSize: 12
                        visible: false
                        Layout.alignment: Qt.AlignHCenter
                    }

                    // === BUTTON ===
                    Button {
                        id: createBtn
                        Layout.fillWidth: true
                        Layout.preferredHeight: 48
                        enabled: fullNameInput.text.length > 0 && emailInput.text.length > 0 && passwordInput.text.length >= 10 && getStrength(passwordInput.text) >= 0.75 && confirmInput.text === passwordInput.text && agreeCheck.checked
                        
                        contentItem: Text {
                            text: "Create Vault"
                            color: "#FFFFFF"
                            font.family: "Segoe UI"; font.pixelSize: 16; font.weight: Font.Bold
                            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                        }
                        
                        background: Rectangle {
                            radius: 8
                            color: createBtn.enabled ? (createBtn.hovered ? "#409eff" : "#58A6FF") : "#21262D"
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: createBtn.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: createBtn.clicked()
                        }

                        onClicked: {
                            regErrorText.visible = false
                            if (uiBridge) {
                                var success = uiBridge.registerVault(fullNameInput.text, emailInput.text, passwordInput.text)
                                if (!success) {
                                    regErrorText.text = "Registration failed. Email might already be in use."
                                    regErrorText.visible = true
                                }
                            }
                        }
                    }
                }
            }

            // === SIGN IN LINK (BOTTOM) ===
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 6
                Layout.bottomMargin: 40 
                visible: uiBridge && uiBridge.isRegistered
                
                Text { 
                    text: "Already have an account?"
                    color: "#7D8590"
                    font.family: "Segoe UI"; font.pixelSize: 14
                }
                
                Text {
                    text: "Sign in"
                    color: "#58A6FF"
                    font.family: "Segoe UI"; font.pixelSize: 14; font.weight: Font.Medium
                    
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                             if (uiBridge) uiBridge.signInBack()
                        }
                    }
                }
            }
        }
    }
}
