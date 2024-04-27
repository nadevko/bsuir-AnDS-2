DESTDIR ?= dist
LABS ?= $(foreach lab,$(filter-out zig-cache/,$(filter-out dist/,$(sort $(dir $(wildcard */))))),$(lab:/=))

OUTS := $(foreach lab,$(LABS),$(DESTDIR)/bin/$(lab))

### Phony ######################################################################

.PHONY: all run-% test-% clean clean-%

all: $(DESTDIR)

clean: clean-dist clean-build

clean-dist:
	@rm --verbose --recursive --force $(DESTDIR)

clean-build:
	@rm --verbose --recursive --force zig-cache

### Build general ##############################################################

$(DESTDIR): $(OUTS)

### Build and run code #########################################################

define mk-lab =
$(DESTDIR)/bin/$(1): $(1)/main.zig
	zig build -p $(DESTDIR) -Dlab=$(1)

.PHONY: run-$(1)
run-$(1):
	zig build run -p $(DESTDIR) -Dlab=$(1)

.PHONY: test-$(1)
test-$(1):
	zig build test -p $(DESTDIR) -Dlab=$(1)
endef

$(foreach lab,$(LABS),$(eval $(call mk-lab,$(lab))))
