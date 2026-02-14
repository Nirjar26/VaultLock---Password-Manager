import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: settingsRoot
    
    property alias settingsDialog: settingsDialog
    property alias confirmReset: confirmReset
    property alias changePasswordDialog: changePasswordDialog
    property alias pinSetupDialog: pinSetupDialog
    property alias verifyPinToRemove: verifyPinToRemove

    function open() { settingsDialog.open() }
    function close() { settingsDialog.close() }

    Dialog {
        id: settingsDialog
        anchors.centerIn: parent
        width: 950
        height: 700
        modal: true
        padding: 0
        
        property string activeDetailTitle: ""
        property string activeDetailText: ""
        property bool showingDetail: false

        function showDetail(title, text) {
            activeDetailTitle = title
            activeDetailText = text
            showingDetail = true
        }

        background: Rectangle {
            color: "#0D1117"
            radius: 12
            border.color: "#30363D"
            border.width: 1
        }

        Overlay.modal: Rectangle {
            color: "#AA000000"
        }

        contentItem: RowLayout {
            spacing: 0
            
            // --- Sidebar Navigation ---
            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: 260
                color: "#161B22"
                radius: 12
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 4
                    
                    Text {
                        text: "Settings"
                        color: "white"
                        font.family: "Segoe UI"; font.pixelSize: 22; font.weight: Font.DemiBold
                        Layout.alignment: Qt.AlignLeft
                        Layout.bottomMargin: 24
                        padding: 4
                    }
                    
                    Repeater {
                        model: [
                            { name: "App Lock & Security" },
                            { name: "Privacy" },
                            { name: "App Behavior" },
                            { name: "Data Management", danger: true },
                            { name: "About" }
                        ]
                        
                        delegate: ItemDelegate {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 48
                            
                            background: Rectangle {
                                color: settingsStack.currentIndex === index ? "#21262D" : (hovered ? "#30363D" : "transparent")
                                radius: 10
                            }
                            
                            contentItem: RowLayout {
                                spacing: 0
                                anchors.leftMargin: 8
                                Text { 
                                    text: modelData.name
                                    color: settingsStack.currentIndex === index ? "#58A6FF" : (modelData.danger ? "#F85149" : "#8B949E")
                                    font.family: "Segoe UI"; font.pixelSize: 15
                                    font.weight: settingsStack.currentIndex === index ? Font.Medium : Font.Normal
                                    Layout.fillWidth: true
                                }
                            }
                            onClicked: {
                                settingsStack.currentIndex = index
                                settingsDialog.showingDetail = false
                            }
                        }
                    }
                    
                    Item { Layout.fillHeight: true }
                    
                    // --- Session Controls ---
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Layout.bottomMargin: 16

                        Button {
                            id: settingsLogoutBtn
                            text: "Log Out"
                            Layout.fillWidth: true
                            Layout.preferredHeight: 38
                            onClicked: {
                                if (uiBridge) {
                                    uiBridge.logout()
                                    settingsDialog.close()
                                }
                            }
                            background: Rectangle { 
                                color: settingsLogoutBtn.hovered ? "#30363D" : "#21262D"
                                radius: 8
                                border.color: "#30363D"
                            }
                            contentItem: RowLayout {
                                spacing: 8
                                anchors.centerIn: parent
                                SharpIcon { source: Qt.resolvedUrl("../assets/arrow-back.svg"); color: "#F85149"; iconSize: 12 }
                                Text { text: "Log Out"; color: "#F85149"; font.pixelSize: 13; font.weight: Font.Medium }
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: settingsLogoutBtn.clicked()
                            }
                        }
                    }

                    Button {
                        id: settingsCloseBtn
                        text: "Close"
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        onClicked: settingsDialog.close()
                        background: Rectangle { color: "#21262D"; radius: 8; border.color: "#30363D" }
                        contentItem: Text { 
                            text: "Close"
                            color: "white"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.weight: Font.Medium 
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: settingsCloseBtn.clicked()
                        }
                    }
                }
            }
            
            // --- Content Area ---
            StackLayout {
                id: settingsStack
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: 0
                
                // 1. App Lock & Security
                SettingsSection {
                    title: "App Lock & Security"
                    ColumnLayout {
                        spacing: 0; Layout.fillWidth: true
                        
                        SettingsItem {
                            label: "Master Password"
                            description: "Update your master vault password. Requires current password to change."
                            actionText: "Change"
                            onClicked: changePasswordDialog.open()
                        }
                        
                        SettingsItem {
                            label: "Quick PIN Setup"
                            description: "Unlock your vault with a 4-digit code instead of your master password."
                            actionText: (uiBridge && uiBridge.isPinSet) ? "Remove PIN" : "Setup PIN"
                            onClicked: {
                                if (uiBridge && uiBridge.isPinSet) {
                                    verifyPinToRemove.open()
                                } else {
                                    pinSetupDialog.open()
                                }
                            }
                        }
                        
                        SettingsDropdown {
                            label: "Failed attempts limit"
                            description: "Number of incorrect entries allowed before a temporary lockout is applied."
                            options: ["3 attempts", "5 attempts", "10 attempts", "Disabled"]
                            currentIndex: (typeof uiBridge !== "undefined" && uiBridge) ? 1 : 1
                            onOptionSelected: (option) => { if(typeof uiBridge !== "undefined" && uiBridge) uiBridge.setSetting("failed_attempts_limit", option.split(" ")[0]) }
                        }

                        SettingsDropdown {
                            label: "Clipboard auto-clear"
                            description: "Time to wait before clearing sensitive password data from your system clipboard."
                            options: ["10s", "30s", "60s", "120s", "Never"]
                            currentIndex: 1
                            onOptionSelected: (option) => { if(typeof uiBridge !== "undefined" && uiBridge) uiBridge.setSetting("clipboard_clear_time", option.replace("s", "")) }
                        }
                    }
                }
                
                // 2. Privacy
                SettingsSection {
                    title: "Privacy Controls"
                    ColumnLayout {
                        spacing: 0; Layout.fillWidth: true
                        
                        SettingsToggle {
                            label: "Hide passwords by default"
                            description: "Mask password fields in the vault until the eye icon is clicked."
                            checked: (typeof uiBridge !== "undefined" && uiBridge) ? uiBridge.hidePasswordsDefault : true
                            onToggled: (checked) => { if(typeof uiBridge !== "undefined" && uiBridge) uiBridge.setSetting("hide_passwords_default", checked ? "1" : "0") }
                        }
                        
                        SettingsToggle {
                            label: "Disable screenshots"
                            description: "Prevents screen sharing apps and local screenshots from capturing sensitive vault data."
                            checked: false
                            onToggled: (checked) => { if(typeof uiBridge !== "undefined" && uiBridge) uiBridge.setSetting("disable_screenshots", checked ? "1" : "0") }
                        }
                        
                        SettingsToggle {
                            label: "Clear clipboard on app close"
                            description: "Wipes any copied passwords from the clipboard when VaultLock is terminated."
                            checked: false
                            onToggled: (checked) => { if(typeof uiBridge !== "undefined" && uiBridge) uiBridge.setSetting("clear_clipboard_on_exit", checked ? "1" : "0") }
                        }
                    }
                }
                
                // 3. App Behavior
                SettingsSection {
                    title: "Preferences & Behavior"
                    ColumnLayout {
                        spacing: 0; Layout.fillWidth: true
                        
                        SettingsDropdown {
                            label: "Default screen on launch"
                            description: "The view you land on after unlocking your vault."
                            options: ["All Items", "Favourites"]
                            onOptionSelected: (option) => { if(typeof uiBridge !== "undefined" && uiBridge) uiBridge.setSetting("launch_screen", option) }
                        }

                        SettingsToggle {
                            label: "Remember last opened item"
                            description: "Automatically re-open the last viewed credential when you log in."
                            checked: false
                            onToggled: (checked) => { if(typeof uiBridge !== "undefined" && uiBridge) uiBridge.setSetting("remember_last_item", checked ? "1" : "0") }
                        }
                    }
                }
                
                // 4. Data Management
                SettingsSection {
                    title: "Vault Maintenance"
                    ColumnLayout {
                        spacing: 0; Layout.fillWidth: true
                        
                        SettingsItem {
                            label: "Factory Reset"
                            description: "This will PERMANENTLY erase all data, settings, and folders."
                            actionText: "Wipe Vault"
                            isDanger: true
                            onClicked: confirmReset.open()
                        }
                    }
                }
                
                // 5. About
                SettingsSection {
                    title: settingsDialog.showingDetail ? settingsDialog.activeDetailTitle : "About & Legal"
                    
                    ColumnLayout {
                        id: aboutListView
                        spacing: 0; Layout.fillWidth: true
                        opacity: settingsDialog.showingDetail ? 0 : 1
                        visible: opacity > 0
                        
                        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }

                        RowLayout {
                            Layout.fillWidth: true; Layout.leftMargin: 32; Layout.rightMargin: 32; Layout.topMargin: 16; Layout.bottomMargin: 32; spacing: 24
                            
                            Rectangle { 
                                width: 24; height: 24; radius: 12; clip: true; color: "transparent"
                                Image { 
                                    anchors.fill: parent
                                    source: Qt.resolvedUrl("../assets/VaultLock_windowicon.ico")
                                    fillMode: Image.PreserveAspectFit
                                }
                            }
                            
                            ColumnLayout {
                                spacing: 4
                                Text { text: "VaultLock for Desktop"; color: "white"; font.bold: true; font.pixelSize: 22; font.family: "Segoe UI Semibold" }
                                Text { text: "Version 1.2.4 • Stable Build • 2026"; color: "#8B949E"; font.pixelSize: 14 }
                                Rectangle { height: 1; width: 40; color: "#58A6FF"; opacity: 0.5; Layout.topMargin: 4 }
                            }
                        }
                        

                        SettingsItem { 
                            label: "Encryption Specs"
                            description: "Industry-standard AES-256-GCM. Hardware-level security."
                            actionText: "Specs"
                            onClicked: settingsDialog.showDetail("Encryption Specs", 
                                "VaultLock utilizes AES-256-GCM encryption for all sensitive data stored in your local vault. " +
                                "Key derivation is handled via PBKDF2-HMAC-SHA256 with 600,000 iterations to prevent brute-force attacks.\n\n" +
                                "• Algorithm: AES-256-GCM\n" +
                                "• KDF: PBKDF2-HMAC-SHA256\n" +
                                "• Iterations: 600,000\n" +
                                "• Storage: SQLite Encrypted (SQLCipher compatible)\n" +
                                "• Local First: No cloud synchronization ensures your data never leaves your device.") 
                        }
                        SettingsItem { 
                            label: "Privacy Policy"
                            description: "We never see your data. Offline-first philosophy."
                            actionText: "View"
                            onClicked: settingsDialog.showDetail("Privacy Policy", 
                                "Your privacy is our core mission. VaultLock is designed as an offline-first application.\n\n" +
                                "• Zero Tracking: We do not collect telemetry or usage data.\n" +
                                "• Local Storage: All credentials and notes are stored strictly on your local machine.\n" +
                                "• No Accounts: We don't require external accounts, meaning we have no access to your master password or encryption keys.") 
                        }
                        SettingsItem { 
                            label: "Terms of Service"
                            description: "Usage guidelines and local data ownership."
                            actionText: "Read"
                            onClicked: settingsDialog.showDetail("Terms of Service", 
                                "By using VaultLock, you acknowledge that you are the sole owner and protector of your Master Password.\n\n" +
                                "• Ownership: You own your data. You are responsible for creating backups.\n" +
                                "• Liability: VaultLock is provided 'as-is'. We are not responsible for data loss due to forgotten passwords.\n" +
                                "• Open Source: This software is licensed under the MIT License.") 
                        }
                        SettingsItem { 
                            label: "Report a Bug"
                            description: "Help us improve VaultLock by reporting issues."
                            actionText: "Support"
                            onClicked: settingsDialog.showDetail("Support", 
                                "Found an issue? We'd love to hear from you.\n\n" +
                                "You can report bugs or request new features on our community forums or GitHub repository.\n\n" +
                                "Contact: nirjargoswami2626@gmail.com\n" +
                                "GitHub: github.com/vaultlock/desktop") 
                        }
                        SettingsItem { label: "Developer credits"; description: "Nirjar Goswami"; showAction: false }
                    }

                    // Detail View
                    ColumnLayout {
                        id: aboutDetailView
                        Layout.fillWidth: true
                        Layout.leftMargin: 32
                        Layout.rightMargin: 32
                        spacing: 24
                        opacity: settingsDialog.showingDetail ? 1 : 0
                        visible: opacity > 0
                        
                        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }

                        Button {
                            id: backBtn
                            onClicked: settingsDialog.showingDetail = false
                            Layout.topMargin: 16
                            
                            background: Rectangle { 
                                color: backBtn.hovered ? "#21262D" : "transparent"
                                radius: 8
                                border.color: backBtn.hovered ? "#30363D" : "transparent"
                                border.width: 1
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                            
                            contentItem: RowLayout {
                                spacing: 10
                                SharpIcon {
                                    source: Qt.resolvedUrl("../assets/arrow-back.svg")
                                    color: "#58A6FF"
                                    iconSize: 11
                                }
                                Text { text: "Back to About"; color: "#58A6FF"; font.pixelSize: 14; font.weight: Font.Medium; verticalAlignment: Text.AlignVCenter }
                            }
                        }

                        ScrollView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.bottomMargin: 20
                            clip: true
                            contentWidth: availableWidth

                            ColumnLayout {
                                width: parent.width
                                spacing: 16
                                
                                Text {
                                    text: settingsDialog.activeDetailText
                                    color: "#E6EDF3"
                                    font.family: "Segoe UI"; font.pixelSize: 15
                                    lineHeight: 1.6
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                    font.weight: Font.Normal
                                }
                                
                                Item { Layout.preferredHeight: 20 } // Bottom padding
                            }
                            
                            ScrollBar.vertical: ScrollBar { 
                                active: true
                                width: 8
                                background: null
                                contentItem: Rectangle { color: "#30363D"; radius: 4 }
                            }
                        }
                    }
                }
            }
        }
    }

    Dialog {
        id: confirmReset
        anchors.centerIn: parent
        width: 440
        modal: true
        padding: 24
        
        background: Rectangle { 
            color: "#161B22"
            radius: 16
            border.color: "#30363D"
            border.width: 1
        }

        Overlay.modal: Rectangle { color: "#AA000000" }
        
        contentItem: ColumnLayout {
            spacing: 0
            
            ColumnLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: 24
                spacing: 8
                
                Label {
                    text: "Danger: Permanent Deletion"
                    color: "white"
                    font.family: "Segoe UI"
                    font.pixelSize: 20
                    font.weight: Font.DemiBold
                    Layout.alignment: Qt.AlignLeft
                }
                
                Label {
                    text: "This operation will completely purge your local vault data. This cannot be undone."
                    color: "#8B949E"
                    font.pixelSize: 14
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignLeft
                }
            }
            
            TextField {
                id: confirmPass
                Layout.fillWidth: true
                Layout.preferredHeight: 46
                Layout.bottomMargin: 24
                placeholderText: "Authorize with Master Password"
                echoMode: TextInput.Password
                color: "white"
                leftPadding: 16
                background: Rectangle { 
                    color: "#0D1117"
                    radius: 10
                    border.color: confirmPass.activeFocus ? "#F85149" : "#30363D"
                }
            }
            
            RowLayout {
                Layout.fillWidth: true
                spacing: 16
                
                Button { 
                    id: cancelResetBtn
                    text: "Cancel"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 42
                    onClicked: confirmReset.close()
                    background: Rectangle { color: cancelResetBtn.hovered ? "#30363D" : "#21262D"; radius: 10 }
                    contentItem: Text { text: "Cancel"; color: "white"; font.family: "Segoe UI"; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                }
                
                Button { 
                    id: wipeBtn; text: "AUTHORIZE WIPE"; enabled: confirmPass.text.length > 0
                    Layout.fillWidth: true
                    Layout.preferredHeight: 42
                    onClicked: {
                        if (uiBridge.unlockVault(confirmPass.text)) {
                            uiBridge.wipeAllData();
                            confirmReset.close();
                            settingsDialog.close();
                        }
                    }
                    background: Rectangle { color: wipeBtn.enabled ? (wipeBtn.hovered ? "#FF4444" : "#F85149") : "#2C1A1A"; radius: 10 }
                    contentItem: Text { text: "AUTHORIZE WIPE"; color: "white"; font.family: "Segoe UI"; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                }
            }
        }
    }

    Dialog {
        id: changePasswordDialog
        anchors.centerIn: parent
        width: 440
        modal: true
        padding: 24
        
        background: Rectangle { 
            color: "#161B22"
            radius: 16
            border.color: "#30363D"
            border.width: 1
        }

        Overlay.modal: Rectangle { color: "#AA000000" }
        
        contentItem: ColumnLayout {
            spacing: 0
            
            ColumnLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: 24
                spacing: 8
                
                Label {
                    text: "Update Master Password"
                    color: "white"
                    font.family: "Segoe UI"
                    font.pixelSize: 20
                    font.weight: Font.DemiBold
                    Layout.alignment: Qt.AlignLeft
                }
                
                Label {
                    text: "Enter your current password and choose a strong new one."
                    color: "#8B949E"
                    font.pixelSize: 14
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignLeft
                }
            }
            
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 12
                Layout.bottomMargin: 24
                
                TextField {
                    id: oldPassInput
                    Layout.fillWidth: true; Layout.preferredHeight: 46
                    placeholderText: "Current Master Password"
                    echoMode: TextInput.Password
                    color: "white"
                    leftPadding: 16
                    background: Rectangle { color: "#0D1117"; radius: 10; border.color: oldPassInput.activeFocus ? "#58A6FF" : "#30363D" }
                }
                
                TextField {
                    id: newPassInput
                    Layout.fillWidth: true; Layout.preferredHeight: 46
                    placeholderText: "New Master Password"
                    echoMode: TextInput.Password
                    color: "white"
                    leftPadding: 16
                    background: Rectangle { color: "#0D1117"; radius: 10; border.color: newPassInput.activeFocus ? "#58A6FF" : "#30363D" }
                }
                
                TextField {
                    id: confirmNewPassInput
                    Layout.fillWidth: true; Layout.preferredHeight: 46
                    placeholderText: "Confirm New Master Password"
                    echoMode: TextInput.Password
                    color: "white"
                    leftPadding: 16
                    background: Rectangle { 
                        color: "#0D1117"; radius: 10; 
                        border.color: (confirmNewPassInput.text === newPassInput.text) ? (confirmNewPassInput.activeFocus ? "#58A6FF" : "#30363D") : "#F85149"
                    }
                }
            }
            
            Label {
                id: changeStatusLabel
                text: ""
                color: "#F85149"
                font.pixelSize: 12
                Layout.alignment: Qt.AlignHCenter
                Layout.bottomMargin: 16
                visible: text !== ""
            }
            
            RowLayout {
                Layout.fillWidth: true
                spacing: 16
                
                Button { 
                    id: cancelChangeBtn
                    text: "Cancel"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 42
                    onClicked: changePasswordDialog.close()
                    background: Rectangle { color: cancelChangeBtn.hovered ? "#30363D" : "#21262D"; radius: 10 }
                    contentItem: Text { text: "Cancel"; color: "white"; font.family: "Segoe UI"; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                }
                
                Button { 
                    id: confirmChangeBtn; text: "Update"
                    enabled: oldPassInput.text.length > 0 && newPassInput.text.length >= 8 && confirmNewPassInput.text === newPassInput.text
                    Layout.fillWidth: true
                    Layout.preferredHeight: 42
                    onClicked: {
                        if (uiBridge.changeMasterPassword(oldPassInput.text, newPassInput.text)) {
                            changePasswordDialog.close();
                            oldPassInput.clear();
                            newPassInput.clear();
                            confirmNewPassInput.clear();
                            changeStatusLabel.text = "";
                        } else {
                            changeStatusLabel.text = "Incorrect current password or error.";
                        }
                    }
                    background: Rectangle { color: confirmChangeBtn.enabled ? (confirmChangeBtn.hovered ? "#388BFD" : "#1F6FEB") : "#1E293B"; radius: 10 }
                    contentItem: Text { text: "Update"; color: "white"; font.family: "Segoe UI"; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                }
            }
        }
    }

    Dialog {
        id: pinSetupDialog
        anchors.centerIn: parent
        width: 380
        modal: true
        padding: 24
        
        background: Rectangle { 
            color: "#161B22"
            radius: 16
            border.color: "#30363D"
            border.width: 1
        }

        Overlay.modal: Rectangle { color: "#AA000000" }
        
        contentItem: ColumnLayout {
            spacing: 0
            
            ColumnLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: 24
                spacing: 8
                
                Label {
                    text: "Setup Quick PIN"
                    color: "white"
                    font.family: "Segoe UI"
                    font.pixelSize: 20
                    font.weight: Font.DemiBold
                    Layout.alignment: Qt.AlignLeft
                }
                
                Label {
                    text: "Use this PIN to quickly unlock your vault."
                    color: "#8B949E"
                    font.pixelSize: 14
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignLeft
                }
            }
            
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 70
                Layout.bottomMargin: 24
                color: "#0D1117"
                radius: 12
                border.color: pinInput.activeFocus ? "#58A6FF" : "#30363D"
                
                TextField {
                    id: pinInput
                    anchors.centerIn: parent
                    width: 180; height: 40
                    placeholderText: "0 0 0 0"
                    echoMode: TextInput.Password
                    horizontalAlignment: TextInput.AlignHCenter
                    verticalAlignment: TextInput.AlignVCenter
                    font.pixelSize: 24; font.letterSpacing: 8
                    color: "white"
                    maximumLength: 4
                    focus: true
                    validator: RegularExpressionValidator { regularExpression: /[0-9]{0,4}/ }
                    background: null
                }
            }
            
            RowLayout {
                Layout.fillWidth: true
                spacing: 16
                
                Button { 
                    id: cancelPinBtn
                    text: "Cancel"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 42
                    onClicked: pinSetupDialog.close()
                    background: Rectangle { color: cancelPinBtn.hovered ? "#30363D" : "#21262D"; radius: 10 }
                    contentItem: Text { text: "Cancel"; color: "white"; font.family: "Segoe UI"; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                }
                
                Button { 
                    id: confirmPinBtn; text: "Save"
                    enabled: pinInput.text.length === 4
                    Layout.fillWidth: true
                    Layout.preferredHeight: 42
                    onClicked: {
                        uiBridge.setPin(pinInput.text);
                        pinSetupDialog.close();
                        pinInput.clear();
                    }
                    background: Rectangle { color: confirmPinBtn.enabled ? (confirmPinBtn.hovered ? "#388BFD" : "#1F6FEB") : "#1E293B"; radius: 10 }
                    contentItem: Text { text: "Save"; color: "white"; font.family: "Segoe UI"; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                }
            }
        }
    }

    Dialog {
        id: verifyPinToRemove
        anchors.centerIn: parent
        width: 380
        modal: true
        padding: 24
        
        background: Rectangle { 
            color: "#161B22"
            radius: 16
            border.color: "#30363D"
            border.width: 1
        }

        Overlay.modal: Rectangle { color: "#AA000000" }
        
        contentItem: ColumnLayout {
            spacing: 0
            
            ColumnLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: 24
                spacing: 8
                
                Label {
                    text: "Confirm PIN Removal"
                    color: "white"
                    font.family: "Segoe UI"
                    font.pixelSize: 20
                    font.weight: Font.DemiBold
                    Layout.alignment: Qt.AlignLeft
                }
                
                Label {
                    text: "Please enter your current PIN to disable quick unlock."
                    color: "#8B949E"
                    font.pixelSize: 14
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignLeft
                }
            }
            
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 70
                Layout.bottomMargin: 24
                color: "#0D1117"
                radius: 12
                border.color: removePinInput.activeFocus ? "#58A6FF" : "#30363D"
                
                TextField {
                    id: removePinInput
                    anchors.centerIn: parent
                    width: 180; height: 40
                    placeholderText: "0 0 0 0"
                    echoMode: TextInput.Password
                    horizontalAlignment: TextInput.AlignHCenter
                    verticalAlignment: TextInput.AlignVCenter
                    font.pixelSize: 24; font.letterSpacing: 8
                    color: "white"
                    maximumLength: 4
                    focus: true
                    validator: RegularExpressionValidator { regularExpression: /[0-9]{0,4}/ }
                    background: null
                }
            }
            
            RowLayout {
                Layout.fillWidth: true
                spacing: 16
                
                Button { 
                    id: cancelRemovePinBtn
                    text: "Cancel"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 42
                    onClicked: verifyPinToRemove.close()
                    background: Rectangle { color: cancelRemovePinBtn.hovered ? "#30363D" : "#21262D"; radius: 10 }
                    contentItem: Text { text: "Cancel"; color: "white"; font.family: "Segoe UI"; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                }
                
                Button { 
                    id: confirmRemovePinBtn; text: "Remove"
                    enabled: removePinInput.text.length === 4
                    Layout.fillWidth: true
                    Layout.preferredHeight: 42
                    onClicked: {
                        if (uiBridge.getSetting("pin_code") === removePinInput.text) {
                            uiBridge.removePin();
                            verifyPinToRemove.close();
                            removePinInput.clear();
                        }
                    }
                    background: Rectangle { color: confirmRemovePinBtn.enabled ? (confirmRemovePinBtn.hovered ? "#FF4444" : "#F85149") : "#2C1A1A"; radius: 10 }
                    contentItem: Text { text: "Remove"; color: "white"; font.family: "Segoe UI"; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                }
            }
        }
    }
}
