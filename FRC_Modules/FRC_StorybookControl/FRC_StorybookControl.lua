local FRC_Layout = require('FRC_Modules.FRC_Layout.FRC_Layout');
local ui = require('ui');
local FRC_StorybookControl = Runtime._super:new();

-- checkoptions.callee should be set before calling any other method
local checkoptions = {};
checkoptions.callee = ''; -- name of function calling a checkoptions method

-- adds Corona 'DisplayObject' to Lua type() function
--[[
local cached_type = type;
type = function(obj)
	if ((cached_type(obj) == 'table') and (obj._class) and (obj._class.addEventListener)) then
		return "DisplayObject";
	else
		return cached_type(obj);
	end
end
--]]

local activeMenu;
-- TODO:  put values like these into a settings.JSON file for this module
local controlsAlpha = 0.4;
local autohideDelay = 5000;

-- check for required options; sets defaults
checkoptions.check = function(options, required, defaults)
	assert(options);
	assert(required);
	assert(defaults);

	if (required) then
		for k,v in pairs(required) do
			-- check for all required options
			assert(options[k], 'Missing Option: \'' .. k .. '\' is a required option for \'' .. checkoptions.callee .. '\'');

			-- ensure option is the proper type
			assert(type(options[k]) == v, 'Type Error: option' .. '\'' .. k .. '\' in \'' .. checkoptions.callee .. '\' must be a ' .. v .. '. Got ' .. type(options[k]));
		end
	end

	-- check options table for default keys (if key is not present, use default)
	if (defaults) then
		for k,v in pairs(defaults) do
			if (options[k] == nil) then
				options[k] = v;
			end
		end
	end

	return options;
end

local requiredOptions = {
	buttonWidth = 'number',
	buttonHeight = 'number',
	parent = 'table'
};

local defaultOptions = {
	items = {},
	top = 0,
	left = 0,
	buttons = {},
	buttonPadding = 20
};

local function show(self)
	-- DEBUG:
	print("FRC_StorybookControl SHOW");
	if (self.hideTimer) then timer.cancel(self.hideTimer); self.hideTimer = nil; end
	-- TODO:  put the timer delay in the next line into a settings.JSON file for this module
	self.hideTimer = timer.performWithDelay(autohideDelay, function()
		self.hideTimer = nil;
		self:hide();
	end, 1);

	-- if (not self.isHidden) then self.alpha = 1.0; return; end
	--[[ if (self.showTransition) then transition.cancel(self.showTransition); self.showTransition = nil; end
	self.showTransition = transition.to(self, { time=400, alpha=1.0, onComplete=function()

		self.isHidden = false;
	end });
	--]]

	self.isHidden = false;

	if ((self.menuItems) and (self.menuItems.numChildren > 0)) then
		for i=1, self.menuItems.numChildren do
			self.menuItems[i].alpha = controlsAlpha; -- immediate
			-- transition.to(self.menuItems[i], { time = 400, alpha = controlsAlpha });
		end
	end

	if (self.next) then
		self.next.alpha = controlsAlpha; -- immediate
		-- transition.to(self.next, { time = 400, alpha = controlsAlpha });
	end

	if (self.previous) then
		self.previous.alpha = controlsAlpha; -- immediate
		-- transition.to(self.previous, { time = 400, alpha = controlsAlpha });
	end

end

local function hide(self, doNotDispatch)
	-- DEBUG:
	print("FRC_StorybookControl HIDE");
	if (self.hideTimer) then timer.cancel(self.hideTimer); self.hideTimer = nil; end
	-- if (self.isHidden) then self.alpha = 0; return; end
	if (self.showTransition) then transition.cancel(self.showTransition); self.showTransition = nil; end

	--[[ self.showTransition = transition.to(self, { time=400, alpha=0, onComplete=function()
		self.isHidden = true;
		-- self.menuItems.x = self.menuItems.xHidden;

		if (not doNotDispatch) then
			Runtime:dispatchEvent({
				name = "FRC_MenuClose",
				type = "FRC_ActionBar",
				time = 400
			});
		end

		if (not doNotDispatch) then
			Runtime:dispatchEvent({
				name = "FRC_MenuClose",
				type = "FRC_SettingsBar",
				time = 400
			});
		end

	end });
	--]]

	self.isHidden = true;

	for i=1, self.menuItems.numChildren do
		if (not self.menuItems[i].forceDisplay) then
			self.menuItems[i].alpha = 0; -- immediate
			-- transition.to(self.menuItems[i], { time = 400, alpha = 0 });
		end
	end

	if (self.next and not self.next.forceDisplay) then
		self.next.alpha = 0; -- immediate
		-- transition.to(self.next, { time = 400, alpha = 0 });
	end

	if (self.previous and not self.previous.forceDisplay) then
		self.previous.alpha = 0; -- immediate
		-- transition.to(self.previous, { time = 400, alpha = 0 });
	end

end

local function dispose(self)
	-- DEBUG:
	print("FRC_StorybookControl DISPOSING");
	if (self.isDisposed) then return; end
	if (self.hideTimer) then timer.cancel(self.hideTimer); self.hideTimer = nil; end
	if (self.showTransition) then transition.cancel(self.showTransition); self.showTransition = nil; end

	if ((self.menuItems) and (self.menuItems.numChildren > 0)) then
		for i=self.menuItems.numChildren,1,-1 do
			if (self.menuItems[i].dispose) then
				self.menuItems[i]:dispose();
			else
				self.menuItems[i]:removeSelf();
			end
		end
		self.menuItems:removeSelf();
		self.menuItems = nil;
	end

	if (activeMenu == self) then
		activeMenu = nil;
	end

	if (menuGroup.next) then
		menuGroup.next:removeSelf();
		menuGroup.next = nil;
	end
	if (menuGroup.previous) then
		menuGroup.previous:removeSelf();
		menuGroup.previous = nil;
	end
	if (self.pauseCover) then
		self.pauseCover:removeSelf();
		self.pauseCover = nil;
	end

	if (self.menuActivator) then
		self.menuActivator:removeSelf();
		self.menuActivator = nil;
	end
	self:removeSelf();
	collectgarbage("collect");
	self.isDisposed = true;
end

-- used when the BookParser reaches the interactive phase
FRC_StorybookControl.hideMenuItems = function()
	if (activeMenu.menuItems) then activeMenu.menuItems.isVisible = false; end
end

-- used when the BookParser reaches the interactive phase
FRC_StorybookControl.showMenuItems = function()
	if (activeMenu.menuItems) then activeMenu.menuItems.isVisible = true; end
end

local function togglePause(self, state)
	if ((self.menuItems) and (self.menuItems.numChildren > 0)) then
		for i=1, self.menuItems.numChildren do
			-- DEBUG:
			-- print("TOGGLE PAUSE id check: ", self.menuItems[i].id);
			if (self.menuItems[i].id == 'pause') then

				if (state) then
					-- set the new value if provided
					self.menuItems[i].forceDisplay = state;
				else
					-- otherwise toggle the current value
					self.menuItems[i].forceDisplay = not self.menuItems[i].forceDisplay;
				end

				-- DEBUG:
				-- print("PAUSE forceDisplay: ", self.menuItems[i].forceDisplay);
				activeMenu.pauseCover.isVisible = state; -- self.menuItems[i].forceDisplay;
			end
		end
	end
end

-- used when the BookParser reaches the interactive phase
FRC_StorybookControl.showNavButtons = function()
	if (activeMenu.next) then
		activeMenu.next.alpha = controlsAlpha;
		activeMenu.next.forceDisplay = true;
	end
	if (activeMenu.previous) then
		activeMenu.previous.alpha = controlsAlpha;
		activeMenu.previous.forceDisplay = true;
	end
end

-- used when the BookParser enter the storybook phase
FRC_StorybookControl.hideNavButtons = function()
	if (activeMenu.next) then
		activeMenu.next.alpha = 0;
	  activeMenu.next.forceDisplay = false;
	end
	if (activeMenu.previous) then
		activeMenu.previous.alpha = 0;
		activeMenu.previous.forceDisplay = false;
	end
end


--[[
FRC_StorybookControl.hidePauseCover = function()
	if (activeMenu.pauseCover) then
		activeMenu.pauseCover.isVisible = false;
	end
end
--]]

FRC_StorybookControl.new = function(args)
	checkoptions.callee = 'FRC_StorybookControl.new';
	local options = checkoptions.check(args, requiredOptions, defaultOptions);
	local screenW, screenH = FRC_Layout.getScreenDimensions();

	local menuGroup = display.newGroup();
	local screenOverlayGroup = display.newGroup();
	menuGroup:insert(screenOverlayGroup);

	local pauseCover = display.newRect(0, 0, screenW, screenH);
	-- menuGroup:insert(pauseCover);
	menuGroup.pauseCover = pauseCover;

	pauseCover.fill = {0,0,0,0.4};
	pauseCover.isVisible = false;
	pauseCover.x = display.contentCenterX;
	pauseCover.y = display.contentCenterY;

	options.parent:insert(menuGroup.pauseCover);

	local menuItems = display.newGroup();
	menuGroup:insert(menuItems);


	-- Create sub-menu buttons
	local x, y = 0,0; -- toggleButton.x, toggleButton.y;
	for i=1,#options.buttons do
		local button = ui.button.new({
			id = options.buttons[i].id,
			imageUp = options.buttons[i].imageUp,
			imageDown = options.buttons[i].imageDown,
			focusState = options.buttons[i].focusState,
			disabled = options.buttons[i].disabled,
			width = options.buttonWidth,
			height = options.buttonHeight,
			onPress = function(e)
				menuGroup:show(); -- is this needed?
				if (e.target.onPress) then e.target.onPress(e); end
			end,
			onRelease = options.buttons[i].onRelease
		});
		button.onPress = options.buttons[i].onPress;
		if (options.buttons[i].isFocused) then
			button:setFocusState(true);
		end
		if (options.buttons[i].isDisabled) then
			button:setDisabledState(true);
		end
		-- set up the forceDisplay property which precludes the item from being hidden
		button.forceDisplay = false;
		menuItems:insert(button);
		x = x + button.contentWidth + options.buttonPadding;
		button.x = x;
		button.y = y;
	end

	-- create the prev and next navigation buttons
	local nextButton = options.nextButtonData;
	if (nextButton) then
		menuGroup.next = nextButton;
		menuGroup.next.alpha = 0
		menuGroup.next.forceDisplay = false;
		-- menuGroup:insert(nextButton);
		-- DEBUG:
		print("StorybookControl ATTACHING NEXT BUTTON");
	end
	local prevButton = options.prevButtonData;
	if (prevButton) then
		menuGroup.previous = prevButton;
		menuGroup.previous.alpha = 0;
		menuGroup.previous.forceDisplay = false;
		-- menuGroup:insert(prevButton);
		-- DEBUG:
		print("StorybookControl ATTACHING PREV BUTTON");
	end

	menuItems.x = 0; -- display.contentCenterX;
	menuItems.y = 0; -- display.contentCenterY;

	if ((menuItems) and (menuItems.numChildren > 0)) then
		for i=1, menuItems.numChildren do
			menuItems[i].alpha = 0;
		end
	end
	-- menuItems.alpha = controlsAlpha;

	-- TODO:
	-- this next line needs cleanup
	menuGroup.x = (screenW * 0.5) - ((screenW - display.contentWidth) * 0.5) - (menuGroup.width * .75);
	menuGroup.y = (screenH * 0.5) - (menuItems.height * 0.25);

	-- create background overlay to capture touches behind everything else
	menuGroup.menuActivator = display.newRect(0, 0, screenW, screenH);
	menuGroup.menuActivator.alpha = 0;
	menuGroup.menuActivator.isHitTestable = true;
	-- this connects the menuActivator (transparent full screen background object) to the parent
	-- so that touch events will trigger the appropriate response
	options.parent:insert(2, menuGroup.menuActivator); -- out of bounds?!
	menuGroup.menuActivator.x = display.contentCenterX;
	menuGroup.menuActivator.y = display.contentCenterY;

	-- DEBUG:
	--[[
	print("StorybookControl menuItems x/y: ", menuItems.x, "/", menuItems.y);
	print("StorybookControl menuItems width/height: ", menuItems.contentWidth, "/", menuItems.contentHeight);
	print("StorybookControl menuGroup x/y: ", menuGroup.x, "/", menuGroup.y);
	print("StorybookControl menuGroup width/height: ", menuGroup.contentWidth, "/", menuGroup.contentHeight);
	--]]

	menuGroup.menuActivator:addEventListener('touch', function(event)
		if (event.phase == "began") then
			-- DEBUG:
			print("menuGroup.menuActivator TOUCH");
			if (menuGroup.pauseCover.isVisible) then
				-- tell the pause button it has been pressed
				for i=1, menuItems.numChildren do
					if (menuItems[i].id == 'pause') then
					  menuItems[i]:dispatchEvent( { name = "press", target = menuItems[i] } );
					end
				end
			elseif (menuGroup.isHidden) then
				menuGroup:show();
			else
				menuGroup:hide();
			end
			return true  --prevent propagation to underlying tap objects
		end
		-- return false;
	end);

	-- properties and methods
	menuGroup.menuItems = menuItems;
	--[[ menuGroup.alpha = 0;
	if (menuGroup.next) then menuGroup.next.alpha = 0; end
	if (menuGroup.previous) then menuGroup.previous.alpha = 0; end
	--]]
	menuGroup.isHidden = true;
	menuGroup.show = show;
	menuGroup.hide = hide;
	menuGroup.togglePause = togglePause;
	menuGroup.dispose = function(self) pcall(dispose, self); end

	activeMenu = menuGroup;
	return menuGroup;
end

function FRC_StorybookControl.onUnrelatedTouch(event)
	if (not activeMenu) then return; end
	activeMenu.pauseCover.isVisible = false;
	activeMenu:hide();
end

FRC_StorybookControl:addEventListener('unrelatedTouch', FRC_StorybookControl.onUnrelatedTouch);

return FRC_StorybookControl;
