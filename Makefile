
# ----------------------------------------------------------------------------
#
# Configs
#
# ----------------------------------------------------------------------------

HOSTCC         := cc # unused
CROSS_COMPILE  :=
CC             := $(CROSS_COMPILE)$(HOSTCC)
LD             := $(CC)
ARCH           := $(shell $(CC) -dumpmachine) # unused

LUAVER         := 5.4
LUA            := lua$(LUAVER)

CFLAGS         += -std=c99
LDFLAGS        += -lm -lc

BUILD_DIR      := build

# -- internals ---------------------------------------------------------------

SRC_C_DIR      := src
SRCS_C         := $(wildcard $(SRC_C_DIR)/*.c)

SRC_LUA_DIR    := $(SRC_C_DIR)/lua
SRCS_LUA       := $(wildcard $(SRC_C_DIR)/**/*.lua)

TLUA_H         := osbpb-lua.h
BUILD_INC_DIR  := $(BUILD_DIR)/include
BUILD_TLUA     := $(BUILD_DIR)/osbpb.lua
BUILD_TLUA_H   := $(BUILD_INC_DIR)/$(TLUA_H)

DEPS_GEN       := $(BUILD_TLUA_H)

TOOL_DIR       := tool
TOOLS          := $(wildcard $(TOOL_DIR)/*)

TARGET         := $(BUILD_DIR)/osbpb

# -- auto generated ----------------------------------------------------------

CONFIG         := CC LD LUA CFLAGS LDFLAGS
CONFIG_CDIR    := # cache dir
CONFIG_CACHE   :=
CONFIG_CONTENT :=
SRCS           :=
OBJS           :=
REBUILD_DEPS   :=


# ----------------------------------------------------------------------------
#
# Dependencies
#
# ----------------------------------------------------------------------------

# -- import auto-generated things --------------------------------------------

CFLAGS         += -I$(BUILD_INC_DIR)
REBUILD_DEPS   += $(wildcard $(SRC_C_DIR)/*.h)
REBUILD_DEPS   += $(BUILD_TLUA_H)

# -- external libraries ------------------------------------------------------

LUA_ROOT        = lib/lua
SRCS_C         += $(LUA_ROOT)/onelua.c
CFLAGS         += -I$(LUA_ROOT) -DMAKE_LIB

# -- config cache ------------------------------------------------------------

CONFIG_CONTENT := $(foreach conf,$(CONFIG),$(strip $(conf)=$($(conf))))
$(info [CONFIG] $(CONFIG_CONTENT))

CONFIG_CDIR     = $(BUILD_DIR)/.config
CONFIG_NAME    := $(shell echo $(CONFIG_CONTENT) | md5sum | cut -d' ' -f1)
CONFIG_CACHE   := $(CONFIG_CDIR)/$(CONFIG_NAME).txt
$(info [CONFIG] @ $(CONFIG_CACHE))

REBUILD_DEPS   += $(CONFIG_CACHE)


# ----------------------------------------------------------------------------
#
# Rules
#
# ----------------------------------------------------------------------------

OBJS           += $(patsubst %, $(BUILD_DIR)/%, $(SRCS_C:.c=.o))

all: $(TARGET)

$(TARGET): $(OBJS) $(REBUILD_DEPS)
	$(LD) -o $@ $(OBJS) $(LDFLAGS)

# -- misc --------------------------------------------------------------------

$(BUILD_DIR):
	@mkdir $(BUILD_DIR)

$(BUILD_INC_DIR): | $(BUILD_DIR)
	@mkdir $(BUILD_INC_DIR)

$(CONFIG_CACHE): Makefile | $(BUILD_INC_DIR)
	@rm -rf $(CONFIG_CDIR)
	@mkdir $(CONFIG_CDIR)
	@echo $(CONFIG_CONTENT) > $(CONFIG_CACHE)

$(BUILD_DIR)/%.o: %.c $(DEPS_GEN) $(CONFIG_CACHE) | $(BUILD_DIR)
	-@mkdir -p $(@D)
	$(CC) -c -o $@ $(CFLAGS) $<

$(BUILD_TLUA_H): $(TOOLS) $(SRCS_LUA) $(TOOLS) | $(BUILD_INC_DIR)
	$(LUA) $(TOOL_DIR)/onec.lua -o $(BUILD_TLUA) -m osbpb.init -C $(SRC_LUA_DIR) .
	$(LUA) $(TOOL_DIR)/bin2c.lua -o $@ -n osbpb_lua $(BUILD_TLUA)

.PHONY: all

