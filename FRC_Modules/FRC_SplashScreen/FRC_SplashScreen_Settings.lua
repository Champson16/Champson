local FRC_SplashScreen_Settings = {};

FRC_SplashScreen_Settings.DATA = {
	VIDEOS = {
		{
			HD_VIDEO_PATH = 'FRC_Assets/FRC_SplashScreen/Video/GENU_LandingPage_IntroAnim_HD.m4v',
			HD_VIDEO_SIZE = { width = 1024, height = 768 },
			SD_VIDEO_PATH = 'FRC_Assets/FRC_SplashScreen/Video/GENU_LandingPage_IntroAnim_SD.m4v',
			SD_VIDEO_SIZE = { width = 512, height = 384 },
			VIDEO_SCALE = 'LETTERBOX',
			VIDEO_LENGTH = 3033 },
		{
			HD_VIDEO_PATH = 'FRC_Assets/FRC_SplashScreen/Video/FRC_SplashScreen_IdentityVideo_LandscapeHD.m4v',
			HD_VIDEO_SIZE = { width = 1024, height = 768 },
			SD_VIDEO_PATH = 'FRC_Assets/FRC_SplashScreen/Video/FRC_SplashScreen_IdentityVideo_LandscapeSD.m4v',
			SD_VIDEO_SIZE = { width = 512, height = 384 },
			VIDEO_SCALE = 'LETTERBOX',
			VIDEO_LENGTH = 4200 }
	}
};

return FRC_SplashScreen_Settings;
