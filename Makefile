# 编译 Skynet（submodule）与 pbc protobuf.so

.PHONY: all linux macosx skynet protobuf clean

UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
  PLAT ?= macosx
  SHARED ?= -fPIC -dynamiclib -Wl,-undefined,dynamic_lookup
else
  PLAT ?= linux
  SHARED ?= -fPIC -shared
endif

CC ?= gcc
CFLAGS ?= -O2 -g -Wall

PBC_DIR := vendor/pbc
LUA_INC := skynet/3rd/lua
LUACLIB := skynet/luaclib
PROTOBUF_SO := $(LUACLIB)/protobuf.so

PBC_SRC := $(wildcard $(PBC_DIR)/src/*.c)
PBC_LUA := $(PBC_DIR)/binding/lua53/pbc-lua53.c

all: skynet protobuf

linux macosx:
	$(MAKE) all PLAT=$@

skynet:
	$(MAKE) -C skynet $(PLAT)

protobuf: $(PROTOBUF_SO)

$(PROTOBUF_SO): $(PBC_SRC) $(PBC_LUA)
	mkdir -p $(LUACLIB)
	$(CC) $(CFLAGS) $(SHARED) -o $@ $(PBC_SRC) $(PBC_LUA) \
		-I$(PBC_DIR) -I$(PBC_DIR)/src -I$(LUA_INC)

clean:
	-$(MAKE) -C skynet cleanall
	rm -f $(PROTOBUF_SO)
