local E, _, V, P, G = unpack(ElvUI) --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local C, L = unpack(select(2, ...))

E.Options.args.attune = {
	order = 15,
	type = "group",
	name = L["Attunement Display"],
	childGroups = "tab",
	args = {
		header = {
			order = 1,
			type = "header",
			name = L["Attune"]
		},
		general = {
			order = 2,
			type = "group",
			name = L["General"],
			args = {
				header = {
					order = 1,
					type = "header",
					name = L["General"]
				},
				attuneProgress = {
					order = 2,
					type = "toggle",
					name = L["Display Attune Icons"],
					desc = L["Displays attune progress on the item icon in bags/bank/character sheet."],
					get = function(info) return E.db.attune.enabled end,
					set = function(info, value) 
						E.db.attune.enabled = value 
						if E.Bags.Initialized then
							E:GetModule("Bags"):UpdateAllBagSlots()
						end
					end
				},
				spacer = {
					order = 3,
					type = "description",
					name = ""
				},
				showInBags = {
					order = 4,
					type = "toggle",
					name = L["Show in Bags"],
					desc = L["Display attune progress in bag slots."],
					get = function(info) return E.db.attune.showInBags end,
					disabled = function() return not E.db.attune.enabled end,
					set = function(info, value) 
						E.db.attune.showInBags = value 
						if E.Bags.Initialized then
							E:GetModule("Bags"):UpdateAllBagSlots()
						end
					end
				},
				showInBank = {
					order = 5,
					type = "toggle",
					name = L["Show in Bank"],
					desc = L["Display attune progress in bank slots."],
					get = function(info) return E.db.attune.showInBank end,
					disabled = function() return not E.db.attune.enabled end,
					set = function(info, value) 
						E.db.attune.showInBank = value 
						if E.Bags.Initialized then
							E:GetModule("Bags"):UpdateAllBagSlots()
						end
					end
				}
			}
		},
		colors = {
			order = 3,
			type = "group",
			name = L["Colors"],
			args = {
				header = {
					order = 1,
					type = "header",
					name = L["Colors"]
				},
				invalid = {
					order = 2,
					type = "color",
					name = L["Invalid Items"],
					desc = L["Color for items that cannot be attuned."],
					disabled = function() return not E.db.attune.enabled end,
					get = function(info)
						local t = E.db.attune.colors.invalid
						local d = P.attune.colors.invalid
						return t.r, t.g, t.b, t.a, d.r, d.g, d.b
					end,
					set = function(info, r, g, b)
						local t = E.db.attune.colors.invalid
						t.r, t.g, t.b = r, g, b
						if E.Bags.Initialized then
							E:GetModule("Bags"):UpdateAllBagSlots()
						end
					end
				},
				inProgress = {
					order = 3,
					type = "color",
					name = L["In Progress"],
					desc = L["Color for items currently being attuned."],
					disabled = function() return not E.db.attune.enabled end,
					get = function(info)
						local t = E.db.attune.colors.inProgress
						local d = P.attune.colors.inProgress
						return t.r, t.g, t.b, t.a, d.r, d.g, d.b
					end,
					set = function(info, r, g, b)
						local t = E.db.attune.colors.inProgress
						t.r, t.g, t.b = r, g, b
						if E.Bags.Initialized then
							E:GetModule("Bags"):UpdateAllBagSlots()
						end
					end
				},
				completed = {
					order = 4,
					type = "color",
					name = L["Completed"],
					desc = L["Color for fully attuned items."],
					disabled = function() return not E.db.attune.enabled end,
					get = function(info)
						local t = E.db.attune.colors.completed
						local d = P.attune.colors.completed
						return t.r, t.g, t.b, t.a, d.r, d.g, d.b
					end,
					set = function(info, r, g, b)
						local t = E.db.attune.colors.completed
						t.r, t.g, t.b = r, g, b
						if E.Bags.Initialized then
							E:GetModule("Bags"):UpdateAllBagSlots()
						end
					end
				}
			}
		}
	}
} 