local FRC_CameraRoll = {};

FRC_CameraRoll.saveFromFile = function(filename, baseDirectory)
	if (not filename) then return false; end
	baseDirectory = baseDirectory or system.ResourceDirectory;
	local image = display.newImage(filename, baseDirectory);
	local obj = display.capture(image, {
		saveToPhotoLibrary = true,
		isFullResolution = true
	});
	image:removeSelf();
	obj:removeSelf();
	return true;
end

FRC_CameraRoll.saveDisplayObject = function(displayObject)
	if (not displayObject) then return false; end
	local obj = display.capture(displayObject, {
		saveToPhotoLibrary = true,
		isFullResolution = true
	});
	obj:removeSelf();
	return true;
end

FRC_CameraRoll.saveBounds = function(bounds)
	if (not bounds) then return false; end
	local obj = display.captureBounds(bounds, true);
	obj:removeSelf();
	return true;
end

return FRC_CameraRoll;