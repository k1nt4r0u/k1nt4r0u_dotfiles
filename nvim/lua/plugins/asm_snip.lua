local ls = require("luasnip")
local fmt = require("luasnip.extras.fmt").fmt
local s = ls.snippet
local i = ls.insert_node

ls.add_snippets("asm", {
  s("asm", fmt([[
section .data
	

section .bss
	

section .text
	global _start

_start:
	{}
	mov rax, 60
	xor rdi, rdi
	syscall
  ]], {
    i(0)
  }))
})
