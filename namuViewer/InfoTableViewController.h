//
//  InfoTableViewController.h
//  namuViewer
//

#import <UIKit/UIKit.h>

@protocol InfoDelegate <NSObject>
-(void)infoTableViewControllerDismissed:(int)n;
@end

@interface InfoTableViewController : UITableViewController<UIActionSheetDelegate, UIGestureRecognizerDelegate>
@property (nonatomic, assign) id <InfoDelegate> delegate;
// @property (weak, nonatomic) IBOutlet UILabel *versionLabel;

@end
