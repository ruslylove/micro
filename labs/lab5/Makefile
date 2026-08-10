AVRA := avra

SRC_DIR := src
BUILD_DIR := build

SOURCES := $(wildcard $(SRC_DIR)/*.s)
HEXES := $(patsubst $(SRC_DIR)/%.s,$(BUILD_DIR)/%.hex,$(SOURCES))

.PHONY: all clean

all: $(HEXES)

$(BUILD_DIR)/%.hex: $(SRC_DIR)/%.s | $(BUILD_DIR)
	$(AVRA) -o $@ -e $(BUILD_DIR)/$*.eep.hex -d $(BUILD_DIR)/$*.obj $<

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

clean:
	rm -f $(BUILD_DIR)/*.hex $(BUILD_DIR)/*.eep.hex $(BUILD_DIR)/*.obj
