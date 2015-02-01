---------------
-- Constants --
---------------
local _, CLASS = UnitClass("player")

local BASE_TEXTURE_PATH = [[Interface\AddOns\ClassComboPoints\Textures\]]
local BAR_FILL_CLASS = ("bar_fill_%s.tga"):format(CLASS:lower())
local BAR_FILL_VEHICLE = "bar_fill_rogue.tga"

local MAX_COMBO_POINTS = 5

--------------------
-- Region Methods --
--------------------
local function CopyMethods(methods, object)
	for name, func in pairs(methods) do
		object[name] = func
	end
end

local Region = {}

-- Anchor methods return self to allow easy method chaining

-- Sets all four points of the region to the corresponding points of its parent with an x- and y-offset.
-- Positive values of x and y will anchor the region inside the parent, negative values will anchor it outside the parent.
function Region:AnchorToParent(x, y)
	self:SetPoint("TOPLEFT", x, -y)
	self:SetPoint("BOTTOMLEFT", x, y)
	self:SetPoint("TOPRIGHT", -x, -y)
	self:SetPoint("BOTTOMRIGHT", -x, y)
	
	return self
end

-- Anchor the region horizontally between two regions with the specified x and y offsets.
-- Positive values of x and y will anchor the region inside the the space between the regions, negative values will anchor it outside.
function Region:AnchorBetweenHorizontal(left, right, x, y)
	self:SetPoint("TOPLEFT", left, "TOPRIGHT", x, -y)
	self:SetPoint("BOTTOMLEFT", left, "BOTTOMRIGHT", x, y)
	self:SetPoint("TOPRIGHT", right, "TOPLEFT", -x, -y)
	self:SetPoint("BOTTOMRIGHT", right, "BOTTOMLEFT", -x, y)
	
	return self
end

-- Anchor the region horizontally to one side of its parent and set its width
function Region:AnchorSideHorizontal(side, width)
	self:SetPoint("TOP" .. side)
	self:SetPoint("BOTTOM" .. side)
	self:SetWidth(width)
	
	return self
end

-------------------
-- Frame Methods --
-------------------
local Frame = {}
CopyMethods(Region, Frame)


function Frame:NewFrame(frameType, name, template)
	local frame = CreateFrame(frameType, name, self, template)
	
	CopyMethods(Frame, frame)
	
	return frame
end

-- Create a new texture object with the specified draw layer, sublevel and texture file name (without the leading BASE_TEXTURE_PATH)
function Frame:NewTexture(layer, level, textureName)
	local texture = self:CreateTexture(nil, layer, nil, level)
	texture:SetTexture(BASE_TEXTURE_PATH .. textureName)
	
	CopyMethods(Region, texture)
	
	return texture
end

---------------
----- Bar -----
---------------
-- We only create the bar elements here, we anchor them in the horizontal/vertical layout functions

local bar = CreateFrame("Frame", "ClassComboPoints", UIParent)
bar:SetFrameStrata("HIGH")
CopyMethods(Frame, bar)

bar.background = bar:NewTexture("BACKGROUND", 1, "bar_background.tga")

bar.comboPoints = {}
for i = 1, MAX_COMBO_POINTS do
	local comboPoint = bar:NewTexture("BACKGROUND", 2, BAR_FILL_CLASS)
	comboPoint.index = i
	bar.comboPoints[i] = comboPoint
end

bar.capLeft = bar:NewTexture("BORDER", 1, "bar_left_cap.tga")
bar.capRight = bar:NewTexture("BORDER", 1, "bar_right_cap.tga")

local glow = bar:NewFrame("Frame")
glow.border = glow:NewTexture("BORDER", 1, "glow_borders.tga")
glow.capLeft = glow:NewTexture("BORDER", 2, "glow_left_cap.tga")
glow.capRight = glow:NewTexture("BORDER", 2, "glow_right_cap.tga")
bar.glow = glow

bar.separators = bar:NewFrame("Frame")
for i = 1, MAX_COMBO_POINTS - 1 do
	local separator = bar:NewTexture("ARTWORK", 3, "separator.tga")
	separator.index = i
	bar.separators[i] = separator
end

---------------
--- Layout ----
---------------

function bar:ClearAnchors()
	self.background:ClearAllPoints()
	
	for _, comboPoint in ipairs(self.comboPoints) do
		comboPoint:ClearAllPoints()
	end
	
	self.capLeft:ClearAllPoints()
	self.capRight:ClearAllPoints()
	
	self.glow.border:ClearAllPoints()
	self.glow.capLeft:ClearAllPoints()
	self.glow.capRight:ClearAllPoints()
	self.glow:ClearAllPoints()
	
	for _, separator in ipairs(self.separators) do
		separator:ClearAllPoints()
	end
	self.separators:ClearAllPoints()
end

function bar:SetHorizontal()
	self:SetSize(256 + 32 * 2, 32)
	
	local capLeft = self.capLeft:AnchorSideHorizontal("LEFT", 32)
	local capRight = self.capRight:AnchorSideHorizontal("RIGHT", 32)
	
	self.background:AnchorBetweenHorizontal(capLeft, capRight, 0, 0)
	
	local glow = self.glow:AnchorBetweenHorizontal(capLeft, capRight, 0, 8)
	local glowCapLeft = glow.capLeft:AnchorSideHorizontal("LEFT", 16)
	local glowCapRight = glow.capRight:AnchorSideHorizontal("RIGHT", 16)
	glow.border:AnchorBetweenHorizontal(glowCapLeft, glowCapRight, 0, 0)
	
	
end