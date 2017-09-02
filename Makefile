include $(THEOS)/makefiles/common.mk

export SYSROOT = $(THEOS)/sdks/iPhoneOS10.1.sdk

TWEAK_NAME = Downloadally
downloadally_CFLAGS = -fobjc-arc
downloadally_FILES = Tweak.xm
include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
