import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

ColumnLayout {
    id: root
    spacing: 0
    Layout.fillWidth: true
    
    property var folderData: null
    property int level: 0
    property bool isExpanded: false
    property bool isLastChild: false
    
    signal addSubFolderRequested(var folderData)
    
    // Container for folder item and tree lines
    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 36
        
        // Tree Branch Lines (Visible only for children)
        Item {
            anchors.fill: parent
            visible: root.level > 0
            
            // Vertical line segment from parent
            Rectangle {
                x: (root.level - 1) * 28 + 20
                y: 0
                width: 1
                height: root.isLastChild ? parent.height / 2 : parent.height
                color: "#30363D"
            }
            
            // Horizontal line segment to this icon
            Rectangle {
                x: (root.level - 1) * 28 + 20
                y: parent.height / 2
                width: 14
                height: 1
                color: "#30363D"
            }
        }

        SidebarItem {
            id: sidebarItem
            width: parent.width - (root.level * 28)
            height: parent.height
            x: root.level * 28 // Indentation
            
            text: folderData ? folderData.name : ""
            iconSource: Qt.resolvedUrl("../assets/folder.svg")
            isFolder: true
            folderColor: (folderData && folderData.color) ? folderData.color : "#4B5563"
            count: (uiBridge && uiBridge.counts && folderData) ? (uiBridge.counts[folderData.name] || 0) : 0
            isActive: (uiBridge && uiBridge.currentFilter && folderData) ? (uiBridge.currentFilter === folderData.name) : false
            
            hasChildren: folderData && folderData.children && folderData.children.length > 0
            isFolderExpanded: root.isExpanded
            showArrow: root.level === 0 // Show arrow only at top level
            isLastChild: root.isLastChild
            canAddSubfolder: root.level === 0 // Only root folders can have subfolders
            
            onArrowClicked: {
                root.isExpanded = !root.isExpanded
            }

            onClickedWithModifiers: (modifiers) => {
                if (modifiers & Qt.AltModifier) {
                    folderDetails.folder = folderData
                    folderDetails.open()
                } else {
                    if (uiBridge) uiBridge.setFilter(folderData.name)
                }
            }
            
            onMoreClicked: {
                sidebarRoot.moreFolderClicked(folderData)
            }
            
            onAddClicked: {
                root.addSubFolderRequested(folderData)
            }
        }
    }

    // Children Area
    ColumnLayout {
        id: childrenCol
        Layout.fillWidth: true
        visible: root.isExpanded && folderData && folderData.children && folderData.children.length > 0
        spacing: 0
        
        Repeater {
            model: (folderData && folderData.children) ? folderData.children : []
            delegate: Loader {
                Layout.fillWidth: true
                source: "FolderTreeItem.qml"
                onLoaded: {
                    item.folderData = modelData
                    item.level = root.level + 1
                    item.isLastChild = (index === (folderData.children.length - 1))
                    item.addSubFolderRequested.connect(root.addSubFolderRequested)
                }
            }
        }
    }
}
