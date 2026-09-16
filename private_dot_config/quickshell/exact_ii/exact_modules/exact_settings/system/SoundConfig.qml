import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: root
    forceWidth: true

    function deviceName(node) {
        return Audio.friendlyDeviceName(node)
    }

    component DeviceRow: Rectangle {
        required property var node
        required property bool output
        signal selected()

        Layout.fillWidth: true
        implicitHeight: 54
        radius: Appearance.rounding.small
        color: selectedDevice ? Appearance.colors.colLayer2 : Appearance.colors.colLayer1

        property bool selectedDevice: (output ? Audio.sink : Audio.source) === node

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 12
            spacing: 10

            MaterialSymbol {
                text: output ? "speaker" : "mic"
                iconSize: 20
                color: Appearance.colors.colOnLayer1
            }
            StyledText {
                Layout.fillWidth: true
                text: root.deviceName(node)
                elide: Text.ElideRight
            }
            MaterialSymbol {
                visible: parent.parent.selectedDevice
                text: "check"
                iconSize: 20
                color: Appearance.colors.colPrimary
            }
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: output ? Audio.setDefaultSink(node) : Audio.setDefaultSource(node)
        }
    }

    component AudioLevel: ColumnLayout {
        required property var node
        required property bool output

        Layout.fillWidth: true
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            MaterialSymbol {
                text: node?.audio?.muted ? (output ? "volume_off" : "mic_off") : (output ? "volume_up" : "mic")
                iconSize: 21
                color: Appearance.colors.colOnLayer1
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: node.audio.muted = !node.audio.muted
                }
            }
            StyledText { text: output ? Translation.tr("Output volume") : Translation.tr("Input volume") }
            Item { Layout.fillWidth: true }
            StyledText {
                text: `${Math.round((node?.audio?.volume ?? 0) * 100)}%`
                color: Appearance.colors.colSubtext
            }
        }
        StyledSlider {
            Layout.fillWidth: true
            enabled: node?.audio !== null && node?.audio !== undefined
            value: node?.audio?.volume ?? 0
            onMoved: node.audio.volume = value
            configuration: StyledSlider.Configuration.M
        }
    }

    ContentSection {
        icon: "speaker"
        title: Translation.tr("Output")

        StyledText {
            Layout.fillWidth: true
            text: Translation.tr("Output device")
            color: Appearance.colors.colSubtext
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            Repeater {
                model: ScriptModel { values: Audio.outputDevices }
                delegate: DeviceRow { required property var modelData; node: modelData; output: true }
            }
        }
        AudioLevel { node: Audio.sink; output: true }
    }

    ContentSection {
        icon: "mic"
        title: Translation.tr("Input")

        StyledText {
            Layout.fillWidth: true
            text: Translation.tr("Input device")
            color: Appearance.colors.colSubtext
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            Repeater {
                model: ScriptModel { values: Audio.inputDevices }
                delegate: DeviceRow { required property var modelData; node: modelData; output: false }
            }
        }
        AudioLevel { node: Audio.source; output: false }
    }

    ContentSection {
        icon: "tune"
        title: Translation.tr("Sounds")

        RippleButton {
            Layout.fillWidth: true
            implicitHeight: 48
            buttonText: Translation.tr("Volume mixer")
            onClicked: Quickshell.execDetached(["bash", "-c", Config.options.apps.volumeMixer])
        }
        RippleButton {
            Layout.fillWidth: true
            implicitHeight: 48
            visible: EasyEffects.available
            buttonText: Translation.tr("EasyEffects")
            onClicked: EasyEffects.active ? EasyEffects.disable() : EasyEffects.enable()
        }
    }
}
