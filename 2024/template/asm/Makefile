DB := lldb
SHELL := sh
ASM := nasm
LD := ld

SRC_DIR ?= $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
BUILD_DIR = $(SRC_DIR)/build
BINARY_NAME = main
ARGS =

SRCS_FULL = $(shell find $(SRC_DIR) -maxdepth 1 -name '*.asm')
SRCS = $(SRCS_FULL:$(SRC_DIR)/%=%)
OBJS = $(SRCS:%=$(BUILD_DIR)/%.o)

.DEFAULT_GOAL := help

$(BUILD_DIR)/$(BINARY_NAME): $(OBJS)
	$(LD) -m elf_x86_64 -static -o $(BUILD_DIR)/$(BINARY_NAME) $(OBJS)

$(BUILD_DIR)/%.o: $(SRC_DIR)/%
	@mkdir -p $(BUILD_DIR)
	$(ASM) -g -f elf64 -F dwarf -o $@ $<

.PHONY: clean run debug help

clean:
	rm -rf $(BUILD_DIR)

run: $(BUILD_DIR)/$(BINARY_NAME)
	$(BUILD_DIR)/$(BINARY_NAME) $(ARGS)

debug: $(BUILD_DIR)/$(BINARY_NAME)
	@echo "settings set target.source-map $$(pwd)/$(SRC_DIR)/$(SRC_DIR) $$(pwd)/$(SRC_DIR)" > .lldb_settings
ifeq ($(DB), lldb)
		$(DB) $(BUILD_DIR)/$(BINARY_NAME) -s .lldb_settings
else
		$(DB) $(BUILD_DIR)/$(BINARY_NAME)
endif
	@rm .lldb_settings

help:
	@echo "Usage: make { clean | run | debug | help }"
	@echo "    clean - Remove build artifacts"
	@echo "    run   - Assemble, link and run the program"
	@echo "    debug - Assemble, link and run the program in the debugger"
	@echo "            The default debugger is 'lldb', but can be changed"
	@echo "            by setting 'make debug DB=<your preferred debugger>'"
	@echo "    help  - Show this message"
