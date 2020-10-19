--####################################################################################
--####################################################################################
--Main class
--####################################################################################
--####################################################################################
--Dependencies: LinkWebParsing.lua, Locale.lua, SearchProvider.lua

--LINKSINCHAT_GameVersion		= nil; --UIversion number of the game for quick lookup for other parts of the code for compatibility
	--if (LINKSINCHAT_GameVersion < 50300) then
		--Before patch 5.3.0

--local LINKSINCHAT_addon_version = GetAddOnMetadata("LinksInChat", "Version");	--Version number for the addon

--####################################################################################
--####################################################################################
--Event Handling and Cache
--####################################################################################

LinksInChat			= {};	--Global declaration
LinksInChat.__index	= LinksInChat;

local LinkWebParsing	= LinksInChat_LinkWebParsing;		--Local pointer
local Locale			= LinksInChat_Locale;
local SearchProvider	= LinksInChat_SearchProvider;

LINKSINCHAT_settings	= {};		--Array of Settings	(SAVED TO DISK)
--[[
	Color				:: Number	: Hex formatted color for links (RRGGBB)
	AutoHide			:: Number	: Hide copy frame after N seconds. Positive number in seconds or -1 to disable the feature.
	IgnoreHyperlinks 	:: Boolean	: Ignore any hyperlinks [myitem] etc. and will just work for web links www. and http://
	Extra				:: Boolean	: Enable Alt-clicking in character frame, auction house, black market and achievement frame.
	Simple				:: Boolean	: Always simple-search for providers (only search for item name and dont try to lookup using spellid, factionname etc).
	UseHTTPS			:: Boolean	: Use https:// or http:// (true).
	AlwaysEnglish		:: Boolean  : Always use english search provider.
	Provider			:: String	: Dropdown of several different search providers for itemlinks (Google, Bing, Wowdb, Wowhead, etc).
	--KeyModifier		:: String	: Dropdown of different key modifier (ALT, CTRL, SHIFT)
	Debug				:: Number   : Number from 0 (disabled) or higher that determines debug output level. Call LinksInChat_Debug() ingame to change
]]--

--Local variables that cache stuff so we dont have to recreate large objects
local cache_rawLink				= false;	--Flag used to enable showing raw links as output.
local cache_Color_HyperLinks	= "FF0080";	--Pink hyperlink color
local cache_Provider			= nil;		--Current selected provider
local cache_Debug				= 0;		--Current debuglevel
local hook_ChatFrame_OnHyperlinkShow		= nil; --ChatFrame_OnHyperlinkShow; --Original function
local hook_ReputationBar_OnClick			= nil; --ReputationFrame.lua
local hook_QuestMapLogTitleButton_OnClick	= nil; --QuestMapLogTitleButton_OnClick; --Original function
local hook_ACHIEVEMENT_TRACKER_MODULE		= nil; --Blizzard_AchievementObjectiveTracker.lua
local hook_QUEST_TRACKER_MODULE				= nil; --Blizzard_QuestObjectiveTracker.lua
local hook_TokenButton_OnClick				= nil; --Blizzard_TokenUI.lua

LinksInChat_IsKeyDown = IsAltKeyDown; --Global Pointer to function that returns true/false (IsAltKeyDown, IsShiftKeyDown or IsControlKeyDown)


--Handles the events for the addon
function LinksInChat:OnEvent(s, event, ...)
	if (event == "PLAYER_ENTERING_WORLD") then
		--Startup

		--Register for chat channels (rest is done in LinkWebParsing)
		LinkWebParsing:RegisterMessageEventFilters(true);
		---------------------------------------------------------------------------

		--Apply default settings.
		cache_Color_HyperLinks	= self:GetCurrentSetting("Color",	"string", "FF0080"); --Pink color
		local s_AutoHide		= self:GetCurrentSetting("AutoHide","number", -1);
		local s_Ignore			= self:GetCurrentSetting("IgnoreHyperlinks", "boolean", false);
		local s_Extra			= self:GetCurrentSetting("Extra",	"boolean", true);
		local s_Simple			= self:GetCurrentSetting("Simple",	"boolean", false);
		local s_HTTPS			= self:GetCurrentSetting("UseHTTPS","boolean", true);
		local s_English			= self:GetCurrentSetting("AlwaysEnglish", "boolean", false);
		local s_Provider		= self:GetCurrentSetting("Provider", "string", "wowhead");
		--local s_KeyModifier	= self:GetCurrentSetting("KeyModifier", "string", "ALT"); --ALT, SHIFT, CTRL
		local s_Debug			= self:GetCurrentSetting("Debug",	"number", 0);

		--Validate Color
		local booResult, strMessage = pcall( LinksInChat.HexColorToRGBPercent, LinksInChat, cache_Color_HyperLinks ); --Instead of LinksInChat: (colon) we need to use LinksInChat. (period) and pass LinksInChat (self) as the first argument
		if (booResult == false) then cache_Color_HyperLinks = "FF0080"; end --Reset to default Pink color

		--Validate Autohide
		--	As long as autohide is a number we dont care; A user can thereby manually sets a custom value via the luafile and it will still work.

		--Validate Provider
		SearchProvider:InitializeProvider(s_English);
		if (SearchProvider:ProviderExists(s_Provider) ~= true) then s_Provider = "wowhead"; end
		cache_Provider = SearchProvider:GetProvider(s_Provider);

		--Validate KeyModifier
		--	(not yet implemented)

		--Validate Debug
		if (s_Debug == nil or type(s_Debug) ~= "number" or s_Debug < 0) then s_Debug = 0; end --only whole numbers
		cache_Debug = s_Debug;

		self:SetCurrentSetting("Color", cache_Color_HyperLinks);
		self:SetCurrentSetting("AutoHide", s_AutoHide);
		self:SetCurrentSetting("IgnoreHyperlinks", s_Ignore);
		self:SetCurrentSetting("Extra", s_Extra);
		self:SetCurrentSetting("Simple", s_Simple);
		self:SetCurrentSetting("UseHTTPS", s_HTTPS);
		self:SetCurrentSetting("AlwaysEnglish", s_English);
		self:SetCurrentSetting("Provider", s_Provider);
		--self:SetCurrentSetting("KeyModifier", s_KeyModifier);
		self:SetCurrentSetting("Debug", s_Debug);
		---------------------------------------------------------------------------

		--[[Determine what Key modifier (all globals return true/false)
		if		(s_KeyModifier == "SHIFT") then	LinksInChat_IsKeyDown = IsShiftKeyDown --Globals that must return true/false
		elseif	(s_KeyModifier == "CTRL")  then	LinksInChat_IsKeyDown = IsControlKeyDown
		else									LinksInChat_IsKeyDown = IsAltKeyDown --Default is ALT
		end--if]]--
		---------------------------------------------------------------------------

		--Add the slash command
		local k,v = self:findInSlashList("/link");
		self["findInSlashList"] = nil; --Cleanup after single use.
		if (k == nil) then
			SLASH_LINKSINCHAT1 = "/link";
		else
			--Some other addon has taken "/link" as a slash command. We print an errormessage and use "/linksinchat" instead.
			print("|cFFB92828LinksInChat:|r Some other addon has already used '/link' as a command. Use '/linksinchat' instead.");
			SLASH_LINKSINCHAT1 = "/linksinchat";
		end
		SlashCmdList["LINKSINCHAT"] = function(cmd) return self:Slash(cmd) end;
		---------------------------------------------------------------------------

		--Secure hook into most places where hyperlinks are used. For the other scenarios we need custom code.
		hooksecurefunc("HandleModifiedItemClick", LinksInChat_HandleModifiedItemClick);
		---------------------------------------------------------------------------

		--Hook into chat
		hooksecurefunc("ChatFrame_OnHyperlinkShow", LinksInChat_ChatFrame_OnHyperlinkShow);
		---------------------------------------------------------------------------

		--Hook into Reputation tab on character frame (Interface\FrameXML\ReputationFrame.lua)
		hook_ReputationBar_OnClick = ReputationBar_OnClick; --Save pointer to Original function
		ReputationBar_OnClick = LinksInChat_ReputationBar_OnClick; --Override with our own function.
		---------------------------------------------------------------------------

		--Hook into questlog (quest frame), objective tracker and quest tracker
		hook_QuestMapLogTitleButton_OnClick = QuestMapLogTitleButton_OnClick; --Save pointer to Original function
		QuestMapLogTitleButton_OnClick = LinksInChat_QuestMapLogTitleButton_OnClick; --Override with our own function.

		--Using a post-hook on the quest details frame
		hooksecurefunc("QuestLogPopupDetailFrame_Show", LinksInChat_QuestLogPopupDetailFrame_Show);

		--Hook into objective tracker for achievement and quests
		hook_ACHIEVEMENT_TRACKER_MODULE = ACHIEVEMENT_TRACKER_MODULE["OnBlockHeaderClick"];
		ACHIEVEMENT_TRACKER_MODULE["OnBlockHeaderClick"] = LinksInChat_ACHIEVEMENT_TRACKER_MODULE;
		hook_QUEST_TRACKER_MODULE = QUEST_TRACKER_MODULE["OnBlockHeaderClick"];
		QUEST_TRACKER_MODULE["OnBlockHeaderClick"] = LinksInChat_QUEST_TRACKER_MODULE;

		--Hook into objectives tracker for world quest
		hooksecurefunc("BonusObjectiveTracker_OnBlockClick", LinksInChat_BonusObjectiveTracker_OnBlockClick);
		---------------------------------------------------------------------------

		--Hook into Default grouploot frames
		--Source: LootFrame.lua and .xml
		local CONST1, CONST2, i = "GroupLootFrame", "IconFrame", 1; --GroupLootFrame%.IconFrame
		local objName1, objName2 = _G[CONST1..i], nil;	--Frame with a icon as subframe
		if (objName1 ~= nil) then objName2 = objName1[CONST2]; end

		while (objName1 ~= nil) do
			objName2:HookScript("OnClick", LinksInChat_GroupLootFrame_OnClick); --This is the button that holds the icon in the grouploot frame
			i = i +1;
			objName1 = _G[CONST1..i];
			if (objName1 ~= nil) then objName2 = objName1[CONST2]; end
		end--while
		---------------------------------------------------------------------------

		--Hook into Character frame (handled by HandleModifiedItemClick)
		--Hook into Default lootframe (handled by HandleModifiedItemClick)
		--Hook into Default bags (handled by HandleModifiedItemClick)
		--Hook into Default bank (handled by HandleModifiedItemClick)
		--Hook into Default merchantframe (handled by HandleModifiedItemClick)
		--Hook into the 'Bagnon' addon's bagframes. (handled by HandleModifiedItemClick)
		---------------------------------------------------------------------------

		---Hook into Default quest info reward icons
		--Source: QuestInfo.lua and .xml
		local callback = self["CALLBACK_LinksInChat_QuestInfo_ToggleRewardElement"]; --Quest rewards that are items/currency
		local timed_callback = function() C_Timer.After(1, callback) end; --Creat a hook that triggers a callback after 1 second
		--hooksecurefunc("QuestInfo_ToggleRewardElement", timed_callback);
		if (QuestInfoRewardSpell ~= nil) then QuestInfoRewardSpell:HookScript("OnClick", LinksInChat_QuestInfoRewardsFrameQuestInfoItem_OnClick); end --Quest reward that is a spell
		if (MapQuestInfoRewardsFrame.SpellFrame ~= nil) then MapQuestInfoRewardsFrame.SpellFrame:HookScript("OnClick", LinksInChat_QuestInfoRewardsFrameQuestInfoItem_OnClick); end --Quest reward that is a spell
		---------------------------------------------------------------------------

		---Hook into Default quest requirement items (these are static and always declared at loading)
		--Source: QuestFrame.xml
		self:Hook1("QuestProgressItem@", "OnClick", LinksInChat_QuestInfoRewardsFrameQuestInfoItem_OnClick); --Reuse same as for quest info --QuestProgressItem@
		---------------------------------------------------------------------------

		--Hook into Default spellbook
		--Source: SpellBookFrame.lua ad .xml
		self:Hook1("SpellButton@", "OnClick", LinksInChat_SpellButton_OnClick);
		---------------------------------------------------------------------------


		if(IsAddOnLoaded("Blizzard_AchievementUI") == true) then
			local callback = self["CALLBACK_Blizzard_AchievementUI"];
			if (callback ~= nil) then C_Timer.After(1, callback); end
		end
		---------------------------------------------------------------------------
		if(IsAddOnLoaded("Blizzard_TalentUI") == true) then
			local callback = self["CALLBACK_Blizzard_TalentUI"];
			if (callback ~= nil) then C_Timer.After(1, callback); end
		end
		---------------------------------------------------------------------------
		if (IsAddOnLoaded("Blizzard_Collections") == true) then
			--We need to make several hooks for the Mount,Pet,ToyBoy and Heirloom UI.
			local callback = self["CALLBACK_Blizzard_Collections"];
			if (callback ~= nil) then C_Timer.After(1, callback); end
		end
		---------------------------------------------------------------------------
		if(IsAddOnLoaded("Blizzard_GarrisonUI") == true) then
			--We need to make several hooks for the Garrison UI. One for each button in the UI.
			local callback = self["CALLBACK_Blizzard_GarrisonUI"];
			if (callback ~= nil) then C_Timer.After(1, callback); end
		end
		---------------------------------------------------------------------------
		--Hook into the Currency frame on the default UI character tab.
		if (IsAddOnLoaded("Blizzard_TokenUI") == true) then
			local callback = self["CALLBACK_Blizzard_TokenUI"]; --If its nil then its already been loaded
			if (callback ~= nil) then C_Timer.After(1, callback); end --Trigger function 1 seconds after the addon is loaded.
		end
		---------------------------------------------------------------------------


		--Hook into the 'ElvUI' addon's bagframes.
		if (IsAddOnLoaded("ElvUI") == true) then
			--The ElvUI bag buttons are created at its startup.
			local callback = self["CALLBACK_ElvUI"]; --If its nil then its already been loaded
			if (callback ~= nil) then C_Timer.After(1, callback); end --Trigger function 1 seconds after the addon is loaded.
		end
		---------------------------------------------------------------------------
		--Disable url-translation if 'WoW Instant Messenger (WIM)' addon is loaded.
		if (IsAddOnLoaded("WIM") == true) then
			--Use alternate chat-registration to support only default chatframes. WIM will handle the rest. Callback function will make Alt-clicking hyperlinks work.
			LinkWebParsing:RegisterMessageEventFilters(false);
			LinkWebParsing:Alternate_RegisterMessageEventFilters(true);
			if (WIM ~= nil) then WIM.RegisterItemRefHandler("wim_url", function() end); end --Override WIM's own displayfunction for url's. We handle it in LinksInChat_ChatFrame_OnHyperlinkShow
			local callback = self["CALLBACK_WIM"];
			if (callback ~= nil) then C_Timer.After(1, callback); end
		end
		---------------------------------------------------------------------------
		--Disable url-translation if 'Prat' addon is loaded.
		if (IsAddOnLoaded("Prat-3.0") == true) then
			LinkWebParsing:RegisterMessageEventFilters(false);
		end
		---------------------------------------------------------------------------
		--Disable url-translation if 'Total RP 3 (TRP3)' addon is loaded.
		if (IsAddOnLoaded("totalRP3") == true) then
			--Use alternate chat-registration to support only default chatframes.
			LinkWebParsing:RegisterMessageEventFilters(false);
			LinkWebParsing:Alternate_RegisterMessageEventFilters(true);
		end
		---------------------------------------------------------------------------
		--Hook into Rematch PetJournal
		if (IsAddOnLoaded("Rematch") == true) then
			local callback = self["CALLBACK_Rematch"];
			if (callback ~= nil) then C_Timer.After(1, callback); end
		end
		---------------------------------------------------------------------------


		s:RegisterEvent("ADDON_LOADED");		--Inspect frame, Auction house, Black market, Achivement and other addons are loaded on demand.
		s:RegisterEvent("BANKFRAME_OPENED");	--When the bank frame is opened
		---------------------------------------------------------------------------

		--After the first call to RegisterMessageEventFilters we dont need this anymore
		s:UnregisterEvent("PLAYER_ENTERING_WORLD");

	elseif(event=="BANKFRAME_OPENED") then
		--Hook into Default bank reagent frame (buttons are created when the user clicks the reagent-tab)  (handled by HandleModifiedItemClick)

		--Hook into the 'ElvUI' addon's bankframes and reagent frame.
		if (IsAddOnLoaded("ElvUI") == true) then
			--The default ElvUI bank frame is created after BANKFRAME_OPENED is fired
			local callback = self["CALLBACK_ElvUI_BANK"];
			if (callback ~= nil) then C_Timer.After(1, callback); end
			--ElvUI reagent frame (buttons are created when the user clicks the reagent-tab)
			local callback = self["CALLBACK_ElvUI_ReagentBankFrameItem"];
			if (callback ~= nil) then C_Timer.After(1, callback); end
		end
	---------------------------------------------------------------------------

	--[[All these now handled by HandleModifiedItemClick
	elseif(event=="ADDON_LOADED" and addon_name == "Blizzard_GuildBankUI") then
	elseif(event=="ADDON_LOADED" and addon_name == "Blizzard_VoidStorageUI") then
	elseif(event=="ADDON_LOADED" and addon_name == "Blizzard_InspectUI") then
	elseif(event=="ADDON_LOADED" and addon_name == "Blizzard_AuctionUI") then
	elseif(event=="ADDON_LOADED" and addon_name == "Blizzard_BlackMarketUI") then
	elseif(event=="ADDON_LOADED" and addon_name == "Blizzard_EncounterJournal") then
	elseif(event=="ADDON_LOADED" and addon_name == "Blizzard_TradeSkillUI") then
	elseif(event=="ADDON_LOADED" and addon_name == "Bagnon") then
	elseif(event=="ADDON_LOADED" and addon_name == "Bagnon_GuildBank") then
	elseif(event=="ADDON_LOADED" and addon_name == "Bagnon_VoidStorage") then
	]]--

	elseif(event=="ADDON_LOADED" and tostring(select(1,...)) == "Blizzard_AchievementUI") then
		local callback = self["CALLBACK_Blizzard_AchievementUI"];
		if (callback ~= nil) then C_Timer.After(1, callback); end

	elseif(event=="ADDON_LOADED" and tostring(select(1,...)) == "Blizzard_TalentUI") then
		local callback = self["CALLBACK_Blizzard_TalentUI"];
		if (callback ~= nil) then C_Timer.After(1, callback); end

	elseif(event=="ADDON_LOADED" and tostring(select(1,...)) == "Blizzard_Collections") then
		--We need to make several hooks for the Mount,Pet,ToyBoy and Heirloom UI.
		local callback = self["CALLBACK_Blizzard_Collections"];
		if (callback ~= nil) then C_Timer.After(1, callback); end

	elseif(event=="ADDON_LOADED" and tostring(select(1,...)) == "Blizzard_GarrisonUI") then
		--We need to make several hooks for the Garrison UI. One for each button in the UI.
		local callback = self["CALLBACK_Blizzard_GarrisonUI"];
		if (callback ~= nil) then C_Timer.After(1, callback); end

	elseif(event=="ADDON_LOADED" and tostring(select(1,...)) == "Blizzard_TokenUI") then
		local callback = self["CALLBACK_Blizzard_TokenUI"];
		if (callback ~= nil) then C_Timer.After(1, callback); end

	elseif(event=="ADDON_LOADED" and tostring(select(1,...)) == "ElvUI") then
		--The ElvUI bag buttons are created at its startup.
		local callback = self["CALLBACK_ElvUI"];
		if (callback ~= nil) then C_Timer.After(1, callback); end

	elseif(event=="ADDON_LOADED" and tostring(select(1,...)) == "WIM") then
		--Use alternate chat-registration to support only default chatframes. WIM will handle the rest. Callback function will make alt-clicking hyperlinks work.
		LinkWebParsing:RegisterMessageEventFilters(false);
		LinkWebParsing:Alternate_RegisterMessageEventFilters(true);
		if (WIM ~= nil) then WIM.RegisterItemRefHandler("wim_url", function() end); end --Override WIM's own displayfunction for url's. We handle it in LinksInChat_ChatFrame_OnHyperlinkShow
		local callback = self["CALLBACK_WIM"];
		if (callback ~= nil) then C_Timer.After(1, callback); end

	elseif(event=="ADDON_LOADED" and tostring(select(1,...)) == "Prat-3.0") then
		--Disable url-translation if 'Prat' addon is loaded.
		LinkWebParsing:RegisterMessageEventFilters(false);

	elseif(event=="ADDON_LOADED" and tostring(select(1,...)) == "totalRP3") then
		--Use alternate chat-registration to support only default chatframes.
		LinkWebParsing:RegisterMessageEventFilters(false);
		LinkWebParsing:Alternate_RegisterMessageEventFilters(true);

	elseif(event=="ADDON_LOADED" and tostring(select(1,...)) == "Rematch" ) then
		--We need to make several hooks for the Rematch PetJournal
		local callback = self["CALLBACK_Rematch"];
		if (callback ~= nil) then C_Timer.After(1, callback); end
	end
	return nil;
end


--####################################################################################
--####################################################################################
--Callback
--####################################################################################


function LinksInChat:CALLBACK_Blizzard_AchievementUI()
	--We need to make several hooks for the Achievement UI. One for each line in the UI
	local objName = _G["AchievementFrameAchievementsContainerButton1"];

	if (objName == nil) then
		local callback = LinksInChat["CALLBACK_Blizzard_AchievementUI"];
		C_Timer.After(1, callback); --Trigger function again in 1 second
		return nil;
	end--if

	LinksInChat:Hook1("AchievementFrameAchievementsContainerButton@", "OnClick", LinksInChat_AchievementButton_OnClick);

	LinksInChat["CALLBACK_Blizzard_AchievementUI"] = nil; --Cleanup this function when it's been run sucessfully. Only needs to be done once.
	return nil;
end


function LinksInChat:CALLBACK_Blizzard_TalentUI()
	--We need to make several hooks for the Talent UI. One for PvE and one for PvP
	local objName = _G["PlayerTalentFrameTalent_OnClick"];

	if (objName == nil) then
		local callback = LinksInChat["CALLBACK_Blizzard_TalentUI"];
		C_Timer.After(1, callback); --Trigger function again in 1 second
		return nil;
	end--if

	--Source: Blizzard_TalentUI\Blizzard_TalentUI.lua
	if (PlayerTalentFrameTalent_OnClick ~= nil)				then hooksecurefunc("PlayerTalentFrameTalent_OnClick", LinksInChat_PlayerTalentFrameTalent_OnClick); end
	if (PlayerTalentFramePVPTalentsTalent_OnClick ~= nil)	then hooksecurefunc("PlayerTalentFramePVPTalentsTalent_OnClick", LinksInChat_PlayerTalentFramePVPTalentsTalent_OnClick); end

	LinksInChat["CALLBACK_Blizzard_TalentUI"] = nil; --Cleanup this function when it's been run sucessfully. Only needs to be done once.
	return nil;
end


function LinksInChat:CALLBACK_Blizzard_Collections()
	--We need to make several hooks for the MountJournal UI. One for each button in the UI + for the icon button.
	--	Main element: "MountJournalListScrollFrameButton@".
	--	Sub element	: "MountJournalListScrollFrameButton@.DragButton"
	LinksInChat:Hook1_sub("MountJournalListScrollFrameButton@", "DragButton", "OnClick", "OnClick", LinksInChat_MountJournalListScrollFrameButton_OnClick, LinksInChat_MountJournalListScrollFrameButton_DragButton_OnClick);

	--We need to make several hooks for the PetJournal UI. One for each button in the UI + for the icon button.
	--	Main element: "PetJournalListScrollFrameButton@".
	--	Sub element	: "PetJournalListScrollFrameButton@.dragButton"
	LinksInChat:Hook1_sub("PetJournalListScrollFrameButton@", "dragButton", "OnClick", "OnClick", LinksInChat_PetJournalListScrollFrameButton_OnClick, LinksInChat_PetJournalListScrollFrameButton_dragButton_OnClick);

	--The abilities of the pet selected
	LinksInChat:Hook1("PetJournalPetCardSpell@", "OnClick", LinksInChat_PetJournalPetCardSpell_OnClick);

	--ToyBox
	hooksecurefunc("ToySpellButton_OnModifiedClick", LinksInChat_ToySpellButton_OnModifiedClick);

	--Heirlooms
	--hooksecurefunc("HeirloomsJournalSpellButton_OnClick", LinksInChat_HeirloomsJournalSpellButton_OnClick);

	--Appearances (Wardrobe) UI
	if (_G["WardrobeCollectionFrame"] ~= nil) then --2017-03-31: Patch 7.2.0 Legion. This hook is for the items shown in the Transmog UI aswell as the Collections tab.
		LinksInChat:Hook3_sub("WardrobeCollectionFrame", "ItemsCollectionFrame", "ModelR@1C@2", "OnMouseDown", LinksInChat_WardrobeItemsModelMixin_OnMouseDown);
	end
	if (_G["WardrobeSetsDetailsItemMixin"] ~= nil) then --2017-03-31: Patch 7.2.0 Legion. This patch added the "Sets" tab for itemssets under the Apperances collection.
		hooksecurefunc(WardrobeSetsDetailsItemMixin, "OnMouseDown", LinksInChat_WardrobeSetsDetailsItemMixin_OnMouseDown);
	end

	LinksInChat["CALLBACK_Blizzard_Collections"] = nil; --Cleanup this function when it's been run sucessfully. Only needs to be done once.
	return nil;
end


function LinksInChat:CALLBACK_Blizzard_GarrisonUI()
	--We need to make several hooks for the WOD Garrison / Legion Order Hall.
	local objName = _G["GarrisonFollowerListButton_OnModifiedClick"];

	if (objName == nil) then
		local callback = LinksInChat["CALLBACK_Blizzard_GarrisonUI"];
		C_Timer.After(1, callback); --Trigger function again in 1 second
		return nil;
	end--if

	--Followers List (both Landing Page and Mission Frame).
	--	(This hook also just works with OrderHallMissionFrameFollowersListScrollFrameButton2-10 for the Order Hall)
	hooksecurefunc("GarrisonFollowerListButton_OnModifiedClick", LinksInChat_GarrisonFollowerListButton_OnModifiedClick);

	--Landing Page: Report tab. In progress and Available mission list. Same UI element used for Legion Order Halls
	LinksInChat:Hook1("GarrisonLandingPageReportListListScrollFrameButton@", "OnClick", LinksInChat_GarrisonLandingPageReportMission_OnClick);

	LinksInChat["CALLBACK_Blizzard_GarrisonUI"] = nil; --Cleanup this function when it's been run sucessfully. Only needs to be done once.
	return nil;
end


function LinksInChat:CALLBACK_Blizzard_TokenUI()
	--Pre-hook
	--Source: AddOns\Blizzard_TokenUI\Blizzard_TokenUI.lua: TokenButton_OnClick()
	hook_TokenButton_OnClick = TokenButton_OnClick;
	TokenButton_OnClick = LinksInChat_TokenButton_OnClick;

	LinksInChat["CALLBACK_Blizzard_TokenUI"] = nil; --Cleanup this function when it's been run sucessfully. Only needs to be done once.
	return nil;
end


local cache_QuestLogRewardButton	= nil; --Index of the highest questlog rewardbutton that already have a hook installed.
local cache_MapQuestLogRewardButton	= nil; --Index of the highest questlog rewardbutton that already have a hook installed.
function LinksInChat:CALLBACK_LinksInChat_QuestInfo_ToggleRewardElement()
	--This is fired every time the quest reward frame is shown/hiden. All we need to do is check wether a new rewardbutton has been created this time around that's not already hooked into.

	--These buttons are not available until the user opens the questlog frame for the first time for a specific quest (i.e buttonN will not exist until you open a quest with N rewards).
	--QuestInfoRewardsFrameQuestInfoItem (classical full size reward frame)
	local CONST1, i = "QuestInfoRewardsFrameQuestInfoItem", 1; --QuestInfoRewardsFrameQuestInfoItem%
	if (cache_QuestLogRewardButton ~= nil) then i = cache_QuestLogRewardButton +1; end --Make loop faster by skipping over older items
	local objItem = _G[CONST1..i];

	while (objItem ~= nil) do
		objItem:HookScript("OnClick", LinksInChat_QuestInfoRewardsFrameQuestInfoItem_OnClick);
		cache_QuestLogRewardButton = i; --Save index after button has been hooked
		i = i +1;
		objItem = _G[CONST1..i];
	end--while

	--MapQuestInfoRewardsFrameQuestInfoItem (new type map+questlog combined frame)
	local CONST1, i = "MapQuestInfoRewardsFrameQuestInfoItem", 1; --MapQuestInfoRewardsFrameQuestInfoItem%
	if (cache_MapQuestLogRewardButton ~= nil) then i = cache_MapQuestLogRewardButton +1; end --Make loop faster by skipping over older items
	local objItem = _G[CONST1..i];

	while (objItem ~= nil) do
		objItem:HookScript("OnClick", LinksInChat_QuestInfoRewardsFrameQuestInfoItem_OnClick);
		cache_MapQuestLogRewardButton = i; --Save index after button has been hooked
		i = i +1;
		objItem = _G[CONST1..i];
	end--while

	return nil;
end


function LinksInChat:CALLBACK_ElvUI()
	--Hook into ElvUI bag. All bags/buttons are available from startup of the addon.
	local CONST1, CONST2, i, j = "ElvUI_ContainerFrameBag", "Slot", 0, 1; --ElvUI_ContainerFrameBag%Slot% (starts with 0)
	local objFrame, objItem = _G[CONST1..i], _G[CONST1..i..CONST2..j];

	while (i < 15) do --15 is just an arbitrary, large number
		while (objFrame ~= nil) do
			while (objItem ~= nil) do
				objItem:HookScript("OnClick", LinksInChat_ElvUI_ContainerFrameItem_OnClick); --Works with default Blizzard OnClick for bags
				j = j +1;
				objItem = _G[CONST1..i..CONST2..j]; --ElvUI_ContainerFrameBag%Slot%
			end--while objItem

			i = i +1;	--Increment counter
			j = 1;		--Reset before next inner loop
			objFrame = _G[CONST1..i];
			objItem = _G[CONST1..i..CONST2..j]; --ElvUI_ContainerFrameBag%Slot%
		end--while objFrame

		--There might be holes in the counter due to empty bag-slots
		i = i +1;	--Increment counter
		j = 1;		--Reset before next inner loop
		objFrame = _G[CONST1..i];
		objItem = _G[CONST1..i..CONST2..j]; --ElvUI_ContainerFrameBag%Slot%
	end--while i

	LinksInChat["CALLBACK_ElvUI"] = nil; --Cleanup this function when it's been run sucessfully. Only needs to be done once.
	return nil;
end


function LinksInChat:CALLBACK_ElvUI_BANK()
	--Hook into ElvUI bank bags. These bags/buttons are only available after BANKFRAME_OPENED has fired.
	local CONST1, CONST2, i, j = "ElvUI_BankContainerFrameBag-", "Slot", 1, 1; --ElvUI_BankContainerFrameBag-%Slot% (using - in the name only in the first set of bankslots)
	local objItem = _G[CONST1..i..CONST2..j];

	while (i < 15) do --15 is just an arbitrary, large number
		while (objItem ~= nil) do
			while (objItem ~= nil) do
				objItem:HookScript("OnClick", LinksInChat_ElvUI_ContainerFrameItem_OnClick); --Works with default Blizzard OnClick for bags
				j = j +1;
				objItem = _G[CONST1..i..CONST2..j]; --ElvUI_BankContainerFrameBag-%Slot%
			end--while objItem

			i = i +1;	--Increment bag
			j = 1;		--Reset itemslot
			objItem = _G[CONST1..i..CONST2..j]; --ElvUI_BankContainerFrameBag-%Slot%
		end--while

		--There might be holes in the counter due to empty bag-slots
		i = i +1;	--Increment counter
		j = 1;		--Reset before next inner loop
		objFrame = _G[CONST1..i];
		objItem = _G[CONST1..i..CONST2..j]; --ElvUI_BankContainerFrameBag-%Slot%
	end--while i


	--For some strange reason, ElvUI uses a hypen in the first set of bankslots and then no hypen in the rest.
	--The numbering is also strange, seeming to start with 5. This code will iterate from 1 to 15 just to make sure.
	local CONST1, CONST2, i, j = "ElvUI_BankContainerFrameBag", "Slot", 1, 1; --ElvUI_BankContainerFrameBag-%Slot% (not having - in this set)
	local objItem = _G[CONST1..i..CONST2..j];

	while (i < 15) do --15 is just an arbitrary, large number
		while (objItem ~= nil) do
			while (objItem ~= nil) do
				objItem:HookScript("OnClick", LinksInChat_ElvUI_ContainerFrameItem_OnClick); --Works with default Blizzard OnClick for bags
				j = j +1;
				objItem = _G[CONST1..i..CONST2..j]; --ElvUI_BankContainerFrameBag%Slot%
			end--while objItem

			i = i +1;	--Increment bag
			j = 1;		--Reset itemslot
			objItem = _G[CONST1..i..CONST2..j]; --ElvUI_BankContainerFrameBag%Slot%
		end--while

		--There might be holes in the counter due to empty bag-slots
		i = i +1;	--Increment counter
		j = 1;		--Reset before next inner loop
		objFrame = _G[CONST1..i];
		objItem = _G[CONST1..i..CONST2..j]; --ElvUI_BankContainerFrameBag%Slot%
	end--while i

	LinksInChat["CALLBACK_ElvUI_BANK"] = nil; --Cleanup this function when it's been run sucessfully. Only needs to be done once.
	return nil;
end


function LinksInChat:CALLBACK_ElvUI_ReagentBankFrameItem()
	--Reagent frame buttons does not exist until the user presses the reagent button in the bank. Starts a sleep loop when the bank frame is opened until it closes.
	local objItem = _G["ElvUIReagentBankFrameItem1"];

	if (objItem == nil) then
		if (BankFrame:IsShown() == false) then return nil; end --Will make the loop stop if the BankFrame is closed. Will start again whenever the bank frame is openend again.
		local callback = LinksInChat["CALLBACK_ElvUI_ReagentBankFrameItem"];
		C_Timer.After(1, callback); --Trigger function again in 1 second
		return nil;
	end--if

	LinksInChat:Hook1("ElvUIReagentBankFrameItem@", "OnClick", LinksInChat_ElvUI_ContainerFrameItem_OnClick); --Reuse the same function as for bags

	LinksInChat["CALLBACK_ElvUI_ReagentBankFrameItem"] = nil; --Cleanup this function when it's been run sucessfully. Only needs to be done once.
	return nil;
end


local cache_WIMWindowList = nil; --Index of the highest WIM window that already have a hook installed.
function LinksInChat:CALLBACK_WIM()
	--Hook into WIM addon chat frames.
	--These windows are not available until the first chat message appears. Need therefore to check for their existense.
	local CONST1, i, CONST2 = "WIM3_msgFrame", 1, "ScrollingMessageFrame"; --WIM3_msgFrame%ScrollingMessageFrame
	if (cache_WIMWindowList ~= nil) then i = cache_WIMWindowList +1; end --Make loop faster by skipping over older items
	local objItem = _G[CONST1..i..CONST2];

	while (objItem ~= nil) do
		objItem:HookScript("OnHyperlinkClick", LinksInChat_WIM_OnHyperlinkShow);
		cache_WIMWindowList = i; --Save index after button has been hooked
		i = i +1; --Increment counter
		objItem = _G[CONST1..i..CONST2];
	end--while

	local callback = LinksInChat["CALLBACK_WIM"];
	C_Timer.After(1, callback); --Sleep and re-check again in 1 second
	return nil;
end


local hook_Rematch_PetListButtonOnClick		= nil; --Rematch addon. Pre-hook needed for its Pet Journal
local hook_Rematch_PetListButtonPetOnClick	= nil; --Rematch addon. Pre-hook needed for its Pet Journal
function LinksInChat:CALLBACK_Rematch()
	--We need to make 2 hooks for the Rematch PetJournal. One for the button and one for the icon.
	--Source: AddOns\Rematch\Widgets\PetListButtons.lua: PetListButtonOnClick()/PetListButtonPetOnClick()

	--Does Rematch exist in _G
	if (Rematch == nil or type(Rematch) ~= "table") then
		local callback = LinksInChat["CALLBACK_Rematch"];
		C_Timer.After(1, callback); --Sleep and re-check again in 1 second
		return nil;
	end

	--Need to do a pre-hook into Rematch's widget
	hook_Rematch_PetListButtonOnClick	 = Rematch["PetListButtonOnClick"];
	hook_Rematch_PetListButtonPetOnClick = Rematch["PetListButtonPetOnClick"];
	Rematch["PetListButtonOnClick"]		= LinksInChat_Rematch_PetListButtonOnClick;		--Title of the pet
	Rematch["PetListButtonPetOnClick"]	= LinksInChat_Rematch_PetListButtonPetOnClick;	--Icon of the pet

	LinksInChat["CALLBACK_Rematch"] = nil; --Cleanup this function when it's been run sucessfully. Only needs to be done once.
	return nil;
end


--####################################################################################
--####################################################################################
--Settings
--####################################################################################


--Returns the current value for a setting.
function LinksInChat:GetCurrentSetting(strSetting, expectedType, overrideValue)
	if (strSetting == nil) then return nil end
	strSetting = strupper(strSetting);
	local res = LINKSINCHAT_settings[strSetting];
	--print("GetCurrentSetting '"..strSetting.."', '"..tostring(res).."'");

	if (expectedType ~= nil and type(expectedType) == "string") then --types: number, string, boolean, function, nil, userdata, thread, table
		if (strlower(type(res)) ~= strlower(expectedType)) then
			--This will also happen when the addon is run the first time; no settings are then saved and it will return nil for everything
			--print ("GetCurrentSetting: Type mismatch on '"..tostring(strSetting).."' resetting to value '"..tostring(overrideValue).."'");
			return overrideValue;
		end--if type
	end--if expectedType
	return res;
end


--Sets the current value for a setting.
function LinksInChat:SetCurrentSetting(strSetting, objValue)
	if (strSetting == nil) then return nil end
	strSetting = strupper(strSetting);
	--print("SetCurrentSetting '"..strSetting.."', '"..tostring(objValue).."'");
	LINKSINCHAT_settings[strSetting] = objValue;
	return objValue;
end

--####################################################################################
--####################################################################################
--Slash commands
--####################################################################################


--Handler for slash commands
function LinksInChat:Slash(cmd)
	cmd = strtrim(strlower(cmd)); --tweak the input string

	--Only 1 command supported here: "/link"
	local unit = nil;
	if (GetUnitName("mouseover") ~= nil)	then unit = "mouseover"; end
	if (GetUnitName("target") ~= nil)		then unit = "target"; end

	local name, data = nil, nil;
	if (unit == nil) then
		--Try looking up mouseover using GameTooltip.
		local link = nil;
		name, link = GameTooltip:GetItem();
		if (link == nil) then
			name = self:GetFirstTooltipLines(GameTooltip); --Second try: just get the name in GameTooltip
		else
			data, name = self:HyperLink_Strip2(link);
		end--if link

	else
		if (UnitIsPlayer(unit) == true) then return nil end --Skip player names
		name = GetUnitName(unit); --Only works for npcs
		local id = self:getNPCID(unit);
		if (id ~= nil) then data = "npc:"..tostring(id); end --NPC advanced link
	end

	self:CopyFrame_Show("other", name, data);
	return nil;
end


--Support function to lookup NPCid. Based on IfThen_Methods:getNPCNameFromGUID(unit)
function LinksInChat:getNPCID(unit)
	local guid = UnitGUID(unit); --GUID format was changed in patch 6.0 to use a delimted format.
	if (guid == nil) then return nil; end
	--New Globally Unique Identifier format: Source: http://wowpedia.org/Patch_6.0.1/API_changes#Changes
		--For players: Player-[server ID]-[player UID] (Example: "Player:976:0002FD64")
		--For creatures, pets, objects, and vehicles: [Unit type]-0-[server ID]-[instance ID]-[zone UID]-[ID]-[Spawn UID] (Example: "Creature-0-976-0-11-31146-000136DF91")
		--Unit Type Names: "Creature", "Pet", "GameObject", and "Vehicle"
		--For vignettes: Vignette-0-[server ID]-[instance ID]-[zone UID]-0-[spawn UID] (Example: "Vignette-0-970-1116-7-0-0017CAE465" for rare mob Sulfurious)
	local tmp = LinkWebParsing:split(guid, "-"); --"Creature-0-1135-1116-82308-00006376D9"  - Shadowmoon Stalker (lvl 90 beast), 6th element is the NPCID
	if (tmp == nil) then return nil; end
	if (strlower(tostring(tmp[1])) ~= "creature") then return nil; end --ignore anything but creatures
	local npcID = tonumber(tmp[6]); --6th element in the array is the NPC ID
	return npcID;
end


--Return the 1st line in a gametooltip. Will return nil if nothing is found. Based on HiddenTooltip:GetAllTooltipLines()
function LinksInChat:GetFirstTooltipLines(objTooltip)
	--Get all regions for the tooltip object, iterate though these and return the result as an table, will skip empty lines
	--Source: http://www.wowwiki.com/UIOBJECT_GameTooltip
	local allRegions = {objTooltip:GetRegions()};
	if (#allRegions == 0) then return nil; end
	local tbl = {};
	for i=1, #allRegions do
        local currRegion = allRegions[i];
        if (currRegion ~=nil and currRegion:GetObjectType() == "FontString") then
            local text = currRegion:GetText() -- string or nil
			if (text ~= nil) then tbl[#tbl+1] = text; end
        end
    end--for i
	if (#tbl == 0) then return nil; end
	return tbl[1];--return tbl;
end


--Traverses _G in search for _G["SLASH_*"] keys and will then try to see if the named key already exists. Returns both it's Key and Value in _G.
function LinksInChat:findInSlashList(name)
	local strlower	= strlower; --local fpointer
	local strtrim	= strtrim;
	local pairs		= pairs;
	local type		= type;
	local strfind	= strfind;

	local _G		= _G;
	local strKey	= "SLASH_";
	local strValue	= strtrim(strlower(name)); --"/";

	for k,v in pairs(_G) do --go though _G and find all the "SLASH_" entries
		if (type(k) == "string") then
			local sPos1 = strfind(k, strKey, 1, true); --plain find starting at pos 1 in the string
			if (sPos1 == 1) then
				if (type(v) == "string" and strtrim(strlower(v)) == strValue) then --key must start with SLASH_ and the value must match
					return k, v;
				end--if type
			end--if sPos1
		end--if type()
	end--for k,v
	return nil, nil;
end


--Set Debuglevel
function LinksInChat_Debug(intDebug)
	if (intDebug == nil) then
		print("LinksInChat: Debug level is currently "..tostring(cache_Debug));
	else
		if (type(intDebug) ~= "number")	then intDebug = 0; end --only numbers
		if (intDebug < 0)				then intDebug = 0; end --minvalue
		LinksInChat:SetCurrentSetting("Debug", intDebug);
		cache_Debug = LinksInChat:GetCurrentSetting("Debug");
		print("LinksInChat: Debug level has been changed to "..tostring(cache_Debug));
	end--if nil
	return cache_Debug;
end


--Print function for Debug messages
function LinksInChat:dPrint(intLevel, strFunction, ...)
	--intLevel		: debug level to output
	--strFunction	: calling function
	--...			: list of values that is to be outputted. If you input a string 2 times in a row then function will assume its a hyperlink and replace the | with - on the second string.
	if (cache_Debug == 0 or intLevel == nil or type(intLevel) ~= "number" or intLevel < 1) then return nil; end --only accept whole numbers
	if not(intLevel == cache_Debug or intLevel < cache_Debug) then return nil; end --only accept if intLevel is equal or lower than cache_Debug's debuglevel

	local s, cur, prev = tostring(strFunction)..":", nil, nil;
	for i = 1, select("#", ...) do
		cur = select(i,...);
		if (i >1 and prev == cur and type(cur) == "string") then
			--if we get the same string 2 times in a row, then replace it's | with - (most likely a hyperlink)
			cur = gsub(cur, "|", "-");
		end--if
		s = s.."\n    '"..tostring(cur).."'";
		prev = cur; --save for next iteration
	end--for i
	return print(strtrim(s));
end


--####################################################################################
--####################################################################################
--Settings frame
--####################################################################################


function LinksInChat:SettingsFrame_OnLoad(panel)
	-- Set the name of the Panel
	panel.name = Locale["CopyFrame Title"];	--"LinksInChat";
	panel.default	= function (self) end;	--So few settings that we simply ignore the reset button
	InterfaceOptions_AddCategory(panel);	--Add the panel to the Interface Options
end


--Called after settings related to search provider has been changed
function LinksInChat:UpdateProvider()
	--Get current settings
	local s_English			= self:GetCurrentSetting("AlwaysEnglish", "boolean", false);
	local s_Provider		= self:GetCurrentSetting("Provider", "string", "wowhead");

	--Validate search provider
	SearchProvider:InitializeProvider(s_English);
	if (SearchProvider:ProviderExists(s_Provider) ~= true) then s_Provider = "wowhead"; end
	cache_Provider = SearchProvider:GetProvider(s_Provider);

	return nil;
end


--####################################################################################
--####################################################################################
--Settings frame - Color picker
--####################################################################################


function LinksInChat:ShowColorPicker(objTexture)
	local strColor	= self:GetCurrentSetting("Color");
	local r,g,b		= self:HexColorToRGBPercent(strColor);

	local cf = ColorPickerFrame;
	cf:SetColorRGB(r,g,b);
	cf.hasOpacity = false; --We dont have Alpha for link colors.
	cf.opacity = 1;

	local f = function() end;
	local o = function() LinksInChat:ColorPicker_Callback("ok", objTexture) end;
	local c = function() LinksInChat:ColorPicker_Callback("cancel", objTexture) end;
	cf.func, cf.opacityFunc, cf.cancelFunc = f, o, c;
	cf:Hide(); -- Need to run the OnShow handler.
	cf:Show();
	return nil;
end


function LinksInChat:ColorPicker_Callback(restore, objTexture)
	local cf = ColorPickerFrame;

	if (restore == "ok") then --'ok' or 'cancel'
		local r,g,b = cf:GetColorRGB();
		--local a = OpacitySliderFrame:GetValue();
		if (objTexture["SetColorTexture"] ~= nil) then
			objTexture:SetColorTexture(r,g,b,1); --2016-05-14: Patch 7.0.3 Legion Addded SetColorTexture() to be used instead of SetTexture()
		else
			objTexture:SetTexture(r,g,b,1);
		end
		cache_Color_HyperLinks = self:RGBPercentToHex(r,g,b); --HEX formatted string
		self:SetCurrentSetting("Color", cache_Color_HyperLinks);
	end--if restore

	--Cleanup
	local f = function() end;
	cf.func, cf.opacityFunc, cf.cancelFunc = f,f,f;
	return nil;
end


--Takes a RGB percent set (0.0-1.0) and converts it to a hex string.
function LinksInChat:RGBPercentToHex(r,g,b)
	--Source: http://www.wowwiki.com/RGBPercToHex
	r = r <= 1 and r >= 0 and r or 0;
	g = g <= 1 and g >= 0 and g or 0;
	b = b <= 1 and b >= 0 and b or 0;
	return strupper(format("%02x%02x%02x", r*255, g*255, b*255));
end


--Returns r, g, b for a given hex colorstring
function LinksInChat:HexColorToRGBPercent(strHexColor)
	--Expects: RRGGBB  --Red, Green, Blue
	if (strlen(strHexColor) ~= 6) then return nil end
	local tonumber	= tonumber; --local fpointer
	local strsub	= strsub;

	local r, g, b = (tonumber( strsub(strHexColor,1,2), 16) /255), (tonumber( strsub(strHexColor,3,4), 16) /255), (tonumber( strsub(strHexColor,5,6), 16) /255);
	if (r==nil or g==nil or b==nil) then return nil end
	return r, g, b;
end


--####################################################################################
--####################################################################################
--Settings frame - Dropdown menus
--####################################################################################
--Source: InterfaceOptionsPanel.lua, InterfaceOptionsPanel.xml ($parentAutoLootKeyDropDown)

--[[
function LinksInChat:Settings_Frame_DropDown_KeyModifier_OnEvent(objSelf, event, ...)
	if ( event == "PLAYER_ENTERING_WORLD" ) then
		objSelf.defaultValue = "ALT";
		objSelf.oldValue = self:GetCurrentSetting("KeyModifier");
		objSelf.value = objSelf.oldValue or objSelf.defaultValue;

		local init = function(...) return self.Settings_Frame_DropDown__KeyModifier_Initialize(self,...) end; --This function is called each time the Dropdown menu is clicked

		UIDropDownNoTaintMenu_SetWidth(objSelf, 90);
		UIDropDownNoTaintMenu_Initialize(objSelf, init);
		UIDropDownNoTaintMenu_SetSelectedValue(objSelf, objSelf.value);

		objSelf.SetValue		=	function(objSelf, value)
										objSelf.value = value
										UIDropDownNoTaintMenu_SetSelectedValue(objSelf, value)
										self:SetCurrentSetting("KeyModifier", value)
										if		(value == "SHIFT") then	LinksInChat_IsKeyDown = IsShiftKeyDown --Globals that must return true/false
										elseif	(value == "CTRL")  then	LinksInChat_IsKeyDown = IsControlKeyDown
										else							LinksInChat_IsKeyDown = IsAltKeyDown --Default is ALT
										end--if
									end;
		objSelf.GetValue		=	function(objSelf)
										return UIDropDownNoTaintMenu_GetSelectedValue(objSelf)
									end;
		objSelf.RefreshValue	=	function (objSelf)
										UIDropDownNoTaintMenu_Initialize(objSelf, init)
										UIDropDownNoTaintMenu_SetSelectedValue(objSelf, objSelf.value)
									end;
		objSelf:UnregisterEvent(event);
	end--if event
end

function LinksInChat_Settings_Frame_DropDown_KeyModifier_OnClick(self)
	--We declare this one here. If we declared it inline in :Settings_Frame_DropDown__KeyModifier_Initialize(), it would mean that every time that the user clicked the dropdown it would generate a new and wasted function pointer
	LinksInChatXML_Settings_Frame_DropDown_KeyModifier:SetValue(self.value);
end

function LinksInChat:Settings_Frame_DropDown__KeyModifier_Initialize()
	local selectedValue = UIDropDownNoTaintMenu_GetSelectedValue(LinksInChatXML_Settings_Frame_DropDown_KeyModifier);
	local info = UIDropDownNoTaintMenu_CreateInfo();

	local Lsub = Locale["Dropdown Options KeyModifier"];
	info.text = Lsub["ALT"];
	info.func = LinksInChat_Settings_Frame_DropDown_KeyModifier_OnClick;
	info.value = "ALT";
	if ( info.value == selectedValue ) then
		info.checked = true;
	else
		info.checked = false;
	end
	UIDropDownNoTaintMenu_AddButton(info);

	info.text = Lsub["CTRL"];
	info.func = LinksInChat_Settings_Frame_DropDown_KeyModifier_OnClick;
	info.value = "CTRL";
	if ( info.value == selectedValue ) then
		info.checked = true;
	else
		info.checked = false;
	end
	UIDropDownNoTaintMenu_AddButton(info);

	info.text = Lsub["SHIFT"];
	info.func = LinksInChat_Settings_Frame_DropDown_KeyModifier_OnClick;
	info.value = "SHIFT";
	if ( info.value == selectedValue ) then
		info.checked = true;
	else
		info.checked = false;
	end
	UIDropDownNoTaintMenu_AddButton(info);
end
]]--


function LinksInChat:Settings_Frame_DropDown_AutoHide_OnEvent(objSelf, event, ...)
	if ( event == "PLAYER_ENTERING_WORLD" ) then
		objSelf.defaultValue = -1;
		objSelf.oldValue = self:GetCurrentSetting("AutoHide");
		objSelf.value = objSelf.oldValue or objSelf.defaultValue;

		local init = function(...) return self.Settings_Frame_DropDown__AutoHide_Initialize(self,...) end; --This function is called each time the Dropdown menu is clicked

		UIDropDownNoTaintMenu_SetWidth(objSelf, 150);
		UIDropDownNoTaintMenu_Initialize(objSelf, init);
		UIDropDownNoTaintMenu_SetSelectedValue(objSelf, objSelf.value);

		objSelf.SetValue		=	function(objSelf, value)
										objSelf.value = value
										UIDropDownNoTaintMenu_SetSelectedValue(objSelf, value)
										self:SetCurrentSetting("AutoHide", value)
									end;
		objSelf.GetValue		=	function(objSelf)
										return UIDropDownNoTaintMenu_GetSelectedValue(objSelf)
									end;
		objSelf.RefreshValue	=	function (objSelf)
										UIDropDownNoTaintMenu_Initialize(objSelf, init)
										UIDropDownNoTaintMenu_SetSelectedValue(objSelf, objSelf.value)
									end;
		objSelf:UnregisterEvent(event);
	end--if event
end

function LinksInChat_Settings_Frame_DropDown_AutoHide_OnClick(self)
	--We declare this one here. If we declared it inline in :Settings_Frame_DropDown__AutoHide_Initialize(), it would mean that every time that the user clicked the dropdown it would generate a new and wasted function pointer
	LinksInChatXML_Settings_Frame_DropDown_AutoHide:SetValue(self.value);
end

function LinksInChat:Settings_Frame_DropDown__AutoHide_Initialize()
	local selectedValue = UIDropDownNoTaintMenu_GetSelectedValue(LinksInChatXML_Settings_Frame_DropDown_AutoHide);
	local info = UIDropDownNoTaintMenu_CreateInfo();

	local Lsub = Locale["Dropdown Options Autohide"];
	info.text = Lsub["none"]; --"Don't hide";
	info.func = LinksInChat_Settings_Frame_DropDown_AutoHide_OnClick;
	info.value = -1;
	if ( info.value == selectedValue ) then
		info.checked = true;
	else
		info.checked = false;
	end
	UIDropDownNoTaintMenu_AddButton(info);

	info.text = Lsub["3sec"]; --"3 seconds";
	info.func = LinksInChat_Settings_Frame_DropDown_AutoHide_OnClick;
	info.value = 3;
	if ( info.value == selectedValue ) then
		info.checked = true;
	else
		info.checked = false;
	end
	UIDropDownNoTaintMenu_AddButton(info);

	info.text = Lsub["5sec"]; --"5 seconds";
	info.func = LinksInChat_Settings_Frame_DropDown_AutoHide_OnClick;
	info.value = 5;
	if ( info.value == selectedValue ) then
		info.checked = true;
	else
		info.checked = false;
	end
	UIDropDownNoTaintMenu_AddButton(info);

	info.text = Lsub["7sec"]; --"7 seconds";
	info.func = LinksInChat_Settings_Frame_DropDown_AutoHide_OnClick;
	info.value = 7;
	if ( info.value == selectedValue ) then
		info.checked = true;
	else
		info.checked = false;
	end
	UIDropDownNoTaintMenu_AddButton(info);

	info.text = Lsub["10sec"]; --"10 seconds";
	info.func = LinksInChat_Settings_Frame_DropDown_AutoHide_OnClick;
	info.value = 10;
	if ( info.value == selectedValue ) then
		info.checked = true;
	else
		info.checked = false;
	end
	UIDropDownNoTaintMenu_AddButton(info);
end


function LinksInChat:Settings_Frame_DropDown_Provider_OnEvent(objSelf, event, ...)
	if ( event == "PLAYER_ENTERING_WORLD" ) then
		objSelf.defaultValue = "wowhead";
		objSelf.oldValue = self:GetCurrentSetting("Provider");
		objSelf.value = objSelf.oldValue or objSelf.defaultValue;

		local init = function(...) return self.Settings_Frame_DropDown__Provider_Initialize(self,...) end; --This function is called each time the Dropdown menu is clicked

		UIDropDownNoTaintMenu_SetWidth(objSelf, 220);
		UIDropDownNoTaintMenu_Initialize(objSelf, init);
		UIDropDownNoTaintMenu_SetSelectedValue(objSelf, objSelf.value);

		objSelf.SetValue		=	function(objSelf, value)
										objSelf.value = value
										UIDropDownNoTaintMenu_SetSelectedValue(objSelf, value)
										self:SetCurrentSetting("Provider", value)
										self:UpdateProvider()
									end;
		objSelf.GetValue		=	function(objSelf)
										return UIDropDownNoTaintMenu_GetSelectedValue(objSelf)
									end;
		objSelf.RefreshValue	=	function (objSelf)
										UIDropDownNoTaintMenu_Initialize(objSelf, init)
										UIDropDownNoTaintMenu_SetSelectedValue(objSelf, objSelf.value)
									end;
		objSelf:UnregisterEvent(event);
	end--if event
end

function LinksInChat_Settings_Frame_DropDown_Provider_OnClick(self)
	--We declare this one here. If we declared it inline in :Settings_Frame_DropDown__Provider_Initialize(), it would mean that every time that the user clicked the dropdown it would generate a new and wasted function pointer
	LinksInChatXML_Settings_Frame_DropDown_Provider:SetValue(self.value);
end

function LinksInChat:Settings_Frame_DropDown__Provider_Initialize()
	local selectedValue = UIDropDownNoTaintMenu_GetSelectedValue(LinksInChatXML_Settings_Frame_DropDown_Provider);
	local info = UIDropDownNoTaintMenu_CreateInfo();

	local tblProviders, tblSorted = SearchProvider:GetProvider("all");

	for i = 1, #tblSorted do --tblSorted gives us a sorted list of the key's
		local providerKey	= strlower(tostring(tblSorted[i])); --key = "provider uniqe name", data = table with localized provider data
		local title			= tblProviders[providerKey]["Title"];
		info.text = title;
		info.func = LinksInChat_Settings_Frame_DropDown_Provider_OnClick;
		info.value = providerKey;
		if ( info.value == selectedValue ) then
			info.checked = true;
		else
			info.checked = false;
		end
		UIDropDownNoTaintMenu_AddButton(info);
	end--for i
	return nil;
end


--####################################################################################
--####################################################################################
--Copy link frame
--####################################################################################


--Callback used to iterate on the CopyFrame
local TimerTicker		= nil;	--nil or pointer to a ticker object.
local TimerIteration	= 0;	--Counts down from X until 0

function LinksInChat:CopyFrame_TimerTick()
	TimerIteration = TimerIteration -1;
	LinksInChat_Copy_Frame_Countdown:SetText(TimerIteration);

	if (TimerIteration <= 0) then --We only execute this code once to hide the frame
		LinksInChat_Copy_Frame:Hide(); --Hide the frame
		LinksInChat_Copy_Frame_Countdown:SetText("");
		TimerIteration = 0;
		TimerTicker = nil;
		collectgarbage("collect"); --force a garbage collection
	end	--if
	return nil;
end


function LinksInChat:RawLink()
	cache_rawLink = not cache_rawLink;
	return print("LinksInChat rawLink set to: "..tostring(cache_rawLink));
end


function LinksInChat:CopyFrame_Show(linkType, text, link)
	--linkType: either 'wcl' or 'other'. If it's wcl then its a www or http:// link and we use text. Otherwise its a hyperlink and we must use that
	--returns: true if the linktype is unknown and the link should be propagated further. otherwise false.
	local message, res = "", true;

	if (linkType == "wcl") then
		message = self:WebLink_Strip(text);
		res = false;
	else
		if (self:GetCurrentSetting("IgnoreHyperlinks") == true) then return true; end --Return immediatly if we are to ignore hyperlinks all together
		message = LinkWebParsing:getHyperLinkURI(link, text, cache_Provider, self:GetCurrentSetting("Simple"), self:GetCurrentSetting("UseHTTPS") ); --Returns an string or nil.
		if (message == nil) then return true; end --Will be nil if we do not support the hyperlink.
		res = false;
	end--if linkType

	--Output a raw itemlink. Used for debugging
	if (cache_rawLink == true) then message = tostring(link).."["..tostring(text).."]"; end

	--Display frame with pre-selected uri ready to be copied to the clipboard
	LinksInChat_Copy_Frame:Hide();
	LinksInChat_Copy_Frame_Countdown:SetText("");
	LinksInChat_Copy_Frame_EditBox:SetText(message);
	LinksInChat_Copy_Frame:Show();
	LinksInChat_Copy_Frame_EditBox:SetFocus();
	--LinksInChat_Copy_Frame:SetFrameStrata("DIALOG"); --LinksInChat_Copy_Frame:SetFrameStrata("HIGH");
	--LinksInChat_Copy_Frame:SetToplevel(true);

	--Create a timer-ticker that will get invokes every second until the Display is to be hidden.
	local sec = tonumber(self:GetCurrentSetting("AutoHide")); --Will count down from X until 0. Then the form will hide itself.
	if (sec ~= nil and sec > 0) then
		if (TimerTicker ~= nil) then TimerTicker:Cancel(); end --Cancel any potentially still running timer

		LinksInChat_Copy_Frame_Countdown:SetText(tostring(sec));
		TimerIteration = sec;
		local callback = self["CopyFrame_TimerTick"];
		TimerTicker = C_Timer.NewTicker(1, callback, sec);
	end--if sec
	return res;
end


function LinksInChat:CopyFrame_ExtraShow(link)
	--Subfunction used by alot of hooks since most of their code identical
	if (link == nil)			then return false; end --if link is nil then its a empty slot.
	if (LinksInChat_IsKeyDown()==false)	then return false; end --If alt-key isnt pressed then skip this.
	if (LinksInChat:GetCurrentSetting("Extra") == false)	then return false; end
	ClearCursor();

	local data, text = LinksInChat:HyperLink_Strip2(link);
	LinksInChat:CopyFrame_Show("other", text, data); --Show the text of the link
	return true;
end


--####################################################################################
--####################################################################################
--Custom hyperlink handling
--####################################################################################


--Returns a wcl: hyperlink in the correct format
function LinksInChat:HyperLink_Create(title)
	--Format: |cFF000000|Hwcl:|h[title]|h|r
	local res = "|cFF@COLOR@|Hwcl:|h@TITLE@|h|r";
	res = LinkWebParsing:replace(res, "@COLOR@", cache_Color_HyperLinks);
	res = LinkWebParsing:replace(res, "@TITLE@", tostring(title) ); --Manually add [ ] if you want that as part of the title
	return res;
end


--Removes any weblink data from the string
function LinksInChat:WebLink_Strip(link)
	--[[
		Weblinks can be inside Weblinks (www. inside http://)
		Hyperlinks can not be inside weblinks
		"Hello|cFF000000http://www.link.com|h|r|cff000000[item]|h|rWorld"
	]]--
	local link2 = LinkWebParsing:replace(link, "|cFF"..tostring(cache_Color_HyperLinks).."|Hwcl:|h", ""); --plain replace of the whole beginning of the string
	local link2 = LinkWebParsing:replace(link, "|cFF"..tostring(cache_Color_HyperLinks).."|Hwcl:|h", ""); --plain replace of the whole beginning of the string
	if (link2 ~= link) then
		link2 = LinkWebParsing:replace(link2, "|h|r", ""); --plain replace at the end of the string
		return link2;
	end
	return link;
end


--Returns the plain text title of a web-link (http:// etc)
function LinksInChat:HyperLink_Strip(link)
	local p = "%|h(.-)%|h%|r"; --Just the text inside the hyperlink (note we dont use the [ ] in web-links
	local startPos, endPos, firstWord, restOfString = strfind(link, p);
	if (firstWord ~= nil) then return firstWord; end
	return nil;
end


--Returns the linkdata and plain text of a hyperlink
function LinksInChat:HyperLink_Strip2(link)
	local p = "%H(.-)%|h%[(.-)%]%|h%|r"; --Just the text inside the hyperlink (note that we use [ ] here)
	local startPos, endPos, firstWord, restOfString = strfind(link, p);
	if (firstWord ~= nil) then return firstWord, restOfString; end
	return nil;
end


local hook_ItemRefTooltip_SetHyperlink = ItemRefTooltip["SetHyperlink"];
--Hook prevents addon hyperlinks to be propagated all the way down to Blizzard code
function ItemRefTooltip:SetHyperlink(link, ...)
	if (link:sub(0, 4) == "wcl:") then return nil end;
	return hook_ItemRefTooltip_SetHyperlink(self, link, ...);
end


--####################################################################################
--####################################################################################
--Hook functions
--####################################################################################


--Create a post-hook for a list of buttons/etc
function LinksInChat:Hook1(CONST1, scriptName1, hookPointer1)
	--	CONST1:			String. "Name@ where @ is the index number location. "MyLootButton@" --> "MyLootButton1", 2, 3 etc
	--	scriptName1:	String. "Name of event to hook into. "OnClick"
	--	hookPointer1:	Function. Pointer to the eventhandler to call.
	--Returns: Index for the last hooked button or nil

	local f = LinkWebParsing["replace"]; --local fpointer
	local i = 1;
	local n = f(LinkWebParsing, CONST1, "@", tostring(i));
	local objName1 = _G[n];	--PetJournalListScrollFrameButton@
	if (objName1 == nil) then return nil; end --no object found

	while (objName1 ~= nil) do
		objName1:HookScript(scriptName1, hookPointer1);
		i = i +1;
		n = f(LinkWebParsing, CONST1, "@", tostring(i));
		objName1 = _G[n];
	end--while
	return (i-1);
end


--Create a post-hook for a list of buttons/etc (just 1 index, but has a single sub-element aswell).
function LinksInChat:Hook1_sub(CONST1, CONST2, scriptName1, scriptName2, hookPointer1, hookPointer2)
	--	CONST1:			String. "Name@ where @ is the index number location. "MyLootButton@" --> "MyLootButton1", 2, 3 etc
	--	CONST2:			String. "Subelement of CONST1 "MyLootButton@.Subelement" --> "MyLootButton1.Subelement"
	--	scriptName1:	String. "Name of event to hook into. "OnClick"
	--	scriptName2:
	--	hookPointer1:	Function. Pointer to the eventhandler to call.
	--	hookPointer2:
	--Returns: Index for the last hooked button or nil

	local f = LinkWebParsing["replace"]; --local fpointer
	local i = 1;
	local n = f(LinkWebParsing, CONST1, "@", tostring(i));
	local objName1 = _G[n];	--MountJournalListScrollFrameButton@
	if (objName1 == nil) then return nil; end --no object found

	local objName2 = nil;	--subelement of MountJournalListScrollFrameButton@.DragButton
	if (objName1 ~= nil) then objName2 = objName1[CONST2]; end

	while (objName1 ~= nil) do
		objName1:HookScript(scriptName1, hookPointer1);
		objName2:HookScript(scriptName2, hookPointer2);
		i = i +1;
		n = f(LinkWebParsing, CONST1, "@", tostring(i));
		objName1 = _G[n];
		if (objName1 ~= nil) then objName2 = objName1[CONST2]; end
	end--while
	return (i-1);
end


--Create a post-hook for a list of buttons/etc (3 levels deep, with 2 indexes)
function LinksInChat:Hook3_sub(CONST1, CONST2, CONST3, scriptName1, hookPointer1)
	--	CONST1:			String. "Name"
	--	CONST2:			String. "Name.Name"
	--	CONST3:			String. "Name.Name.NameR@1C@2" where @1 is the i-index and @2 is the j-index.
	--	scriptName1:	String. "Name of event to hook into. "OnMouseDown"
	--	hookPointer1:	Function. Pointer to the eventhandler to call.
	--Returns: i-Index for the last hooked button or nil

	local f = LinkWebParsing["replace"]; --local fpointer
	local i = 1;
	local j = 1;
	local n = f(LinkWebParsing, CONST3, "@1", tostring(i));
		  n = f(LinkWebParsing, n,		"@2", tostring(j));
	local objName1 = _G[CONST1][CONST2][n];	--WardrobeCollectionFrame.ModelsFrame.ModelR1C1
	if (objName1 == nil) then return nil; end --no object found

	while (objName1 ~= nil) do --i
		while (objName1 ~= nil) do --j
			objName1:HookScript(scriptName1, hookPointer1);
			j = j +1;

			n = f(LinkWebParsing, CONST3, "@1", tostring(i));
			n = f(LinkWebParsing, n,	  "@2", tostring(j));
			objName1 = _G[CONST1][CONST2][n];	--WardrobeCollectionFrame.ModelsFrame.ModelR1C1
		end--while j

		i = i +1;
		j = 1;
		n = f(LinkWebParsing, CONST3, "@1", tostring(i));
		n = f(LinkWebParsing, n,	  "@2", tostring(j));
		objName1 = _G[CONST1][CONST2][n];	--WardrobeCollectionFrame.ModelsFrame.ModelR1C1
	end--while i
	return (i-1);
end


--####################################################################################
--####################################################################################
--Hooks
--####################################################################################


--Secure hook into most places where hyperlinks are used. For the other scenarios we need custom code.
function LinksInChat_HandleModifiedItemClick(link, ...)
	LinksInChat:dPrint(1, "LinksInChat_HandleModifiedItemClick", link,link);
	LinksInChat:CopyFrame_ExtraShow(link);
	return nil;
end


--This post-hook makes us able to create and handle customized hyperlinks for the addon in default ChatFrames
function LinksInChat_ChatFrame_OnHyperlinkShow(chatframe, link, text, button) --function ChatFrame_OnHyperlinkShow(chatframe, link, text, button)
	--Hook is done in LinksInChat:OnEvent()
	LinksInChat:dPrint(1, "LinksInChat_ChatFrame_OnHyperlinkShow", link,link,text);

	--Bagnon override: If user is ALT-clicking an item and Bagnon has reacted by doing its search thing then clear it...
	local f = _G["BagnonFrameinventory"];
	if (f ~= nil and f["searchFrame"] ~= nil and f["searchFrame"]:IsVisible() == true) then
		local ff = f["searchFrame"];
		local yy = ff["DisableSearch"];
		if (yy ~= nil) then yy(ff); end
	end--if f

	local start = strfind(link, "wcl:", 1, true); --plain find starting at pos 1 in the string
	if (start == 1) then --This is a web-link (not a hyperlink)
		if (IsShiftKeyDown()==true) then
			--Shift was held while clicking the web-link, we pass it along like a normal string (if the editbox is visible at the moment)...
			local t = strtrim(LinksInChat:HyperLink_Strip(text));
			if (t ~= nil) then
				local n = chatframe:GetName().."EditBox";
				local f = _G[n];
				--If the user presses Shift, we insert the web-link in plaintext into the chatframe's editbox.
				if (f ~= nil) then
					if (f:IsVisible() == 1) then
						f:Insert(" "..t.." "); --Editbox already open
					else
						f:Show();
						f:Insert(t.." ");
						f:SetFocus();
					end--if f:isVisible()
				end---if f
			end--if t

		else
			--Shift was not held down
			LinksInChat:CopyFrame_Show("wcl", text, nil); --Show the text of the link
		end--if IsShiftKeyDown

	else --This is a Hyperlink
		if (LinksInChat_IsKeyDown()==true) then
			LinksInChat:CopyFrame_Show("other", text, link); --If Alt was held while clicking the hyperlink we will show the copy window too (maybe; depending on the link)
		end--if IsAltKeyDown
	end--if start

	return nil;
end

--Event handler for used with ElvUI
function LinksInChat_ElvUI_ContainerFrameItem_OnClick(s, button)
	local link = GetContainerItemLink(s:GetParent():GetID(), s:GetID());
	LinksInChat:CopyFrame_ExtraShow(link);
	return true; --This is a post-hook.
end

--This post-hook makes us able to create and handle hyperlinks for WIM addon's frames
function LinksInChat_WIM_OnHyperlinkShow(chatframe, link, text, button)
	--Hook is done in LinksInChat:CALLBACK_WIM()

	local start = strfind(link, "wim_url:", 1, true); --Plain find starting at pos 1 in the string
	if (start == 1) then --This is a web-link (not a hyperlink)
		local t = LinkWebParsing:replace(link, "wim_url:", "");	--Remove the WIM hyperlink prefix. Note wim_url: links are not identical with wcl: links.
		if (IsShiftKeyDown()==true) then
			--Shift was held while clicking the web-link, we pass it along like a normal string (if the editbox is visible at the moment)...
			if (t ~= nil) then
				local n = chatframe:GetParent():GetName().."MsgBox"; --WIM addon editbox structure
				local f = _G[n];
				--If the user presses Shift, we insert the web-link in plaintext into the chatframe's editbox.
				if (f ~= nil) then
					if (f:IsVisible() == 1) then
						f:Insert(" "..t.." "); --Editbox already open
					else
						f:Show();
						f:Insert(t.." ");
						f:SetFocus();
					end--if f:isVisible()
				end---if f
			end--if t
		else
			--Shift was not held down
			LinksInChat:CopyFrame_Show("wcl", t, nil); --Show the text of the link
		end--if IsShiftKeyDown

	else --This is a Hyperlink
		if (LinksInChat_IsKeyDown()==true) then
			LinksInChat:CopyFrame_Show("other", text, link); --If Alt was held while clicking the hyperlink we will show the copy window too (maybe; depending on the link)
		end--if IsAltKeyDown

		return nil;
	end--if start
end


--This hook makes us able to hook into the questlog
function LinksInChat_QuestMapLogTitleButton_OnClick(s, button) --function QuestMapLogTitleButton_OnClick(self, button)
	--Hook is done in LinksInChat:OnEvent()
	--2014-12-07 Known issue: Clicking the 1st entry in the questlog does not work.
	local link = GetQuestLink(s.questID);
	local b = LinksInChat:CopyFrame_ExtraShow(link);
	if (b == true) then return nil; end --Skip passing hook if we show the link.
	return hook_QuestMapLogTitleButton_OnClick(s, button); --Call original function
end


function LinksInChat_QuestLogPopupDetailFrame_Show(questLogIndex)
	--Post-hook on the questlog details frame.
	--Source: FrameXML\QuestMapFrame.lua
	if (QuestLogPopupDetailFrame:IsShown() == false) then return nil; end
	local questID = select(8, GetQuestLogTitle(questLogIndex));
	local link = GetQuestLink(questID);
	local b = LinksInChat:CopyFrame_ExtraShow(link);
	if (b == true) then QuestLogPopupDetailFrame:Hide(); end
end


--This hooks into the objective tracker (achievement part)
function LinksInChat_ACHIEVEMENT_TRACKER_MODULE(s, block, mouseButton)
	--Hook is done in LinksInChat:OnEvent()
	--Source: Blizzard_AchievementObjectiveTracker.lua
	local link = GetAchievementLink(block.id);
	local b = LinksInChat:CopyFrame_ExtraShow(link);
	if (b == true) then return nil; end --Skip calling original function if we show the link.

	return hook_ACHIEVEMENT_TRACKER_MODULE(s, block, mouseButton); --Call original function
end


--This hooks into the objective tracker (quest part)
function LinksInChat_QUEST_TRACKER_MODULE(s, block, mouseButton)
	--Hook is done in LinksInChat:OnEvent()
	--Source: Blizzard_QuestObjectiveTracker.lua
	local link = GetQuestLink(block.id);
	local b = LinksInChat:CopyFrame_ExtraShow(link);
	if (b == true) then return nil; end --Skip calling original function if we show the link.

	return hook_QUEST_TRACKER_MODULE(s, block, mouseButton); --Call original function
end


--This hooks into the objective tracker (world quest).
function LinksInChat_BonusObjectiveTracker_OnBlockClick(self, button)
	--Post-hook on the worldquest objective tracker.
	--Source: AddOns\Blizzard_ObjectiveTracker\Blizzard_BonusObjectiveTracker.lua
	--This function only works for quests added after the addon has been loaded. If you have anything tracked from before a /reload it will not trigger on this function.
	--if (WorldMapFrame:IsShown() == false) then return nil; end --This is a post hook so the map is always shown first.
	local questID = self.TrackedQuest.questID;
	if (questID == nil) then return nil; end
	local link = GetQuestLink(questID);
	local b = LinksInChat:CopyFrame_ExtraShow(link);
	--if (b == true) then WorldMapFrame:Hide(); end --Don't know what the user did first; open the map or alt-click the worldquest. closing a window that the user opened is not nice.
end


--Event handler for Button.Onclick for AchievementButton_OnClick
function LinksInChat_AchievementButton_OnClick(s, button, down, ignoreModifiers)
	if (LinksInChat_IsKeyDown()==true) then --If alt-key isnt pressed then skip this.
		if (LinksInChat:GetCurrentSetting("Extra") == true) then
			local id, text = GetAchievementInfo(s.id);
			if (id ~= nil) then
				local data = "achievement:"..id..":"..UnitGUID("player")..":0:0:0:0:0:0:0:0"; --Create a ad-hock achievement link
				LinksInChat:CopyFrame_Show("other", text, data); --Show the text of the link
			end--if
		end--if GetCurrentSetting
	end--if IsAltKeyDown
	return true; --This is a post-hook.
end


--Event handler for Talent icons in Blizzard_TalentUI
function LinksInChat_PlayerTalentFrameTalent_OnClick(self, button)
	--local intSpec	= GetSpecialization(); --Currently enabled spec. Returns 1,2,3 or 4
	local intSpec = 1; --Seems to only work with 1
	local _, talentName = GetTalentInfoByID(self:GetID(), intSpec, false);
	local spellName, subSpellName, _, _, _, _, spellID = GetSpellInfo(talentName);

	--Seems that if the user has learned the spell then the system will return a spellID+link but otherwise it will not recognize that a spell of that name exists.
	--Until the user selects the talent and 'learns' the spell, it will have to do a simple-search. After the spell is learned it will return a spellid.
	--For passive's it will always have to do a simple-search.
	local link = nil;
	if (spellID ~= nil) then	link = GetSpellLink(spellID);			--returns a |HSpell: type link that works better
	else						link = GetTalentLink(self:GetID()); end	--returns a |HTalent: type link

	LinksInChat:CopyFrame_ExtraShow(link);
	return true; --This is a post-hook.
end


--Event handler for PVP Talent icons in Blizzard_TalentUI
function LinksInChat_PlayerTalentFramePVPTalentsTalent_OnClick(self, button)
	--local intSpec	= GetSpecialization(); --Currently enabled spec. Returns 1,2,3 or 4
	local intSpec = 1; --Seems to only work with 1
	local _, talentName = GetPvpTalentInfoByID(self.pvpTalentID, intSpec, false);
	local spellName, subSpellName, _, _, _, _, spellID = GetSpellInfo(talentName);

	local link = nil;
	if (spellID ~= nil) then	link = GetSpellLink(spellID);					--returns a |HSpell: type link that works better
	else						link = GetPvpTalentLink(self.pvpTalentID); end	--returns a |HPvptal: type link

	LinksInChat:CopyFrame_ExtraShow(link);
	return true; --This is a post-hook.
end


--Event handler for MountJournalListScrollFrameButtonN widget for the MountJournal UI.
function LinksInChat_MountJournalListScrollFrameButton_DragButton_OnClick(s, button)
	return LinksInChat_MountJournalListScrollFrameButton_OnClick(s:GetParent(), button);
end
function LinksInChat_MountJournalListScrollFrameButton_OnClick(s, button)
	--Source: Blizzard_Collections\Blizzard_MountCollection.lua/.xml
	local link = GetSpellLink(s.spellID);
	LinksInChat:CopyFrame_ExtraShow(link);
	return true; --This is a post-hook.
end


--Event handler for PetJournalListScrollFrameButtonN widget for the PetJournal UI.
function LinksInChat_PetJournalListScrollFrameButton_dragButton_OnClick(s, button)
	return LinksInChat_PetJournalListScrollFrameButton_OnClick(s:GetParent(), button);
end
function LinksInChat_PetJournalListScrollFrameButton_OnClick(s, button)
	--Source: Blizzard_Collections\Blizzard_PetCollection.lua/.xml
	if (LinksInChat_IsKeyDown()==true) then --If alt-key isnt pressed then skip this.
		if (LinksInChat:GetCurrentSetting("Extra") == true) then
			local id, data, text = s.petID, nil, nil;
			if (id ~= nil) then	--The pet has been collected. We can get a link for it and use that
				local link = C_PetJournal.GetBattlePetLink(id);
				data, text = LinksInChat:HyperLink_Strip2(link);
			else				--Pet has not been collected yet, We can lookup its localized name using the speciesID.
				text = C_PetJournal.GetPetInfoBySpeciesID(s.speciesID);
			end
			LinksInChat:CopyFrame_Show("other", text, data); --Show the text of the link
		end--if GetCurrentSetting
	end--if IsAltKeyDown
	return true; --This is a post-hook.
end


--Event handler for PetJournalPetCardSpellN widget for the PetJournal UI.
function LinksInChat_PetJournalPetCardSpell_OnClick(s, button)
	--Source: Blizzard_Collections\Blizzard_PetCollection.lua/.xml
	local link = PetJournal_GetPetAbilityHyperlink(s.abilityID, s.petID);
	LinksInChat:CopyFrame_ExtraShow(link);
	return true; --This is a post-hook.
end


--Secure hook onto ToySpellButton_OnModifiedClick for the ToyBox UI.
function LinksInChat_ToySpellButton_OnModifiedClick(s, button)
	--Source: Blizzard_Collections\Blizzard_Toybox.lua/.xml
	local link = C_ToyBox.GetToyLink(s.itemID);
	LinksInChat:CopyFrame_ExtraShow(link);
	return true; --This is a post-hook.
end


--Hook for the Transmog and Wardrobe UI (items).
function LinksInChat_WardrobeItemsModelMixin_OnMouseDown(self, button)
	--Source: Blizzard_Collections\Blizzard_Wardrobe.lua/.xml
	--Function WardrobeItemsModelMixin:OnMouseDown(button)
	local link = nil;
	local transmogType = self:GetParent().transmogType;
	if (transmogType == LE_TRANSMOG_TYPE_ILLUSION) then
		link = select(3, C_TransmogCollection.GetIllusionSourceInfo(self.visualInfo.sourceID));
	else
		local sources = WardrobeCollectionFrame_GetSortedAppearanceSources(self.visualInfo.visualID);
		if (WardrobeCollectionFrame.tooltipSourceIndex) then
			local index = WardrobeUtils_GetValidIndexForNumSources(WardrobeCollectionFrame.tooltipSourceIndex, #sources);
			link = select(6, C_TransmogCollection.GetAppearanceSourceInfo(sources[index].sourceID));
		end
	end
	LinksInChat:CopyFrame_ExtraShow(link);
	return true; --This is a post-hook.
end


--Hook for the Wardrobe UI (Sets).
function LinksInChat_WardrobeSetsDetailsItemMixin_OnMouseDown(self)
	--Source: Blizzard_Collections\Blizzard_Wardrobe.lua/.xml
	--Function: WardrobeSetsDetailsItemMixin:OnMouseDown()
	local link = nil;
	local sourceInfo = C_TransmogCollection.GetSourceInfo(self.sourceID);
	local slot = C_Transmog.GetSlotForInventoryType(sourceInfo.invType);
	local sources = C_TransmogSets.GetSourcesForSlot(self:GetParent():GetParent():GetSelectedSetID(), slot);
	if ( #sources == 0 ) then
		-- can happen if a slot only has HiddenUntilCollected sources
		tinsert(sources, sourceInfo);
	end
	WardrobeCollectionFrame_SortSources(sources, sourceInfo.visualID, self.sourceID);
	if (WardrobeCollectionFrame.tooltipSourceIndex) then
		local index = WardrobeUtils_GetValidIndexForNumSources(WardrobeCollectionFrame.tooltipSourceIndex, #sources);
		link = select(6, C_TransmogCollection.GetAppearanceSourceInfo(sources[index].sourceID));
	end

	LinksInChat:CopyFrame_ExtraShow(link);
	return true; --This is a post-hook.
end


--[[Secure hook onto HeirloomsJournalSpellButton_OnClick for the Heirlooms UI.
function LinksInChat_HeirloomsJournalSpellButton_OnClick(s, button)
	--Source: Blizzard_Collections\Blizzard_HeirloomCollection.lua/.xml
	local link = C_Heirloom.GetHeirloomLink(s.itemID);
	LinksInChat:CopyFrame_ExtraShow(link);
	return true; --This is a post-hook.
end--]]


--Secure hook onto GarrisonFollowerListButton_OnModifiedClick in the Garrison and Order Hall UI.
function LinksInChat_GarrisonFollowerListButton_OnModifiedClick(s, button)
	--Source: Blizzard_GarrisonUI\Blizzard_GarrisonSharedTemplates.lua/.xml
	local link = nil;
	if (s.info.isCollected) then
		link = C_Garrison.GetFollowerLink(s.info.followerID);
	else
		link = C_Garrison.GetFollowerLinkByID(s.info.followerID);
	end
	LinksInChat:CopyFrame_ExtraShow(link);
	return true; --This is a post-hook.
end


--Event handler for GarrisonLandingPageReportMission_OnClick()
function LinksInChat_GarrisonLandingPageReportMission_OnClick(s, button)
	--Source: Blizzard_GarrisonUI\Blizzard_GarrisonLandingPage.lua/.xml
	local items = GarrisonLandingPageReport.List.items or {};
	if (GarrisonLandingPageReport.selectedTab == GarrisonLandingPageReport.Available) then
		items = GarrisonLandingPageReport.List.AvailableItems or {};
	end
	local item = items[s.id];
	if (not item.missionID) then return; end -- non mission entries have no click capability

	local link = C_Garrison.GetMissionLink(item.missionID);
	LinksInChat:CopyFrame_ExtraShow(link);
	return true; --This is a post-hook.
end


--Pre-hook for ReputationBar_OnClick
function LinksInChat_ReputationBar_OnClick(s,...)
	--Hook is done in LinksInChat:OnEvent()
	--Source: Interface\FrameXML\ReputationFrame.lua:ReputationBar_OnClick()/ReputationFrame_Update()
	local name, description, standingID, barMin, barMax, barValue, atWarWith, canToggleAtWar, isHeader, isCollapsed, hasRep, isWatched, isChild, factionID, hasBonusRepGain, canBeLFGBonus = GetFactionInfo(s.index);

	if (isHeader ~= nil and isHeader == false) then --Ignore header lines
		if (LinksInChat_IsKeyDown()==true) then --If alt-key isnt pressed then skip this.
			if (LinksInChat:GetCurrentSetting("Extra") == true) then
				local data, text = "faction:"..tostring(factionID), tostring(name); --create a "faction:" link
				LinksInChat:CopyFrame_Show("other", text, data); --Show the text of the link
			end--if GetCurrentSetting
		end--if IsAltKeyDown
	end--if isHeader

	return hook_ReputationBar_OnClick(s,...); --Call original function
end


--Pre-hook for Blizzard_TokenUI (currency tab)
function LinksInChat_TokenButton_OnClick(s,...)
	--Hook is done in LinksInChat:CALLBACK_Blizzard_TokenUI()
	--Source: AddOns\Blizzard_TokenUI\Blizzard_TokenUI.lua:TokenButton_OnClick()
	local link = C_CurrencyInfo.GetCurrencyListLink(s.index);
	LinksInChat:CopyFrame_ExtraShow(link);

	return hook_TokenButton_OnClick(s,...); --Call original function
end


--Event handler for GroupLootFrame.IconFrame_OnClick for the default Blizzard grouploot (the frame with the need/greed/diss buttons)
function LinksInChat_GroupLootFrame_OnClick(s, button)
	local link = GetLootRollItemLink(s:GetParent().rollID);
	LinksInChat:CopyFrame_ExtraShow(link);
	return true; --This is a post-hook.
end


--Event handler for QuestInfoRewardsFrameQuestInfoItem and MapQuestInfoRewardsFrameQuestInfoItem for the default Blizzard quest reward icons
function LinksInChat_QuestInfoRewardsFrameQuestInfoItem_OnClick(s, button)
	local link = nil;
	--print("s.objectType: "..tostring(s.objectType).."s.GetID: "..tostring(s:GetID()).."type: "..tostring(type(s.Name)));
	if (s.objectType == "item") then --Item rewards
		if (QuestInfoFrame.questLog) then
			--This is triggered when the user clicks an item reward in the questlog
			link = GetQuestLogItemLink(s.type, s:GetID());
		else
			--This is triggered when the user clicks an item that is required to hand in a quest.
			link = GetQuestItemLink(s.type, s:GetID());
		end

	elseif (s.objectType == "currency") then --Currency rewards
		local name, texture, numItems = nil, nil, nil;
		if (QuestInfoFrame.questLog) then
			name, texture, numItems = GetQuestLogRewardCurrencyInfo(s:GetID());
		else
			name, texture, numItems = GetQuestCurrencyInfo(s.type, s:GetID());
		end

		--HARDCODED: Last updated on 2016-05-16 (Legion Beta 7.0.3), Highest number found was 1268: http://www.wowhead.com/currencies
		--			 The maxvalue that the loop will iterate to look for currencies.
		local maxID = 9000;
		local f		= GetCurrencyInfo; --local fpointer
		for i=1, maxID do				--Note: This loop uses a very large maxvalue, plus it does not cache results for later fast lookup; Good enough for the quest-reward scenario tho.
				local strName, strAmount, strTexture = f(i); --There are more arguments returned from this function but they vary depending on the currency and they are not documented
				if (strName == name and strTexture == texture) then
					link = GetCurrencyLink(i);
					break;
				end--if strName
		end--for i
		--When we reach here, we either have a currency link or link is still nil.

	else --Spells does not return a s.objectType
		--If might be a spell?, Check if something returns
		if ( QuestInfoFrame.questLog ) then
			link = GetQuestLogSpellLink();
		else
			link = GetQuestSpellLink();
		end
		--When we reach here, we either have a spell link or link is still nil.

		--TODO: Add support for follower as reward: FollowerFrame
	end--if s.objectType

	LinksInChat:CopyFrame_ExtraShow(link);
	return true; --This is a post-hook.
end


--Event handler for SpellButton_OnClick for the default Blizzard spellbook
function LinksInChat_SpellButton_OnClick(s, button)
	local slot = SpellBook_GetSpellBookSlot(s);
	if (slot > MAX_SPELLS) then return nil; end

	local link = GetSpellLink(slot, SpellBookFrame.bookType);
	LinksInChat:CopyFrame_ExtraShow(link);
	return true; --This is a post-hook.
end


--Pre-hook for Rematch addon widget functions
function LinksInChat_Rematch_OnClick(s, ...)
	--Hook is done in LinksInChat:CALLBACK_Rematch()
	--Source: AddOns\Rematch\Widgets\PetListButtons.lua:PetListButtonOnClick()/PetListButtonPetOnClick()
	--s.petID contains either a "Battlepet-" type string or the speciesID.
	if (LinksInChat_IsKeyDown()==true) then --If alt-key isnt pressed then skip this.
		if (LinksInChat:GetCurrentSetting("Extra") == true) then
			local id, data, text = s.petID, nil, nil;
			if (Rematch:GetIDType(s.petID)=="pet") then --The pet has been collected. We can get a link for it and use that
				local link = C_PetJournal.GetBattlePetLink(id);
				data, text = LinksInChat:HyperLink_Strip2(link);
			else --Pet has not been collected yet, We can lookup its localized name using the speciesID.
				text = C_PetJournal.GetPetInfoBySpeciesID(s.petID);
			end
			LinksInChat:CopyFrame_Show("other", text, data); --Show the text of the link
		end--if GetCurrentSetting
	end--if IsAltKeyDown
	return nil;
end
function LinksInChat_Rematch_PetListButtonOnClick(s, ...)
	LinksInChat_Rematch_OnClick(s, ...);				--Code is identical for our purposes, except for the original pointer
	return hook_Rematch_PetListButtonOnClick(s, ...);	--Call original function
end
function LinksInChat_Rematch_PetListButtonPetOnClick(s, ...)
	LinksInChat_Rematch_OnClick(s, ...);				--Code is identical for our purposes, except for the original pointer
	return hook_Rematch_PetListButtonPetOnClick(s,...);	--Call original function
end


--####################################################################################
--####################################################################################

--[[Prints out all variables that are passed into the function
function pprint(...)
	local s="";
	for i = 1, select("#", ...) do
		s = s.." Arg"..tostring(i).." '"..tostring( select(i,...) );
	end--for i
	if (s ~= "") then s = s.."'"; end
	return print(strtrim(s));
end--]]

--[[
local hook_org = nil; --original pointer
function myOverride(...)--override function
	print("myOverride was triggered");
	if (hook_org ~=nil) then return hook_org(...); end
	return nil;
end

function foo()
	--hook_org = TaskPOI_OnClick;
	--TaskPOI_OnClick = myOverride;
	--hooksecurefunc("WorldMapPOI_OnClick", myOverride);

	print("hook done done");
end--]]
