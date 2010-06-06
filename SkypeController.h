//
//  @author Nobu Funaki <http://twitter.com/zuzara>
//
//  Some codes are base on SkypeAPITest
//      SkypeController.h
//      SkypeAPITest
//
//      Created by Janno Teelem on 14/04/2005.
//      Copyright 2005-2006 Skype Limited. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Skype/Skype.h>

enum {
	CallTag			= 100,
	ChatTag			= 101,
	PreferencesTag	= 102,
	QuitTag			= 103,
};

@interface SkypeController : NSObject <SkypeAPIDelegate>
{
	IBOutlet NSButton *checkBoxOpenAtLogin;
	IBOutlet NSImageView *offlineIcon;
	IBOutlet NSImageView *onlineIcon;
	IBOutlet NSPanel *preferencePanel;
	IBOutlet NSMenu *statusMenu;
    NSStatusItem *statusItem;
	NSString *commandGetOnlineStatus;
	NSString *applicationPath;
    int commandLength;
	
	NSString *sweetieName;
	BOOL currentStatusOffline;
	BOOL userStatusOnline;
}
@property (assign) NSString *sweetieName;

- (BOOL)searchLoginItemWithLoginItemsReference:(LSSharedFileListRef )theLoginItemsRefs ForPath:(CFURLRef)thePath DeleteFlag:(BOOL)isDelete;
- (void)checkInitialProcess:(NSString *)aNotificationString;
- (void)sendGetUserOnlineStatus;
- (BOOL)isOffline:(NSString*)receivedString;
- (void)checkOnlineStatus:(NSString*)aNotificationString;
- (void)changeStatusBarIcon:(BOOL)isOffline;

@end
