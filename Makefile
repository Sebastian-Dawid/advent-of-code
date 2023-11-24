SHELL := zsh
.DEFAULT_GOAL := day

DAYS = $(shell find -maxdepth 1 -type d -path '*day*')
DAY = $(shell date +%d)

.PHONY: day all clean

day:
	@mkdir -p day$(DAY)
	@cd day$(DAY); \
	make; \
	cd ..

all:
	@for directory in $(DAYS); do \
		cd $$directory; \
		make; \
		cd ..; \
	done

clean:
	@for directory in $(DAYS); do \
		cd $$directory; \
		make clean; \
		cd ..; \
	done
