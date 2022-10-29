--####################################################################################
--####################################################################################
--Hidden Tooltip Scanner
--####################################################################################
--Dependencies: none

local HiddenTooltip	= {};
HiddenTooltip.__index	= HiddenTooltip;
LinksInChat_HiddenTooltip	= HiddenTooltip; --Global declaration

--local StringParsing	= <AddonName>_StringParsing; --Local pointer


--Local variables that cache stuff so we dont have to recreate large objects
local cache_Tooltip		= nil; --Pointer to the hidden GameTooltip object we use
local cache_ItemList	= nil; --Table with list of scanned items (key=uppercase itemlink, value=table with scanned values).
local cache_ItemListCount = 0; --Size of cache_ItemList


--Local Constants
local CONST_ITEMLISTMAX		= 500; --Max size of cache_ItemList before its reset to nil
local CONST_PLACEHOLDER		= _G["RETRIEVING_ITEM_INFO"]; --"Retrieving item information"
--local CONST_ITEM_LEVEL	= _G["ITEM_LEVEL"];
--local CONST_ITEM_UPGRADE	= _G["ITEM_UPGRADE_TOOLTIP_FORMAT"];
--local CONST_ITEM_ENCHANTED= _G["ENCHANTED_TOOLTIP_LINE"];
--local CONST_ITEM_MIN_LEVEL= _G["ITEM_MIN_LEVEL"];


--Local pointers to global functions
local strupper	= strupper;
local strtrim	= strtrim;	--string.trim
local gsub		= gsub;
local strmatch	= strmatch;
local strfind	= strfind;
local strrev	= strrev;


--####################################################################################
--####################################################################################
--Public
--####################################################################################


--Get info from a itemlink for equipment that you can wear (armor, weapons, rings, trinkets, shirts, tabards etc).
function HiddenTooltip:GetEquipmentItemInfo(itemLink, itemInfo)
	if (itemLink == nil or itemLink == "") then return nil; end
	itemInfo = strtrim(strupper(itemInfo)); --Can be: TITLE, ITEM_LEVEL, UPGRADE_LEVEL, UPGRADE_LEVEL_CURRENT, UPGRADE_LEVEL_MAX, ENCHANT, LEVEL_REQUIREMENT
	local strKey = strupper(itemLink);

	--Check if itemlink has previously been scanned
	if (cache_ItemList ~= nil and cache_ItemList[strKey] ~= nil) then
		local tbl = cache_ItemList[strKey];
		return tbl; --We just store the title itself
	end

	--1. Get object and Set tooltip
	local objTip = self:GetTooltipObject();
	--objTip:SetHyperlink(itemLink);
	local booResult, strMessage = pcall( objTip.SetHyperlink, objTip, itemLink ); --Instead of objTip: (colon) we need to use objTip. (period) and pass objTip (self) as the first argument
	if (booResult == false) then return nil; end --If this crashes then its most likely the "Unknown link type" exception
		--2013-01-20 WOW Patch 5.1.0: Known issue:: If the itemlink passed in is of the type 'battlepet' (i.e pets in the PetJournal) then the function will throw an error.

	--2. Get all lines from the tooltip back as an array
	local tblLines = self:GetAllTooltipLines(objTip);
	if (tblLines == nil or #tblLines == 0) then return nil; end

	--3. Populate the table with the data that we can or nil values
	--|local tbl, p = {}, nil;
	local tbl, p = nil, nil;
	--Title is always the first line in any tooltip
	p = tblLines[1];
	if (p == CONST_PLACEHOLDER) then return nil; end --If the title is 'Retrieving item information' (meaning that the scan has failed) then we will return immediatly
	--|tbl["TITLE"] = p;
	tbl = p;

--[[
	--Find the line that matches the "Item Level %d" string
	p = self:FindTooltipLine(tblLines, CONST_ITEM_LEVEL, "START");
	if (p~=nil) then tbl["ITEM_LEVEL"] = p; end

	--Find the line that matches the "Upgrade Level: %d/%d" string (both numbers)
	p = gsub(CONST_ITEM_UPGRADE, "%%d/%%d", "(%%d+/%%d+)"); --Replace %d/%d with (%d+/%d+) to group the two digits
	if (p~=nil) then
		p = self:FindTooltipLine(tblLines, p, "START");
		if (p~=nil) then tbl["UPGRADE_LEVEL"] = p; end

		--Find the line that matches the "Upgrade Level: %d/%d" string (first number)
		p = self:FindTooltipLine(tblLines, CONST_ITEM_UPGRADE, "START");
		if (p~=nil) then tbl["UPGRADE_LEVEL_CURRENT"] = p; end

		--Find the line that matches the "Upgrade Level: %d/%d" string (second number)
		p = self:FindTooltipLine(tblLines, CONST_ITEM_UPGRADE, "START");	--Get the first number
		if (p~=nil) then
			p = gsub(CONST_ITEM_UPGRADE, "%%d/", p.."/");					--Replace %d/ with  f/ (the number itself) so that we can get to the second digit
			if (p~=nil) then
				p = self:FindTooltipLine(tblLines, p, "START");
				if (p~=nil) then tbl["UPGRADE_LEVEL_MAX"] = p; end
			end
		end
	end--if p

	--Find the line that matches the "Enchanted: %d" string
	p = self:FindTooltipLine(tblLines, CONST_ITEM_ENCHANTED, "START");
	if (p~=nil) then tbl["ENCHANT"] = p; end

	--Find the line that matches the "Requires Level %d" string
	p = self:FindTooltipLine(tblLines, CONST_ITEM_MIN_LEVEL, "START");
	if (p~=nil) then tbl["LEVEL_REQUIREMENT"] = p; end
--]]

	--4. Store in cache for later
	if (cache_ItemList == nil) then	cache_ItemList = {}; end --create table when needed but not before
	cache_ItemList[strKey] = tbl;
	cache_ItemListCount = cache_ItemListCount +1;
	if (cache_ItemListCount > CONST_ITEMLISTMAX) then cache_ItemList = nil; cache_ItemListCount = 0; end --Set cache to nil if it grows over its maximum size. This is to prevent infinite growth

	--5. Return the value that was requested
	--|return tbl[itemInfo];
	return tbl;

	--[[
		HARDCODED: Last updated on 2012-12-07: (Patch 5.1.0), Expected tooltip format for items when using :SetHyperlink()
		Note: tooltips will always be using the localized language of the client, even if the itemlink is in another language.
		Info: http://www.wowwiki.com/UIOBJECT_GameTooltip

		--------------------------------------------
		' Staff of trembling will
		' Heroic
		' Item Level 471
		' Upgrade Level: 1/1
		' Binds when picked up
		' Two-Hand						 Staff
		' 4,813 - 7,222 Damage		Speed 3.40
		' (1,769 damage per second)
		' +1,454 Stamina
		' +969 Intellect
		' +702 Haste
		' +551 Critical Strike
		' +5,551 Spell Power
		'
		' Enchanted: Elemental Force
		'
		' Requires Level 90
		' Sell Price:	42g 53s 15c
		--------------------------------------------

		--------------------------------------------
		' Lightweight Retinal Armor
		' Item Level 476
		' Upgrade Level: 0/2
		' Binds when picked up
		' Head						 Cloth
		' 1,733 Armor
		' +1,522 Stamina
		' +855 Intellect
		'
		' [X] +216 Intellect and 3% Increased Critical Effect
		' [X] +600 Haste
		' [X] +600 Critical Strike
		' Socket Bonus: +180 Intellect
		'
		' Requires Level 87
		' Requires Engineering (600)
		' Sell Price:	42g 53s 15c
		' GP: 587                         						<--- EPGP addon inputs this
		--------------------------------------------
	]]--
end


--####################################################################################
--####################################################################################
--Support functions
--####################################################################################


--Put cursor marker in the current position
function HiddenTooltip:GetTooltipObject()
	--if (true) then return GameTooltip; end --For testing, is visible when mousing over something
	if (cache_Tooltip ~= nil) then --Return the local pointer
		cache_Tooltip:ClearLines();
		return cache_Tooltip;
	end

	--[[ XML format
	<GameTooltip name="HiddenTooltip_HiddenTooltipTemplate" inherits="GameTooltipTemplate" hidden="true">
		<!-- This template is used by HiddenTooltip.lua to create and scan tooltips for information like itemlevel etc. -->
		<Scripts><Onload>self:SetOwner(WorldFrame, "ANCHOR_NONE");</Onload></Scripts>
	</GameTooltip> ]]--

	--Generate a unique name so that it won't collide with any other instance of the class running at the same time
	local strName = "HiddenTooltip_HiddenTooltipTemplate";
	while (_G[strName] ~= nil) do
		strName = "HiddenTooltip_HiddenTooltipTemplate_"..tostring(random(1,1000));
	end--while

	--Source: http://www.wowwiki.com/UIOBJECT_GameTooltip
	CreateFrame("GameTooltip", strName, nil, "GameTooltipTemplate");
	cache_Tooltip = _G[strName]; --Store pointer for later
	cache_Tooltip:SetOwner(WorldFrame, "ANCHOR_NONE");
	cache_Tooltip:ClearLines();
	return cache_Tooltip;
end


--Return table with all the lines in the tooltip. Will return nil if nothing is found.
function HiddenTooltip:GetAllTooltipLines(objTooltip)
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
	return tbl;
end


--Search and return a specific line from a tooltip
function HiddenTooltip:FindTooltipLine(tblLines, strPattern, linePos)
	if (linePos == nil) then linePos = "ANY"; end --START, END or ANY
	linePos = strupper(linePos);

	local gsub		= gsub;		--local fpointer
	local strmatch	= strmatch;
	local strfind	= strfind;
	local strrev	= strrev;

	--Source: http://www.wowpedia.org/Pattern_matching

	--Same as StringParsing:indexOf()
	local start = strfind(strPattern, "%d+", 1, true); --Plain find, Will return nil if not found
	if (start == nil) then --Skip if %d+ exists in the string already
		--Replace %d with a grouping of %d+ so that it accepts more than 1 digit (idea from Phanx)
		strPattern = gsub(strPattern, "%%d", "(%%d+)");
	end

	--Same as StringParsing:endsWith()
	local strR, itemR  = strrev(strPattern), strrev("%s"); --reverse the strings
	local sPos1 = strfind(strR, itemR, 1, true); --plain find starting at pos 1 in the string
	if (sPos1 == 1) then
		--Replace %s at the end of a string (wich i assume is supposed to mean 'string' in this context with a pattern that supports spaces inside of it
		strPattern = gsub(strPattern, "%%s", "(%%a*%%s*%%a*%%s*%%a*%%s*%%a*%%s*%%a*%%s*%%a*%%s*%%a*%%s*%%a*%%s*%%a*)");
	else
		strPattern = gsub(strPattern, "%%s", "(%%a+)"); --Replace %s with a grouping of %a+ (series of letters)
	end

	if		(linePos == "START")	then strPattern = "^"..strPattern;
	elseif	(linePos == "END")		then strPattern = strPattern.."$";
	end

	for i=1, #tblLines do
		local currLine = tblLines[i];

		local s = strmatch(currLine, strPattern);
		if (s ~= nil) then return s; end
	end--for i
	return nil;
end


--####################################################################################
--####################################################################################
