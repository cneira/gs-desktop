OTEST = otest

UNITTEST_API_HEADER_FILES = $($(FRAMEWORK_NAME)_API_HEADER_FILES)
UNITTEST_API_OBJC_FILES = $($(FRAMEWORK_NAME)_API_OBJC_FILES)
UNITTEST_API_DIRECTORY = $($(FRAMEWORK_NAME)_API_DIRECTORY)

$(FRAMEWORK_NAME)_HEADER_FILES += $(UNITTEST_API_HEADERS_FILES)
$(FRAMEWORK_NAME)_OBJC_FILES += $(UNITTEST_API_OBJC_FILES)

$(FRAMEWORK_NAME)_CFLAGS += -I$(UNITTEST_API_DIRECTORY)/.. -I$(UNITTEST_API_DIRECTORY)

$(FRAMEWORK_NAME)_LDFLAGS += -lSenTestingKit -lgnustep-base -lgnustep-gui

all::

before-all:: $(UNITTEST_API_HEADER_FILES) $(UNITTEST_API_OBJC_FILES)

$(UNITTEST_API_HEADER_FILES) $(UNITTEST_API_OBJC_FILES):
	@echo Linking API file '$@'...
	@rm -f $@
	@ln -s $(UNITTEST_API_DIRECTORY)/$@ ./

after-distclean after-clean::
	@echo Cleaning API symlinks...
	@rm -f $(UNITTEST_API_HEADER_FILES) $(UNITTEST_API_OBJC_FILES)

test:: all
	@$(OTEST) -SenTest All $(FRAMEWORK_NAME).framework
