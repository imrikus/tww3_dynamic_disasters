--[[

    Skaven Incursions, By Frodo45127.

    Mid-late game repeatable disaster where skavens pop down a few undercities, and try to get one of the special buildings triggered.

    Repeatable. Supports debug mode.

    Requirements:
        - Random chance: 2% (1/50 turns).
        - +1% for each possible attacker faction that has been wiped out (not confederated).
        - At least turn 30 (so the player is... a bit prepared).
        - At least one of the potential attackers must be alive (you can end this disaster by killing them all).
        - At least 10 turns have passed since the last incursion.

    Effects:
        - Trigger/First Warning:
            - Message of warning about skaven marks on a city.
            - Create an undercity for a living major skaven faction and start expanding it like crazy (max 10 expansions).
            - After 4-10 turns, popup the anexation building on all of them.
            - If the skaven faction is Skryre, swap one of them with a nuke.
        - Invasion:
            - Reinforce the vanilla armies with some of our own.
            - Force an attack on the city with invasion AI, and release it 5 turns later if it's still locked
        - Finish:
            - Before invasion:
                - If the major clan is killed.
            - Once everything is spawned and freed, finish the disaster.

]]


-- Status list for this disaster.
local STATUS_TRIGGERED = 1;
local STATUS_FULL_INVASION = 2;

-- Object representing the disaster.
disaster_skaven_incursions = {
    name = "skaven_incursions",

    -- Values for categorizing the disaster.
    is_global = true;
    allowed_for_sc = {},
    denied_for_sc = { "wh2_main_sc_skv_skaven" },
    campaigns = {                       -- Campaigns this disaster works on.
        "main_warhammer",
    },

    -- Settings of the disaster that will be stored in a save.
    settings = {},
    default_settings = {

        -- Common data for all disasters.
        enabled = true,                     -- If the disaster is enabled or not.
        started = false,                    -- If the disaster has been started.
        finished = false,                   -- If the disaster has been finished.
        repeteable = true,                  -- If the disaster can be repeated.
        is_endgame = false,                 -- If the disaster is an endgame.
        min_turn = 30,                      -- Minimum turn required for the disaster to trigger.
        max_turn = 0,                       -- If the disaster hasn't trigger at this turn, we try to trigger it. Set to 0 to not check for max turn. Used only for some disasters.
        status = 0,                         -- Current status of the disaster. Used to re-initialize the disaster correctly on reload.
        last_triggered_turn = 0,            -- Turn when the disaster was last triggerd.
        last_finished_turn = 0,             -- Turn when the disaster was last finished.
        wait_turns_between_repeats = 0,     -- If repeteable, how many turns will need to pass after finished for the disaster to be available again.
        difficulty_mod = 1.5,               -- Difficulty multiplier used by the disaster (effects depend on the disaster).

        -- Disaster-specific data.
        base_army_unit_count = 19,
        invasion_over_delay = 5,

        repeat_regions = {},
        faction = "",

        -- List of skaven factions that will participate in the uprising.
        factions = {

            -- Major factions
            "wh2_main_skv_clan_mors",           -- Clan Mors (Queek)
            "wh2_main_skv_clan_pestilens",      -- Clan Pestilens (Skrolk)
            "wh2_dlc09_skv_clan_rictus",        -- Clan Rictus (Tretch)
            "wh2_main_skv_clan_skryre",         -- Clan Skryre (Ikit Claw)
            "wh2_main_skv_clan_eshin",          -- Clan Eshin (Snikch)
            "wh2_main_skv_clan_moulder",        -- Clan Moulder (Throt)
        },
    },

    army_templates = {

        -- Major factions use faction-specific templates
        wh2_main_skv_clan_mors = { skaven = "lategame_mors" },
        wh2_main_skv_clan_pestilens = { skaven = "lategame_pestilens" },
        wh2_dlc09_skv_clan_rictus = { skaven = "lategame_rictus" },
        wh2_main_skv_clan_skryre = { skaven = "lategame_skryre" },
        wh2_main_skv_clan_eshin = { skaven = "lategame_eshin" },
        wh2_main_skv_clan_moulder = { skaven = "lategame_moulder" },
    },

    warning_event_key = "wh3_main_ie_incident_endgame_vermintide_1",
    warning_effect_key = "dyn_dis_vermintide_early_warning",
    finish_before_stage_1_event_key = "dyn_dis_vermintide_finish_before_stage_1",
    attacker_buffs_key = "dyn_dis_vermintide_attacker_buffs",

    inital_expansion_chance = 39,   -- Chance for each region to get an under empire expansion each turn
    repeat_expansion_chance = 13,   -- Chance for a region to get an under empire if it didn't get one on the first dice roll
    unique_building_chance = 25,    -- Chance for a region to get one of the special faction-unique under empire templates
    max_regions_expanded = 15,      -- Max amount of regions we'll expand the underempire before swapping to rat kings.
    under_empire_buildings = {
        generic = {
            {
                "wh2_dlc12_under_empire_annexation_war_camp_1",
                "wh2_dlc12_under_empire_money_crafting_2",
                "wh2_dlc12_under_empire_food_kidnappers_2",
                "wh2_dlc12_under_empire_food_raiding_camp_1"
            },
            {
                "wh2_dlc12_under_empire_settlement_stronghold_3",
            },
            {
                "wh2_dlc12_under_empire_settlement_stronghold_4",
                "wh2_dlc12_under_empire_food_raiding_camp_1"
            },
            {
                "wh2_dlc12_under_empire_settlement_stronghold_5",
                "wh2_dlc12_under_empire_food_raiding_camp_1",
                "wh2_dlc12_under_empire_discovery_deeper_tunnels_1"
            },
            {
                "wh2_dlc12_under_empire_settlement_warren_3",
            },
            {
                "wh2_dlc12_under_empire_settlement_warren_4",
                "wh2_dlc12_under_empire_food_raiding_camp_1"
            },
            {
                "wh2_dlc12_under_empire_settlement_warren_5",
                "wh2_dlc12_under_empire_food_raiding_camp_1",
                "wh2_dlc12_under_empire_discovery_deeper_tunnels_1"
            }
        },
        wh2_main_skv_clan_skryre = {
            "wh2_dlc12_under_empire_annexation_doomsday_1",
            "wh2_dlc12_under_empire_money_crafting_2",
            "wh2_dlc12_under_empire_food_kidnappers_2",
            "wh2_dlc12_under_empire_food_raiding_camp_1"
        },
        wh2_main_skv_clan_pestilens = {
            "wh2_dlc14_under_empire_annexation_plague_cauldron_1",
            "wh2_dlc12_under_empire_money_crafting_2",
            "wh2_dlc12_under_empire_food_kidnappers_2",
            "wh2_dlc12_under_empire_food_raiding_camp_1"
        },
    },

    initial_under_empire_placements = {
        wh2_main_skv_clan_mors = {
            "wh3_main_combi_region_karag_orrud",
            "wh3_main_combi_region_karak_zorn",
            "wh3_main_combi_region_galbaraz",
        },
        wh2_main_skv_clan_pestilens = {
            "wh3_main_combi_region_xahutec",
            "wh3_main_combi_region_hualotal",
            "wh3_main_combi_region_hexoatl",
        },
        wh2_dlc09_skv_clan_rictus = {
            "wh3_main_combi_region_karak_azul",
            "wh3_main_combi_region_black_fortress",
            "wh3_main_combi_region_zharr_naggrund",
        },
        wh2_main_skv_clan_skryre = {
            "wh3_main_combi_region_pfeildorf",
            "wh3_main_combi_region_altdorf",
            "wh3_main_combi_region_nuln",
        },
        wh2_main_skv_clan_eshin = {
            "wh3_main_combi_region_nan_gau",
            "wh3_main_combi_region_wei_jin",
            "wh3_main_combi_region_shang_yang",
        },
        wh2_main_skv_clan_moulder = {
            "wh3_main_combi_region_kislev",
            "wh3_main_combi_region_middenheim",
            "wh3_main_combi_region_kraka_drak",
        },
    }
}

-- Function to set the status of the disaster, initializing the needed listeners in the process.
function disaster_skaven_incursions:set_status(status)
    self.settings.status = status;

    -- Trigger can trigger twice here, so make sure we don't have duplicated listeners running.
    if self.settings.status == STATUS_TRIGGERED then

        -- This triggers stage one of the disaster if the disaster hasn't been cancelled.
        core:add_listener(
            "SkavenIncursionsInvasion",
            "WorldStartRound",
            function()
                if cm:turn_number() >= self.settings.last_triggered_turn and #self.settings.repeat_regions >= 15 then
                    return true
                end
                return false;
            end,

            -- If there are skaven alive, proceed with stage 1.
            function()
                if self:check_end_disaster_conditions() == true then
                    dynamic_disasters:trigger_incident(self.finish_before_stage_1_event_key, nil, 0, nil);
                    self:trigger_end_disaster();
                else
                    self:trigger_invasion();
                end
                core:remove_listener("SkavenIncursionsInvasion")
            end,
            true
        );
    end

    -- Listener to keep retriggering the Under-Empire expansion each turn, as long as the disaster lasts.
    core:remove_listener("VermintideUnderEmpireExpansion");
    core:add_listener(
        "VermintideUnderEmpireExpansion",
        "WorldStartRound",
        function()
            return self.settings.started == true and self.settings.status == STATUS_TRIGGERED;
        end,
        function()
            self:expand_under_empire()
        end,
        true
    )

    -- No need to have a specific listener to end the disaster after no more stages can be triggered, as that's controlled by a mission.
end

-- Function to trigger the disaster.
function disaster_skaven_incursions:trigger()
    out("Frodo45127: Starting disaster: " .. self.name);

    -- Setup strategic under-cities for all factions available, including the recently resurrected ones.
    out("Frodo45127: Setting up initial underempire base for faction " .. self.settings.faction .. ".");
    if self.initial_under_empire_placements[self.settings.faction] ~= nil then
        for _, region_key in pairs(self.initial_under_empire_placements[self.settings.faction]) do

            out("Frodo45127: Setting up initial underempire for faction " .. self.settings.faction .. ", region " .. region_key .. ".");
            local region = cm:get_region(region_key);
            self:expand_under_empire_adjacent_region_check(self.settings.faction, region, {}, true, true, true)
        end
    end

    -- Initialize listeners.
    dynamic_disasters:trigger_incident(self.warning_event_key, self.warning_event_key, 0, nil);
    self:set_status(STATUS_TRIGGERED);
end

-- Function to trigger the first stage of the Vermintide.
function disaster_skaven_incursions:trigger_invasion()

    -- Spawn a few Skryre armies in Estalia, Tilea and Sartosa. Enough so they're able to expand next.
    local current_turn = cm:turn_number();
    local army_count_base = 1
    if current_turn < 50 then
        army_count_base = 1;
    elseif current_turn >= 50 and current_turn < 100 then
        army_count_base = 1.5;
    elseif current_turn >= 100 then
        army_count_base = 2;
    end

    local army_count = math.floor(army_count_base * self.settings.difficulty_mod)

    for _, region_key in pairs(self.settings.repeat_regions) do
        dynamic_disasters:create_scenario_force(self.settings.faction, region_key, self.army_templates[self.settings.faction], self.settings.base_army_unit_count, false, army_count, self.name, nil)
    end

    -- Setup strategic under-cities for all factions available, including the recently resurrected ones.
    for _, faction_key in pairs(self.settings.factions) do
        if self.settings.repeat_regions[faction_key] == nil then
            self.settings.repeat_regions[faction_key] = {}
        end

        out("Frodo45127: Setting up initial underempire for faction " .. faction_key .. ".");
        if self.initial_under_empire_placements[faction_key] ~= nil then

            -- Only spawn new armies here for dead main factions.
            if cm:get_faction(faction_key):is_dead() == true then
                dynamic_disasters:create_scenario_force(faction_key, "wh3_main_combi_region_skavenblight", self.army_templates[faction_key], self.settings.base_army_unit_count, false, army_count, self.name, nil)
            end

            for _, region_key in pairs(self.initial_under_empire_placements[faction_key]) do

                out("Frodo45127: Setting up initial underempire for faction " .. faction_key .. ", region " .. region_key .. ".");
                local region = cm:get_region(region_key);
                self:expand_under_empire_adjacent_region_check(faction_key, region, {}, true, true, true)
            end
        end
    end

    -- Prepare the regions to reveal.
    dynamic_disasters:prepare_reveal_regions(self.settings.repeat_regions);

    -- Trigger all the stuff related to the invasion (missions, effects,...).
    self:set_status(STATUS_FULL_INVASION);
end

-------------------------------------------
-- Underempire expansion logic
-------------------------------------------

-- This function expands the underempire when called, if expansion is still possible.
function disaster_skaven_incursions:expand_under_empire()
    local potential_skaven = {}
    for _, faction_key in pairs(self.settings.factions) do
        local faction = cm:get_faction(faction_key)
        if endgame:check_faction_is_valid(faction, false) then
            table.insert(potential_skaven, faction_key)
        end
    end

    -- Update the potential factions removing the confederated ones.
    self.settings.factions = dynamic_disasters:remove_confederated_factions_from_list(self.settings.factions);
    for i = 1, #self.settings.factions do

        -- We're only interested in expanding the underempire for factions that are actually alive.
        -- NOTE: Make sure the ones we want each stage to expand are alive.
        local faction_key = self.settings.factions[i];
        local faction = cm:get_faction(faction_key);
        if not faction == false and faction:is_null_interface() == false and faction:is_dead() == false then

            local checked_regions = {}

            if self.settings.repeat_regions[faction_key] == nil then
                self.settings.repeat_regions[faction_key] = {}
            end

            -- Try to expand to regions bordering the current underempire.
            local foreign_region_list = faction:foreign_slot_managers()
            for i2 = 0, foreign_region_list:num_items() -1 do
                local region = foreign_region_list:item_at(i2):region()
                self:expand_under_empire_adjacent_region_check(faction_key, region, checked_regions, false)
            end

            -- Try to expand to regions bordering the current surface empire.
            local region_list = faction:region_list()
            for i2 = 0, region_list:num_items() -1 do
                local region = region_list:item_at(i2)
                self:expand_under_empire_adjacent_region_check(faction_key, region, checked_regions, false)
            end
        end
    end
end

-- This function expands the underempire for the provided faction, using the provided region as source region to expand from.
function disaster_skaven_incursions:expand_under_empire_adjacent_region_check(sneaky_skaven, region, checked_regions, force_unique_setup, ignore_rolls, apply_to_current_region)
    local adjacent_region_list = region:adjacent_region_list()
    for i = 0, adjacent_region_list:num_items() -1 do
        local adjacent_region = adjacent_region_list:item_at(i)
        local adjacent_region_key = adjacent_region:name()

        if apply_to_current_region == true then
            adjacent_region = region;
            adjacent_region_key = region:name();
        end

        -- To reduce iterations, we only process regions that have not be processed yet this turn.
        if checked_regions[adjacent_region_key] == nil then
            checked_regions[adjacent_region_key] = true

            -- Expand with higher chance on the first expansion, the reduce the expansion chance.
            if not adjacent_region == false and adjacent_region:is_null_interface() == false then
                local chance = self.repeat_expansion_chance
                if self.settings.repeat_regions[sneaky_skaven][adjacent_region_key] == nil then
                    self.settings.repeat_regions[sneaky_skaven][adjacent_region_key] = true
                    chance = self.inital_expansion_chance
                end
                local dice_roll = cm:random_number(100, 1)
                if (dice_roll <= chance or ignore_rolls == true) then
                    out("Frodo45127: Spreading under-empire to " .. adjacent_region_key .. " for " .. sneaky_skaven)

                    -- If the region is abandoned, do not use underempire. Take the region directly.
                    if adjacent_region:is_abandoned() then
                        cm:transfer_region_to_faction(adjacent_region_key, sneaky_skaven)

                    -- Only expand to regions not owned by the same faction and with not an undercity already there.
                    elseif adjacent_region:owning_faction():name() ~= sneaky_skaven then
                        local is_sneaky_skaven_present = false
                        local foreign_slot_managers = adjacent_region:foreign_slot_managers()
                        for i2 = 0, foreign_slot_managers:num_items() -1 do
                            local foreign_slot_manager = foreign_slot_managers:item_at(i2)
                            if foreign_slot_manager:faction():name() == sneaky_skaven then
                                is_sneaky_skaven_present = true
                                break
                            end
                        end

                        if is_sneaky_skaven_present == false then

                            -- Pick the underempire setup at random.
                            local under_empire_buildings
                            if self.under_empire_buildings[sneaky_skaven] ~= nil and (cm:random_number(100, 1) <= self.unique_building_chance or force_unique_setup == true) then
                                under_empire_buildings = self.under_empire_buildings[sneaky_skaven]
                            else
                                local random_index = cm:random_number(#self.under_empire_buildings.generic, 1)
                                under_empire_buildings = self.under_empire_buildings.generic[random_index]
                            end

                            local region_cqi = adjacent_region:cqi()
                            local faction_cqi = cm:get_faction(sneaky_skaven):command_queue_index()
                            foreign_slot = cm:add_foreign_slot_set_to_region_for_faction(faction_cqi, region_cqi, "wh2_dlc12_slot_set_underempire")

                            -- Add the buildings to the underempire.
                            for i3 = 1, #under_empire_buildings do
                                local building_key = under_empire_buildings[i3]
                                slot = foreign_slot:slots():item_at(i3-1)
                                cm:foreign_slot_instantly_upgrade_building(slot, building_key)
                                out("Frodo45127: Added " .. building_key .. " to " .. adjacent_region:name() .. " for " .. sneaky_skaven)
                            end
                        end
                    end
                end
            end
        end
    end
end

-------------------------------------------
-- Underempire expansion logic end
-------------------------------------------

-- Function to trigger cleanup stuff after the invasion is over.
function disaster_skaven_incursions:trigger_end_disaster()
    if self.settings.started == true then
        out("Frodo45127: Disaster: " .. self.name .. ". Triggering end invasion.");

        self.settings.repeat_regions = {};
        self.settings.faction = "";

        dynamic_disasters:finish_disaster(self);
    end
end

--- Function to check if the disaster custom conditions are valid and can be trigger.
---@return boolean If the disaster will be triggered or not.
function disaster_skaven_incursions:check_start_disaster_conditions()

    -- Update the potential factions removing the confederated ones.
    self.settings.factions = dynamic_disasters:remove_confederated_factions_from_list(self.settings.factions);

    -- Do not start if we don't have attackers for stage 1.
    if #self.settings.factions == 0 then
        return false;
    end

    -- Check that Clan Skryre is alive or dead and non-confederated. It's needed to kickstart the disaster.
    cm:random_sort(self.settings.factions);
    for _, faction_key in pairs(self.settings.factions) do
        local faction = cm:get_faction(faction_key);
        if not faction == false and faction:is_null_interface() == false and faction:is_dead() == false then
            self.settings.faction = faction:name();
            break
        end
    end

    -- Do not start if we don't have a faction.
    if self.settings.faction == "" then
        return false;
    end

    -- Debug mode support.
    if dynamic_disasters.settings.debug_2 == true then
        return true;
    end

    local base_chance = 0.02;
    for _, faction_key in pairs(self.settings.factions) do
        local faction = cm:get_faction(faction_key);
        if not faction == false and faction:is_null_interface() == false and faction:is_dead() then
            base_chance = base_chance + 0.01;
        end
    end

    -- If the vermintide has been triggered, do not start this.
    for _, disaster in pairs(dynamic_disasters.disasters) do
        if disaster.name == "the_vermintide" and disaster.settings.started == true and disaster.settings.finished == false then
            return false;
        end
    end

    if cm:random_number(1, 0) < base_chance then
        return true;
    end

    return false;
end

return disaster_skaven_incursions
