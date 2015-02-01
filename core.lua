local ADDON, ClassComboPoints = ...

---------------
-- Constants --
---------------
local _, CLASS = UnitClass("player")

local BASE_TEXTURE_PATH = [[Interface\AddOns\ClassComboPoints\Textures\]]
local BAR_FILL_CLASS = ("bar_fill_%s.tga"):format(CLASS:lower())
local BAR_FILL_VEHICLE = "bar_fill_rogue.tga"

-- The maximum number of combo points of any class/spec. May not be the maximum number of combo points for the current class/spec.
local MAX_COMBO_POINTS = 5

local NINETY_DEGREES_IN_RADIANS = 0.5 * math.pi

-- The width of the left and right caps of the bar (or their height in vertical mode)
local CAPS_WIDTH = 64

--------------------
-- Region Methods --
--------------------

-- Copies all values from methods into object. Returns object for convenience.
local function CopyMethods(methods, object)
	for name, func in pairs(methods) do
		object[name] = func
	end
	
	return object
end

local Region = {}

-- Anchor methods return self to allow easy method chaining

-- Sets all four points of the region to the corresponding points of its parent with an x and y offset.
-- Positive values of x and y will anchor the region inside the parent, negative values will anchor it outside the parent.
function Region:AnchorToParent(x, y)
	self:SetPoint("TOPLEFT", x, -y)
	self:SetPoint("BOTTOMLEFT", x, y)
	self:SetPoint("TOPRIGHT", -x, -y)
	self:SetPoint("BOTTOMRIGHT", -x, y)
	
	return self
end

-- Horizontal anchoring methods

-- Anchor the region horizontally between two regions with the specified x and y offsets.
-- Positive values of x and y will anchor the region inside the the space between the regions, negative values will anchor it outside.
function Region:AnchorBetweenHorizontal(left, right, x, y)
	self:SetPoint("TOPLEFT", left, "TOPRIGHT", x, -y)
	self:SetPoint("BOTTOMLEFT", left, "BOTTOMRIGHT", x, y)
	self:SetPoint("TOPRIGHT", right, "TOPLEFT", -x, -y)
	self:SetPoint("BOTTOMRIGHT", right, "BOTTOMLEFT", -x, y)
	
	return self
end

-- Anchor one side of the region horizontally to the same side of its parent and set its width
function Region:AnchorSideToParentHorizontal(side, width)
	return self:AnchorSideToSameSideHorizontal(self:GetParent(), side, width, 0, 0)
end

-- Anchor one side of the region horizontally to the same side of another region with the specified x and y offsets and set its width.
-- Positive values of x will anchor the region to the right of the other region, negative values will anchor it to the left.
-- Positive values of y will anchor the region within the other region, negative values will anchor it outside.
function Region:AnchorSideToSameSideHorizontal(region, side, width, x, y)
	local top, bottom = "TOP" .. side, "BOTTOM" .. side
	
	self:SetPoint(top, region, top, x, -y)
	self:SetPoint(bottom, region, bottom, x, y)
	self:SetWidth(width)
	
	return self
end

-- Anchor one side of the region horizontally to the opposite side of another region with the specified x and y offsets and set its width.
-- Positive values of x will anchor the region to the right of the other region, negative values will anchor it to the left.
-- Positive values of y will anchor the region within the other region, negative values will anchor it outside.
function Region:AnchorSideToOppositeSideHorizontal(region, side, width, x, y)
	local oppositeSide = side == "LEFT" and "RIGHT" or "LEFT"
	
	self:SetPoint("TOP" .. side, region, "TOP" .. oppositeSide, x, -y)
	self:SetPoint("BOTTOM" .. side, region, "BOTTOM" .. oppositeSide, x, y)
	self:SetWidth(width)
	
	return self
end

-- Vertical anchoring methods

-- Anchor the region vertically between two regions with the specified x and y offsets.
-- Positive values of x and y will anchor the region inside the the space between the regions, negative values will anchor it outside.
function Region:AnchorBetweenVertical(bottom, top, x, y)
	self:SetPoint("TOPLEFT", top, "TOPRIGHT", x, -y)
	self:SetPoint("TOPRIGHT", top, "TOPLEFT", -x, -y)
	self:SetPoint("BOTTOMLEFT", bottom, "BOTTOMRIGHT", x, y)
	self:SetPoint("BOTTOMRIGHT", bottom, "BOTTOMLEFT", -x, y)
	
	return self
end

-- Anchor one side of the region vertically to the same side of its parent and set its width
function Region:AnchorSideToParentVertical(side, width)
	return self:AnchorSideToSameSideVertical(self:GetParent(), side, width, 0, 0)
end

-- Anchor one side of the region vertically to the same side of another region with the specified x and y offsets and set its height.
-- Positive values of x will anchor the region within the other region, negative values will anchor it outside.
-- Positive values of y will anchor the region above the other region, negative values will anchor it below.
function Region:AnchorSideToSameSideVertical(region, side, height, x, y)
	local left, right = side .. "LEFT", side .. "RIGHT"
	
	self:SetPoint(left, region, left, x, y)
	self:SetPoint(right, region, right, -x, y)
	self:SetHeight(height)
	
	return self
end

-- Anchor one side of the region vertically to the opposite side of another region with the specified x and y offsets and set its height.
-- Positive values of x will anchor the region within the other region, negative values will anchor it outside.
-- Positive values of y will anchor the region above the other region, negative values will anchor it below.
function Region:AnchorSideToOppositeSideVertical(region, side, height, x, y)
	local oppositeSide = side == "TOP" and "BOTTOM" or "TOP"
	
	self:SetPoint(side .. "LEFT", region, oppositeSide .. "LEFT", x, y)
	self:SetPoint(side .. "RIGHT", region, oppositeSide .. "RIGHT", -x, y)
	self:SetWidth(width)
	
	return self
end

---------------------
-- Texture Methods --
---------------------
local Texture = CopyMethods(Region, {})

-- Set whether or not the texture is rotated ninety degrees counter-clockwise
function Texture:SetRotated(rotated)
	self.isRotated = rotated
	self:SetRotation(rotated and NINETY_DEGREES_IN_RADIANS or 0)
end

-------------------
-- Frame Methods --
-------------------
local Frame = CopyMethods(Region, {})

function Frame:NewFrame(frameType, name, template)
	local frame = CreateFrame(frameType, name, self, template)
	frame.parent = self

	return CopyMethods(Frame, frame)
end

-- Create a new texture object with the specified draw layer, sublevel and texture file name (without the leading BASE_TEXTURE_PATH)
function Frame:NewTexture(layer, level, textureName)
	local texture = self:CreateTexture(nil, layer, nil, level)
	texture:SetTexture(BASE_TEXTURE_PATH .. textureName)
	
	(self.parent or self).allTextures[texture] = true
	
	return CopyMethods(Texture, texture)
end

---------------
----- Bar -----
---------------
-- We only create the bar elements here, we anchor them in the horizontal/vertical layout functions

local bar = CreateFrame("Frame", "ClassComboPointsBar", UIParent)
bar.allTextures = {}
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
	local separator = bar:NewTexture("ARTWORK", 1, "separator.tga")
	separator.index = i
	bar.separators[i] = separator
end

---------------
--- Layout ----
---------------

function bar:ClearAnchors()
	for texture, _ in pairs(self.allTextures) do
		texture:ClearAllPoints()
	end
	
	self.glow:ClearAllPoints()
	self.separators:ClearAllPoints()
end

function bar:ClearComboPointAnchors()
	for _, comboPoint in ipairs(self.comboPoints) do
		comboPoint:ClearAllPoints()
	end
end

function bar:IsHorizontal()
	return self.isHorizontal
end

function bar:AnchorComboPoints()
	if self:IsHorizontal() then
		self:AnchorComboPointsHorizontal()
	else
		self:AnchorComboPointsVertical()
	end
end

function bar:UpdateComboPointDimensions()
	local maxComboPoints = ClassComboPoints:GetMaxComboPoints()
	if maxComboPoints == 0 then return end
	
	local comboPoints = self.comboPoints
	
	if self:IsHorizontal() then
		local comboPointWidth = (self:GetWidth() - 64) / maxComboPoints
		
		for i = 1, maxComboPoints do
			comboPoints[i]:SetWidth(comboPointWidth)
		end
	else
		local comboPointHeight = (self:GetHeight() - 64) / maxComboPoints
		
		for i = 1, maxComboPoints do
			comboPoints[i]:SetHeight(comboPointHeight)
		end
	end
end

function bar:SetHorizontal()
	self.isHorizontal = true
	
	self:SetSize(256 + CAPS_WIDTH, 32)
	
	for texture, _ in pairs(self.allTextures) do
		texture:SetRotated(false)
	end
	
	local capLeft = self.capLeft:AnchorSideToParentHorizontal("LEFT", 32)
	local capRight = self.capRight:AnchorSideToParentHorizontal("RIGHT", 32)
	self.background:AnchorBetweenHorizontal(capLeft, capRight, 0, 0)
	
	local glow = self.glow:AnchorBetweenHorizontal(capLeft, capRight, 0, 8)
	local glowCapLeft = glow.capLeft:AnchorSideToParentHorizontal("LEFT", 16)
	local glowCapRight = glow.capRight:AnchorSideToParentHorizontal("RIGHT", 16)
	glow.border:AnchorBetweenHorizontal(glowCapLeft, glowCapRight, 0, 0)
	
	self:AnchorComboPointsHorizontal()
end

function bar:AnchorComboPointsHorizontal()
	local maxComboPoints = ClassComboPoints:GetMaxComboPoints()
	if maxComboPoints == 0 then return end
	
	local comboPoints, separators = self.comboPoints, self.separators
	
	local comboPointWidth = (self:GetWidth() - CAPS_WIDTH) / maxComboPoints
	
	for i = 1, maxComboPoints do
		local comboPoint = comboPoints[i]
		local separator = separators[i]
		
		local anchor, yOffset
		if i == 1 then
			anchor, yOffset = self.capLeft, 8
		else
			anchor, yOffset = comboPoints[i - 1], 0
		end
		comboPoint:AnchorSideToOppositeSideHorizontal("LEFT", anchor, comboPointWidth, 0, yOffset)
		
		if i < maxComboPoints then
			separator:AnchorSideToOppositeSideHorizontal("LEFT", comboPoint, 32, -16, 0)
		end
	end
	
	comboPoints[maxComboPoints]:AnchorSideToOppositeSideHorizontal("RIGHT", self.capRight, comboPointWidth, 0, 8)
end

function bar:SetVertical()
	self.isHorizontal = false
	
	self:SetSize(32, 256 + CAPS_WIDTH)
	
	for texture, _ in pairs(self.allTextures) do
		texture:SetRotated(true)
	end
	
	-- In vertical mode, the left cap is on the bottom and the right cap is on the top
	local capLeft = self.capLeft:AnchorSideToParentVertical("BOTTOM", 32)
	local capRight = self.capRight:AnchorSideToParentVertical("TOP", 32)
	self.background:AnchorBetweenVertical(capLeft, capRight, 0, 0)
	
	local glow = self.glow:AnchorBetweenVertical(capLeft, capRight, 8, 0)
	local glowCapLeft = glow.capLeft:AnchorSideToParentVertical("BOTTOM", 16)
	local glowCapRight = glow.capRight:AnchorSideToParentVertical("TOP", 16)
	glow.border:AnchorBetweenVertical(glowCapLeft, glowCapRight, 0, 0)
	
	self:AnchorComboPointsVertical()
end
	
function bar:AnchorComboPointsVertical()
	local maxComboPoints = ClassComboPoints:GetMaxComboPoints()
	if maxComboPoints == 0 then return end
	
	local comboPoints, separators = self.comboPoints, self.separators
	
	local comboPointHeight = (self:GetHeight() - CAPS_WIDTH) / maxComboPoints
	
	for i = 1, maxComboPoints do
		local comboPoint = comboPoints[i]
		local separator = separators[i]
		
		local anchor, xOffset
		if i == 1 then
			anchor, xOffset = self.capLeft, 8
		else
			anchor, xOffset = comboPoints[i - 1], 0
		end
		comboPoint:AnchorSideToOppositeSideVertical("BOTTOM", anchor, comboPointHeight, xOffset, 0)
		
		if i < maxComboPoints then
			separator:AnchorSideToOppositeSideVertical("BOTTOM", comboPoint, 32, 0, -16)
		end
	end
	
	comboPoints[maxComboPoints]:AnchorSideToOppositeSideVertical("TOP", self.capRight, comboPointHeight, 8, 0)
end

function bar:UpdateComboPointFill()
	local inVehicle = ClassComboPoints:IsInVehicle()
	local comboPoints = self.comboPoints
	for i = 1, MAX_COMBO_POINTS do
		comboPoints[i]:SetTexture(BASE_TEXTURE_PATH .. (inVehicle and BAR_FILL_VEHICLE or BAR_FILL_CLASS))
	end
end

function bar:UpdateComboPointVisibility()
	local currentComboPoints = ClassComboPoints:GetCurrentComboPoints()
	local comboPoints = self.comboPoints
	for i = 1, MAX_COMBO_POINTS do
		comboPoints[i]:SetShown(i <= currentComboPoints)
	end
end
