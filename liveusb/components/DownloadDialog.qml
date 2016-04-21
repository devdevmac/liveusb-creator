import QtQuick 2.4
import QtQuick.Controls 1.2
import QtQuick.Dialogs 1.2
import QtQuick.Layouts 1.1
import QtQuick.Window 2.0

Dialog {
    id: root
    title: qsTranslate("", "Write %1").arg(liveUSBData.currentImage.name)

    height: layout.height + $(56)
    standardButtons: StandardButton.NoButton

    width: $(640)

    function reset() {
        writeArrow.color = "black"
        writeImmediately.checked = false
    }

    onVisibleChanged: reset()

    Connections {
        target: liveUSBData
        onCurrentImageChanged: {
            reset();
        }
    }

    Connections {
        id: downloadWait
        target: liveUSBData.currentImage
        onReadyToWriteChanged: {
            if (liveUSBData.currentImage.readyToWrite && writeImmediately.checked) {
                liveUSBData.currentImage.write()
            }
        }
    }

    Connections {
        target: liveUSBData.currentImage.writer
        onFinishedChanged: {
            writeImmediately.checked = false
        }
    }

    contentItem: Rectangle {
        id: contentWrapper
        anchors.fill: parent
        color: palette.window
        ScrollView {
            anchors.fill: parent
            horizontalScrollBarPolicy: Qt.ScrollBarAlwaysOff
            contentItem: Item {
                width: contentWrapper.width
                height: layout.height + $(32)
                Column {
                    id: layout
                    spacing: $(24)
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                        topMargin: $(32)
                        leftMargin: $(48)
                        rightMargin: anchors.leftMargin
                    }
                    Column {
                        id: infoColumn
                        spacing: $(4)
                        width: parent.width

                        Repeater {
                            model: liveUSBData.currentImage.error
                            RowLayout {
                                width: infoColumn.width
                                spacing: $(8)
                                Rectangle {
                                    Layout.fillWidth: false
                                    Layout.alignment: Qt.AlignVCenter
                                    width: $(16)
                                    height: $(16)
                                    radius: width / 2
                                    color: "#88ffffff"
                                    border {
                                        width: $(1)
                                        color: "#a1a1a1"
                                    }
                                    Item {
                                        anchors.fill: parent
                                        transformOrigin: Item.Center
                                        rotation: 45
                                        Rectangle {
                                            anchors.centerIn: parent
                                            width: parent.width * 0.6
                                            height: parent.width * 0.1
                                            color: "red"
                                        }
                                        Rectangle {
                                            anchors.centerIn: parent
                                            height: parent.width * 0.6
                                            width: parent.width * 0.1
                                            color: "red"
                                        }
                                    }
                                }
                                Text {
                                    Layout.fillHeight: true
                                    Layout.fillWidth: true
                                    verticalAlignment: Text.AlignVCenter
                                    wrapMode: Text.Wrap
                                    font.pixelSize: $(12)
                                    text: liveUSBData.currentImage.error[index]
                                }
                            }
                        }


                        Repeater {
                            model: (liveUSBData.currentImage.writer.finished || liveUSBData.currentImage.error.length > 0) ? null : liveUSBData.currentImage.warning
                            RowLayout {
                                width: infoColumn.width
                                spacing: $(8)
                                Text {
                                    Layout.fillHeight: true
                                    verticalAlignment: Text.AlignVCenter
                                    color: "red"
                                    text: "!"
                                    font.pixelSize: $(20)
                                }
                                Text {
                                    Layout.fillHeight: true
                                    Layout.fillWidth: true
                                    verticalAlignment: Text.AlignVCenter
                                    wrapMode: Text.Wrap
                                    font.pixelSize: $(12)
                                    text: liveUSBData.currentImage.warning[index]
                                }
                            }
                        }

                        Repeater {
                            model: liveUSBData.currentImage.error.length > 0 ? null : liveUSBData.currentImage.info
                            RowLayout {
                                width:  infoColumn.width
                                spacing: $(8)
                                // a rotated exclamation mark instead of an 'i' as for information - that's funny, right... right?!
                                Text {
                                    Layout.fillHeight: true
                                    verticalAlignment: Text.AlignVCenter
                                    color: "blue"
                                    text: "!"
                                    rotation: 180
                                    font.pixelSize: $(18)
                                }
                                Text {
                                    Layout.fillHeight: true
                                    Layout.fillWidth: true
                                    verticalAlignment: Text.AlignVCenter
                                    wrapMode: Text.Wrap
                                    text: liveUSBData.currentImage.info[index]
                                    font.pixelSize: $(12)
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        width: parent.width
                        spacing: $(5)

                        Behavior on y {
                            NumberAnimation {
                                duration: 1000
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            horizontalAlignment: Text.AlignHCenter
                            font.pixelSize: $(12)
                            property double leftSize: liveUSBData.currentImage.download.maxProgress - liveUSBData.currentImage.download.progress
                            property string leftStr: leftSize <= 0 ? "" :
                                                     (leftSize < 1024) ? (leftSize + " B") :
                                                     (leftSize < (1024 * 1024)) ? ((leftSize / 1024).toFixed(1) + " KB") :
                                                     (leftSize < (1024 * 1024 * 1024)) ? ((leftSize / 1024 / 1024).toFixed(1) + " MB") :
                                                     ((leftSize / 1024 / 1024 / 1024).toFixed(1) + " GB")
                            text: liveUSBData.currentImage.status + (liveUSBData.currentImage.download.maxProgress > 0 ? " (" + leftStr + " left)" : "")
                        }
                        Item {
                            Layout.fillWidth: true
                            height: childrenRect.height
                            AdwaitaProgressBar {
                                width: parent.width
                                value: liveUSBData.currentImage.download.running ? liveUSBData.currentImage.download.progress / liveUSBData.currentImage.download.maxProgress : 0
                                visible: !liveUSBData.currentImage.writer.running
                            }
                            AdwaitaProgressBar {
                                width: parent.width
                                value: liveUSBData.currentImage.writer.progress
                                visible: !liveUSBData.currentImage.download.running
                                progressColor: liveUSBData.currentImage.writer.checking ? Qt.lighter("green") : "red"
                            }
                        }
                        AdwaitaCheckBox {
                            id: writeImmediately
                            enabled: driveCombo.count && opacity > 0.0
                            opacity: !liveUSBData.currentImage.readyToWrite && liveUSBData.currentImage.download.running && liveUSBData.currentImage.download.progress / liveUSBData.currentImage.download.maxProgress < 0.95 ? 1.0 : 0.0
                            text: qsTranslate("", "Write the image immediately when the download is finished")
                        }
                    }

                    RowLayout {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: $(32)
                        Image {
                            source: liveUSBData.currentImage.logo
                            Layout.preferredWidth: $(64)
                            Layout.preferredHeight: $(64)
                            sourceSize.width: $(64)
                            sourceSize.height: $(64)
                            fillMode: Image.PreserveAspectFit
                        }
                        Arrow {
                            id: writeArrow
                            anchors.verticalCenter: parent.verticalCenter
                            scale: $(1.4)
                            SequentialAnimation {
                                running: liveUSBData.currentImage.writer.running
                                loops: -1
                                onStopped: {
                                    if (liveUSBData.currentImage.writer.finished)
                                        writeArrow.color = "#00dd00"
                                    else
                                        writeArrow.color = "black"
                                }
                                ColorAnimation {
                                    duration: 3500
                                    target: writeArrow
                                    property: "color"
                                    to: "red"
                                }
                                PauseAnimation {
                                    duration: 500
                                }
                                ColorAnimation {
                                    duration: 3500
                                    target: writeArrow
                                    property: "color"
                                    to: "black"
                                }
                                PauseAnimation {
                                    duration: 500
                                }
                            }
                        }
                        AdwaitaComboBox {
                            id: driveCombo
                            Layout.preferredWidth: implicitWidth * 2.5
                            model: liveUSBData.usbDriveNames
                            currentIndex: liveUSBData.currentDrive
                            onCurrentIndexChanged: {
                                liveUSBData.currentImage.writer.finished = false
                                liveUSBData.currentDrive = currentIndex
                            }
                            onModelChanged: {
                                if (liveUSBData.usbDriveNames.length <= 0)
                                    currentIndex = -1
                            }

                            enabled: !liveUSBData.currentImage.writer.running
                            Row {
                                spacing: $(8)
                                anchors.fill: parent
                                anchors.leftMargin: $(8)
                                visible: liveUSBData.usbDriveNames.length <= 0
                                BusyIndicator {
                                    anchors.verticalCenter: parent.verticalCenter
                                    height: parent.height * 0.6
                                    width: height
                                }
                                Text {
                                    height: parent.height
                                    verticalAlignment: Text.AlignVCenter
                                    text: qsTranslate("", "There are no portable drives connected")
                                    color: "gray"
                                    font.pixelSize: $(12)
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        width: parent.width
                        spacing: $(12)
                        RowLayout {
                            height: acceptButton.height
                            width: parent.width
                            spacing: $(10)

                            Item {
                                Layout.fillWidth: true
                                height: $(1)
                            }

                            AdwaitaButton {
                                id: cancelButton
                                anchors {
                                    right: acceptButton.left
                                    top: parent.top
                                    bottom: parent.bottom
                                    rightMargin: $(6)
                                }
                                text: qsTranslate("", "Cancel")
                                enabled: !liveUSBData.currentImage.writer.running && !liveUSBData.currentImage.writer.finished
                                onClicked: {
                                    liveUSBData.currentImage.download.cancel()
                                    liveUSBData.currentImage.writer.cancel()
                                    liveUSBData.currentImage.writer.finished = false
                                    writeImmediately.checked = false
                                    root.close()
                                }
                            }
                            AdwaitaButton {
                                id: acceptButton
                                anchors {
                                    right: parent.right
                                    top: parent.top
                                    bottom: parent.bottom
                                }
                                color: liveUSBData.currentImage.writer.finished ? "#628fcf" : "red"
                                textColor: enabled ? "white" : palette.text
                                transformOrigin: Item.Center
                                enabled: (liveUSBData.currentImage.readyToWrite && !liveUSBData.currentImage.writer.running && liveUSBData.usbDrives.length > 0)
                                text: liveUSBData.currentImage.writer.finished ? qsTranslate("", "Close") : qsTranslate("", "Write to disk")
                                onClicked: {
                                    if (liveUSBData.currentImage.writer.finished) {
                                        liveUSBData.currentImage.download.cancel()
                                        liveUSBData.currentImage.writer.cancel()
                                        liveUSBData.currentImage.writer.finished = false
                                        writeImmediately.checked = false
                                        root.close()
                                    }
                                    else {
                                        liveUSBData.currentImage.write()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
