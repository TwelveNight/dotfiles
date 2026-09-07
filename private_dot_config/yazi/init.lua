-- Persistent bookmarks
require("whoosh"):setup({
	jump_notify = true,
	bookmarks_path = os.getenv("HOME") .. "/.config/yazi/plugins/whoosh.yazi/bookmarks",
	home_alias_enabled = true,
	history_size = 10,
})

-- Multiple processes at the same time
require("session"):setup({
	sync_yanked = true,
})

-- full-border
require("full-border"):setup()
