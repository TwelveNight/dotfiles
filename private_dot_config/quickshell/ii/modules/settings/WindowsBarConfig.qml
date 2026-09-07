import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    forceWidth: true

    ContentSection {
        icon: "bottom_app_bar"
        title: Translation.tr("Windows Bar")

        ConfigSwitch {
            buttonIcon: "filter_list"
            text: Translation.tr("Show only current workspace windows")
            checked: Config.options.waffles.bar.currentWorkspaceOnly
            onCheckedChanged: {
                Config.options.waffles.bar.currentWorkspaceOnly = checked;
            }
            StyledToolTip {
                text: Translation.tr("Keep pinned apps visible, while hiding running windows from other workspaces")
            }
        }
    }
}
