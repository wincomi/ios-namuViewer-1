//
//  TocViewController.h
//  namuViewer
//

#import <UIKit/UIKit.h>
#import <Webkit/Webkit.h>

@protocol TocDelegate <NSObject>
-(void)tocTableViewControllerDismissed:(NSString *)no;
@end

@interface TocViewController : UITableViewController <WKNavigationDelegate, WKUIDelegate, UIGestureRecognizerDelegate>
@property (nonatomic, assign) id <TocDelegate> delegate;
@property WKWebView *webView;
@property NSString *html;

@end
