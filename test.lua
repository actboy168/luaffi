package.cpath = "build/msvc/bin/?.dll"
if _VERSION == "Lua 5.4" then
    debug.setcstacklimit(1000)
end
dofile "src/test.lua"
