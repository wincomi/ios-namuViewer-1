//
//  InfoTableViewController.m
//  namuViewer
//

#import "InfoTableViewController.h"
#import <WebKit/WKWebsiteDataStore.h>

@import SafariServices;

@interface InfoTableViewController ()
@property NSMutableArray *commands;

@end

@implementation InfoTableViewController

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    self.clearsSelectionOnViewWillAppear = YES;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Close"] style:UIBarButtonItemStyleDone target:self action:@selector(dismissModal:)];
	
	/* NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    _versionLabel.text = [NSString stringWithFormat:@"v%@ (%@)", appVersion,  [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]]; */

	// iOS13 강제 라이트모드
	if (@available(iOS 13.0, *)) {
		self.navigationController.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
	}
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    /*
    UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapBehind:)];
    [recognizer setNumberOfTapsRequired:1];
    recognizer.cancelsTouchesInView = NO; //So the user can still interact with controls in the modal view
    [self.view.window addGestureRecognizer:recognizer];
    recognizer.delegate = self; */
}
- (void)dismissModal:(id)sender {
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewWillAppear:(BOOL)animated {
	[self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	// Return the number of rows in the section.
	return [super tableView:tableView numberOfRowsInSection:section];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && indexPath.row == 2) {
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.0")) {
            /* NSSet *websiteDataTypes = [NSSet setWithArray:@[
             WKWebsiteDataTypeDiskCache,
             //WKWebsiteDataTypeOfflineWebApplicationCache,
             WKWebsiteDataTypeMemoryCache,
             //WKWebsiteDataTypeLocalStorage,
             //WKWebsiteDataTypeCookies,
             //WKWebsiteDataTypeSessionStorage,
             //WKWebsiteDataTypeIndexedDBDatabases,
             //WKWebsiteDataTypeWebSQLDatabases
             ]];
             */
            // All kinds of data
            NSSet *websiteDataTypes = [WKWebsiteDataStore allWebsiteDataTypes];
            // Date from
            NSDate *dateFrom = [NSDate dateWithTimeIntervalSince1970:0];
            // Execute
            [[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:websiteDataTypes modifiedSince:dateFrom completionHandler:^{
                // Done
            }];
        } else {
            NSString *libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
            NSString *cookiesFolderPath = [libraryPath stringByAppendingString:@"/Cookies"];
            NSError *errors;
            [[NSFileManager defaultManager] removeItemAtPath:cookiesFolderPath error:&errors];
        }
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle: @"나무뷰어"
                                                                       message: @"캐시를 비웠습니다."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"확인"
                                                         style:UIAlertActionStyleCancel
                                                       handler:^(UIAlertAction * action) {
                                                           [alert dismissViewControllerAnimated:YES completion:nil];
                                                       }];
        [alert addAction:cancel];
        [self presentViewController:alert animated:YES completion:nil];
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    } else if (indexPath.section == 2) {
        NSURL *url = [NSURL URLWithString:@"https://www.wincomi.com"];
        if (NSClassFromString(@"SFSafariViewController")) {
            SFSafariViewController *safariViewController = [[SFSafariViewController alloc] initWithURL:url];
            [self presentViewController:safariViewController animated:YES completion:nil];
        } else {
            [[UIApplication sharedApplication] openURL:url];
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        }
	} else if(indexPath.section == 3) {
        NSURL *url = [NSURL URLWithString:@"http://krevony.github.io"];
        if (NSClassFromString(@"SFSafariViewController")) {
            SFSafariViewController *safariViewController = [[SFSafariViewController alloc] initWithURL:url];
            [self presentViewController:safariViewController animated:YES completion:nil];
        } else {
            [[UIApplication sharedApplication] openURL:url];
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        }
	} else if(indexPath.section == 1) {
		switch (indexPath.row) {
            case 0: {
				[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"itms-apps://itunes.apple.com/app/id993035669"]];
                [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
				break;
            }
			case 1:{/*
                UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:@"나무뷰어 피드백 보내기"
                                                                                     message:nil
                                                                              preferredStyle:UIAlertControllerStyleActionSheet];
                
                UIAlertAction *twitterAction = [UIAlertAction actionWithTitle:@"트위터로"
                                                                    style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction * action) {
                                                                      
                                                                  }];
                [actionSheet addAction:twitterAction];
                UIAlertAction *fbAction = [UIAlertAction actionWithTitle:@"페이스북으로"
                                                                        style:UIAlertActionStyleDefault
                                                                      handler:^(UIAlertAction * action) {
                                                                          
                                                                      }];
                [actionSheet addAction:fbAction];
                UIAlertAction *emailAction = [UIAlertAction actionWithTitle:@"이메일로"
                                                                        style:UIAlertActionStyleDefault
                                                                      handler:^(UIAlertAction * action) { */
                
                                                                          NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
                                                                          UIDevice *currentDevice = [UIDevice currentDevice];
                                                                          NSString *recipients = [NSString stringWithFormat:@"mailto:admin@wincomi.com?subject=나무뷰어 v%@ 피드백",appVersion];
                                                                          NSString *body = [NSString stringWithFormat:@"&body=* 나무뷰어는 나무위키의 공식 앱이 아니므로 나무위키 사이트의 문의사항은 나무위키로 문의하시기 바랍니다.\n* 하단에 피드백 내용을 입력해주세요.\n\n\n___________________\niOS %@ (%@, %@)", [currentDevice systemVersion], [currentDevice model], [[NSLocale preferredLanguages] objectAtIndex:0]];
                                                                          NSString *email = [NSString stringWithFormat:@"%@%@", recipients, body];
                                                                          email = [email stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                                                                          [[UIApplication sharedApplication] openURL:[NSURL URLWithString:email]];
                                                                      /* }];
                [actionSheet addAction:emailAction];
                UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"취소"
                                                                       style:UIAlertActionStyleCancel
                                                                     handler:^(UIAlertAction * action) {
                                                                         [actionSheet dismissViewControllerAnimated:YES completion:nil];
                                                                     }];
                [actionSheet addAction:cancelAction];
                actionSheet.popoverPresentationController.sourceView = self.view;
                actionSheet.popoverPresentationController.sourceRect = self.view.bounds;
                */
                [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
                
				break;
			}
			default:
				break;
		}
	}
}


- (NSArray *)keyCommands {
    if (!_commands) {
        _commands = [[NSMutableArray alloc] initWithArray:@[[UIKeyCommand keyCommandWithInput:@"w"
                                                                                modifierFlags:UIKeyModifierCommand
                                                                                       action:@selector(handleShortcut:)
                                                                         discoverabilityTitle:@"창 닫기"]]];
    }
    return _commands;
}

- (void)handleShortcut:(UIKeyCommand *)keyCommand {
    if ([keyCommand.input isEqualToString:@"w"]) {
        // [[self.autoCompleteQueue.operations lastObject] cancel];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

/*
#pragma mark - UIGestureRecognizer Delegate
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    return YES;
}

- (void)handleTapBehind:(UITapGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateEnded) {
        
        // passing nil gives us coordinates in the window
        CGPoint location = [sender locationInView:nil];
        
        if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            location = CGPointMake(location.y, location.x);
        }
        
        // convert the tap's location into the local view's coordinate system, and test to see if it's in or outside. If outside, dismiss the view.
        if (![self.view pointInside:[self.view convertPoint:location fromView:self.view.window] withEvent:nil]) {
            
            // remove the recognizer first so it's view.window is valid
            [self.view.window removeGestureRecognizer:sender];
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }
}
*/
@end


@interface UIImageView (Utils)

- (void)setImageRenderingMode:(UIImageRenderingMode)renderMode;

@end

@implementation UIImageView (Utils)

- (void)setImageRenderingMode:(UIImageRenderingMode)renderMode
{
	NSAssert(self.image, @"Image must be set before setting rendering mode");
	self.image = [self.image imageWithRenderingMode:renderMode];
}

@end
