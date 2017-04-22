include $(THEOS)/makefiles/common.mk

TWEAK_NAME = downloadally
downloadally_CFLAGS = -fobjc-arc
downloadally_FILES = Tweak.xm
downloadally_TARGET = 9.3:9.3:9.3:9.3
include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
