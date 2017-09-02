include $(THEOS)/makefiles/common.mk

export SYSROOT = $(THEOS)/sdks/iPhoneOS10.1.sdk

TWEAK_NAME = Downloadally
Downloadally_CFLAGS = -fobjc-arc
Downloadally_FILES = Tweak.xm
include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
