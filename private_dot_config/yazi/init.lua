-- -- Bookmarks
require("bookmarks"):setup({
	save_last_directory = true,
	persist = "all",
	notify = {
		enable = false,
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
