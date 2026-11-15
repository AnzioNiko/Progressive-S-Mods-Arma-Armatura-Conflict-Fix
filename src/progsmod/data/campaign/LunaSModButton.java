package progsmod.data.campaign;

import com.fs.starfarer.api.Global;
import com.fs.starfarer.api.campaign.InteractionDialogAPI;
import com.fs.starfarer.api.campaign.econ.MarketAPI;
import com.fs.starfarer.api.combat.ShipVariantAPI;
import com.fs.starfarer.api.fleet.FleetMemberAPI;
import com.fs.starfarer.api.input.InputEventAPI;
import com.fs.starfarer.api.ui.TooltipMakerAPI;
import com.fs.starfarer.api.util.Misc;
import lunalib.lunaRefit.BaseRefitButton;
import lunalib.lunaRefit.LunaRefitManager;
import progsmod.data.campaign.rulecmd.PSM_BuildInHullMod;
import progsmod.util.Action;
import progsmod.util.SModUtils;

public class LunaSModButton extends BaseRefitButton {

    public static void addButton() {
        LunaRefitManager.addRefitButton(new LunaSModButton());
    }

    @Override
    public boolean hasPanel(FleetMemberAPI member, ShipVariantAPI variant, MarketAPI market) {
        return false;
    }

    @Override
    public String getButtonName(FleetMemberAPI member, ShipVariantAPI variant) {
        return "管理 S-插件";
    }

    @Override
    public String getIconName(FleetMemberAPI member, ShipVariantAPI variant) {
        return "graphics/hullmods/progsmod_xp_tracker.png";
    }

    @Override
    public boolean isClickable(FleetMemberAPI member, ShipVariantAPI variant, MarketAPI market) {
        InteractionDialogAPI dialog = Global.getSector().getCampaignUI().getCurrentInteractionDialog();
        return dialog != null;
    }

    @Override
    public boolean hasTooltip(FleetMemberAPI member, ShipVariantAPI variant, MarketAPI market) {
        return !isClickable(member, variant, market);
    }

    @Override
    public void addTooltip(TooltipMakerAPI tooltip, FleetMemberAPI member, ShipVariantAPI variant, MarketAPI market) {
        tooltip.addPara("必须停靠在一处殖民地。", Misc.getNegativeHighlightColor(), 0f);
    }

    @Override
    public void onClick(FleetMemberAPI member, ShipVariantAPI variant, InputEventAPI event, MarketAPI market) {
        InteractionDialogAPI dialog = Global.getSector().getCampaignUI().getCurrentInteractionDialog();
        if (dialog == null) return;

        boolean found = false;
        for (FleetMemberAPI fm : Global.getSector().getPlayerFleet().getFleetData().getMembersListCopy()) {
            if (fm == member) {
                found = true;
                break;
            }
            for (ShipVariantAPI moduleVariant : SModUtils.getModuleVariantsWithOP(fm.getVariant())) {
                if (member.getVariant() == moduleVariant) {
                    member = fm;
                    found = true;
                    break;
                }
            }
        }

        if (!found) return;

        PSM_BuildInHullMod.fromLunaButton = true;
        PSM_BuildInHullMod.createPanel(member, variant, dialog, 0f, null, new Action() {
            @Override
            public void perform() {
                refreshVariant();
            }
        });
    }
}
