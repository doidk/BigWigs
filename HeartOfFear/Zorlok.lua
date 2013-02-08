
--------------------------------------------------------------------------------
-- Module Declaration
--

local mod, CL = BigWigs:NewBoss("Imperial Vizier Zor'lok", 897, 745)
if not mod then return end
mod:RegisterEnableMob(62980)

--------------------------------------------------------------------------------
-- Locals
--

local forceCount, platform, danceTracker = 0, 0, true

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:NewLocale("enUS", true)
if L then
	L.engage_yell = "The Divine chose us to give mortal voice to Her divine will. We are but the vessel that enacts Her will."

	L.force, L.force_desc = EJ_GetSectionInfo(6427)
	L.force_icon = 122713
	L.force_message = "AoE Pulse"

	L.attenuation = EJ_GetSectionInfo(6426) .. " (Discs)"
	L.attenuation_desc = select(2, EJ_GetSectionInfo(6426))
	L.attenuation_icon = 127834
	L.attenuation_bar = "Discs... Dance!"
	L.attenuation_message = "%s Dancing %s"
	L.echo = "|c001cc986Echo|r"
	L.zorlok = "|c00ed1ffaZor'lok|r"
	L.left = "|c00008000<- Left <-|r"
	L.right = "|c00FF0000-> Right ->|r"

	L.platform_emote = "platforms" -- Imperial Vizier Zor'lok flies to one of his platforms!
	L.platform_emote_final = "inhales"-- Imperial Vizier Zor'lok inhales the Pheromones of Zeal!
	L.platform_message = "Swapping Platform"
end
L = mod:GetLocale()
L.force = L.force .." (".. L.force_message ..")"

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		{"attenuation", "FLASH"}, {"force", "FLASH"}, 122740, {122761, "ICON"},
		"stages", "berserk", "bosskill",
	}
end

function mod:OnBossEnable()
	self:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "PreForceAndVerse", "boss1")
	self:Log("SPELL_CAST_START", "Attenuation", 122496, 122497, 122474, 122479, 123721, 123722)
	self:Log("SPELL_AURA_APPLIED", "Convert", 122740)
	self:Log("SPELL_AURA_APPLIED", "Exhale", 122761)
	self:Log("SPELL_AURA_REMOVED", "ExhaleOver", 122761)
	self:Log("SPELL_CAST_START", "ForceAndVerse", 122713)

	self:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT", "CheckBossStatus")

	self:Emote("PlatformSwap", L["platform_emote"], L["platform_emote_final"])

	self:Death("Win", 62980)
end

function mod:OnEngage()
	self:RegisterUnitEvent("UNIT_HEALTH_FREQUENT", nil, "boss1")
	forceCount, platform, danceTracker = 0, 0, true
	self:Berserk(self:Heroic() and 720 or 600) -- Verify
end

--------------------------------------------------------------------------------
-- Event Handlers
--

do
	local convertList, scheduled = mod:NewTargetList(), nil
	local function convert(spellId)
		mod:TargetMessage(spellId, spellId, convertList, "Attention", spellId)
		scheduled = nil
	end
	function mod:Convert(args)
		self:Bar(args.spellId, "~"..args.spellName, 36, args.spellId)
		convertList[#convertList + 1] = args.destName
		if not scheduled then
			scheduled = self:ScheduleTimer(convert, 0.1, args.spellId)
		end
	end
end

function mod:Attenuation(args)
	local target = danceTracker and L["zorlok"] or L["echo"]
	if args.spellId == 122497 or args.spellId == 122479 or args.spellId == 123722 then -- right
		self:Message("attenuation", L["attenuation_message"]:format(target, L["right"]), "Urgent", "misc_arrowright", "Alarm")
	elseif args.spellId == 122496 or args.spellId == 122474 or args.spellId == 123721 then -- left
		self:Message("attenuation", L["attenuation_message"]:format(target, L["left"]), "Attention", "misc_arrowleft", "Alert")
	end
	self:Bar("attenuation", L["attenuation_bar"], 14, args.spellId)
	self:Flash("attenuation")

	if platform == 3 and self:Heroic() and forceCount > 0 then
		danceTracker = not danceTracker
	end
end

function mod:PreForceAndVerse(_, _, _, _, spellId)
	if spellId == 122933 then -- Clear Throat
		self:Message("force", CL["soon"]:format(L["force_message"]), "Important", L.force_icon, "Long")
	end
end

function mod:ForceAndVerse(args)
	forceCount = forceCount + 1
	self:Message("force", ("%s (%d)"):format(L["force_message"], forceCount), "Urgent", args.spellId)
	self:Bar("force", CL["cast"]:format(L["force_message"]), 12, args.spellId)
	self:Flash("force")
end

function mod:UNIT_HEALTH_FREQUENT(unitId)
	local hp = UnitHealth(unitId) / UnitHealthMax(unitId) * 100
	if platform == 0 and hp < 83 then
		self:Message("stages", CL["soon"]:format(L["platform_message"]), "Positive", "ability_vehicle_launchplayer", "Info")
		platform = 1
	elseif platform == 1 and hp < 63 then
		self:Message("stages", CL["soon"]:format(L["platform_message"]), "Positive", "ability_vehicle_launchplayer", "Info")
		platform = 2
	elseif platform == 2 and ((self:Heroic() and hp < 47) or hp < 43) then
		self:Message("stages", CL["soon"]:format(CL["phase"]:format(2)), "Positive", "ability_vehicle_launchplayer", "Info")
		self:UnregisterUnitEvent("UNIT_HEALTH_FREQUENT", unitId)
		platform = 3
	end
end

function mod:Exhale(args)
	self:TargetMessage(args.spellId, args.spellName, args.destName, "Important", args.spellId)
	self:TargetBar(args.spellId, args.spellName, args.destName, 6, args.spellId)
	self:PrimaryIcon(args.spellId, args.destName)
end

function mod:ExhaleOver(args)
	self:PrimaryIcon(args.spellId)
end

function mod:PlatformSwap()
	forceCount = 0
	if platform == 2 then
		danceTracker = false
	end
	if platform == 3 then
		self:Message("stages", CL["phase"]:format(2), "Positive", "ability_vehicle_launchplayer", "Info")
		self:StopBar("~"..self:SpellName(122740)) -- Convert
		danceTracker = true
	else
		self:Message("stages", L["platform_message"], "Positive", "ability_vehicle_launchplayer", "Info")
	end
end

