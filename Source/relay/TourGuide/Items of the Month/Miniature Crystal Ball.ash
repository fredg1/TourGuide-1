RegisterTaskGenerationFunction("IOTMCrystalBallGenerateTasks");
void IOTMCrystalBallGenerateTasks(ChecklistEntry [int] task_entries, ChecklistEntry [int] optional_task_entries, ChecklistEntry [int] future_task_entries)
{
    string [int] predictions = get_property("crystalBallPredictions").split_string("|");

    if (predictions.count() < 2)
        return;

    monster [int] predicted_monsters;
    location [int] respective_locations;

    for i from 1 to predictions.count() by 2 {
        predicted_monsters.listAppend(predictions[i-1].to_monster());
        respective_locations.listAppend(predictions[i].to_location());
    }


    boolean crystal_equipped = lookupItem("miniature crystal ball").equipped();

    string subtitle = crystal_equipped ? "" : "Equip the crystal ball to encounter them";
    string [int] description;

    description.listAppend("Spend a turn elsewhere to reset");

    foreach key in predicted_monsters {
        description.listAppend(respective_locations.to_string() + " : " + predicted_monsters.to_string().HTMLGenerateSpanFont("blue"));
    }

    task_entries.listAppend(ChecklistEntryMake("__item miniature crystal ball", "", ChecklistSubentryMake("Current predictions", subtitle, description), crystal_equipped ? -11 : -1).ChecklistEntrySetIDTag("Crystal ball prediction"));
}