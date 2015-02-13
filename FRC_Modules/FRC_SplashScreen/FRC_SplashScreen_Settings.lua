local FRC_SplashScreen_Settings = {};

FRC_SplashScreen_Settings.DATA = {
	VIDEOS = {
		{
			HD_VIDEO_PATH = 'FRC_Assets/FRC_SplashScreen/Video/FRC_SplashScreen_IdentityVideo_LandscapeHD.m4v',
			HD_VIDEO_SIZE = { width = 1024, height = 768 },
			SD_VIDEO_PATH = 'FRC_Assets/FRC_SplashScreen/Video/FRC_SplashScreen_IdentityVideo_LandscapeSD.m4v',
			SD_VIDEO_SIZE = { width = 512, height = 384 },
			VIDEO_SCALE = 'LETTERBOX',
			VIDEO_LENGTH = 5000 },
			{
			HD_VIDEO_PATH = 'FRC_Assets/GENU_Assets/Videos/GENU_Auditorium_IntroAnim_HD.m4v',
			HD_VIDEO_SIZE = { width = 1024, height = 768 },
			SD_VIDEO_PATH = 'FRC_Assets/GENU_Assets/Videos/GENU_Auditorium_IntroAnim_SD.m4v',
			SD_VIDEO_SIZE = { width = 512, height = 384 },
			VIDEO_SCALE = 'FULLSCREEN',
			VIDEO_LENGTH = 30367 }
	}
};

return FRC_SplashScreen_Settings;
