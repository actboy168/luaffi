local lm = require "luamake"

lm.arch = "x86"
--lm.mode = "debug"

local function dynasm(output, input, flags)
    lm:build ("dynasm_"..output) {
        "$luamake", "lua", "src/dynasm/dynasm.lua",
        "-LNE",
        flags or {},
        "-o", "src/"..output,
        "src/"..input,
        output = "src/"..output,
    }
end

dynasm('call_x86.h', 'call_x86.dasc', {'-D', 'X32WIN'})
dynasm('call_x64.h', 'call_x86.dasc', {'-D', 'X64'})
dynasm('call_x64win.h', 'call_x86.dasc', {'-D', 'X64', '-D', 'X64WIN'})
dynasm('call_arm.h', 'call_arm.dasc')

lm:phony {
    input = {
        "src/call_x86.h",
        "src/call_x64.h",
        "src/call_x64win.h",
        "src/call_arm.h",
    },
    output = "src/call.c",
}

lm:lua_library "ffi" {
    sources = {
        "src/*.c",
        "!src/test.c",
    }
}

lm:shared_library "ffi_test_cdecl" {
    sources = "src/test.c",
    defines = "_CRT_SECURE_NO_WARNINGS",
}

if lm.arch == "x86" then
    lm:shared_library "ffi_test_stdcall" {
        sources = "src/test.c",
        defines = "_CRT_SECURE_NO_WARNINGS",
        flags = "/Gz",
    }
    lm:shared_library "ffi_test_fastcall" {
        sources = "src/test.c",
        defines = "_CRT_SECURE_NO_WARNINGS",
        flags = "/Gr",
    }
end

lm:shared_library 'lua54' {
    sources = {
        "lua/*.c",
        "!lua/ltests.c",
        "!lua/onelua.c",
        "!lua/lua.c",
    },
    defines = {
        "_WIN32_WINNT=0x0601",
        "LUA_BUILD_AS_DLL",
    }
}
lm:executable 'lua' {
    deps = "lua54",
    defines = "_WIN32_WINNT=0x0601",
    sources = "lua/lua.c",
}
lm:build "test" {
    "$bin/lua.exe", "src/test.lua",
    deps = {
        "lua",
        "ffi",
        "ffi_test_cdecl",
        lm.arch == "x86" and "ffi_test_stdcall",
        lm.arch == "x86" and "ffi_test_fastcall",
    }
}
