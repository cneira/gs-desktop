/* Switcher
 *  
 * Copyright (C) 2005 Free Software Foundation, Inc.
 *
 * Author: Gregory John Casamento <greg_casamento@yahoo.com>
 * Date: August 2005
 *
 * This file is part of the GNUstep Application Project
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02111 USA.
 */

#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>

#include "Switcher.h"

#include "GNUstepGUI/GSDisplayServer.h"
#include "GNUstepGUI/GSServicesManager.h"
#include "GNUstepGUI/GSInfoPanel.h"
#include "GNUstepGUI/GSVersion.h"

@implementation Switcher

- (id)init
{	
    if((self = [super init]) != nil)
    {
	// any addition setup goes here...
	NSLog(@"Switcher loaded");
	return nil;
    }
    return self;
}

@end

// declare...
@interface NSAppIconView : NSView
- (void) setImage: (NSImage *)anImage;
@end

// category...
@interface NSAppIconView (OverrideMouseDown)
@end

@implementation NSAppIconView (OverrideMouseDown)
- (void) mouseDown: (NSEvent*)theEvent
{
  if ([theEvent clickCount] >= 2)
    {
      if ([NSApp isHidden] == NO)
	{
          [NSApp hide: self];
	  [NSApp unhide: self];

	  if ([NSApp keyWindow] != nil)
	  {
	      [[NSApp keyWindow] orderFront: self];
	  }
	  else if ([NSApp mainWindow] != nil)
	  {
	      [[NSApp mainWindow] makeKeyAndOrderFront: self];
	  }
	  else
	  {
	      /* We need give input focus to some window otherwise we'll 
		 never get keyboard events. FIXME: doesn't work. */
	      NSWindow *menu_window= [[NSApp mainMenu] window];
	      NSDebugLLog(@"Focus", @"No key on activation - make menu key");
	      [GSServerForWindow(menu_window) setinputfocus:
				    [menu_window windowNumber]];
	  }
	}
       
      [NSApp unhide: self];
    }
  else
    {
      NSPoint	lastLocation;
      NSPoint	location;
      unsigned	eventMask = NSLeftMouseDownMask | NSLeftMouseUpMask
	| NSPeriodicMask | NSOtherMouseUpMask | NSRightMouseUpMask;
      NSDate	*theDistantFuture = [NSDate distantFuture];
      BOOL	done = NO;

      lastLocation = [theEvent locationInWindow];
      [NSEvent startPeriodicEventsAfterDelay: 0.02 withPeriod: 0.02];

      while (!done)
	{
	  theEvent = [NSApp nextEventMatchingMask: eventMask
					 untilDate: theDistantFuture
					    inMode: NSEventTrackingRunLoopMode
					   dequeue: YES];
	
	  switch ([theEvent type])
	    {
	      case NSRightMouseUp:
	      case NSOtherMouseUp:
	      case NSLeftMouseUp:
	      /* any mouse up means we're done */
		done = YES;
		break;
	      case NSPeriodic:
		location = [_window mouseLocationOutsideOfEventStream];
		if (NSEqualPoints(location, lastLocation) == NO)
		  {
		    NSPoint	origin = [_window frame].origin;

		    origin.x += (location.x - lastLocation.x);
		    origin.y += (location.y - lastLocation.y);
		    [_window setFrameOrigin: origin];
		  }
		break;

	      default:
		break;
	    }
	}
      [NSEvent stopPeriodicEvents];
    }
}                                                        
@end

