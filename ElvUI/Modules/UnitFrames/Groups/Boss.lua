local E, L, V, P, G = unpack(select(2, ...)); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local UF = E:GetModule("UnitFrames")
local _, ns = ...
local ElvUF = ns.oUF
assert(ElvUF, "ElvUI was unable to locate oUF.")

--Lua functions
local _G = _G
--WoW API / Variables
MAX_BOSS_FRAMES = 9
local MAX_BOSS_FRAMES = MAX_BOSS_FRAMES

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")

f:SetScript("OnEvent", function(self, event)
    local delay = 1 -- Delay in seconds
    local elapsed = 0

    self:SetScript("OnUpdate", function(self, delta)
        elapsed = elapsed + delta
        if elapsed >= delay then
            self:SetScript("OnUpdate", nil) -- Stop running OnUpdate

            for i = 1, MAX_BOSS_FRAMES do
                local frame = _G["Boss"..i.."TargetFrame"]
                if frame then
                    frame:Hide()
                    frame.Show = frame.Hide -- Prevent it from being shown again
                end
            end
        end
    end)
end)

local BossHeader = CreateFrame("Frame", "BossHeader", UIParent)
BossHeader:SetFrameStrata("LOW")

function UF:Construct_BossFrames(frame)
	frame.RaisedElementParent = CreateFrame("Frame", nil, frame)
	frame.RaisedElementParent.TextureParent = CreateFrame("Frame", nil, frame.RaisedElementParent)
	frame.RaisedElementParent:SetFrameLevel(frame:GetFrameLevel() + 100)

	frame.Health = self:Construct_HealthBar(frame, true, true, "RIGHT")

	frame.Power = self:Construct_PowerBar(frame, true, true, "LEFT")

	frame.Name = self:Construct_NameText(frame)

	frame.Portrait3D = self:Construct_Portrait(frame, "model")
	frame.Portrait2D = self:Construct_Portrait(frame, "texture")
	frame.InfoPanel = self:Construct_InfoPanel(frame)
	frame.Buffs = self:Construct_Buffs(frame)

	frame.Debuffs = self:Construct_Debuffs(frame)
	frame.DebuffHighlight = self:Construct_DebuffHighlight(frame)

	frame.Castbar = self:Construct_Castbar(frame)
	frame.RaidTargetIndicator = self:Construct_RaidIcon(frame)
	frame.Fader = self:Construct_Fader()
	frame.Cutaway = self:Construct_Cutaway(frame)
	frame.MouseGlow = self:Construct_MouseGlow(frame)
	frame.TargetGlow = self:Construct_TargetGlow(frame)
	frame:SetAttribute("type2", "focus")
	frame.customTexts = {}

	BossHeader:Point("BOTTOMRIGHT", E.UIParent, "RIGHT", -105, -165)
	E:CreateMover(BossHeader, BossHeader:GetName().."Mover", L["Boss Frames"], nil, nil, nil, "ALL,PARTY,RAID", nil, "unitframe,boss,generalGroup")
	frame.mover = BossHeader.mover

	frame.unitframeType = "boss"
end

function UF:Update_BossFrames(frame, db)
	frame.db = db

	do
		frame.ORIENTATION = db.orientation --allow this value to change when unitframes position changes on screen?
		frame.UNIT_WIDTH = db.width
		frame.UNIT_HEIGHT = db.infoPanel.enable and (db.height + db.infoPanel.height) or db.height

		frame.USE_POWERBAR = db.power.enable
		frame.POWERBAR_DETACHED = db.power.detachFromFrame
		frame.USE_INSET_POWERBAR = not frame.POWERBAR_DETACHED and db.power.width == "inset" and frame.USE_POWERBAR
		frame.USE_MINI_POWERBAR = (not frame.POWERBAR_DETACHED and db.power.width == "spaced" and frame.USE_POWERBAR)
		frame.USE_POWERBAR_OFFSET = db.power.offset ~= 0 and frame.USE_POWERBAR and not frame.POWERBAR_DETACHED
		frame.POWERBAR_OFFSET = frame.USE_POWERBAR_OFFSET and db.power.offset or 0

		frame.POWERBAR_HEIGHT = not frame.USE_POWERBAR and 0 or db.power.height
		frame.POWERBAR_WIDTH = frame.USE_MINI_POWERBAR and (frame.UNIT_WIDTH - (frame.BORDER*2))/2 or (frame.POWERBAR_DETACHED and db.power.detachedWidth or (frame.UNIT_WIDTH - ((frame.BORDER+frame.SPACING)*2)))

		frame.USE_PORTRAIT = db.portrait and db.portrait.enable
		frame.USE_PORTRAIT_OVERLAY = frame.USE_PORTRAIT and (db.portrait.overlay or frame.ORIENTATION == "MIDDLE")
		frame.PORTRAIT_WIDTH = (frame.USE_PORTRAIT_OVERLAY or not frame.USE_PORTRAIT) and 0 or db.portrait.width

		frame.USE_INFO_PANEL = not frame.USE_MINI_POWERBAR and not frame.USE_POWERBAR_OFFSET and db.infoPanel.enable
		frame.INFO_PANEL_HEIGHT = frame.USE_INFO_PANEL and db.infoPanel.height or 0

		frame.BOTTOM_OFFSET = UF:GetHealthBottomOffset(frame)

		frame.VARIABLES_SET = true
	end

	frame.colors = ElvUF.colors
	frame.Portrait = frame.Portrait or (db.portrait.style == "2D" and frame.Portrait2D or frame.Portrait3D)
	frame:RegisterForClicks(self.db.targetOnMouseDown and "AnyDown" or "AnyUp")
	frame:Size(frame.UNIT_WIDTH, frame.UNIT_HEIGHT)
	UF:Configure_InfoPanel(frame)
	--Health
	UF:Configure_HealthBar(frame)

	--Name
	UF:UpdateNameSettings(frame)

	--Power
	UF:Configure_Power(frame)

	--Portrait
	UF:Configure_Portrait(frame)

	--Auras
	UF:EnableDisable_Auras(frame)
	UF:Configure_Auras(frame, "Buffs")
	UF:Configure_Auras(frame, "Debuffs")

	--Castbar
	UF:Configure_Castbar(frame)

	--Raid Icon
	UF:Configure_RaidIcon(frame)

	UF:Configure_DebuffHighlight(frame)

	UF:Configure_CustomTexts(frame)

	--Fader
	UF:Configure_Fader(frame)

	--Cutaway
	UF:Configure_Cutaway(frame)

	frame:ClearAllPoints()
	if frame.index == 1 then
		if db.growthDirection == "UP" then
			frame:Point("BOTTOMRIGHT", BossHeaderMover, "BOTTOMRIGHT")
		elseif db.growthDirection == "RIGHT" then
			frame:Point("LEFT", BossHeaderMover, "LEFT")
		elseif db.growthDirection == "LEFT" then
			frame:Point("RIGHT", BossHeaderMover, "RIGHT")
		else --Down
			frame:Point("TOPRIGHT", BossHeaderMover, "TOPRIGHT")
		end
	else
		if db.growthDirection == "UP" then
			frame:Point("BOTTOMRIGHT", _G["ElvUF_Boss"..frame.index-1], "TOPRIGHT", 0, db.spacing)
		elseif db.growthDirection == "RIGHT" then
			frame:Point("LEFT", _G["ElvUF_Boss"..frame.index-1], "RIGHT", db.spacing, 0)
		elseif db.growthDirection == "LEFT" then
			frame:Point("RIGHT", _G["ElvUF_Boss"..frame.index-1], "LEFT", -db.spacing, 0)
		else --Down
			frame:Point("TOPRIGHT", _G["ElvUF_Boss"..frame.index-1], "BOTTOMRIGHT", 0, -db.spacing)
		end
	end

	if db.growthDirection == "UP" or db.growthDirection == "DOWN" then
		BossHeader:Width(frame.UNIT_WIDTH)
		BossHeader:Height(frame.UNIT_HEIGHT + ((frame.UNIT_HEIGHT + db.spacing) * (MAX_BOSS_FRAMES -1)))
	elseif db.growthDirection == "LEFT" or db.growthDirection == "RIGHT" then
		BossHeader:Width(frame.UNIT_WIDTH + ((frame.UNIT_WIDTH + db.spacing) * (MAX_BOSS_FRAMES -1)))
		BossHeader:Height(frame.UNIT_HEIGHT)
	end

	frame:UpdateAllElements("ForceUpdate")
end

UF.unitgroupstoload.boss = {MAX_BOSS_FRAMES}