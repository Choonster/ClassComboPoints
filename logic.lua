local ADDON, ClassComboPoints = ...

---------------
-- Constants --
---------------
local CLASS, MAX_COMBO_POINTS = ClassComboPoints.CLASS, ClassComboPoints.MAX_COMBO_POINTS

-- Classes that use combo points in one or more specs
local COMBO_CLASSES = { ROGUE = true, DRUID = true }

-- classIDs and specIDs that use combo points.
local COMBO_SPECS = { 
	ROGUE = true, -- Rogue - All Specs
	[103] = true, -- Druid - Feral
}

-- Classes that use a power mechanic (UnitPower/UnitPowerMax) in one or more specs that acts in a similar fashion to combo points (e.g. Warlock Soul Shards)
local POWER_CLASSES = { WARLOCK = true, PALADIN = true, MONK = true, PRIEST = true }

-- A mapping of classIDs and specIDs to their powerType
local POWER_TYPES = {
	MONK = SPELL_POWER_CHI,				-- Monk - All Specs - Chi
	PALADIN = SPELL_POWER_HOLY_POWER,	-- Paladin - All Specs - Holy Power
	[265] = SPELL_POWER_SOUL_SHARDS,	-- Warlock - Affliction - Soul Shards
	[267] = SPELL_POWER_BURNING_EMBERS,	-- Warlock - Destruction - Burning Embers
	[258] = SPELL_POWER_SHADOW_ORBS,	-- Priest - Shadow - Shadow Orbs
}

------------
-- Events --
------------
local bar = ClassComboPoints.bar

local CallbackHandler = LibStub("CallbackHandler-1.0")

-- We use CallbackHandler to handle event callbacks (like AceEvent does) so each "module" (combo points, power, etc.) can register its own callback for each event
-- We don't use AceEvent because there are several events we want to use RegisterUnitEvent for (which AceEvent doesn't support since it's a shared library)

-- Normal event callbacks
local events = {}
events.registry = CallbackHandler:New(events, "RegisterEvent", "UnregisterEvent", "UnregisterAllEvents")
events.used = {}

-- Post event callbacks (fired after normal callbacks)
local postEvents = {}
postEvents.registry = CallbackHandler:New(postEvents, "RegisterEvent", "UnregisterEvent", "UnregisterAllEvents")
postEvents.used = {}

local frame = CreateFrame("Frame")
frame:SetScript("OnEvent", function(self, event, ...)
	events.registry:Fire(event, ...)
	postEvents.registry:Fire(event, ...)
end)

-- Like CallbackHandler's RegisterEvent, but calls RegisterUnitEvent on the frame first (after unregistering the event)
function events:RegisterUnitEvent(event, unit1, unit2, method, ...)
	frame:UnregisterEvent(event)
	frame:RegisterUnitEvent(event, unit1, unit2)
	events.RegisterEvent(self, event, method, ...) -- self may not be events
end

function events.registry:OnUsed(target, event)
	target.used[event] = true
	
	if not frame:IsEventRegistered() then
		frame:RegisterEvent(event)
	end
end

function events.registry:OnUnused(target, event)
	target.used[event] = false

	if not events.used[event] and not postEvents.used[event] then
		frame:UnregisterEvent(event)
	end
end

postEvents.registry.OnUsed, postEvents.registry.OnUnused = events.registry.OnUsed, events.registry.OnUnused
	
--------------------
-- Specialization --
--------------------

local CurrentSpecID
local function UpdateSpecID()
	local specIndex = GetSpecialization()
	if specIndex then
		CurrentSpecID = GetSpecializationInfo(specIndex)
	else
		CurrentSpecID = nil
	end
end

------------------
-- Combo Points --
------------------

local VEHICLE = "Vehicle"
local HasVehicle, GetVehicleCurrentComboPoints, GetVehicleMaxComboPoints
do
	local InVehicle = false
	
	events.RegisterUnitEvent(VEHICLE, "UNIT_ENTERED_VEHICLE", "player", nil, function()
		InVehicle = true
	end)
	
	events.RegisterUnitEvent(VEHICLE, "UNIT_EXITED_VEHICLE", "player", nil, function()
		InVehicle = false
	end)
	
	function HasVehicle()
		return InVehicle
	end
	
	function GetVehicleCurrentComboPoints()
		return InVehicle and UnitComboPoints("vehicle", "target")
	end
	
	function GetVehicleMaxComboPoints()
		return InVehicle and MAX_COMBO_POINTS
	end
end

local COMBO_POINTS = "ComboPoints"
local IsComboClass = COMBO_CLASSES[CLASS]
local HasClassComboPoints, GetClassCurrentComboPoints, GetClassMaxComboPoints

if IsComboClass then
	local isSpecCombo = not COMBO_SPECS[CLASS] -- Whether combo points are used only by one spec instead of all specs of the class
	
	local HasComboPoints
	local function UpdateHasComboPoints()
		HasComboPoints = (not isSpecCombo) and COMBO_SPECS[CLASS] or COMBO_SPECS[CurrentSpecID]
	end
	
	function HasClassComboPoints()
		return HasComboPoints
	end
	
	function GetClassCurrentComboPoints()
		return HasComboPoints and UnitComboPoints("player", "target")
	end
	
	function GetClassMaxComboPoints()
		return HasComboPoints and MAX_COMBO_POINTS
	end
	
	if isSpecCombo then
		events.RegisterEvent(COMBO_POINTS, "PLAYER_SPECIALIZATION_CHANGED", function()
			UpdateSpecID()
			UpdateHasComboPoints()
		end)
	else
		UpdateHasComboPoints()
	end
end

function events:UNIT_COMBO_POINTS(unit)
	bar:UpdateComboPointVisibility()
end

-- All classes can have vehicle combo points, only Rogues and Druids can have their own combo points
events:RegisterUnitEvent("UNIT_COMBO_POINTS", "vehicle", IsComboClass and "player" or nil)

-----------
-- Power --
-----------

local POWER = "Power"
local IsPowerClass = POWER_CLASSES[CLASS]
local HasPower, GetCurrentPower, GetMaxPower

if IsPowerClass then	
	local isSpecPower = not POWER_TYPES[CLASS] -- Whether the power is specific to one spec instead of shared by all specs of the class
	
	local CurrentPowerType
	local function UpdatePowerType()
		-- The spec's powerType is looked up second so that the class's powerType isn't looked up for specs that don't have a powerType
		CurrentPowerType = (not isSpecPower) and POWER_TYPES[CLASS] or POWER_TYPES[CurrentSpecID]
	end
	
	function HasPower()
		return CurrentPowerType ~= nil
	end
	
	function GetCurrentPower()
		return CurrentPowerType and UnitPower("player", CurrentPowerType)
	end
	
	function GetMaxPower(powerType)
		return CurrentPowerType and UnitPowerMax("player", CurrentPowerType)
	end
	
	local function OnUnitPower()
		if CurrentPowerType then
			bar:UpdateComboPointVisibility()
		end
	end
	
	if isSpecPower then
		events.RegisterEvent(POWER, "PLAYER_SPECIALIZATION_CHANGED", function()
			UpdateSpecID()
			UpdatePowerType()
			
			if CurrentPowerType then
				events.RegisterUnitEvent(POWER, "UNIT_POWER", "player", nil, OnUnitPower)
			else
				events.UnregisterEvent(POWER, "UNIT_POWER")
			end
		end)
	else
		UpdatePowerType()
		events.RegisterUnitEvent(POWER, "UNIT_POWER", "player", nil, OnUnitPower)
	end
end

---------------------------
-- Display Update Events --
---------------------------

postEvents:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", function()
	bar:SetShown(ClassComboPoints:GetMaxComboPoints() > 0)
	
	bar:AnchorComboPoints()
	bar:UpdateComboPointVisibility()
end)


------------------------------
-- ClassComboPoints Methods --
------------------------------

function ClassComboPoints:IsInVehicle()
	return UnitUsingVehicle("player")
end

function ClassComboPoints:GetCurrentComboPoints()
	local comboPoints
	
	if HasVehicle() then
		comboPoints = GetVehicleCurrentComboPoints()
	elseif HasPower() then
		comboPoints = GetCurrentPower()
	elseif HasComboPoints() then
		comboPoints = GetClassCurrentComboPoints()
	end
	
	return comboPoints or 0
end

function ClassComboPoints:GetMaxComboPoints()
	local maxComboPoints
	
	if HasVehicle() then
		maxComboPoints = GetVehicleMaxComboPoints()
	elseif HasPower() then
		maxComboPoints = GetMaxPower()
	elseif HasComboPoints() then
		maxComboPoints = GetClassMaxComboPoints()
	end
	
	return maxComboPoints or 0
end
