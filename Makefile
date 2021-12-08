#!/usr/bin/make -f
# Makefile for DISTRHO Plugins #
# ---------------------------- #
# Created by falkTX
#

include dpf/Makefile.base.mk

all: cardinal carla deps dgl plugins gen resources

# --------------------------------------------------------------
# Build config

PREFIX  ?= /usr/local
DESTDIR ?=
SYSDEPS ?= false

# --------------------------------------------------------------
# Carla config

CARLA_EXTRA_ARGS = \
	HAVE_FFMPEG=false \
	HAVE_FLUIDSYNTH=false \
	HAVE_LIBMAGIC=false \
	HAVE_SNDFILE=false

ifneq ($(MACOS),true)
CARLA_EXTRA_ARGS += USING_JUCE=false
CARLA_EXTRA_ARGS += USING_JUCE_GUI_EXTRA=false
endif

# --------------------------------------------------------------
# Check for system-wide dependencies

ifeq ($(SYSDEPS),true)

ifneq ($(shell pkg-config --exists jansson && echo true),true)
$(error jansson dependency not installed/available)
endif
ifneq ($(shell pkg-config --exists libarchive && echo true),true)
$(error libarchive dependency not installed/available)
endif
ifneq ($(shell pkg-config --exists samplerate && echo true),true)
$(error samplerate dependency not installed/available)
endif
ifneq ($(shell pkg-config --exists speexdsp && echo true),true)
$(error speexdsp dependency not installed/available)
endif

endif

# --------------------------------------------------------------
# Check for X11+OpenGL dependencies (unless headless build)

ifneq ($(HAIKU_OR_MACOS_OR_WINDOWS),true)
ifneq ($(WASM),true)
ifneq ($(HEADLESS),true)

ifneq ($(HAVE_OPENGL),true)
$(error X11 dependency not installed/available)
endif
ifneq ($(HAVE_X11),true)
$(error X11 dependency not installed/available)
endif
ifneq ($(HAVE_XEXT),true)
$(warning Xext dependency not installed/available)
endif
ifneq ($(HAVE_XRANDR),true)
$(warning Xrandr dependency not installed/available)
endif

else

CARLA_EXTRA_ARGS += HAVE_OPENGL=false
CARLA_EXTRA_ARGS += HAVE_X11=false
CARLA_EXTRA_ARGS += HAVE_XEXT=false
CARLA_EXTRA_ARGS += HAVE_XRANDR=false

endif
endif
endif

# --------------------------------------------------------------

cardinal: carla deps dgl plugins
	$(MAKE) all -C src $(CARLA_EXTRA_ARGS)

carla:
	$(MAKE) static-plugin -C carla $(CARLA_EXTRA_ARGS) \
		CAN_GENERATE_LV2_TTL=false \
		STATIC_PLUGIN_TARGET=true

deps:
ifeq ($(SYSDEPS),true)
	$(MAKE) quickjs -C deps
else
	$(MAKE) all -C deps
endif

dgl:
ifneq ($(HEADLESS),true)
	$(MAKE) -C dpf/dgl opengl USE_NANOVG_FBO=true
endif

plugins: deps
	$(MAKE) all -C plugins

resources: cardinal
	$(MAKE) resources -C plugins

ifneq ($(CROSS_COMPILING),true)
gen: cardinal resources dpf/utils/lv2_ttl_generator
ifeq ($(AS_LV2),true)
	@$(CURDIR)/dpf/utils/generate-ttl.sh
endif

dpf/utils/lv2_ttl_generator:
ifeq ($(AS_LV2),true)
	$(MAKE) -C dpf/utils/lv2-ttl-generator
endif

else
gen:
endif

# --------------------------------------------------------------

clean:
	$(MAKE) distclean -C carla
	$(MAKE) clean -C deps
	$(MAKE) clean -C dpf/dgl
	$(MAKE) clean -C dpf/utils/lv2-ttl-generator
	$(MAKE) clean -C plugins
	$(MAKE) clean -C src
	rm -rf bin build

# --------------------------------------------------------------

install:
	install -d $(DESTDIR)$(PREFIX)/bin
	install -d $(DESTDIR)$(PREFIX)/lib/lv2
	install -d $(DESTDIR)$(PREFIX)/lib/vst
	install -d $(DESTDIR)$(PREFIX)/lib/vst3
	install -d $(DESTDIR)$(PREFIX)/share/Cardinal

	cp -rL bin/Cardinal.lv2  $(DESTDIR)$(PREFIX)/lib/lv2/
	cp -rL bin/Cardinal.vst3 $(DESTDIR)$(PREFIX)/lib/vst3/

	cp -rL bin/CardinalFX.lv2  $(DESTDIR)$(PREFIX)/lib/lv2/
	cp -rL bin/CardinalFX.vst  $(DESTDIR)$(PREFIX)/lib/vst/
	cp -rL bin/CardinalFX.vst3 $(DESTDIR)$(PREFIX)/lib/vst3/

	cp -rL bin/CardinalSynth.lv2  $(DESTDIR)$(PREFIX)/lib/lv2/
	cp -rL bin/CardinalSynth.vst  $(DESTDIR)$(PREFIX)/lib/vst/
	cp -rL bin/CardinalSynth.vst3 $(DESTDIR)$(PREFIX)/lib/vst3/

	install -m 755 bin/Cardinal$(APP_EXT) $(DESTDIR)$(PREFIX)/bin/
	install -m 755 bin/CardinalFX$(APP_EXT) $(DESTDIR)$(PREFIX)/bin/
	install -m 755 bin/CardinalSynth$(APP_EXT) $(DESTDIR)$(PREFIX)/bin/
	cp -rL bin/Cardinal.lv2/resources/* $(DESTDIR)$(PREFIX)/share/Cardinal/

# --------------------------------------------------------------

.PHONY: carla deps plugins
