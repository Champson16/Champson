--local ui = require('FRC_Modules.FRC_UI.FRC_UI');
local ui = require('ui')
local FRC_DataLib = require('FRC_Modules.FRC_DataLib.FRC_DataLib');
local FRC_JigsawPuzzle_Settings = require('FRC_Modules.FRC_JigsawPuzzle.FRC_JigsawPuzzle_Settings');
local FRC_JigsawPuzzle = require('FRC_Modules.FRC_JigsawPuzzle.FRC_JigsawPuzzle');
local FRC_Layout = require('FRC_Modules.FRC_Layout.FRC_Layout');
local FRC_JigsawPuzzle_OptionScreen = {};
local math_floor = math.floor;
local math_abs = math.abs;
local FRC_ArtCenter;
local artCenterLoaded = pcall(function()
	FRC_ArtCenter = require('FRC_Modules.FRC_ArtCenter.FRC_ArtCenter');
end);

local lastSelectedPuzzle = 1;
local lastSelectedSize = 2;
local lastRotationSetting = false;

FRC_JigsawPuzzle_OptionScreen.new = function(parent, onCompleteCallback)
	local screenW, screenH = display.contentWidth, display.contentHeight; --FRC_Layout.getScreenDimensions();
	local group = display.newContainer(screenW, screenH);
	group.anchorChildren = false;
	local elementPadding = 12;
	local puzzleImagePath = FRC_JigsawPuzzle_Settings.UI.IMAGE_PATH;
	local thumbnailSuffix = '_thumbnail';
	local puzzlePreview = nil;
	local previewHeight = 415;
	local puzzlePreviewX = nil;
	local puzzlePreviewY = nil;
	local selectedEffectIndex = 1;
	local imageSelector, sizeSlider, sizeSliderText, rotationToggle, fxHeader, fxSelector;

	local puzzleJSON = FRC_DataLib.readJSON(FRC_JigsawPuzzle_Settings.DATA.PUZZLES);
	local puzzleSizes = puzzleJSON.sizes;
	local puzzleData = puzzleJSON.puzzles;
	local userImagesIndex = nil;
	local systemImagesIndex = 1;

	if (artCenterLoaded) then
		FRC_ArtCenter.getSavedData();
		if ((FRC_ArtCenter.savedData) and (#FRC_ArtCenter.savedData.savedItems > 0)) then
			systemImagesIndex = #FRC_ArtCenter.savedData.savedItems + 1;
			userImagesIndex = 1; --#puzzleData + 1;
			for i=#FRC_ArtCenter.savedData.savedItems,1,-1 do
				local item = FRC_ArtCenter.savedData.savedItems[i];
				table.insert(puzzleData, 1, {
					image = item.id,
					width = item.fullWidth,
					height = item.fullHeight,
					ext = 'jpg',
					baseDirectory = 'DocumentsDirectory'
				});
			end
		end
	end

	local imageSelectorWidth = (screenW * 0.95);
	local userImagesButton, systemImagesButton;

	if (userImagesIndex) then
		userImagesButton = ui.button.new({
			imageUp = puzzleImagePath .. puzzleJSON.userImagesButtonImage,
			imageDown = puzzleImagePath .. puzzleJSON.userImagesButtonImage,
			width = puzzleJSON.userImagesButtonWidth,
			height = puzzleJSON.userImagesButtonHeight,
			pressAlpha = 0.5,
			onRelease = function()
				--local x = imageSelector.content[userImagesIndex*2].startX - (imageSelector.leftPadding * 0.5) - (imageSelector.content[2].startX);
				local x = imageSelector.content[userImagesIndex*2].startX;
				imageSelector:scrollToX(-x);
			end
		});
		userImagesButton.y = -(screenH * 0.5) + 75 + (userImagesButton.contentHeight * 0.5);

		systemImagesButton = ui.button.new({
			imageUp = puzzleImagePath .. puzzleJSON.systemImagesButtonImage,
			imageDown = puzzleImagePath .. puzzleJSON.systemImagesButtonImage,
			width = puzzleJSON.systemImagesButtonWidth,
			height = puzzleJSON.systemImagesButtonHeight,
			pressAlpha = 0.5,
			onRelease = function()
				local x = imageSelector.content[systemImagesIndex*2].startX; --(imageSelector.leftPadding * 0.5) - (imageSelector.content[1].x);
				imageSelector:scrollToX(-x - (imageSelector.contentWidth * 0.5) + (imageSelector.content[systemImagesIndex*2].contentWidth * 0.5) + elementPadding);
			end
		});
		systemImagesButton.y = userImagesButton.y + systemImagesButton.contentHeight + 10;

		imageSelectorWidth = imageSelectorWidth - userImagesButton.contentWidth - (elementPadding * 4) - ((screenW - (screenW * 0.95)) * 0.5);
	end

	imageSelector = ui.scrollcontainer.new({
		width = imageSelectorWidth,
		height = 125,
		xScroll = true,
		yScroll = false;
		leftPadding = elementPadding,
		rightPadding = elementPadding,
		bgColor = { 0, 0, 0, 0.25 },
		borderWidth = 0
	});
	group:insert(imageSelector);
	if (userImagesButton) then
		group:insert(userImagesButton);
		group:insert(systemImagesButton);
		userImagesButton.x = -((screenW * 0.95) * 0.5) + (userImagesButton.contentWidth) - elementPadding;
		systemImagesButton.x = userImagesButton.x;
		imageSelector.x = userImagesButton.contentWidth - elementPadding * 2;
	end

	imageSelector.y = -(screenH * 0.5) + (imageSelector.contentHeight * 0.5) + 75;

	-- create thumbnail buttons for each all of the thumbnails
	local x = -(imageSelector.contentWidth * 0.5);
	for i=1,#puzzleData do
		local thumbHeight = FRC_JigsawPuzzle_Settings.UI.THUMBNAIL_HEIGHT;
		local thumbWidth = (puzzleData[i].width / puzzleData[i].height) * thumbHeight;
		local image = puzzleImagePath .. puzzleData[i].image .. thumbnailSuffix .. '.' .. puzzleData[i].ext;
		if (puzzleData[i].baseDirectory) then
			image = puzzleData[i].image .. thumbnailSuffix .. '.' .. puzzleData[i].ext;
		end

		local thumb = ui.button.new({
			id = i,
			imageUp = image,
			imageDown = image,
			width = thumbWidth,
			height = thumbHeight,
			baseDirectory = system[puzzleData[i].baseDirectory] or system.ResourceDirectory,
			pressAlpha = 0.5,
			parentScrollContainer = imageSelector,
			onRelease = function(e)
				local self = e.target;
				lastSelectedPuzzle = self.id;

				-- show this puzzle as selected
				for i=1,imageSelector.content.numChildren do
					if (imageSelector.content[i] ~= self) then
						if (imageSelector.content[i].selection) then
							imageSelector.content[i].selection.isVisible = false;
						end
					else
						self.selection.isVisible = true;
					end
				end

				-- replace puzzle preview's background
				if (puzzlePreview.effectTimer) then timer.cancel(puzzlePreview.effectTimer); puzzlePreview.effectTimer = nil; end
				puzzlePreview:dispose();
				local previewWidth = (puzzleData[lastSelectedPuzzle].width / puzzleData[lastSelectedPuzzle].height) * previewHeight;
				puzzlePreview = FRC_JigsawPuzzle.newPreview(lastSelectedPuzzle, puzzleSizes[lastSelectedSize].columns, puzzleSizes[lastSelectedSize].rows, previewWidth, previewHeight, puzzleData);
				group:insert(puzzlePreview);
				puzzlePreview.x = -(screenW * 0.5) + (puzzlePreview.contentWidth * 0.5) + (screenW * 0.025);
				puzzlePreview.y = puzzlePreviewY;

				if (fxSelector) then
					local xShift = ((imageSelector.contentBounds.xMax - puzzlePreview.contentBounds.xMin) - (fxSelector.contentWidth) - (puzzlePreview.contentWidth)) * 0.5;
					puzzlePreview.x = puzzlePreview.x + xShift;
					sizeSlider.x = puzzlePreview.x;
					sizeSliderText.x = sizeSlider.x - (sizeSlider.contentWidth * 0.5) - (sizeSliderText.contentWidth * 0.5) - elementPadding;
					rotationToggle.x = sizeSlider.x;

					if ((puzzlePreview.contentBounds.xMax + elementPadding) > fxSelector.contentBounds.xMin) then
						local xShift = -((puzzlePreview.contentBounds.xMax + elementPadding) - fxSelector.contentBounds.xMin);
						puzzlePreview.x = puzzlePreview.x + xShift;
						sizeSlider.x = puzzlePreview.x;
						sizeSliderText.x = sizeSlider.x - (sizeSlider.contentWidth * 0.5) - (sizeSliderText.contentWidth * 0.5) - elementPadding;
						rotationToggle.x = sizeSlider.x;
					end
				end
				puzzlePreviewX = puzzlePreview.x;
				puzzlePreviewY = puzzlePreview.y;
			end
		});
		if (puzzleData[i].baseDirectory) then
			thumb.baseDirectory = puzzleData[i].baseDirectory;
		end

		thumb.selection = display.newRect(0, 0, thumb.contentWidth + 6, thumb.contentHeight + 6);
		thumb.selection:setFillColor(1.0, 1.0, 1.0, 1.0);

		imageSelector:insert(thumb.selection);
		imageSelector:insert(thumb);
		x = x + (thumb.contentWidth * 0.5) + (elementPadding * 0.5);
		thumb.x = x;
		thumb.startX = x;
		x = x + (thumb.contentWidth * 0.5) + (elementPadding * 0.5);
		thumb.selection.x = thumb.x;
		thumb.selection.y = thumb.y;

		if (lastSelectedPuzzle == i) then
			thumb.selection.isVisible = true;
		else
			thumb.selection.isVisible = false;
		end
	end

	local previewWidth = (puzzleData[lastSelectedPuzzle].width / puzzleData[lastSelectedPuzzle].height) * previewHeight;
	puzzlePreview = FRC_JigsawPuzzle.newPreview(lastSelectedPuzzle, puzzleSizes[lastSelectedSize].columns, puzzleSizes[lastSelectedSize].rows, previewWidth, previewHeight, puzzleData);
	group:insert(puzzlePreview);
	puzzlePreview.x = -(screenW * 0.5) + (puzzlePreview.contentWidth * 0.5) + (screenW * 0.025);
	puzzlePreview.y = (puzzlePreview.contentHeight * 0.5) + imageSelector.contentBounds.yMax + elementPadding;
	puzzlePreviewX = puzzlePreview.x;
	puzzlePreviewY = puzzlePreview.y;

	sizeSlider = ui.slider.new({
		width = 472,
		min = 0,
		max = 100,
		startValue = (lastSelectedSize * (100 / #puzzleSizes)) - ((100 / #puzzleSizes) * 0.5),
		sliderColor = { 0, 0, 0, 0.25 },
		handleColor = { .309803922, .552941176, .352941176, 1.0 }
	});

	if (lastSelectedSize == 1) then
		sizeSlider:setValue(0);
	elseif (lastSelectedSize == #puzzleSizes) then
		sizeSlider:setValue(100);
	end

	sizeSlider.handle:setStrokeColor(0, 0, 0, 1.0);
	sizeSlider.handle.strokeWidth = 2;
	group:insert(sizeSlider);
	sizeSlider.x = puzzlePreview.x;
	sizeSlider.y = puzzlePreview.contentBounds.yMax + (sizeSlider.contentHeight * 0.5) + elementPadding;
	sizeSlider:addEventListener("change", function(e)
		local value = math_floor(e.value);
		local lowestNumber = 1000;
		local closestValue;

		for i=1,#puzzleSizes do
			local notch = (i / (#puzzleSizes+1)) * 100;
			local diff = math_abs(notch - value);
			if (diff < lowestNumber) then
				lowestNumber = diff;
				closestValue = i;
			end
		end

		if (closestValue ~= lastSelectedSize) then
			lastSelectedSize = closestValue;

			-- regenerate puzzle preview to reflect the changes
			puzzlePreview:regenerate(puzzleSizes[lastSelectedSize].columns, puzzleSizes[lastSelectedSize].rows);
		end
	end);

	sizeSlider:addEventListener("touchEnded", function(e)
		if (lastSelectedSize == 1) then
			sizeSlider:setValue(0);
		elseif (lastSelectedSize == #puzzleSizes) then
			sizeSlider:setValue(100);
		else
			sizeSlider:setValue((lastSelectedSize * (100 / #puzzleSizes)) - ((100 / #puzzleSizes) * 0.5));
		end
	end);

	sizeSliderText = display.newText(group, 'Pieces', 0, 0, "FunnyBoneJF", 30);
	sizeSliderText:setFillColor(1, 1, 1, 1.0);
	sizeSliderText.y = sizeSlider.y - 7;

	rotationToggle = ui.button.new({
		imageUp = FRC_JigsawPuzzle_Settings.UI.IMAGE_PATH .. FRC_JigsawPuzzle_Settings.UI.TAP_TO_ROTATE_OFF_IMAGE,
		imageDown = FRC_JigsawPuzzle_Settings.UI.IMAGE_PATH .. FRC_JigsawPuzzle_Settings.UI.TAP_TO_ROTATE_OFF_IMAGE,
		focusState = FRC_JigsawPuzzle_Settings.UI.IMAGE_PATH .. FRC_JigsawPuzzle_Settings.UI.TAP_TO_ROTATE_ON_IMAGE,
		width = FRC_JigsawPuzzle_Settings.UI.TAP_TO_ROTATE_WIDTH,
		height = FRC_JigsawPuzzle_Settings.UI.TAP_TO_ROTATE_HEIGHT,
		onPress = function(e)
			local self = e.target;
			if (self.focused) then
				lastRotationSetting = false;
			else
				lastRotationSetting = true;
				self.down.isVisible = false;
			end
			self:setFocusState(lastRotationSetting);
		end,
		onRelease = function(e)
			local self = e.target;
			if (self.focused) then
				self.up.isVisible = false;
			else
				self.up.isVisible = true;
			end
		end
	});
	rotationToggle:setFocusState(lastRotationSetting);
	rotationToggle.up.isVisible = not lastRotationSetting;
	group:insert(rotationToggle);
	rotationToggle.x = puzzlePreview.x;
	rotationToggle.y = sizeSlider.contentBounds.yMax + (rotationToggle.contentHeight * 0.5) + (elementPadding * 0.5);
	rotationToggle:addEventListener('releaseoutside', function(e)
		local self = e.target;
		if (self.focused) then
			self.up.isVisible = false;
		else
			self.up.isVisible = true;
		end
	end);

	local fxData = puzzleJSON.fxSection;
	if (fxData) then
		if (fxData.headerImage) and (fxData.headerWidth) and (fxData.headerHeight) then
			fxHeader = display.newImageRect(group, FRC_JigsawPuzzle_Settings.UI.IMAGE_PATH .. fxData.headerImage, fxData.headerWidth, fxData.headerHeight);
			fxHeader.x = imageSelector.contentBounds.xMax - (fxHeader.contentWidth * 0.5) - elementPadding;
			fxHeader.y = (fxHeader.contentHeight * 0.5) + imageSelector.contentBounds.yMax + elementPadding;
		end

		if ((fxData.effects) and (#fxData.effects > 0)) then
			fxSelector = ui.scrollcontainer.new({
				width = fxData.effects[1].width + elementPadding,
				height = puzzlePreview.contentHeight + (sizeSlider.contentHeight * 0.5) + (elementPadding * 0.5) - (fxHeader.contentHeight + (elementPadding * 0.5)),
				xScroll = false,
				yScroll = true;
				topPadding = elementPadding,
				bottomPadding = elementPadding,
				bgColor = { 0, 0, 0, 0 },
				borderWidth = 0
			});
			group:insert(fxSelector);
			fxSelector.x = imageSelector.contentBounds.xMax - (fxSelector.contentWidth * 0.5);
			if (fxHeader) then
				fxSelector.y = fxHeader.contentBounds.yMax + (fxSelector.contentHeight * 0.5) + (elementPadding * 0.5);
			else
				fxSelector.y = -(screenH * 0.5) + imageSelector.contentBounds.yMax + elementPadding + (fxSelector.contentHeight * 0.5);
			end

			-- reposition puzzle preview
			local xShift = ((imageSelector.contentBounds.xMax - puzzlePreview.contentBounds.xMin) - (fxSelector.contentWidth) - (puzzlePreview.contentWidth)) * 0.5;
			if (userImagesButton) then
				xShift = ((imageSelector.contentBounds.xMax - userImagesButton.contentBounds.xMin) - (fxSelector.contentWidth) - (puzzlePreview.contentWidth)) * 0.5;
				xShift = xShift + elementPadding * 3;
				fxSelector.x = fxSelector.x + elementPadding;
			end
			puzzlePreview.x = puzzlePreview.x + xShift;
			sizeSlider.x = sizeSlider.x + xShift;
			sizeSliderText.x = sizeSlider.x - (sizeSlider.contentWidth * 0.5) - (sizeSliderText.contentWidth * 0.5) - elementPadding;

			if ((puzzlePreview.contentBounds.xMax + elementPadding) > fxSelector.contentBounds.xMin) then
				local xShift = -((puzzlePreview.contentBounds.xMax + elementPadding) - fxSelector.contentBounds.xMin);
				puzzlePreview.x = puzzlePreview.x + xShift;
				sizeSlider.x = puzzlePreview.x;
				sizeSliderText.x = sizeSlider.x - (sizeSlider.contentWidth * 0.5) - (sizeSliderText.contentWidth * 0.5) - elementPadding;
				rotationToggle.x = sizeSlider.x;
			end

			local y = -(fxSelector.contentHeight * 0.5);
			for i=1,#fxData.effects do
				local fxButton = ui.button.new({
					id = i,
					imageUp = FRC_JigsawPuzzle_Settings.UI.IMAGE_PATH .. fxData.effects[i].image,
					imageDown = FRC_JigsawPuzzle_Settings.UI.IMAGE_PATH .. fxData.effects[i].image,
					width = fxData.effects[i].width,
					height = fxData.effects[i].height,
					pressAlpha = 0.5,
					parentScrollContainer = fxSelector,
					onRelease = function(e)
						local self = e.target;
						selectedEffectIndex = self.id;

						if (puzzlePreview.effectTimer) then timer.cancel(puzzlePreview.effectTimer); puzzlePreview.effectTimer = nil; end
						if (self.filter) then
							puzzlePreview.bg.fill.effect = self.filter;

							local zoomInOut = false;

							if (self.filterProperties) then
								for k,v in pairs(self.filterProperties) do
									if (k ~= "zoomInOut") then
										puzzlePreview.bg.fill.effect[k] = v;
									else
										zoomInOut = true;
									end
								end
							end

							if (zoomInOut) then
								local function onTimerComplete()
									puzzlePreview.bg.fill.effect.numPixels = puzzlePreview.pixelIndex;
									puzzlePreview.pixelIndex = puzzlePreview.pixelIndex + puzzlePreview.pixelMoveDirection;
									if (puzzlePreview.pixelIndex <= 1) then
										puzzlePreview.pixelMoveDirection = 2;
										timer.cancel(puzzlePreview.effectTimer);
										puzzlePreview.effectTimer = timer.performWithDelay(500, function()
											puzzlePreview.effectTimer = timer.performWithDelay(100, onTimerComplete, 0);
										end, 1);
									end
									if (puzzlePreview.pixelIndex >= 30) then
										puzzlePreview.pixelMoveDirection = -2;
									end
								end
								puzzlePreview.pixelIndex = 1;
								puzzlePreview.pixelMoveDirection = 2;
								puzzlePreview.effectTimer = timer.performWithDelay(100, onTimerComplete, 0);
							end
						else
							puzzlePreview.bg.fill.effect = nil;
						end
					end
				});
				fxSelector:insert(fxButton);
				y = y + (fxButton.contentHeight * 0.5) + (elementPadding * 0.5);
				fxButton.y = y;
				y = y + (fxButton.contentHeight * 0.5) + (elementPadding * 0.5);
				fxButton.filter = fxData.effects[i].filter;
				if (fxData.effects[i].filterProperties) then
					fxButton.filterProperties = fxData.effects[i].filterProperties;
				end
			end
		end
	end

	local function onStartButtonRelease(e)
		if (group.puzzleStarted) then return; end
		group.puzzleStarted = true;
		local self = e.target;

		local puzzle;
		if ((puzzleJSON.fxSection) and (puzzleJSON.fxSection.effects[selectedEffectIndex].filter)) then
			puzzle = FRC_JigsawPuzzle.new(lastSelectedPuzzle, puzzlePreview.totalColumns, puzzlePreview.totalRows, puzzlePreview.joinerData, puzzleJSON.fxSection.effects[selectedEffectIndex].filter, puzzleData);
		else
			puzzle = FRC_JigsawPuzzle.new(lastSelectedPuzzle, puzzlePreview.totalColumns, puzzlePreview.totalRows, puzzlePreview.joinerData, nil, puzzleData);
		end
		puzzle.timerText.isVisible = parent.timerVisible;
		puzzle.bg.isVisible = parent.previewVisible;
		group.parent:insert(puzzle); group.parent.puzzle = puzzle;
		puzzle.x = display.contentCenterX;
		puzzle.y = display.contentCenterY;
		puzzle.isVisible = false;
		puzzle:addEventListener('puzzleComplete', onCompleteCallback);

		for i=group.numChildren,1,-1 do
			if (group[i] ~= puzzlePreview) then
				transition.to(group[i], {
					time = 500,
					alpha = 0,
					onComplete = function()
						ui:dispose(group[i]);
					end
				});
			end
		end

		local function hidePreviewBeginRealPuzzle()
			puzzle.alpha = 0; puzzle.isVisible = true;

			puzzle.showTransition = transition.to(puzzle, {
				time = 500,
				alpha = 1.0,
				onComplete = function()
					puzzle.showTransition = nil;

					-- scatter pieces and cleanup all the garbage that was created
					puzzle:scatter(rotationToggle.focused, function()
						group:dispose();
						group = nil;
					end);
				end
			});

			puzzlePreview.fadeOut = transition.to(puzzlePreview, {
				time=499,
				alpha = 0,
				onComplete = function()
					puzzlePreview.fadeOut = nil;
					puzzlePreview:dispose();
					puzzlePreview = nil;
				end
			});
		end

		puzzlePreview.moveScaleTransition = transition.to(puzzlePreview, {
			time = 1000,
			x = 0,
			y = 0,
			xScale = puzzle.contentWidth / puzzlePreview.contentWidth,
			yScale = puzzle.contentWidth / puzzlePreview.contentWidth,
			transition = easing.inOutExpo,
			onComplete = hidePreviewBeginRealPuzzle
		});
	end

	local startButton = ui.button.new({
		imageUp = FRC_JigsawPuzzle_Settings.UI.IMAGE_PATH .. puzzleJSON.startButton_up,
		imageDown = FRC_JigsawPuzzle_Settings.UI.IMAGE_PATH .. puzzleJSON.startButton_down,
		width = puzzleJSON.startButtonWidth,
		height = puzzleJSON.startButtonHeight,
		pressAlpha = 0.5,
		onRelease = onStartButtonRelease
	});
	group:insert(startButton);
	startButton.x = imageSelector.contentBounds.xMax - (startButton.contentWidth * 0.5) - elementPadding;
	if (fxSelector) then
		startButton.y = fxSelector.contentBounds.yMax + (startButton.contentHeight * 0.5) + (elementPadding * 0.25);
	elseif (fxHeader) then
		 startButton.y = fxHeader.contentBounds.yMax + (startButton.contentHeight * 0.5) + (elementPadding * 0.25);
	else
		startButton.y = imageSelector.contentBounds.yMax + (startButton.contentHeight * 0.5) + (elementPadding * 0.25);
	end

	group.dispose = function(self)
		if (self.dispatchEvent) then
			self:dispatchEvent({ name = "disposed"	});
		end
		if (puzzlePreview) then
			puzzlePreview:dispose();
			puzzlePreview = nil;
		end
		if (self.removeSelf) then self:removeSelf(); end
	end

	if (parent) then parent:insert(group); end
	return group;
end

return FRC_JigsawPuzzle_OptionScreen;
