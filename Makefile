DESTDIR ?= dist
ZIGS ?= $(foreach lab,$(wildcard */main.zig),$(lab:/main.zig=))
CPPS ?= $(foreach lab,$(wildcard */main.cc),$(lab:/main.cc=))
OUTS := $(foreach lab,$(ZIGS) $(CPPS),$(DESTDIR)/bin/$(lab))

CC ?= gcc
CXX ?= g++
CFLAGS ?= -pedantic-errors -Wall -Wextra -Werror -Ofast
CXXFLAGS ?= $(CFLAGS) -std=c++20

### Phony ######################################################################

.PHONY: all clean clean-%

all: $(DESTDIR)

clean: clean-dist clean-build

clean-dist:
	@rm --verbose --recursive --force $(DESTDIR)

clean-build:
	@rm --verbose --recursive --force zig-cache

### Build general ##############################################################

$(DESTDIR): $(OUTS)

### Build and run code #########################################################

define mk-zig =
$(DESTDIR)/bin/$(1): $(1)/main.zig
	zig build -p $(DESTDIR) -Dlab=$(1)

.PHONY: run-$(1)
run-$(1): $(DESTDIR)/bin/$(1)
	zig build run -p $(DESTDIR) -Dlab=$(1)

.PHONY: test-$(1)
test-$(1): $(DESTDIR)/bin/$(1)
	zig build test -p $(DESTDIR) -Dlab=$(1)
endef

define mk-cpp =
$(DESTDIR)/bin/$(1): | $(DESTDIR)/bin $(1)/main.cc
	$(CXX) $(CXXFLAGS) -o $(DESTDIR)/bin/$(1) $(1)/main.cc

.PHONY: run-$(1)
run-$(1): $(DESTDIR)/bin/$(1)
	./$(DESTDIR)/bin/$(1)
endef

$(foreach lab,$(ZIGS),$(eval $(call mk-zig,$(lab))))

$(foreach lab,$(CPPS),$(eval $(call mk-cpp,$(lab))))
