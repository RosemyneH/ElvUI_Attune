local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule("Skins")
local AS = E:GetModule("AddOnSkins")

if not AS:IsAddonLODorEnabled("ScootsStats") then return end

-- ʕ •ᴥ•ʔ✿ Helpers to fetch user-configurable values with sane fallbacks ✿ ʕ •ᴥ•ʔ
local function GetRowHeight()
	local dbValue = E.db and E.db.addOnSkins and tonumber(E.db.addOnSkins.scootStatsRowHeight)
	return (dbValue and dbValue > 0) and dbValue or 16
end

local function GetFontSize()
	local dbValue = E.db and E.db.addOnSkins and tonumber(E.db.addOnSkins.scootStatsFontSize)
	return (dbValue and dbValue > 0) and dbValue or 16
end

-- Forward declaration so we can assign it later
local function updateScootStatsConfig() end

local function restyleRow(row)
	if not row or row.isStyled then return end
	
	local name = row:GetName()
	if not name then return end
	
	local label = _G[name .. "Label"]
	local stat = _G[name .. "StatText"]
	local fontSize = GetFontSize()
	local rowHeight = GetRowHeight()
	
	if label then
		label:FontTemplate(nil, fontSize, "OUTLINE")
		label:ClearAllPoints()
		label:SetPoint("LEFT", row, "LEFT", 6, 0)
	end
	if stat then
		stat:FontTemplate(nil, fontSize, "OUTLINE")
		stat:ClearAllPoints()
		stat:SetPoint("RIGHT", row, "RIGHT", -6, 0)
	end

	-- Some versions of ScootsStats override SetHeight; use pcall to be safe
	pcall(row.SetHeight, row, rowHeight)

	-- Clear Blizzard textures and apply alternating background
	if row.StripTextures then row:StripTextures() end

	-- Determine row index from name (captures digits after last hyphen)
	local rowIndex = tonumber(name:match("-(%d+)$")) or 0
	local stripesEnabled = not E.db or not E.db.addOnSkins or E.db.addOnSkins.scootStatsStripeRows ~= false
	if stripesEnabled and ((rowIndex % 2) == 0) then
		if not row.bgStripe then
			row.bgStripe = row:CreateTexture(nil, "BACKGROUND")
			row.bgStripe:SetAllPoints()
		end
		-- guarantee correct layer on old clients
		row.bgStripe:SetDrawLayer("BACKGROUND", 1)

		-- colour – light grey, 40 % alpha (easy to see on dark backdrop)
		row.bgStripe:SetTexture(0.25, 0.25, 0.25, 0.4)

		-- update width every time we resize the row
		hooksecurefunc(row, "SetWidth", function(self) if self.bgStripe then self.bgStripe:SetAllPoints() end end)

		-- show or hide depending on even/odd index & toggle
		row.bgStripe:SetShown(stripesEnabled and (rowIndex % 2 == 0))
	else
		if row.bgStripe then row.bgStripe:Hide() end
	end

	row.isStyled = true
end

local function restyleHeader(frame)
	if frame and frame.text and not frame.text.isStyled then
		frame.text:FontTemplate(nil, GetFontSize(), "OUTLINE")
		frame.text.isStyled = true
	end
end

local function adjustFrameHeights()
	if not ScootsStats or not ScootsStats.frames or not ScootsStats.frames.master then return end
	
	local charFrame = _G['CharacterFrame']
	if not charFrame then return end
	
	local f = ScootsStats.frames
	local charHeight = charFrame:GetHeight() - 88
	
	-- Set master frame height to match character frame
	f.master:SetHeight(charHeight)
	ScootsStats.frames.master:SetPoint('TOPRIGHT', _G['CharacterFrame'], 'TOPRIGHT', 0, 0)
	
	-- Reset CharacterFrame width to base width (override addon's width expansion)
	if ScootsStats.baseWidth then
		charFrame:SetWidth(ScootsStats.baseWidth)
	end
	
	-- Position ScootsStats frame with a nice offset to the right of CharacterFrame
	f.master:ClearAllPoints()
	f.master:SetPoint('TOPLEFT', charFrame, 'TOPRIGHT', -30, -14)
	
	-- Adjust scroll frame height accordingly (accounting for title and padding)
	if f.scrollFrame then
		local scrollHeight = charHeight - 34 -- Account for title area
		f.scrollFrame:SetHeight(scrollHeight)
	end
	
	-- Adjust background height to match
	if f.background then
		f.background:SetHeight(charHeight)
	end

	-- Reapply width & x-offset so they aren't lost when this function runs
	if applyDimensionSettings then
		applyDimensionSettings()
	end
end

-- ʕ •ᴥ•ʔ✿ Apply width & offset settings ✿ ʕ •ᴥ•ʔ
local function applyDimensionSettings()
	if not ScootsStats or not ScootsStats.frames or not ScootsStats.frames.master then return end

	local f = ScootsStats.frames

	-- Guard to avoid infinite loops when this function itself triggers SetPoint
	if f._dimensionApplying then return end

	f._dimensionApplying = true

	-- Width
	local width = tonumber(E.db and E.db.addOnSkins and E.db.addOnSkins.scootStatsWidth) or f.master:GetWidth()
	if width and width > 0 then
		f.master:SetWidth(width)
		-- adjust scroll child/frame widths so scroll bar anchors remain ok
		if f.scrollFrame then
			local scrollWidth = (f.scrollBar and f.scrollBar:IsShown()) and f.scrollBar:GetWidth() or 0
			f.scrollFrame:SetWidth(width + scrollWidth)
		end
		if f.scrollChild then
			f.scrollChild:SetWidth(width)
		end
		if f.background then
			f.background:SetWidth(width + 20)
		end

		-- Update individual row and section frame widths to match new inner width (minus 10px padding Blizzard uses)
		local contentWidth = math.max(0, width - 10)
		if ScootsStats.sectionFrames then
			for _, sFrame in pairs(ScootsStats.sectionFrames) do
				sFrame:SetWidth(contentWidth)
			end
		end
		if ScootsStats.rowFrames then
			for _, rFrame in pairs(ScootsStats.rowFrames) do
				rFrame:SetWidth(contentWidth)
			end
		end
	end

	-- Horizontal offset relative to CharacterFrame right edge
	local offsetX = tonumber(E.db and E.db.addOnSkins and E.db.addOnSkins.scootStatsXOffset)
	if offsetX == nil then offsetX = -30 end

	if _G['CharacterFrame'] then
		f.master:ClearAllPoints()
		f.master:SetPoint('TOPLEFT', _G['CharacterFrame'], 'TOPRIGHT', offsetX, -14)
	end

	f._dimensionApplying = false
end

-- ʕ •ᴥ•ʔ✿ ScootsStats Skin ✿ ʕ •ᴥ•ʔ
S:AddCallbackForAddon("ScootsStats", "ScootsStats", function()
	if not E.private.addOnSkins.ScootsStats then return end
	
	-- Expose updater so the options panel (or other modules) can refresh styling on the fly
	AS.updateScootStatsConfig = updateScootStatsConfig

	local function styleMain()
		if not ScootsStats or not ScootsStats.frames then return end
		
		local f = ScootsStats.frames
		if not f.master then return end

		-- Hide and clear the background texture
		if f.background then
			f.background:Hide()
			if f.background.texture then
				f.background.texture:SetTexture(nil)
			end
		end

		-- Style the master frame
		if f.master then
			f.master:StripTextures()
			f.master:SetTemplate("Transparent")
		end

		-- Style the scroll frame
		if f.scrollFrame then
			f.scrollFrame:StripTextures()
			f.scrollFrame:SetTemplate("Transparent")
		end

		-- Style the scroll child
		if f.scrollChild then
			f.scrollChild:StripTextures()
			f.scrollChild:SetTemplate("Transparent")
		end

		-- Style the scroll bar components
		if f.scrollBar and not f.scrollBar.isStyled then
			f.scrollBar:StripTextures()
			f.scrollBar:SetTemplate("Transparent")
			f.scrollBar.isStyled = true
		end
		
		if f.scrollUpButton and not f.scrollUpButton.isStyled then
			f.scrollUpButton:StripTextures()
			S:HandleNextPrevButton(f.scrollUpButton)
			f.scrollUpButton.isStyled = true
		end
		
		if f.scrollDownButton and not f.scrollDownButton.isStyled then
			f.scrollDownButton:StripTextures()
			S:HandleNextPrevButton(f.scrollDownButton)
			f.scrollDownButton.isStyled = true
		end

		-- Style the options button
		if f.optionsButton and not f.optionsButton.isStyled then
			S:HandleButton(f.optionsButton)
			f.optionsButton.isStyled = true
		end

		-- Style the title
		if f.title and f.title.text then
			local titleFontSize = math.max(10, GetFontSize() - 4)
			f.title.text:FontTemplate(nil, titleFontSize, "OUTLINE")
		end

		-- Adjust frame heights to match CharacterFrame
		adjustFrameHeights()
		applyDimensionSettings()

		-- Style existing section headers
		if ScootsStats.sectionFrames then
			for _, sFrame in pairs(ScootsStats.sectionFrames) do
				restyleHeader(sFrame)
			end
		end
		
		-- Style existing row frames
		if ScootsStats.rowFrames then
			for _, rFrame in pairs(ScootsStats.rowFrames) do
				restyleRow(rFrame)
			end
			applyDimensionSettings()
		end
	end

	local function styleOptionsPanel()
		if not ScootsStats or not ScootsStats.frames or not ScootsStats.frames.options then return end
		
		local options = ScootsStats.frames.options
		if options.isStyled then return end
		
		options:StripTextures()
		options:SetTemplate("Transparent")
		
		-- Style option toggle frames
		if ScootsStats.optionToggleFrames then
			for _, toggle in pairs(ScootsStats.optionToggleFrames) do
				if toggle and not toggle.isStyled then
					toggle:StripTextures()
					toggle:SetTemplate("Default")
					toggle.isStyled = true
				end
			end
		end
		
		options.isStyled = true
	end

	-- Hook into the addon's initialization
	if ScootsStats then
		-- Try immediate styling if already initialized
		if ScootsStats.initialised and ScootsStats.frames and ScootsStats.frames.master then
			styleMain()
		end
		
		-- Hook the init function
		if ScootsStats.init then
			S:SecureHook(ScootsStats, "init", function()
				E:Delay(0.1, function()
					styleMain()
					adjustFrameHeights() -- Ensure height is set after init
				end)
			end)
		end

		-- Hook the updateStats function to restyle frames as they're created
		if ScootsStats.updateStats then
			S:SecureHook(ScootsStats, "updateStats", function()
				-- Hide background each update
				if ScootsStats.frames and ScootsStats.frames.background then
					ScootsStats.frames.background:Hide()
				end
				
				-- Ensure height stays matched
				adjustFrameHeights()
				
				-- Restyle any new frames
				E:Delay(0.05, function()
					if ScootsStats.sectionFrames then
						for _, sFrame in pairs(ScootsStats.sectionFrames) do
							restyleHeader(sFrame)
						end
					end
					
					if ScootsStats.rowFrames then
						for _, rFrame in pairs(ScootsStats.rowFrames) do
							restyleRow(rFrame)
						end
					end
					applyDimensionSettings()
				end)
			end)
		end

		-- Hook the toggleOptionsPanel function
		if ScootsStats.toggleOptionsPanel then
			S:SecureHook(ScootsStats, "toggleOptionsPanel", function()
				E:Delay(0.1, styleOptionsPanel) -- Delay to ensure options panel is created
			end)
		end

		-- Hook CreateFrame to catch dynamically created section headers
		hooksecurefunc("CreateFrame", function(frameType, name, parent)
			if name and string.find(name, "ScootsStatsSectionHead") then
				E:Delay(0.01, function()
					local frame = _G[name]
					if frame and frame.text then
						restyleHeader(frame)
					end
				end)
			elseif name and string.find(name, "ScootsStatsRow") then
				E:Delay(0.01, function()
					local frame = _G[name]
					if frame then
						restyleRow(frame)
					end
				end)
			end
		end)
		
		-- Hook CharacterFrame show/hide events to maintain height matching
		if _G['CharacterFrame'] then
			S:SecureHookScript(_G['CharacterFrame'], "OnShow", function()
				E:Delay(0.1, adjustFrameHeights)
			end)
			
			S:SecureHookScript(_G['CharacterFrame'], "OnSizeChanged", function()
				adjustFrameHeights()
			end)
		end
	end
	
	-- Fallback styling attempt after a delay
	E:Delay(2, function()
		if ScootsStats and ScootsStats.frames and ScootsStats.frames.master then
			styleMain()
		end
	end)

	-- After ScootsStats is available, lock its master frame position against external changes
	if ScootsStats and ScootsStats.frames and ScootsStats.frames.master then
		local master = ScootsStats.frames.master
		if not master._elvuiHooked then
			hooksecurefunc(master, "SetPoint", function()
				-- Re-apply our anchor a moment later to override any external move
				E:Delay(0, function() applyDimensionSettings() end)
			end)
			master._elvuiHooked = true
		end
	end
end)

-- ʕ •ᴥ•ʔ✿ Restyle everything when the user tweaks options ✿ ʕ •ᴥ•ʔ
function updateScootStatsConfig()
	if not ScootsStats then return end

	if ScootsStats.rowFrames then
		for _, r in pairs(ScootsStats.rowFrames) do
			r.isStyled = nil
			restyleRow(r)
		end
	end

	if ScootsStats.sectionFrames then
		for _, s in pairs(ScootsStats.sectionFrames) do
			if s.text then s.text.isStyled = nil end
			restyleHeader(s)
		end
	end

	applyDimensionSettings()
end 