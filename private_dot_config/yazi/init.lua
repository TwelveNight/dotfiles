-- -- Bookmarks
require("bookmarks"):setup({
	last_directory = { enable = true, persist = true },
	persist = "all",
	notify = {
		enable = true,
		timeout = 1,
		message = {
			new = "New bookmark '<key>' -> '<folder>'",
			delete = "Deleted bookmark in '<key>'",
			delete_all = "Deleted all bookmarks",
		},
	},
})

-- Multiple processes at the same time
require("session"):setup({
	sync_yanked = true,
})

-- full-border
require("full-border"):setup()
