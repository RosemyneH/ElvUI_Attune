local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule("Skins")
local AS = E:GetModule("AddOnSkins")

if not AS:IsAddonLODorEnabled("ScootsStats") then return end

local function restyleRow(row)
	if not row or row.isStyled then return end
	
	local name = row:GetName()
	if not name then return end
	
	local label = _G[name .. "Label"]
	local stat = _G[name .. "StatText"]
	
	if label then
		label:FontTemplate(nil, 16, "OUTLINE")
		label:ClearAllPoints()
		label:SetPoint("LEFT", row, "LEFT", 6, 0)
	end
	if stat then
		stat:FontTemplate(nil, 16, "OUTLINE")
		stat:ClearAllPoints()
		stat:SetPoint("RIGHT", row, "RIGHT", -6, 0)
	end
	row:SetHeight(16)
	row.isStyled = true
end

local function restyleHeader(frame)
	if frame and frame.text and not frame.text.isStyled then
		frame.text:FontTemplate(nil, 16, "OUTLINE")
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
end

-- ʕ •ᴥ•ʔ✿ ScootsStats Skin ✿ ʕ •ᴥ•ʔ
S:AddCallbackForAddon("ScootsStats", "ScootsStats", function()
	if not E.private.addOnSkins.ScootsStats then return end

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
			f.title.text:FontTemplate(nil, 12, "OUTLINE")
		end

		-- Adjust frame heights to match CharacterFrame
		adjustFrameHeights()

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
end) 