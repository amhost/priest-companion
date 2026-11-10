#!/usr/bin/env python3
"""Run syntax and offline behavioral checks using the installed Lua shared library.

No Python packages are required. This checks ordinary Lua logic and mocked UI
behavior; it does not emulate Blizzard's secure execution or validate WoW.
"""
from __future__ import annotations
import ctypes
import ctypes.util
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
library = ctypes.util.find_library("lua5.4")
if not library:
    raise SystemExit("liblua5.4 is required for this optional offline test runner.")
lua = ctypes.CDLL(library)
lua.luaL_newstate.restype = ctypes.c_void_p
lua.luaL_openlibs.argtypes = [ctypes.c_void_p]
lua.luaL_loadfilex.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_char_p]
lua.luaL_loadfilex.restype = ctypes.c_int
lua.lua_pcallk.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_longlong, ctypes.c_void_p]
lua.lua_pcallk.restype = ctypes.c_int
lua.lua_tolstring.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.POINTER(ctypes.c_size_t)]
lua.lua_tolstring.restype = ctypes.c_char_p
lua.lua_settop.argtypes = [ctypes.c_void_p, ctypes.c_int]
lua.lua_pushstring.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
lua.lua_setglobal.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
lua.lua_close.argtypes = [ctypes.c_void_p]

def message(state):
    value = lua.lua_tolstring(state, -1, None)
    return value.decode("utf-8", "replace") if value else "Lua failure without readable error"

state = lua.luaL_newstate()
if not state:
    raise SystemExit("Could not allocate Lua state")
try:
    lua.luaL_openlibs(state)
    files = sorted((ROOT / "PriestCompanion").rglob("*.lua"))
    for path in files:
        if lua.luaL_loadfilex(state, str(path).encode(), None):
            raise RuntimeError(f"Syntax failure in {path.relative_to(ROOT)}: {message(state)}")
        lua.lua_settop(state, 0)
    print(f"PASS: syntax for {len(files)} addon Lua files (Lua 5.4 parser)", flush=True)
    lua.lua_pushstring(state, str(ROOT).encode())
    lua.lua_setglobal(state, b"TEST_ROOT")
    suite = ROOT / "tests" / "run.lua"
    if lua.luaL_loadfilex(state, str(suite).encode(), None):
        raise RuntimeError(message(state))
    if lua.lua_pcallk(state, 0, 0, 0, 0, None):
        raise RuntimeError(message(state))
finally:
    lua.lua_close(state)
