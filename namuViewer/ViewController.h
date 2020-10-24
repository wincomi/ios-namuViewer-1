//
//  ViewController.h
//  namuViewer
//

#import <UIKit/UIKit.h>
#import <Webkit/Webkit.h>
#import "SearchTableViewController.h"
#import "BookmarkTableViewController.h"
#import "TocViewController.h"

#import <M13ProgressSuite/M13ProgressView.h>
#import <CWStatusBarNotification/CWStatusBarNotification.h>
#import "UIViewController+ENPopUp.h"

@import SafariServices;

@interface ViewController : UIViewController <SearchDelegate, BookmarkDelegate, TocDelegate, WKNavigationDelegate, WKUIDelegate, SFSafariViewControllerDelegate>

@property WKWebView *webView;
@property (strong, nonatomic) UISearchController *searchController;

// Top Toolbar
@property (weak, nonatomic) IBOutlet UIBarButtonItem *goBackButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *goForwardButton;
- (IBAction)goBack:(id)sender;
- (IBAction)goForward:(id)sender;

// Bottom Toolbar
@property (weak, nonatomic) IBOutlet UIBarButtonItem *starButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *actionButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *tocButton;
- (IBAction)touchStarButton:(id)sender;
- (IBAction)touchActionButton:(id)sender;
- (IBAction)touchMoreButton:(id)sender;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *bookmarkButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *moreButton;


- (void)openURL:(NSString *)urlString;

@end

