local lm = require "luamake"

lm.arch = "x86"
--lm.mode = "debug"

local function dynasm(output, input, flags)
    lm:runlua("dynasm_" .. output) {
        script = "src/dynasm/dynasm.lua",
        args = {
            "-LNE",
            flags or {},
            "-o", "$out",
            "$in",
        },
        inputs = "src/" .. input,
        outputs = "src/" .. output,
    }
end

dynasm('call_x86.h', 'call_x86.dasc', { '-D', 'X32WIN' })
dynasm('call_x64.h', 'call_x86.dasc', { '-D', 'X64' })
dynasm('call_x64win.h', 'call_x86.dasc', { '-D', 'X64', '-D', 'X64WIN' })
dynasm('call_arm.h', 'call_arm.dasc')

lm:phony {
    inputs = {
        "src/call_x86.h",
        "src/call_x64.h",
        "src/call_x64win.h",
        "src/call_arm.h",
    },
    outputs = "src/call.c",
}

lm:lua_dll "ffi" {
    sources = {
        "src/*.c",
        "!src/test.c",
    }
}

lm:dll "ffi_test_cdecl" {
    sources = "src/test.c",
    defines = "_CRT_SECURE_NO_WARNINGS",
}

if lm.arch == "x86" then
    lm:dll "ffi_test_stdcall" {
        sources = "src/test.c",
        defines = "_CRT_SECURE_NO_WARNINGS",
        flags = "/Gz",
    }
    lm:dll "ffi_test_fastcall" {
        sources = "src/test.c",
        defines = "_CRT_SECURE_NO_WARNINGS",
        flags = "/Gr",
    }
end

lm:dll 'lua54' {
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
lm:exe 'lua' {
    deps = "lua54",
    defines = "_WIN32_WINNT=0x0601",
    sources = "lua/lua.c",
}
lm:build "test" {
    args = { "$bin/lua.exe", "src/test.lua" },
    deps = {
        "lua",
        "ffi",
        "ffi_test_cdecl",
        lm.arch == "x86" and "ffi_test_stdcall",
        lm.arch == "x86" and "ffi_test_fastcall",
    }
}
