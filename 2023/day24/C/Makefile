DB := lldb
SHELL := sh
CC := clang

SRC_DIR = src
BUILD_DIR = build
BINARY_NAME = main
ARGS =

SRCS_FULL = $(shell find $(SRC_DIR) -maxdepth 1 -name '*.c')
SRCS = $(SRCS_FULL:$(SRC_DIR)/%=%)
OBJS = $(SRCS:%=$(BUILD_DIR)/%.o)

LD_FLAGS = -lgsl

.DEFAULT_GOAL := help

$(BUILD_DIR)/$(BINARY_NAME): $(OBJS)
	$(CC) $(OBJS) -o $(BUILD_DIR)/$(BINARY_NAME) $(LD_FLAGS)

$(BUILD_DIR)/%.o: $(SRC_DIR)/%
	@mkdir -p $(BUILD_DIR)
	$(CC) -g $(CFLAGS) -c $< -o $@

.PHONY: clean run debug help

clean:
	rm -rf $(BUILD_DIR)

run: $(BUILD_DIR)/$(BINARY_NAME)
	$(BUILD_DIR)/$(BINARY_NAME) $(ARGS)

debug: $(BUILD_DIR)/$(BINARY_NAME)
	$(DB) $(BUILD_DIR)/$(BINARY_NAME)

help:
	@echo "Usage: make { clean | run | debug | help }"
	@echo "    clean - Remove build artifacts"
	@echo "    run   - Compile, link and run the program"
	@echo "    debug - Compile, link and run the program in the debugger"
	@echo "            The default debugger is 'lldb', but can be changed"
	@echo "            by setting 'make debug DB=<your preferred debugger>'"
	@echo "    help  - Show this message"
