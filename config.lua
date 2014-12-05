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
      -- key = "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAikZx7asRzCUYD10Z+eC7bKfi/8k6K0lLeExLvXxDzT+bpYyiNw1vosV06iQFU3iEam0++7+WqNJkiL4fh1q+JHzy/PwcpWoAOdWlx8BBVeDI+sylfwyK9qW7um1reONb5KTsWyCU8oTmbOxgQNrmojNFwMUyZVkFd7bcGuoIL4CiFy3LpyOAP0cQzrKBJbL0L/aiLpLzlFGpNMQb4B6ogfj/7Cha2ShiX0eSj1iLkbvVHk4fGQgnLZF5EdMxhivKwl8NQtb8HbWec5C1ODkw4yyXcuAvn4LuSAup9xKKl1mkKYEfTCWF5JEkjAI3nKogLi3UnEpQed6AyLCI6SBw0wIDAQAB",
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
