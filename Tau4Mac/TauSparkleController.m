//
//  TauSparkleController.m
//  Tau4Mac
//
//  Created by Tong G. on 4/6/16.
//  Copyright © 2016 Tong Kuo. All rights reserved.
//

#import "TauSparkleController.h"

@interface TauVersionDisplayer : NSObject <SUVersionDisplay>
@end

@implementation TauVersionDisplayer

- ( void ) formatVersion: ( NSString** )_InOutVersionA andVersion: ( NSString** )_InOutVersionB
    {
    NSBundle* mainBundle = [ NSBundle mainBundle ];

    NSString* humanReadableVer = [ mainBundle objectForInfoDictionaryKey: @"CFBundleShortVersionString" ];
    NSString* machineVer = [ mainBundle objectForInfoDictionaryKey: @"CFBundleVersion" ];
    NSString* currentVersion = [ NSString stringWithFormat: @"%@ (%@)", humanReadableVer, machineVer ];

    *_InOutVersionB = currentVersion;
    }

@end

// Private
@interface TauSparkleController ()

// Debugging Sparkle

- ( NSURL* ) locateDebugSampleDirFrom_: ( NSURL* )_BeginningURL;

@end // Private

// TauSparkleController class
@implementation TauSparkleController

#pragma mark - Singleton

TauSparkleController static* sController;
+ ( instancetype ) sharedController
    {
    return [ [ self alloc ] init ];
    }

SUUpdater static* sSparkleUpdater;
- ( instancetype ) init
    {
    if ( !sController )
        {
        if ( self = [ super init ] )
            {
            if ( ![ [ NSBundle mainBundle ] isSandboxed ] )
                {
                // SUUpdater has a singleton for each bundle.
                // An NSBundle instances are also singletons.
                sSparkleUpdater = [ [ SUUpdater alloc ] init ];
                sSparkleUpdater.delegate = self;
                }

            sController = self;
            }
        }

    return sController;
    }

#pragma mark - Determine Necessity of Sparkle

@dynamic requiresSparkle;
- ( BOOL ) requiresSparkle
    {
    return ( sSparkleUpdater != nil );
    }

@dynamic isUpdating;
- ( BOOL ) isUpdating
    {
    if ( !self.requiresSparkle )
        return NO;

    return sSparkleUpdater.updateInProgress;
    }

#pragma mark - Update Operation

- ( IBAction ) checkForUpdates: ( id )_Sender
    {
    if ( self.requiresSparkle )
        {
        [ sSparkleUpdater checkForUpdates: _Sender ];
        [ _Sender setEnabled: !sSparkleUpdater.updateInProgress ];
        }
    else
        DDLogFatal( @"We don't need the Sparkle for MAS version of Tau4Mac. Sender of %@ should not be visible for user, it's a programmer error", THIS_METHOD );
    }

#pragma mark - Conforms to <SUUpdaterDelegate>

- ( id <SUVersionDisplay> ) versionDisplayerForUpdater: ( SUUpdater* )_Updater;
    {
    return [ [ TauVersionDisplayer alloc ] init ];
    }

- ( NSString* ) feedURLStringForUpdater: ( SUUpdater* )_Updater
    {
    #if debugSparkleWithLocalAppcastFeed
        NSString* srcLoc = [ NSString stringWithUTF8String: __FILE__ ];
        NSURL* srcURL = [ NSURL fileURLWithPath: srcLoc ];
        return [ [ self locateDebugSampleDirFrom_: srcURL ] URLByAppendingPathComponent: @"appcast-feed-debug.rss" ].absoluteString;
    #endif

    return @"https://raw.githubusercontent.com/TauProject/appcast-feed/master/feed.rss";
    }

#pragma mark - Private

// Debugging Sparkle

- ( NSURL* ) locateDebugSampleDirFrom_: ( NSURL* )_BeginningURL
    {
    sint8 static reasonableRecursionTimes;

    reasonableRecursionTimes++;

    // debug-sample dir isn't very far from the root of TauProject and therefore limitation of 10 times is enough.
    // Once recursion times exceed the resonable value, the debug-sample dir was removed by mistake perhaps.
    if ( reasonableRecursionTimes > 10 )
        {
        DDLogNotice( @"Recursion times exceeds a reasonable value." );
        reasonableRecursionTimes = 0;
        return nil;
        }

    NSURL* workspaceURL = [ _BeginningURL URLByDeletingLastPathComponent ];
    NSDirectoryEnumerator* enumerator = [ [ NSFileManager defaultManager ]
               enumeratorAtURL: workspaceURL
    includingPropertiesForKeys: @[ NSURLNameKey, NSURLIsDirectoryKey ]
                       options: NSDirectoryEnumerationSkipsSubdirectoryDescendants
                                    | NSDirectoryEnumerationSkipsPackageDescendants
                                    | NSDirectoryEnumerationSkipsHiddenFiles
                  errorHandler:
    ^BOOL ( NSURL* _Nonnull _URL, NSError* _Nonnull _Error )
        {
        DDLogRecoverable( @"Error {%@} occured while enuemrating \"%@\".", _Error, _URL );
        return YES;
        } ];

    NSURL* resultURL = nil;
    for ( NSURL* _CandidateURL in enumerator )
        {
        NSString* fileName = nil;
        [ _CandidateURL getResourceValue: &fileName forKey: NSURLNameKey error: nil ];

        NSNumber* isDir = nil;
        [ _CandidateURL getResourceValue: &isDir forKey: NSURLIsDirectoryKey error: nil ];

        if ( isDir && [ fileName isEqualToString: @"debug-sample" ] )
            {
            resultURL = _CandidateURL;
            break;
            }
        }

    return resultURL ?: [ self locateDebugSampleDirFrom_: workspaceURL ];
    }

@end // TauSparkleController class