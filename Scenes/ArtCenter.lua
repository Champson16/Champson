local ui = require('FRC_Modules.FRC_UI.FRC_UI');
local FRC_ArtCenter = require('FRC_Modules.FRC_ArtCenter.FRC_ArtCenter');
local FRC_ActionBar = require('FRC_Modules.FRC_ActionBar.FRC_ActionBar');
local FRC_SettingsBar = require('FRC_Modules.FRC_SettingsBar.FRC_SettingsBar');
local FRC_Layout = require('FRC_Modules.FRC_Layout.FRC_Layout');
local FRC_AudioManager = require('FRC_Modules.FRC_AudioManager.FRC_AudioManager');
local FRC_AppSettings = require('FRC_Modules.FRC_AppSettings.FRC_AppSettings');
local FRC_ArtCenter_Settings = require('FRC_Modules.FRC_ArtCenter.FRC_ArtCenter_Settings');
local storyboard = require('storyboard');

local scene = FRC_ArtCenter.newScene({
	--SCENE_BACKGROUND_IMAGE = 'FRC_Assets/FRC_MemoryGame/Images/PUFF_Games_global_LandingPage_Background.jpg',
	SCENE_BACKGROUND_WIDTH = 1152,
	SCENE_BACKGROUND_HEIGHT = 768,
	MENU_SWOOSH_AUDIO = 'FRC_Assets/FRC_ArtCenter/Audio/PUFF_global_ArtCenter_MenuSwoosh.mp3'
});

local imageBase = 'FRC_Assets/GENU_Assets/Images/';

scene.postCreateScene = function(self, event)
	--local self = event.target;
	local view = self.view;
	local screenW, screenH = FRC_Layout.getScreenDimensions();

	local function goHome()
		if (self.canvas.isDirty) then
			native.showAlert('Exit?', 'If you exit, your unsaved progress will be lost.\nIf you want to save first, tap Cancel now and then use the Save feature.', { 'Cancel', 'OK' }, function(event)
				if (event.index == 2) then
					storyboard.gotoScene('Scenes.Home');
				end
			end);
		else
			storyboard.gotoScene('Scenes.Home');
		end
	end
	self.backHandler = goHome; -- attempt to go home if user presses "Back" button on Android

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
			-- SAVE button
			{
				imageUp = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_SaveText_up.png',
				imageDown = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_SaveText_down.png',
				onRelease = function(e)
					self.actionBarMenu:pauseHideTimer();
					self.settingsBarMenu:pauseHideTimer();

					local FRC_GalleryPopup = require('FRC_Modules.FRC_GalleryPopup.FRC_GalleryPopup');
					local galleryPopup;
					galleryPopup = FRC_GalleryPopup.new({
						title = FRC_ArtCenter_Settings.DATA.SAVE_PROMPT,
						hideBlank = false,
						width = screenW * 0.68,
						height = screenH * 0.65,
						data = FRC_ArtCenter.savedData.savedItems,
						callback = function(e)
							self.actionBarMenu:resumeHideTimer();
							self.settingsBarMenu:resumeHideTimer();

							galleryPopup:dispose();
							galleryPopup = nil;
							self.actionBarMenu.isVisible = false;
							self.canvas:save(e.id);
							self.canvas.id = FRC_ArtCenter.generateUniqueIdentifier();
							self.actionBarMenu.menuItems[5]:setDisabledState(false);
							self.canvas.isDirty = false;
							self.actionBarMenu.isVisible = true;
						end
					});

					local this = self;
					galleryPopup:addEventListener("cancelled", function()
						this.actionBarMenu:resumeHideTimer();
						this.settingsBarMenu:resumeHideTimer();
					end);
				end
			},
			-- SAVE TO CAMERA ROLL button (needs icon)
			{
				imageUp = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_Camera_up.png',
				imageDown = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_Camera_down.png',
				onRelease = function(e)
					self.actionBarMenu.isVisible = false; -- hide actionbar so it doesn't end up in the saved drawing
					local FRC_CameraRoll = require('FRC_Modules.FRC_CameraRoll.FRC_CameraRoll');
					FRC_CameraRoll.saveBounds(self.canvas.contentBounds);
					native.showAlert("Drawing Saved!", "Your drawing has been saved to your device photo library. Now you can share it with your family and friends.", { "OK" });
					self.actionBarMenu.isVisible = true; -- re-show actionbar menu
				end
			},
			-- LOAD button
			{
				imageUp = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_LoadText_up.png',
				imageDown = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_LoadText_down.png',
				disabled = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_LoadText_disabled.png',
				isDisabled = (#FRC_ArtCenter.savedData.savedItems < 1),
				onRelease = function(e)
					self.actionBarMenu:pauseHideTimer();
					self.settingsBarMenu:pauseHideTimer();

					local function showLoadPopup()
						local FRC_GalleryPopup = require('FRC_Modules.FRC_GalleryPopup.FRC_GalleryPopup');
						local galleryPopup;
						galleryPopup = FRC_GalleryPopup.new({
							title = FRC_ArtCenter_Settings.DATA.LOAD_PROMPT,
							isLoadPopup = true,
							hideBlank = true,
							width = screenW * 0.68,
							height = screenH * 0.65,
							data = FRC_ArtCenter.savedData.savedItems,
							callback = function(e)
								self.actionBarMenu:resumeHideTimer();
								self.settingsBarMenu:resumeHideTimer();

								galleryPopup:dispose();
								galleryPopup = nil;
								self.canvas:load(e.data);
								self.canvas.isDirty = false;
							end
						});

						local this = self;
						galleryPopup:addEventListener("cancelled", function()
							this.actionBarMenu:resumeHideTimer();
							this.settingsBarMenu:resumeHideTimer();
						end);
					end

					if (not self.canvas.isDirty) then
						showLoadPopup();
					else
						native.showAlert('You have unsaved changes.', 'If you Load, your unsaved progress will be lost.', { "Cancel", "OK" }, function(event)
							if (event.index == 2) then
								showLoadPopup();
							else
								self.actionBarMenu:resumeHideTimer();
								self.settingsBarMenu:resumeHideTimer();
							end
						end);
					end
				end
			},
			{
				imageUp = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_StartOver_up.png',
				imageDown = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_StartOver_down.png',
				onRelease = self.clearCanvas
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
					webView:request("Help/GENU_FRC_WebOverlay_Help_ArtCenter.html", system.DocumentsDirectory);

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
end

return scene;
