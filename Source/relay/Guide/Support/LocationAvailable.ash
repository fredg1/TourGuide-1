//Library for checking if any given location is unlocked.
//Similar to canadv.ash, except there's no code for using items and no URLs are (currently) visited. This limits our accuracy.
//Currently, most locations are missing, sorry.
import "relay/Guide/Support/Error.ash"
import "relay/Guide/Support/List.ash"
import "relay/Guide/Support/Library.ash"


//Version compatibility locations:
location __location_palindome;
location __location_the_haunted_wine_cellar;

boolean __location_compatibility_inited = false;
//Should probably be called manually, as a backup:
void locationCompatibilityInit()
{
    //Different versions refer to locations by different names.
    //For instance, pre-13878 versions refer to the palindome as "The Palindome". Versions after that refer it to "Inside the Palindome".
    //This method provides correct lookups for both versions, without warnings.
    if (__location_compatibility_inited)
        return;
    __location_compatibility_inited = true;
    
    __location_palindome = "Inside the Palindome".to_location();
    if (__location_palindome == $location[none])
        __location_palindome = "The Palindome".to_location();
    if (mafiaIsPastRevision(13971)) //FIXME look up exact revision
        __location_the_haunted_wine_cellar = "The Haunted Wine Cellar".to_location();
}

locationCompatibilityInit(); //not sure if calling functions like this is intended. may break in the future?

boolean [location] __la_location_is_available;

boolean __la_commons_were_inited = false;
int __la_turncount_initialized_on = -1;


//Takes into account banishes and olfactions.
//Probably will be inaccurate in many corner cases, sorry.
float [monster] appearance_rates_adjusted(location l)
{
    //FIXME domed city of ronald/grimacia doesn't take into account alien appearance rate
    float [monster] source = l.appearance_rates();
    
    if (l == $location[the sleazy back alley])
        source[$monster[none]] = MIN(MAX(0, 20 - combat_rate_modifier()), 100);
    
    float minimum_monster_appearance = 1000000000.0;
    foreach m in source
    {
        if (m == $monster[none])
            continue;
        float v = source[m];
        if (v > 0.0)
        {
            if (v < minimum_monster_appearance)
                minimum_monster_appearance = v;
        }
    }
    
    float [monster] source_altered;
    foreach m in source
    {
        float v = source[m];
        if (m == $monster[none])
        {
            if (v < 0.0)
                source_altered[m] = 0.0;
            else
                source_altered[m] = v;
        }
        else
            source_altered[m] = v / minimum_monster_appearance;
    }
    
    
    boolean lawyers_relocated = (get_property_int("relocatePygmyLawyer") == my_ascensions());
    boolean janitors_relocated = (get_property_int("relocatePygmyJanitor") == my_ascensions());
    if (l == $location[the hidden park])
    {
        if (janitors_relocated)
            source_altered[$monster[pygmy janitor]] += 1.0;
        if (lawyers_relocated)
            source_altered[$monster[pygmy witch lawyer]] += 1.0;
    }
    if (($locations[The Hidden Apartment Building,The Hidden Bowling Alley,The Hidden Hospital,The Hidden Office Building] contains l))
    {
        if (janitors_relocated && (source_altered contains $monster[pygmy janitor]))
            remove source_altered[$monster[pygmy janitor]];
        if (lawyers_relocated && (source_altered contains $monster[pygmy witch lawyer]))
            remove source_altered[$monster[pygmy witch lawyer]];
    }
    
    foreach m in source_altered
    {
        if (m.is_banished())
            source_altered[m] = 0.0;
    }
    
    if ($effect[on the trail].have_effect() > 0)
    {
        monster olfacted_monster = get_property("olfactedMonster").to_monster();
        if (olfacted_monster != $monster[none])
        {
            if (source_altered contains olfacted_monster)
                source_altered[olfacted_monster] += 3.0; //FIXME is this correct?
        }
    }
    
    
    //Convert source_altered to source.
    if (l == __location_palindome)
    {
        if (!questPropertyPastInternalStepNumber("questL11Palindome", 3))
            source_altered[$monster[none]] = 0.0;
    }
    
    float total = 0.0;
    float nc_rate = clampf(source_altered[$monster[none]], 0.0, 100.0);
    float combat_rate = clampf(100.0 - nc_rate, 0.0, 100.0);
    foreach m in source_altered
    {
        float v = source_altered[m];
        if (m == $monster[none])
            continue;
        if (v > 0)
            total += v;
    }
    if ($locations[Guano Junction,the Batrat and Ratbat Burrow,the Beanbat Chamber] contains l)
    {
        //hacky, probably wrong:
        float v = total / 8.0;
        source_altered[$monster[screambat]] = v;
        total += v;
    }
    //oil peak goes here?
    
    if (total > 0.0)
    {
        foreach m in source_altered
        {
            if (m == $monster[none])
                continue;
            float v = source_altered[m];
            source_altered[m] = v / total * combat_rate;
        }
    }
    
    return source_altered;
}


float [monster] appearance_rates_adjusted_cancel_nc(location l)
{
    float [monster] base_rates = appearance_rates_adjusted(l);
    float nc_rate = base_rates[$monster[none]];
    float nc_inverse_multiplier = 1.0;
    if (nc_rate != 1.0)
        nc_inverse_multiplier = 1.0 / (1.0 - nc_rate);
    foreach m in base_rates
    {
        if (m == $monster[none])
            base_rates[m] = 0.0;
        else
            base_rates[m] *= nc_inverse_multiplier;
    }
    return base_rates;
}


//Do not call - internal implementation detail.
boolean locationAvailablePrivateCheck(location loc, Error able_to_find)
{
	string zone = loc.zone;
	
	if (zone == "KOL High School")
	{
		if (my_path_id() == PATH_KOLHS)
			return true;
		return false;
	}
	if (zone == "Mothership")
	{
		if (my_path_id() == PATH_BUGBEAR_INVASION)
			return true;
		return false;
	}
	if (zone == "BadMoon")
	{
		if (in_bad_moon())
			return true;
		return false;
	}
	
	switch (loc)
	{
		case $location[The Castle in the Clouds in the Sky (Ground floor)]:
			return get_property_int("lastCastleGroundUnlock") == my_ascensions();
		case $location[The Castle in the Clouds in the Sky (Top floor)]:
			return get_property_int("lastCastleTopUnlock") == my_ascensions();
		case $location[The Haunted Kitchen]:
		case $location[The Haunted Conservatory]:
            return true; //FIXME exact detection
		case $location[The Haunted Billiards Room]:
            if (lookupItem("7301").available_amount() > 0)
                return true;
			//return get_property_int("lastManorUnlock") == my_ascensions();
		case $location[The Haunted Bedroom]:
		case $location[The Haunted Bathroom]:
        case $location[the haunted gallery]:
            //FIXME detect this
			return get_property_int("lastSecondFloorUnlock") == my_ascensions();
        case $location[the haunted ballroom]:
            return questPropertyPastInternalStepNumber("questM21Dance", 4);
        case $location[the batrat and ratbat burrow]:
            return questPropertyPastInternalStepNumber("questL04Bat", 2);
        case $location[the beanbat chamber]:
            return questPropertyPastInternalStepNumber("questL04Bat", 3);
        case $location[the boss bat's lair]:
            return questPropertyPastInternalStepNumber("questL04Bat", 4);
		case $location[cobb's knob barracks]:
		case $location[cobb's knob kitchens]:
		case $location[cobb's knob harem]:
		case $location[cobb's knob treasury]:
			string quest_value = get_property("questL05Goblin");
			if (quest_value == "finished")
				return true;
			else if (questPropertyPastInternalStepNumber("questL05Goblin", 1))
			{
				//Inference - quest is started. If map is missing, area must be unlocked
				if ($item[cobb's knob map].available_amount() > 0)
					return false;
				else //no map, must be available
					return true;
			}
			//unstarted, impossible
            return false;
		case $location[Vanya's Castle Chapel]:
			if ($item[map to Vanya's Castle].available_amount() > 0)
				return true;
			return false;
		case $location[the hidden park]:
			return questPropertyPastInternalStepNumber("questL11Worship", 4);
        case $location[the hidden temple]:
            return (get_property_int("lastTempleUnlock") == my_ascensions());
		case $location[the spooky forest]:
			return questPropertyPastInternalStepNumber("questL02Larva", 1);
		case $location[The Smut Orc Logging Camp]:
			return questPropertyPastInternalStepNumber("questL09Topping", 1);
		case $location[the black forest]:
			return questPropertyPastInternalStepNumber("questL11MacGuffin", 1);
		case $location[guano junction]:
		case $location[the bat hole entrance]:
			return questPropertyPastInternalStepNumber("questL04Bat", 1);
		case $location[itznotyerzitz mine]:
			return questPropertyPastInternalStepNumber("questL08Trapper", 2);
        case $location[the arid, extra-dry desert]:
			return (questPropertyPastInternalStepNumber("questL11MacGuffin", 3) || $item[your father's MacGuffin diary].available_amount() > 0);
        case $location[the oasis]:
			return (get_property_int("desertExploration") > 0) && (questPropertyPastInternalStepNumber("questL11MacGuffin", 3) || $item[your father's MacGuffin diary].available_amount() > 0);
        case $location[the defiled alcove]:
			return questPropertyPastInternalStepNumber("questL07Cyrptic", 1) && get_property_int("cyrptAlcoveEvilness") > 0;
        case $location[the defiled cranny]:
			return questPropertyPastInternalStepNumber("questL07Cyrptic", 1) && get_property_int("cyrptCrannyEvilness") > 0;
        case $location[the defiled niche]:
			return questPropertyPastInternalStepNumber("questL07Cyrptic", 1) && get_property_int("cyrptNicheEvilness") > 0;
        case $location[the defiled nook]:
			return questPropertyPastInternalStepNumber("questL07Cyrptic", 1) && get_property_int("cyrptNookEvilness") > 0;
		case $location[south of the border]:
			return $items[pumpkin carriage,desert bus pass, bitchin' meatcar, tin lizzie].available_amount() > 0;
		default:
			break;
	}
    if (loc.turnsAttemptedInLocation() > 0) //FIXME make this finer-grained, this is hacky
        return true;
	
	ErrorSet(able_to_find, "");
	return false;
}

void locationAvailablePrivateInit()
{
	if (__la_commons_were_inited && __la_turncount_initialized_on == my_turncount())
		return;
        
    if (__la_location_is_available.count() > 0)
    {
        foreach key in __la_location_is_available
        {
            remove __la_location_is_available[key];
        }
    }
	
	boolean [location] locations_always_available = $locations[the haunted pantry,the sleazy back alley,the outskirts of cobb's knob,the limerick dungeon,The Haiku Dungeon,The Daily Dungeon];
	foreach loc in locations_always_available
	{
		if (loc == $location[none])
			continue;
		__la_location_is_available[loc] = true;
	}
		
	string zones_never_accessible_string = "Gyms,Crimbo06,Crimbo07,Crimbo08,Crimbo09,Crimbo10,The Candy Diorama,Crimbo12,WhiteWed";
	
	item [location] locations_unlocked_by_item;
	effect [location] locations_unlocked_by_effect;
	
	item [string] zones_unlocked_by_item;
	effect [string] zones_unlocked_by_effect;
	
	locations_unlocked_by_item[$location[Cobb's Knob Menagerie\, Level 1]] = $item[Cobb's Knob Menagerie key];
	locations_unlocked_by_item[$location[Cobb's Knob Menagerie\, Level 2]] = $item[Cobb's Knob Menagerie key];
	locations_unlocked_by_item[$location[Cobb's Knob Menagerie\, Level 3]] = $item[Cobb's Knob Menagerie key];
	
	//locations_unlocked_by_item[$location[the haunted ballroom]] = $item[spookyraven ballroom key];
	locations_unlocked_by_item[$location[The Haunted Library]] = $item[spookyraven library key];
	//locations_unlocked_by_item[$location[The Haunted Gallery]] = $item[spookyraven gallery key];
	locations_unlocked_by_item[$location[The Castle in the Clouds in the Sky (Basement)]] = $item[S.O.C.K.];
	locations_unlocked_by_item[$location[the hole in the sky]] = $item[steam-powered model rocketship];
	
	locations_unlocked_by_item[$location[Vanya's Castle Foyer]] = $item[map to Vanya's Castle];
	
	
	zones_unlocked_by_item["Magic Commune"] = $item[map to the Magic Commune];
	zones_unlocked_by_item["Landscaper"] = $item[Map to The Landscaper's Lair];
	zones_unlocked_by_item["Kegger"] = $item[map to the Kegger in the Woods];
	zones_unlocked_by_item["Ellsbury's Claim"] = $item[Map to Ellsbury's Claim];
	zones_unlocked_by_item["Memories"] = $item[empty agua de vida bottle];
	zones_unlocked_by_item["Casino"] = $item[casino pass];
	
	zones_unlocked_by_effect["Astral"] = $effect[Half-Astral];
	zones_unlocked_by_effect["Spaaace"] = $effect[Transpondent];
	zones_unlocked_by_effect["RabbitHole"] = $effect[Down the Rabbit Hole];
	zones_unlocked_by_effect["Wormwood"] = $effect[Absinthe-Minded];	
	zones_unlocked_by_effect["Suburbs"] = $effect[Dis Abled];
	
	string [int] zones_never_accessible = split_string_alternate(zones_never_accessible_string, ",");
	
	boolean [string] zone_accessibility_status = zones_never_accessible.listGeneratePresenceMap();
	
	
	foreach loc in $locations[Shivering Timbers,A Skeleton Invasion!,The Cannon Museum,A Swarm of Yeti-Mounted Skeletons,The Bonewall,A Massive Flying Battleship,A Supply Train,The Bone Star,Grim Grimacite Site,A Pile of Old Servers,The Haunted Sorority House,Fightin' Fire,Super-Intense Mega-Grassfire,Fierce Flying Flames,Lord Flameface's Castle Entryway,Lord Flameface's Castle Belfry,Lord Flameface's Throne Room,A Stinking Abyssal Portal,A Scorching Abyssal Portal,A Terrifying Abyssal Portal,A Freezing Abyssal Portal,An Unsettling Abyssal Portal,A Yawning Abyssal Portal,The Space Odyssey Discotheque,The Spirit World]
	{
		__la_location_is_available[loc] = false;
	}
	
	foreach loc in locations_unlocked_by_item
	{
		if (locations_unlocked_by_item[loc].available_amount() > 0)
			__la_location_is_available[loc] = true;
		else
			__la_location_is_available[loc] = false;
	}
	foreach loc in locations_unlocked_by_effect
	{
		if (locations_unlocked_by_effect[loc].have_effect() > 0)
			__la_location_is_available[loc] = true;
		else
			__la_location_is_available[loc] = false;
	}
	
	foreach zone in zones_unlocked_by_item
	{
		if (zones_unlocked_by_item[zone].available_amount() > 0)
			zone_accessibility_status[zone] = true;
		else
			zone_accessibility_status[zone] = false;
	}
	foreach zone in zones_unlocked_by_effect
	{
		if (zones_unlocked_by_effect[zone].have_effect() > 0)
			zone_accessibility_status[zone] = true;
		else
			zone_accessibility_status[zone] = false;
	}
	
	
	
	
	
	foreach loc in $locations[]
	{
		if (zone_accessibility_status contains (loc.zone))
			__la_location_is_available[loc] = zone_accessibility_status[loc.zone];
	}
		
		
	__la_commons_were_inited = true;
    __la_turncount_initialized_on = my_turncount();
}

boolean locationAvailable(location loc, Error able_to_find)
{
    locationAvailablePrivateInit();
	if ((__la_location_is_available contains loc))
		return __la_location_is_available[loc];
	
	boolean [int] could_find;
	boolean is_available = locationAvailablePrivateCheck(loc, able_to_find);
	if (able_to_find.was_error)
		return false;
	__la_location_is_available[loc] = is_available;
	
	return is_available;
}

boolean locationAvailable(location loc)
{
	return locationAvailable(loc, ErrorMake());
}


void locationAvailableRunDiagnostics()
{
	location [string][int] unknown_locations_by_zone;
	
	foreach loc in $locations[]
	{
		Error able_to_find;
		locationAvailable(loc, able_to_find);
		if (!able_to_find.was_error)
			continue;
		if (!(unknown_locations_by_zone contains (loc.zone)))
			unknown_locations_by_zone[loc.zone] = listMakeBlankLocation();
		unknown_locations_by_zone[loc.zone].listAppend(loc);
	}
	if (unknown_locations_by_zone.count() > 0)
	{
		print("Unknown locations in location availability tester:");
		foreach zone in unknown_locations_by_zone
		{
			print(zone + ":");
			foreach key in unknown_locations_by_zone[zone]
			{
				location loc = unknown_locations_by_zone[zone][key];
				print("&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;" + loc);
			}
		}
	}
}

string HTMLGenerateFutureTextByLocationAvailability(string base_text, location place)
{
    if (!locationAvailable(place) && place != $location[none])
    {
        base_text = HTMLGenerateSpanOfClass(base_text, "r_future_option");
    }
    return base_text;
}

string HTMLGenerateFutureTextByLocationAvailability(location place)
{
	return HTMLGenerateFutureTextByLocationAvailability(place.to_string(), place);
}



string [location] __clickable_urls_map;
string getClickableURLForLocation(location l, Error unable_to_find_url)
{
    if (l == $location[none])
        return "";
        
    if (__clickable_urls_map.count() == 0)
    {
        //Initialize:
        //We use to_location() lookups here because $location[] will halt the script if the location name changes.
        //Probably could coalese these into foreach s in $strings[] loops, or move this to an external data file.
        string [string] lookup_map;
        lookup_map["Pump Up Muscle"] = "place.php?whichplace=knoll_friendly&action=dk_gym";
        lookup_map["Richard's Hobo Mysticality"] = "clan_hobopolis.php?place=3";
        lookup_map["Richard's Hobo Moxie"] = "clan_hobopolis.php?place=3";
        lookup_map["Richard's Hobo Muscle"] = "clan_hobopolis.php?place=3";
        lookup_map["South of the Border"] = "place.php?whichplace=desertbeach";
        lookup_map["The Oasis"] = "place.php?whichplace=desertbeach";
        lookup_map["The Arid, Extra-Dry Desert"] = "place.php?whichplace=desertbeach";
        lookup_map["The Shore, Inc. Travel Agency"] = "place.php?whichplace=desertbeach";
        lookup_map["The Upper Chamber"] = "pyramid.php";
        lookup_map["The Middle Chamber"] = "pyramid.php";
        lookup_map["The Lower Chambers"] = "pyramid.php";
        lookup_map["Goat Party"] = "casino.php";
        lookup_map["Pirate Party"] = "casino.php";
        lookup_map["Lemon Party"] = "casino.php";
        lookup_map["The Roulette Tables"] = "casino.php";
        lookup_map["The Poker Room"] = "casino.php";
        lookup_map["The Haiku Dungeon"] = "da.php";
        lookup_map["The Limerick Dungeon"] = "da.php";
        lookup_map["The Enormous Greater-Than Sign"] = "da.php";
        lookup_map["The Dungeons of Doom"] = "da.php";
        lookup_map["The Daily Dungeon"] = "da.php";
        lookup_map["Video Game Level 1"] = "place.php?whichplace=faqdungeon";
        lookup_map["Video Game Level 2"] = "place.php?whichplace=faqdungeon";
        lookup_map["Video Game Level 3"] = "place.php?whichplace=faqdungeon";
        lookup_map["A Maze of Sewer Tunnels"] = "clan_hobopolis.php";
        lookup_map["Hobopolis Town Square"] = "clan_hobopolis.php?place=2";
        lookup_map["Burnbarrel Blvd."] = "clan_hobopolis.php?place=4";
        lookup_map["Exposure Esplanade"] = "clan_hobopolis.php?place=5";
        lookup_map["The Heap"] = "clan_hobopolis.php?place=6";
        lookup_map["The Ancient Hobo Burial Ground"] = "clan_hobopolis.php?place=7";
        lookup_map["The Purple Light District"] = "clan_hobopolis.php?place=8";
        lookup_map["The Slime Tube"] = "clan_slimetube.php";
        lookup_map["Dreadsylvanian Woods"] = "clan_dreadsylvania.php";
        lookup_map["Dreadsylvanian Village"] = "clan_dreadsylvania.php";
        lookup_map["Dreadsylvanian Castle"] = "clan_dreadsylvania.php";
        lookup_map["The Briny Deeps"] = "place.php?whichplace=thesea";
        lookup_map["The Brinier Deepers"] = "place.php?whichplace=thesea";
        lookup_map["The Briniest Deepests"] = "place.php?whichplace=thesea";
        lookup_map["An Octopus's Garden"] = "seafloor.php";
        lookup_map["The Wreck of the Edgar Fitzsimmons"] = "seafloor.php";
        lookup_map["Madness Reef"] = "seafloor.php";
        lookup_map["The Mer-Kin Outpost"] = "seafloor.php";
        lookup_map["The Skate Park"] = "seafloor.php";
        lookup_map["The Marinara Trench"] = "seafloor.php";
        lookup_map["Anemone Mine"] = "seafloor.php";
        lookup_map["The Dive Bar"] = "seafloor.php";
        lookup_map["The Coral Corral"] = "seafloor.php";
        lookup_map["Mer-kin Elementary School"] = "sea_merkin.php?seahorse=1";
        lookup_map["Mer-kin Library"] = "sea_merkin.php?seahorse=1";
        lookup_map["Mer-kin Gymnasium"] = "sea_merkin.php?seahorse=1";
        lookup_map["Mer-kin Colosseum"] = "sea_merkin.php?seahorse=1";
        lookup_map["The Caliginous Abyss"] = "seafloor.php";
        lookup_map["Anemone Mine (Mining)"] = "seafloor.php";
        lookup_map["The Sleazy Back Alley"] = "place.php?whichplace=town_wrong";
        lookup_map["The Copperhead Club"] = "place.php?whichplace=town_wrong";
        lookup_map["The Haunted Kitchen"] = "place.php?whichplace=manor1";
        lookup_map["The Haunted Conservatory"] = "place.php?whichplace=manor1";
        lookup_map["The Haunted Library"] = "place.php?whichplace=manor1";
        lookup_map["The Haunted Billiards Room"] = "place.php?whichplace=manor1";
        lookup_map["The Haunted Pantry"] = "place.php?whichplace=manor1";
        lookup_map["The Haunted Gallery"] = "place.php?whichplace=manor2";
        lookup_map["The Haunted Bathroom"] = "place.php?whichplace=manor2";
        lookup_map["The Haunted Bedroom"] = "place.php?whichplace=manor2";
        lookup_map["The Haunted Ballroom"] = "place.php?whichplace=manor2";
        lookup_map["The Haunted Boiler Room"] = "place.php?whichplace=manor4";
        lookup_map["The Haunted Laundry Room"] = "place.php?whichplace=manor4";
        lookup_map[__location_the_haunted_wine_cellar.to_string()] = "place.php?whichplace=manor4";
        lookup_map["The Haunted Laboratory"] = "place.php?whichplace=manor3";
        lookup_map["The Haunted Nursery"] = "place.php?whichplace=manor3";
        lookup_map["The Haunted Storage Room"] = "place.php?whichplace=manor3";
        lookup_map["Summoning Chamber"] = "place.php?whichplace=manor4";
        lookup_map["The Hidden Apartment Building"] = "place.php?whichplace=hiddencity";
        lookup_map["The Hidden Hospital"] = "place.php?whichplace=hiddencity";
        lookup_map["The Hidden Office Building"] = "place.php?whichplace=hiddencity";
        lookup_map["The Hidden Bowling Alley"] = "place.php?whichplace=hiddencity";
        lookup_map["The Hidden Park"] = "place.php?whichplace=hiddencity";
        lookup_map["An Overgrown Shrine (Northwest)"] = "place.php?whichplace=hiddencity";
        lookup_map["An Overgrown Shrine (Southwest)"] = "place.php?whichplace=hiddencity";
        lookup_map["An Overgrown Shrine (Northeast)"] = "place.php?whichplace=hiddencity";
        lookup_map["An Overgrown Shrine (Southeast)"] = "place.php?whichplace=hiddencity";
        lookup_map["A Massive Ziggurat"] = "place.php?whichplace=hiddencity";
        lookup_map["The Typical Tavern Cellar"] = "cellar.php";
        lookup_map["The Spooky Forest"] = "place.php?whichplace=woods";
        lookup_map["The Hidden Temple"] = "place.php?whichplace=woods";
        lookup_map["A Barroom Brawl"] = "tavern.php";
        lookup_map["8-Bit Realm"] = "place.php?whichplace=woods";
        lookup_map["Whitey's Grove"] = "place.php?whichplace=woods";
        lookup_map["The Road to White Citadel"] = "place.php?whichplace=woods";
        lookup_map["The Black Forest"] = "place.php?whichplace=woods";
        lookup_map["The Old Landfill"] = "place.php?whichplace=woods";
        lookup_map["The Bat Hole Entrance"] = "place.php?whichplace=bathole";
        lookup_map["Guano Junction"] = "place.php?whichplace=bathole";
        lookup_map["The Batrat and Ratbat Burrow"] = "place.php?whichplace=bathole";
        lookup_map["The Beanbat Chamber"] = "place.php?whichplace=bathole";
        lookup_map["The Boss Bat's Lair"] = "place.php?whichplace=bathole";
        lookup_map["The Red Queen's Garden"] = "place.php?whichplace=rabbithole";
        lookup_map["The Clumsiness Grove"] = "suburbandis.php";
        lookup_map["The Maelstrom of Lovers"] = "suburbandis.php";
        lookup_map["The Glacier of Jerks"] = "suburbandis.php";
        lookup_map["The Degrassi Knoll Restroom"] = "bigisland.php?place=orchard";
        lookup_map["The Degrassi Knoll Bakery"] = "bigisland.php?place=orchard";
        lookup_map["The Degrassi Knoll Gym"] = "bigisland.php?place=orchard";
        lookup_map["The Degrassi Knoll Garage"] = "bigisland.php?place=orchard";
        lookup_map["The \"Fun\" House"] = "place.php?whichplace=plains";
        lookup_map["Pre-Cyrpt Cemetary"] = "place.php?whichplace=plains";
        lookup_map["Post-Cyrpt Cemetary"] = "place.php?whichplace=plains";
        lookup_map["Tower Ruins"] = "fernruin.php";
        lookup_map["Fernswarthy's Basement"] = "basement.php";
        lookup_map["Cobb's Knob Barracks"] = "cobbsknob.php";
        lookup_map["Cobb's Knob Kitchens"] = "cobbsknob.php";
        lookup_map["Cobb's Knob Harem"] = "cobbsknob.php";
        lookup_map["Cobb's Knob Treasury"] = "cobbsknob.php";
        lookup_map["Throne Room"] = "cobbsknob.php";
        lookup_map["Cobb's Knob Laboratory"] = "cobbsknob.php?action=tolabs";
        lookup_map["The Knob Shaft"] = "cobbsknob.php?action=tolabs";
        lookup_map["The Knob Shaft (Mining)"] = "cobbsknob.php?action=tolabs";
        lookup_map["Cobb's Knob Menagerie, Level 1"] = "cobbsknob.php?action=tomenagerie";
        lookup_map["Cobb's Knob Menagerie, Level 2"] = "cobbsknob.php?action=tomenagerie";
        lookup_map["Cobb's Knob Menagerie, Level 3"] = "cobbsknob.php?action=tomenagerie";
        lookup_map["The Dark Neck of the Woods"] = "friars.php";
        lookup_map["The Dark Heart of the Woods"] = "friars.php";
        lookup_map["The Dark Elbow of the Woods"] = "friars.php";
        lookup_map["Friar Ceremony Location"] = "friars.php";
        lookup_map["Pandamonium Slums"] = "pandamonium.php";
        lookup_map["The Laugh Floor"] = "pandamonium.php?action=beli";
        lookup_map["Infernal Rackets Backstage"] = "pandamonium.php?action=infe";
        lookup_map["The Defiled Nook"] = "crypt.php";
        lookup_map["The Defiled Cranny"] = "crypt.php";
        lookup_map["The Defiled Alcove"] = "crypt.php";
        lookup_map["The Defiled Niche"] = "crypt.php";
        lookup_map["Haert of the Cyrpt"] = "crypt.php";
        lookup_map["Frat House"] = "island.php";
        lookup_map["Frat House In Disguise"] = "island.php";
        lookup_map["The Frat House (Bombed Back to the Stone Age)"] = "island.php";
        lookup_map["Hippy Camp"] = "island.php";
        lookup_map["Hippy Camp In Disguise"] = "island.php";
        lookup_map["The Hippy Camp (Bombed Back to the Stone Age)"] = "island.php";
        lookup_map["The Obligatory Pirate's Cove"] = "island.php";
        lookup_map["Barrrney's Barrr"] = "place.php?whichplace=cove";
        lookup_map["The F'c'le"] = "place.php?whichplace=cove";
        lookup_map["The Poop Deck"] = "place.php?whichplace=cove";
        lookup_map["Belowdecks"] = "place.php?whichplace=cove";
        lookup_map["Post-War Junkyard"] = "island.php";
        lookup_map["McMillicancuddy's Farm"] = "island.php";
        lookup_map["The Battlefield (Frat Uniform)"] = "bigisland.php";
        lookup_map["The Battlefield (Hippy Uniform)"] = "bigisland.php";
        lookup_map["Wartime Frat House"] = "island.php";
        lookup_map["Wartime Frat House (Hippy Disguise)"] = "island.php";
        lookup_map["Wartime Hippy Camp"] = "island.php";
        lookup_map["Wartime Hippy Camp (Frat Disguise)"] = "island.php";
        lookup_map["Next to that Barrel with Something Burning in it"] = "bigisland.php?place=junkyard";
        lookup_map["Near an Abandoned Refrigerator"] = "bigisland.php?place=junkyard";
        lookup_map["Over Where the Old Tires Are"] = "bigisland.php?place=junkyard";
        lookup_map["Out by that Rusted-Out Car"] = "bigisland.php?place=junkyard";
        lookup_map["Sonofa Beach"] = "bigisland.php?place=lighthouse";
        lookup_map["The Themthar Hills"] = "bigisland.php?place=nunnery";
        lookup_map["McMillicancuddy's Barn"] = "bigisland.php?place=farm";
        lookup_map["McMillicancuddy's Pond"] = "bigisland.php?place=farm";
        lookup_map["McMillicancuddy's Back 40"] = "bigisland.php?place=farm";
        lookup_map["McMillicancuddy's Other Back 40"] = "bigisland.php?place=farm";
        lookup_map["McMillicancuddy's Granary"] = "bigisland.php?place=farm";
        lookup_map["McMillicancuddy's Bog"] = "bigisland.php?place=farm";
        lookup_map["McMillicancuddy's Family Plot"] = "bigisland.php?place=farm";
        lookup_map["McMillicancuddy's Shady Thicket"] = "bigisland.php?place=farm";
        lookup_map["The Hatching Chamber"] = "bigisland.php?place=orchard";
        lookup_map["The Feeding Chamber"] = "bigisland.php?place=orchard";
        lookup_map["The Royal Guard Chamber"] = "bigisland.php?place=orchard";
        lookup_map["The Filthworm Queen's Chamber"] = "bigisland.php?place=orchard";
        lookup_map["Noob Cave"] = "tutorial.php";
        lookup_map["The Dire Warren"] = "tutorial.php";
        lookup_map["The Valley of Rof L'm Fao"] = "place.php?whichplace=mountains";
        lookup_map["Mt. Molehill"] = "place.php?whichplace=mountains";
        lookup_map["The Barrel Full of Barrels"] = "barrel.php";
        lookup_map["Nemesis Cave"] = "cave.php";
        lookup_map["The Smut Orc Logging Camp"] = "place.php?whichplace=orc_chasm";
        lookup_map["The Thinknerd Warehouse"] = "place.php?whichplace=mountains";
        lookup_map["A Mob of Zeppelin Protesters"] = "place.php?whichplace=zeppelin";
        lookup_map["The Red Zeppelin"] = "place.php?whichplace=zeppelin";
        lookup_map["A-Boo Peak"] = "place.php?whichplace=highlands";
        lookup_map["Twin Peak"] = "place.php?whichplace=highlands";
        lookup_map["Oil Peak"] = "place.php?whichplace=highlands";
        lookup_map["Itznotyerzitz Mine"] = "place.php?whichplace=mclargehuge";
        lookup_map["The Goatlet"] = "place.php?whichplace=mclargehuge";
        lookup_map["Lair of the Ninja Snowmen"] = "place.php?whichplace=mclargehuge";
        lookup_map["The eXtreme Slope"] = "place.php?whichplace=mclargehuge";
        lookup_map["Mist-Shrouded Peak"] = "place.php?whichplace=mclargehuge";
        lookup_map["The Icy Peak"] = "place.php?whichplace=mclargehuge";
        lookup_map["Itznotyerzitz Mine (in Disguise)"] = "place.php?whichplace=mclargehuge";
        lookup_map["The Penultimate Fantasy Airship"] = "place.php?whichplace=beanstalk";
        lookup_map["The Castle in the Clouds in the Sky (Basement)"] = "place.php?whichplace=giantcastle";
        lookup_map["The Castle in the Clouds in the Sky (Ground Floor)"] = "place.php?whichplace=giantcastle";
        lookup_map["The Castle in the Clouds in the Sky (Top Floor)"] = "place.php?whichplace=giantcastle";
        lookup_map["The Hole in the Sky"] = "place.php?whichplace=beanstalk";
        lookup_map["Sorceress' Hedge Maze"] = "lair3.php";
        lookup_map["The Broodling Grounds"] = "volcanoisland.php";
        lookup_map["The Outer Compound"] = "volcanoisland.php";
        lookup_map["The Temple Portico"] = "volcanoisland.php";
        lookup_map["Convention Hall Lobby"] = "volcanoisland.php";
        lookup_map["Outside the Club"] = "volcanoisland.php";
        lookup_map["The Island Barracks"] = "volcanoisland.php";
        lookup_map["The Nemesis' Lair"] = "volcanoisland.php";
        lookup_map["The Bugbear Pen"] = "bigisland.php?place=orchard";
        lookup_map["The Spooky Gravy Burrow"] = "bigisland.php?place=orchard";
        lookup_map["The Stately Pleasure Dome"] = "place.php?whichplace=wormwood";
        lookup_map["The Mouldering Mansion"] = "place.php?whichplace=wormwood";
        lookup_map["The Rogue Windmill"] = "place.php?whichplace=wormwood";
        lookup_map["The Primordial Soup"] = "place.php?whichplace=memories";
        lookup_map["The Jungles of Ancient Loathing"] = "place.php?whichplace=memories";
        lookup_map["Seaside Megalopolis"] = "place.php?whichplace=memories";
        lookup_map["Domed City of Ronaldus"] = "place.php?whichplace=spaaace";
        lookup_map["Domed City of Grimacia"] = "place.php?whichplace=spaaace";
        lookup_map["Hamburglaris Shield Generator"] = "place.php?whichplace=spaaace";
        lookup_map["The Arrrboretum"] = "place.php?whichplace=woods";
        lookup_map["Spectral Pickle Factory"] = "place.php?whichplace=plains";
        lookup_map["Lollipop Forest"] = "";
        lookup_map["Fudge Mountain"] = "";
        lookup_map["WarBear Fortress (First Level)"] = "";
        lookup_map["WarBear Fortress (Second Level)"] = "";
        lookup_map["WarBear Fortress (Third Level)"] = "";
        lookup_map["Crimbokutown Toy Factory"] = "";
        lookup_map["Elf Alley"] = "";
        lookup_map["CRIMBCO cubicles"] = "";
        lookup_map["CRIMBCO WC"] = "";
        lookup_map["Crimbo Town Toy Factory"] = "";
        lookup_map["The Don's Crimbo Compound"] = "";
        lookup_map["Atomic Crimbo Toy Factory"] = "";
        lookup_map["Old Crimbo Town Toy Factory"] = "";
        lookup_map["Sinister Dodecahedron"] = "";
        lookup_map["Crimbo Town Toy Factory"] = "";
        lookup_map["Simple Tool-Making Cave"] = "";
        lookup_map["Spooky Fright Factory"] = "";
        lookup_map["Crimborg Collective Factory"] = "";
        lookup_map["Crimbo Town Toy Factory"] = "";
        lookup_map["Future Market Square"] = "";
        lookup_map["Mall of the Future"] = "";
        lookup_map["Future Wrong Side of the Tracks"] = "";
        lookup_map["Icy Peak of the Past"] = "";
        lookup_map["Shivering Timbers"] = "";
        lookup_map["A Skeleton Invasion!"] = "";
        lookup_map["The Cannon Museum"] = "";
        lookup_map["A Swarm of Yeti-Mounted Skeletons"] = "";
        lookup_map["The Bonewall"] = "";
        lookup_map["A Massive Flying Battleship"] = "";
        lookup_map["A Supply Train"] = "";
        lookup_map["The Bone Star"] = "";
        lookup_map["Grim Grimacite Site"] = "";
        lookup_map["A Pile of Old Servers"] = "";
        lookup_map["The Haunted Sorority House"] = "";
        lookup_map["Fightin' Fire"] = "";
        lookup_map["Super-Intense Mega-Grassfire"] = "";
        lookup_map["Fierce Flying Flames"] = "";
        lookup_map["Lord Flameface's Castle Entryway"] = "";
        lookup_map["Lord Flameface's Castle Belfry"] = "";
        lookup_map["Lord Flameface's Throne Room"] = "";
        lookup_map["A Stinking Abyssal Portal"] = "";
        lookup_map["A Scorching Abyssal Portal"] = "";
        lookup_map["A Terrifying Abyssal Portal"] = "";
        lookup_map["A Freezing Abyssal Portal"] = "";
        lookup_map["An Unsettling Abyssal Portal"] = "";
        lookup_map["A Yawning Abyssal Portal"] = "";
        lookup_map["The Space Odyssey Discotheque"] = "";
        lookup_map["The Spirit World"] = "";
        lookup_map["Some Scattered Smoking Debris"] = "place.php?whichplace=crashsite";
        lookup_map["Anger Man's Level"] = "place.php?whichplace=junggate_3";
        lookup_map["Fear Man's Level"] = "place.php?whichplace=junggate_3";
        lookup_map["Doubt Man's Level"] = "place.php?whichplace=junggate_3";
        lookup_map["Regret Man's Level"] = "place.php?whichplace=junggate_3";
        lookup_map["The Nightmare Meatrealm"] = "place.php?whichplace=junggate_6";
        lookup_map["A Kitchen Drawer"] = "place.php?whichplace=junggate_5";
        lookup_map["A Grocery Bag"] = "place.php?whichplace=junggate_5";
        lookup_map["Chinatown Shops"] = "place.php?whichplace=junggate_1";
        lookup_map["Triad Factory"] = "place.php?whichplace=junggate_1";
        lookup_map["1st Floor, Shiawase-Mitsuhama Building"] = "place.php?whichplace=junggate_1";
        lookup_map["2nd Floor, Shiawase-Mitsuhama Building"] = "place.php?whichplace=junggate_1";
        lookup_map["3rd Floor, Shiawase-Mitsuhama Building"] = "place.php?whichplace=junggate_1";
        lookup_map["Chinatown Tenement"] = "place.php?whichplace=junggate_1";
        lookup_map["A Deserted Stretch of I-911"] = "place.php?whichplace=ioty2014_hare";
        lookup_map["The Prince's Restroom"] = "place.php?whichplace=ioty2014_cindy";
        lookup_map["The Prince's Dance Floor"] = "place.php?whichplace=ioty2014_cindy";
        lookup_map["The Prince's Kitchen"] = "place.php?whichplace=ioty2014_cindy";
        lookup_map["The Prince's Balcony"] = "place.php?whichplace=ioty2014_cindy";
        lookup_map["The Prince's Lounge"] = "place.php?whichplace=ioty2014_cindy";
        lookup_map["The Prince's Canapes table"] = "place.php?whichplace=ioty2014_cindy";
        lookup_map["The Inner Wolf Gym"] = "place.php?whichplace=ioty2014_wolf";
        lookup_map["Unleash Your Inner Wolf"] = "place.php?whichplace=ioty2014_wolf";
        lookup_map["The Cave Before Time"] = "place.php?whichplace=twitch";
        lookup_map["An Illicit Bohemian Party"] = "place.php?whichplace=twitch";
        lookup_map["Moonshiners' Woods"] = "place.php?whichplace=twitch";
        lookup_map["The Fun-Guy Mansion"] = "place.php?whichplace=airport_sleaze";
        lookup_map["Sloppy Seconds Diner"] = "place.php?whichplace=airport_sleaze";
        lookup_map["The Sunken Party Yacht"] = "place.php?whichplace=airport_sleaze";
        //Conditionals:
        if ($location[cobb's knob barracks].locationAvailable())
            lookup_map["The Outskirts of Cobb's Knob"] = "cobbsknob.php";
        else
            lookup_map["The Outskirts of Cobb's Knob"] = "place.php?whichplace=plains";
            
        if (knoll_available())
            lookup_map["Post-Quest Bugbear Pens"] = "place.php?whichplace=knoll_friendly";
        else
            lookup_map["Post-Quest Bugbear Pens"] =  "place.php?whichplace=knoll_hostile";
            
        if ($item[talisman o' nam].equipped_amount() > 0)
            lookup_map["Palindome"] = "place.php?whichplace=palindome";
        else
            lookup_map["Palindome"] = "inventory.php?which=2";
        
        //Parse into locations:
        foreach location_name in lookup_map
        {
            location l = location_name.to_location();
            if (l == $location[none])
            {
                if (__setting_debug_mode)
                    print("Location \"" + location_name + "\" does not appear to exist anymore.");
                continue;
            }
            __clickable_urls_map[l] = lookup_map[location_name];
        }
    }
    if (__clickable_urls_map contains l)
        return __clickable_urls_map[l];

    ErrorSet(unable_to_find_url);
    return "";
}

string getClickableURLForLocation(location l)
{
    return l.getClickableURLForLocation(ErrorMake());
}

string getClickableURLForLocationIfAvailable(location l)
{
    Error able_to_find;
    boolean found = l.locationAvailable(able_to_find);
    if (able_to_find.was_error) //assume it's available, since we don't know
        found = true;
    if (found)
        return l.getClickableURLForLocation();
    else
        return "";
}