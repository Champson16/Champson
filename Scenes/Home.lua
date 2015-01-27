local ui = require('ui');
local FRC_Layout = require('FRC_Modules.FRC_Layout.FRC_Layout');
local storyboard = require('storyboard');
local FRC_ActionBar = require('FRC_Modules.FRC_ActionBar.FRC_ActionBar');
local FRC_SettingsBar = require('FRC_Modules.FRC_SettingsBar.FRC_SettingsBar');
local FRC_AnimationManager = require('FRC_Modules.FRC_AnimationManager.FRC_AnimationManager');
local FRC_AudioManager = require('FRC_Modules.FRC_AudioManager.FRC_AudioManager');
local FRC_AppSettings = require('FRC_Modules.FRC_AppSettings.FRC_AppSettings');
local math_random = math.random;

local animationSequences = {};
local animationXMLBase = 'FRC_Assets/GENU_Assets/Animation/XMLData/';
local animationImageBase = 'FRC_Assets/GENU_Assets/Animation/Images/';

local scene = storyboard.newScene();
local webView;

scene.backHandler = function()
	if (webView) then
		webView.closeButton:dispatchEvent({
			name = "release",
			target = webView.closeButton
		});
	else
		native.showAlert('Exit?', 'Are you sure you want to exit the app?', { "Cancel", "OK" }, function(event)
			if (event.index == 2) then
				native.requestExit();
			end
		end);
	end
end

function scene.playTheme1()
	-- DEBUG:
	print("playing THEME1");
	ambientMusic = FRC_AudioManager:findGroup("ambientMusic");
	if ambientMusic then
		scene.currentThemeMusic = "UofChewTheme1";
		ambientMusic:play("UofChewTheme1", { onComplete = function() scene.playTheme2(); end } );
		if (not FRC_AppSettings.get("ambientSoundOn")) then
			-- DEBUG:
			print("scene.playTheme1 - PAUSING AMBIENT MUSIC");
			ambientMusic:pause();
		end
	end
end

function scene.playTheme2()
	-- DEBUG:
	print("playing THEME2");
	ambientMusic = FRC_AudioManager:findGroup("ambientMusic");
	if ambientMusic then
		scene.currentThemeMusic = "UofChewTheme2";
		ambientMusic:play("UofChewTheme2", { onComplete = function() scene.playTheme1(); end } );
		if (not FRC_AppSettings.get("ambientSoundOn")) then
			-- DEBUG:
			print("scene.playTheme2 - PAUSING AMBIENT MUSIC");
			ambientMusic:pause();
		end
	end
end

function scene.onCanvasTouch(self, event)

	if (event.phase == "began") then
		-- nothing yet
	elseif (event.phase == "moved") then
		-- enable pinch-scaling when one finger is on a shape/stamp and the other on the canvas
		if (event.list and scene.currentlyPinchingObject and scene.initialTouchList) then
			local list = {};
			list[1] = scene.initialTouchList;
			list[2] = event.list[1];
			doPinchZoom(scene.currentlyPinchingObject, list);
		end
	end

	return true;
end

function scene.removeControls(self)
	local transArray = {};
	scene.buttonIsActive = true;
end

function scene.stopThemeMusic(self)
	local ambientMusic = FRC_AudioManager:findGroup("ambientMusic");
	if ambientMusic then
		-- find the current theme music
		local themeMusic = ambientMusic:findHandle(scene.currentThemeMusic);
		if (themeMusic and themeMusic:isPlaying()) then
			ambientMusic:stop();
		end
	end
end

function scene.createScene(self, event)
	local scene = self;
	local view = scene.view;

	local screenW, screenH = FRC_Layout.getScreenDimensions();

	local imageBase = 'FRC_Assets/GENU_Assets/Images/';
	local videoBase = 'FRC_Assets/GENU_Assets/Videos/';

	local genericDialogBackground, sugaryCloseButton, sugaryBackground; -- forward declarations

	-- animations for main navigation buttons at the bottom of the screen
	local transArray = {};

	-- set up the display of the background image and logo
	local bgGroup = display.newGroup();
	bgGroup.anchorChildren = false;
	bgGroup.anchorX = 0.5;
	bgGroup.anchorY = 0.5;

	local function calculateDelta( previousTouches, event )

		local id,touch = next( previousTouches )
		if event.id == id then
			id,touch = next( previousTouches, id )
			assert( id ~= event.id )
		end

		local dx = touch.x - event.x
		local dy = touch.y - event.y
		return dx, dy

	end

	local function calculateCenter( previousTouches, event )

		local id,touch = next( previousTouches )
		if event.id == id then
			id,touch = next( previousTouches, id )
			assert( id ~= event.id )
		end

		local cx = math.floor( ( touch.x + event.x ) * 0.5 )
		local cy = math.floor( ( touch.y + event.y ) * 0.5 )
		return cx, cy

	end

	-- create a table listener object for the bkgd image
	function bgGroup:touch( event )

		local phase = event.phase
		local eventTime = event.time
		local previousTouches = self.previousTouches

		if not self.xScaleStart then
			self.xScaleStart, self.yScaleStart = self.xScale, self.yScale
		end

		local numTotalTouches = 1
		if previousTouches then
			-- add in total from previousTouches, subtract one if event is already in the array
			numTotalTouches = numTotalTouches + self.numPreviousTouches
			if previousTouches[event.id] then
				numTotalTouches = numTotalTouches - 1
			end
		end

		if "began" == phase then
			-- Very first "began" event
			if not self.isFocus then
				-- Subsequent touch events will target button even if they are outside the contentBounds of button
				display.getCurrentStage():setFocus( self )
				self.isFocus = true

				-- Store initial position
				self.x0 = event.x - self.x
				self.y0 = event.y - self.y

				previousTouches = {}
				self.previousTouches = previousTouches
				self.numPreviousTouches = 0
				self.firstTouch = event

			elseif not self.distance then
				local dx,dy
				local cx,cy

				if previousTouches and numTotalTouches >= 2 then
					dx,dy = calculateDelta( previousTouches, event )
					cx,cy = calculateCenter( previousTouches, event )
				end

				-- initialize to distance between two touches
				if dx and dy then
					local d = math.sqrt( dx*dx + dy*dy )
					if d > 0 then
						self.distance = d
						self.xScaleOriginal = self.xScale
						self.yScaleOriginal = self.yScale

						self.x0 = cx - self.x
						self.y0 = cy - self.y

					end
				end

			end

			if not previousTouches[event.id] then
				self.numPreviousTouches = self.numPreviousTouches + 1
			end
			previousTouches[event.id] = event

		elseif self.isFocus then
			if "moved" == phase then
				if self.distance then
					local dx,dy
					local cx,cy
					if previousTouches and numTotalTouches == 2 then
						dx,dy = calculateDelta( previousTouches, event )
						cx,cy = calculateCenter( previousTouches, event )
					end

					if dx and dy then
						local newDistance = math.sqrt( dx*dx + dy*dy )
						local scale = newDistance / self.distance

						if scale > 0 then
							self.xScale = self.xScaleOriginal * scale
							self.yScale = self.yScaleOriginal * scale

							-- Make object move while scaling
							self.x = cx - ( self.x0 * scale )
							self.y = cy - ( self.y0 * scale )
						end
					end
				else
					if event.id == self.firstTouch.id then
						-- don't move unless this is the first touch id.
						-- Make object move (we subtract self.x0, self.y0 so that moves are
						-- relative to initial grab point, rather than object "snapping").
						-- TODO: we need to constrain the x and y to prevent the image move from exceeding display bounds!
						self.x = event.x - self.x0
						self.y = event.y - self.y0
					end
				end

				if event.id == self.firstTouch.id then
					self.firstTouch = event
				end

				if not previousTouches[event.id] then
					self.numPreviousTouches = self.numPreviousTouches + 1
				end
				previousTouches[event.id] = event

			elseif "ended" == phase or "cancelled" == phase then
				-- check for taps
				local dx = math.abs( event.xStart - event.x )
				local dy = math.abs( event.yStart - event.y )
				if eventTime - previousTouches[event.id].time < 150 and dx < 10 and dy < 10 then
					if not self.tapTime then
						-- single tap
						self.tapTime = eventTime
						self.tapDelay = timer.performWithDelay( 300, function() self.tapTime = nil end )
					elseif eventTime - self.tapTime < 300 then
						-- double tap
						timer.cancel( self.tapDelay )
						self.tapTime = nil
						if self.xScale == self.xScaleStart and self.yScale == self.yScaleStart then
							-- when double tap increases scale, scale goes to 2x
							transition.to( self, { time=300, transition=easing.inOutQuad, xScale=self.xScale*2, yScale=self.yScale*2, x=event.x - self.x0*2, y=event.y - self.y0*2 } )
						else
							local factor = self.xScaleStart / self.xScale
							-- alternatively double tap reduces image back to original 1x scale
							transition.to( self, { time=300, transition=easing.inOutQuad, xScale=self.xScaleStart, yScale=self.yScaleStart, x=event.x - self.x0*factor, y=event.y - self.y0*factor } )
						end
					end
				end

				--
				if previousTouches[event.id] then
					self.numPreviousTouches = self.numPreviousTouches - 1
					previousTouches[event.id] = nil
				end

				if self.numPreviousTouches == 1 then
					-- must be at least 2 touches remaining to pinch/zoom
					self.distance = nil
					-- reset initial position
					local id,touch = next( previousTouches )
					self.x0 = touch.x - self.x
					self.y0 = touch.y - self.y
					self.firstTouch = touch

				elseif self.numPreviousTouches == 0 then
					-- previousTouches is empty so no more fingers are touching the screen
					-- Allow touch events to be sent normally to the objects they "hit"
					display.getCurrentStage():setFocus( nil )
					self.isFocus = false
					self.distance = nil
					self.xScaleOriginal = nil
					self.yScaleOriginal = nil

					-- reset array
					self.previousTouches = nil
					self.numPreviousTouches = nil
				end
			end
		end

		return true
	end

	-- bgGroup:addEventListener('touch', bgGroup);

	-- setup any overlays needed
	local bgOverlayGroup = display.newGroup();
	bgOverlayGroup.anchorChildren = false;
	bgOverlayGroup.anchorX = 0.5;
	bgOverlayGroup.anchorY = 0.5;

	-- set up the background
	local bgImage = display.newImageRect(imageBase .. 'GENU_Home_LandingPage_Background.png', 1152, 768);
	bgGroup:insert(bgImage);
	-- bgImage.alpha = 0;
	FRC_Layout.scaleToFit(bgImage);
	bgImage.x, bgImage.y = 0, 0;

	-- transArray[ #transArray + 1 ] = transition.to( bgImage, { delay = 0, time = 300, alpha = 1, transition = easing.inOutQuad});
	-- setup the logo animation
	local bgLogo = display.newImageRect(imageBase .. 'GENU_Home_LandingPage_Logo.png', 1152, 768);
	bgOverlayGroup:insert(bgLogo);

	bgLogo.xScale = 0.001;
	bgLogo.yScale = 0.001;
	bgLogo.rotation = math.random(-45, 45);
	local rotation = bgLogo.rotation * 0.25;

	--[[
	-- set up the book logo
	local bookLogo = display.newImageRect(imageBase .. 'GENU_LandingPage_TitleSpaced.png', 1152, 768);
	bgOverlayGroup:insert(bookLogo);
	bookLogo.alpha = 0;

	 transArray[ #transArray + 1 ] = transition.to( bgLogo, { delay = 0, time = 200, y = -120, rotation = rotation, xScale = 1.25, yScale = 1.25, transition = easing.inOutQuad, onComplete = function()
		transArray[ #transArray + 1  ] = transition.to( bgLogo, { time = 200, rotation = 0, xScale = .75, yScale = .75, transition = easing.inExpo, onComplete = function()
			transArray[ #transArray + 1  ] = transition.to( bgLogo, { time = 200, alpha = 0, transition = easing.inExpo });
			transArray[ #transArray + 1  ] = transition.to( bookLogo, { delay = 400, time = 200, alpha = 1, transition = easing.inExpo,
			onComplete = function()
				transArray[ #transArray + 1  ] = transition.to( bookLogo, { delay = 200, time = 200, alpha = 0, transition = easing.inExpo })
				end })
		end })
	end
 })
--]]

	-- lay in all of the map overlay buttons
	local fisheryButton = ui.button.new({
		imageUp = imageBase .. 'GENU_LandingPage_NavigationButton_TheFishery_up.png',
		imageDown = imageBase .. 'GENU_LandingPage_NavigationButton_TheFishery_down.png',
		width = 434,
		height = 179,
		x = 576 - 576;
		y = 154 - 384;
		onRelease = function()
			if scene.buttonIsActive then return; end
			scene.removeControls();
			scene.stopThemeMusic();
			storyboard.gotoScene('Scenes.Fishery');
		end
	});
	fisheryButton.anchorX = 0.5;
	fisheryButton.anchorY = 0.5;
	-- create and assign the mask
	local fisheryButtonMask = graphics.newMask(imageBase .. 'GENU_LandingPage_NavigationButton_TheFishery_mask.png');
	fisheryButton:setMask(fisheryButtonMask);
	bgGroup:insert(fisheryButton);

	local makeryButton = ui.button.new({
		imageUp = imageBase .. 'GENU_LandingPage_NavigationButton_TheMakery_up.png',
		imageDown = imageBase .. 'GENU_LandingPage_NavigationButton_TheMakery_down.png',
		width = 359,
		height = 221,
		x = 335 - 576;
		y = 176 - 384;
		onRelease = function()
			if scene.buttonIsActive then return; end
			scene.removeControls();
			scene.stopThemeMusic();
			storyboard.gotoScene('Scenes.Makery');
		end
	});
	makeryButton.anchorX = 0.5;
	makeryButton.anchorY = 0.5;
	-- create and assign the mask
	local makeryButtonMask = graphics.newMask(imageBase .. 'GENU_LandingPage_NavigationButton_TheMakery_mask.png');
	makeryButton:setMask(makeryButtonMask);
	bgGroup:insert(makeryButton);

	local sugaryButton = ui.button.new({
		imageUp = imageBase .. 'GENU_LandingPage_NavigationButton_TheSugary_up.png',
		imageDown = imageBase .. 'GENU_LandingPage_NavigationButton_TheSugary_down.png',
		width = 328,
		height = 239,
		x = 223 - 576;
		y = 295 - 384;
		onRelease = function()
			if scene.buttonIsActive then return; end
			scene.removeControls();
			scene.stopThemeMusic();
			storyboard.gotoScene('Scenes.Sugary');
		end
	});
	sugaryButton.anchorX = 0.5;
	sugaryButton.anchorY = 0.5;
	-- create and assign the mask
	local sugaryButtonMask = graphics.newMask(imageBase .. 'GENU_LandingPage_NavigationButton_TheSugary_mask.png');
	sugaryButton:setMask(sugaryButtonMask);
	bgGroup:insert(sugaryButton);

	local puzzlesButton = ui.button.new({
		imageUp = imageBase .. 'GENU_LandingPage_NavigationButton_Puzzles_up.png',
		imageDown = imageBase .. 'GENU_LandingPage_NavigationButton_Puzzles_down.png',
		width = 163,
		height = 107,
		x = 661 - 576;
		y = 292 - 384;
		onRelease = function()
			if scene.buttonIsActive then return; end
			scene.removeControls();
			if (not _G.ANDROID_DEVICE) then native.setActivityIndicator(true); end
			storyboard.gotoScene('Scenes.JigsawPuzzle', { effect="crossFade", time="250" });
		end
	});
	puzzlesButton.anchorX = 0.5;
	puzzlesButton.anchorY = 0.5;
	-- create and assign the mask
	local puzzlesButtonMask = graphics.newMask(imageBase .. 'GENU_LandingPage_NavigationButton_Puzzles_mask.png');
	puzzlesButton:setMask(puzzlesButtonMask);
	bgGroup:insert(puzzlesButton);

	local tasteeTownButton = ui.button.new({
		imageUp = imageBase .. 'GENU_LandingPage_NavigationButton_TasteeTown_up.png',
		imageDown = imageBase .. 'GENU_LandingPage_NavigationButton_TasteeTown_down.png',
		width = 232,
		height = 130,
		x = 813 - 576;
		y = 339 - 384;
		onRelease = function()
			if scene.buttonIsActive then return; end
			scene.removeControls();
			scene.stopThemeMusic();
			storyboard.gotoScene('Scenes.TasteeTown');
		end
	});
	tasteeTownButton.anchorX = 0.5;
	tasteeTownButton.anchorY = 0.5;
	-- create and assign the mask
	local tasteeTownButtonMask = graphics.newMask(imageBase .. 'GENU_LandingPage_NavigationButton_TasteeTown_mask.png');
	tasteeTownButton:setMask(tasteeTownButtonMask);
	bgGroup:insert(tasteeTownButton);

	local braineryButton = ui.button.new({
		imageUp = imageBase .. 'GENU_LandingPage_NavigationButton_Brainery_up.png',
		imageDown = imageBase .. 'GENU_LandingPage_NavigationButton_Brainery_down.png',
		width = 294,
		height = 200,
		x = 893 - 576;
		y = 260 - 384;
		onRelease = function()
			if scene.buttonIsActive then return; end
			scene.removeControls();
			scene.stopThemeMusic();
			storyboard.gotoScene('Scenes.Brainery');
		end
	});
	braineryButton.anchorX = 0.5;
	braineryButton.anchorY = 0.5;
	-- create and assign the mask
	local braineryButtonMask = graphics.newMask(imageBase .. 'GENU_LandingPage_NavigationButton_Brainery_mask.png');
	braineryButton:setMask(braineryButtonMask);
	bgGroup:insert(braineryButton);

	local recipesButton = ui.button.new({
		imageUp = imageBase .. 'GENU_LandingPage_NavigationButton_Recipes_up.png',
		imageDown = imageBase .. 'GENU_LandingPage_NavigationButton_Recipes_down.png',
		width = 181,
		height = 129,
		x = 574 - 576;
		y = 417 - 384;
		onRelease = function()
			if scene.buttonIsActive then return; end
			scene.removeControls();
			local screenRect = display.newRect(0, 0, screenW, screenH);
			screenRect.x = display.contentCenterX;
			screenRect.y = display.contentCenterY;
			screenRect:setFillColor(0, 0, 0, 0.75);
			screenRect:addEventListener('touch', function() return true; end);
			screenRect:addEventListener('tap', function() return true; end);

			local webView = native.newWebView(0, 0, screenW - 100, screenH - 55);
			webView.x = display.contentCenterX;
			webView.y = display.contentCenterY + 20;
			webView:request("Help/GENU_FRC_WebOverlay_Recipes.html", system.DocumentsDirectory);

			local closeButton = ui.button.new({
				imageUp = imageBase .. 'GENU_Home_global_LandingPage_CloseButton.png',
				imageDown = imageBase .. 'GENU_Home_global_LandingPage_CloseButton.png',
				width = 50,
				height = 50,
				onRelease = function(event)
					local self = event.target;
					webView:removeSelf(); webView = nil;
					self:removeSelf(); closeButton = nil;
					screenRect:removeSelf(); screenRect = nil;
				end
			});
			closeButton.x = 5 + (closeButton.contentWidth * 0.5) - ((screenW - display.contentWidth) * 0.5);
			closeButton.y = 5 + (closeButton.contentHeight * 0.5) - ((screenH - display.contentHeight) * 0.5);
			webView.closeButton = closeButton;
		end
	});
	recipesButton.anchorX = 0.5;
	recipesButton.anchorY = 0.5;
	-- create and assign the mask
	local recipesButtonMask = graphics.newMask(imageBase .. 'GENU_LandingPage_NavigationButton_Recipes_mask.png');
	recipesButton:setMask(recipesButtonMask);
	bgGroup:insert(recipesButton);

	local mainBuildingButton = ui.button.new({
		imageUp = imageBase .. 'GENU_LandingPage_NavigationButton_MainBuilding_up.png',
		imageDown = imageBase .. 'GENU_LandingPage_NavigationButton_MainBuilding_down.png',
		width = 283,
		height = 125,
		x = 348 - 576;
		y = 453 - 384;
		onRelease = function()
			if scene.buttonIsActive then return; end
			scene.removeControls();
			scene.stopThemeMusic();
			storyboard.gotoScene('Scenes.MainBuilding', { effect="crossFade", time="250" });
		end
	});
	mainBuildingButton.anchorX = 0.5;
	mainBuildingButton.anchorY = 0.5;
	-- create and assign the mask
	local mainBuildingButtonMask = graphics.newMask(imageBase .. 'GENU_LandingPage_NavigationButton_MainBuilding_mask.png');
	mainBuildingButton:setMask(mainBuildingButtonMask);
	bgGroup:insert(mainBuildingButton);

	local bodinatorButton = ui.button.new({
		imageUp = imageBase .. 'GENU_LandingPage_NavigationButton_Bodinator_up.png',
		imageDown = imageBase .. 'GENU_LandingPage_NavigationButton_Bodinator_down.png',
		width = 141,
		height = 93,
		x = 549 - 576;
		y = 470 - 384;
		onRelease = function()
			if scene.buttonIsActive then return; end
			scene.removeControls();
			-- scene.stopThemeMusic();
			storyboard.gotoScene('Scenes.Bodinator', { effect="crossFade", time="250" });
		end
	});
	bodinatorButton.anchorX = 0.5;
	bodinatorButton.anchorY = 0.5;
	-- create and assign the mask
	local bodinatorButtonMask = graphics.newMask(imageBase .. 'GENU_LandingPage_NavigationButton_Bodinator_mask.png');
	bodinatorButton:setMask(bodinatorButtonMask);
	bgGroup:insert(bodinatorButton);

	local memoryGameButton = ui.button.new({
		imageUp = imageBase .. 'GENU_LandingPage_NavigationButton_Concentration_up.png',
		imageDown = imageBase .. 'GENU_LandingPage_NavigationButton_Concentration_down.png',
		width = 241,
		height = 101,
		x = 810 - 576;
		y = 505 - 384;
		onRelease = function()
			if scene.buttonIsActive then return; end
			scene.removeControls();
			if (not _G.ANDROID_DEVICE) then native.setActivityIndicator(true); end
			storyboard.gotoScene('Scenes.MemoryGame', { effect="crossFade", time="250" });
		end
	});
	memoryGameButton.anchorX = 0.5;
	memoryGameButton.anchorY = 0.5;
	-- create and assign the mask
	local memoryGameButtonMask = graphics.newMask(imageBase .. 'GENU_LandingPage_NavigationButton_Concentration_mask.png');
	memoryGameButton:setMask(memoryGameButtonMask);
	bgGroup:insert(memoryGameButton);

	local artDepartmentButton = ui.button.new({
		imageUp = imageBase .. 'GENU_LandingPage_NavigationButton_ArtDepartment_up.png',
		imageDown = imageBase .. 'GENU_LandingPage_NavigationButton_ArtDepartment_down.png',
		width = 235,
		height = 110,
		x = 608 - 576;
		y = 596 - 384;
		onRelease = function()
			if scene.buttonIsActive then return; end
			scene.removeControls();
			if (not _G.ANDROID_DEVICE) then native.setActivityIndicator(true); end
			timer.performWithDelay(600, function() storyboard.gotoScene('Scenes.ArtCenter'); end, 1);
		end
	});
	artDepartmentButton.anchorX = 0.5;
	artDepartmentButton.anchorY = 0.5;
	-- create and assign the mask
	local artDepartmentButtonMask = graphics.newMask(imageBase .. 'GENU_LandingPage_NavigationButton_ArtDepartment_mask.png');
	artDepartmentButton:setMask(artDepartmentButtonMask);
	bgGroup:insert(artDepartmentButton);

	-- position background image at correct location
	bgGroup.x = display.contentCenterX;
	bgGroup.y = display.contentCenterY;
	view:insert(bgGroup);

	-- position background image at correct location
	bgOverlayGroup.x = display.contentCenterX;
	bgOverlayGroup.y = display.contentCenterY;
	view:insert(bgOverlayGroup);

	--if (not buildText) then
		local buildText = display.newEmbossedText(view, FRC_AppSettings.get("version") .. ' (' .. system.getInfo('build') .. ')', 0, 0, native.systemFontBold, 11);
		buildText:setFillColor(1, 1, 1);
		buildText.anchorX = 1.0;
		buildText.anchorY = 1.0;
		buildText.x = screenW - ((screenW - display.contentWidth) * 0.5) - 5;
		buildText.y = screenH - ((screenH - display.contentHeight) * 0.5); -- - 7;
	--end
	--]]

	--[[

	-- setup array of animation sequences
	local titleAnimationFiles = {
		"Macho_Cheer_Loop.xml"
	};
	-- preload the animation data (XML and images) early
	titleAnimationSequences = FRC_AnimationManager.createAnimationClipGroup(titleAnimationFiles, animationXMLBase, animationImageBase);
	FRC_Layout.scaleToFit(titleAnimationSequences, 400, -100);
	-- titleAnimationSequences.y = titleAnimationSequences.y + bg.contentBounds.yMin;
	view:insert(titleAnimationSequences);
--]]

	-- create action bar menu at top left corner of screen
	scene.actionBarMenu = FRC_ActionBar.new({
		parent = view,
		imageUp = 'FRC_Assets/FRC_ActionBar/Images/GENU_ActionBar_global_Button_ActionBar_up.png',
		imageDown = 'FRC_Assets/FRC_ActionBar/Images/GENU_ActionBar_global_Button_ActionBar_down.png',
		focusState = 'FRC_Assets/FRC_ActionBar/Images/GENU_ActionBar_global_Button_ActionBar_focused.png',
		disabled = 'FRC_Assets/FRC_ActionBar/Images/GENU_ActionBar_global_Button_ActionBar_disabled.png',
		buttonWidth = 100,
		buttonHeight = 100,
		buttonPadding = 15,
		alwaysVisible = true,
		bgColor = { 1, 1, 1, .95 },
		buttons = {
			{
				imageUp = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_Discover_up.png',
				imageDown = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_Discover_down.png',
				onRelease = function(e)
					local screenRect = display.newRect(0, 0, screenW, screenH);
					screenRect.x = display.contentCenterX;
					screenRect.y = display.contentCenterY;
					screenRect:setFillColor(0, 0, 0, 0.75);
					screenRect:addEventListener('touch', function() return true; end);
					screenRect:addEventListener('tap', function() return true; end);

					local webView = native.newWebView(0, 0, screenW - 100, screenH - 55);
					webView.x = display.contentCenterX;
					webView.y = display.contentCenterY + 20;
					local devicePlatformName = import("platform").detected;
					webView:request("http://genuwinhealth.com/?p=" .. devicePlatformName);

					local closeButton = ui.button.new({
						imageUp = imageBase .. 'GENU_Home_global_LandingPage_CloseButton.png',
						imageDown = imageBase .. 'GENU_Home_global_LandingPage_CloseButton.png',
						width = 50,
						height = 50,
						onRelease = function(event)
							local self = event.target;
							webView:removeSelf(); webView = nil;
							self:removeSelf(); closeButton = nil;
							screenRect:removeSelf(); screenRect = nil;
						end
					});
					closeButton.x = 5 + (closeButton.contentWidth * 0.5) - ((screenW - display.contentWidth) * 0.5);
					closeButton.y = 5 + (closeButton.contentHeight * 0.5) - ((screenH - display.contentHeight) * 0.5);
					webView.closeButton = closeButton;
				end
			},
			{
				imageUp = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_FRC_down.png',
				imageDown = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_FRC_up.png',
				onRelease = function(e)
					local screenRect = display.newRect(0, 0, screenW, screenH);
					screenRect.x = display.contentCenterX;
					screenRect.y = display.contentCenterY;
					screenRect:setFillColor(0, 0, 0, 0.75);
					screenRect:addEventListener('touch', function() return true; end);
					screenRect:addEventListener('tap', function() return true; end);

					local webView = native.newWebView(0, 0, screenW - 100, screenH - 55);
					webView.x = display.contentCenterX;
					webView.y = display.contentCenterY + 20;
					local devicePlatformName = import("platform").detected;
					webView:request("http://fatredcouch.com/page.php?t=products&p=" .. devicePlatformName);

					local closeButton = ui.button.new({
						imageUp = imageBase .. 'GENU_Home_global_LandingPage_CloseButton.png',
						imageDown = imageBase .. 'GENU_Home_global_LandingPage_CloseButton.png',
						width = 50,
						height = 50,
						onRelease = function(event)
							local self = event.target;
							webView:removeSelf(); webView = nil;
							self:removeSelf(); closeButton = nil;
							screenRect:removeSelf(); screenRect = nil;
						end
					});
					closeButton.x = 5 + (closeButton.contentWidth * 0.5) - ((screenW - display.contentWidth) * 0.5);
					closeButton.y = 5 + (closeButton.contentHeight * 0.5) - ((screenH - display.contentHeight) * 0.5);
					webView.closeButton = closeButton;
				end
			},
			{
				imageUp = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_About_up.png',
				imageDown = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_About_down.png',
				onRelease = function(e)
					local screenRect = display.newRect(0, 0, screenW, screenH);
					screenRect.x = display.contentCenterX;
					screenRect.y = display.contentCenterY;
					screenRect:setFillColor(0, 0, 0, 0.75);
					screenRect:addEventListener('touch', function() return true; end);
					screenRect:addEventListener('tap', function() return true; end);

					local webView = native.newWebView(0, 0, screenW - 100, screenH - 55);
					webView.x = display.contentCenterX;
					webView.y = display.contentCenterY + 20;
					local devicePlatformName = import("platform").detected;
					webView:request("Help/GENU_FRC_WebOverlay_Learn_Credits.html", system.DocumentsDirectory);

					local closeButton = ui.button.new({
						imageUp = imageBase .. 'GENU_Home_global_LandingPage_CloseButton.png',
						imageDown = imageBase .. 'GENU_Home_global_LandingPage_CloseButton.png',
						width = 50,
						height = 50,
						onRelease = function(event)
							local self = event.target;
							webView:removeSelf(); webView = nil;
							self:removeSelf(); closeButton = nil;
							screenRect:removeSelf(); screenRect = nil;
						end
					});
					closeButton.x = 5 + (closeButton.contentWidth * 0.5) - ((screenW - display.contentWidth) * 0.5);
					closeButton.y = 5 + (closeButton.contentHeight * 0.5) - ((screenH - display.contentHeight) * 0.5);
					webView.closeButton = closeButton;
				end
			},
			{
				imageUp = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_Help_up.png',
				imageDown = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_Help_down.png',
				onRelease = function()
					local screenRect = display.newRect(0, 0, screenW, screenH);
					screenRect.x = display.contentCenterX;
					screenRect.y = display.contentCenterY;
					screenRect:setFillColor(0, 0, 0, 0.75);
					screenRect:addEventListener('touch', function() return true; end);
					screenRect:addEventListener('tap', function() return true; end);
					local webView = native.newWebView(0, 0, screenW - 100, screenH - 55);
					webView.x = display.contentCenterX;
					webView.y = display.contentCenterY + 20;
					webView:request("Help/GENU_FRC_WebOverlay_Help_Main.html", system.DocumentsDirectory);

					local closeButton = ui.button.new({
						imageUp = imageBase .. 'GENU_Home_global_LandingPage_CloseButton.png',
						imageDown = imageBase .. 'GENU_Home_global_LandingPage_CloseButton.png',
						width = 50,
						height = 50,
						onRelease = function(event)
							local self = event.target;
							webView:removeSelf(); webView = nil;
							self:removeSelf();
							screenRect:removeSelf(); screenRect = nil;
						end
					});
					closeButton.x = 5 + (closeButton.contentWidth * 0.5) - ((screenW - display.contentWidth) * 0.5);
					closeButton.y = 5 + (closeButton.contentHeight * 0.5) - ((screenH - display.contentHeight) * 0.5);
					webView.closeButton = closeButton;
				end
			}
		}
	});

	-- create settings bar menu at top left corner of screen
	local musicButtonFocused = false;
	-- DEBUG:
	print("INIT ambientSoundOn: ", FRC_AppSettings.get("ambientSoundOn"));
	if (FRC_AppSettings.get("ambientSoundOn")) then musicButtonFocused = true; end
	scene.settingsBarMenu = FRC_SettingsBar.new({
		parent = view,
		imageUp = 'FRC_Assets/FRC_SettingsBar/Images/FRC_Settings_Icon_Settings_up.png',
		imageDown = 'FRC_Assets/FRC_SettingsBar/Images/FRC_Settings_Icon_Settings_down.png',
		focusState = 'FRC_Assets/FRC_SettingsBar/Images/FRC_Settings_Icon_Settings_focused.png',
		disabled = 'FRC_Assets/FRC_SettingsBar/Images/FRC_Settings_Icon_Settings_disabled.png',
		buttonWidth = 100,
		buttonHeight = 100,
		buttonPadding = 15,
alwaysVisible = true,
		bgColor = { 1, 1, 1, .95 },
		buttons = {
			{
				imageUp = 'FRC_Assets/FRC_SettingsBar/Images/FRC_Settings_Icon_SoundMusic_up.png',
				imageDown = 'FRC_Assets/FRC_SettingsBar/Images/FRC_Settings_Icon_SoundMusic_up.png',
				focusState = 'FRC_Assets/FRC_SettingsBar/Images/FRC_Settings_Icon_SoundMusic_focused.png',
				isFocused = musicButtonFocused,
				onPress = function(event)
					local self = event.target;
					if (FRC_AppSettings.get("ambientSoundOn")) then
						self:setFocusState(false);
						FRC_AppSettings.set("ambientSoundOn", false);
						local ambientMusic = FRC_AudioManager:findGroup("ambientMusic");
						if ambientMusic then
							ambientMusic:pause();
						end
					else
						self:setFocusState(true);
						FRC_AppSettings.set("ambientSoundOn", true);
						local ambientMusic = FRC_AudioManager:findGroup("ambientMusic");
						if ambientMusic then
							-- find the current theme music
							local themeMusic = ambientMusic:findHandle(scene.currentThemeMusic);
							if (themeMusic and themeMusic:isPlaying()) then
							  ambientMusic:resume();
						  else
								scene.playTheme1();
							end
						end
					end
				end
			}
		}
	});

end

function scene.enterScene(self, event)
	local scene = self;
	local view = scene.view;

	-- now let's animate everything!
	-- this should only happen the first time that the application is launched
	if (FRC_AppSettings.get("freshLaunch")) then
		if titleAnimationSequences then
			for i=1, titleAnimationSequences.numChildren do
				titleAnimationSequences[i]:play({
					showLastFrame = false,
					playBackward = false,
					autoLoop = true,
					palindromicLoop = false,
					delay = 3,
					intervalTime = 30,
					maxIterations = 1,
					onCompletion = function ()
						-- after the title animation, we will play the introduction sequences only
						-- ambientAnimationSequences[i]:play({autoLoop = true, intervalTime = 30});
					end
				});
			end
		end
	else

	end

	local ambientMusic = FRC_AudioManager:findGroup("ambientMusic");
  if (FRC_AppSettings.get("freshLaunch")) then
		FRC_AppSettings.set("freshLaunch", false);
		-- setup a delay for device playback
		if (system.getInfo("environment") == "simulator") then
			-- DEBUG:
			print("freshLaunch playing TitleAudio");
			-- DEBUG:
			print("ambientSoundOn: ",  FRC_AppSettings.get("ambientSoundOn"));
			scene.currentThemeMusic = "TitleAudio";
			ambientMusic:play("TitleAudio", { onComplete = function()
					scene.playTheme1();
				end, 1 } );
			if (not FRC_AppSettings.get("ambientSoundOn")) then
				-- DEBUG:
				print("ambientMusic:pause");
				timer.performWithDelay(1, function()
					ambientMusic:pause();
				end, 1);
			end
		else
			timer.performWithDelay(1000, function()
				scene.currentThemeMusic = "TitleAudio";
				ambientMusic:play("TitleAudio", { onComplete = function()
						scene.playTheme1();
					end } );
				if (not FRC_AppSettings.get("ambientSoundOn")) then
					-- DEBUG:
					print("ambientMusic:pause");
					timer.performWithDelay(1, function()
						ambientMusic:pause();
					end, 1);
				end
			end, 1);
		end

		-- set the volume to 1 just after starting up playback to avoid the "pop" heard when
		-- starting playback and then pausing it
		ambientMusic:setVolume(1.0);
	else
		-- DEBUG:
		print("HOME scene background audio");
		if (ambientMusic) then
			-- resume the background theme song that was playing when we left the Home scene
			if (not FRC_AppSettings.get("ambientSoundOn")) then
				-- DEBUG:
				print("ambientMusic:pause");
				timer.performWithDelay(1, function()
					ambientMusic:pause();
					end, 1);
			else
				-- DEBUG:
				print("HOME scene RESUME background audio");
				scene.playTheme1();
				-- ambientMusic:resume("UofChewTheme1");
				--[[ -- check to make sure that there was audio to resume
				timer.performWithDelay(100, function()
					if not ambientMusic:isPlaying() then
						ambientMusic:resume("UofChewTheme1");
					end
					end, 1);
				--]]
			end
		else
			-- fallback to restarting one of the background theme songs
			scene.playTheme1();
		end
	end

	-- show "Rate It" dialog
	-- TODO:  we need to move this so it doesn't happen until the user returns BACK to the Home scene from another scene
	require("FRC_Modules.FRC_Ratings.FRC_Ratings").ask();
end

function scene.exitScene(self, event)
	-- we need to clear the animations from the screen
	if (titleAnimationSequences) then
		for i=1, titleAnimationSequences.numChildren do
			local anim = titleAnimationSequences[i];
			if (anim) then
				-- if (anim.isPlaying) then
					anim.dispose();
				-- end
				-- anim.remove();
			end
		end
		titleAnimationSequences = nil;
	end
	if (ambientAnimationSequences) then
		for i=1, ambientAnimationSequences.numChildren do
			local anim = ambientAnimationSequences[i];
			if (anim) then
				-- if (anim.isPlaying) then
					anim.dispose();
				-- end
				-- anim.remove();
			end
		end
		ambientAnimationSequences = nil;
	end
	ui:dispose();
end

function scene.didExitScene(self, event)
	local scene = self;
	scene.buttonIsActive = false;
	scene.actionBarMenu:dispose();
	scene.actionBarMenu = nil;
	scene.settingsBarMenu:dispose();
	scene.settingsBarMenu = nil;
end

scene:addEventListener('createScene');
scene:addEventListener('enterScene');
scene:addEventListener('exitScene');
scene:addEventListener('didExitScene');

return scene;
