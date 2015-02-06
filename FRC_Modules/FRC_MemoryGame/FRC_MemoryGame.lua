local FRC_DataLib = require('FRC_Modules.FRC_DataLib.FRC_DataLib');
local FRC_Layout = require('FRC_Modules.FRC_Layout.FRC_Layout');
local FRC_MemoryGame_Settings = require('FRC_Modules.FRC_MemoryGame.FRC_MemoryGame_Settings');
local FRC_MemoryGame_Card = require('FRC_Modules.FRC_MemoryGame.FRC_MemoryGame_Card');
local FRC_AudioManager = require('FRC_Modules.FRC_AudioManager.FRC_AudioManager');
local FRC_AppSettings = require('FRC_Modules.FRC_AppSettings.FRC_AppSettings');

local FRC_MemoryGame = {};

math.randomseed( os.time() )  -- ensures math.random() is actually random

local flipDelay = 300;
local shakeEvent;

-- shuffles an array
table.shuffle = function(t)
    local n = #t

    while n >= 2 do
        -- n is now the last pertinent index
        local k = math.random(n) -- 1 <= k <= n
        -- Quick swap
        t[n], t[k] = t[k], t[n]
        n = n - 1
    end

    return t
end

local function onCardFlippedToFront(event)
	local self = event.target;
	local card = event.card;

	if (event.phase == "began") then

		if (self.flippedCardCount == 0) then
			self.activeCard1 = card;

		elseif (self.flippedCardCount == 1) then
			self.activeCard2 = card;
			self.triesCount = self.triesCount + 1;
			self.scene.triesText.text = 'Tries: ' .. self.triesCount;

		elseif (self.flippedCardCount == 2) then
			return false;
		end

		self.flippedCardCount = self.flippedCardCount + 1;

    -- play the flip SFX
    --[[ local sfxSound = FRC_AudioManager:findGroup("memory_sfx");
    if sfxSound then
      sfxSound:play(self.flippedCardSound);
    end
    --]]
    -- DEBUG:
    print("Playing Card Flip sound: ", self.flippedCardSound.name);
    self.flippedCardSound:play();
		return true;

	elseif (event.phase == "ended") then

		if (self.flippedCardCount == 2) then
			-- Check if the two flipped cards match

			if (self.activeCard1.id == self.activeCard2.id) then
				self.matchCount = self.matchCount + 1;

				if self.loadedAudio[self.activeCard1.id] then
          self.loadedAudio[self.activeCard1.id]:play({channel=FRC_AppSettings.get("SFX_CHANNEL"), force=true});

  				self.matchTimer = timer.performWithDelay(self.loadedAudio[self.activeCard1.id]:getDuration(), function()
  					self.matchTimer = nil;
  					self.activeCard1:hide();
  					self.activeCard2:hide();
  				end, 1);
        else
          self.matchTimer = nil;
          self.activeCard1:hide();
          self.activeCard2:hide();
        end
			else
				self.flipToBackTimer = timer.performWithDelay(flipDelay, function()
					self.flipToBackTimer = nil;
					self.activeCard1:flipToBack();
					self.activeCard2:flipToBack();
				end, 1);
			end
		end

		return false;
	end
end

local function onCardFlippedToBack(event)
	local self = event.target;
	local card = event.card;

	-- When two cards don't match, this event is fired when the cards are finished flipping back over
	-- Remove references to flipped cards and reset flipped card count
	if ((self.activeCard1) and (self.activeCard1.id == card.id)) then
		self.activeCard1 = nil;

	elseif ((self.activeCard2) and (self.activeCard2.id == card.id)) then
		self.activeCard2 = nil;
		self.flippedCardCount = 0;
	end
end

local function onCardDisappear(event)
	local self = event.target;
	local card = event.card;

	-- Remove references to flipped cards and reset flipped card count
	if ((self.activeCard1) and (self.activeCard1.id == card.id)) then
		self.activeCard1 = nil;

	elseif ((self.activeCard2) and (self.activeCard2.id == card.id)) then
		self.activeCard2 = nil;
		self.flippedCardCount = 0;

		-- Check for game over (after second card has disappeared)
		-- DEBUG:
		print("onCardDisappear is calling checkGameOver");
		self:checkGameOver();
	end

	if (card.dispose) then
		card:dispose();
		card = nil;
	end
end

local function checkGameOver(self)
	if (self.matchCount >= self.availableMatches) then
		-- DEBUG:
		print("checkGameOver is dispatching memoryGameOver event");

		-- Dispatch "memoryGameOver" event to parent scene
		self.scene:dispatchEvent({
			name = 'memoryGameOver',
			target = self.scene
		});

		-- Dispose of the game
		self:dispose();
		return true;
	end
	return false;
end

local function dispose(self)
  -- DEBUG:
  print("FRC_MemoryGame self disposing!");
	if (self.isDisposed) then return; end
	self.isDisposed = true;
	if (self.matchTimer) then timer.cancel(self.matchTimer); self.matchTimer = nil; end
	if (self.flipToBackTimer) then timer.cancel(self.flipToBackTimer); self.flipToBackTimer = nil; end
	self.activeCard1 = nil;
	self.activeCard2 = nil;

	self:removeEventListener('cardFlipToFront', onCardFlippedToFront);
	self:removeEventListener('cardFlipToBack', onCardFlippedToBack);
	self:removeEventListener('cardDisappear', onCardDisappear);

  for i=1,#self.loadedAudio do
    if self.loadedAudio[i] then
      -- DEBUG:
      print("disposing game audio: ", self.loadedAudio[i].name);
      self.loadedAudio[i]:stop();
      self.loadedAudio[i]:dispose();
    end
  end

  self.loadedAudio = nil;
  self.flippedCardSound:dispose();
  self.flippedCardSound = nil;

	for i=self.numChildren,1,-1 do
		if (self[i].dispose) then
			self[i]:dispose();
		end
	end

	Runtime:removeEventListener( "accelerometer", shakeEvent);
	self:removeSelf();
	collectgarbage('collect');
end

FRC_MemoryGame.new = function(scene, columns, rows)
	local screenW, screenH = FRC_Layout.getScreenDimensions();
  local cards = FRC_DataLib.readJSON(FRC_MemoryGame_Settings.DATA.CARDS);
	local cardData = cards.cards;
	local shuffledCardData = table.shuffle(cardData);

	local matchSet = (columns * rows) * 0.5;

	-- select correct number of cards and store them in 'cardsInPlay' table
	FRC_MemoryGame.cardsInPlay = {};
	for i=1,matchSet do
		table.insert(FRC_MemoryGame.cardsInPlay, shuffledCardData[i]);
		table.insert(FRC_MemoryGame.cardsInPlay, shuffledCardData[i]);
	end

	-- shuffle order of cards that are in play
	FRC_MemoryGame.cardsInPlay = table.shuffle(FRC_MemoryGame.cardsInPlay);

	-- create grid of cards based on columns and rows
	local gameGroup = display.newGroup();
	local x, y = 0, 0;

	-- preload all card specific audios
	gameGroup.loadedAudio = {};
	for i=1,#cardData do
    if cardData[i].audioFile then
  		gameGroup.loadedAudio[cardData[i].id] = FRC_AudioManager:newHandle({
  			path = FRC_MemoryGame_Settings.UI.AUDIO_BASE_PATH .. cardData[i].audioFile,
  			group = "memory_sfx",
        useLoadSound = true
  		});
    end
	end

  -- lay the cards out on the screen
	for i=1,#FRC_MemoryGame.cardsInPlay do
		local card = FRC_MemoryGame_Card.new(gameGroup, FRC_MemoryGame.cardsInPlay[i].id, FRC_MemoryGame_Settings.UI.IMAGE_BASE_PATH .. FRC_MemoryGame.cardsInPlay[i].imageFile, x, y);
		card.rotation = math.random(-2, 2);

		local xPadding = (screenW - (50*2) - (card.contentWidth * columns)) / columns;
		if (xPadding > FRC_MemoryGame_Settings.UI.CARD_PADDING_X) then
			xPadding = FRC_MemoryGame_Settings.UI.CARD_PADDING_X;
		end

		x = x + FRC_MemoryGame_Settings.UI.CARD_WIDTH + FRC_MemoryGame_Settings.UI.CARD_PADDING_X; --math.random(xPadding - (xPadding * 0.25), xPadding + (xPadding * 0.25)); --FRC_MemoryGame_Settings.UI.CARD_PADDING_X;
		if ((i % columns) == 0) then
			x = 0;
			y = y + FRC_MemoryGame_Settings.UI.CARD_HEIGHT + FRC_MemoryGame_Settings.UI.CARD_PADDING_Y;
		end
	end

  -- add in flip sound
  local flipSoundGroup = FRC_AudioManager:findGroup("cardflip_sfx");
  local flipSound;
  if flipSoundGroup then
    flipSound = flipSoundGroup:findHandle("cardFlipSFX");
  end
  if flipSound then
    gameGroup.flippedCardSound = flipSound;
  else
    gameGroup.flippedCardSound = FRC_AudioManager:newHandle({
      name = "cardFlipSFX",
      path = "FRC_Assets/FRC_MemoryGame/Audio/GENU_MemoryGame_en_Tile_Flip.mp3",
      group = "cardflip_sfx",
      useLoadSound = true
    });
  end

	-- properties and methods
	gameGroup.scene = scene;
	gameGroup.availableMatches = matchSet;
	gameGroup.activeCard1 = nil;
	gameGroup.activeCard2 = nil;
	gameGroup.flippedCardCount = 0;
	gameGroup.matchCount = 0;
	gameGroup.triesCount = 0;
	gameGroup.checkGameOver = checkGameOver;
	gameGroup.dispose = dispose;

	-- event listeners
	gameGroup:addEventListener('cardFlipToFront', onCardFlippedToFront);
	gameGroup:addEventListener('cardFlipToBack', onCardFlippedToBack);
	gameGroup:addEventListener('cardDisappear', onCardDisappear);

	-- if the user shakes the device, slightly randomly rotate the card pieces (hidden feature)
	shakeEvent = function(event)
		if (event.isShake) then
			for i=1,gameGroup.numChildren do
				gameGroup[i].rotation = math.random(-2, 2);
			end
		end
	end

	Runtime:addEventListener( "accelerometer", shakeEvent);

	return gameGroup;
end

return FRC_MemoryGame;
