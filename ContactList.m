//
//  @author Nobu Funaki <http://twitter.com/zuzara>
//
//
#import "ContactList.h"

@implementation ContactList

NSString* const keySweetie = @"sweetie";

- (void)addSkypeName:(NSString *)skypeName andFullName:(NSString *)fullName
{
	[contactList setObject:fullName forKey:skypeName];
}
- (id)init
{
	contactList			= [[NSMutableDictionary alloc] init];
	sortedContactList	= [[NSMutableArray alloc] init];
	//	recieve from controller
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivingContactListUpdated:) name:@"sendNotificationContactList" object:nil];
	return self;
}
- (void)receivingContactListUpdated:(NSNotification *)notification
{
	// reset array
	[contactList removeAllObjects];
	[sortedContactList removeAllObjects];

	[self setSkypeContactList];
	[contactListTable reloadData];
}
- (void)dealloc
{
	[contactList release];
	[sortedContactList release];
	[super dealloc];
}
+ (id)getSweetieNameFromPlist
{
	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
	return [ud objectForKey:keySweetie];
}
- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	NSLog(@"number of contact list: %d", [contactList count]);
	return [contactList count];
}
- (IBAction)tableAction:(id)sender
{
	[sender reloadData]; // XXX avoid BUG?
}
- (void)setSkypeContactList
{
	NSString *buf = [SkypeAPI sendSkypeCommand:@"search friends"];
	NSString *strNames = [buf substringFromIndex:[@"USERS " length]];
	if (strNames) {
		NSArray *names = [strNames componentsSeparatedByString:@", "];
		for (NSString *name in names) {
			//NSLog(@"name: [%@]", name);
			NSString *strGetFullName = [SkypeAPI sendSkypeCommand:[NSString stringWithFormat:@"get user %@ fullname", name]];
			//NSLog(@"log: %s", [strGetFullName cString]);
			NSString *fullName = [strGetFullName substringFromIndex:[[NSString stringWithFormat:@"USER %@ FULLNAME ", name] length]];									  
			//NSLog(@"fullName: %s", [fullName cString]);
			if ([fullName length] == 0) {
				[self addSkypeName:name andFullName:name];
			} else {
				[self addSkypeName:name andFullName:fullName];
			}
		}
	}
	NSArray *tmpContactList = [contactList keysSortedByValueUsingSelector:@selector(caseInsensitiveCompare:)];
	[sortedContactList addObjectsFromArray:tmpContactList];
	//NSLog(@"sorted count: %d", [sortedContactList count]);
}
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	if ([[tableColumn identifier] isEqualToString:@"fullName"]) {
		//	save/load preference to .plist
		if ([tableView selectedRow] == -1) {
			id sweetieName = [ContactList getSweetieNameFromPlist];
			if (sweetieName != nil) {
				int i = 0;
				BOOL flag = FALSE;
				for (NSString *skypeName in sortedContactList) {
					if ([skypeName isEqualToString:sweetieName]) {
						flag = TRUE;
						break;
					}
					i++;
				}
				if (flag == TRUE) {
					previousSelectedRow = i;
					[tableView selectRow:i byExtendingSelection:TRUE];
				}
			}
		} else if (previousSelectedRow != [tableView selectedRow]) {
			previousSelectedRow = [tableView selectedRow];
			NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
			[ud setObject:[sortedContactList objectAtIndex:[tableView selectedRow]] forKey:keySweetie];
			[ud synchronize];
			// send message to controller
			[[NSNotificationCenter defaultCenter] postNotificationName:@"sendNotificationSkypeController" object:nil];
			
		}
		//NSLog(@"%d, %d", [contactList count], row);
		if ([contactList count] == 0) {
			return nil;
		}
		return [[contactList objectForKey:[sortedContactList objectAtIndex:row]] description];
    }
	return nil;
}
@end
