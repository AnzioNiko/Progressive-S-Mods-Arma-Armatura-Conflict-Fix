package progsmod.data.campaign.rulecmd.ui.plugins;

import com.fs.starfarer.api.Global;
import com.fs.starfarer.api.campaign.InteractionDialogAPI;
import com.fs.starfarer.api.fleet.FleetMemberAPI;
import com.fs.starfarer.api.ui.ScrollPanelAPI;
import progsmod.data.campaign.rulecmd.PSM_BuildInHullMod;
import progsmod.data.campaign.rulecmd.delegates.SelectShip;
import progsmod.data.campaign.rulecmd.ui.PanelCreator.PanelCreatorData;
import progsmod.data.campaign.rulecmd.ui.ShipButton;

import java.util.List;

public class ShipSelector extends Selector<ShipButton> {
    private InteractionDialogAPI dialog;
    private ScrollPanelAPI scrollPanelAPI;
    private SelectShip selectShip;

    public ShipSelector(SelectShip selectShip) {
        this.selectShip = selectShip;
    }

    public void init(
            PanelCreatorData<List<ShipButton>> data,
            InteractionDialogAPI dialog,
            ScrollPanelAPI scrollPanelAPI
    ) {
        super.init(data.created);
        this.dialog = dialog;
        this.scrollPanelAPI = scrollPanelAPI;
    }

    @Override
    protected void onSelected(int index) {
        float scrollPanelY = scrollPanelAPI.getYOffset();
        selectShip.callback.dismissCustomDialog(1);
        FleetMemberAPI fleetMember = items.get(index).data.fleetMember;
        // 不持久化完整 FleetMember；该引用会导致部分组合舰存档在读取时提前访问玩家舰队。
        PSM_BuildInHullMod.fromLunaButton = false;
        PSM_BuildInHullMod.createPanel(fleetMember, fleetMember.getVariant(), dialog, scrollPanelY, selectShip.callback, null);
    }

    @Override
    protected void onDeselected(int index) {
    }
}
