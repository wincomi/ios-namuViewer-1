//
//  BookmarkTableViewController.h
//  namuViewer
//

#import <UIKit/UIKit.h>
#import <DZNEmptyDataSet/UIScrollView+EmptyDataSet.h>

@protocol BookmarkDelegate <NSObject>
-(void) bookmarkTableViewControllerDismissed:(NSString *)urlString;
@end

@interface BookmarkTableViewController : UITableViewController<DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, UISearchControllerDelegate, UISearchBarDelegate, UISearchResultsUpdating, UIGestureRecognizerDelegate>
@property (nonatomic, assign) id <BookmarkDelegate> delegate;


@property (strong, nonatomic) UISearchController *searchController;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
- (IBAction)typeChanged:(id)sender;
- (IBAction)touchClearButton:(id)sender;
- (IBAction)touchBackupButton:(id)sender;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *clearButton;

@end
