﻿UIDROPDOWNNOTAINTMENU_MINBUTTONS = 8;
UIDROPDOWNNOTAINTMENU_MAXBUTTONS = 8;
UIDROPDOWNNOTAINTMENU_MAXLEVELS = 2;
UIDROPDOWNNOTAINTMENU_BUTTON_HEIGHT = 16;
UIDROPDOWNNOTAINTMENU_BORDER_HEIGHT = 15;
-- The current open menu
UIDROPDOWNNOTAINTMENU_OPEN_MENU = nil;
-- The current menu being initialized
UIDROPDOWNNOTAINTMENU_INIT_MENU = nil;
-- Current level shown of the open menu
UIDROPDOWNNOTAINTMENU_MENU_LEVEL = 1;
-- Current value of the open menu
UIDROPDOWNNOTAINTMENU_MENU_VALUE = nil;
-- Time to wait to hide the menu
UIDROPDOWNNOTAINTMENU_SHOW_TIME = 2;
-- Default dropdown text height
UIDROPDOWNNOTAINTMENU_DEFAULT_TEXT_HEIGHT = nil;
-- List of open menus
OPEN_DROPDOWNNOTAINTMENUS = {};

local UIDropDownNoTaintMenuDelegate = CreateFrame("FRAME");

function UIDropDownNoTaintMenuDelegate_OnAttributeChanged (self, attribute, value)
	if ( attribute == "createframes" and value == true ) then
		UIDropDownNoTaintMenu_CreateFrames(self:GetAttribute("createframes-level"), self:GetAttribute("createframes-index"));
	elseif ( attribute == "initmenu" ) then
		UIDROPDOWNNOTAINTMENU_INIT_MENU = value;
	elseif ( attribute == "openmenu" ) then
		UIDROPDOWNNOTAINTMENU_OPEN_MENU = value;
	end
end

UIDropDownNoTaintMenuDelegate:SetScript("OnAttributeChanged", UIDropDownNoTaintMenuDelegate_OnAttributeChanged);

function UIDropDownNoTaintMenu_InitializeHelper (frame)
	-- This deals with the potentially tainted stuff!
	if ( frame ~= UIDROPDOWNNOTAINTMENU_OPEN_MENU ) then
		UIDROPDOWNNOTAINTMENU_MENU_LEVEL = 1;
	end

	-- Set the frame that's being intialized
	UIDropDownNoTaintMenuDelegate:SetAttribute("initmenu", frame);

	-- Hide all the buttons
	local button, dropDownList;
	for i = 1, UIDROPDOWNNOTAINTMENU_MAXLEVELS, 1 do
		dropDownList = _G["DropDownNoTaintList"..i];
		if ( i >= UIDROPDOWNNOTAINTMENU_MENU_LEVEL or frame ~= UIDROPDOWNNOTAINTMENU_OPEN_MENU ) then
			dropDownList.numButtons = 0;
			dropDownList.maxWidth = 0;
			for j=1, UIDROPDOWNNOTAINTMENU_MAXBUTTONS, 1 do
				button = _G["DropDownNoTaintList"..i.."Button"..j];
				button:Hide();
			end
			dropDownList:Hide();
		end
	end
	frame:SetHeight(UIDROPDOWNNOTAINTMENU_BUTTON_HEIGHT * 2);
end

function UIDropDownNoTaintMenu_Initialize(frame, initFunction, displayMode, level, menuList)
	frame.menuList = menuList;

	securecall("UIDropDownNoTaintMenu_InitializeHelper", frame);

	-- Set the initialize function and call it.  The initFunction populates the dropdown list.
	if ( initFunction ) then
		frame.initialize = initFunction;
		initFunction(frame, level, frame.menuList);
	end

	--master frame
	if(level == nil) then
		level = 1;
	end

	local dropDownList = _G["DropDownNoTaintList"..level]
	dropDownList.dropdown = frame;
	dropDownList.shouldRefresh = true;

	-- Change appearance based on the displayMode
	if ( displayMode == "MENU" ) then
		local name = frame:GetName();
		_G[name.."Left"]:Hide();
		_G[name.."Middle"]:Hide();
		_G[name.."Right"]:Hide();
		_G[name.."ButtonNormalTexture"]:SetTexture("");
		_G[name.."ButtonDisabledTexture"]:SetTexture("");
		_G[name.."ButtonPushedTexture"]:SetTexture("");
		_G[name.."ButtonHighlightTexture"]:SetTexture("");

		local button = _G[name.."Button"]
		button:ClearAllPoints();
		button:SetPoint("LEFT", name.."Text", "LEFT", -9, 0);
		button:SetPoint("RIGHT", name.."Text", "RIGHT", 6, 0);
		frame.displayMode = "MENU";
	end

end

function UIDropDownNoTaintMenu_RefreshDropDownNoTaintSize(self)
	self.maxWidth = UIDropDownNoTaintMenu_GetMaxButtonWidth(self);
	self:SetWidth(self.maxWidth + 25);

	for i=1, UIDROPDOWNNOTAINTMENU_MAXBUTTONS, 1 do
		local icon = _G[self:GetName().."Button"..i.."Icon"];

		if ( icon.tFitDropDownNoTaintSizeX ) then
			icon:SetWidth(self.maxWidth - 5);
		end
	end
end

-- If dropdown is visible then see if its timer has expired, if so hide the frame
function UIDropDownNoTaintMenu_OnUpdate(self, elapsed)
	if ( self.shouldRefresh ) then
		UIDropDownNoTaintMenu_RefreshDropDownNoTaintSize(self);
		self.shouldRefresh = false;
	end

	if ( not self.showTimer or not self.isCounting ) then
		return;
	elseif ( self.showTimer < 0 ) then
		self:Hide();
		self.showTimer = nil;
		self.isCounting = nil;
	else
		self.showTimer = self.showTimer - elapsed;
	end
end

-- Start the countdown on a frame
function UIDropDownNoTaintMenu_StartCounting(frame)
	if ( frame.parent ) then
		UIDropDownNoTaintMenu_StartCounting(frame.parent);
	else
		frame.showTimer = UIDROPDOWNNOTAINTMENU_SHOW_TIME;
		frame.isCounting = 1;
	end
end

-- Stop the countdown on a frame
function UIDropDownNoTaintMenu_StopCounting(frame)
	if ( frame.parent ) then
		UIDropDownNoTaintMenu_StopCounting(frame.parent);
	else
		frame.isCounting = nil;
	end
end

--[[
List of button attributes
======================================================
info.text = [STRING]  --  The text of the button
info.value = [ANYTHING]  --  The value that UIDROPDOWNNOTAINTMENU_MENU_VALUE is set to when the button is clicked
info.func = [function()]  --  The function that is called when you click the button
info.checked = [nil, true, function]  --  Check the button if true or function returns true
info.isNotRadio = [nil, true]  --  Check the button uses radial image if false check box image if true
info.isTitle = [nil, true]  --  If it's a title the button is disabled and the font color is set to yellow
info.disabled = [nil, true]  --  Disable the button and show an invisible button that still traps the mouseover event so menu doesn't time out
info.tooltipWhileDisabled = [nil, 1] -- Show the tooltip, even when the button is disabled.
info.hasArrow = [nil, true]  --  Show the expand arrow for multilevel menus
info.hasColorSwatch = [nil, true]  --  Show color swatch or not, for color selection
info.r = [1 - 255]  --  Red color value of the color swatch
info.g = [1 - 255]  --  Green color value of the color swatch
info.b = [1 - 255]  --  Blue color value of the color swatch
info.colorCode = [STRING] -- "|cAARRGGBB" embedded hex value of the button text color. Only used when button is enabled
info.swatchFunc = [function()]  --  Function called by the color picker on color change
info.hasOpacity = [nil, 1]  --  Show the opacity slider on the colorpicker frame
info.opacity = [0.0 - 1.0]  --  Percentatge of the opacity, 1.0 is fully shown, 0 is transparent
info.opacityFunc = [function()]  --  Function called by the opacity slider when you change its value
info.cancelFunc = [function(previousValues)] -- Function called by the colorpicker when you click the cancel button (it takes the previous values as its argument)
info.notClickable = [nil, 1]  --  Disable the button and color the font white
info.notCheckable = [nil, 1]  --  Shrink the size of the buttons and don't display a check box
info.owner = [Frame]  --  Dropdown frame that "owns" the current dropdownlist
info.keepShownOnClick = [nil, 1]  --  Don't hide the dropdownlist after a button is clicked
info.tooltipTitle = [nil, STRING] -- Title of the tooltip shown on mouseover
info.tooltipText = [nil, STRING] -- Text of the tooltip shown on mouseover
info.tooltipOnButton = [nil, 1] -- Show the tooltip attached to the button instead of as a Newbie tooltip.
info.justifyH = [nil, "CENTER"] -- Justify button text
info.arg1 = [ANYTHING] -- This is the first argument used by info.func
info.arg2 = [ANYTHING] -- This is the second argument used by info.func
info.fontObject = [FONT] -- font object replacement for Normal and Highlight
info.menuTable = [TABLE] -- This contains an array of info tables to be displayed as a child menu
info.noClickSound = [nil, 1]  --  Set to 1 to suppress the sound when clicking the button. The sound only plays if .func is set.
info.padding = [nil, NUMBER] -- Number of pixels to pad the text on the right side
info.leftPadding = [nil, NUMBER] -- Number of pixels to pad the button on the left side
info.minWidth = [nil, NUMBER] -- Minimum width for this line
]]

local UIDropDownNoTaintMenu_ButtonInfo = {};

--Until we get around to making this betterz...
local UIDropDownNoTaintMenu_SecureInfo = {};

local wipe = table.wipe;

function UIDropDownNoTaintMenu_CreateInfo()
	-- Reuse the same table to prevent memory churn

	if ( issecure() ) then
		securecall(wipe, UIDropDownNoTaintMenu_SecureInfo);
		return UIDropDownNoTaintMenu_SecureInfo;
	else
		return wipe(UIDropDownNoTaintMenu_ButtonInfo);
	end
end

function UIDropDownNoTaintMenu_CreateFrames(level, index)

	while ( level > UIDROPDOWNNOTAINTMENU_MAXLEVELS ) do
		UIDROPDOWNNOTAINTMENU_MAXLEVELS = UIDROPDOWNNOTAINTMENU_MAXLEVELS + 1;
		local newList = CreateFrame("Button", "DropDownNoTaintList"..UIDROPDOWNNOTAINTMENU_MAXLEVELS, nil, "UIDropDownNoTaintListTemplate");
		newList:SetFrameStrata("FULLSCREEN_DIALOG");
		newList:SetToplevel(true);
		newList:Hide();
		newList:SetID(UIDROPDOWNNOTAINTMENU_MAXLEVELS);
		newList:SetWidth(180)
		newList:SetHeight(10)
		for i=UIDROPDOWNNOTAINTMENU_MINBUTTONS+1, UIDROPDOWNNOTAINTMENU_MAXBUTTONS do
			local newButton = CreateFrame("Button", "DropDownNoTaintList"..UIDROPDOWNNOTAINTMENU_MAXLEVELS.."Button"..i, newList, "UIDropDownNoTaintMenuButtonTemplate");
			newButton:SetID(i);
		end
	end

	while ( index > UIDROPDOWNNOTAINTMENU_MAXBUTTONS ) do
		UIDROPDOWNNOTAINTMENU_MAXBUTTONS = UIDROPDOWNNOTAINTMENU_MAXBUTTONS + 1;
		for i=1, UIDROPDOWNNOTAINTMENU_MAXLEVELS do
			local newButton = CreateFrame("Button", "DropDownNoTaintList"..i.."Button"..UIDROPDOWNNOTAINTMENU_MAXBUTTONS, _G["DropDownNoTaintList"..i], "UIDropDownNoTaintMenuButtonTemplate");
			newButton:SetID(UIDROPDOWNNOTAINTMENU_MAXBUTTONS);
		end
	end
end

function UIDropDownNoTaintMenu_AddButton(info, level)
	--[[
	Might to uncomment this if there are performance issues
	if ( not UIDROPDOWNNOTAINTMENU_OPEN_MENU ) then
		return;
	end
	]]
	if ( not level ) then
		level = 1;
	end

	local listFrame = _G["DropDownNoTaintList"..level];
	local index = listFrame and (listFrame.numButtons + 1) or 1;
	local width;

	UIDropDownNoTaintMenuDelegate:SetAttribute("createframes-level", level);
	UIDropDownNoTaintMenuDelegate:SetAttribute("createframes-index", index);
	UIDropDownNoTaintMenuDelegate:SetAttribute("createframes", true);

	listFrame = listFrame or _G["DropDownNoTaintList"..level];
	local listFrameName = listFrame:GetName();

	-- Set the number of buttons in the listframe
	listFrame.numButtons = index;

	local button = _G[listFrameName.."Button"..index];
	local normalText = _G[button:GetName().."NormalText"];
	local icon = _G[button:GetName().."Icon"];
	-- This button is used to capture the mouse OnEnter/OnLeave events if the dropdown button is disabled, since a disabled button doesn't receive any events
	-- This is used specifically for drop down menu time outs
	local invisibleButton = _G[button:GetName().."InvisibleButton"];

	-- Default settings
	button:SetDisabledFontObject(GameFontDisableSmallLeft);
	invisibleButton:Hide();
	button:Enable();

	-- If not clickable then disable the button and set it white
	if ( info.notClickable ) then
		info.disabled = 1;
		button:SetDisabledFontObject(GameFontHighlightSmallLeft);
	end

	-- Set the text color and disable it if its a title
	if ( info.isTitle ) then
		info.disabled = 1;
		button:SetDisabledFontObject(GameFontNormalSmallLeft);
	end

	-- Disable the button if disabled and turn off the color code
	if ( info.disabled ) then
		button:Disable();
		invisibleButton:Show();
		info.colorCode = nil;
	end

	-- If there is a color for a disabled line, set it
	if( info.disablecolor ) then
		info.colorCode = info.disablecolor;
	end

	-- Configure button
	if ( info.text ) then
		-- look for inline color code this is only if the button is enabled
		if ( info.colorCode ) then
			button:SetText(info.colorCode..info.text.."|r");
		else
			button:SetText(info.text);
		end

		-- Set icon
		if ( info.icon ) then
			icon:SetSize(16,16);
			icon:SetTexture(info.icon);
			icon:ClearAllPoints();
			icon:SetPoint("RIGHT");

			if ( info.tCoordLeft ) then
				icon:SetTexCoord(info.tCoordLeft, info.tCoordRight, info.tCoordTop, info.tCoordBottom);
			else
				icon:SetTexCoord(0, 1, 0, 1);
			end
			icon:Show();
		else
			icon:Hide();
		end

		-- Check to see if there is a replacement font
		if ( info.fontObject ) then
			button:SetNormalFontObject(info.fontObject);
			button:SetHighlightFontObject(info.fontObject);
		else
			button:SetNormalFontObject(GameFontHighlightSmallLeft);
			button:SetHighlightFontObject(GameFontHighlightSmallLeft);
		end
	else
		button:SetText("");
		icon:Hide();
	end

	button.iconOnly = nil;
	button.icon = nil;
	button.iconInfo = nil;

	if (info.iconInfo) then
		icon.tFitDropDownNoTaintSizeX = info.iconInfo.tFitDropDownNoTaintSizeX;
	else
		icon.tFitDropDownNoTaintSizeX = nil;
	end
	if (info.iconOnly and info.icon) then
		button.iconOnly = true;
		button.icon = info.icon;
		button.iconInfo = info.iconInfo;

		UIDropDownNoTaintMenu_SetIconImage(icon, info.icon, info.iconInfo);
		icon:ClearAllPoints();
		icon:SetPoint("LEFT");
	end

	-- Pass through attributes
	button.func = info.func;
	button.owner = info.owner;
	button.hasOpacity = info.hasOpacity;
	button.opacity = info.opacity;
	button.opacityFunc = info.opacityFunc;
	button.cancelFunc = info.cancelFunc;
	button.swatchFunc = info.swatchFunc;
	button.keepShownOnClick = info.keepShownOnClick;
	button.tooltipTitle = info.tooltipTitle;
	button.tooltipText = info.tooltipText;
	button.arg1 = info.arg1;
	button.arg2 = info.arg2;
	button.hasArrow = info.hasArrow;
	button.hasColorSwatch = info.hasColorSwatch;
	button.notCheckable = info.notCheckable;
	button.menuList = info.menuList;
	button.tooltipWhileDisabled = info.tooltipWhileDisabled;
	button.tooltipOnButton = info.tooltipOnButton;
	button.noClickSound = info.noClickSound;
	button.padding = info.padding;

	if ( info.value ) then
		button.value = info.value;
	elseif ( info.text ) then
		button.value = info.text;
	else
		button.value = nil;
	end

	-- Show the expand arrow if it has one
	if ( info.hasArrow ) then
		_G[listFrameName.."Button"..index.."ExpandArrow"]:Show();
	else
		_G[listFrameName.."Button"..index.."ExpandArrow"]:Hide();
	end
	button.hasArrow = info.hasArrow;

	-- If not checkable move everything over to the left to fill in the gap where the check would be
	local xPos = 5;
	local yPos = -((button:GetID() - 1) * UIDROPDOWNNOTAINTMENU_BUTTON_HEIGHT) - UIDROPDOWNNOTAINTMENU_BORDER_HEIGHT;
	local displayInfo = normalText;
	if (info.iconOnly) then
		displayInfo = icon;
	end

	displayInfo:ClearAllPoints();
	if ( info.notCheckable ) then
		if ( info.justifyH and info.justifyH == "CENTER" ) then
			displayInfo:SetPoint("CENTER", button, "CENTER", -7, 0);
		else
			displayInfo:SetPoint("LEFT", button, "LEFT", 0, 0);
		end
		xPos = xPos + 10;

	else
		xPos = xPos + 12;
		displayInfo:SetPoint("LEFT", button, "LEFT", 20, 0);
	end

	-- Adjust offset if displayMode is menu
	local frame = UIDROPDOWNNOTAINTMENU_OPEN_MENU;
	if ( frame and frame.displayMode == "MENU" ) then
		if ( not info.notCheckable ) then
			xPos = xPos - 6;
		end
	end

	-- If no open frame then set the frame to the currently initialized frame
	frame = frame or UIDROPDOWNNOTAINTMENU_INIT_MENU;

	if ( info.leftPadding ) then
		xPos = xPos + info.leftPadding;
	end
	button:SetPoint("TOPLEFT", button:GetParent(), "TOPLEFT", xPos, yPos);

	-- See if button is selected by id or name
	if ( frame ) then
		if ( UIDropDownNoTaintMenu_GetSelectedName(frame) ) then
			if ( button:GetText() == UIDropDownNoTaintMenu_GetSelectedName(frame) ) then
				info.checked = 1;
			end
		elseif ( UIDropDownNoTaintMenu_GetSelectedID(frame) ) then
			if ( button:GetID() == UIDropDownNoTaintMenu_GetSelectedID(frame) ) then
				info.checked = 1;
			end
		elseif ( UIDropDownNoTaintMenu_GetSelectedValue(frame) ) then
			if ( button.value == UIDropDownNoTaintMenu_GetSelectedValue(frame) ) then
				info.checked = 1;
			end
		end
	end


	if not info.notCheckable then
		if info.isNotRadio then
			_G[listFrameName.."Button"..index.."Check"]:SetTexCoord(0.0, 0.5, 0.0, 0.5);
			_G[listFrameName.."Button"..index.."UnCheck"]:SetTexCoord(0.5, 1.0, 0.0, 0.5);
		else
			_G[listFrameName.."Button"..index.."Check"]:SetTexCoord(0.0, 0.5, 0.5, 1.0);
			_G[listFrameName.."Button"..index.."UnCheck"]:SetTexCoord(0.5, 1.0, 0.5, 1.0);
		end

		-- Checked can be a function now
		local checked = info.checked;
		if ( type(checked) == "function" ) then
			checked = checked(button);
		end

		-- Show the check if checked
		if ( checked ) then
			button:LockHighlight();
			_G[listFrameName.."Button"..index.."Check"]:Show();
			_G[listFrameName.."Button"..index.."UnCheck"]:Hide();
		else
			button:UnlockHighlight();
			_G[listFrameName.."Button"..index.."Check"]:Hide();
			_G[listFrameName.."Button"..index.."UnCheck"]:Show();
		end
	else
		_G[listFrameName.."Button"..index.."Check"]:Hide();
		_G[listFrameName.."Button"..index.."UnCheck"]:Hide();
	end
	button.checked = info.checked;

	-- If has a colorswatch, show it and vertex color it
	local colorSwatch = _G[listFrameName.."Button"..index.."ColorSwatch"];
	if ( info.hasColorSwatch ) then
		_G["DropDownNoTaintList"..level.."Button"..index.."ColorSwatch".."NormalTexture"]:SetVertexColor(info.r, info.g, info.b);
		button.r = info.r;
		button.g = info.g;
		button.b = info.b;
		colorSwatch:Show();
	else
		colorSwatch:Hide();
	end

	width = max(UIDropDownNoTaintMenu_GetButtonWidth(button), info.minWidth or 0);
	--Set maximum button width
	if ( width > listFrame.maxWidth ) then
		listFrame.maxWidth = width;
	end

	-- Set the height of the listframe
	listFrame:SetHeight((index * UIDROPDOWNNOTAINTMENU_BUTTON_HEIGHT) + (UIDROPDOWNNOTAINTMENU_BORDER_HEIGHT * 2));

	button:Show();
end

function UIDropDownNoTaintMenu_GetMaxButtonWidth(self)
	local maxWidth = 0;
	for i=1, self.numButtons do
		local button = _G[self:GetName().."Button"..i];
		if ( button:IsShown() ) then
			local width = UIDropDownNoTaintMenu_GetButtonWidth(button);
			if ( width > maxWidth ) then
				maxWidth = width;
			end
		end
	end
	return maxWidth;
end

function UIDropDownNoTaintMenu_GetButtonWidth(button)
	local width;
	local buttonName = button:GetName();
	local icon = _G[buttonName.."Icon"];
	local normalText = _G[buttonName.."NormalText"];

	if ( button.iconOnly and icon ) then
		width = icon:GetWidth();
	elseif ( normalText and normalText:GetText() ) then
		width = normalText:GetWidth() + 40;

		if ( button.icon ) then
			-- Add padding for the icon
			width = width + 10;
		end
	else
		return 0;
	end

	-- Add padding if has and expand arrow or color swatch
	if ( button.hasArrow or button.hasColorSwatch ) then
		width = width + 10;
	end
	if ( button.notCheckable ) then
		width = width - 30;
	end
	if ( button.padding ) then
		width = width + button.padding;
	end

	return width;
end

function UIDropDownNoTaintMenu_Refresh(frame, useValue, dropdownLevel)
	local button, checked, checkImage, uncheckImage, normalText, width;
	local maxWidth = 0;
	local somethingChecked = nil;
	if ( not dropdownLevel ) then
		dropdownLevel = UIDROPDOWNNOTAINTMENU_MENU_LEVEL;
	end

	local listFrame = _G["DropDownNoTaintList"..dropdownLevel];
	listFrame.numButtons = listFrame.numButtons or 0;
	-- Just redraws the existing menu
	for i=1, UIDROPDOWNNOTAINTMENU_MAXBUTTONS do
		button = _G["DropDownNoTaintList"..dropdownLevel.."Button"..i];
		checked = nil;

		if(i <= listFrame.numButtons) then
			-- See if checked or not
			if ( UIDropDownNoTaintMenu_GetSelectedName(frame) ) then
				if ( button:GetText() == UIDropDownNoTaintMenu_GetSelectedName(frame) ) then
					checked = 1;
				end
			elseif ( UIDropDownNoTaintMenu_GetSelectedID(frame) ) then
				if ( button:GetID() == UIDropDownNoTaintMenu_GetSelectedID(frame) ) then
					checked = 1;
				end
			elseif ( UIDropDownNoTaintMenu_GetSelectedValue(frame) ) then
				if ( button.value == UIDropDownNoTaintMenu_GetSelectedValue(frame) ) then
					checked = 1;
				end
			end
		end
		if (button.checked and type(button.checked) == "function") then
			checked = button.checked(button);
		end

		if not button.notCheckable and button:IsShown() then
			-- If checked show check image
			checkImage = _G["DropDownNoTaintList"..dropdownLevel.."Button"..i.."Check"];
			uncheckImage = _G["DropDownNoTaintList"..dropdownLevel.."Button"..i.."UnCheck"];
			if ( checked ) then
				somethingChecked = true;
				local icon = _G[frame:GetName().."Icon"];
				if (button.iconOnly and icon and button.icon) then
					UIDropDownNoTaintMenu_SetIconImage(icon, button.icon, button.iconInfo);
				elseif ( useValue ) then
					UIDropDownNoTaintMenu_SetText(frame, button.value);
					icon:Hide();
				else
					UIDropDownNoTaintMenu_SetText(frame, button:GetText());
					icon:Hide();
				end
				button:LockHighlight();
				checkImage:Show();
				uncheckImage:Hide();
			else
				button:UnlockHighlight();
				checkImage:Hide();
				uncheckImage:Show();
			end
		end

		if ( button:IsShown() ) then
			width = UIDropDownNoTaintMenu_GetButtonWidth(button);
			if ( width > maxWidth ) then
				maxWidth = width;
			end
		end
	end
	if(somethingChecked == nil) then
		UIDropDownNoTaintMenu_SetText(frame, VIDEO_QUALITY_LABEL6);
	end
	if (not frame.noResize) then
		for i=1, UIDROPDOWNNOTAINTMENU_MAXBUTTONS do
			button = _G["DropDownNoTaintList"..dropdownLevel.."Button"..i];
			button:SetWidth(maxWidth);
		end
		UIDropDownNoTaintMenu_RefreshDropDownNoTaintSize(_G["DropDownNoTaintList"..dropdownLevel]);
	end
end

function UIDropDownNoTaintMenu_RefreshAll(frame, useValue)
	for dropdownLevel = UIDROPDOWNNOTAINTMENU_MENU_LEVEL, 2, -1 do
		local listFrame = _G["DropDownNoTaintList"..dropdownLevel];
		if ( listFrame:IsShown() ) then
			UIDropDownNoTaintMenu_Refresh(frame, nil, dropdownLevel);
		end
	end
	-- useValue is the text on the dropdown, only needs to be set once
	UIDropDownNoTaintMenu_Refresh(frame, useValue, 1);
end

function UIDropDownNoTaintMenu_SetIconImage(icon, texture, info)
	icon:SetTexture(texture);
	if ( info.tCoordLeft ) then
		icon:SetTexCoord(info.tCoordLeft, info.tCoordRight, info.tCoordTop, info.tCoordBottom);
	else
		icon:SetTexCoord(0, 1, 0, 1);
	end
	if ( info.tSizeX ) then
		icon:SetWidth(info.tSizeX);
	else
		icon:SetWidth(16);
	end
	if ( info.tSizeY ) then
		icon:SetHeight(info.tSizeY);
	else
		icon:SetHeight(16);
	end
	icon:Show();
end

function UIDropDownNoTaintMenu_SetSelectedName(frame, name, useValue)
	frame.selectedName = name;
	frame.selectedID = nil;
	frame.selectedValue = nil;
	UIDropDownNoTaintMenu_Refresh(frame, useValue);
end

function UIDropDownNoTaintMenu_SetSelectedValue(frame, value, useValue)
	-- useValue will set the value as the text, not the name
	frame.selectedName = nil;
	frame.selectedID = nil;
	frame.selectedValue = value;
	UIDropDownNoTaintMenu_Refresh(frame, useValue);
end

function UIDropDownNoTaintMenu_SetSelectedID(frame, id, useValue)
	frame.selectedID = id;
	frame.selectedName = nil;
	frame.selectedValue = nil;
	UIDropDownNoTaintMenu_Refresh(frame, useValue);
end

function UIDropDownNoTaintMenu_GetSelectedName(frame)
	return frame.selectedName;
end

function UIDropDownNoTaintMenu_GetSelectedID(frame)
	if ( frame.selectedID ) then
		return frame.selectedID;
	else
		-- If no explicit selectedID then try to send the id of a selected value or name
		local button;
		for i=1, UIDROPDOWNNOTAINTMENU_MAXBUTTONS do
			button = _G["DropDownNoTaintList"..UIDROPDOWNNOTAINTMENU_MENU_LEVEL.."Button"..i];
			-- See if checked or not
			if ( UIDropDownNoTaintMenu_GetSelectedName(frame) ) then
				if ( button:GetText() == UIDropDownNoTaintMenu_GetSelectedName(frame) ) then
					return i;
				end
			elseif ( UIDropDownNoTaintMenu_GetSelectedValue(frame) ) then
				if ( button.value == UIDropDownNoTaintMenu_GetSelectedValue(frame) ) then
					return i;
				end
			end
		end
	end
end

function UIDropDownNoTaintMenu_GetSelectedValue(frame)
	return frame.selectedValue;
end

function UIDropDownNoTaintMenuButton_OnClick(self)
	local checked = self.checked;
	if ( type (checked) == "function" ) then
		checked = checked(self);
	end


	if ( self.keepShownOnClick ) then
		if not self.notCheckable then
			if ( checked ) then
				_G[self:GetName().."Check"]:Hide();
				_G[self:GetName().."UnCheck"]:Show();
				checked = false;
			else
				_G[self:GetName().."Check"]:Show();
				_G[self:GetName().."UnCheck"]:Hide();
				checked = true;
			end
		end
	else
		self:GetParent():Hide();
	end

	if ( type (self.checked) ~= "function" ) then
		self.checked = checked;
	end

	-- saving this here because func might use a dropdown, changing this self's attributes
	local playSound = true;
	if ( self.noClickSound ) then
		playSound = false;
	end

	local func = self.func;
	if ( func ) then
		func(self, self.arg1, self.arg2, checked);
	else
		return;
	end

	if ( playSound ) then
		PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON);
	end
end

function HideDropDownNoTaintMenu(level)
	local listFrame = _G["DropDownNoTaintList"..level];
	listFrame:Hide();
end

function ToggleDropDownNoTaintMenu(level, value, dropDownFrame, anchorName, xOffset, yOffset, menuList, button, autoHideDelay)
	if ( not level ) then
		level = 1;
	end
	UIDropDownNoTaintMenuDelegate:SetAttribute("createframes-level", level);
	UIDropDownNoTaintMenuDelegate:SetAttribute("createframes-index", 0);
	UIDropDownNoTaintMenuDelegate:SetAttribute("createframes", true);
	UIDROPDOWNNOTAINTMENU_MENU_LEVEL = level;
	UIDROPDOWNNOTAINTMENU_MENU_VALUE = value;
	local listFrame = _G["DropDownNoTaintList"..level];
	local listFrameName = "DropDownNoTaintList"..level;
	local tempFrame;
	local point, relativePoint, relativeTo;
	if ( not dropDownFrame ) then
		tempFrame = button:GetParent();
	else
		tempFrame = dropDownFrame;
	end
	if ( listFrame:IsShown() and (UIDROPDOWNNOTAINTMENU_OPEN_MENU == tempFrame) ) then
		listFrame:Hide();
	else
		-- Set the dropdownframe scale
		local uiScale;
		local uiParentScale = UIParent:GetScale();
		if ( GetCVar("useUIScale") == "1" ) then
			uiScale = tonumber(GetCVar("uiscale"));
			if ( uiParentScale < uiScale ) then
				uiScale = uiParentScale;
			end
		else
			uiScale = uiParentScale;
		end
		listFrame:SetScale(uiScale);

		-- Hide the listframe anyways since it is redrawn OnShow()
		listFrame:Hide();

		-- Frame to anchor the dropdown menu to
		local anchorFrame;

		-- Display stuff
		-- Level specific stuff
		if ( level == 1 ) then
			UIDropDownNoTaintMenuDelegate:SetAttribute("openmenu", dropDownFrame);
			listFrame:ClearAllPoints();
			-- If there's no specified anchorName then use left side of the dropdown menu
			if ( not anchorName ) then
				-- See if the anchor was set manually using setanchor
				if ( dropDownFrame.xOffset ) then
					xOffset = dropDownFrame.xOffset;
				end
				if ( dropDownFrame.yOffset ) then
					yOffset = dropDownFrame.yOffset;
				end
				if ( dropDownFrame.point ) then
					point = dropDownFrame.point;
				end
				if ( dropDownFrame.relativeTo ) then
					relativeTo = dropDownFrame.relativeTo;
				else
					relativeTo = UIDROPDOWNNOTAINTMENU_OPEN_MENU:GetName().."Left";
				end
				if ( dropDownFrame.relativePoint ) then
					relativePoint = dropDownFrame.relativePoint;
				end
			elseif ( anchorName == "cursor" ) then
				relativeTo = nil;
				local cursorX, cursorY = GetCursorPosition();
				cursorX = cursorX/uiScale;
				cursorY =  cursorY/uiScale;

				if ( not xOffset ) then
					xOffset = 0;
				end
				if ( not yOffset ) then
					yOffset = 0;
				end
				xOffset = cursorX + xOffset;
				yOffset = cursorY + yOffset;
			else
				-- See if the anchor was set manually using setanchor
				if ( dropDownFrame.xOffset ) then
					xOffset = dropDownFrame.xOffset;
				end
				if ( dropDownFrame.yOffset ) then
					yOffset = dropDownFrame.yOffset;
				end
				if ( dropDownFrame.point ) then
					point = dropDownFrame.point;
				end
				if ( dropDownFrame.relativeTo ) then
					relativeTo = dropDownFrame.relativeTo;
				else
					relativeTo = anchorName;
				end
				if ( dropDownFrame.relativePoint ) then
					relativePoint = dropDownFrame.relativePoint;
				end
			end
			if ( not xOffset or not yOffset ) then
				xOffset = 8;
				yOffset = 22;
			end
			if ( not point ) then
				point = "TOPLEFT";
			end
			if ( not relativePoint ) then
				relativePoint = "BOTTOMLEFT";
			end
			listFrame:SetPoint(point, relativeTo, relativePoint, xOffset, yOffset);
		else
			if ( not dropDownFrame ) then
				dropDownFrame = UIDROPDOWNNOTAINTMENU_OPEN_MENU;
			end
			listFrame:ClearAllPoints();
			-- If this is a dropdown button, not the arrow anchor it to itself
			if ( strsub(button:GetParent():GetName(), 0,12) == "DropDownNoTaintList" and strlen(button:GetParent():GetName()) == 13 ) then
				anchorFrame = button;
			else
				anchorFrame = button:GetParent();
			end
			point = "TOPLEFT";
			relativePoint = "TOPRIGHT";
			listFrame:SetPoint(point, anchorFrame, relativePoint, 0, 0);
		end

		-- Change list box appearance depending on display mode
		if ( dropDownFrame and dropDownFrame.displayMode == "MENU" ) then
			_G[listFrameName.."Backdrop"]:Hide();
			_G[listFrameName.."MenuBackdrop"]:Show();
		else
			_G[listFrameName.."Backdrop"]:Show();
			_G[listFrameName.."MenuBackdrop"]:Hide();
		end
		dropDownFrame.menuList = menuList;
		UIDropDownNoTaintMenu_Initialize(dropDownFrame, dropDownFrame.initialize, nil, level, menuList);
		-- If no items in the drop down don't show it
		if ( listFrame.numButtons == 0 ) then
			return;
		end

		-- Check to see if the dropdownlist is off the screen, if it is anchor it to the top of the dropdown button
		listFrame:Show();
		-- Hack since GetCenter() is returning coords relative to 1024x768
		local x, y = listFrame:GetCenter();
		-- Hack will fix this in next revision of dropdowns
		if ( not x or not y ) then
			listFrame:Hide();
			return;
		end

		listFrame.onHide = dropDownFrame.onHide;


		--  We just move level 1 enough to keep it on the screen. We don't necessarily change the anchors.
		if ( level == 1 ) then
			local offLeft = listFrame:GetLeft()/uiScale;
			local offRight = (GetScreenWidth() - listFrame:GetRight())/uiScale;
			local offTop = (GetScreenHeight() - listFrame:GetTop())/uiScale;
			local offBottom = listFrame:GetBottom()/uiScale;

			local xAddOffset, yAddOffset = 0, 0;
			if ( offLeft < 0 ) then
				xAddOffset = -offLeft;
			elseif ( offRight < 0 ) then
				xAddOffset = offRight;
			end

			if ( offTop < 0 ) then
				yAddOffset = offTop;
			elseif ( offBottom < 0 ) then
				yAddOffset = -offBottom;
			end

			listFrame:ClearAllPoints();
			if ( anchorName == "cursor" ) then
				listFrame:SetPoint(point, relativeTo, relativePoint, xOffset + xAddOffset, yOffset + yAddOffset);
			else
				listFrame:SetPoint(point, relativeTo, relativePoint, xOffset + xAddOffset, yOffset + yAddOffset);
			end
		else
			-- Determine whether the menu is off the screen or not
			local offscreenY, offscreenX;
			if ( (y - listFrame:GetHeight()/2) < 0 ) then
				offscreenY = 1;
			end
			if ( listFrame:GetRight() > GetScreenWidth() ) then
				offscreenX = 1;
			end
			if ( offscreenY and offscreenX ) then
				point = gsub(point, "TOP(.*)", "BOTTOM%1");
				point = gsub(point, "(.*)LEFT", "%1RIGHT");
				relativePoint = gsub(relativePoint, "TOP(.*)", "BOTTOM%1");
				relativePoint = gsub(relativePoint, "(.*)RIGHT", "%1LEFT");
				xOffset = -11;
				yOffset = -14;
			elseif ( offscreenY ) then
				point = gsub(point, "TOP(.*)", "BOTTOM%1");
				relativePoint = gsub(relativePoint, "TOP(.*)", "BOTTOM%1");
				xOffset = 0;
				yOffset = -14;
			elseif ( offscreenX ) then
				point = gsub(point, "(.*)LEFT", "%1RIGHT");
				relativePoint = gsub(relativePoint, "(.*)RIGHT", "%1LEFT");
				xOffset = -11;
				yOffset = 14;
			else
				xOffset = 0;
				yOffset = 14;
			end

			listFrame:ClearAllPoints();
			listFrame.parentLevel = tonumber(strmatch(anchorFrame:GetName(), "DropDownNoTaintList(%d+)"));
			listFrame.parentID = anchorFrame:GetID();
			listFrame:SetPoint(point, anchorFrame, relativePoint, xOffset, yOffset);
		end

		if ( autoHideDelay and tonumber(autoHideDelay)) then
			listFrame.showTimer = autoHideDelay;
			listFrame.isCounting = 1;
		end
	end
end

function CloseDropDownNoTaintMenus(level)
	if ( not level ) then
		level = 1;
	end
	for i=level, UIDROPDOWNNOTAINTMENU_MAXLEVELS do
		_G["DropDownNoTaintList"..i]:Hide();
	end
end

function UIDropDownNoTaintMenu_OnHide(self)
	local id = self:GetID()
	if ( self.onHide ) then
		self.onHide(id+1);
		self.onHide = nil;
	end
	CloseDropDownNoTaintMenus(id+1);
	OPEN_DROPDOWNNOTAINTMENUS[id] = nil;
end

function UIDropDownNoTaintMenu_SetWidth(frame, width, padding)
	_G[frame:GetName().."Middle"]:SetWidth(width);
	local defaultPadding = 25;
	if ( padding ) then
		frame:SetWidth(width + padding);
	else
		frame:SetWidth(width + defaultPadding + defaultPadding);
	end
	if ( padding ) then
		_G[frame:GetName().."Text"]:SetWidth(width);
	else
		_G[frame:GetName().."Text"]:SetWidth(width - defaultPadding);
	end
	frame.noResize = 1;
end

function UIDropDownNoTaintMenu_SetButtonWidth(frame, width)
	if ( width == "TEXT" ) then
		width = _G[frame:GetName().."Text"]:GetWidth();
	end

	_G[frame:GetName().."Button"]:SetWidth(width);
	frame.noResize = 1;
end

function UIDropDownNoTaintMenu_SetText(frame, text)
	local filterText = _G[frame:GetName().."Text"];
	filterText:SetText(text);
end

function UIDropDownNoTaintMenu_GetText(frame)
	local filterText = _G[frame:GetName().."Text"];
	return filterText:GetText();
end

function UIDropDownNoTaintMenu_ClearAll(frame)
	-- Previous code refreshed the menu quite often and was a performance bottleneck
	frame.selectedID = nil;
	frame.selectedName = nil;
	frame.selectedValue = nil;
	UIDropDownNoTaintMenu_SetText(frame, "");

	local button, checkImage, uncheckImage;
	for i=1, UIDROPDOWNNOTAINTMENU_MAXBUTTONS do
		button = _G["DropDownNoTaintList"..UIDROPDOWNNOTAINTMENU_MENU_LEVEL.."Button"..i];
		button:UnlockHighlight();

		checkImage = _G["DropDownNoTaintList"..UIDROPDOWNNOTAINTMENU_MENU_LEVEL.."Button"..i.."Check"];
		checkImage:Hide();
		uncheckImage = _G["DropDownNoTaintList"..UIDROPDOWNNOTAINTMENU_MENU_LEVEL.."Button"..i.."UnCheck"];
		uncheckImage:Hide();
	end
end

function UIDropDownNoTaintMenu_JustifyText(frame, justification)
	local text = _G[frame:GetName().."Text"];
	text:ClearAllPoints();
	if ( justification == "LEFT" ) then
		text:SetPoint("LEFT", frame:GetName().."Left", "LEFT", 27, 2);
		text:SetJustifyH("LEFT");
	elseif ( justification == "RIGHT" ) then
		text:SetPoint("RIGHT", frame:GetName().."Right", "RIGHT", -43, 2);
		text:SetJustifyH("RIGHT");
	elseif ( justification == "CENTER" ) then
		text:SetPoint("CENTER", frame:GetName().."Middle", "CENTER", -5, 2);
		text:SetJustifyH("CENTER");
	end
end

function UIDropDownNoTaintMenu_SetAnchor(dropdown, xOffset, yOffset, point, relativeTo, relativePoint)
	dropdown.xOffset = xOffset;
	dropdown.yOffset = yOffset;
	dropdown.point = point;
	dropdown.relativeTo = relativeTo;
	dropdown.relativePoint = relativePoint;
end

function UIDropDownNoTaintMenu_GetCurrentDropDownNoTaint()
	if ( UIDROPDOWNNOTAINTMENU_OPEN_MENU ) then
		return UIDROPDOWNNOTAINTMENU_OPEN_MENU;
	elseif ( UIDROPDOWNNOTAINTMENU_INIT_MENU ) then
		return UIDROPDOWNNOTAINTMENU_INIT_MENU;
	end
end

function UIDropDownNoTaintMenuButton_GetChecked(self)
	return _G[self:GetName().."Check"]:IsShown();
end

function UIDropDownNoTaintMenuButton_GetName(self)
	return _G[self:GetName().."NormalText"]:GetText();
end

function UIDropDownNoTaintMenuButton_OpenColorPicker(self, button)
	CloseMenus();
	if ( not button ) then
		button = self;
	end
	UIDROPDOWNNOTAINTMENU_MENU_VALUE = button.value;
	OpenColorPicker(button);
end

function UIDropDownNoTaintMenu_DisableButton(level, id)
	_G["DropDownNoTaintList"..level.."Button"..id]:Disable();
end

function UIDropDownNoTaintMenu_EnableButton(level, id)
	_G["DropDownNoTaintList"..level.."Button"..id]:Enable();
end

function UIDropDownNoTaintMenu_SetButtonText(level, id, text, colorCode)
	local button = _G["DropDownNoTaintList"..level.."Button"..id];
	if ( colorCode) then
		button:SetText(colorCode..text.."|r");
	else
		button:SetText(text);
	end
end

function UIDropDownNoTaintMenu_SetButtonNotClickable(level, id)
	_G["DropDownNoTaintList"..level.."Button"..id]:SetDisabledFontObject(GameFontHighlightSmallLeft);
end

function UIDropDownNoTaintMenu_SetButtonClickable(level, id)
	_G["DropDownNoTaintList"..level.."Button"..id]:SetDisabledFontObject(GameFontDisableSmallLeft);
end

function UIDropDownNoTaintMenu_DisableDropDownNoTaint(dropDown)
	local label = _G[dropDown:GetName().."Label"];
	if ( label ) then
		label:SetVertexColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b);
	end
	_G[dropDown:GetName().."Text"]:SetVertexColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b);
	_G[dropDown:GetName().."Button"]:Disable();
	dropDown.isDisabled = 1;
end

function UIDropDownNoTaintMenu_EnableDropDownNoTaint(dropDown)
	local label = _G[dropDown:GetName().."Label"];
	if ( label ) then
		label:SetVertexColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
	end
	_G[dropDown:GetName().."Text"]:SetVertexColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
	_G[dropDown:GetName().."Button"]:Enable();
	dropDown.isDisabled = nil;
end

function UIDropDownNoTaintMenu_IsEnabled(dropDown)
	return not dropDown.isDisabled;
end

function UIDropDownNoTaintMenu_GetValue(id)
	--Only works if the dropdown has just been initialized, lame, I know =(
	local button = _G["DropDownNoTaintList1Button"..id];
	if ( button ) then
		return _G["DropDownNoTaintList1Button"..id].value;
	else
		return nil;
	end
end

function OpenColorPicker(info)
	ColorPickerFrame.func = info.swatchFunc;
	ColorPickerFrame.hasOpacity = info.hasOpacity;
	ColorPickerFrame.opacityFunc = info.opacityFunc;
	ColorPickerFrame.opacity = info.opacity;
	ColorPickerFrame.previousValues = {r = info.r, g = info.g, b = info.b, opacity = info.opacity};
	ColorPickerFrame.cancelFunc = info.cancelFunc;
	ColorPickerFrame.extraInfo = info.extraInfo;
	-- This must come last, since it triggers a call to ColorPickerFrame.func()
	ColorPickerFrame:SetColorRGB(info.r, info.g, info.b);
	ShowUIPanel(ColorPickerFrame);
end

function ColorPicker_GetPreviousValues()
	return ColorPickerFrame.previousValues.r, ColorPickerFrame.previousValues.g, ColorPickerFrame.previousValues.b;
end