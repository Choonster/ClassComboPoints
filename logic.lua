local ADDON, ClassComboPoints = ...

---------------
-- Constants --
---------------
local CLASS, MAX_COMBO_POINTS = ClassComboPoints.CLASS, ClassComboPoints.MAX_COMBO_POINTS

-- Classes that use combo points
local COMBO_CLASSES = { ROGUE = true, DRUID = true }

-- Classes that use a power mechanic (UnitPower/UnitPowerMax) that acts in a similar fashion to combo points (e.g. Warlock Soul Shards)
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

local events = CreateFrame("Frame")
events:SetScript("OnEvent", function(self, event, ...)
	self[event](self, ...)
end)

-- All classes can have vehicle combo points, only Rogues and Druids can have their own combo points
events:RegisterUnitEvent("UNIT_COMBO_POINTS", "vehicle", COMBO_CLASSES[CLASS] and "player" or nil)
	
function events:UNIT_COMBO_POINTS(unit)
	bar:UpdateComboPointVisibility()
end

local HasPower = false

if POWER_CLASSES[CLASS] then
	HasPower = true
	
	local function GetPowerType()
		
	end
	
	events:RegisterUnitEvent("UNIT_POWER", "player")
	
	
end


------------
-- Logic --
-----------


local function GetVehicleCurrentComboPoints()
	return UnitComboPoints("vehicle", "target")
end

local function GetVehicleMaxComboPoints()
	return MAX_COMBO_POINTS
end

local GetClassComboPoints

function ClassComboPoints:IsInVehicle()
	return UnitUsingVehicle("player")
end