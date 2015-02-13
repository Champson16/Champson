application = {
  showRuntimeErrors = true,
	content = {
		width = 768,
		height = 1024,
		scale = "letterBox",
		fps = 60,
    antialias = false,
    imageSuffix = {
      ["@2x"] = 0.5,
      ["@4x"] = 3.0
		}
	},
  launchPad = false,

  license = {
    google = {
      -- key = "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAtABnCZH+DUUjLlehfutjRoPu8mO2B6A50mVofm6EVDq0Itd7yi8eAyLn/NDfAkUCKofsmdG78cLHbVjByKhyw/NhZx0ipccdLnylrrnXsIMVcyoSgWX4qULp0jdObU6zEYsIbZGVqsMxgLJqx1BixFmFE0wiKBj8hzVYZj9UEbcjXyfH/yMUU1/YRoDPTzzwgnweK8oqrSncg3Mb5I/8Z+N9SWd7LHEkaEDnuNVxjjwt8jN+Z5efoqIMgyZYDVQz5PcMhAIcPKUpej//HIHm6ilgZmyt86CcS8w/HnYU1406vKxeidok1P72ES5+1EQG2Q8rKcJZaVTTKYrPxHNNCwIDAQAB",
      -- The "policy" key is optional. Its value can be either "serverManaged" (default) or "strict".
      -- A value of "serverManaged" will query the Google server and cache the results (this is similar to Google's "ServerManagedPolicy").
      -- A value of "strict" will not cache the results, so when there's a network failure, the licensing will fail (this is similar to Google's "StrictPolicy").
      policy = "serverManaged"
    }
  }

    --[[
    -- Push notifications

    notification =
    {
        iphone =
        {
            types =
            {
                "badge", "sound", "alert", "newsstand"
            }
        }
    }
    --]]
}
