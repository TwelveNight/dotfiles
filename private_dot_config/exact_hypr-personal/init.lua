-- Shared package bootstrap; adapters pass the installed package directory.
local root = assert(..., "shared personal package root is required")
package.path = root .. "/custom/?.lua;" .. package.path
return require("hypr_personal")
