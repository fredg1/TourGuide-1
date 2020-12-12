RegisterResourceGenerationFunction("IOTMPizzaCube");
void IOTMPizzaCube(ChecklistEntry [int] resource_entries)
{
    if (!__iotms_usable[lookupItem("diabolic pizza cube")] || (fullness_limit() - my_fullness() < 3)) return;

    ChecklistSubentry getQuestItems() {
        // Title
        string main_title = "Make pizza";

        // Subtitle
        string subtitle = "Some ingredients give useful items";

        // Entries
        string [int] description;
        
        boolean need_cheese = !__quest_state["Trapper"].state_boolean["Past mine"] && $item[goat cheese].available_amount() < 3;

        if (need_cheese) {
            description.listAppend(HTMLGenerateSpanOfClass("\"cheese\"/\"milk\":", "r_bold") + " 3 goat cheese");
        }
        description.listAppend(HTMLGenerateSpanOfClass("\"luck\"/\"green\":", "r_bold") + " clover");
        description.listAppend(HTMLGenerateSpanOfClass("familiar equipment/hatchling:", "r_bold") + " equipment + xp for your familiar");
        description.listAppend(HTMLGenerateSpanOfClass("\"cloak\":", "r_bold") + " dead mimic");
        description.listAppend(HTMLGenerateSpanOfClass("combat item:", "r_bold") + " 3 of sonar-in-a-biscuit, Duskwalker syringe, cocktail napkin, unnamed cocktail, cigarette lighter, glark cable, short writ of habeas corpus");

        return ChecklistSubentryMake(main_title, subtitle, description);
    }

    ChecklistSubentry getBuffs() {
        // Title
        string main_title = "Buffs";

        // Subtitle
        string subtitle = "";

        // Entries
        string [int] description;

        description.listAppend("Get any wishable buff");

        return ChecklistSubentryMake(main_title, subtitle, description);
    }

    ChecklistEntry entry;
    entry.image_lookup_name = "__item diabolic pizza";
    entry.url = "campground.php?action=workshed";
    entry.tags.id = "Diabolic pizza cube resource";

    ChecklistSubentry questItems = getQuestItems();
    if (questItems.entries.count() > 0) {
        entry.subentries.listAppend(questItems);
    }

    ChecklistSubentry buffs = getBuffs();
    if (buffs.entries.count() > 0) {
        entry.subentries.listAppend(buffs);
    }
    
    if (entry.subentries.count() > 0) {
        resource_entries.listAppend(entry);
    }
}
