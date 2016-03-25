NOTES_DEBUG = nil; --Set to nil to not get debug shit

--Contains all the frames ever created, this is not to orphan any frames by mistake...
local AllFrames = {};

--Contains frames that are created but currently not used (Frames can't be deleted so we pool them to save space);
local FramePool = {};

QUESTIE_NOTES_MAP_ICON_SCALE = 1.2;-- Zone
QUESTIE_NOTES_WORLD_MAP_ICON_SCALE = 0.75;--Full world shown
QUESTIE_NOTES_CONTINENT_ICON_SCALE = 1;--Continent Shown
QUESTIE_NOTES_MINIMAP_ICON_SCALE = 1.0;
QuestieUsedNoteFrames = {};
QuestieHandledQuests = {};
QuestieCachedMonstersAndObjects = {};

function Questie:AddQuestToMap(questHash, redraw)
	if(Active == false) then
		return;
	end
	Questie:RemoveQuestFromMap(questHash);
	Objectives = Questie:AstroGetQuestObjectives(questHash);
	Questie:debug_Print("[AddQuestToMap] Adding quest", questHash);
	--Cache code
	local ques = {};
	ques["noteHandles"] = {};
	UsedContinents = {};
	UsedZones = {};
	local Quest = Questie:IsQuestFinished(questHash);
	if not (Quest) then
		for name, locations in pairs(Objectives['objectives']) do
			for k, location in pairs(locations) do
				--This checks if just THIS objective is done (Data is not super efficient but it's nil unless set so...)
				if not location.done then
					local MapInfo = Questie:GetMapInfoFromID(location.mapid);
					local notehandle = {};
					notehandle.c = MapInfo[4];
					notehandle.z = MapInfo[5];
					Questie:AddNoteToMap(MapInfo[4], MapInfo[5], location.x, location.y, location.type, questHash, location.objectiveid);
					if not UsedContinents[MapInfo[4]] and not UsedZones[MapInfo[5]] then
						UsedContinents[MapInfo[4]] = true;
						UsedZones[MapInfo[5]] = true;
						table.insert(ques["noteHandles"], notehandle);
					end
				end
			end
		end
	else
		--Quest Finished add finisher
		--QuestieFinishers var
		--QuestieMonsters var
		local finisher = nil;
		if( QuestieHashMap[Quest["questHash"]] and QuestieHashMap[Quest["questHash"]]['finishedBy']) then
			local finishMonster = QuestieHashMap[Quest["questHash"]]['finishedBy'];
			finisher = QuestieMonsters[finishMonster];
		end
		if(not finisher) then
			finisher = QuestieMonsters[QuestieFinishers[Quest["name"]]];
		end
		if(finisher) then
			local MapInfo = Questie:GetMapInfoFromID(finisher['locations'][1][1]);--Map id is at ID 1, i then convert this to a useful continent and zone
			local c, z, x, y = MapInfo[4], MapInfo[5], finisher['locations'][1][2],finisher['locations'][1][3]-- You just have to know about this, 2 is x 3 is y
			--The 1 is just the first locations as finisher only have one location
			--Questie:debug_Print("Quest finished",MapInfo[4], MapInfo[5]);
			Questie:AddNoteToMap(c,z, x, y, "complete", questHash, 0);
			local notehandle = {};
			notehandle.c = MapInfo[4];
			notehandle.z = MapInfo[5];
			table.insert(ques["noteHandles"], notehandle);
		else
			Questie:debug_Print("[AddQuestToMap] ERROR Quest broken! ", Quest["name"], questHash, "report on github!");
		end
	end
	--Cache code
	ques["objectives"] = Objectives;
	QuestieHandledQuests[questHash] = ques;
	if(redraw) then
		Questie:RedrawNotes();
	end
end

function Questie:UpdateQuestNotes(questHash, redraw)
	if not QuestieHandledQuests[questHash] then
		Questie:debug_Print("[UpdateQuestNotes] ERROR: Tried updating a quest not handled. ", questHash);
		return;
	end
	local QuestLogID = Questie:GetQuestIdFromHash(questHash);
	SelectQuestLogEntry(QuestLogID);
	local q, level, questTag, isHeader, isCollapsed, isComplete = QuestieCompat_GetQuestLogTitle(QuestLogID);
	local count =  GetNumQuestLeaderBoards();
	local questText, objectiveText = _GetQuestLogQuestText();
	for k, noteInfo in pairs(QuestieHandledQuests[questHash]["noteHandles"]) do
		for id, note in pairs(QuestieMapNotes[noteInfo.c][noteInfo.z]) do
			if(note.questHash == questHash) then
				local desc, typ, done = GetQuestLogLeaderBoard(note.objectiveid);
				Questie:debug_Print("[UpdateQuestNotes] ", tostring(desc),tostring(typ),tostring(done));
			end
		end
	end
	if(redraw) then
		Questie:RedrawNotes();
	end
end

GLOBALJAO = nil

function Questie:RemoveQuestFromMap(questHash, redraw)
	local removed = false;
	for continent, zoneTable in pairs(QuestieMapNotes) do
		for index, zone in pairs(zoneTable) do
			for i, note in pairs(zone) do
				if(note.questHash == questHash) then
					QuestieMapNotes[continent][index][i] = nil;
					removed = true;
				end
			end
		end
	end
	if(redraw) then
		Questie:RedrawNotes();
	end
	if(QuestieHandledQuests[questHash]) then
		QuestieHandledQuests[questHash] = nil;
	end
end

function Questie:GetMapInfoFromID(id)
	return QuestieZoneIDLookup[id];
end

QuestieMapNotes = {};--Usage Questie[Continent][Zone][index]
MiniQuestieMapNotes = {};
function Questie:AddNoteToMap(continent, zoneid, posx, posy, type, questHash, objectiveid)
	--This is to set up the variables
	if(QuestieMapNotes[continent] == nil) then
		QuestieMapNotes[continent] = {};
	end
	if(QuestieMapNotes[continent][zoneid] == nil) then
		QuestieMapNotes[continent][zoneid] = {};
	end
	--Sets values that i want to use for the notes THIS IS WIP MORE INFO MAY BE NEDED BOTH IN PARAMETERS AND NOTES!!!
	Note = {};
	Note.x = posx;
	Note.y = posy;
	Note.zoneid = zoneid;
	Note.continent = continent;
	Note.icontype = type;
	Note.questHash = questHash;
	Note.objectiveid = objectiveid;
	--Inserts it into the right zone and continent for later use.
	table.insert(QuestieMapNotes[continent][zoneid], Note);
end

--Available Quest Code
QuestieAvailableMapNotes = {};
function Questie:AddAvailableNoteToMap(continent, zoneid, posx, posy, type, questHash, objectiveid)
	--This is to set up the variables
	if(QuestieAvailableMapNotes[continent] == nil) then
		QuestieAvailableMapNotes[continent] = {};
	end
	if(QuestieAvailableMapNotes[continent][zoneid] == nil) then
		QuestieAvailableMapNotes[continent][zoneid] = {};
	end
	--Sets values that i want to use for the notes THIS IS WIP MORE INFO MAY BE NEDED BOTH IN PARAMETERS AND NOTES!!!
	Note = {};
	Note.x = posx;
	Note.y = posy;
	Note.zoneid = zoneid;
	Note.continent = continent;
	Note.icontype = type;
	Note.questHash = questHash;
	Note.objectiveid = objectiveid;
	--Inserts it into the right zone and continent for later use.
	table.insert(QuestieAvailableMapNotes[continent][zoneid], Note);
end

--Gets a blank frame either from Pool or creates a new one!
function Questie:GetBlankNoteFrame()
	if(table.getn(FramePool)==0) then
		Questie:CreateBlankFrameNote();
	end
	f = FramePool[1];
	table.remove(FramePool, 1);
	return f;
end

function Questie_Tooltip_OnEnter()
	if(this.data.questHash) then
		local Tooltip = GameTooltip;
		if(this.type == "WorldMapNote") then
			Tooltip = WorldMapTooltip;
		else
			Tooltip = GameTooltip;
		end
		Tooltip:SetOwner(this, this); --"ANCHOR_CURSOR"
		if(this.data.icontype ~= "available") then
			local Quest = Questie:IsQuestFinished(this.data.questHash);
			if not Quest then
				local QuestLogID = Questie:GetQuestIdFromHash(this.data.questHash);
				if QuestLogID then
					SelectQuestLogEntry(QuestLogID);
					local q, level, questTag, isHeader, isCollapsed, isComplete = QuestieCompat_GetQuestLogTitle(QuestLogID);
					local count =  GetNumQuestLeaderBoards();
					local questText, objectiveText = _GetQuestLogQuestText();
					local desc, typ, done = GetQuestLogLeaderBoard(this.data.objectiveid);
					Tooltip:AddLine(q ,1,1,1);
					Tooltip:AddLine(desc);
				end
			else
				Tooltip:AddLine(Quest["name"],1,1,1);
				Tooltip:AddLine("Quest Level: "..QuestieHashMap[this.data.questHash].level);
				Tooltip:AddLine("Quest Started by: "..QuestieHashMap[this.data.questHash].startedBy);
				Tooltip:AddLine("Quest Finished by: "..QuestieHashMap[this.data.questHash].finishedBy);
				Tooltip:AddLine("Quest in progress");
				Tooltip:AddLine("Shift+CTRL+Click to manually complete quest!",1,1,1);
			end
		else
			Tooltip:AddLine(QuestieHashMap[this.data.questHash].name);
			Tooltip:AddLine("Quest Level: "..QuestieHashMap[this.data.questHash].level,1,1,1);
			Tooltip:AddLine("Quest Started by: "..QuestieHashMap[this.data.questHash].startedBy,1,1,1);
			Tooltip:AddLine("Quest Finished by: "..QuestieHashMap[this.data.questHash].finishedBy,1,1,1);
			Tooltip:AddLine("Quest available",1,1,1);
			Tooltip:AddLine("Shift+CTRL+Click to manually complete quest!",1,1,1);
		end
		if(NOTES_DEBUG and IsAltKeyDown()) then
			Tooltip:AddLine("!DEBUG!", 1, 0, 0);
			Tooltip:AddLine("questHash: "..this.data.questHash, 1, 0, 0);
			Tooltip:AddLine("objectiveid: "..tostring(this.data.objectiveid), 1, 0, 0);
		end
		Tooltip:SetFrameLevel(11);
		Tooltip:Show();
	end
end

function Questie_AvailableQuestClick()
	local Tooltip = GameTooltip
	if(this.type == "WorldMapNote") then
		Tooltip = WorldMapTooltip
	else
		Tooltip = GameTooltip
	end
	if (QuestieConfig.arrowEnabled == true) and (arg1 == "LeftButton") and (QuestieSeenQuests[this.data.questHash] == 0) and (QuestieTrackedQuests[this.data.questHash] ~= false) and (not IsControlKeyDown()) and (not IsShiftKeyDown()) then
		SetArrowObjective(this.data.questHash)
	end
	if ( IsShiftKeyDown() and IsControlKeyDown() and Tooltip ) then
		local QuestName = tostring(QuestieHashMap[this.data.questHash].name)
		if QuestName then
			for k,v in pairs(QuestieLevLookup) do
				if strlower(k) == strlower(QuestName) then
					local index = 0
					for kk,vv in pairs(v) do
						index = index + 1
					end
					if index == 1 then
						Questie:Toggle()
						for kk,vv in pairs(v) do
							Questie:finishAndRecurse(vv[2])
						end
					else
						local index = 0
						for kk,vv in pairs(v) do
							index = index + 1
						end
						StaticPopupDialogs["QUESTIE_COMPLETE"] = {
							text = "|cFFFFFF00There are multiple quests matching the name \"" .. QuestName .. "\". Please enter the number listed in the chat window for the step that you want marked as complete:|r",
							hasEditBox = 1,
							maxLetters = 2,
							OnShow = function()
								getglobal(this:GetName().."EditBox"):SetFocus()
							end,
							EditBoxOnEnterPressed = function()
								local text = getglobal(this:GetParent():GetName().."EditBox"):GetText()
								for k,v in pairs(QuestieLevLookup) do
									if strlower(k) == strlower(QuestName) then
										local index = 0
										for kk,vv in pairs(v) do
											if index == tonumber(text) then
												Questie:finishAndRecurse(vv[2])
												index = index + 1
											end
										end
									end
								end
								this:GetParent():Hide()
								Questie:Toggle()
								Questie:Toggle()
							end,
							OnHide = function()
								getglobal(this:GetName().."EditBox"):SetText("")
							end,
							EditBoxOnEscapePressed = function()
								this:GetParent():Hide()
							end,
							timeout = 10,
							whileDead = 1,
							exclusive = 1,
							hideOnEscape = 1
						}
						StaticPopup_Show ("QUESTIE_COMPLETE")
						Questie:Toggle()
					end
				end
			end
		end
		Questie:Toggle()
	end
end

CREATED_NOTE_FRAMES = 1;
--Creates a blank frame for use within the map system
function Questie:CreateBlankFrameNote()
	local f = CreateFrame("Button","QuestieNoteFrame"..CREATED_NOTE_FRAMES,WorldMapFrame)
	f:SetFrameLevel(9);
	f:SetWidth(16*QUESTIE_NOTES_MAP_ICON_SCALE)  -- Set These to whatever height/width is needed
	f:SetHeight(16*QUESTIE_NOTES_MAP_ICON_SCALE) -- for your Texture
	local t = f:CreateTexture(nil,"BACKGROUND")
	t:SetTexture("Interface\\AddOns\\!Questie\\Icons\\complete")
	t:SetAllPoints(f)
	f.texture = t
	f:SetScript("OnEnter", Questie_Tooltip_OnEnter); --Script Toolip
	f:SetScript("OnLeave", function() if(WorldMapTooltip) then WorldMapTooltip:Hide() end if(GameTooltip) then GameTooltip:Hide() end end) --Script Exit Tooltip
	f:SetScript("OnClick", Questie_AvailableQuestClick);
	f:RegisterForClicks("LeftButtonDown", "RightButtonDown");
	CREATED_NOTE_FRAMES = CREATED_NOTE_FRAMES+1;
	table.insert(FramePool, f);
	table.insert(AllFrames, f);
end

TICK_DELAY = 0.01;--0.1 Atm not to get spam while debugging should probably be a lot faster...
LAST_TICK = GetTime();
local LastContinent = nil;
local LastZone = nil;
UIOpen = false;
NATURAL_REFRESH = 60;
NATRUAL_REFRESH_SPACING = 2;

function Questie:NOTES_ON_UPDATE(elapsed)
	--Test to remove the delay
	--Gets current map to see if we need to redraw or not.
	local c, z = GetCurrentMapContinent(), GetCurrentMapZone();
	if(c ~= LastContinent or LastZone ~= z) then
		--Clears before redrawing
		Questie:SetAvailableQuests();
		Questie:RedrawNotes();
		--Sets the last continent and zone to hinder spam.
		LastContinent = c;
		LastZone = z;
	end
	--NOT NEEDED BUT KEEPING FOR AWHILE
	if(WorldMapFrame:IsVisible() and UIOpen == false) then
		Questie:debug_Print("Created Frames: "..CREATED_NOTE_FRAMES, "Used Frames: "..table.getn(QuestieUsedNoteFrames), "Free Frames: "..table.getn(FramePool));
		UIOpen = true;
	elseif(WorldMapFrame:IsVisible() == nil and UIOpen == true) then
		UIOpen = false;
	end
end

--Inital pool size (Not tested how much you can do before it lags like shit, from experiance 11 is good)
INIT_POOL_SIZE = 11;
function Questie:NOTES_LOADED()
	Questie:debug_Print("Loading QuestieNotes");
	if(table.getn(FramePool) < 10) then--For some reason loading gets done several times... added this in as safety
		for i = 1, INIT_POOL_SIZE do
			Questie:CreateBlankFrameNote();
		end
	end
	Questie:debug_Print("Done Loading QuestieNotes");
end

function Questie:SetAvailableQuests()
	QuestieAvailableMapNotes = {};
	local t = GetTime();
	local level = UnitLevel("player");
	local c, z = GetCurrentMapContinent(), GetCurrentMapZone();
	local mapFileName = GetMapInfo();
	local quests = nil;
	if QuestieConfig.minLevelFilter and not QuestieConfig.maxLevelFilter then
		quests = Questie:GetAvailableQuestHashes(mapFileName,level-(QuestieConfig.minShowLevel),level);
	elseif QuestieConfig.minLevelFilter and QuestieConfig.maxLevelFilter then
		quests = Questie:GetAvailableQuestHashes(mapFileName,level-(QuestieConfig.minShowLevel),level-(QuestieConfig.maxShowLevel));
	elseif not QuestieConfig.minLevelFilter and not QuestieConfig.maxLevelFilter then
		quests = Questie:GetAvailableQuestHashes(mapFileName,0,level);
	end
	if quests then
	for k, v in pairs(quests) do
		if(QuestieHashMap[v] and QuestieHashMap[v]['startedBy'] and QuestieMonsters[QuestieHashMap[v]['startedBy']]) then
			Monster = QuestieMonsters[QuestieHashMap[v]['startedBy']]['locations'][1]
			local MapInfo = Questie:GetMapInfoFromID(Monster[1]);
			Questie:AddAvailableNoteToMap(c,z,Monster[2],Monster[3],"available",v,-1);
		end
	end
	Questie:debug_Print("Added Available quests: Time:",tostring((GetTime()- t)*1000).."ms", "Count:"..table.getn(quests))
	end
end

--Reason this exists is to be able to call both clearnotes and drawnotes without doing 2 function calls, and to be able to force a redraw
function Questie:RedrawNotes()
	local time = GetTime();
	Questie:CLEAR_ALL_NOTES();
	Questie:DRAW_NOTES();
	Questie:debug_Print("Notes redrawn time:", tostring((GetTime()- time)*1000).."ms");
	time = nil;
end

function Questie:Clear_Note(v)
	v:SetParent(nil);
	v:Hide();
	v:SetAlpha(1);
	v:SetFrameLevel(9);
	v:SetHighlightTexture(nil, "ADD");
	v.questHash = nil;
	v.objId = nil;
	table.insert(FramePool, v);
end

--Clears the notes, goes through the usednoteframes and clears them. Then sets the QuestieUsedNotesFrame to new table;
function Questie:CLEAR_ALL_NOTES()
	Questie:debug_Print("CLEAR_NOTES");
	Astrolabe:RemoveAllMinimapIcons();
	for k, v in pairs(QuestieUsedNoteFrames) do
		--Questie:debug_Print("Hash:"..v.questHash,"Type:"..v.type);
		Questie:Clear_Note(v);
	end
	QuestieUsedNoteFrames = {};
end

--Checks first if there are any notes for the current zone, then draws the desired icon
function Questie:DRAW_NOTES()
	local c, z = GetCurrentMapContinent(), GetCurrentMapZone();
	Questie:debug_Print("DRAW_NOTES");
	if(QuestieMapNotes[c] and QuestieMapNotes[c][z]) then
		for k, v in pairs(QuestieMapNotes[c][z]) do
			--If an available quest isn't in the zone or we aren't tracking a quest on the QuestTracker then hide the objectives from the minimap
			if (QuestieConfig.alwaysShowQuests == false) and (MMLastX ~= 0 and MMLastY ~= 0) and ((not QuestieTrackedQuests[v.questHash] == false) or (v.icontype == "complete")) then
				MMIcon = Questie:GetBlankNoteFrame();
				MMIcon.data = v;
				MMIcon:SetParent(Minimap);
				MMIcon:SetFrameLevel(9);
				MMIcon:SetPoint("CENTER",0,0)
				MMIcon:SetWidth(16*QUESTIE_NOTES_MINIMAP_ICON_SCALE)  -- Set These to whatever height/width is needed
				MMIcon:SetHeight(16*QUESTIE_NOTES_MINIMAP_ICON_SCALE) -- for your Texture
				MMIcon.type = "MiniMapNote";
				--Sets highlight texture (Nothing stops us from doing this on the worldmap aswell)
				MMIcon:SetHighlightTexture(QuestieIcons[v.icontype].path, "ADD");
				--Set the texture to the right type
				MMIcon.texture:SetTexture(QuestieIcons[v.icontype].path);
				MMIcon.texture:SetAllPoints(MMIcon)
				Astrolabe:PlaceIconOnMinimap(MMIcon, v.continent, v.zoneid, v.x, v.y);
				table.insert(QuestieUsedNoteFrames, MMIcon);
			elseif (QuestieConfig.alwaysShowQuests == true) then
				MMIcon = Questie:GetBlankNoteFrame();
				MMIcon.data = v;
				MMIcon:SetParent(Minimap);
				MMIcon:SetFrameLevel(9);
				MMIcon:SetPoint("CENTER",0,0)
				MMIcon:SetWidth(16*QUESTIE_NOTES_MINIMAP_ICON_SCALE)  -- Set These to whatever height/width is needed
				MMIcon:SetHeight(16*QUESTIE_NOTES_MINIMAP_ICON_SCALE) -- for your Texture
				MMIcon.type = "MiniMapNote";
				--Sets highlight texture (Nothing stops us from doing this on the worldmap aswell)
				MMIcon:SetHighlightTexture(QuestieIcons[v.icontype].path, "ADD");
				--Set the texture to the right type
				MMIcon.texture:SetTexture(QuestieIcons[v.icontype].path);
				MMIcon.texture:SetAllPoints(MMIcon)
				Astrolabe:PlaceIconOnMinimap(MMIcon, v.continent, v.zoneid, v.x, v.y);
				table.insert(QuestieUsedNoteFrames, MMIcon);
			end
		end
	end
	for k, Continent in pairs(QuestieMapNotes) do
		for zone, noteHeap in pairs(Continent) do
			for k, v in pairs(noteHeap) do
				if true then
					--If we aren't tracking a quest on the QuestTracker then hide the objectives from the worldmap
					if ((not QuestieTrackedQuests[v.questHash] == false) or (v.icontype == "complete")) and (QuestieConfig.alwaysShowQuests == false) then
						local c, z = GetCurrentMapContinent(), GetCurrentMapZone();
						Icon = Questie:GetBlankNoteFrame();
						Icon.data = v;
						Icon:SetParent(WorldMapFrame);
						--This is so that Complete quests are over everything else
						if(v.icontype == "complete") then
							Icon:SetFrameLevel(10);
						else
							Icon:SetFrameLevel(9);
						end
						Icon:SetPoint("CENTER",0,0)
						Icon.type = "WorldMapNote";
						Icon:SetScript("OnEnter", Questie_Tooltip_OnEnter); --Script Toolip
						Icon:SetScript("OnLeave", function() if(WorldMapTooltip) then WorldMapTooltip:Hide() end if(GameTooltip) then GameTooltip:Hide() end end) --Script Exit Tooltip
						Icon:SetScript("OnClick", Questie_AvailableQuestClick);
						Icon:RegisterForClicks("LeftButtonDown", "RightButtonDown");
						if(z == 0 and c == 0) then--Both continents
							Icon:SetWidth(16*QUESTIE_NOTES_WORLD_MAP_ICON_SCALE)  -- Set These to whatever height/width is needed
							Icon:SetHeight(16*QUESTIE_NOTES_WORLD_MAP_ICON_SCALE) -- for your Texture
						elseif(z == 0) then--Single continent
							Icon:SetWidth(16*QUESTIE_NOTES_CONTINENT_ICON_SCALE)  -- Set These to whatever height/width is needed
							Icon:SetHeight(16*QUESTIE_NOTES_CONTINENT_ICON_SCALE) -- for your Texture
						else
							Icon:SetWidth(16*QUESTIE_NOTES_MAP_ICON_SCALE)  -- Set These to whatever height/width is needed
							Icon:SetHeight(16*QUESTIE_NOTES_MAP_ICON_SCALE) -- for your Texture
						end
						--Set the texture to the right type
						Icon.texture:SetTexture(QuestieIcons[v.icontype].path);
						Icon.texture:SetAllPoints(Icon)
						--Shows and then calls Astrolabe to place it on the map.
						Icon:Show();
						xx, yy = Astrolabe:PlaceIconOnWorldMap(WorldMapButton,Icon,v.continent ,v.zoneid ,v.x, v.y); --WorldMapFrame is global
						if(xx and yy and xx > 0 and xx < 1 and yy > 0 and yy < 1) then
							table.insert(QuestieUsedNoteFrames, Icon);
						else
							Questie:Clear_Note(Icon);
						end
					elseif (QuestieConfig.alwaysShowQuests == true) then
						local c, z = GetCurrentMapContinent(), GetCurrentMapZone();
						Icon = Questie:GetBlankNoteFrame();
						Icon.data = v;
						Icon:SetParent(WorldMapFrame);
						--This is so that Complete quests are over everything else
						if(v.icontype == "complete") then
							Icon:SetFrameLevel(10);
						else
							Icon:SetFrameLevel(9);
						end
						Icon:SetPoint("CENTER",0,0)
						Icon.type = "WorldMapNote";
						Icon:SetScript("OnEnter", Questie_Tooltip_OnEnter); --Script Toolip
						Icon:SetScript("OnLeave", function() if(WorldMapTooltip) then WorldMapTooltip:Hide() end if(GameTooltip) then GameTooltip:Hide() end end) --Script Exit Tooltip
						Icon:SetScript("OnClick", Questie_AvailableQuestClick);
						Icon:RegisterForClicks("LeftButtonDown", "RightButtonDown");
						if(z == 0 and c == 0) then--Both continents
							Icon:SetWidth(16*QUESTIE_NOTES_WORLD_MAP_ICON_SCALE)  -- Set These to whatever height/width is needed
							Icon:SetHeight(16*QUESTIE_NOTES_WORLD_MAP_ICON_SCALE) -- for your Texture
						elseif(z == 0) then--Single continent
							Icon:SetWidth(16*QUESTIE_NOTES_CONTINENT_ICON_SCALE)  -- Set These to whatever height/width is needed
							Icon:SetHeight(16*QUESTIE_NOTES_CONTINENT_ICON_SCALE) -- for your Texture
						else
							Icon:SetWidth(16*QUESTIE_NOTES_MAP_ICON_SCALE)  -- Set These to whatever height/width is needed
							Icon:SetHeight(16*QUESTIE_NOTES_MAP_ICON_SCALE) -- for your Texture
						end
						--Set the texture to the right type
						Icon.texture:SetTexture(QuestieIcons[v.icontype].path);
						Icon.texture:SetAllPoints(Icon)
						--Shows and then calls Astrolabe to place it on the map.
						Icon:Show();
						xx, yy = Astrolabe:PlaceIconOnWorldMap(WorldMapButton,Icon,v.continent ,v.zoneid ,v.x, v.y); --WorldMapFrame is global
						if(xx and yy and xx > 0 and xx < 1 and yy > 0 and yy < 1) then
							table.insert(QuestieUsedNoteFrames, Icon);
						else
							Questie:Clear_Note(Icon);
						end
					end
				end
			end
		end
	end
	if(QuestieAvailableMapNotes[c] and QuestieAvailableMapNotes[c][z]) then
		local con,zon,x,y = Astrolabe:GetCurrentPlayerPosition();
		for k, v in pairs(QuestieAvailableMapNotes[c][z]) do
			local c, z = GetCurrentMapContinent(), GetCurrentMapZone();
			Icon = Questie:GetBlankNoteFrame();
			Icon.data = v;
			Icon:SetParent(WorldMapFrame);
			--This is so that Complete quests are over everything else
			Icon:SetFrameLevel(9);
			Icon:SetPoint("CENTER",0,0)
			Icon.type = "WorldMapNote";
			Icon:SetScript("OnEnter", Questie_Tooltip_OnEnter); --Script Toolip
			Icon:SetScript("OnLeave", function() if(WorldMapTooltip) then WorldMapTooltip:Hide() end if(GameTooltip) then GameTooltip:Hide() end end) --Script Exit Tooltip
			Icon:SetWidth(16*QUESTIE_NOTES_MAP_ICON_SCALE)  -- Set These to whatever height/width is needed
			Icon:SetHeight(16*QUESTIE_NOTES_MAP_ICON_SCALE) -- for your Texture
			Icon:SetScript("OnClick", Questie_AvailableQuestClick);
			Icon:RegisterForClicks("LeftButtonDown", "RightButtonDown");
			--Set the texture to the right type
			Icon.texture:SetTexture(QuestieIcons[v.icontype].path);
			Icon.texture:SetAllPoints(Icon)
			--Shows and then calls Astrolabe to place it on the map.
			Icon:Show();
			xx, yy = Astrolabe:PlaceIconOnWorldMap(WorldMapButton,Icon,v.continent ,v.zoneid ,v.x, v.y); --WorldMapFrame is global
			if(xx and yy and xx > 0 and xx < 1 and yy > 0 and yy < 1) then
				table.insert(QuestieUsedNoteFrames, Icon);
			else
				Questie:Clear_Note(Icon);
			end
			MMIcon = Questie:GetBlankNoteFrame();
			MMIcon.data = v;
			MMIcon:SetParent(Minimap);
			MMIcon:SetFrameLevel(7);
			MMIcon:SetPoint("CENTER",0,0)
			MMIcon:SetWidth(16*QUESTIE_NOTES_MINIMAP_ICON_SCALE)  -- Set These to whatever height/width is needed
			MMIcon:SetHeight(16*QUESTIE_NOTES_MINIMAP_ICON_SCALE) -- for your Texture
			MMIcon.type = "MiniMapNote";
			--Sets highlight texture (Nothing stops us from doing this on the worldmap aswell)
			MMIcon:SetHighlightTexture(QuestieIcons[v.icontype].path, "ADD");
			--Set the texture to the right type
			MMIcon.texture:SetTexture(QuestieIcons[v.icontype].path);
			MMIcon.texture:SetAllPoints(MMIcon)
			Astrolabe:PlaceIconOnMinimap(MMIcon, v.continent, v.zoneid, v.x, v.y);
			table.insert(QuestieUsedNoteFrames, MMIcon);
		end
	end
end

--Debug print function
function Questie:debug_Print(...)
	local debugWin = 0;
	local name, shown;
	for i=1, NUM_CHAT_WINDOWS do
		name,_,_,_,_,_,shown = GetChatWindowInfo(i);
		if (string.lower(name) == "questiedebug") then debugWin = i; break; end
	end
	if (debugWin == 0) then return end
	local out = "";
	for i = 1, arg.n, 1 do
		if (i > 1) then out = out .. ", "; end
		local t = type(arg[i]);
		if (t == "string") then
			out = out .. '"'..arg[i]..'"';
		elseif (t == "number") then
			out = out .. arg[i];
		else
			out = out .. dump(arg[i]);
		end
	end
	getglobal("ChatFrame"..debugWin):AddMessage(out, 1.0, 1.0, 0.3);
end

--Sets the icons
QuestieIcons = {
	["complete"] = {
		text = "Complete",
		path = "Interface\\AddOns\\!Questie\\Icons\\complete"
	},
	["available"] = {
		text = "Complete",
		path = "Interface\\AddOns\\!Questie\\Icons\\available"
	},
	["loot"] = {
		text = "Complete",
		path = "Interface\\AddOns\\!Questie\\Icons\\loot"
	},
	["item"] = {
		text = "Complete",
		path = "Interface\\AddOns\\!Questie\\Icons\\loot"
	},
	["event"] = {
		text = "Complete",
		path = "Interface\\AddOns\\!Questie\\Icons\\event"
	},
	["object"] = {
		text = "Complete",
		path = "Interface\\AddOns\\!Questie\\Icons\\object"
	},
	["slay"] = {
		text = "Complete",
		path = "Interface\\AddOns\\!Questie\\Icons\\slay"
	}
}