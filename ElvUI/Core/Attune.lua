local E, L, V, P, G = unpack(ElvUI);
local B = E:GetModule("Bags")

Attune = {}

-- ʕ •ᴥ•ʔ✿ Performance caches ✿ ʕ •ᴥ•ʔ
local itemInfoCache = {}
local itemValidCache = {}
local apiAvailable = nil
local colorCache = {}

function Attune:AddAtuneIcon(slot)
	if not slot.AttuneTextureBorder then
		local AttuneTextureBorder = slot:CreateTexture(nil, "ARTWORK")
		AttuneTextureBorder:SetTexture(E.Media.Textures.AttuneIconWhite)
		AttuneTextureBorder:SetVertexColor(0, 0, 0)
		AttuneTextureBorder:Hide()
		slot.AttuneTextureBorder = AttuneTextureBorder
	end

	if not slot.AttuneTexture then
		local AttuneTexture = slot:CreateTexture(nil, "OVERLAY")
		AttuneTexture:SetTexture(E.Media.Textures.AttuneIconWhite)
		AttuneTexture:Hide()
		slot.AttuneTexture = AttuneTexture
	end
end

local function ExtractItemId(itemIdOrLink)
	if not(ItemLocIsLoaded()) or not(CustomExtractItemId) then 
		-- ʕ •ᴥ•ʔ✿ Handle both numbers and strings manually ✿ ʕ •ᴥ•ʔ
		if type(itemIdOrLink) == 'number' then
			return itemIdOrLink
		elseif type(itemIdOrLink) == 'string' then
			return tonumber(itemIdOrLink:match('item:(%d+)'))
		end
		return nil
	end
	return CustomExtractItemId(itemIdOrLink) or nil
end

-- ʕ •ᴥ•ʔ✿ Wrapper around the native CanAttuneItemHelper API (mirrors old CheckItemValid) ✿ ʕ •ᴥ•ʔ
local function CheckItemValid(itemIdOrLink)
	-- ʕ •ᴥ•ʔ✿ Cache API availability check ✿ ʕ •ᴥ•ʔ
	if apiAvailable == nil then
		apiAvailable = CanAttuneItemHelper ~= nil
	end
	if not apiAvailable then return 0 end
	
	local itemId = ExtractItemId(itemIdOrLink)
	if not itemId then return 0 end
	
	-- ʕ •ᴥ•ʔ✿ Cache validation results ✿ ʕ •ᴥ•ʔ
	if itemValidCache[itemId] == nil then
		itemValidCache[itemId] = CanAttuneItemHelper(itemId)
	end
	return itemValidCache[itemId]
end

-- ʕ •ᴥ•ʔ✿ Wrapper around native attunement-progress APIs ✿ ʕ •ᴥ•ʔ
local function GetAttuneProgress(itemIdOrLink)
	if type(itemIdOrLink) == 'string' and GetItemLinkAttuneProgress then
		local progress = GetItemLinkAttuneProgress(itemIdOrLink)
		if type(progress) == 'number' then return progress end
	end

	local itemId = ExtractItemId(itemIdOrLink)
	if itemId and GetItemAttuneProgress then
		local progress = GetItemAttuneProgress(itemId)
		if type(progress) == 'number' then return progress end
	end

	return 0
end

-- ʕ •ᴥ•ʔ✿ Simple flag indicating whether required native APIs are present ✿ ʕ •ᴥ•ʔ
local function IsServerApiLoaded()
	if apiAvailable == nil then
		apiAvailable = CanAttuneItemHelper ~= nil
	end
	return apiAvailable
end

-- ʕ •ᴥ•ʔ✿ Cache color settings for better performance ✿ ʕ •ᴥ•ʔ
local function GetColorSettings()
	if not colorCache.lastUpdate or colorCache.lastUpdate ~= E.db.attune then
		colorCache = {
			invalid = E.db.attune.colors.invalid,
			inProgress = E.db.attune.colors.inProgress,
			completed = E.db.attune.colors.completed,
			lastUpdate = E.db.attune
		}
	end
	return colorCache
end

-- ʕ •ᴥ•ʔ✿ Check if slot should show attune icons ✿ ʕ •ᴥ•ʔ
local function ShouldShowAttuneIcon(slot)
	local parent = slot:GetParent()
	if not parent then return true end
	
	local parentName = parent:GetName()
	if not parentName then return true end
	
	-- ʕ •ᴥ•ʔ✿ More efficient string matching ✿ ʕ •ᴥ•ʔ
	if parentName:find("Bank", 1, true) then
		return E.db.attune.showInBank
	elseif parentName:find("Bag", 1, true) then
		return E.db.attune.showInBags
	end
	
	return true
end

function Attune:ToggleAttuneIcon(slot, itemIdOrLink, additionalXMargin)
	Attune:UpdateItemLevelText(slot, itemIdOrLink)
	Attune:AddAtuneIcon(slot)
	slot.AttuneTexture:Hide()
	slot.AttuneTextureBorder:Hide()
	
	-- ʕ •ᴥ•ʔ✿ Debug: Check what's happening ✿ ʕ •ᴥ•ʔ
	local serverApiLoaded = IsServerApiLoaded()
	local attuneEnabled = E.db.attune and E.db.attune.enabled
	local hasItem = itemIdOrLink ~= nil
	
	if not serverApiLoaded then
		print("DEBUG: Server API not loaded")
		return
	end
	if not attuneEnabled then
		print("DEBUG: Attune not enabled in settings")
		return
	end
	if not hasItem then
		print("DEBUG: No item provided")
		return
	end
	
	if not ShouldShowAttuneIcon(slot) then
		print("DEBUG: Slot should not show attune icon")
		return
	end
	
	-- ʕ •ᴥ•ʔ✿ Single call to CheckItemValid ✿ ʕ •ᴥ•ʔ
	local itemValidStatus = CheckItemValid(itemIdOrLink)
	print("DEBUG: Item", itemIdOrLink, "has valid status:", itemValidStatus)
	if itemValidStatus == 0 then
		return
	end

	-- ʕ •ᴥ•ʔ✿ Cache margin calculations ✿ ʕ •ᴥ•ʔ
	local xMargin = 2 + (additionalXMargin or 0)
	local yMargin = 2
	local borderWidth = 1
	local maxHeight = slot:GetHeight() - (yMargin * 2 + borderWidth * 2)
	local minHeight = maxHeight * 0.2
	local width = 8 - borderWidth * 2
	local colors = GetColorSettings()

	slot.AttuneTextureBorder:SetPoint("BOTTOMLEFT", xMargin, yMargin)
	slot.AttuneTextureBorder:SetWidth(width + borderWidth * 2)
	slot.AttuneTexture:SetPoint("BOTTOMLEFT", xMargin + borderWidth, yMargin + borderWidth)
	slot.AttuneTexture:SetWidth(width)

	if itemValidStatus == -2 then
		slot.AttuneTextureBorder:SetHeight(minHeight + borderWidth*2)
		slot.AttuneTexture:SetHeight(minHeight)
		slot.AttuneTexture:SetVertexColor(colors.invalid.r, colors.invalid.g, colors.invalid.b)
		slot.AttuneTextureBorder:Show()
		slot.AttuneTexture:Show()
	elseif itemValidStatus == 1 then
		local progress = GetAttuneProgress(itemIdOrLink)
		if progress < 100 then
			local height = math.max(maxHeight * (progress/100), minHeight)
			slot.AttuneTextureBorder:SetHeight(height + borderWidth*2)
			slot.AttuneTexture:SetHeight(height)
			slot.AttuneTexture:SetVertexColor(colors.inProgress.r, colors.inProgress.g, colors.inProgress.b)
		else
			slot.AttuneTextureBorder:SetHeight(maxHeight + borderWidth*2)
			slot.AttuneTexture:SetHeight(maxHeight)
			slot.AttuneTexture:SetVertexColor(colors.completed.r, colors.completed.g, colors.completed.b)
		end
		slot.AttuneTextureBorder:Show()
		slot.AttuneTexture:Show()
	end
end

function Attune:UpdateItemLevelText(slot, itemIdOrLink)
	if not slot.itemLevel then
		slot.itemLevel = slot:CreateFontString(nil, "OVERLAY")
		slot.itemLevel:Point("BOTTOMRIGHT", -1, 3)
		slot.itemLevel:FontTemplate(E.Libs.LSM:Fetch("font", E.db.bags.itemLevelFont), E.db.bags.itemLevelFontSize,
			E.db.bags.itemLevelFontOutline)
	end
	slot.itemLevel:SetText("")

	if itemIdOrLink then
		-- ʕ •ᴥ•ʔ✿ Cache GetItemInfo results ✿ ʕ •ᴥ•ʔ
		local itemId = ExtractItemId(itemIdOrLink)
		if itemId and not itemInfoCache[itemId] then
			local _, _, itemRarity, iLvl, _, _, _, _, itemEquipLoc, _, _ = GetItemInfo(itemIdOrLink)
			itemInfoCache[itemId] = {
				rarity = itemRarity,
				level = iLvl,
				equipLoc = itemEquipLoc
			}
		end
		
		if itemId and itemInfoCache[itemId] then
			local cached = itemInfoCache[itemId]
			if cached.level and B.db.itemLevel and 
			   (cached.equipLoc and cached.equipLoc ~= "" and cached.equipLoc ~= "INVTYPE_AMMO" and 
			    cached.equipLoc ~= "INVTYPE_BAG" and cached.equipLoc ~= "INVTYPE_QUIVER" and cached.equipLoc ~= "INVTYPE_TABARD") and 
			   (cached.rarity and cached.rarity > 1) and cached.level >= B.db.itemLevelThreshold then
				slot.itemLevel:SetText(cached.level)
				if B.db.itemLevelCustomColorEnable then
					slot.itemLevel:SetTextColor(B.db.itemLevelCustomColor.r, B.db.itemLevelCustomColor.g, B.db.itemLevelCustomColor.b)
				else
					slot.itemLevel:SetTextColor(GetItemQualityColor(cached.rarity))
				end
			end
		end
	end
end

-- ʕ •ᴥ•ʔ✿ Clear caches when settings change ✿ ʕ •ᴥ•ʔ
function Attune:ClearCaches()
	wipe(itemInfoCache)
	wipe(itemValidCache)
	colorCache = {}
	apiAvailable = nil
	print("DEBUG: Attune caches cleared, API availability reset")
end

-- ʕ •ᴥ•ʔ✿ Debug function to check current status ✿ ʕ •ᴥ•ʔ
function Attune:DebugStatus()
	print("=== ATTUNE DEBUG STATUS ===")
	print("Server API loaded:", IsServerApiLoaded())
	print("CanAttuneItemHelper exists:", CanAttuneItemHelper ~= nil)
	print("GetItemAttuneProgress exists:", GetItemAttuneProgress ~= nil)
	print("GetItemLinkAttuneProgress exists:", GetItemLinkAttuneProgress ~= nil)
	print("ItemLocIsLoaded exists:", ItemLocIsLoaded ~= nil)
	print("CustomExtractItemId exists:", CustomExtractItemId ~= nil)
	if E.db.attune then
		print("Attune enabled:", E.db.attune.enabled)
		print("Show in bags:", E.db.attune.showInBags)
		print("Show in bank:", E.db.attune.showInBank)
	else
		print("E.db.attune is nil!")
	end
	print("API available cache:", apiAvailable)
	print("========================")
end

-- ʕ •ᴥ•ʔ✿ Slash commands for debugging ✿ ʕ •ᴥ•ʔ
SLASH_ATTUNEDEBUG1 = "/attunedebug"
SlashCmdList["ATTUNEDEBUG"] = function()
	Attune:DebugStatus()
end

SLASH_ATTUNECLEAR1 = "/attuneclear"
SlashCmdList["ATTUNECLEAR"] = function()
	Attune:ClearCaches()
end