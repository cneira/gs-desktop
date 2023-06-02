#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <AppKit/NSDocument.h>
#import <AppKit/NSDocumentController.h>

#define DOCTYPE  @"jigsaw"

#define DESKTOPEXTRA 150
#define DESKTOPMAX   400

typedef enum {
  MENU_ACTION = 64,
  MENU_SCRAMBLE,
  MENU_VERIFY,
  MENU_SOLVE
} MENU_TAG;


@interface Document : NSDocument
{
    NSImage *image;
    NSMutableArray *clusters;
    NSView *view;
    NSString *nameOfImageFile;
    int px, py;

    BOOL solving, fromImage;
    int done;

    int piece_width, piece_height;
}

+ actionMenu;

- init;
- (void)dealloc;

- (int)setDone:(int)flag;

- (NSSize)withPadding;

- scramble:(id)sender;
- verify:(id)sender;
- solve:(id)sender;

- (NSPoint)offsetInScrollView:(NSScrollView *)scroll;

- (NSMutableArray *)clusters;

- (NSData *)dataRepresentationOfType:(NSString *)aType;
- (BOOL)loadDataRepresentation:(NSData *)data ofType:(NSString *)aType;

- (BOOL)readFromFile:(NSString *)fileName ofType:(NSString *)docType;

- (void)makeWindowControllers;
- (void)windowControllerDidLoadNib:(NSWindowController *)aController;


@end
