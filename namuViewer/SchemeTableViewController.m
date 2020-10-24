//
//  SchemeTableViewController.m
//  namuViewer
//

#import "SchemeTableViewController.h"
#import <CWStatusBarNotification/CWStatusBarNotification.h>

@interface SchemeTableViewController ()

@end

@implementation SchemeTableViewController

- (void)viewDidLoad {
	[super viewDidLoad];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
	UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
	pasteboard.persistent = YES;
	pasteboard.string = cell.textLabel.text;

	CWStatusBarNotification *notification = [CWStatusBarNotification new];
	notification.notificationLabelBackgroundColor = self.view.tintColor;
	notification.notificationStyle = CWNotificationAnimationStyleTop;
	[notification displayNotificationWithMessage:@"클립보드에 복사되었습니다." forDuration:1.0f];

	[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end

