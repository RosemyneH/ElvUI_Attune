local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule("Skins")
local AS = E:GetModule("AddOnSkins")

if not AS:IsAddonLODorEnabled("ScootsStats") then return end

local function restyleRow(row)
	if not row or row.isStyled then return end
	local label = _G[row:GetName() .. "Label"]
	local stat = _G[row:GetName() .. "StatText"]
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

-- ʕ •ᴥ•ʔ✿ ScootsStats Skin ✿ ʕ •ᴥ•ʔ
S:AddCallbackForAddon("ScootsStats", "ScootsStats", function()
	if not E.private.addOnSkins.ScootsStats then return end

	local function styleMain()
		local f = ScootsStats and ScootsStats.frames
		if not f or not f.master then return end

		if f.background and f.background:IsShown() then
			f.background:Hide()
			if f.background.texture then
				f.background.texture:SetTexture(nil)
			end
		end

		if f.master.SetTemplate then
			f.master:StripTextures()
			f.master:SetTemplate("Transparent")
		end

		if f.scrollChild and f.scrollChild.SetTemplate then
			f.scrollChild:StripTextures()
			f.scrollChild:SetTemplate("Transparent")
		end

		-- Minimal styling for scroll bar to avoid re-anchoring issues
		if f.scrollBar and not f.scrollBar.isStyled then
			f.scrollBar:StripTextures()
			f.scrollBar:SetTemplate("Transparent")
			f.scrollUpButton:StripTextures()
			S:HandleNextPrevButton(f.scrollUpButton)
			f.scrollDownButton:StripTextures()
			S:HandleNextPrevButton(f.scrollDownButton)
			f.scrollBar.isStyled = true
		end

		if f.optionsButton then
			S:HandleButton(f.optionsButton)
		end

		-- options panel (may be created later)
		if f.options and not f.options.isStyled then
			f.options:StripTextures()
			f.options:SetTemplate("Transparent")
			f.options.isStyled = true
		end

		-- Adjust title font
		if f.title and f.title.text then
			f.title.text:FontTemplate(nil, 12, "OUTLINE")
		end
		
		-- Adjust positioning and sizing to fit within character frame
		if f.master then
			-- Make sure the master frame doesn't exceed character frame height
			local charFrame = _G['CharacterFrame']
			if charFrame then
				local maxHeight = charFrame:GetHeight() - 40 -- Leave some margin
				f.master:SetHeight(math.min(f.master:GetHeight(), maxHeight))
			end
			
			-- Adjust scroll frame height accordingly
			if f.scrollFrame then
				local newScrollHeight = f.master:GetHeight() - 34 - 10 -- Account for title and padding
				f.scrollFrame:SetHeight(newScrollHeight)
			end
			
			-- Store initial width to prevent combat resizing
			if not f.master.initialWidth then
				f.master.initialWidth = f.master:GetWidth()
			end
		end
		
		-- Adjust existing section header fonts
		if ScootsStats.sectionFrames then
			for _, sFrame in pairs(ScootsStats.sectionFrames) do
				restyleHeader(sFrame)
			end
		end
	end

	-- style immediately if already initialised
	if ScootsStats and ScootsStats.initialised then
		styleMain()
	end

	-- hook into init to style after frame creation
	if ScootsStats then
		S:SecureHook(ScootsStats, "init", function()
			styleMain()
		end)

		S:SecureHook(ScootsStats, "toggleOptionsPanel", function()
			local f = ScootsStats.frames
			if f and f.options and not f.options.isStyled then
				f.options:StripTextures()
				f.options:SetTemplate("Transparent")

				for _, toggle in pairs(ScootsStats.optionToggleFrames or {}) do
					if toggle and not toggle.isStyled then
						toggle:StripTextures()
						toggle:SetTemplate("Default")
						toggle.isStyled = true
					end
				end

				f.options.isStyled = true
			end
		end)

		S:SecureHook(ScootsStats, "updateStats", function()
			local f = ScootsStats.frames
			if f and f.background then f.background:Hide() end
			
			-- Constrain height to fit within character frame
			if f and f.master then
				local charFrame = _G['CharacterFrame']
				if charFrame then
					local maxHeight = charFrame:GetHeight() - 40
					if f.master:GetHeight() > maxHeight then
						f.master:SetHeight(maxHeight)
						if f.scrollFrame then
							local newScrollHeight = maxHeight - 34 - 10
							f.scrollFrame:SetHeight(newScrollHeight)
						end
					end
					
					-- Maintain consistent width (prevent combat state changes from resizing)
					if f.master.initialWidth and f.master:GetWidth() ~= f.master.initialWidth then
						f.master:SetWidth(f.master.initialWidth)
						if f.scrollFrame then
							f.scrollFrame:SetWidth(f.master.initialWidth - 10)
						end
						if f.scrollChild then
							f.scrollChild:SetWidth(f.master.initialWidth - 15)
						end
					end
				end
			end
			
			-- Restyle any new rows and section headers each update
			if ScootsStats.rowFrames then
				for _, r in pairs(ScootsStats.rowFrames) do
					restyleRow(r)
				end
			end
			if ScootsStats.sectionFrames then
				for _, s in pairs(ScootsStats.sectionFrames) do
					restyleHeader(s)
				end
			end
		end)

		-- Hook CreateFontString to override fonts for section headers
		hooksecurefunc("CreateFrame", function(frameType, name, parent)
			if name and string.find(name, "ScootsStatsSectionHead") then
				-- Wait a frame for the object to be fully created
				E:Delay(0.01, function()
					local frame = _G[name]
					if frame and frame.text then
						frame.text:FontTemplate(nil, 16, "OUTLINE")
					end
				end)
			end
		end)
	end
end) 