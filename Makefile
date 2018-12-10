include $(THEOS)/makefiles/common.mk

export TARGET = iphone:clang:11.2:8.0
export ARCHS = arm64 armv7

TWEAK_NAME = Downloadally
Downloadally_CFLAGS = -fobjc-arc
Downloadally_FILES = Tweak.xm
include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 TikTok"
