/* Copyright (C) 2004 Raffael Herzog
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 *
 * $Id: WrapperDelegate.m 103 2004-08-09 16:30:51Z rherzog $
 * $HeadURL: file:///home/rherzog/Subversion/GNUstep/GSWrapper/tags/release-0.1.0/libGSWrapper/WrapperDelegate.m $
 */

#include <AppKit/AppKit.h>

#include "WrapperDelegate.h"
#include "NSApplication+AppName.h"


@implementation WrapperDelegate

/*
 * application delegate
 */

- (id)init
{
    self = [super init];
    appDidFinishLaunching = NO;
    startupFiles = nil;
    return self;
}

- (void)applicationWillFinishLaunching: (NSNotification*)not
{
}

- (void)applicationDidFinishLaunching: (NSNotification*)not
{
    NSLog(@"LAUNCH");
    appDidFinishLaunching = YES;
    NSRegisterServicesProvider(self, [[NSApp applicationName] stringByDeletingPathExtension]);

    NSString *path = [[NSBundle mainBundle] pathForResource: @"GSWrapper"
                                            ofType: @"plist"];
    properties = RETAIN([NSDictionary dictionaryWithContentsOfFile: path]);

    if ( startupFiles ) {
        mainAction = [self actionForMessage: @"StartOpen"];
    }
    else {
        mainAction = [self actionForMessage: @"Start"];
    }
    [mainAction executeWithFiles: startupFiles];
    if ( !mainAction ) {
        [NSApp terminate: self];
        return;
    }
    if ( ![mainAction task] ) {
        if ( [properties objectForKey: @"Filter"] ) {
            NSLog(@"Service handler configured - continue running for 6os");
            [NSApp performSelector:@selector(terminate:) withObject: self afterDelay:60];
            return;
        }
        else {
            NSLog(@"Main action has no task assigned - exiting");
            [NSApp terminate: self];
            return;
        }
    }


    [[NSNotificationCenter defaultCenter] addObserver: self
                                          selector: @selector(unixAppExited:)
                                          name: (NSTaskDidTerminateNotification)
                                          object: [mainAction task]];
}

- (BOOL)application: (NSApplication*)app
           openFile: (NSString*)file
{
    return [self application: app
                 openFiles: [NSArray arrayWithObject: file]];
}

- (void)openURL:(NSPasteboard *)pboard
       userData:(NSString *)userData
          error:(NSString **)error  {
  NSString *path = [[pboard stringForType:NSStringPboardType] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\n\r"]];

  if (path) {
    [self application:NSApp openFile:path];
  }
}

- (BOOL) application: (NSApplication*)theApp
	     openURL: (NSURL*)aURL
{
    return [self application:NSApp openFile:[aURL description]];
}

- (BOOL)application: (NSApplication*)app
          openFiles: (NSArray*)files
{
    NSLog(@"Open files: %@", files);
    if ( ! appDidFinishLaunching ) {
        startupFiles = RETAIN(files);
        return YES;
    }
    else {
        if ( !openAction ) {
            openAction = [self actionForMessage: @"Open"];
        }
        if ( !openAction ) {
            return NO;
        }

        BOOL retval = [openAction executeWithFiles: files];
        NSTask *task = [openAction task];
        if ( !task ) {
            return retval;
        }
        else {
            [task waitUntilExit];
            if ( [task terminationStatus] ) {
                NSRunCriticalAlertPanel([NSApp applicationName],
                                        [NSString stringWithFormat: @"Script exited with exit code %d",
                                                  [task terminationStatus]],
                                        @"OK", nil, nil);
                return NO;
            }
            else {
                return YES;
            }
        }
    }
}

- (NSApplicationTerminateReply) applicationShouldTerminate:(NSApplication *)sender
{
    if ( mainAction ) {
        [[mainAction task] terminate];
    }
    return YES;
}

- (BOOL) supportsReturnType:(NSString *)rtype forSendType:(NSString *)stype
{
    NSDictionary* info = [[NSBundle mainBundle] infoDictionary];
    NSArray* services = [info valueForKey:@"NSServices"];
    for (NSDictionary* it in services) {
      NSArray* rtypes = [it valueForKey:@"NSReturnTypes"];
      NSArray* stypes = [it valueForKey:@"NSSendTypes"];

      if ([rtypes containsObject:rtype] && [stypes containsObject:stype]) {
        return YES;
      }
    }
    return NO;
} 

- (void) executeFilter: (NSPasteboard *)pboard
              userData: (NSString *)userData
                 error: (NSString **)error
{
    NSString *outDataType = userData;
    NSLog(@"FILTER >>> %@", userData);

    @try {
        RunScriptAction *serviceAction = (RunScriptAction*)[self actionForMessage: @"Filter"];

        if ( !serviceAction ) {
            NSLog(@"no action for Filter");
            return;
        }

        if ( !outDataType ) {
            NSLog(@"no output type for Filter");
            return;
        }
        
        NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
        NSString *ext = @"";
        BOOL found = NO;

        if ( ![files count] ) {
            for (int i = 0; i < [[pboard types] count]; i++) {
                NSString* it = [[pboard types] objectAtIndex: i];
                if ([it hasPrefix:@"NSTypedFileContentsPboardType"]) {
                    ext = [it substringFromIndex:30];
                    if ([self supportsReturnType:outDataType forSendType:it]) {
                      found = YES;
                      break;
                    }
                }
            }

            if ( !found ) {
                *error = @"no filter available for datatype";
                NSLog(@"no filter script for type %@ found", outDataType);
                return;
            }

            NSString *tmpf = [NSString stringWithFormat:@"%@/filter.%lx.%@", NSTemporaryDirectory(), [self hash], ext];
            NSLog(@"creating temp file for %@ in %@", ext, tmpf);
            [pboard readFileContentsType:ext toFile:tmpf];
            files = [NSArray arrayWithObject:tmpf];
        }

        if ( ![files count] ) {
            NSLog(@"no input %@", [pboard types]);
            *error = @"no input files specified";
            return;
        }

        NSDictionary *myenv = [[NSProcessInfo processInfo] environment];
        NSMutableDictionary *env = [NSMutableDictionary dictionaryWithDictionary: myenv];
        [env setObject:outDataType forKey:@"GSFILTER_RETURN_TYPE"];
        [env setObject:ext forKey:@"GSFILTER_SEND_FILE_EXT"];

        NSLog(@"input files %@", files);

        NSTask *task = [serviceAction createTaskWithFiles: files];
        if ( !task ) {
            *error = @"filter error";
            NSLog(@"exit with error");
            return;
        }
        else {
            NSPipe *outPipe = [NSPipe pipe];

            [task setStandardOutput:outPipe];
            [task setEnvironment:env];
            [task launch];

            NSFileHandle *inFh = [outPipe fileHandleForReading];
            NSData *outData = [inFh readDataToEndOfFile];
            [inFh closeFile];

            if (outData) {
                if ([outDataType isEqualToString:@"NSStringPboardType"]) {
                    NSLog(@"provide data as string");
                    NSString *str = [[NSString alloc] initWithData: outData encoding:NSUTF8StringEncoding];
                    [pboard declareTypes: [NSArray arrayWithObject: NSStringPboardType] owner: nil];
                    [pboard setString: str forType: NSStringPboardType];
                }
                else if ([outDataType length] > 0) {
                    NSLog(@"provide data as %@", outDataType);
                    [pboard declareTypes: [NSArray arrayWithObject: outDataType] owner: nil];
                    [pboard setData: outData forType: outDataType];
                }
            }
            NSLog(@"filter done");
        }
    }
    @catch (NSException* ex) {
        NSLog(@"FILTER exception %@", ex);
    }
}


- (void) executeService: (NSPasteboard *)pboard
               userData: (NSString *)userData
                  error: (NSString **)error
{
    
    NSString *inDataType  = [[properties objectForKey: userData] objectForKey: @"SendType"];
    NSString *outDataType = [[properties objectForKey: userData] objectForKey: @"ReturnType"];

    NSLog(@"SERVICE >>> %@ %@ %@", userData, inDataType, outDataType);

    RunScriptAction *serviceAction = (RunScriptAction*)[self actionForMessage: userData];

    if ( !serviceAction ) {
        NSLog(@"no action for %@", userData);
        return;
    }
    
    NSArray *files = [NSArray array];
    NSData *inData = nil;
    if ([inDataType isEqualToString:@"NSStringPboardType"]) {
        NSLog(@"input string");
        inData = [pboard dataForType: NSStringPboardType];
    }
    else if ([inDataType isEqualToString:@"NSFilenamesPboardType"]) {
        files = [pboard propertyListForType:NSFilenamesPboardType];
        NSLog(@"input files %@", files);
    }

    NSTask *task = [serviceAction createTaskWithFiles: files];
    if ( !task ) {
        NSLog(@"exit with error");
        return;
    }
    else {
        NSPipe *outPipe = [NSPipe pipe];

        [task setStandardOutput:outPipe];

        if (inData) {
            NSPipe *inPipe = [NSPipe pipe];
            [task setStandardInput:inPipe];
            NSFileHandle *outFh = [inPipe fileHandleForWriting];
            [outFh writeData:inData];
            [outFh closeFile];
        }

        [task launch];

        NSFileHandle *inFh = [outPipe fileHandleForReading];
        NSData *outData = [inFh readDataToEndOfFile];
        [inFh closeFile];

        if (outData) {
            if ([outDataType isEqualToString:@"NSStringPboardType"]) {
                NSLog(@"provide data as string");
                NSString *str = [[NSString alloc] initWithData: outData encoding:NSUTF8StringEncoding];
                [pboard declareTypes: [NSArray arrayWithObject: NSStringPboardType] owner: nil];
                [pboard setString: str forType: NSStringPboardType];
            }
            else if ([outDataType length] > 0) {
                NSLog(@"provide data as %@", outDataType);
                [pboard declareTypes: [NSArray arrayWithObject: outDataType] owner: nil];
                [pboard setData: outData forType: outDataType];
            }
        }
        NSLog(@"service done");
    }
}

/*
 * task notification
 */

- (void)unixAppExited: (NSNotification*)not
{
    int status = [[not object] terminationStatus];
    NSLog(@"UNIX application exited with code %d", status);
    if ( status ) {
        NSRunCriticalAlertPanel([NSApp applicationName],
                                [NSString stringWithFormat: @"UNIX appliation exited with exit code %d",
                                          status],
                                @"OK", nil, nil);
    }
    if ( [properties objectForKey: @"Filter"] ) {
        //give the service a chance to be called
        [NSApp performSelector:@selector(terminate:) withObject: self afterDelay:1];
    }
    else {
        [NSApp terminate: self];
    }
}



/*
 * initializing actions
 */

- (id<Action>)actionForMessage: (NSString *)msg
{
    NSDictionary *actionProps = [properties objectForKey: msg];
    if ( !actionProps ) {
        actionProps = AUTORELEASE([[NSDictionary alloc] init]);
    }
    NSString *actionName = [actionProps objectForKey: @"Action"];
    if ( ! actionName ) {
        NSLog(@"Warning: No type specified for message %@ - defaulting to RunScript", msg);
        actionName = @"RunScript";
    }
    if ( [actionName isEqualToString: @"RunScript"] ) {
        return [[RunScriptAction alloc] initWithActionName: msg properties: actionProps];
    }
    else if ( [actionName isEqualToString: @"Fail"] ) {
        return [[ErrorDialogAction alloc] initWithActionName: msg properties: actionProps];
    }
    else if ( [actionName isEqualToString: @"Ignore"] ) {
        return [[IgnoreAction alloc] initWithActionName: msg properties: actionProps];
    }
    else {
        NSRunCriticalAlertPanel([NSApp applicationName],
                                [NSString stringWithFormat: @"Unknown action %@ specified for message %@", actionName, msg],
                                @"OK", nil, nil);
        return nil;
    }
}

@end
