local FRC_Layout = require('FRC_Modules.FRC_Layout.FRC_Layout');
-- local FRC_UI = require('FRC_Modules.FRC_UI.FRC_UI');
local ui = require('ui');
local settings = require('FRC_Modules.FRC_StorybookSceneSelector.FRC_StorybookSceneSelector_Settings');

local FRC_StorybookSceneSelector = {};

FRC_StorybookSceneSelector.new = function(options)
	options = options or {};
	-- DEBUG:
	print("FRC_StorybookSceneSelector baseDir: ", options.baseDir);

	local group = display.newGroup();

	local cancelTouch = function(e)
		if (e.phase == 'began') then group:dispose(); end
		return true;
	end

	local screenW, screenH = FRC_Layout.getScreenDimensions();
	local dimRect = display.newRect(group, 0, 0, screenW, screenH);
	dimRect:setFillColor(0, 0, 0, 0.5);
	dimRect:addEventListener('touch', cancelTouch);
	dimRect:addEventListener('tap', cancelTouch);

	local popupWidth = options.width or settings.DEFAULTS.POPUP_WIDTH;
	local popupHeight = options.height or settings.DEFAULTS.POPUP_HEIGHT;
	local popup = ui.pagecontainer.new({
		width = popupWidth,
		height = popupHeight
	});
	group:insert(popup);
	popup.x, popup.y = 0, 0;
	group.popup = popup;

	local pages = {};
	pages[1] = popup:addPage();
	pages[2] = popup:addPage();
	pages[3] = popup:addPage();

	pages[1].thumbGroup = display.newGroup(); pages[1]:insert(pages[1].thumbGroup);
	pages[1].thumbGroup.anchorChildren = true;
	pages[2].thumbGroup = display.newGroup(); pages[2]:insert(pages[2].thumbGroup);
	pages[2].thumbGroup.anchorChildren = true;
	pages[3].thumbGroup = display.newGroup(); pages[3]:insert(pages[3].thumbGroup);
	pages[3].thumbGroup.anchorChildren = true;

	local thumbImage, baseDirectory, thumbWidth, thumbHeight, thumbSubtitle;
	thumbWidth = settings.DEFAULTS.BLANK_SLOT_WIDTH;
	thumbHeight = settings.DEFAULTS.BLANK_SLOT_HEIGHT;
	local largestThumbWidth = thumbWidth;
	local largestThumbHeight = thumbHeight;

	local j = 1;
	local removeIndexes = {};
	for i=1,#pages do
		local x, y = 0, 0;
		local max = 0; --settings.UI.PER_PAGE_ROWS * settings.UI.PER_PAGE_COLS;
		if (options.data) then
			max = #options.data;
		end

		local blankCount = 0;
		local totalThumbs = settings.DEFAULTS.PER_PAGE_ROWS * settings.DEFAULTS.PER_PAGE_COLS;

		for row=1,settings.DEFAULTS.PER_PAGE_ROWS do
			x = 0;
			for col=1,settings.DEFAULTS.PER_PAGE_COLS do
				local baseDir = system.ResourceDirectory;
				local id = nil;
				local item;
				local newThumbImageUp;
				local specialicon;

				if ((options.data) and (options.data[j])) then
					-- build the selector buttons
					item = options.data[j];
					id = item.id;
					thumbImage = id .. item.thumbSuffix;
					specialicon = item.specialicon;

					-- use the subtitle if provided
					thumbSubtitle = item.subtitle or id;

					-- DEBUG:
					-- print("FRC_StorybookSceneSelector thumbImage: ", thumbImage);
					if (item.thumbWidth > thumbWidth) then
						largestThumbWidth = item.thumbWidth;
					end
					if (item.thumbHeight > thumbHeight) then
						largestThumbHeight = item.thumbHeight;
					end
					thumbWidth = item.thumbWidth;
					thumbHeight = item.thumbHeight;

					-- bookPath .. 'assets/' .. id .. '/' .. id .. '_thumbnail.jpg',
					baseDir = nil;
					newThumbImageUp = options.baseDir .. id .. '/' .. thumbImage;
				else
					id = nil;
					thumbImage = settings.DEFAULTS.BLANK_SLOT_IMAGE;
					if (settings.DEFAULTS.BLANK_SLOT_WIDTH > thumbWidth) then
						largestThumbWidth = settings.DEFAULTS.BLANK_SLOT_WIDTH;
					end
					if (settings.DEFAULTS.BLANK_SLOT_HEIGHT > thumbHeight) then
						largestThumbHeight = settings.DEFAULTS.BLANK_SLOT_HEIGHT;
					end
					thumbWidth = settings.DEFAULTS.BLANK_SLOT_WIDTH;
					thumbHeight = settings.DEFAULTS.BLANK_SLOT_HEIGHT;
					baseDir = system.ResourceDirectory;
					newThumbImageUp = thumbImage;
				end

				-- DEBUG:
				-- print("FRC_StorybookSceneSelector creating thumb: ", id, " ", baseDirectory, " up/down: ", thumbImage, " w: ", thumbWidth, " h: ", thumbHeight);


				local thumbButton = ui.button.new({
					id = id,
					baseDirectory = baseDir,
					imageUp = newThumbImageUp,
					imageDown = newThumbImageUp,
					width = tonumber(thumbWidth),
					height = tonumber(thumbHeight),
					pressAlpha = 0.5,
					onRelease = function(e)
						local self = e.target;
						local function proceedToLoad()
							if (options.callback) then
								options.callback({
									id = self.id,
									page = i,
									row = row,
									column = col,
									data = item
								});
							end
						end
						proceedToLoad();
					end
				});

				thumbButton.parentScrollContainer = popup;
				-- make a container for the thumbButton and the subTitleText
				local thumbGroup = display.newGroup();

				-- identify the current scene
				if (j == options.currentIndex) then
					-- for now we'll just dim it
					-- thumbButton.alpha = 0.5;
					local thumbHighlight = display.newRect(thumbGroup, 0, 0, thumbWidth + 6, thumbHeight + 6);
					thumbHighlight.x = 0;
					thumbHighlight.y = 0;
					thumbHighlight:setFillColor(1, 0, 0, 1);
				end

				thumbGroup:insert(thumbButton);
				-- pages[i].thumbGroup:insert(thumbButton);

				-- add a special (e.g. pawsforthought) icon to the right of the subtitle
				if (specialicon and options.specialicon) then
					local icon = display.newImageRect(thumbGroup, options.specialicon, 32,32);
					-- if the icon image is available... display it
					if (icon) then
						icon.anchorX, icon.anchorY = 0.5, 0.5;
						icon.x = (thumbButton.width * 0.5) - (icon.width * 0.5);
						icon.y = (thumbButton.height * 0.5) - (icon.height * 0.5); -- + (icon.contentHeight * 0.5) + 3;
						icon.rotation = -25;
					else
						print("WARNING:  Missing special icon: ", options.specialicon);
					end
				end
				-- add a subtitle if requested
				if (options.showSubtitles) then
					local subtitleWidth = thumbWidth;
					local subTitleText = display.newText({
						parent = thumbGroup,
						text = tostring(j) .. ": " .. thumbSubtitle, -- tonumber(id), -- "Scene Thumbnail Subtitle", -- tostring(tonumber(id)),
						-- x = 0,
						-- y = 0,
						font = native.systemFontBold,
						fontSize = settings.DEFAULTS.SUBTITLE_FONTSIZE,
						width = subtitleWidth,
						align = "center"
					});
					subTitleText:setFillColor(0, 0, 0, 1.0);
					subTitleText.anchorX, subTitleText.anchorY = 0.5, 0.5;
					-- thumbGroup:insert(subTitleText);
					subTitleText.x = 0; -- (thumbButton.width * 0.5); -- - (subTitleText.contentWidth * 0.5);
					subTitleText.y = (thumbButton.height * 0.5) + (subTitleText.contentHeight * 0.5) + 3;
					-- DEBUG:
					-- print("subtitle: ", thumbSubtitle);

					-- subTitleText:toFront();
				end

				--thumbButton.x = x;
				--thumbButton.y = y;
				pages[i].thumbGroup:insert(thumbGroup);
				thumbGroup.x = x;
				thumbGroup.y = y;

				-- if there's no id and we are supposed to show a blank, do so
				if ((not id) and (options.hideBlank)) then
					thumbGroup.isVisible = false;
					blankCount = blankCount + 1;
				end

				x = x + largestThumbWidth + 6 + settings.DEFAULTS.THUMBNAIL_SPACING;
				j = j + 1;
			end
			y = y + largestThumbHeight + 6 + settings.DEFAULTS.THUMBNAIL_SPACING;
		end
		pages[i].thumbGroup.x = 0;
		pages[i].thumbGroup.y = settings.DEFAULTS.THUMBNAIL_SPACING * 0.5;

		if ((options.hideBlank) and (blankCount >= totalThumbs)) then
			table.insert(removeIndexes, i);
		end
	end

	if (#removeIndexes > 0) then
		for i=#removeIndexes,1,-1 do
			popup:removePage(removeIndexes[i]);
		end
	end

	group.dispose = FRC_StorybookSceneSelector.dispose;

	if (options.title) then
		local titleText = display.newText(popup, options.title, 0, 0, native.systemFontBold, 36);
		titleText:setFillColor(0, 0, 0, 1.0);
		titleText.x = 0;
		titleText.y = -(popup.height * 0.5) + (titleText.contentHeight * 0.5) + (settings.DEFAULTS.THUMBNAIL_SPACING);
	end

	if (options.parent) then options.parent:insert(group); end
	group.x, group.y = display.contentCenterX, display.contentCenterY;

	-- scroll the container to the page containing the current scene
	local pageNum = math.ceil(options.currentIndex / (settings.DEFAULTS.PER_PAGE_ROWS * settings.DEFAULTS.PER_PAGE_COLS));
	if (pageNum > 1) then
		popup:gotoPage(pageNum);
	end

	return group;
end

FRC_StorybookSceneSelector.dispose = function(self)
	self.popup:dispose();
	if (self.removeSelf) then self:removeSelf(); end
end

return FRC_StorybookSceneSelector;
