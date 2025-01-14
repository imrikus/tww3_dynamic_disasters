--[[
    The Wild Hunt, By CA. Extended by Frodo45127

    Disaster ported from the endgames disasters. Wood Elfs go full retard. Extended functionality and fixes added.

    Classified as Endgame, can trigger final mission. Supports debug mode.

    Requirements:
        - Random chance: 0.5% (1/200 turns).
        - +0.5% for each Wood Elf faction that has been wiped out (not confederated).
        - At least turn 100 (so the player has already "prepared").
    Effects:
        - Trigger/Early Warning:
            - "The end is nigh" message
        - Invasion:
            - All major and minor non-confederated Wood Elfs factions declare war on every non Wood Elf faction.
            - All major and minor non-confederated Wood Elfs factions gets disabled diplomacy and full-retard AI.
            - If no other disaster has triggered a Victory Condition yet, this will trigger one.
            - Every ceil(10 / (difficulty_mod + 1)) turns spawn an extra army in each magical forest controlled by wood elves.
        - Finish:
            - A certain amount of Sacred Forest regions controled, or all Wood Elfs factions destroyed.

    Ideas:
        - Add The enchanted forest, Gaen Vale and the Sacred Pools to make this disaster more world-wide.

]]

-- Status list for this disaster.
local STATUS_TRIGGERED = 1;
local STATUS_STARTED = 2;

disaster_wild_hunt = {
	name = "wild_hunt",

    -- Values for categorizing the disaster.
    is_global = true;
    allowed_for_sc = {},
    denied_for_sc = { "wh_dlc05_sc_wef_wood_elves" },
    campaigns = {                       -- Campaigns this disaster works on.
        "main_warhammer",
    },

    -- If the disaster is an endgame scenario, define here the objectives to pass to the function that creates the victory condition.
    objectives = {
        {
            type = "DESTROY_FACTION",
            conditions = {
                "confederation_valid",
                "vassalization_valid"
            },
            payloads = {
                "money 50000"
            }
        },
        {
            type = "CONTROL_N_REGIONS_FROM",
            conditions = {
                "override_text mission_text_text_mis_activity_control_n_regions_satrapy_including_at_least_n"
            },
            payloads = {
                "money 25000"
            }
        },
    },

    -- Settings of the disaster that will be stored in a save.
    settings = {},
    default_settings = {
        enabled = true,                     -- If the disaster is enabled or not.
        started = false,                    -- If the disaster has been started.
        finished = false,                   -- If the disaster has been finished.
        repeteable = false,                 -- If the disaster can be repeated.
        is_endgame = true,                  -- If the disaster is an endgame.
        revive_dead_factions = true,        -- If true, dead factions will be revived if needed.
        enable_diplomacy = false,           -- If true, you will still be able to use diplomacy with disaster-related factions. Broken beyond believe, can make the game a cakewalk.
        min_turn = 100,                     -- Minimum turn required for the disaster to trigger.
        max_turn = 0,                       -- If the disaster hasn't trigger at this turn, we try to trigger it. Set to 0 to not check for max turn. Used only for some disasters.
        status = 0,                         -- Current status of the disaster. Used to re-initialize the disaster correctly on reload.
        last_triggered_turn = 0,            -- Turn when the disaster was last triggerd.
        last_finished_turn = 0,             -- Turn when the disaster was last finished.
        wait_turns_between_repeats = 0,     -- If repeteable, how many turns will need to pass after finished for the disaster to be available again.
        difficulty_mod = 1.5,               -- Difficulty multiplier used by the disaster (effects depend on the disaster).
        mct_settings = {},                  -- Extra settings this disaster may pull from MCT.
        early_warning_delay = 10,

        factions = {
            "wh_dlc05_wef_wood_elves",
            "wh_dlc05_wef_wydrioth",
            "wh3_main_wef_laurelorn",
            "wh_dlc05_wef_torgovann",
            "wh2_main_wef_bowmen_of_oreon",
            "wh_dlc05_wef_argwylon",
            "wh2_dlc16_wef_drycha",
            "wh2_dlc16_wef_sisters_of_twilight",

            -- Not in the vanilla disaster.
            "wh3_dlc21_wef_spirits_of_shanlin",
        },

		regions = {},
	},

    unit_count = 19,
    army_count_per_province = 4,
    army_template = {
        wood_elves = "lategame"
    },

    factions_base_regions = {
        wh_dlc05_wef_wood_elves = "wh3_main_combi_region_kings_glade",
        wh_dlc05_wef_wydrioth = "wh3_main_combi_region_crag_halls_of_findol",
        wh3_main_wef_laurelorn = "wh3_main_combi_region_laurelorn_forest",
        wh_dlc05_wef_torgovann = "wh3_main_combi_region_vauls_anvil_loren",
        wh2_main_wef_bowmen_of_oreon = "wh3_main_combi_region_oreons_camp",
        wh_dlc05_wef_argwylon = "wh3_main_combi_region_waterfall_palace",
        wh2_dlc16_wef_drycha = "wh3_main_combi_region_gryphon_wood",
        wh2_dlc16_wef_sisters_of_twilight = "wh3_main_combi_region_the_witchwood",

        -- Not in the vanilla disaster.
        wh3_dlc21_wef_spirits_of_shanlin = "wh3_main_combi_region_jungles_of_chian",
    },

    magical_forests = {
        "wh3_main_combi_region_the_oak_of_ages",
        "wh3_main_combi_region_the_sacred_pools",
        "wh3_main_combi_region_gaean_vale",
        "wh3_main_combi_region_gryphon_wood",
        "wh3_main_combi_region_oreons_camp",
        "wh3_main_combi_region_jungles_of_chian",
        "wh3_main_combi_region_laurelorn_forest",
        "wh3_main_combi_region_the_witchwood",
        "wh3_main_combi_region_the_haunted_forest",
        "wh3_main_combi_region_forest_of_gloom",
    },

    oak_of_ages_region_key = "wh3_main_combi_region_the_oak_of_ages",
    subculture = "wh_dlc05_sc_wef_wood_elves",

    early_warning_incident_key = "wh3_main_ie_incident_endgame_wild_hunt_early_warning",
    early_warning_effects_key = "dyn_dis_wild_hunt_early_warning",
    invasion_incident_key = "wh3_main_ie_incident_endgame_wild_hunt",
    endgame_mission_name = "and_so_the_wild_hunt_begun",
    invader_buffs_effects_key = "wh3_main_ie_scripted_endgame_wild_hunt",
    finish_early_incident_key = "dyn_dis_wild_hunt_early_end",
    ai_personality = "wh3_combi_woodelf_endgame",
}

--[[-------------------------------------------------------------------------------------------------------------

    Mandatory functions.

]]---------------------------------------------------------------------------------------------------------------

-- Function to set the status of the disaster, initializing the needed listeners in the process.
function disaster_wild_hunt:set_status(status)
    self.settings.status = status;

    if self.settings.status == STATUS_TRIGGERED then

        -- Listener for the disaster.
        core:remove_listener("TheWildHuntStart")
        core:add_listener(
            "TheWildHuntStart",
            "WorldStartRound",
            function()
                return cm:turn_number() == self.settings.last_triggered_turn + self.settings.early_warning_delay
            end,
            function()
                if self:check_finish() then
                    dynamic_disasters:trigger_incident(self.finish_early_incident_key, nil, 0, nil, nil, nil);
                    self:finish()
                else
                    self:trigger_the_wild_hunt();
                end
                core:remove_listener("TheWildHuntStart")
            end,
            true
        );
    end

    if self.settings.status == STATUS_STARTED then

        -- Listener to keep spawning armies every (10 / (difficulty_mod + 1)) turns, one army on each wood elf controlled magical forest.
        core:remove_listener("TheWildHuntRespawn")
        core:add_listener(
            "TheWildHuntRespawn",
            "WorldStartRound",
            function()
                return cm:turn_number() % math.ceil(10 / (self.settings.difficulty_mod + 1)) == 0 and
                    dynamic_disasters:is_any_faction_alive_from_list_with_home_region(self.settings.factions);
            end,
            function()
                for _, region_key in pairs(self.magical_forests) do
                    local region = cm:get_region(region_key);
                    if not region == false and region:is_null_interface() == false and region:is_abandoned() == false then
                        local owner = region:owning_faction();
                        if not owner == false and owner:is_null_interface() == false and owner:subculture() == self.subculture then
                            dynamic_disasters:create_scenario_force(owner:name(), region_key, self.settings.army_template, self.unit_count, false, 1, self.name, nil)
                        end
                    end
                end
            end,
            true
        )
    end

    -- Once we triggered the disaster, ending it is controlled by two missions, so we don't need to listen for an ending.
end

-- Function to trigger the early warning before the disaster.
function disaster_wild_hunt:start()

    -- Debug mode support.
    if dynamic_disasters.settings.debug_2 == true then
        self.settings.early_warning_delay = 1;
    else
        self.settings.early_warning_delay = cm:random_number(12, 8);
    end

    dynamic_disasters:trigger_incident(self.early_warning_incident_key, self.early_warning_effects_key, self.settings.early_warning_delay, nil, nil, nil);
    self:set_status(STATUS_TRIGGERED);
end

-- Function to trigger cleanup stuff after the invasion is over.
function disaster_wild_hunt:finish()
    if self.settings.started == true then
        out("Frodo45127: Disaster: " .. self.name .. ". Triggering end invasion.");
        core:remove_listener("TheWildHuntRespawn")
        dynamic_disasters:finish_disaster(self);
    end
end

--- Function to check if the disaster custom conditions are valid and can be trigger.
---@return boolean If the disaster will be triggered or not.
function disaster_wild_hunt:check_start()

    -- Update the potential factions removing the confederated ones.
    self.settings.factions = dynamic_disasters:remove_confederated_factions_from_list(self.settings.factions);

    -- Do not start if we don't have attackers.
    if #self.settings.factions == 0 then
        return false;
    end

    -- Do not start if we don't have any alive attackers.
    if not dynamic_disasters:is_any_faction_alive_from_list(self.settings.factions) then
        return false;
    end

    -- Debug mode support.
    if dynamic_disasters.settings.debug_2 == true then
        return true;
    end

    -- If we're at max turn, trigger it without checking chances.
    if self.settings.max_turn > 0 and cm:turn_number() == self.settings.max_turn then
        return true;
    end

    local base_chance = 0.005;
    for _, faction_key in pairs(self.settings.factions) do
        local faction = cm:get_faction(faction_key);
        if not faction == false and faction:is_null_interface() == false and faction:is_dead() then
            base_chance = base_chance + 0.005;
        end
    end

    if cm:random_number(100, 0) / 100 < base_chance then
        return true;
    end

    return false;
end

--- Function to check if the conditions to declare the disaster as "finished" are fulfilled.
---@return boolean If the disaster will be finished or not.
function disaster_wild_hunt:check_finish()

    -- Update the potential factions removing the confederated ones and check if we still have factions to use.
    self.settings.factions = dynamic_disasters:remove_confederated_factions_from_list(self.settings.factions);
    return #self.settings.factions == 0 or not dynamic_disasters:is_any_faction_alive_from_list(self.settings.factions);
end

--[[-------------------------------------------------------------------------------------------------------------

    Disaster-specific functions.

]]---------------------------------------------------------------------------------------------------------------

-- Function to trigger the invasion itself.
function disaster_wild_hunt:trigger_the_wild_hunt()

    for _, faction_key in pairs(self.settings.factions) do
        local invasion_faction = cm:get_faction(faction_key)

        if not invasion_faction:is_dead() or (invasion_faction:is_dead() and self.settings.revive_dead_factions == true) then
            local region_key = self.factions_base_regions[faction_key];
            local army_count = math.floor(self.army_count_per_province * self.settings.difficulty_mod);
            if dynamic_disasters:create_scenario_force_with_backup_plan(faction_key, region_key, self.army_template, self.unit_count, false, army_count, self.name, nil, self.settings.factions) then

                -- First, declare war on the player, or we may end up in a locked turn due to mutual alliances. But do it after resurrecting them or we may break their war declarations!
                dynamic_disasters:no_peace_no_confederation_only_war(faction_key, self.settings.enable_diplomacy)

                -- In the case of the main Wood Elf faction, also spawn armies in the Oak of Ages if it owns it.
                if faction_key == "wh_dlc05_wef_wood_elves" then
                    local oak_of_ages_region = cm:get_region(self.oak_of_ages_region_key);
                    if not oak_of_ages_region == false and oak_of_ages_region:is_null_interface() == false then
                        local owning_faction = oak_of_ages_region:owning_faction();
                        if not owning_faction == false and owning_faction:is_null_interface() == false and owning_faction:name() == faction_key then
                            if dynamic_disasters:create_scenario_force_with_backup_plan(faction_key, self.oak_of_ages_region_key, self.army_template, self.unit_count, false, army_count, self.name, nil, self.settings.factions) then
                                table.insert(self.settings.regions, self.oak_of_ages_region_key);
                            end
                        end
                    end
                end

                -- Give the invasion region to the invader if it isn't owned by them or a human
                local region = cm:get_region(region_key)
                if not region == false and region:is_null_interface() == false then
                    local region_owner = region:owning_faction()
                    if region:is_abandoned() or region_owner == false or region_owner:is_null_interface() or (region_owner:name() ~= faction_key and region_owner:is_human() == false and region_owner:subculture() ~= self.subculture) then
                        cm:transfer_region_to_faction(region_key, faction_key)
                    end
                end

                -- Change their AI so it becomes aggressive, while declaring war to everyone and their mother.
                cm:force_change_cai_faction_personality(faction_key, self.ai_personality)
                cm:instantly_research_all_technologies(faction_key);
                dynamic_disasters:declare_war_to_all(invasion_faction, { self.subculture }, true);

                cm:apply_effect_bundle(self.invader_buffs_effects_key, faction_key, 0)
                table.insert(self.settings.regions, region_key);
            end
        end
    end

    -- Force an alliance between all Wood Elfs factions.
    dynamic_disasters:force_peace_between_factions(self.settings.factions, true);

    -- If we got regions, prepare the victory mission/disaster end data.
    table.insert(self.objectives[2].conditions, "total " .. math.ceil(#self.settings.regions * 0.65))
    for i = 1, #self.settings.regions do
        table.insert(self.objectives[2].conditions, "region " .. self.settings.regions[i])
    end
    for i = 1, #self.settings.factions do
        table.insert(self.objectives[1].conditions, "faction " .. self.settings.factions[i])
    end

    -- Trigger either the victory mission, or just the related incident.
    dynamic_disasters:add_mission(self.objectives, true, self.name, self.endgame_mission_name, self.invasion_incident_key, self.settings.regions[1], self.settings.factions[1], function () self:finish() end, false)
    cm:activate_music_trigger("ScriptedEvent_Negative", self.subculture)
    self:set_status(STATUS_STARTED);
end

return disaster_wild_hunt
