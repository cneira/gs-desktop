/* main.m: Main Body of GNUstep Ink demo application

   Copyright (C) 2000 Free Software Foundation, Inc.

   Adaptation:  Marko Riedel <mriedel@neuearbeit.de>
   Date: May 2002, June 2007

   Author:  Fred Kiefer <fredkiefer@gmx.de>
   Date: 2000
   
   This file is part of GNUstep.
   
   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.
   
   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.
   
   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

#import "Document.h"


@interface Controller : NSObject

- (void) applicationWillFinishLaunching: (NSNotification *)not;
- (void) applicationDidFinishLaunching: (NSNotification *)not;

- (BOOL) applicationShouldOpenUntitledFile:(NSApplication *)sender;
@end

@implementation Controller : NSObject 

- (void) applicationWillFinishLaunching: (NSNotification *)not
{
  CREATE_AUTORELEASE_POOL(pool);
  NSMenu *menu;
  NSMenu *info;
  NSMenu *action;
  NSMenu *file;
  NSMenu *services;
  NSMenu *windows;

  //	Create the app menu
  menu = [NSMenu new];

  [menu addItemWithTitle: @"Info"
		  action: NULL
	   keyEquivalent: @""];

  [menu addItemWithTitle: @"File"
		  action: NULL
	   keyEquivalent: @""];

  [menu addItemWithTitle: @"Action"
		  action: NULL
	   keyEquivalent: @""];

  [menu addItemWithTitle: @"Windows"
		  action: NULL
	   keyEquivalent: @""];

  [menu addItemWithTitle: @"Services"
		  action: NULL
	   keyEquivalent: @""];

  [menu addItemWithTitle: @"Hide"
		  action: @selector(hide:)
	   keyEquivalent: @"h"];

  [menu addItemWithTitle: @"Quit"
		  action: @selector(terminate:)
	   keyEquivalent: @"q"];

  // Create the info submenu
  info = [NSMenu new];
  [menu setSubmenu: info
	   forItem: [menu itemWithTitle: @"Info"]];

  [info addItemWithTitle: @"Info Panel..."
	          action: @selector(orderFrontStandardInfoPanel:)
	   keyEquivalent: @""];
/*  
  [info addItemWithTitle: @"Preferences..."
		  action: NULL
	   keyEquivalent: @""];
*/
  [info addItemWithTitle: @"Help"
		  action: @selector (orderFrontHelpPanel:)
	   keyEquivalent: @"?"];
  RELEASE(info);

  // Create the action submenu
  action = [[Document actionMenu] copy];
  [menu setSubmenu: action
	   forItem: [menu itemWithTitle: @"Action"]];

  // Create the file submenu
  file = [NSMenu new];
  [menu setSubmenu: file
	   forItem: [menu itemWithTitle: @"File"]];

  [file addItemWithTitle: @"Open Document"
		  action: @selector(openDocument:)
	   keyEquivalent: @"o"];

  [file addItemWithTitle: @"Save"
	          action: @selector(saveDocument:)
	   keyEquivalent: @"s"];

  [file addItemWithTitle: @"Save To..."
	          action: @selector(saveDocumentTo:)
	   keyEquivalent: @"t"];

  [file addItemWithTitle: @"Save All"
	action: @selector(saveDocumentAll:)
	   keyEquivalent: @""];

  [file addItemWithTitle: @"Revert to Saved"
		  action: @selector(revertDocumentToSaved:)
	   keyEquivalent: @"u"];

  [file addItemWithTitle: @"Close"
		  action: @selector(close)
	   keyEquivalent: @""];

  RELEASE(file);

  [menu setSubmenu: [[Document actionMenu] copy]
	forItem: [menu itemWithTag: MENU_ACTION]];

  // Create the windows submenu
  windows = [NSMenu new];
  [menu setSubmenu: windows
	   forItem: [menu itemWithTitle: @"Windows"]];

  [windows addItemWithTitle: @"Arrange"
		     action: @selector(arrangeInFront:)
	      keyEquivalent: @""];

  [windows addItemWithTitle: @"Miniaturize"
		     action: @selector(performMiniaturize:)
	      keyEquivalent: @"m"];

  [windows addItemWithTitle: @"Close"
		     action: @selector(performClose:)
	      keyEquivalent: @"w"];

  [NSApp setWindowsMenu: windows];
  RELEASE(windows);

  // Create the service submenu
  services = [NSMenu new];
  [menu setSubmenu: services
	   forItem: [menu itemWithTitle: @"Services"]];

  [NSApp setServicesMenu: services];
  RELEASE(services);

  [NSApp setMainMenu: menu];
  RELEASE(menu);

  RELEASE(pool);
}

- (void) applicationDidFinishLaunching: (NSNotification *)not;
{
  NSDocumentController *dc = 
    [NSDocumentController sharedDocumentController];

  // Make the DocumentController the delegate of the application.
  [NSApp setDelegate: dc];
}

- (BOOL) applicationShouldOpenUntitledFile:(NSApplication *)sender
{
  return NO;
}

@end

int main(int argc, const char **argv, char** env)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  [NSApplication sharedApplication];
  [NSApp setDelegate: [Controller new]];
  
  return NSApplicationMain(argc, argv);
}
