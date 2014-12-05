local FRC_DataLib = require('FRC_Modules.FRC_DataLib.FRC_DataLib');
local json = require "json";
local FRC_Store = Runtime._super:new();
local FRC_AppSettings = require('FRC_Modules.FRC_AppSettings.FRC_AppSettings');

FRC_Store.settings = FRC_DataLib.readJSON("FRC_Assets/FRC_Store/Data/FRC_Store_Settings.json") or {};
local saveDataFilename = FRC_Store.settings.saveDataFilename or "FRC_Store_Save.json";
local productDataPath = FRC_Store.settings.productDataPath or "FRC_Assets/FRC_Store/Data/FRC_Store_Products.json";

FRC_Store.data = nil;
FRC_Store.storeName = nil;
FRC_Store.storeData = nil;
FRC_Store.interface = nil;
FRC_Store.cart = {}; -- used to store one or more products for purchase

local function standardTransactionCallback(event)
	local transaction = event.transaction;
	local state = event.transaction.state;
	local store = FRC_Store.interface;
	local id = transaction.productIdentifier;
	local productData = FRC_Store:getDataForSingleProduct(id) or {};

	-- handle restores for "google" since they come through as "purchased" state
	-- check timestamp of product to see if it was > 5 minutes ago (assume restore)

	if (store.availableStores) then
		if (store.availableStores.google and state == "purchased") then
			local timestamp;
			local success = pcall(function() timestamp = FRC_DataLib.makeTimeStamp(transaction.date, "ctime"); end);
			if (timestamp and success and (timestamp + 360) > os.time()) then
				-- Change state to "restored"
				state = "restored";
			end
		end
	end

	local productPurchased = function()
		local result = false;
		local index = 0;
		for i=1,#FRC_Store.data.purchased do
			if (FRC_Store.data.purchased[i] == id) then
				result = true;
				index = i;
				break;
			end
		end
		return result, index;
	end

	if (state == "purchased") then
		if (not productPurchased()) then
			table.insert(FRC_Store.data.purchased, id);
		end

		-- dispatch "purchased" event
		FRC_Store:dispatchEvent({
			name = "purchased",
			target = FRC_Store,
			product = id
		});

	elseif (state == "restored") then
		if (not productPurchased()) then
			table.insert(FRC_Store.data.purchased, id);
		end

		-- dispatch "restored" event
		FRC_Store:dispatchEvent({
			name = "restored",
			target = FRC_Store,
			product = id
		});

	elseif (state == "refunded" or state == "revoked") then
		-- if product was previously marked as "purchased", remove from saved purchases array
		local purchased, index = productPurchased();
		if (purchased) then
			table.remove(FRC_Store.data.purchased, index);
		end

		-- dispatch "refunded" event
		FRC_Store:dispatchEvent({
			name = "refunded",
			target = FRC_Store,
			product = id
		});

	elseif (state == "cancelled") then
		-- dispatch "cancelled" event
		FRC_Store:dispatchEvent({
			name = "cancelled",
			target = FRC_Store,
			product = id
		});

	elseif (state == "failed") then
		native.showAlert("[ERROR] " .. transaction.errorType, transaction.errorString, { "OK" });
		print('Store transaction failed: [' .. transaction.errorType .. '] ' .. transaction.errorString);
	else
		print('unknown event');
	end

	FRC_DataLib.saveTable(FRC_Store.data, saveDataFilename);
	if (not FRC_AppSettings.get("DEBUG_PURCHASES")) then store.finishTransaction(transaction); end
end

function FRC_Store:getDataForSingleProduct(identifier)
	if (not self.storeData) then return; end
	local result = nil;
	for i=1,#self.storeData.products do
		if (self.storeData.products[i].identifier == identifier) then
			result = self.storeData.products[i];
			break;
		end
	end
	return result;
end

function FRC_Store:checkPurchased(identifier)
	local result = false;
	for i=1,#self.data.purchased do
		if (self.data.purchased[i] == identifier) then
			result = true;
			break;
		end
	end
	return result;
end

function FRC_Store:checkout()
	local productList = {};
	for i=1,#self.cart do
		productList[i] = self.cart[i];
	end
	if (not FRC_AppSettings.get("DEBUG_PURCHASES")) then
		self.interface.purchase(productList);
	end

	if (system.getInfo("environment") == "simulator" or FRC_AppSettings.get("DEBUG_PURCHASES")) then
		local simulated_state = "purchased";
		for i=1,#self.cart do
			standardTransactionCallback({
				transaction = {
					state = simulated_state,
					productIdentifier = self.cart[i]
				}
			});
		end
	end
	self:emptyCart();
end

function FRC_Store:restore()
	if (not FRC_AppSettings.get("DEBUG_PURCHASES") and self.interface.restore and type(self.interface.restore) == "function") then
		self.interface.restore();
	end

	if (system.getInfo("environment") == "simulator" or FRC_AppSettings.get("DEBUG_PURCHASES")) then
		local products = self:getProductIds();
		for i=1,#products do
			standardTransactionCallback({
				transaction = {
					state = "restored",
					productIdentifier = products[i]
				}
			});
		end
	end
end

function FRC_Store:addToCard(items)
	if (type(items) == "string") then
		local item = items;
		local exists = false;
		for i=1,#self.cart do
			if (self.cart[i] == item) then
				exists = true;
				break;
			end
		end
		if (exists) then return; end
		table.insert(self.cart, item);

	elseif (type(items) == "table") then
		for i=1,#items do
			local item = items[i];
			local exists = false;
			for i=1,#self.cart do
				if (self.cart[i] == item) then
					exists = true;
					break;
				end
			end
			if (exists) then return; end
			table.insert(self.cart, item);
		end
	end
end

function FRC_Store:removeFromCart(items)
	if (type(items) == "string") then
		for i=1,#self.cart do
			if (self.cart[i] == items) then
				table.remove(self.cart, i);
				break;
			end
		end
	elseif (type(items) == "table") then
		for i=1,#items do
			for j=1,#self.cart do
				if (self.cart[j] == items[i]) then
					table.remove(self.cart, j);
					break;
				end
			end
		end
	end
end

function FRC_Store:emptyCart()
	self.cart = {};
end

function FRC_Store:getProductIds()
	local products = {};
	for i=1,#self.storeData.products do
		table.insert(products, self.storeData.products[i].identifier);
	end
	return products;
end

function FRC_Store:getIAPProductIds()
	local products = {};
	for i=1,#self.storeData.products do
		local product = self.storeData.products[i];
		if (product.productType ~= "direct") then
			table.insert(products, self.storeData.products[i].identifier);
		end
	end
	return products;
end

function FRC_Store:getSortedProductsWithDetails(focusId)
	local purchased = self.data.purchased;
	local products = {};
	local purchasedProducts = {};
	local focusIndex = 0;

	for i=1,#self.storeData.products do
		local product = self.storeData.products[i];
		local isPurchased = false;
		for j=1,#purchased do
			if (purchased[j] == product.identifier) then
				isPurchased = true;
				break;
			end
		end
		if (not isPurchased) then
			if (focusId and product.identifier == focusId) then
				focusIndex = i;
			else
				table.insert(products, product);
			end
		else
			table.insert(purchasedProducts, product);
		end
	end

	-- prepend focused product to the beginning of the array
	if (focusId and focusIndex > 0) then
		table.insert(products, 1, self.storeData.products[focusIndex]);
	end

	-- append purchased products to the end of the list
	for i=1,#purchasedProducts do
		purchasedProducts[i].isPurchased = true;
		table.insert(products, purchasedProducts[i]);
	end

	return products;
end

function FRC_Store:init()
	if (self.initialized) then return; end
	-- Load saved product data
	self.data = FRC_DataLib.loadTable(saveDataFilename);
	if (not self.data) then
		self.data = { purchased = {} };
		FRC_DataLib.saveTable(self.data, saveDataFilename);
	end


	-- get product data from JSON
	local allStoreData = FRC_DataLib.readJSON(productDataPath);
	assert(allStoreData, productDataPath .. " does not exist or has no product data. Please create one before calling FRC_Store:init().");

	-- load store data for target device store
	self.storeName = system.getInfo("targetAppStore");
	if (system.getInfo("environment") == "simulator") then
		self.storeName = FRC_Store.settings.debugStore;
	end
	if (not self.storeName or self.storeName == "none") then
		print("No target store for current device/build. Aborting.");
		return;
	end
	self.storeData = allStoreData[self.storeName];
	if (not self.storeData) then
		print("No product data found for target store (" .. self.storeName .. "). Aborting.");
		return;
	end
	pcall(function()
		self.interface = require(self.storeData.interface);

		local cached_purchase = self.interface.purchase;
		self.interface.purchase = function(productIds)
			if (system.getInfo("targetAppStore") == "amazon") then
				if (type(productIds) == "table" and #productIds >= 1) then
					cached_purchase(productIds[1]);
				elseif (type(productIds) == "string") then
					cached_purchase(productIds);
				end
			else
				cached_purchase(productIds);
			end
		end
	end);
	self.storeData.products = allStoreData.products;

	-- Call init() on native store module as "interface" (into IAP purchase API)
	if (PREPAID_BUILD) then
		for i=1,#allStoreData.products do
			if (not self:checkPurchased(allStoreData.products[i])) then
				table.insert(self.data.purchased, allStoreData.products[i].identifier);
			end
		end
	elseif (self.interface.init) then
		if (self.storeData.storeNameAsFirstArg) then
			self.interface.init(self.storeName, standardTransactionCallback);
		else
			self.interface.init(standardTransactionCallback);
		end
	end

	self.initialized = true;
	--if (not self.interface.isActive) then return; end
	-- set pricing (and sale) info for each product
	--[[
	if (self.interface.canLoadProducts or system.getInfo("environment") == "simulator") then
		local productCallback = function(event)
			local products = event.products;
			for i=1,#products do
				local productData = self:getDataForSingleProduct(products[i].productIdentifier);
				if (productData) then
					if (productData.MSRP > products[i].price) then
						-- price on store is lower than MSRP; mark item onSale
						productData.onSale = true;
					end
					productData.price = products[i].price;
				end
			end

			-- check for invalid products and print message
			if (event.invalidProducts and #event.invalidProducts > 0) then
				print('The following products in "' .. productDataPath .. '" are invalid:');
				--local invalidStr = "";
				for i=1,#event.invalidProducts do
					print('\t', event.invalidProducts[i]);
					--invalidStr = invalidStr .. ", " .. event.invalidProducts[i];
				end
				--native.showAlert("Invalid Products", invalidStr, { "OK" });
			end
		end
		local listOfProducts = {};
		for i=1,#self.storeData.products do
			listOfProducts[i] = self.storeData.products[i].identifier;
		end
		self.interface.loadProducts(listOfProducts, productCallback);
	else
		-- set 'price' to equal set MSRP for product (since we cannot poll store for pricing info)
		for i=1,#self.storeData.products do
			self.storeData.products[i].price = self.storeData.products[i].MSRP;
			self.storeData.products[i].onSale = false;
		end
	end
	--]]
end

function FRC_Store:show(focusId, focusImage)
	if (not self.initialized) then
		self:init();
	end
	local FRC_Store_View = require("FRC_Modules.FRC_Store.FRC_Store_View");
	return FRC_Store_View:new(focusId, focusImage);
end

return FRC_Store;
