local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule("Skins")
local AS = E:GetModule("AddOnSkins")

if not AS:IsAddonLODorEnabled("ScootsStats") then return end

-- ʕ •ᴥ•ʔ✿ Performance optimizations - Cache frequently accessed values ✿ ʕ •ᴥ•ʔ
local cachedRowHeight, cachedFontSize
local pendingOperations = {}
local hasPendingBatch = false

-- Cache frame references
local characterFrame = _G['CharacterFrame']
local scrollBarFrame

local function updateCachedValues()
	cachedRowHeight = (E.db and E.db.addOnSkins and tonumber(E.db.addOnSkins.scootStatsRowHeight)) or 16
	cachedFontSize = (E.db and E.db.addOnSkins and tonumber(E.db.addOnSkins.scootStatsFontSize)) or 16
	cachedRowHeight = (cachedRowHeight > 0) and cachedRowHeight or 16
	cachedFontSize = (cachedFontSize > 0) and cachedFontSize or 16
end

local function GetRowHeight()
	return cachedRowHeight or 16
end

local function GetFontSize()
	return cachedFontSize or 16
end

-- Batch operations only for non-critical operations
local function batchOperation(operation)
	table.insert(pendingOperations, operation)
	
	if not hasPendingBatch then
		hasPendingBatch = true
		E:Delay(0.01, function() -- Reduced delay for faster response
			for _, op in ipairs(pendingOperations) do
				pcall(op)
			end
			wipe(pendingOperations)
			hasPendingBatch = false
		end)
	end
end

-- ʕ •ᴥ•ʔ✿ Force scrollbar visibility ✿ ʕ •ᴥ•ʔ
local function ensureScrollBarVisible()
	-- Cache scrollbar reference only if it exists
	if not scrollBarFrame then
		scrollBarFrame = _G.ScootsStatsScrollFrameScrollBar
	end
	
	-- Only proceed if scrollbar actually exists
	if scrollBarFrame then
		scrollBarFrame:Show()
	else
		-- Scrollbar doesn't exist yet, return false to indicate failure
		return false
	end
	
	-- Also try to show through ScootsStats frames if available
	if ScootsStats and ScootsStats.frames then
		if ScootsStats.frames.scrollBar then
			ScootsStats.frames.scrollBar:Show()
		end
		if ScootsStats.frames.scrollUpButton then
			ScootsStats.frames.scrollUpButton:Show()
		end
		if ScootsStats.frames.scrollDownButton then
			ScootsStats.frames.scrollDownButton:Show()
		end
	end
	
	return true -- Success
end

-- Forward declaration so we can assign it later
local function updateScootStatsConfig() end

-- Counter for row indexing (since name parsing might be unreliable)
local rowCounter = 0

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

	-- ʕノ•ᴥ•ʔノ✿ Ensure row width matches parent on creation ✿ ʕノ•ᴥ•ʔノ
	local parentWidth = row:GetParent() and row:GetParent():GetWidth()
	if parentWidth and parentWidth > 50 then
		pcall(row.SetWidth, row, parentWidth - 4)
	else
		-- Parent width not finalized yet; update once when frame is next visible
		if not row._pendingWidthUpdate then
			row._pendingWidthUpdate = true
			row:SetScript('OnUpdate', function(self)
				local pw = self:GetParent() and self:GetParent():GetWidth() or 0
				if pw > 50 then
					pcall(self.SetWidth, self, pw - 4)
					self:SetScript('OnUpdate', nil)
				end
			end)
		end
	end

	-- Clear Blizzard textures and apply alternating background
	if row.StripTextures then row:StripTextures() end

	-- Assign row index and increment counter
	if not row._rowIndex then
		row._rowIndex = rowCounter
		rowCounter = rowCounter + 1
	end
	
	local stripesEnabled = not E.db or not E.db.addOnSkins or E.db.addOnSkins.scootStatsStripeRows ~= false
	
	if stripesEnabled and ((row._rowIndex % 2) == 0) then
		if not row.bgStripe then
			row.bgStripe = row:CreateTexture(nil, "BACKGROUND")
			row.bgStripe:SetAllPoints()
			-- Use SetTexture with solid color for 3.3.5a
			row.bgStripe:SetTexture(0.25, 0.25, 0.25, 0.4)
		end
		row.bgStripe:Show()
	else
		if row.bgStripe then 
			row.bgStripe:Hide() 
		end
	end

	row.isStyled = true

	-- Some versions of ScootsStats override SetHeight; use pcall to be safe
	pcall(row.SetHeight, row, rowHeight)
end

local function restyleHeader(frame)
	if frame and frame.text and not frame.text.isStyled then
		frame.text:FontTemplate(nil, GetFontSize(), "OUTLINE")
		frame.text.isStyled = true
	end
end

-- ʕ •ᴥ•ʔ✿ INSTANT height adjustments ✿ ʕ •ᴥ•ʔ
local function adjustFrameHeights()
	if not ScootsStats or not ScootsStats.frames or not ScootsStats.frames.master then return end

	-- Cache frame reference
	if not characterFrame then
		characterFrame = _G['CharacterFrame']
	end
	if not characterFrame then return end
	
	local f = ScootsStats.frames
	local charHeight = characterFrame:GetHeight() - 88

	-- Set master frame height to match character frame
	f.master:SetHeight(charHeight)
	f.master:SetPoint('TOPRIGHT', characterFrame, 'TOPRIGHT', 0, 0)
	
	-- Reset CharacterFrame width to base width (override addon's width expansion)
	if ScootsStats.baseWidth then
		characterFrame:SetWidth(ScootsStats.baseWidth)
	end
	
	-- Position ScootsStats frame with a nice offset to the right of CharacterFrame
	f.master:ClearAllPoints()
	f.master:SetPoint('TOPLEFT', characterFrame, 'TOPRIGHT', -30, -14)
	
	-- Adjust scroll frame height accordingly (accounting for title and padding)
	if f.scrollFrame then
		local scrollHeight = charHeight - 34 -- Account for title area
		f.scrollFrame:SetHeight(scrollHeight)
	end
	
	-- Adjust background height to match
	if f.background then
		f.background:SetHeight(charHeight)
	end

	-- Force scrollbar visibility after height adjustments
	ensureScrollBarVisible()
end

-- ʕ •ᴥ•ʔ✿  dimension adjustments ✿ ʕ •ᴥ•ʔ
local function applyDimensionSettings()
	if not ScootsStats or not ScootsStats.frames or not ScootsStats.frames.master then return end

	local f = ScootsStats.frames

	-- Guard to avoid infinite loops when this function itself triggers SetPoint
	if f._dimensionApplying then return end

	f._dimensionApplying = true

	-- Width - let ScootsStats handle its own width calculations since it includes scrollbar logic
	local customWidth = tonumber(E.db and E.db.addOnSkins and E.db.addOnSkins.scootStatsWidth)
	if customWidth and customWidth > 0 then
		-- Apply user-defined width to the master frame
		f.master:SetWidth(customWidth)
	end

	-- Whether or not a custom width exists, calculate current content width
	local effectiveWidth = f.master:GetWidth() or customWidth or 0
	local contentWidth = math.max(0, effectiveWidth - 30) -- Space for scrollbar + padding

	-- Propagate width to section and row frames
	if ScootsStats.sectionFrames then
		for _, sFrame in pairs(ScootsStats.sectionFrames) do
			sFrame:SetWidth(contentWidth)
		end
	end
	if ScootsStats.rowFrames then
		for _, rFrame in pairs(ScootsStats.rowFrames) do
			rFrame:SetWidth(contentWidth)
			if rFrame.bgStripe then rFrame.bgStripe:SetAllPoints() end
		end
	end

	-- Horizontal offset relative to CharacterFrame right edge
	local offsetX = tonumber(E.db and E.db.addOnSkins and E.db.addOnSkins.scootStatsXOffset)
	if offsetX == nil then offsetX = -30 end

	if characterFrame then
		f.master:ClearAllPoints()
		f.master:SetPoint('TOPLEFT', characterFrame, 'TOPRIGHT', offsetX, -12)
	end

	-- Force scrollbar visibility after dimension changes
	ensureScrollBarVisible()

	f._dimensionApplying = false
end

-- ʕ •ᴥ•ʔ✿ Style scrollbar components ✿ ʕ •ᴥ•ʔ
local function styleScrollBar(f)
	if not f then return false end
	
	-- Check if scrollbar exists before trying to style it
	local scrollBarExists = false
	
	-- Try multiple ways to find the scrollbar
	if f.scrollBar then
		scrollBarExists = true
	elseif _G.ScootsStatsScrollFrameScrollBar then
		f.scrollBar = _G.ScootsStatsScrollFrameScrollBar
		scrollBarExists = true
	end
	
	if not scrollBarExists then
		return false -- Scrollbar doesn't exist yet
	end
	
	-- Force show the scrollbar first
	if not ensureScrollBarVisible() then
		return false
	end
	
	-- ʕ •ᴥ•ʔ✿ Break potential circular anchoring before styling ✿ ʕ •ᴥ•ʔ
	if f.scrollBar then
		f.scrollBar:ClearAllPoints()
		if f.scrollFrame then
			f.scrollBar:SetPoint('TOPRIGHT', f.master or f.scrollFrame, 'TOPRIGHT', -2, 0)
			f.scrollBar:SetPoint('BOTTOMRIGHT', f.master or f.scrollFrame, 'BOTTOMRIGHT', -2, 0)
		end
	end

	-- ʕ ◕ᴥ◕ ʔ✿ Safely apply ElvUI default styling ✿ ʕ ◕ᴥ◕ ʔ
	local ok = pcall(function() S:HandleScrollBar(f.scrollBar) end)

	-- Fallback manual styling if dependency error persists
	if not ok then
		if f.scrollUpButton then S:HandleNextPrevButton(f.scrollUpButton) end
		if f.scrollDownButton then S:HandleNextPrevButton(f.scrollDownButton) end
	end
	
	-- Ensure buttons and scrollbar have final positioning without circular anchors
	if f.scrollUpButton then f.scrollUpButton:ClearAllPoints() end
	if f.scrollDownButton then f.scrollDownButton:ClearAllPoints() end

	if f.scrollUpButton and f.master then
		f.scrollUpButton:SetPoint('TOPRIGHT', f.master, 'TOPRIGHT', -2, -2)
	end
	if f.scrollDownButton and f.master then
		f.scrollDownButton:SetPoint('BOTTOMRIGHT', f.master, 'BOTTOMRIGHT', -2, 2)
	end

	-- Re-affirm scrollbar anchoring to the master frame
	if f.master then
		f.scrollBar:ClearAllPoints()
		f.scrollBar:SetPoint('TOPRIGHT', f.master, 'TOPRIGHT', -2, 0)
		f.scrollBar:SetPoint('BOTTOMRIGHT', f.master, 'BOTTOMRIGHT', -2, 0)
	end

	-- Mark scroll buttons as styled to avoid redundant processing
	if f.scrollUpButton then f.scrollUpButton.isStyled = true end
	if f.scrollDownButton then f.scrollDownButton.isStyled = true end

	f.scrollBar.isStyled = true
end

local function attemptScrollBarStyling(retryCount)
	retryCount = retryCount or 0
	
	if not ScootsStats or not ScootsStats.frames then
		if retryCount < 10 then
			E:Delay(0.1, function()
				attemptScrollBarStyling(retryCount + 1)
			end)
		end
		return
	end
	
	-- Try to style the scrollbar
	if styleScrollBar(ScootsStats.frames) then
		-- Success! Scrollbar was styled
		return
	else
		-- Scrollbar doesn't exist yet, retry if we haven't exceeded max attempts
		if retryCount < 20 then -- Increased retry count
			E:Delay(0.1, function()
				attemptScrollBarStyling(retryCount + 1)
			end)
		end
	end
end

-- ʕ •ᴥ•ʔ✿ ScootsStats Skin ✿ ʕ •ᴥ•ʔ
S:AddCallbackForAddon("ScootsStats", "ScootsStats", function()
	if not E.private.addOnSkins.ScootsStats then return end
	
	-- Initialize cached values
	updateCachedValues()
	
	-- Expose updater so the options panel (or other modules) can refresh styling on the fly
	AS.updateScootStatsConfig = updateScootStatsConfig

	local function styleMain()
		if not ScootsStats or not ScootsStats.frames then return end
		
		-- Cache frame references at start
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
	
		-- Try to style scrollbar, but don't fail if it doesn't exist yet
		if not styleScrollBar(f) then
			-- Scrollbar doesn't exist yet, start retry mechanism
			attemptScrollBarStyling()
		end
	
		-- Style the options button
		if f.optionsButton and not f.optionsButton.isStyled then
			S:HandleButton(f.optionsButton)
			f.optionsButton.isStyled = true
		end
	
		-- Style the title elements (move up & enlarge)
		if f.title and f.title.text then
			local titleFontSize = math.max(14, GetFontSize())
			f.title.text:FontTemplate(nil, titleFontSize, "OUTLINE")

			-- Move the title frame closer to the top edge
			f.title:ClearAllPoints()
			f.title:SetPoint('TOPLEFT', f.master, 'TOPLEFT', 6, -6)
			f.title:SetHeight(titleFontSize + 4)

			-- Style the version title and version text as well (scale accordingly)
			if f.title.versionTitle then
				local versionFontSize = math.max(10, titleFontSize - 4)
				f.title.versionTitle:FontTemplate(nil, versionFontSize, "OUTLINE")
			end
			
			if f.title.version then
				local versionFontSize = math.max(10, titleFontSize - 4)
				f.title.version:FontTemplate(nil, versionFontSize, "OUTLINE")
			end
		end
	
		-- INSTANT adjustments - no delays
		adjustFrameHeights()
		applyDimensionSettings()
	
		-- Reset row counter for fresh styling
		rowCounter = 0
	
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
				-- INSTANT - no delays
				styleMain()
				adjustFrameHeights()
				ensureScrollBarVisible()
			end)
		end

		-- Hook the updateStats function to restyle frames as they're created
		if ScootsStats.updateStats then
			S:SecureHook(ScootsStats, "updateStats", function()
				-- Hide background each update
				if ScootsStats.frames and ScootsStats.frames.background then
					ScootsStats.frames.background:Hide()
				end
				
				-- Try to style scrollbar, start retry if it fails
				if ScootsStats.frames then
					if not styleScrollBar(ScootsStats.frames) then
						attemptScrollBarStyling()
					end
				end
				
				-- INSTANT adjustments
				adjustFrameHeights()
				
				-- Batch only the row/section styling (non-critical for resize)
				batchOperation(function()
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
				end)
				
				-- INSTANT dimension changes
				applyDimensionSettings()
			end)
		end

		-- Hook the toggleOptionsPanel function
		if ScootsStats.toggleOptionsPanel then
			S:SecureHook(ScootsStats, "toggleOptionsPanel", function()
				batchOperation(styleOptionsPanel)
			end)
		end

		-- More specific CreateFrame hook for better performance
		local originalCreateFrame = CreateFrame
		CreateFrame = function(frameType, name, parent, ...)
			local frame = originalCreateFrame(frameType, name, parent, ...)
			
			if name and parent and ScootsStats.frames and parent == ScootsStats.frames.scrollChild then
				if string.find(name, "ScootsStatsSectionHead", 1, true) then
					batchOperation(function()
						if frame and frame.text then
							restyleHeader(frame)
						end
					end)
				elseif string.find(name, "ScootsStatsRow", 1, true) then
					batchOperation(function()
						if frame then
							restyleRow(frame)
						end
					end)
				end
			end
			
			return frame
		end
		
		-- Hook CharacterFrame show/hide events to maintain height matching
		if characterFrame then
			S:SecureHookScript(characterFrame, "OnShow", function()
				-- INSTANT - no delays
				adjustFrameHeights()
				applyDimensionSettings()
				ensureScrollBarVisible()
			end)
			
			S:SecureHookScript(characterFrame, "OnSizeChanged", function()
				-- INSTANT - no delays
				adjustFrameHeights()
				applyDimensionSettings()
			end)
		end
	end
	
	-- Reduced fallback delay
	E:Delay(0.5, function()
		if ScootsStats and ScootsStats.frames and ScootsStats.frames.master then
			styleMain()
		end
	end)

	-- INSTANT SetPoint hook - no throttling for resize operations
	E:Delay(0.1, function() -- Give ScootsStats time to initialize
		if ScootsStats and ScootsStats.frames and ScootsStats.frames.master then
			local master = ScootsStats.frames.master
			if not master._elvuiHooked then
				-- React to external position adjustments
				hooksecurefunc(master, "SetPoint", function()
					applyDimensionSettings()
					ensureScrollBarVisible()
				end)
				-- React to width changes issued by ScootsStats.updateStats
				hooksecurefunc(master, "SetWidth", function()
					applyDimensionSettings()
				end)
				master._elvuiHooked = true
			end
		end
	end)
end)

-- ʕ •ᴥ•ʔ✿ INSTANT config updater ✿ ʕ •ᴥ•ʔ
function updateScootStatsConfig()
	if not ScootsStats then return end

	-- Update cached values first
	updateCachedValues()
	
	-- INSTANT adjustments - no batching for critical operations
	if ScootsStats.frames.master:IsShown() then
		-- Reset row counter for fresh styling
		rowCounter = 0

		-- Restyle in batches (non-critical)
		batchOperation(function()
			if ScootsStats.rowFrames then
				for _, r in pairs(ScootsStats.rowFrames) do
					r.isStyled = nil
					r._rowIndex = nil -- Clear cached row index
					restyleRow(r)
				end
			end

			if ScootsStats.sectionFrames then
				for _, s in pairs(ScootsStats.sectionFrames) do
					if s.text then s.text.isStyled = nil end
					restyleHeader(s)
				end
			end
		end)

		-- INSTANT scrollbar and dimension updates
		ensureScrollBarVisible()
		if ScootsStats.frames then
			styleScrollBar(ScootsStats.frames)
		end
		applyDimensionSettings()
		ensureScrollBarVisible()
	end
end