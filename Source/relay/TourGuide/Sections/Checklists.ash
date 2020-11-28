import "relay/TourGuide/Sections/Tests.ash"
import "relay/TourGuide/Limit Mode/Batfellow.ash";

void generateMisc(Checklist [int] checklists)
{
	if (__quest_state["Level 13"].state_boolean["king waiting to be freed"])
	{
		ChecklistEntry [int] unimportant_task_entries;
		string [int] king_messages;
		king_messages.listAppend("You know, whenever.");
		king_messages.listAppend("Or become the new naughty sorceress?");
		unimportant_task_entries.listAppend(ChecklistEntryMake("king imprismed", "place.php?whichplace=nstower", ChecklistSubentryMake("Free the King", "", king_messages)).ChecklistEntrySetIDTag("He's still trapped, just saying"));
		
		checklists.listAppend(ChecklistMake("Unimportant Tasks", unimportant_task_entries));
	}
	
	if (availableDrunkenness() < 0 && ($item[drunkula\'s wineglass].equipped_amount() == 0 || my_adventures() == 0))
	{
        //They are drunk, so tasks are not as relevant. Re-arrange everything:
        string url;
        
        //Give them something to mindlessly click on:
        //url = "bet.php";
        if ($coinmaster[Game Shoppe].is_accessible())
            url = "aagame.php";
        
        
		Checklist task_entries = lookupChecklist(checklists, "Tasks");
		
		lookupChecklist(checklists, "Future Tasks").entries.listAppendList(lookupChecklist(checklists, "Tasks").entries);
		lookupChecklist(checklists, "Future Tasks").entries.listAppendList(lookupChecklist(checklists, "Optional Tasks").entries);
		lookupChecklist(checklists, "Future Unimportant Tasks").entries.listAppendList(lookupChecklist(checklists, "Unimportant Tasks").entries);
		
		lookupChecklist(checklists, "Tasks").entries.listClear();
		lookupChecklist(checklists, "Optional Tasks").entries.listClear();
		lookupChecklist(checklists, "Unimportant Tasks").entries.listClear();
        
        //Remove extra-important popups, because they will not work anymore:
        Checklist future_checklist = lookupChecklist(checklists, "Future Tasks");
        foreach key, c in future_checklist.entries
        {
            if (c.only_show_as_extra_important_pop_up)
                remove future_checklist.entries[key];
        }
		
        string [int] description;
        string line = "You're drunk.";
        if (__last_adventure_location == $location[Drunken Stupor])
            url = "campground.php";
        
        if (hippy_stone_broken() && pvp_attacks_left() > 0)
            url = "peevpee.php";
            
        description.listAppend(line);
        if ($item[drunkula\'s wineglass].available_amount() > 0 && $item[drunkula\'s wineglass].can_equip() && my_adventures() > 0)
        {
            description.listAppend("Or equip your wineglass.");
        }
        
        int pvp_fights_gained = numeric_modifier("pvp fights").to_int() + 10;
        int pvp_fights_after_rollover_before_caps = pvp_attacks_left() + pvp_fights_gained;
        int pvp_fights_after_rollover = MIN(pvp_fights_after_rollover_before_caps, 100);
        if (today_is_pvp_season_end())
            pvp_fights_after_rollover = 0;
        
        int adventures_after_rollover = __misc_state_int["adventures after rollover"];
        
        string [int] all_tomorrows_parties;
        all_tomorrows_parties.listAppend(pluralise(adventures_after_rollover, "adventure", "adventures")); //it should be impossible to have under twenty adventures after rollover, but why should that stop us from checking the singular case?
        if (hippy_stone_broken() && pvp_fights_after_rollover > 0)
            all_tomorrows_parties.listAppend(pluralise(pvp_fights_after_rollover, "fight", "fights"));
        
        description.listAppend("Will start with " + all_tomorrows_parties.listJoinComponents(", ", "and") + " tomorrow.");
        
        int rollover_adventures_from_equipment = 0;
        foreach s in $slots[hat,weapon,off-hand,back,shirt,pants,acc1,acc2,acc3,familiar]
            rollover_adventures_from_equipment += s.equipped_item().numeric_modifier("adventures").to_int_silent();
        
        //detect if they're going to lose some turns, be nice:
        int adventures_lost = __misc_state_int["adventures lost to rollover"];
        if (rollover_adventures_from_equipment == 0.0 && adventures_lost == 0 && my_path_id() != PATH_SLOW_AND_STEADY)
        {
            description.listAppend("Possibly wear +adventures gear.");
        }
        if (adventures_lost > 0)
        {
            string [int] leisure_activities;
            leisure_activities.listAppend("work out in the gym");
            leisure_activities.listAppend("craft");
            if ($item[game grid ticket].is_unrestricted())
                leisure_activities.listAppend("play arcade games");
            description.listAppend("You'll miss out on " + pluraliseWordy(adventures_lost, "adventure", "adventures") + ". Alas.|Could " + leisure_activities.listJoinComponents(", ", "or") + ".");
        }
        
        if (hippy_stone_broken())
        {
            int pvp_fights_lost = pvp_fights_after_rollover_before_caps - pvp_fights_after_rollover;//MAX(0, pvp_fights_after_rollover_before_caps - 100);
            if (pvp_fights_lost > 0 && pvp_attacks_left() > 0)
            {
                description.listAppend("Fight " + pluralise(MIN(pvp_attacks_left(), pvp_fights_lost), "time", "times") + " to avoid losing fights to rollover.");
            }
        }
        
        //this could be better (i.e. checking against current shirt and looking in inventory, etc.)
        if (my_path_id() != PATH_SLOW_AND_STEADY)
        {
            if ($item[Sneaky Pete's leather jacket (collar popped)].equipped_amount() > 0 && adventures_lost <= 0)
                description.listAppend("Could unpop your collar. (+4 adventures)");
            if ($item[Sneaky Pete's leather jacket].equipped_amount() > 0 && hippy_stone_broken())
                description.listAppend("Could pop your collar. (+4 fights)");
            if (in_ronin() && $item[resolution: be more adventurous].available_amount() > 0 && get_property_int("_resolutionAdv") < 5)
            {
                description.listAppend("Use resolution: be more adventurous.");
            }
        }
        if (in_ronin() && pulls_remaining() > 0)
        {
            description.listAppend("Don't forget your " + pluraliseWordy(pulls_remaining(), "pull", "pulls") + ".");
        }
        //FIXME resolution be more adventurous goes here
        
		task_entries.entries.listAppend(ChecklistEntryMake("__item counterclockwise watch", url, ChecklistSubentryMake("Wait for rollover", "", description), -11).ChecklistEntrySetIDTag("Game unplayable"));
        if (stills_available() > 0 && __misc_state["in run"])
        {
            string url = "shop.php?whichshop=still";
            if ($item[soda water].available_amount() == 0)
                url = "shop.php?whichshop=generalstore";
            task_entries.entries.listAppend(ChecklistEntryMake("__item tonic water", url, ChecklistSubentryMake("Make " + pluralise(stills_available(), $item[tonic water]), "", listMake("Tonic water is a ~40MP restore, improved from soda water.", "Or improve drinks.")), -11).ChecklistEntrySetIDTag("End of day nash crosby still"));
        }
	}
}


void generateChecklists(Checklist [int] ordered_output_checklists)
{
	setUpState();
	setUpQuestState();
	
	if (__misc_state["Example mode"])
		setUpExampleState();
	
	finaliseSetUpState();
	
	Checklist [int] checklists;
    
    ChecklistCollection checklist_collection;
    
    if (limit_mode() == "spelunky")
    {
        LimitModeSpelunkingGenerateChecklists(checklists);
    }
    else if (limit_mode() == "batman")
    {
        LimitModeBatfellowGenerateChecklists(checklists);
    }
    else if (!playerIsLoggedIn() && !__misc_state["Example mode"])
    {
		Checklist task_entries = lookupChecklist(checklists, "Tasks");
        
        string image_name;
        image_name = "disco bandit";
		task_entries.entries.listAppend(ChecklistEntryMake(image_name, "", ChecklistSubentryMake("Log in", "+internet", "An Adventurer is You!"), -11).ChecklistEntrySetIDTag("Not logged in"));
    }
    else if (__misc_state["In valhalla"] && !__misc_state["Example mode"])
    {
        //Valhalla:
		Checklist task_entries = lookupChecklist(checklists, "Tasks");
        task_entries.entries.listAppend(ChecklistEntryMake("astral spirit", "", ChecklistSubentryMake("Start a new life", "", listMake("Perm skills.", "Buy consumables.", "Bring along a pet."))).ChecklistEntrySetIDTag("Astral spirit"));
    }
    else
    {
        generateDailyResources(checklists);
        
        generateTasks(checklists);
        if (__misc_state["Example mode"] || !__misc_state["in aftercore"])
        {
            generateMissingItems(checklists);
            generatePullList(checklists);
        }
        if (__setting_debug_show_all_internal_states && __setting_debug_mode)
        {
            generateAllTests(checklists);
        }
        generateFloristFriar(checklists);
        
        
        generateStrategy(checklists);
        
        foreach key, checklist_generation_function_name in __checklist_generation_function_names
        {
            call checklist_generation_function_name(checklist_collection);
        }
        
        foreach checklist_name in __specific_checklist_1_generation_function_names
        {
            ChecklistEntry [int] checklist_entries = checklist_collection.lookup(checklist_name).entries;
            foreach key, function_name in __specific_checklist_1_generation_function_names[checklist_name]
            {
                call function_name(checklist_entries);
            }
        }
        foreach key, request in __specific_checklist_generation_requests
        {
            int argument_count = request.checklist_names.count();
            string function_name = request.function_name;
            //"call request.function_name()" will not work
            if (argument_count == 3)
            {
                call function_name(checklist_collection.lookup(request.checklist_names[0]).entries, checklist_collection.lookup(request.checklist_names[1]).entries, checklist_collection.lookup(request.checklist_names[2]).entries);
            }
            else if (argument_count == 2)
            {
                call function_name(checklist_collection.lookup(request.checklist_names[0]).entries, checklist_collection.lookup(request.checklist_names[1]).entries);
            }
            else if (argument_count == 1)
            {
                call function_name(checklist_collection.lookup(request.checklist_names[0]).entries);
            }
        }
    }
    
    
    //Convert checklist_collection to checklists:
    checklists = ChecklistCollectionMergeWithLinearList(checklist_collection, checklists);
    
    generateMisc(checklists); //Last, due to drunkenness re-arranging
	
	//Remove checklists that have no entries:
	int [int] keys_to_remove;
	foreach key in checklists
	{
		Checklist cl = checklists[key];
		if (cl.entries.count() == 0)
			keys_to_remove.listAppend(key);
	}
	listRemoveKeys(checklists, keys_to_remove);
	listClear(keys_to_remove);
	
	//Go through desired output order:
	string [int] setting_desired_output_order = split_string_alternate("Tasks,Keys,Optional Tasks,Unimportant Tasks,Future Tasks,Resources,Future Unimportant Tasks,Required Items,Suggested Pulls,Florist Friar,Strategy", ",");
	foreach key in setting_desired_output_order {
		string title = setting_desired_output_order[key];
		//Find title in checklists:
		foreach key2 in checklists {
			Checklist cl = checklists[key2];
			if (cl.title == title) {
				ordered_output_checklists.listAppend(cl);
				keys_to_remove.listAppend(key2);
				break;
			}
		}
	}
	listRemoveKeys(checklists, keys_to_remove);
	listClear(keys_to_remove);
	
	//Add remainder:
	foreach key in checklists {
		Checklist cl = checklists[key];
		ordered_output_checklists.listAppend(cl);
	}
}

/**
Adds the checklists to the DOM.
@param ordered_output_checklists Checklists to output.
*/
void outputChecklists(Checklist [int] ordered_output_checklists) {
    Checklist extra_important_tasks;
    
	// Checklists:
	foreach i, cl in ordered_output_checklists {
        // Check for Pin
        if (__show_importance_bar && cl.title == "Tasks") {
            foreach key, entry in cl.entries {
                if (entry.importance_level <= -11) {
                    extra_important_tasks.entries.listAppend(entry);
                    if (entry.only_show_as_extra_important_pop_up) {
                        remove cl.entries[key];
                    }
                }  
            }
        }

        // Output
		PageWrite(ChecklistGenerate(cl));
	}
    
    if (__show_importance_bar && extra_important_tasks.entries.count() > 0) {
        extra_important_tasks.title = "Tasks";
        extra_important_tasks.disable_generating_id = true;
        PageWrite(HTMLGenerateTagPrefix("div", mapMake("id", "importance_bar", "style", "z-index:3;position:fixed; top:0;width:100%;max-width:" + __setting_horizontal_width + "px;visibility:hidden;")));
		PageWrite(ChecklistGenerate(extra_important_tasks, false));
        
        string background = "background-image:url(data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAAUCAYAAABMDlehAAAAb0lEQVR42gFkAJv/AFFRUf8AVlZW+ABcXFzvAGRjY+QAa2xr2AB1dHXLAH5+fr0AiIiIrgCTk5KfAJ2dnZAAqKiofwCzs7JwAL69vmAAyMjIUQDS0tJBANzb3DMA5eXlJwDt7e0bAPT09BAA+vr6B861MNMaArkVAAAAAElFTkSuQmCC);background-repeat:repeat-x;"; //use this gradient image, because alpha gradients are not consistent across browsers (compare black to white, 100% to zero opacity, on safari versus firefox)

        PageWrite(HTMLGenerateTagWrap("div", "", mapMake("id", "importance_bar_gradient", "style", "height:20px;transition:opacity 0.25s;opacity:0;" + background)));
        PageWrite(HTMLGenerateTagSuffix("div"));
    }
}
