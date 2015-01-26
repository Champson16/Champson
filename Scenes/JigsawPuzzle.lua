--local ui = require('FRC_Modules.FRC_UI.FRC_UI');
ui = require('ui');
local storyboard = require('storyboard');
local FRC_ActionBar = require('FRC_Modules.FRC_ActionBar.FRC_ActionBar');
local FRC_SettingsBar = require('FRC_Modules.FRC_SettingsBar.FRC_SettingsBar');
local FRC_JigsawPuzzle = require('FRC_Modules.FRC_JigsawPuzzle.FRC_JigsawPuzzle');
local FRC_JigsawPuzzle_Settings = require('FRC_Modules.FRC_JigsawPuzzle.FRC_JigsawPuzzle_Settings');
local FRC_Layout = require('FRC_Modules.FRC_Layout.FRC_Layout');
local FRC_AudioManager = require('FRC_Modules.FRC_AudioManager.FRC_AudioManager');
local FRC_AppSettings = require('FRC_Modules.FRC_AppSettings.FRC_AppSettings');


local scene = storyboard.newScene();
local timerVisible = true;
local previewVisible = true;

local imageBase = 'FRC_Assets/GENU_Assets/Images/';

function scene.createScene(self, event)
	--local self = event.target;
	local view = self.view;
	view.timerVisible = timerVisible;
	view.previewVisible = previewVisible;

	display.setDrawMode("forceRender"); --, false);

	local screenW, screenH = FRC_Layout.getScreenDimensions();
	local bg = display.newImageRect(view, FRC_JigsawPuzzle_Settings.UI.SCENE_BACKGROUND, FRC_JigsawPuzzle_Settings.UI.SCENE_BACKGROUND_WIDTH, FRC_JigsawPuzzle_Settings.UI.SCENE_BACKGROUND_HEIGHT);
	local xScale = screenW / bg.contentWidth;
	local yScale = screenH / bg.contentHeight;
	if (xScale > yScale) then
		bg.xScale = xScale;
		bg.yScale = xScale;
	else
		bg.xScale = yScale;
		bg.yScale = yScale;
	end

	bg.x = display.contentCenterX;
	bg.y = display.contentCenterY;

	view.optionScreen = FRC_JigsawPuzzle.showOptionScreen(view, function()
		-- This function is called when user completes the puzzle
		FRC_AudioManager:findGroup("puzzle_encouragements"):playRandom({ onComplete=function()
			timer.performWithDelay(800, function()
				storyboard.gotoScene('Scenes.JigsawPuzzle', { useLoader = true });
			end, 1);
		end });
	end);
	view.optionScreen.x = display.contentCenterX; -- -(screenW - display.contentWidth) * 0.5;
	view.optionScreen.y = display.contentCenterY; -- -(screenH - display.contentHeight) * 0.5;
	view.optionScreen:addEventListener('disposed', function(e)
		scene.inPuzzle = true;
		-- This re-enables the Options button in the ActionBar
		self.actionBarMenu.menuItems[3]:setDisabledState(false);
		-- This re-enables the Startover button in the ActionBar
		self.actionBarMenu.menuItems[5]:setDisabledState(false);
	end);

	local function goHome()
		if (scene.inPuzzle) then
			local function onAlertCallback(event)
				if (event.index == 2) then
					storyboard.gotoScene('Scenes.Home');
				end
			end
			native.showAlert("U of Chew", "Are you sure you want to leave the puzzle?", { "No", "Yes" }, onAlertCallback)
		else
			storyboard.gotoScene('Scenes.Home');
		end
	end
	scene.backHandler = goHome;

	-- create action bar menu at top left corner of screen
	self.actionBarMenu = FRC_ActionBar.new({
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
				imageUp = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_Home_up.png',
				imageDown = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_Home_down.png',
				onRelease = function()
					goHome();
				end
			},
			{
				imageUp = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_Options_up.png',
				imageDown = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_Options_down.png',
				disabled = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_Options_disabled.png',
				isDisabled = true,
				onRelease = function()
					local function onAlertCallback(event)
						if (event.index == 2) then
							storyboard.gotoScene('Scenes.JigsawPuzzle', { useLoader = true });
						end
					end
					native.showAlert("Leave the Puzzle?", "You will lose your progress on the current puzzle.", { "No", "Yes" }, onAlertCallback)
				end
			},
			{
				imageUp = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_FRC_down.png',
				imageDown = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_FRC_up.png',
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
				imageUp = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_StartOver_up.png',
				imageDown = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_StartOver_down.png',
				disabled = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_StartOver_disabled.png',
				isDisabled = true,
				onRelease = function()
					local function onAlertCallback(event)
						local puzzle = view.puzzle;
						if (not puzzle) then return; end
						if (event.index == 2) then
							-- restart current puzzle
							if ((puzzle.matchedPieces) and (#puzzle.matchedPieces > 0)) then
								for i=1,#puzzle.matchedPieces do
									local piece = puzzle.matchedPieces[i];
									piece.strokeWidth = 2;
									piece:setStrokeColor(0, 0, 0, 0.35);

									-- scatter the piece
									local rot = 0;
									if (piece.parent.randomRotation) then
										rot = FRC_JigsawPuzzle.choose(0, 90, 180, 270, -90, -180, -270);
									end
									transition.to(piece, { time=1000, x=piece.scatterX, y=piece.scatterY, rotation=rot, transition=easing.inOutExpo, onComplete=function()
										piece.isMovable = true;
									end });
								end
							end

							puzzle.totalMatches = 0;
							puzzle.matchedPieces = {};

							-- reset the timer
							puzzle.seconds = 0;
							puzzle.minutes = 0;
							puzzle.hours = 0;
							puzzle.ms = 0;
							puzzle.ss = 0;
							puzzle.markTime = system.getTimer();

						end
					end
					native.showAlert("Restart Puzzle?", "You will lose your progress on the current puzzle.", { "NO", "YES" }, onAlertCallback)
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
					webView:request("Help/GENU_FRC_WebOverlay_Help_JigsawPuzzles.html", system.DocumentsDirectory);

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
	self.settingsBarMenu = FRC_SettingsBar.new({
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
				imageUp = 'FRC_Assets/FRC_SettingsBar/Images/FRC_Settings_Icon_Timer_up.png',
				imageDown = 'FRC_Assets/FRC_SettingsBar/Images/FRC_Settings_Icon_Timer_up.png',
				focusState = 'FRC_Assets/FRC_SettingsBar/Images/FRC_Settings_Icon_Timer_focused.png',
				disabled = 'FRC_Assets/FRC_SettingsBar/Images/FRC_Settings_Icon_Timer_disabled.png',
				isDisabled = false,
				isFocused = timerVisible,
				onPress = function(event)
					local scene = self;
					local self = event.target;
					if (self.isDisabled) then return; end
					if ((not view.puzzle) or (not view.puzzle.timerText)) then return; end

					if (view.puzzle.timerText.isVisible) then
						self:setFocusState(false);
						view.puzzle.timerText.isVisible = false;
						timerVisible = false;
					else
						self:setFocusState(true);
						view.puzzle.timerText.isVisible = true;
						timerVisible = true;
					end
				end
			},
			{
				imageUp = 'FRC_Assets/FRC_SettingsBar/Images/FRC_Settings_Icon_PuzzlePreview_up.png',
				imageDown = 'FRC_Assets/FRC_SettingsBar/Images/FRC_Settings_Icon_PuzzlePreview_up.png',
				focusState = 'FRC_Assets/FRC_SettingsBar/Images/FRC_Settings_Icon_PuzzlePreview_focused.png',
				isFocused = previewVisible,
				onPress = function(event)
					local scene = self;
					local self = event.target;
					if (not view.puzzle) then print('no puzzle'); return; end
					if (view.puzzle.bg.isVisible) then
						self:setFocusState(false);
						view.puzzle.bg.isVisible = false;
						previewVisible = false;
					else
						self:setFocusState(true);
						view.puzzle.bg.isVisible = true;
						previewVisible = true;
					end
				end
			},
			{
				imageUp = 'FRC_Assets/FRC_SettingsBar/Images/FRC_Settings_Icon_SoundMusic_up.png',
				imageDown = 'FRC_Assets/FRC_SettingsBar/Images/FRC_Settings_Icon_SoundMusic_up.png',
				focusState = 'FRC_Assets/FRC_SettingsBar/Images/FRC_Settings_Icon_SoundMusic_focused.png',
				isFocused = FRC_AppSettings.get("ambientSoundOn"),
				onPress = function(event)
					local self = event.target;
					if (FRC_AppSettings.get("ambientSoundOn")) then
						self:setFocusState(false);
						FRC_AppSettings.set("ambientSoundOn", false);
						FRC_AudioManager:findGroup("ambientMusic"):pause();
					else
						self:setFocusState(true);
						FRC_AppSettings.set("ambientSoundOn", true);
						FRC_AudioManager:findGroup("ambientMusic"):resume();
					end
				end
			}
		}
	});

	view:insert(1, self.settingsBarMenu.menuActivator);
	view:insert(1, self.actionBarMenu.menuActivator);
end

function scene.enterScene(self, event)
	local view = self.view;
	self.inPuzzle = false;
	native.setActivityIndicator(false);
end

function scene.exitScene(self, event)
	if (self.view.optionScreen) then
		self.view.optionScreen:dispose();
		self.view.optionScreen = nil;
	end

	if (self.view.puzzle) then
		self.view.puzzle:dispose();
		self.view.puzzle = nil;
	end

	ui:dispose();
end

function scene.didExitScene(self, event)
	display.setDrawMode("default"); -- display.setDrawMode("forceRender", false);
	local view = self.view;

	self.actionBarMenu:dispose();
	self.actionBarMenu = nil;

	self.settingsBarMenu:dispose();
	self.settingsBarMenu = nil;
end

scene:addEventListener('createScene');
scene:addEventListener('enterScene');
scene:addEventListener('exitScene');
scene:addEventListener('didExitScene');

return scene;
