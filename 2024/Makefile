SHELL := zsh
.DEFAULT_GOAL := new_day

DAYS = $(shell find -maxdepth 1 -type d -path '*day*')
DAY = $(shell date +%d)

.PHONY: new_day day all clean

new_day:
	@if [ ! -d "day$(DAY)" ]; then;\
		mkdir -p day$(DAY);\
		cp -r template/* day$(DAY);\
	fi

day:
	@mkdir -p day$(DAY)
	@cd day$(DAY); \
	make; \
	cd ..

all:
	@for directory in $(DAYS); do \
		cd $$directory; \
		echo "====$$directory===="; \
		make; \
		cd ..; \
	done

clean:
	@for directory in $(DAYS); do \
		cd $$directory; \
		make clean; \
		cd ..; \
	done
