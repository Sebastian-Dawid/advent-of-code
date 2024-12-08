.PHONY: all zig asm clean

SHELL := zsh

all: zig asm

zig:
	@pushd -q zig;\
	zig build run -- $(ARGS);\
	popd -q

asm:
	$(MAKE) -f asm/Makefile run

clean:
	$(MAKE) -f asm/Makefile clean
	@rm -rf zig/zig-out
