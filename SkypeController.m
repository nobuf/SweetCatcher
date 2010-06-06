//
//  @author Nobu Funaki <http://twitter.com/zuzara>
//
//  Some codes are base on SkypeAPITest
//
//      Created by Janno Teelem on 14/04/2005.
//      Copyright 2005-2006 Skype Limited. All rights reserved.
//

#import "SkypeController.h"
#import "ContactList.h"

NSString* const cMyApplicationName	= @"SweetCatcher";
NSString* const statusOffline		= @"OFFLINE";
NSString* const onlineIconFileName  = @"online.png"; // http://www.icondrawer.com/free.php
NSString* const offlineIconFileName = @"offline.png";
NSString* const helpPageUrl			= @"http://zuzara.com/blog/tag/sweetcatcher/";

@implementation SkypeController

@synthesize sweetieName;

- (id)init
{
	commandLength = 0;
	return self;
}
- (BOOL)setCommandOnlineStatus
{
	[self setSweetieName:[ContactList getSweetieNameFromPlist]];
	if (self.sweetieName.length > 0) {
		commandGetOnlineStatus = [[NSString stringWithFormat: @"USER %@ ONLINESTATUS ", self.sweetieName] retain];
		commandLength = commandGetOnlineStatus.length;
		return YES;
	} else {
		return NO;
	}
}

- (void)awakeFromNib
{
	[SkypeAPI setSkypeDelegate:self];
	if ([SkypeAPI isSkypeRunning]) {
		[SkypeAPI connect];
	}

	statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength] retain];
	
	[statusItem setImage:[NSImage imageNamed:offlineIconFileName]];
	[statusItem setHighlightMode:YES];
	[statusMenu setAutoenablesItems:NO];
	[statusItem setMenu:statusMenu];
	
	currentStatusOffline	= YES;
	userStatusOnline		= NO;
	
	[onlineIcon setImage:[NSImage imageNamed:onlineIconFileName]];
	[offlineIcon setImage:[NSImage imageNamed:offlineIconFileName]];
	
	// receive from ContactList
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivingSweetieNameUpdated:) name:@"sendNotificationSkypeController" object:nil];

	// current application file path
	applicationPath = [[NSString stringWithString:[[NSBundle mainBundle] bundlePath]] retain];

	//	"Open at Login" check
	CFURLRef url = (CFURLRef)[NSURL fileURLWithPath:applicationPath];
	LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
	if (loginItems) {
		if ([self searchLoginItemWithLoginItemsReference:loginItems ForPath:url DeleteFlag:NO]) {
			[checkBoxOpenAtLogin setState:NSOnState];
		} else {
			[checkBoxOpenAtLogin setState:NSOffState];
		}
	}
	CFRelease(loginItems);
}
- (void)receivingSweetieNameUpdated:(NSNotification *)notification
{
	[self setCommandOnlineStatus];
	[self sendGetUserOnlineStatus];
}

- (NSString*)clientApplicationName
{
	return cMyApplicationName;
}

- (void)skypeAttachResponse:(unsigned)aAttachResponseCode
{
	switch (aAttachResponseCode)
	{
		case 0:
			NSLog(@"Failed to connect.");
			break;
		case 1:
			NSLog(@"connected.");
			break;
		default:
			NSLog(@"Unknown response from Skype");
			break;
	}
}

- (void)sendGetUserOnlineStatus
{
	NSLog(@"sweet name: %@", self.sweetieName);
	NSString *buf = [SkypeAPI sendSkypeCommand:[NSString stringWithFormat: @"get user %@ onlinestatus", self.sweetieName]];
	if ([buf length] > 0) {
		[self checkOnlineStatus:buf];
	}
}

- (BOOL)isOffline:(NSString*)receivedString
{
	NSString *status = [receivedString substringFromIndex: commandLength];
	NSLog(@"status: %@", status);
	if ([status compare: statusOffline] == 0) {
		return TRUE;
	}
	return FALSE;
}

- (void)skypeNotificationReceived:(NSString*)aNotificationString
{
	if (userStatusOnline == NO) {
		[self checkInitialProcess: aNotificationString];
	}
	[self checkOnlineStatus:aNotificationString];
}

- (void)checkInitialProcess:(NSString *)aNotificationString
{
	// XXX after the string "SKYPEVERSION" appeared, sendSkypeCommand() will recieve return value
	if ([aNotificationString rangeOfString:@"SKYPEVERSION"].location == 0) {
		userStatusOnline = YES;
		[[NSNotificationCenter defaultCenter] postNotificationName:@"sendNotificationContactList" object:nil];
		if ([self setCommandOnlineStatus] == NO) {
			// probably it's an initial execution
			NSLog(@"initial execution...");
			[preferencePanel makeKeyAndOrderFront:nil];
		} else {
			[self sendGetUserOnlineStatus];
		}
	}	
}

- (void)checkOnlineStatus:(NSString*)aNotificationString
{
	if (aNotificationString.length > 0 &&
			commandLength > 0 &&
			[aNotificationString rangeOfString:commandGetOnlineStatus].location != NSNotFound) {
		[self changeStatusBarIcon: [self isOffline:aNotificationString]];
	}
}

- (void)changeStatusBarIcon:(BOOL)isOffline
{
	currentStatusOffline = isOffline;
	if (isOffline == FALSE) {
		[statusItem setImage:[NSImage imageNamed:onlineIconFileName]];
	} else {
		[statusItem setImage:[NSImage imageNamed:offlineIconFileName]];
	}

}

- (void)skypeBecameAvailable:(NSNotification*)aNotification
{
	NSLog(@"Skype became available");
	[SkypeAPI connect];
	[self sendGetUserOnlineStatus];
}

- (void)skypeBecameUnavailable:(NSNotification*)aNotification
{
	NSLog(@"Skype became unavailable");
	[self changeStatusBarIcon:TRUE];
}

- (void)menuNeedsUpdate:(NSMenu*)menu
{
	NSMenuItem *p = [menu itemWithTag:PreferencesTag];
	[p setEnabled:[SkypeAPI isSkypeRunning]];
	NSMenuItem *c = [menu itemWithTag:CallTag];
	[c setEnabled:!currentStatusOffline];
	[c setTitle:[NSString stringWithFormat:@"Call to %@", self.sweetieName]];
	NSMenuItem *t = [menu itemWithTag:ChatTag];
	[t setEnabled:!currentStatusOffline];
	[t setTitle:[NSString stringWithFormat:@"Chat with %@", self.sweetieName]];
}

// http://secondgear-public.googlecode.com/svn/trunk/SGLaunchAtLogin/Controller.m
- (void)enableLoginItemWithLoginItemsReference:(LSSharedFileListRef )theLoginItemsRefs ForPath:(CFURLRef)thePath
{
	// We call LSSharedFileListInsertItemURL to insert the item at the bottom of Login Items list.
	LSSharedFileListItemRef item = LSSharedFileListInsertItemURL(theLoginItemsRefs, kLSSharedFileListItemLast, NULL, NULL, thePath, NULL, NULL);		
	if (item) {
		CFRelease(item);
	}
}

- (BOOL)searchLoginItemWithLoginItemsReference:(LSSharedFileListRef )theLoginItemsRefs ForPath:(CFURLRef)thePath DeleteFlag:(BOOL)isDelete {
	UInt32 seedValue;
	BOOL foundOrNot = NO;
	
	// We're going to grab the contents of the shared file list (LSSharedFileListItemRef objects)
	// and pop it in an array so we can iterate through it to find our item.
	NSArray  *loginItemsArray = (NSArray *)LSSharedFileListCopySnapshot(theLoginItemsRefs, &seedValue);
	for (id item in loginItemsArray) {		
		LSSharedFileListItemRef itemRef = (LSSharedFileListItemRef)item;
		if (LSSharedFileListItemResolve(itemRef, 0, (CFURLRef*) &thePath, NULL) == noErr) {
			if ([[(NSURL *)thePath path] hasPrefix:applicationPath]) {
				if (isDelete) {
					LSSharedFileListItemRemove(theLoginItemsRefs, itemRef); // Deleting the item
				}
				foundOrNot = YES;
			}
		}
	}
	[loginItemsArray release];
	return foundOrNot;
}
- (IBAction)addLoginItem:(id)sender
{
	CFURLRef url = (CFURLRef)[NSURL fileURLWithPath:applicationPath];
	
	// Create a reference to the shared file list.
	LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
	
	if (loginItems) {
		if ([checkBoxOpenAtLogin state] == NSOnState) {
			[self enableLoginItemWithLoginItemsReference:loginItems ForPath:url];
		} else {
			[self searchLoginItemWithLoginItemsReference:loginItems ForPath:url DeleteFlag:YES];
		}
	}
	CFRelease(loginItems);
}
- (IBAction)startCall:(id)sender
{
	[SkypeAPI sendSkypeCommand:[NSString stringWithFormat: @"call %@", self.sweetieName]];
}
- (IBAction)startChat:(id)sender
{
	[SkypeAPI sendSkypeCommand:[NSString stringWithFormat: @"open im %@", self.sweetieName]];
}
- (IBAction)openHelpPage:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString:helpPageUrl]];
}
@end
