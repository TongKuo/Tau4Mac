//
//  TauMainWindowController.m
//  Tau4Mac
//
//  Created by Tong G. on 3/3/16.
//  Copyright © 2016 Tong Kuo. All rights reserved.
//

#import "TauMainWindowController.h"

#import "GTL/GTMOAuth2WindowController.h"

#import "TauTTYLogFormatter.h"

// Private Interfaces
@interface TauMainWindowController ()

// Signning in
- ( void ) runSignInThenHandler_: ( void (^)( void ) )_Handler;

// Logging
- ( void ) configureLogging_;

@end // Private Interfaces

@implementation TauMainWindowController
    {
    NSSegmentedControl __strong* segSwitcher_;
    FBKVOController __strong* kvoController_;
    }

#pragma mark - Initializations

- ( instancetype ) initWithCoder: ( NSCoder* )_Coder
    {
    if ( self = [ super initWithCoder: _Coder] )
        {
        NSUInteger segmentCount = 3;
        CGFloat segmentFixedWidth = 80.f;
        segSwitcher_ = [ [ NSSegmentedControl alloc ] initWithFrame: NSMakeRect( 0, 0, 248.f, 21.f ) ];
        [ segSwitcher_ setSegmentCount: 3 ];
        [ segSwitcher_ setTrackingMode: NSSegmentSwitchTrackingSelectOne ];

        for ( int _Index = 0; _Index < segmentCount; _Index++ )
            {
            [ segSwitcher_ setWidth: segmentFixedWidth forSegment: _Index ];
            [ segSwitcher_.cell setTag: ( TauPanelsSwitcherSegmentTag )_Index forSegment: _Index ];

            switch ( [ segSwitcher_.cell tagForSegment: _Index ] )
                {
                case TauPanelsSwitcherSearchTag:
                    {
                    [ segSwitcher_ setLabel: NSLocalizedString( @"Search", nil ) forSegment: _Index ];
                    } break;

                case TauPanelsSwitcherMeTubeTag:
                    {
                    [ segSwitcher_ setLabel: NSLocalizedString( @"MeTube", nil ) forSegment: _Index ];
                    } break;

                case TauPanelsSwitcherPlayerTag:
                    {
                    [ segSwitcher_ setLabel: NSLocalizedString( @"Player", nil ) forSegment: _Index ];
                    } break;
                }
            }
        }

    return self;
    }

- ( void ) windowDidLoad
    {
    [ super windowDidLoad ];

    [ self.toolbar setAllowsUserCustomization: NO ];

    [ NSApp setDelegate: self ];

    kvoController_ = [ [ FBKVOController alloc ] initWithObserver: self.contentViewController ];

#pragma clang diagnostic push
// Get rid of the 'undeclared selector' warning
#pragma clang diagnostic ignored "-Wundeclared-selector"
    [ kvoController_ observe: segSwitcher_ keyPath: @"cell.selectedSegment"
                     options: NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                      action: @selector( selectedSegmentDidChange:observing: ) ];
#pragma clang diagnostic pop

    [ segSwitcher_ selectSegmentWithTag: TauPanelsSwitcherSearchTag ];
    }

#pragma mark - Conforms to <NSApplicationDelegate>

- ( void ) applicationDidFinishLaunching: ( NSNotification* )_Notif
    {
    [ self configureLogging_ ];

    if ( ![ [ TauDataService sharedService ] isSignedIn ] )
        [ self runSignInThenHandler_: nil ];
    }

#pragma mark - Conforms to <NSToolbarDelegate>

NSString* const kPanelsSwitcher = @"kPanelsSwitcher";

- ( NSArray <NSString*>* ) toolbarAllowedItemIdentifiers: ( NSToolbar* )_Toolbar
    {
    return @[ NSToolbarFlexibleSpaceItemIdentifier
            , kPanelsSwitcher
            , NSToolbarFlexibleSpaceItemIdentifier
            ];
    }

- ( NSArray <NSString*>* ) toolbarDefaultItemIdentifiers: ( NSToolbar* )_Toolbar
    {
    return @[ NSToolbarFlexibleSpaceItemIdentifier
            , kPanelsSwitcher
            , NSToolbarFlexibleSpaceItemIdentifier
            ];
    }

- ( NSToolbarItem* )  toolbar: ( NSToolbar* )_Toolbar
        itemForItemIdentifier: ( NSString* )_ItemIdentifier
    willBeInsertedIntoToolbar: ( BOOL )_Flag
    {
    NSToolbarItem* toolbarItem = nil;
    BOOL should = NO;

    NSString* identifier = _ItemIdentifier;
    NSString* label = nil;
    NSString* paleteLabel = nil;
    NSString* toolTip = nil;
    id content = nil;
    id target = self;
    SEL action = nil;
    NSMenu* repMenu = nil;

    if ( ( should = [ _ItemIdentifier isEqualToString: kPanelsSwitcher ] ) )
        {
        content = segSwitcher_;
        }

    if ( should )
        {
        toolbarItem = [ self _toolbarWithIdentifier: identifier
                                              label: label
                                        paleteLabel: paleteLabel
                                            toolTip: toolTip
                                             target: target
                                             action: action
                                        itemContent: content
                                            repMenu: repMenu ];
        }

    return toolbarItem;
    }

#pragma mark - Private Interfaces
- ( NSToolbarItem* ) _toolbarWithIdentifier: ( NSString* )_Identifier
                                      label: ( NSString* )_Label
                                paleteLabel: ( NSString* )_PaleteLabel
                                    toolTip: ( NSString* )_ToolTip
                                     target: ( id )_Target
                                     action: ( SEL )_ActionSEL
                                itemContent: ( id )_ImageOrView
                                    repMenu: ( NSMenu* )_Menu
    {
    NSToolbarItem* newToolbarItem = [ [ NSToolbarItem alloc ] initWithItemIdentifier: _Identifier ];

    [ newToolbarItem setLabel: _Label ];
    [ newToolbarItem setPaletteLabel: _PaleteLabel ];
    [ newToolbarItem setToolTip: _ToolTip ];

    [ newToolbarItem setTarget: _Target ];
    [ newToolbarItem setAction: _ActionSEL ];

    if ( [ _ImageOrView isKindOfClass: [ NSImage class ] ] )
        [ newToolbarItem setImage: ( NSImage* )_ImageOrView ];

    else if ( [ _ImageOrView isKindOfClass: [ NSView class ] ] )
        [ newToolbarItem setView: ( NSView* )_ImageOrView ];

    if ( _Menu )
        {
        NSMenuItem* repMenuItem = [ [ NSMenuItem alloc ] init ];
        [ repMenuItem setSubmenu: _Menu ];
        [ repMenuItem setTitle: _Label ];
        [ newToolbarItem setMenuFormRepresentation: repMenuItem ];
        }

    return newToolbarItem;
    }

#pragma mark - Private Interfaces

// Signning in
- ( void ) runSignInThenHandler_: ( void (^)( void ) )_Handler
    {
    NSBundle* frameworkBundle = [ NSBundle bundleForClass: [ GTMOAuth2WindowController class ] ];

    GTMOAuth2WindowController* authWindow = [ GTMOAuth2WindowController
        controllerWithScope: TauManageAuthScope
                   clientID: TauClientID
               clientSecret: TauClientSecret
           keychainItemName: TauKeychainItemName
             resourceBundle: frameworkBundle ];

    [ authWindow signInSheetModalForWindow: self.window completionHandler:
        ^( GTMOAuth2Authentication* _Auth, NSError* _Error )
            {
            [ [ TauDataService sharedService ].ytService setAuthorizer: _Auth ];
            if ( _Handler ) _Handler();
            } ];
    }

// Logging
- ( void ) configureLogging_
    {
    NSColor* errorOutputColor = [ NSColor colorWithRed: 248 / 255.f green: 98 / 255.0 blue: 98 / 255.0 alpha: 1.f ];
    NSColor* debugOutputColor = [ NSColor colorWithRed: 151 / 255.f green: 204 / 255.0 blue: 245 / 255.0 alpha: 1.f ];
    NSColor* infoOutputColor = [ NSColor colorWithRed: 184 / 255.f green: 233 / 255.0 blue: 134 / 255.0 alpha: 1.f ];
    NSColor* warningOutputColor = [ NSColor colorWithRed: 246 / 255.f green: 174 / 255.0 blue: 55 / 255.0 alpha: 1.f ];
    NSColor* verboseOutputColor = [ NSColor lightGrayColor ];

    // Configuring TTY Logger
    DDTTYLogger* sharedTTYLogger = [ DDTTYLogger sharedInstance ];
    DDASLLogger* sharedASLLogger = [ DDASLLogger sharedInstance ];

    [ sharedTTYLogger setLogFormatter: [ [ TauTTYLogFormatter alloc ] init ] ];
    [ sharedASLLogger setLogFormatter: [ [ TauTTYLogFormatter alloc ] init ] ];

    [ sharedTTYLogger setColorsEnabled: YES ];
    [ sharedTTYLogger setForegroundColor: errorOutputColor backgroundColor: nil forFlag: DDLogFlagError ];
    [ sharedTTYLogger setForegroundColor: debugOutputColor backgroundColor: nil forFlag: DDLogFlagDebug ];
    [ sharedTTYLogger setForegroundColor: infoOutputColor backgroundColor: nil forFlag: DDLogFlagInfo ];
    [ sharedTTYLogger setForegroundColor: warningOutputColor backgroundColor: nil forFlag: DDLogFlagWarning ];
    [ sharedTTYLogger setForegroundColor: verboseOutputColor backgroundColor: nil forFlag: DDLogFlagVerbose ];

    // Configuring file logger
    DDFileLogger* fileLogger = [ [ DDFileLogger alloc ] init ];

    fileLogger.rollingFrequency = 60 * 60 * 24 * 3; // Three day
    fileLogger.logFileManager.maximumNumberOfLogFiles = 10;

    [ DDLog addLogger: sharedTTYLogger ];
    [ DDLog addLogger: sharedASLLogger ];
    [ DDLog addLogger: fileLogger withLevel: DDLogLevelError | DDLogLevelWarning ];
    }

@end
