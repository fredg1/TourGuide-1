RegisterResourceGenerationFunction("IOTMSpinMasterLatheResource");
void IOTMSpinMasterLatheResource(ChecklistEntry [int] resource_entries)
{
    if (!mafiaIsPastRevision(20279)) return;
    if (lookupItem("SpinMaster&trade; lathe").available_amount() == 0) return;


    boolean need_to_collect_daily_scrap = !get_property_boolean("_spinmasterLatheVisited");
    int scraps = need_to_collect_daily_scrap.to_int() + lookupItem("flimsy hardwood scraps").available_amount();

    record LatheRare {
        item wood;
        boolean [location] source;
        item equipment;
        string attributes;
    };
    LatheRare latheRareMake(string wood, boolean [location] source, string equipment, string attributes) {
        LatheRare result;
        result.wood = wood.lookupItem();
        result.source = source;
        result.equipment = equipment.lookupItem();
        result.attributes = attributes;
        return result;
    }

    LatheRare [int] latheRares = {
        latheRareMake("sweaty balsam", $locations[the smut orc logging camp], "balsam barrel", ""),
        latheRareMake("dripwood slab", $locations[the dripping trees], "drippy diadem", ""),
        latheRareMake("dreadsylvanian hemlock", $locations[dreadsylvanian woods], "hemlock helm", ""),
        latheRareMake("purpleheart logs", $locations[The Purple Light District], "purpleheart \"pants\"", ""),
        latheRareMake("ancient redwood", $locations[The Jungles of Ancient Loathing], "redwood rain stick", ""),
        latheRareMake("wormwood stick", $locations[The mouldering mansion,the rogue windmill,the stately pleasure dome], "wormwood wedding ring", "")
    }

    //if they have the equipment: skip
    //if they have the wood: tell to get the equipment

    foreach key, it in latheRares {
        if (it.equipment.available_amount() > 0)
            continue;

        if (it.wood.available_amount() > 0)
            xxxx.listAppend("Can make a " + it.equipment);
    }

    resource_entries.listAppend(ChecklistEntryMake("__item SpinMaster&trade; lathe", "shop.php?whichshop=lathe", ChecklistSubentryMake("Rentable floundry equipment", "", description), 8));
}