//
//  @author Nobu Funaki <http://twitter.com/zuzara>
//
#import <Cocoa/Cocoa.h>
#import <Skype/Skype.h>

@interface ContactList : NSObject
{
	NSMutableDictionary *contactList;
	NSMutableArray *sortedContactList;
	int previousSelectedRow;
	IBOutlet NSTableView *contactListTable;
}

+ (id)getSweetieNameFromPlist;

- (id)init;
- (void)setSkypeContactList;
- (void)addSkypeName:(NSString *)skypeName andFullName:(NSString *)fullName;
- (int)numberOfRowsInTableView:(NSTableView *)aTableView;
- (IBAction)tableAction:(id)sender;
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row;
@end
