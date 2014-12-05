local FRC_DataLib = require('FRC_Modules.FRC_DataLib.FRC_DataLib');
local FRC_Layout = require('FRC_Modules.FRC_Layout.FRC_Layout');
local FRC_JigsawPuzzle_Settings = require('FRC_Modules.FRC_JigsawPuzzle.FRC_JigsawPuzzle_Settings');
local FRC_JigsawPuzzle_JoinerData = require('FRC_Modules.FRC_JigsawPuzzle.FRC_JigsawPuzzle_JoinerData');
local FRC_AudioManager = require('FRC_Modules.FRC_AudioManager.FRC_AudioManager');
local FRC_AppSettings = require('FRC_Modules.FRC_AppSettings.FRC_AppSettings');
local FRC_JigsawPuzzle = {};

local goldenCockerel = native.systemFontBold; --"Golden Cockerel ITC Std";
if (system.getInfo("platformName") == "Android") then
	goldenCockerel = native.systemFontBold; --"GoldenCockerelITCStd";
end

local puzzleEncouragementAudioPaths = {
	'FRC_Assets/FRC_JigsawPuzzle/Audio/GENU_en_VO_PuzzleEncouragements_Awesome2.mp3',
	'FRC_Assets/FRC_JigsawPuzzle/Audio/GENU_en_VO_PuzzleEncouragements_GreatJob2.mp3',
	'FRC_Assets/FRC_JigsawPuzzle/Audio/GENU_en_VO_PuzzleEncouragements_GreatWork.mp3',
	'FRC_Assets/FRC_JigsawPuzzle/Audio/GENU_en_VO_PuzzleEncouragements_WowAwesome.mp3',
	'FRC_Assets/FRC_JigsawPuzzle/Audio/GENU_en_VO_PuzzleEncouragements_Yay.mp3',
	'FRC_Assets/FRC_JigsawPuzzle/Audio/GENU_en_VO_PuzzleEncouragements_YoureAWinner.mp3'
};

local puzzleEncouragements = FRC_AudioManager:newGroup({
	name = "puzzle_encouragements",
	maxChannels = FRC_AppSettings.get("MAX_VO_CHANNELS");
});

for i=1,#puzzleEncouragementAudioPaths do
	FRC_AudioManager:newHandle({
		path = puzzleEncouragementAudioPaths[i],
		group = puzzleEncouragements
	});
end

math.randomseed( os.time() )  -- make math_random() more random
local math_floor = math.floor;
local math_sqrt = math.sqrt;
local math_random = math.random;
local math_abs = math.abs;

math.round = function(num, idp)
  local mult = 10^(idp or 0)
  return math_floor(num * mult + 0.5) / mult;
end
local math_round = math.round;

math.distance = function(x1, y1, x2, y2)
	local dx = (x2-x1)
	local dy = (y2-y1)
	return math_floor(math_sqrt(dx*dx + dy*dy))
end
local math_distance = math.distance;

local choose = function(...)
	return arg[math.random(1, #arg)];
end
FRC_JigsawPuzzle.choose = choose;

--- Generates a grid of joiner data with proper connections
local createJoinerGrid = function(columns, rows)
	local joiners = { "inner", "outer" };
	local grid = {};

	for y=1,rows do
		grid[y] = {};
		for x=1,columns do
			grid[y][x] = {
				north = joiners[math_random(1,#joiners)],
				east = joiners[math_random(1,#joiners)],
				south = joiners[math_random(1,#joiners)],
				west = joiners[math_random(1,#joiners)]
			}

			if (y == 1) then
				grid[y][x].north = "flat";
			elseif (y == rows) then
				grid[y][x].south = "flat";
			end

			if (x == 1) then
				grid[y][x].west = "flat";
			elseif (x == columns) then
				grid[y][x].east = "flat";
			end
		end
	end

	-- ensure all pieces 'fit' together properly
	for y=1,rows do
		for x=1,columns do
			local tile = grid[y][x];

			-- horizontal
			if (x == 1) then tile.west = 'flat'; end
			if (x == columns) then
				tile.east = 'flat';
			else
				local nextX = grid[y][x+1];
				local r = math_random(1,2);
				tile.east = joiners[r];
				tile.eastOffset = choose(-0.15, -0.1, -0.07, -0.03, 0, 0.03, 0.07, 0.1, 0.15);
				nextX.westOffset = tile.eastOffset;

				tile.bottomRightCornerOffset = 0; --choose(-0.02, 0.02);
				nextX.bottomLeftCornerOffset = tile.bottomRightCornerOffset;
				if (r == 1) then
					nextX.west = joiners[2];
				else
					nextX.west = joiners[1];
				end
			end

			-- vertical
			if (y == 1) then tile.north = 'flat'; end
			if (y == rows) then
				tile.south = 'flat';
			else
				local nextY = grid[y+1][x];
				local r = math_random(1,2);
				tile.south = joiners[r];
				tile.southOffset = choose(-0.15, -0.1, -0.07, -0.03, 0, 0.03, 0.07, 0.1, 0.15);
				nextY.northOffset = tile.southOffset;

				tile.topLeftCornerOffset = 0; --choose(-0.02, 0.02);
				nextY.topRightCornerOffset = tile.topLeftCornerOffset;
				if (r == 1) then
					nextY.north = joiners[2];
				else
					nextY.north = joiners[1];
				end
			end
		end
	end

	return grid;
end

local assemblePiece = function(tile, width, height)
	local northSide = tile.north;
	local eastSide = tile.east;
	local southSide = tile.south;
	local westSide = tile.west;

	local vertices = {};

	for i=1,#FRC_JigsawPuzzle_JoinerData.north[northSide] do
		local a = FRC_JigsawPuzzle_JoinerData.north[northSide][i][1];
		local b = FRC_JigsawPuzzle_JoinerData.north[northSide][i][2];

		if ((tile.northOffset) and (i ~= #FRC_JigsawPuzzle_JoinerData.north[northSide])) then
			a = a + tile.northOffset;
		elseif (tile.topRightCornerOffset) and (i == #FRC_JigsawPuzzle_JoinerData.north[northSide]) then
			a = a + tile.topRightCornerOffset;
		end

		a = a * (width * 0.5);
		b = b * (height * 0.5);

		table.insert(vertices, a);
		table.insert(vertices, b);
	end

	for i=1,#FRC_JigsawPuzzle_JoinerData.east[eastSide] do
		local a = FRC_JigsawPuzzle_JoinerData.east[eastSide][i][1];
		local b = FRC_JigsawPuzzle_JoinerData.east[eastSide][i][2];

		if ((tile.eastOffset) and (i ~= #FRC_JigsawPuzzle_JoinerData.east[eastSide])) then
			b = b + tile.eastOffset;
		elseif (tile.bottomRightCornerOffset) and (i == #FRC_JigsawPuzzle_JoinerData.east[eastSide]) then
			a = a + tile.bottomRightCornerOffset;
		end

		a = a * (width * 0.5);
		b = b * (height * 0.5);

		table.insert(vertices, a);
		table.insert(vertices, b);
	end

	for i=1,#FRC_JigsawPuzzle_JoinerData.south[southSide] do
		local a = FRC_JigsawPuzzle_JoinerData.south[southSide][i][1];
		local b = FRC_JigsawPuzzle_JoinerData.south[southSide][i][2];

		if ((tile.southOffset) and (i ~= #FRC_JigsawPuzzle_JoinerData.south[southSide])) then
			a = a + tile.southOffset;
		elseif (tile.bottomLeftCornerOffset) and (i == #FRC_JigsawPuzzle_JoinerData.south[southSide]) then
			a = a + tile.bottomLeftCornerOffset;
		end

		a = a * (width * 0.5);
		b = b * (height * 0.5);

		table.insert(vertices, a);
		table.insert(vertices, b);
	end

	for i=1,#FRC_JigsawPuzzle_JoinerData.west[westSide] do
		local a = FRC_JigsawPuzzle_JoinerData.west[westSide][i][1];
		local b = FRC_JigsawPuzzle_JoinerData.west[westSide][i][2];

		if ((tile.westOffset) and (i ~= #FRC_JigsawPuzzle_JoinerData.west[westSide])) then
			b = b + tile.westOffset;
		elseif (tile.topLeftCornerOffset) and (i == #FRC_JigsawPuzzle_JoinerData.west[westSide]) then
			a = a + tile.topLeftCornerOffset;
		end

		a = a * (width * 0.5);
		b = b * (height * 0.5);

		table.insert(vertices, a);
		table.insert(vertices, b);
	end

	return vertices;
end

local calculateOffset = function(totalWidth, totalHeight, pieceWidth, pieceHeight)
	local halfPuzzleW = totalWidth * 0.5;
	local halfPuzzleH = totalHeight * 0.5;
	local halfPieceX = pieceWidth * 0.5;
	local halfPieceY = pieceHeight * 0.5;

	local xDiff = halfPuzzleW - halfPieceX;
	local yDiff = halfPuzzleH - halfPieceY;
	local xScale = xDiff / totalWidth;
	local yScale = yDiff / totalHeight;

	return xScale, yScale;
end

local checkPiece = function(piece, x, y)
	local xThresh = piece.parent.xThresh;
	local yThresh = piece.parent.yThresh;

	if (math_floor(piece.rotation) ~= 0) then
		return false;
	end

	return ((math_distance(x, y, piece.correctX, piece.correctY)) <= ((xThresh + yThresh) * 0.5)) and (piece.rotation == 0);
end

local onPieceTouch = function(event)
	local self = event.target;

	if (event.phase == "began") and (self.isMovable) then

		display.getCurrentStage():setFocus(self);
		self.isFocus = true;

		if (self.shadow) then self.shadow:removeSelf(); end
		self.shadow = display.newPolygon(self.parent, self.x, self.y, self.shapeData);
		self.shadow.rotation = self.rotation;
		self.shadow.alpha = 0.3;
		self.shadow:setFillColor(0, 0, 0);
		self.shadow:scale(0.95, 0.95);
		self.shadow.x, self.shadow.y = self.x + 7, self.y + 7;
		self.strokeWidth = 3;

		self.markX = self.x;
		self.markY = self.y;
		self:toFront();

	elseif (self.isFocus) then
		if (event.phase == "moved") then

			self.x = (event.x - event.xStart) + self.markX;
			self.y = (event.y - event.yStart) + self.markY;

			self.shadow.x = self.x + 7;
			self.shadow.y = self.y + 7;

			--[[
			for i=1,#self.connectedPieces do
				local p = self.connectedPieces[i];

				if ((self.north) and (p == self.north)) then
					local correctX = self.correctX - p.correctX;
					local correctY = math_abs(self.correctY - p.correctY);
					p.x = self.x + correctX;
					p.y = self.y - correctY;
				end

				if ((self.west) and (p == self.west)) then
					local correctX = math_abs(self.correctX - p.correctX);
					local correctY = self.correctY - p.correctY;
					p.x = self.x - correctX;
					p.y = self.y + correctY;
				end

				if ((self.east) and (p == self.east)) then
					local correctX = math_abs(self.correctX - p.correctX);
					local correctY = self.correctY - p.correctY;
					p.x = self.x + correctX;
					p.y = self.y + correctY;
				end

				if ((self.south) and (p == self.south)) then
					local correctX = self.correctX - p.correctX;
					local correctY = math_abs(self.correctY - p.correctY);
					p.x = self.x + correctX;
					p.y = self.y + correctY;
				end
			end
			--]]
		else
			if (self.shadow) then
				self.shadow:removeSelf(); self.shadow = nil;
			end
			self.strokeWidth = 2;

			if (self.parent.rotationEnabled) then
				if ((math_abs(self.x - self.markX) <= 3) and (math_abs(self.y - self.markY) <= 3)) then
					self.isMovable = false;
					local r = self.rotation + 90;
					transition.to(self, { time=200, transition=easing.inOutExpo, rotation=r, onComplete=function()
						if (self.rotation > 275) then self.rotation = 0; end
						self.isMovable = true;
					end });
				end
			end

			if (checkPiece(self, self.x, self.y)) then
				local puzzle = self.parent.parent;
				if (not puzzle.totalMatches) then puzzle.totalMatches = 0; end
				if (not puzzle.matchedPieces) then puzzle.matchedPieces = {}; end
				table.insert(puzzle.matchedPieces, self);
				puzzle.totalMatches = puzzle.totalMatches + 1;
				self.isMovable = false;
				self:toBack();
				self:setFillColor(1.0);
				self:setStrokeColor(0, 0, 0, 0);
				if (self.effectTimer) then
					timer.cancel(self.effectTimer); self.effectTimer = nil;
				end
				self.fill.effect = nil;
				transition.to(self, { time=250, x=self.correctX, y=self.correctY, onComplete=function()
					if (puzzle.totalMatches >= (puzzle.totalColumns * puzzle.totalRows)) then
						-- User finished the puzzle!

						Runtime:removeEventListener('enterFrame', puzzle.enterFrame); -- stop the timer
						puzzle.bg.alpha = 1.0;
						puzzle.bg.isVisible = true;
						puzzle.pieces.isVisible = false;
						puzzle:dispatchEvent({
							name='puzzleComplete'
						});
					end
				end });
			end

			--[[
			local xThresh = self.parent.xThresh;
			local yThresh = self.parent.yThresh;
			if (self.rotation == 0) then
				-- Check for northern connection
				if ((self.north) and (self.north.rotation == 0)) then
					local correctX = self.correctX - self.north.correctX;
					local realX = self.x - self.north.x;

					if (math_abs(correctX - realX) <= xThresh) then
						local correctY = self.correctY - self.north.correctY;
						local realY = self.y - self.north.y;

						if (math_abs(correctY - realY) <= yThresh) then
							table.insert(self.connectedPieces, self.north);
							table.insert(self.north.connectedPieces, self);

							self.x = self.north.x + correctX;
							self.y = self.north.y + math_abs(correctY);
						end
					end
				end

				-- Check for western connection
				if ((self.west) and (self.west.rotation == 0)) then
					local correctY = self.correctY - self.west.correctY;
					local realY = self.y - self.west.y;

					if (math_abs(correctY - realY) <= yThresh) then
						local correctX = self.correctX - self.west.correctX;
						local realX = self.x - self.west.x;

						if (math_abs(correctX - realX) <= xThresh) then
							table.insert(self.connectedPieces, self.west);
							table.insert(self.west.connectedPieces, self);

							self.x = self.west.x + math_abs(correctX);
							self.y = self.west.y + correctY;
						end
					end
				end

				-- Check for eastern connection
				if ((self.east) and (self.east.rotation == 0)) then
					local correctY = self.correctY - self.east.correctY;
					local realY = self.y - self.east.y;

					if (math_abs(correctY - realY) <= yThresh) then
						local correctX = self.east.correctX - self.correctX;
						local realX = self.east.x - self.x

						if (math_abs(correctX - realX) <= xThresh) then
							table.insert(self.connectedPieces, self.east);
							table.insert(self.east.connectedPieces, self);

							self.x = self.east.x - math_abs(correctX);
							self.y = self.east.y + correctY;
						end
					end
				end

				-- Check for southern connection
				if ((self.south) and (self.south.rotation == 0)) then
					local correctX = self.correctX - self.south.correctX;
					local realX = self.x - self.south.x;

					if (math_abs(correctX - realX) <= xThresh) then
						local correctY = self.south.correctY - self.correctY;
						local realY = self.south.y - self.y

						if (math_abs(correctY - realY) <= yThresh) then
							table.insert(self.connectedPieces, self.south);
							table.insert(self.south.connectedPieces, self);

							self.x = self.south.x + correctX;
							self.y = self.south.y - math_abs(correctY);
						end
					end
				end
			end
			--]]

			self.isFocus = false;
			display.getCurrentStage():setFocus(nil);
		end
	end

	return true;
end

local createPuzzlePieces = function(parent, grid, hideTexture, filter)
	local group = parent;
	local parentGroup = group.parent;
	local columns = parentGroup.totalColumns;
	local rows = parentGroup.totalRows;
	local puzzleW = parentGroup.puzzleW;
	local puzzleH = parentGroup.puzzleH;
	local pieceWidth = (puzzleW / columns);
	local pieceHeight = (puzzleH / rows);

	-- construct puzzle
	local px = -1.0;
	local py = -1.0;

	local pieceGrid = {};

	for row=1,rows do
		px = -1.0;
		offsetX = 0;
		offsetY = 0;
		pieceGrid[row] = {};
		for col=1,columns do
			local tile = grid[row][col];
			local vertices;
			local innerWest = false;
			local innerEast = false;
			local innerNorth = false;
			local innerSouth = false;
			local outerWest = false;
			local outerEast = false;
			local outerNorth = false;
			local outerSouth = false;

			if (tile.north == 'outer') then outerNorth = true; elseif (tile.north == 'inner') then innerNorth = true; end
			if (tile.east == 'outer') then outerEast = true; elseif (tile.east == 'inner') then innerEast = true; end
			if (tile.south == 'outer') then outerSouth = true; elseif (tile.south == 'inner') then innerSouth = true; end
			if (tile.west == 'outer') then outerWest = true; elseif (tile.west == 'inner') then innerWest = true; end

			--local vertices = assemblePiece(tile.north, tile.east, tile.south, tile.west, pieceWidth, pieceHeight);
			local vertices = assemblePiece(tile, pieceWidth, pieceHeight);

			local x = (col-1) * pieceWidth;
			local y = (row-1) * pieceHeight;
			local piece = display.newPolygon(group, x, y, vertices);
			piece.anchorX = 0.5;
			piece.anchorY = 0.5;
			piece.shapeData = vertices;
			piece.connectedPieces = {};
			pieceGrid[row][col] = piece;

			-- offset x/y position of puzzle piece depending on which sides joiners extend
			local xOffset = pieceWidth * 0.5;
			local yOffset = pieceHeight * 0.5;

			if (outerWest) then
				xOffset = xOffset - ((piece.contentWidth - pieceWidth) * 0.5);
			end

			if (outerEast) then
				xOffset = xOffset + ((piece.contentWidth - pieceWidth) * 0.5);
			end

			if (outerNorth) then
				yOffset = yOffset - ((piece.contentHeight - pieceHeight) * 0.5);
			end

			if (outerSouth) then
				yOffset = yOffset + ((piece.contentHeight - pieceHeight) * 0.5);
			end
			piece.x = piece.x + xOffset;
			piece.y = piece.y + yOffset;
			piece.correctX = piece.x;
			piece.correctY = piece.y;
			piece.isMovable = true;

			piece.strokeWidth = 2;
			piece:setStrokeColor(0, 0, 0, 0.35);
			if (not hideTexture) then
				piece.fill = { type="image", filename=parentGroup.puzzleImage, baseDir=system[parentGroup.baseDirectory]};
				piece.fill.scaleX = puzzleW / piece.contentWidth;
				piece.fill.scaleY = puzzleH / piece.contentHeight;
			end

			local i = 1;
			local d = 2;

			local function onTimerComplete()
				piece.fill.effect.numPixels = i;
				i = i + d;
				if (i <= 1) then
					d = 2;
					timer.cancel(piece.effectTimer);
					piece.effectTimer = timer.performWithDelay(500, function()
						piece.effectTimer = timer.performWithDelay(100, onTimerComplete, 0);
					end, 1);
				end
				if (i >= 30) then
					d = -2;
				end
			end

			if (filter) then
				piece.fill.effect = filter;

				if (filter == "filter.pixelate") then
					piece.effectTimer = timer.performWithDelay(100, onTimerComplete, 0);
				end
			end

			if (hideTexture) then
				piece:setFillColor(1.0, 1.0, 1.0, 0);
				piece.isHitTestable = true;
				piece.isMovable = false;
			else
				piece:setFillColor(0.88);
			end

			local xScale, yScale = calculateOffset(puzzleW, puzzleH, pieceWidth, pieceHeight);
			piece.fill.x = px * xScale;
			piece.fill.y = py * yScale;
			px = px + (2.0 / (columns - 1));

			local oldFill = piece.fill.x;

			local overflowMultiplierX = 0.25;
			local overflowMultiplierY = 0.25;

			if ((outerWest) and (outerEast)) then
				overflowMultiplierX = 0;
			elseif (outerEast) then
				overflowMultiplierX = 0.25;
			elseif (outerWest) then
				if (innerEast) then
					overflowMultiplierX = -0.25;
				else
					overflowMultiplierX = 0.25;
				end
			end

			if ((outerNorth) and (outerSouth)) then
				overflowMultiplierY = 0;
			elseif (outerSouth) then
				overflowMultiplierY = -0.25;
			elseif (outerNorth) then
				if (innerSouth) then
					overflowMultiplierY = -0.25;
				elseif (outerSouth) then
					overflowMultiplierY = 0.25;
				else
					overflowMultiplierY = -0.25;
				end
			end

			if (innerNorth) then
				if (outerSouth) then
					overflowMultiplierY = 0.25;
				end
			end

			local overflowX = (piece.contentWidth - pieceWidth) * overflowMultiplierX;
			local overflowY = (piece.contentHeight - pieceHeight) * overflowMultiplierY;

			if (col == 1) then
				overflowX = (piece.contentWidth - pieceWidth) * 0.25;

			elseif (col == columns) then
				if (outerWest) then
					overflowX = (piece.contentWidth - pieceWidth) * -0.25;
				else
					overflowX = (piece.contentWidth - pieceWidth) * 0;
				end
			end

			if (row == 1) then
				overflowY = (piece.contentHeight - pieceHeight) * 0.25;
			end

			local offsetX = 2.0 / (puzzleW / overflowX);
			local offsetY = 2.0 / (puzzleH / overflowY);

			if (not hideTexture) then
				piece.fill.x = piece.fill.x + offsetX;
				piece.fill.y = piece.fill.y + offsetY;
			end

			piece.touch = onPieceTouch;
			piece:addEventListener('touch', piece.touch);
		end
		py = py + (2.0 / (rows - 1));
	end

	for row=1,#pieceGrid do
		for col=1,#pieceGrid[row] do
			local p = pieceGrid[row][col];

			if (row == 1) then
				p.south = pieceGrid[row+1][col];
			elseif (row == #pieceGrid) then
				p.north = pieceGrid[row-1][col];
			else
				p.south = pieceGrid[row+1][col];
				p.north = pieceGrid[row-1][col];
			end

			if (col == 1) then
				p.east = pieceGrid[row][col+1];
			elseif (row == #pieceGrid) then
				p.west = pieceGrid[row][col-1];
			else
				p.east = pieceGrid[row][col+1];
				p.west = pieceGrid[row][col-1];
			end
		end
	end

	pieceGrid = nil;
end

local scatterPieces = function(piecesGroup, puzzleW, puzzleH, randomRotation)
	local screenW, screenH = FRC_Layout.getScreenDimensions();

	local width = puzzleW + ((screenW - puzzleW) * 0.5);
	local height = puzzleH + ((screenH - puzzleH) * 0.25);
	local puzzlePadding = 40;

	-- create an invisible rect (e.g. "moat") around the puzzle where pieces will be placed
	local moatRect = display.newRect(0, 0, width, height);
	moatRect:setFillColor(0, 0, 0);
	moatRect.alpha = 1.0;
	moatRect.x = display.contentCenterX;
	moatRect.y = display.contentCenterY + ((screenH - puzzleH) * 0.125);

	-- randomize draw order of pieces
	local swappedIndexes = {};
	local indexes = {};
	for i=1,piecesGroup.numChildren do
		indexes[i] = i;
	end

	for i=1,#indexes do
		local swapped = false;
		for j=1,#swappedIndexes do
			if (swappedIndexes[j] == i) then
				swapped = true;
			end
		end

		if ((not swapped) and (#swappedIndexes < #indexes)) then
			local r = math.random(i,#indexes);
			local piece1 = piecesGroup[i];
			local piece2 = piecesGroup[r];
			piecesGroup:insert(r, piece1);
			piecesGroup:insert(i, piece2);
			table.insert(swappedIndexes, i);
			table.insert(swappedIndexes, r);
		end
	end

	-- scatter each piece of the puzzle within the 'moat' area but not in the puzzle space
	for i=1,piecesGroup.numChildren do
		local piece = piecesGroup[i];

		local x = math_random(0, screenW);
		local y = math_random(0, screenH);

		local isWithinPuzzle = ((x > piecesGroup.contentBounds.xMin - puzzlePadding) and (x < piecesGroup.contentBounds.xMax + puzzlePadding) and (y > piecesGroup.contentBounds.yMin - puzzlePadding) and (y < piecesGroup.contentBounds.yMax + puzzlePadding));
		local isWithinRect = ((x > moatRect.contentBounds.xMin) and (x < moatRect.contentBounds.xMax) and (y > moatRect.contentBounds.yMin) and (y < moatRect.contentBounds.yMax))
		local isWithinMoat = isWithinRect and (not isWithinPuzzle);

		while (not isWithinMoat) do
			x = math_random(0, screenW);
			y = math_random(0, screenH);

			isWithinPuzzle = ((x > piecesGroup.contentBounds.xMin - puzzlePadding) and (x < piecesGroup.contentBounds.xMax + puzzlePadding) and (y > piecesGroup.contentBounds.yMin - puzzlePadding) and (y < piecesGroup.contentBounds.yMax + puzzlePadding));
			isWithinRect = ((x > moatRect.contentBounds.xMin) and (x < moatRect.contentBounds.xMax) and (y > moatRect.contentBounds.yMin) and (y < moatRect.contentBounds.yMax))
			isWithinMoat = isWithinRect and (not isWithinPuzzle);
		end

		--display.newCircle(x, y, 3); -- for debugging purposes
		x, y = piece:contentToLocal(x, y);

		piece.scatterX, piece.scatterY = piece.x + x, piece.y + y;
		local rot = 0;
		if (randomRotation) then
			piecesGroup.randomRotation = true;
			rot = choose(0, 90, 180, 270, -90, -180, -270);
		end
		piece.isMovable = false;
		transition.to(piece, { time=1000, x=piece.scatterX, y=piece.scatterY, rotation=rot, transition=easing.inOutExpo, onComplete=function()
			piece.isMovable = true;
		end });
		piece.isMovable = true;
	end
	moatRect:removeSelf(); moatRect = nil;
end

FRC_JigsawPuzzle.new = function(puzzleIndex, columns, rows, customJoinerData, filterEffect, customPuzzleData)
	local group = display.newGroup();
	group.anchorChildren = false;
	group.pieces = display.newGroup(); group:insert(group.pieces);
	group.pieces.anchorChildren = false;
	group.totalColumns = columns;
	group.totalRows = rows;

	-- get puzzle image based on provided index (from data file)
	local puzzleData = ((customPuzzleData) or (FRC_DataLib.readJSON(FRC_JigsawPuzzle_Settings.DATA.PUZZLES).puzzles));
	local puzzleImage = puzzleData[puzzleIndex].image;
	if (display.contentScaleX <= 0.5) then
		puzzleImage = puzzleImage .. '@2x.' .. puzzleData[puzzleIndex].ext;
	else
		puzzleImage = puzzleImage .. '.' .. puzzleData[puzzleIndex].ext;
	end
	group.puzzleImage = FRC_JigsawPuzzle_Settings.UI.IMAGE_PATH .. puzzleImage;

	if (puzzleData[puzzleIndex].baseDirectory) then
		puzzleImage = puzzleData[puzzleIndex].image .. '_full.' .. puzzleData[puzzleIndex].ext;
		group.puzzleImage = puzzleImage;
		group.baseDirectory = puzzleData[puzzleIndex].baseDirectory;
	else
		group.baseDirectory = 'ResourceDirectory';
	end

	-- scale puzzle
	local totalPuzzleW = puzzleData[puzzleIndex].width;
	local totalPuzzleH = puzzleData[puzzleIndex].height;
	local screenW, screenH = FRC_Layout.getScreenDimensions();
	local puzzleScaleX = (FRC_JigsawPuzzle_Settings.UI.MAX_WIDTH * screenW) / totalPuzzleW;
	local puzzleScaleY = (FRC_JigsawPuzzle_Settings.UI.MAX_HEIGHT * screenH) / totalPuzzleH;
	local puzzleW = totalPuzzleW * puzzleScaleX;
	local puzzleH = totalPuzzleH * puzzleScaleX;
	if ((puzzleH / screenH) > FRC_JigsawPuzzle_Settings.UI.MAX_HEIGHT) then
		puzzleW = totalPuzzleW * puzzleScaleY;
		puzzleH = totalPuzzleH * puzzleScaleY;
	end
	group.puzzleW = puzzleW;
	group.puzzleH = puzzleH;

	-- create grid to represent puzzle pieces (includes joiner connection data)
	createPuzzlePieces(group.pieces, customJoinerData or createJoinerGrid(columns, rows), false, filterEffect);

	local borderRect = display.newRect(0, 0, puzzleW + 10, puzzleH + 10);
	borderRect:setFillColor(0, 0, 0, 0.5);
	group:insert(1, borderRect);
	borderRect.x = 0;
	borderRect.y = 0;

	local bgRect = display.newRect(0, 0, puzzleW, puzzleH);
	bgRect:setFillColor(1.0, 1.0, 1.0);
	group:insert(2, bgRect);
	bgRect.x = 0;
	bgRect.y = 0;

	local bg = display.newImageRect(group.puzzleImage, system[group.baseDirectory], puzzleW, puzzleH);
	bg.alpha = 0.35;
	group:insert(3, bg);
	bg.x = 0;
	bg.y = 0;
	group.bg = bg;

	group.x = display.contentCenterX;
	group.y = display.contentCenterY;

	group.pieces.xThresh = math.round((puzzleW / columns) * 0.2); -- x threshold for placing pieces in correct place
	group.pieces.yThresh = math.round((puzzleH / rows) * 0.2); -- y threshold for placing pieces in correct place
	group.pieces.x = -group.pieces.contentWidth * 0.5;
	group.pieces.y = -group.pieces.contentHeight * 0.5;

	-- create timer text
	group.timerText = display.newEmbossedText(group, "00:00:00", 0, 0, goldenCockerel, 48);
	group.timerText.x = 0;
	group.timerText.y = (puzzleH * 0.5) + ((screenH - puzzleH) * 0.25) + 5;
	group.timerText:setFillColor(1.0, 1.0, 1.0, 1.0);
	group.timerText.isVisible = true;
	group.ms = 0;
	group.ss = 0;

	group.enterFrame = function(event)
		local ms = math.floor(event.time - group.markTime);
		if (group.ms == ms) then return; end
		group.ms = ms;
		local seconds = math.floor(ms / 1000);
		if (group.ss == seconds) then return; end
		group.ss = seconds;
		group.seconds = group.seconds + 1;
		if (group.seconds >= 60) then
			group.seconds = 0;
			group.minutes = group.minutes + 1;
			if (group.minutes >= 60) then
				group.minutes = 0;
				group.hours = group.hours + 1;
			end
		end

		local secondsDisplay, minutesDisplay, hoursDisplay;
		if (group.seconds < 10) then
			secondsDisplay = '0' .. tostring(group.seconds);
		else
			secondsDisplay = tostring(group.seconds);
		end

		if (group.minutes < 10) then
			minutesDisplay = '0' .. tostring(group.minutes);
		else
			minutesDisplay = tostring(group.minutes);
		end

		if (group.hours < 10) then
			hoursDisplay = '0' .. tostring(group.hours);
		else
			hoursDisplay = tostring(group.hours);
		end

		group.timerText:setText(hoursDisplay .. ':' .. minutesDisplay .. ':' .. secondsDisplay);
	end

	group.dispose = function(self)
		Runtime:removeEventListener('enterFrame', group.enterFrame);

		for i=group.pieces.numChildren,1,-1 do
			if (group.pieces[i].effectTimer) then timer.cancel(group.pieces[i].effectTimer); group.pieces[i].effectTimer = nil; end
			group.pieces[i]:removeSelf();
			group.pieces[i] = nil;
		end

		group:removeSelf();
	end

	-- scatters pieces and begins timer
	group.scatter = function(self, randomRotation, callback)
		if (randomRotation) then group.pieces.rotationEnabled = true; end

		timer.performWithDelay( 500, function()
			self.seconds = 0;
			self.minutes = 0;
			self.hours = 0;
			self.markTime = system.getTimer();
			Runtime:addEventListener('enterFrame', self.enterFrame);
			scatterPieces(self.pieces, self.puzzleW, self.puzzleH, randomRotation);
			if (callback) then callback(); end
		end, 1);
	end

	return group;
end

FRC_JigsawPuzzle.newPreview = function(puzzleIndex, columns, rows, puzzleW, puzzleH, customPuzzleData)
	local group = display.newGroup();
	group.anchorChildren = false;
	group.pieces = display.newGroup(); group:insert(group.pieces);
	group.pieces.anchorChildren = false;
	group.totalColumns = columns;
	group.totalRows = rows;

	-- get puzzle image based on provided index (from data file)
	local puzzleData = ((customPuzzleData) or (FRC_DataLib.readJSON(FRC_JigsawPuzzle_Settings.DATA.PUZZLES).puzzles));
	local puzzleImage = puzzleData[puzzleIndex].image .. '.' .. puzzleData[puzzleIndex].ext;
	group.puzzleImage = FRC_JigsawPuzzle_Settings.UI.IMAGE_PATH .. puzzleImage;

	if (puzzleData[puzzleIndex].baseDirectory) then
		puzzleImage = puzzleData[puzzleIndex].image .. '_full.' .. puzzleData[puzzleIndex].ext;
		group.puzzleImage = puzzleImage;
		group.baseDirectory = puzzleData[puzzleIndex].baseDirectory;
	else
		group.baseDirectory = 'ResourceDirectory';
	end

	-- scale puzzle
	group.puzzleW = puzzleW;
	group.puzzleH = puzzleH;

	-- create grid to represent puzzle pieces (includes joiner connection data)
	group.joinerData = createJoinerGrid(columns, rows);
	createPuzzlePieces(group.pieces, group.joinerData, true);

	local bgRect = display.newRect(0, 0, puzzleW + 10, puzzleH + 10);
	bgRect:setFillColor(0, 0, 0, 0.25);
	group:insert(1, bgRect);
	bgRect.x = 0;
	bgRect.y = 0;

	local bg = display.newImageRect(group.puzzleImage, system[group.baseDirectory], puzzleW, puzzleH);
	bg.alpha = 1.0;
	group:insert(2, bg);
	bg.x = 0;
	bg.y = 0;
	group.bg = bg;

	group.x = display.contentCenterX;
	group.y = display.contentCenterY;

	group.pieces.xThresh = math.round((puzzleW / columns) * 0.2); -- x threshold for placing pieces in correct place
	group.pieces.yThresh = math.round((puzzleH / rows) * 0.2); -- y threshold for placing pieces in correct place
	group.pieces.x = -group.pieces.contentWidth * 0.5;
	group.pieces.y = -group.pieces.contentHeight * 0.5;

	local previewText = display.newText({
		parent = group,
		text = 'PREVIEW',
		font = native.systemFontBold,
		fontSize = 90,
		x = 0,
		y = 0
	});
	previewText:setFillColor(0, 0, 0, 0.3);
	previewText:rotate(-30);
	previewText.isVisible = false;
	group.previewText = previewText;

	group.regenerate = function(self, c, r)
		for i=self.pieces.numChildren,1,-1 do
			self.pieces[i]:removeSelf();
			self.pieces[i] = nil;
		end
		self.totalColumns = c;
		self.totalRows = r;
		self.joinerData = createJoinerGrid(c, r);
		createPuzzlePieces(self.pieces, self.joinerData, true);
	end

	group.dispose = function(self)
		if (self.effectTimer) then timer.cancel(self.effectTimer); self.effectTimer = nil; end
		group:removeSelf();
	end

	return group;
end

FRC_JigsawPuzzle.showOptionScreen = function(parent, callback)
	local optionsGroup = require('FRC_Modules.FRC_JigsawPuzzle.FRC_JigsawPuzzle_OptionScreen').new(parent, callback);
	return optionsGroup;
end

return FRC_JigsawPuzzle;
