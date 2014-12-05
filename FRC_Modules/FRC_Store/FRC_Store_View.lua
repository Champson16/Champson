local FRC_Store = require("FRC_Modules.FRC_Store.FRC_Store");
local FRC_DataLib = require("FRC_Modules.FRC_DataLib.FRC_DataLib");
local FRC_Store_Settings = FRC_DataLib.readJSON("FRC_Assets/FRC_Store/Data/FRC_Store_Settings.json");
local FRC_Layout = require('FRC_Modules.FRC_Layout.FRC_Layout');
local ui = require("ui");
local json = require "json";
local FRC_Store_View = {};
FRC_Store_View.isVisible = false;

local screenPadding = 60;
local borderSize = 12;
local elementPadding = 12;

local ANDROID_DEVICE = (system.getInfo("platformName") == "Android");
local NOOK_DEVICE = (system.getInfo("targetAppStore") == "nook");
local KINDLE_DEVICE = (system.getInfo("targetAppStore") == "amazon");
if ((NOOK_DEVICE) or (KINDLE_DEVICE)) then
  ANDROID_DEVICE = true;
end

local function createHeaderFooterContent(parent)
	-- create header
	local headerWidth = parent.winWidth;
	local headerHeight = FRC_Store_Settings.headerImageHeight;
	local header = display.newContainer(headerWidth, headerHeight);
	header.x = 0;
	header.y = -(parent.winHeight * 0.5) + (header.height * 0.5);
	parent:insert(header);

	local headerBack = display.newRect(header, 0, 0, headerWidth, headerHeight);
	local hc = FRC_Store_Settings.headerColor;
	headerBack:setFillColor(hc[1], hc[2], hc[3], hc[4]);
	headerBack.x, headerBack.y = 0, 0;

	if (FRC_Store_Settings.headerImagePath ~= "") then
		local headerImg = display.newImageRect(header, FRC_Store_Settings.headerImagePath, FRC_Store_Settings.headerImageWidth, FRC_Store_Settings.headerImageHeight);
		headerImg.x, headerImg.y = 0, 0;
	end
	parent.header = header;

	local unpurchasedCount = #FRC_Store:getIAPProductIds() - #FRC_Store.data.purchased;
	local purchaseAllHidden = false;
	if (unpurchasedCount < 2) then
		purchaseAllHidden = true;
	end

	-- create scrolling container for individual IAPs
	local footerHeight = FRC_Store_Settings.footerHeight or 60;
	local content = ui.newScrollcontainer({
		width = parent.winWidth,
		height = parent.winHeight - headerHeight - footerHeight
	});
	content.bg.isHitTestable = true;
	content.bg.alpha = 0;
	parent:insert(content);
	content.x = 0;
	content.y = -(parent.winHeight * 0.5) + (header.height) + (content.height * 0.5);
	parent.content = content;

	-- create footer
	local footerWidth = headerWidth;
	local footer = display.newContainer(footerWidth, footerHeight);
	footer.x = 0;
	footer.y = (parent.winHeight * 0.5) - (footer.height * 0.5);
	local footerBack = display.newRect(footer, 0, 0, footerWidth, footerHeight);
	local fc = FRC_Store_Settings.footerColor;
	footerBack:setFillColor(fc[1], fc[2], fc[3], fc[4]);
	footerBack.x, footerBack.y = 0, 0;
	parent.footer = footer;
	parent:insert(footer);

	-- create restore all purchases button
	local restoreButton = ui.button.new({
		imageUp = FRC_Store_Settings.restore_up,
		imageDown = FRC_Store_Settings.restore_down,
		disabled = FRC_Store_Settings.restore_disabled,
		width = FRC_Store_Settings.restoreWidth,
		height = FRC_Store_Settings.restoreHeight,
		onRelease = function()
			FRC_Store:restore();
		end
	});
	if (unpurchasedCount < 1) then restoreButton:setDisabledState(true); end
	restoreButton.x = -(footer.width * 0.5) + elementPadding + (restoreButton.contentWidth * 0.5);
	restoreButton.y = 0;
	footer:insert(restoreButton);

	-- close button
	local closeButton = ui.button.new({
		imageUp = FRC_Store_Settings.closeButtonImage,
		imageDown = FRC_Store_Settings.closeButtonImage,
		pressAlpha = 0.75,
		width = FRC_Store_Settings.closeButtonWidth,
		height = FRC_Store_Settings.closeButtonHeight,
		onRelease = function()
			parent:close();
		end
	});
	closeButton.x = -(parent.winWidth * 0.5) - elementPadding + (closeButton.contentWidth * 0.5);
	closeButton.y = -(parent.winHeight * 0.5) - elementPadding + (closeButton.contentHeight * 0.5);
	parent:insert(closeButton);
end

local function newPopup(focusId, focusImage)
	local screenW, screenH = FRC_Layout.getScreenDimensions();
	local view = display.newContainer(screenW, screenH);

	-- create modal window background elements, border, etc.
	local modalBack = display.newRect(view, 0, 0, screenW, screenH);
	modalBack:setFillColor(0, 0, 0, 0);
	modalBack.isHitTestable = true;
	modalBack.x, modalBack.y = 0, 0;
	modalBack.touch = function() return true; end
	modalBack:addEventListener("touch", modalBack.touch);

	local border = display.newRect(view, 0, 0, screenW - screenPadding, screenH - screenPadding);
	border:setFillColor(1.0, 1.0, 1.0, 0.80);
	border.x, border.y = 0, 0;

	local back = display.newRect(view, 0, 0, border.width - (borderSize * 2), border.height - (borderSize * 2));
	back:setFillColor(.188235294, .188235294, .188235294, 1.0);
	back.x, back.y = 0, 0;
	view.winWidth = back.width;
	view.winHeight = back.height;

	-- create the parent UI elements that make up the store experience
	createHeaderFooterContent(view);

	-- get list of sorted products
	local products = FRC_Store:getSortedProductsWithDetails(focusId);
	local context = { x = 0, y = 0 };

	for i=1,#products do
		local p = products[i];
		local id = p.identifier;
		local title = p.title;
		local desc = p.description;
		local image = p.promoImage;
		local pWidth = p.promoWidth;
		local pHeight = p.promoHeight;
		local price = tonumber(p.MSRP);
    local appleDirectURL = p.appleDirectURL;
    local googleDirectURL = p.googleDirectURL;
		local productType = p.productType;
		local thankString = p.newPurchaseMessage;
		local rd = p.releaseDate;
		local g = display.newGroup();

		local leftColumnWidth = pWidth + (elementPadding * 2);
		local rightColumnWidth = FRC_Store_Settings.buyNowWidth + (elementPadding * 2);
		local middleColumnWidth = view.winWidth - leftColumnWidth - rightColumnWidth;

		local promoImage = display.newImageRect(g, "FRC_Assets/FRC_Store/Images/" .. image, pWidth, pHeight);
		promoImage.x = elementPadding + (pWidth * 0.5);
		promoImage.y = elementPadding + (pHeight * 0.5);

		local productTitleFontName = FRC_Store_Settings.productTitleFont;
		if (ANDROID_DEVICE) then productTitleFontName = FRC_Store_Settings.productTitleFont_android; end
		local productTitleText = display.newText({
			parent = g,
			text = title,
			x = 0,
			y = 0,
			width = middleColumnWidth,
			font = productTitleFontName,
			fontSize = FRC_Store_Settings.productTitleFontSize,
			align = "left"
		});
		local pttc = FRC_Store_Settings.productTitleColor;
		productTitleText:setFillColor(pttc[1], pttc[2], pttc[3], pttc[4]);
		productTitleText.anchorX = 0.5;
		productTitleText.anchorY = 0.5;
		productTitleText.x = promoImage.x + (promoImage.contentWidth * 0.5) + elementPadding + (productTitleText.contentWidth * 0.5);
		productTitleText.y = elementPadding + (productTitleText.contentHeight * 0.5);

		local productDescFontName = FRC_Store_Settings.productDescriptionFont;
		if (ANDROID_DEVICE) then productDescFontName = FRC_Store_Settings.productDescriptionFont_android; end
		local productDescText = display.newText({
			parent = g,
			text = desc,
			x = 0,
			y = 0,
			width = middleColumnWidth,
			font = productDescFontName,
			fontSize = FRC_Store_Settings.productDescriptionFontSize,
			align = "left"
		});
		local pdtc = FRC_Store_Settings.productDescriptionColor;
		productDescText:setFillColor(pdtc[1], pdtc[2], pdtc[3], pdtc[4]);
		productDescText.anchorX = 0.5;
		productDescText.anchorY = 0.5;
		productDescText.x = promoImage.x + (promoImage.contentWidth * 0.5) + elementPadding + (productDescText.contentWidth * 0.5);
		productDescText.y = productTitleText.y + (productTitleText.height * 0.5) + elementPadding + (productDescText.contentHeight * 0.5);

		-- check if product is new, if so show orange banner with "NEW" text on it
		local date1 = os.time();
		local date2 = os.time({ year = rd.year, month=rd.month, day=rd.day });
		local difftime = date2 - date1;
		local diff = os.date("*t", difftime);

		-- if product release date is in the future, or if it's less than 90 days in the past...
		if (difftime < 0 or diff.day < 90) then
			local banner = display.newImageRect(g, FRC_Store_Settings.orangeBannerImage, FRC_Store_Settings.orangeBannerWidth, FRC_Store_Settings.orangeBannerHeight);
			banner.x = promoImage.x;
			banner.y = promoImage.y + (promoImage.height * 0.5) + (elementPadding * 2) + (banner.contentHeight * 0.5);

			local newTextFont = FRC_Store_Settings.orangeBannerFont;
			if (ANDROID_DEVICE) then newTextFont = FRC_Store_Settings.orangeBannerFont_android; end
			local newText = display.newText({
				parent = g,
				text = "NEW!",
				x = 0,
				y = 0,
				font = newTextFont,
				fontSize = FRC_Store_Settings.orangeBannerFontSize,
				align = "center"
			});
			local ntc = FRC_Store_Settings.orangeBannerFontColor;
			newText:setFillColor(ntc[1], ntc[2], ntc[3], ntc[4]);
			newText.x = banner.x + FRC_Store_Settings.orangeBannerTextOffsetX;
			newText.y = banner.y + FRC_Store_Settings.orangeBannerTextOffsetY;
		end

		if (focusImage and i == 1) then
			local lockPromo = display.newImage(g, focusImage, true);
			if (lockPromo.contentHeight > lockPromo.contentWidth) then
				local scale = (FRC_Store_Settings.lockedMediaThumbMaxHeight) / lockPromo.contentHeight;
				lockPromo.yScale = scale;
				lockPromo.xScale = scale;
			else
				local scale = (FRC_Store_Settings.lockedMediaThumbMaxWidth) / lockPromo.contentWidth;
				lockPromo.xScale = scale;
				lockPromo.yScale = scale;
			end
			lockPromo.x = promoImage.x + (promoImage.contentWidth * 0.5) + elementPadding + (lockPromo.contentWidth * 0.5);
			lockPromo.y = productDescText.y + (productDescText.contentHeight * 0.5) + (elementPadding * 2) + (lockPromo.contentHeight * 0.5);

			local lockPromoFont = FRC_Store_Settings.lockedMediaFont;
			if (ANDROID_DEVICE) then lockPromoFont = FRC_Store_Settings.lockedMediaFont_android; end
			local lockPromoText = display.newText({
				parent = g,
				text = FRC_Store_Settings.lockedMediaText,
				x = 0,
				y = 0,
				width = middleColumnWidth - lockPromo.contentWidth - (elementPadding * 3),
				font = lockPromoFont,
				fontSize = FRC_Store_Settings.lockedMediaFontSize,
				align="left"
			});
			local lpc = FRC_Store_Settings.lockedMediaFontColor;
			lockPromoText:setFillColor(lpc[1], lpc[2], lpc[3], lpc[4]);
			lockPromoText.x = lockPromo.x + (lockPromo.contentWidth * 0.5) + elementPadding + (lockPromoText.contentWidth * 0.5);
			lockPromoText.y = lockPromo.y;
		end

		if (not p.isPurchased) then
			local buyButton;
      if (p.productType == "direct") then
        buyButton = ui.button.new({
          id = id,
          imageUp = FRC_Store_Settings.buyNow_up,
          imageDown = FRC_Store_Settings.buyNow_down,
          width = FRC_Store_Settings.buyNowWidth,
          height = FRC_Store_Settings.buyNowHeight,
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
            -- DEBUG
            -- native.showAlert("Platform", devicePlatformName);
            local productURL;
            if (devicePlatformName == "apple") then
              productURL = p.appleDirectURL;
            else
              productURL = p.googleDirectURL;
            end
            webView:request(productURL);

            local imageBase = 'FRC_Assets/GENU_Assets/Images/';

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
      else
        buyButton = ui.button.new({
  				id = id,
  				imageUp = FRC_Store_Settings.buyNow_up,
  				imageDown = FRC_Store_Settings.buyNow_down,
  				width = FRC_Store_Settings.buyNowWidth,
  				height = FRC_Store_Settings.buyNowHeight,
  				onRelease = function(e)
  					local self = e.target;
  					FRC_Store:addToCard(self.id);
  					FRC_Store:checkout();
  				end
  			});
      end
			g:insert(buyButton);
			buyButton.x = productDescText.x + (productDescText.contentWidth * 0.5) + elementPadding + (buyButton.contentWidth * 0.5);
			buyButton.y = (g.contentHeight * 0.5) - elementPadding;

			local priceFont = FRC_Store_Settings.priceFont;
			if (ANDROID_DEVICE) then priceFont = FRC_Store_Settings.priceFont_android; end

			local priceText = display.newText({
				parent = g,
				text = "For only $" .. p.MSRP,
				x = 0,
				y = 0,
				font = priceFont,
				fontSize = FRC_Store_Settings.priceFontSize,
				align = "left"
			});
			local pc = FRC_Store_Settings.priceColor;
			priceText:setFillColor(pc[1], pc[2], pc[3], pc[4]);
			priceText.anchorX = 0.5;
			priceText.anchorY = 0.5;
			priceText.x = buyButton.x;
			priceText.y = buyButton.y + (buyButton.contentHeight * 0.5) + elementPadding + (priceText.contentHeight * 0.5);
		else
			local purchaseIndicator = display.newImageRect(g, FRC_Store_Settings.purchasedImage, FRC_Store_Settings.purchasedWidth, FRC_Store_Settings.purchasedHeight);
			purchaseIndicator.x = productDescText.x + (productDescText.contentWidth * 0.5) + elementPadding + (purchaseIndicator.contentWidth * 0.5);
			purchaseIndicator.y = (g.contentHeight * 0.5) - elementPadding;

			-- create a grey rect to cover entire entry
			local disabledRect = display.newRect(g, 0, 0, view.winWidth, g.contentHeight + (elementPadding * 2));
			disabledRect:setFillColor(0.5, 0.5, 0.5, 0.35);
			disabledRect.x = view.winWidth * 0.5;
			disabledRect.y = disabledRect.contentHeight * 0.5;
			purchaseIndicator:toFront();
		end

		view.content:insert(g);
		g.x = -(view.winWidth * 0.5) + context.x;
		g.y = g.y - (view.content.height * 0.5) + context.y; -- + (g.contentHeight * 0.5); -- elementPadding;
		context.y = context.x + g.contentHeight;
	end

	local function onPurchase(event)
		local data = FRC_Store:getDataForSingleProduct(event.product);
		if (data.newPurchaseMessage) then
			native.showAlert("Purchase Successful", data.newPurchaseMessage, { "OK" });
			view:close();
		end
	end
	FRC_Store:addEventListener('purchased', onPurchase);

	local function onRestore(event)
		native.showAlert("Restore Successful", "Your previously purchased items have been restored.", { "OK" });
		view:close();
	end
	FRC_Store:addEventListener('restored', onRestore);

	function view:close()
		FRC_Store:removeEventListener('purchased', onPurchase);
		FRC_Store:removeEventListener('restored', onRestore);

		if (view.content) then
			view.content:dispose();
			view.content = nil;
		end
		if (view.removeSelf) then
			view:removeSelf();
		end
		FRC_Store_View.isVisible = false;
	end

	view.x, view.y = display.contentCenterX, display.contentCenterY;
end

function FRC_Store_View:new(focusId, focusImage)
	if (FRC_Store_View.isVisible) then return; end
	FRC_Store_View.isVisible = true;

	--[[
	local networkError = false;
	network.request("https://itunes.apple.com/search?term=Fat%20Red%20Couch,%20Inc.&country=us&entity=software", "GET", function(event)
		if (event.isError) then
			networkError = true;
			newPopup(self, focusId, focusImage);

		elseif (event.phase == "ended" and not networkError) then
			local response = json.decode(event.response);
			if (response) then
				local results = response.results;
				local found = false;
				local appId = FRC_Store_Settings.appId;
				for i=1,#results do

				end
			else
				newPopup(self, focusId, focusImage);
			end
		end
	end);
	--]]
	newPopup(focusId, focusImage);
end

return FRC_Store_View;
