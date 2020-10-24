//
//  SearchTableViewController.h
//  namuViewer
//

#import <UIKit/UIKit.h>
#import <DZNEmptyDataSet/UIScrollView+EmptyDataSet.h>

@protocol SearchDelegate <NSObject>
-(void)searchTableViewControllerDismissed:(NSString *)urlString;
@end

@interface SearchTableViewController : UITableViewController <UISearchControllerDelegate, UISearchBarDelegate, UISearchResultsUpdating, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, UITextFieldDelegate, UIGestureRecognizerDelegate>
@property (nonatomic, assign) id <SearchDelegate> delegate;

// @property (strong, nonatomic) UISearchController *searchController;
@property (weak, nonatomic) IBOutlet UITextField *searchField;
- (IBAction)dismissModal:(id)sender;
- (IBAction)searching:(id)sender;

@end
