
include $(GNUSTEP_MAKEFILES)/common.make

# The application to be compiled
APP_NAME = Jigsaw

# The Objective-C source files to be compiled

Jigsaw_OBJC_FILES = main.m  \
  BTree.m         \
  Document.m      \
  PieceView.m

SHARED_CFLAGS     += -g -Wall

# The Resource files to be copied into the app's resources directory
Jigsaw_RESOURCE_FILES = Icons/*

-include GNUmakefile.preamble

-include GNUmakefile.local

include $(GNUSTEP_MAKEFILES)/application.make

-include GNUmakefile.postamble

