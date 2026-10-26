#!/usr/bin/env python3
"""Run fixture Lua using the existing shared library; no install/build/IPC."""
import ctypes
import json
import sys
lib = ctypes.CDLL('/usr/lib/x86_64-linux-gnu/liblua5.4.so.0')
lib.luaL_newstate.restype = ctypes.c_void_p
lib.luaL_openlibs.argtypes = [ctypes.c_void_p]
lib.luaL_loadstring.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
lib.luaL_loadstring.restype = ctypes.c_int
lib.lua_pcallk.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_longlong, ctypes.c_void_p]
lib.lua_pcallk.restype = ctypes.c_int
lib.lua_tolstring.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_void_p]
lib.lua_tolstring.restype = ctypes.c_char_p
lib.lua_close.argtypes = [ctypes.c_void_p]
state = lib.luaL_newstate()
lib.luaL_openlibs(state)
args = ','.join('[' + str(i) + ']=' + json.dumps(s) for i, s in enumerate(sys.argv[1:]))
code = '''
os.execute=function(command) error('Forbidden OS execution in config fixture: '..command) end
local real_popen=io.popen
io.popen=function(command,...)
 assert(command:match('^readlink %-e /dev/dri/by%-path/pci%-[%x:%.]+%-card 2>/dev/null$'), 'Forbidden popen in config fixture: '..command)
 return real_popen(command,...)
end
arg={''' + args + '''}
dofile(arg[0])
'''
try:
    status = lib.luaL_loadstring(state, code.encode())
    if status == 0:
        status = lib.lua_pcallk(state, 0, -1, 0, 0, None)
    if status:
        print(lib.lua_tolstring(state, -1, None).decode(errors='replace'), file=sys.stderr)
finally:
    lib.lua_close(state)
sys.exit(status)
