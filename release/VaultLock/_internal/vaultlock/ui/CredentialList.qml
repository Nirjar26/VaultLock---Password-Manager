import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: listPanel
    color: "#0D1117" // Middle Panel Background
    
    property var model: (uiBridge) ? uiBridge.filteredCredentials : []
    
    // Middle Container Layout
    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: {
            listPanel.forceActiveFocus()
            if (uiBridge) uiBridge.selectedId = ""
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        
        // --- HEADER SECTION ---
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: headerLayout.implicitHeight // Auto-expand to fit content
            color: "#0D1117" // Opaque background to prevent transparent bleed-through
            z: 10
            
            ColumnLayout {
                id: headerLayout
                anchors.fill: parent
                // anchors.margins: 20 -> Removed to allow full-width separator
                anchors.topMargin: 16
                anchors.bottomMargin: 0 // Flush bottom
                spacing: 12
                
                // Title (#MiddlePanelTitle)
                Label {
                    text: "Credentials"
                    color: "#FFFFFF"
                    font.family: "Segoe UI"
                    font.pixelSize: 24
                    font.weight: Font.Bold
                    Layout.leftMargin: 20
                    Layout.rightMargin: 20
                }
                
                // Search Bar (#SearchInput)
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 44
                    Layout.leftMargin: 20
                    Layout.rightMargin: 20
                    color: "#1A1E26"
                    radius: 8
                    border.color: "#0DFFFFFF" // ~5% White
                    border.width: 1
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 8
                        
                        SharpIcon {
                            source: Qt.resolvedUrl("../assets/search.svg")
                            color: "#9CA3AF"
                            iconSize: 14
                        }
                        
                        TextInput {
                            id: searchInput
                            Layout.fillWidth: true
                            focus: true
                            text: (uiBridge) ? uiBridge.searchQuery : ""
                            color: "#E6EDF3"
                            font.pixelSize: 14
                            font.family: "Segoe UI"
                            verticalAlignment: Text.AlignVCenter
                            property string placeholder: "Search vault..."
                            
                            Text {
                                text: parent.placeholder
                                color: "#9CA3AF" // Placeholder Text Color
                                visible: !parent.text
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            onTextChanged: uiBridge.searchQuery = text
                        }
                    }
                }
                
                // Action Row
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    Layout.leftMargin: 20
                    Layout.rightMargin: 20
                    spacing: 8
                    
                    // Count Label (#PasswordCountLabel)
                    Label {
                        text: (listPanel.model ? listPanel.model.length : 0) + " Passwords"
                        color: "#E6EDF3"
                        font.pixelSize: 15
                        font.weight: Font.Normal // Normal weight
                        Layout.fillWidth: true
                    }
                    
                    // Add Button
                    Button {
                        Layout.preferredWidth: 38
                        Layout.preferredHeight: 38
                        flat: true
                        background: Rectangle {
                            color: parent.hovered ? "#14FFFFFF" : "transparent"
                            radius: 6
                        }
                        contentItem: Text {
                            text: "+"
                            color: "#E6EDF3"
                            font.pixelSize: 22
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        onClicked: {
                            if (uiBridge) {
                                uiBridge.isEditing = false
                                uiBridge.isAddingCredential = true
                            }
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.NoButton
                        }
                    }
                    // Sort ComboBox
                    ComboBox {
                        id: sortCombo
                        Layout.preferredWidth: 150
                        Layout.preferredHeight: 38
                        
                        model: [
                            { text: "Name A-Z", value: "name_asc" },
                            { text: "Name Z-A", value: "name_desc" },
                            { text: "Last created", value: "newest" },
                            { text: "First created", value: "oldest" }
                        ]
                        
                        textRole: "text"
                        currentIndex: {
                            if (!uiBridge) return 0;
                            var criteria = uiBridge.sortCriteria;
                            for (var i = 0; i < model.length; i++) {
                                if (model[i].value === criteria) return i;
                            }
                            return 0;
                        }

                        onActivated: (index) => {
                            if (uiBridge) {
                                uiBridge.sortCriteria = model[index].value;
                            }
                        }

                        // Use custom indicator to avoid overlapping
                        indicator: Item {}

                        // Theme-integrated styling
                        delegate: ItemDelegate {
                            width: sortCombo.width
                            height: 36
                            padding: 10
                            contentItem: RowLayout {
                                spacing: 8
                                Text {
                                    text: modelData.text
                                    color: highlighted ? "#FFFFFF" : "#E6EDF3"
                                    font.family: "Segoe UI"
                                    font.pixelSize: 13
                                    verticalAlignment: Text.AlignVCenter
                                    Layout.fillWidth: true
                                }
                                
                                SharpIcon {
                                    source: Qt.resolvedUrl("../assets/check.svg")
                                    color: "#58A6FF"
                                    iconSize: 12
                                    visible: uiBridge && uiBridge.sortCriteria === modelData.value
                                    Layout.alignment: Qt.AlignVCenter
                                }
                            }
                            background: Rectangle {
                                color: highlighted ? "#21262D" : "transparent"
                                radius: 4
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                acceptedButtons: Qt.NoButton
                            }
                        }

                        background: Rectangle {
                            // Transparent by default, show color on hover/focus/pressed
                            color: (sortCombo.hovered || sortCombo.visualFocus || sortCombo.pressed) ? "#1A1E26" : "transparent"
                            radius: 8
                            border.color: sortCombo.activeFocus ? "#58A6FF" : "transparent"
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 150 } }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                acceptedButtons: Qt.NoButton
                            }
                            
                            // Chevron/Indicator
                            SharpIcon {
                                anchors.right: parent.right
                                anchors.rightMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                source: Qt.resolvedUrl("../assets/chevron-up-chevron-down-svgrepo-com.svg")
                                color: "#9CA3AF"
                                iconSize: 14
                            }
                        }

                        contentItem: Text {
                            leftPadding: 16
                            rightPadding: 32
                            text: sortCombo.displayText
                            font.family: "Segoe UI"
                            font.pixelSize: 13
                            color: "#E6EDF3"
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }

                        popup: Popup {
                            y: sortCombo.height + 4
                            width: sortCombo.width
                            implicitHeight: contentItem.implicitHeight + 12
                            padding: 6

                            contentItem: ListView {
                                clip: true
                                implicitHeight: contentHeight
                                model: sortCombo.popup.visible ? sortCombo.delegateModel : null
                                currentIndex: sortCombo.highlightedIndex
                                ScrollBar.vertical: ScrollBar { }
                            }

                            background: Rectangle {
                                color: "#161B22"
                                radius: 8
                                border.color: "#30363D"
                                border.width: 1
                                
                                // Shadow simulation
                                layer.enabled: true
                            }
                        }
                    }
                }
                
                // Separator Line
                Rectangle {
                    Layout.fillWidth: true
                    Layout.topMargin: 1
                    Layout.bottomMargin: 30
                    Layout.leftMargin: 20
                    Layout.rightMargin: 20
                    height: 1 
                    color: "#0FFFFFFF" // rgba(255, 255, 255, 0.06)
                }
            }
        }
        
        // --- LIST SCROLL AREA (#ItemScrollArea) ---
        // Wrapper to clip the elastic stretch effect
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            
            // Empty State
            ColumnLayout {
                anchors.centerIn: parent
                visible: listPanel.model.length === 0
                spacing: 12
                width: parent.width * 0.8
                
                Text {
                    text: "No Items Found"
                    color: "#FFFFFF"
                    font.family: "Segoe UI"
                    font.pixelSize: 18
                    font.weight: Font.DemiBold
                    Layout.alignment: Qt.AlignHCenter
                    opacity: 0.7
                }
                
                Text {
                    text: (uiBridge && uiBridge.searchQuery.length > 0) 
                          ? 'No results for "' + uiBridge.searchQuery + '"'
                          : (uiBridge && uiBridge.currentFilter === "Favourites")
                            ? "Mark items as favourites to see them here."
                            : (uiBridge && uiBridge.currentFilter === "Deleted")
                              ? "Your trash is empty."
                              : "Get started by adding your first credential."
                    color: "#8B949E"
                    font.family: "Segoe UI"
                    font.pixelSize: 13
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    opacity: 0.8
                }
            }
            ListView {
                id: listView
                anchors.fill: parent
                // Layout properties moved to wrapper
                
                model: listPanel.model
                spacing: 0
                
                // Enable Overshoot tracking
                boundsBehavior: Flickable.DragOverBounds
                
                // --- CUSTOM PHYSICS & ANIMATION STATE ---
                // --- CUSTOM PHYSICS & ANIMATION STATE (Apple-Style Heavy) ---
                // --- CUSTOM PHYSICS & ANIMATION STATE (Apple-Style Heavy) ---
                // Declarative Binding - Always Track Native Overshoot
                property real smoothOvershoot: listView.verticalOvershoot

                // 3. The "Slow & Heavy" Spring Animation
                Behavior on smoothOvershoot {
                    // Always enabled to add "weight" to every interaction (Drag or Wheel)
                    SpringAnimation {
                        spring: 60       // Balance: Responsive enough to track, slow enough to return heavy
                        damping: 40      
                        mass: 2.0        
                        epsilon: 0.1     
                    }
                }
                
                // --- HEAVY APPLE RUBBER FORMULA ---
                // dimension = 1100 (Wider range = Heavier resistance)
                readonly property real dimension: 1100
                readonly property real absOvershoot: Math.abs(smoothOvershoot)
                
                // Physics: (dim * over) / (dim + over) -> Asymptotic limit
                property real rubberOffset: (dimension * absOvershoot) / (dimension + absOvershoot)

                // Render Layer Optimization
                layer.enabled: true
                layer.smooth: true
                
                // --- TRANSFORM MAPPING ---
                transform: [
                    Scale {
                        // Origin: Dynamic Top/Bottom based on pull direction
                        origin.x: listView.width / 2
                        origin.y: listView.smoothOvershoot < 0 ? 0 : listView.height
                        
                        yScale: {
                            if (listView.smoothOvershoot < 0) {
                                // Top: Very subtle stretch (1.0 + rubber / 2400)
                                return 1.0 + (listView.rubberOffset / 2400)
                            } else {
                                // Bottom: Even subtler (1.0 + rubber / 2600)
                                return 1.0 + (listView.rubberOffset / 2600)
                            }
                        }
                    },
                    Translate {
                        y: {
                            if (listView.smoothOvershoot < 0) {
                                // Top: Pull Down (rubber * 0.20)
                                return listView.rubberOffset * 0.20
                            } else {
                                // Bottom: Pull Up negative (-rubber * 0.18)
                                return -listView.rubberOffset * 0.18
                            }
                        }
                    }
                ]
                
                // Fix Ghosting: Transparent/0-width Scrollbar
                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    active: false
                    width: 0
                    background: null 
                    contentItem: null 
                }
                
                // --- Credential Card Component (#ListItem) ---
                delegate: Rectangle {
                    id: itemCard
                    width: listView.width
                    height: 72
                    color: "transparent"
                    radius: 12
                    
                    // Margins/Padding simulation via Item wrapper or anchors
                    property bool hovered: hoverHandler.hovered
                    property bool active: (uiBridge && uiBridge.selectedId) ? (modelData.id === uiBridge.selectedId) : false
                    
                    // Resolved Logo Path (via Python Backend)
                    property string resolvedLogoPath: (uiBridge && uiBridge.resolveLogo) ? uiBridge.resolveLogo(modelData.service_name, modelData.website || "") : ""
    
                    Connections {
                        target: uiBridge
                        function onLogoUpdated(name, path) {
                            if (name === modelData.service_name) {
                                resolvedLogoPath = "file:///" + path.replace(/\\/g, "/")
                            }
                        }
                        ignoreUnknownSignals: true // Protection against missing backend
                    }
                    
                    // Visual Background (Inset)
                    Rectangle {
                        anchors.fill: parent
                        anchors.topMargin: 2
                        anchors.bottomMargin: 2
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        radius: 12
                        
                        color: itemCard.active ? "#1E60D2" : (itemCard.hovered ? "#0AFFFFFF" : "transparent")
                        // Behavior on color removed to prevent flickers/delays
                        
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (uiBridge) uiBridge.selectedId = modelData.id
                            }
                            hoverEnabled: true
                        }
                        
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 20
                            anchors.rightMargin: 16
                            anchors.topMargin: 10
                            anchors.bottomMargin: 10
                            spacing: 16
                            
                            // Icon Component
                            CredentialIcon {
                                logoSource: resolvedLogoPath
                                name: modelData.service_name
                                folderColor: (uiBridge && uiBridge.getFolderColor) ? uiBridge.getFolderColor(modelData.folder) : "transparent"
                                parentBackgroundColor: itemCard.active ? "#1E60D2" : (itemCard.hovered ? "#161B22" : "#0D1117") // Approx matching
                            }
                            
                            // Text Container
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                Layout.alignment: Qt.AlignVCenter
                                
                                Label {
                                    text: modelData.service_name
                                    color: "#FFFFFF"
                                    font.family: "Segoe UI"
                                    font.bold: true
                                    font.weight: Font.Bold
                                    font.pixelSize: 14
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                                
                                Label {
                                    text: modelData.username
                                    color: itemCard.active ? "#E6EDF3" : "#64748B" // Adjust text color on blue active bg
                                    font.family: "Segoe UI"
                                    font.pixelSize: 13
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }

                            // Deleted / Restore Icon
                            SharpIcon {
                                visible: modelData.is_deleted
                                source: Qt.resolvedUrl("../assets/trash-arrow-up.svg")
                                color: "#8B949E"
                                iconSize: 14
                                rotation: 180
                                Layout.alignment: Qt.AlignVCenter
                            }

                            // Round filled small circle
                            Rectangle {
                                width: 8
                                height: 8
                                radius: 4
                                color: (uiBridge && uiBridge.getFolderColor) ? uiBridge.getFolderColor(modelData.folder) : "transparent"
                                visible: !modelData.is_deleted && modelData.folder && modelData.folder !== "No Folder"
                                Layout.alignment: Qt.AlignVCenter
                            }

                            // Favourites Star on the very right
                            SharpIcon {
                                source: Qt.resolvedUrl("../assets/star (1).svg")
                                color: "#EAB308" // Gold/Yellow
                                iconSize: 14
                                visible: modelData.favourite
                                Layout.alignment: Qt.AlignVCenter
                            }
                        }
                    }
                    
                    HoverHandler { id: hoverHandler }
                }
            }
        }
        
         // --- FADE OVERLAY ---
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#21262D" // Bottom separator of list area
        }
    }
    
    // Fade Overlay (Absolute Positioned at bottom)
    Rectangle {
        width: parent.width
        height: 80
        anchors.bottom: parent.bottom
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 1.0; color: "#0D1117" }
        }
        z: 20
        enabled: false // Click-through
    }
}
