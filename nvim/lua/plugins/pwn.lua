local ls = require("luasnip")
local fmt = require("luasnip.extras.fmt").fmt
local s = ls.snippet
local i = ls.insert_node

ls.add_snippets("python", {
  s("pwn", fmt([[
#!/usr/bin/python3
from pwn import *

context.terminal = ['alacritty', '-e']
context.binary = exe = ELF("./")
#libc = ELF("{}")
context.arch = "{}"
script = '''

'''

#p = gdb.debug(exe.path, gdbscript = script)
#p = remote("{}", {})
#p = process(exe.path)

def slog(name, addr):
	return success(": ".join([name, hex(addr)]))

def s(payload):
    sleep({})
    p.send(payload)

def sa(info, payload):
	p.sendafter(info, payload)

def sl(payload):
    sleep({})
    p.sendline(payload)

def sla(info, payload):
    p.sendlineafter(info, payload)

def ru(payload):
    return p.recvuntil(payload)

def rn(payload):
    return p.recvn(payload)

def rln():
    return p.recvline()

p.interactive()
  ]], {
    i(1, "./libc.so.6"), 
    i(2, "amd64"),
    i(3, "host"),
    i(4, "1337"),
    i(5, "1.5"),
    i(6, "1.5")
  }))
})
