//
//  BookmarkTableViewController.m
//  namuViewer
//

#import "BookmarkTableViewController.h"
#import "ViewController.h"

@interface BookmarkTableViewController ()//  <UIViewControllerPreviewingDelegate>
@property NSArray *searchResults;
@property NSArray *bookmarksArray, *historiesArray;
@property NSMutableArray *bookmarksMutableArray, *historiesMutableArray;
@property UITapGestureRecognizer *tapGesture;
@property int type;
@property BOOL isSearching;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *backupButton;

// @property (nonatomic, strong) id previewingContext;


@property NSMutableArray *commands;

@end

@implementation BookmarkTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	UIBarButtonItem *doneButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Close"] style:UIBarButtonItemStyleDone target:self action:@selector(dismissModal:)];
	self.navigationItem.rightBarButtonItem = doneButtonItem;
	self.navigationItem.leftBarButtonItem = self.editButtonItem;
	
    /* if ([self isForceTouchAvailable]) {
        self.previewingContext = [self registerForPreviewingWithDelegate:self sourceView:self.view];
    } */

    NSString *filePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];

    if  ([[NSUserDefaults standardUserDefaults] boolForKey:@"use_icloud"] == YES) {
        _bookmarksArray = [[[NSUbiquitousKeyValueStore defaultStore] arrayForKey:@"bookmarksFile"] mutableCopy];
        _bookmarksMutableArray = [_bookmarksArray mutableCopy];
        _historiesArray = [[NSArray alloc] initWithContentsOfFile:[filePath stringByAppendingPathComponent:@"historiesFile"]];
        _historiesMutableArray = [[NSMutableArray alloc] initWithContentsOfFile:[filePath stringByAppendingPathComponent:@"historiesFile"]];
        
        //  Observer to catch changes from iCloud
        NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(storeDidChange:)
                                                     name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification
                                                   object:store];
        
        [[NSUbiquitousKeyValueStore defaultStore] synchronize];

    } else {
        _bookmarksArray = [[NSArray alloc] initWithContentsOfFile:[filePath stringByAppendingPathComponent:@"bookmarksFile"]];
        _bookmarksMutableArray = [[NSMutableArray alloc] initWithContentsOfFile:[filePath stringByAppendingPathComponent:@"bookmarksFile"]];
        _historiesArray = [[NSArray alloc] initWithContentsOfFile:[filePath stringByAppendingPathComponent:@"historiesFile"]];
        _historiesMutableArray = [[NSMutableArray alloc] initWithContentsOfFile:[filePath stringByAppendingPathComponent:@"historiesFile"]];
    }

    if (self.bookmarksMutableArray.count == 0) {
		self.editButtonItem.enabled = NO;
		self.tableView.tableFooterView = [UIView new];
	}
	if (!self.bookmarksMutableArray) self.bookmarksMutableArray = [NSMutableArray new];

	self.searchResults = [NSArray new];
	
	self.tableView.emptyDataSetSource = self;
	self.tableView.emptyDataSetDelegate = self;
    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.tableView.bounds.size.width, 0.01f)];
	self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.tableView.bounds.size.width, 0.01f)];
    
    // Search Controller
    /*
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.delegate = self;
    self.searchController.searchBar.delegate = self;
    self.searchController.searchResultsUpdater = self;
    self.searchController.dimsBackgroundDuringPresentation = NO;
    self.searchController.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    // self.tableView.tableHeaderView = self.searchController.searchBar;
    self.definesPresentationContext = YES;
    [self.searchController.searchBar sizeToFit];
     */

	// iOS13 강제 라이트모드
	if (@available(iOS 13.0, *)) {
		self.navigationController.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
	}
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapBehind:)];
    [self.tapGesture setNumberOfTapsRequired:1];
    self.tapGesture.cancelsTouchesInView = NO;
    [self.view.window addGestureRecognizer:self.tapGesture];
    self.tapGesture.delegate = self;
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.view.window removeGestureRecognizer:self.tapGesture];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dismissModal:(id)sender {
    [self.view.window removeGestureRecognizer:self.tapGesture];
	[self.delegate bookmarkTableViewControllerDismissed:nil];
	[self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
	if (self.isSearching == YES)
		return self.searchResults.count;
    else {
        if (self.segmentedControl.selectedSegmentIndex == 1) {
            return self.historiesArray.count;
        } else {
            return self.bookmarksArray.count;
        }
    }
}

- (BOOL)emptyDataSetShouldDisplay:(UIScrollView *)scrollView {
    if ((self.segmentedControl.selectedSegmentIndex == 1 && self.historiesArray.count == 0) ||
        (self.segmentedControl.selectedSegmentIndex != 1 && self.bookmarksArray.count == 0))
        return YES;
    return NO;
}

/* - (UIViewController *)previewingContext:(id )previewingContext viewControllerForLocation:(CGPoint)location{
    
    CGPoint cellPostion = [self.tableView convertPoint:location fromView:self.view];
    NSIndexPath *path = [self.tableView indexPathForRowAtPoint:cellPostion];
    
    if (path) {
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:path];
        
        // get your UIStoryboard
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        return storyboard.instantiateInitialViewController;
        
    }
    return nil;
}

- (void)previewingContext:(id )previewingContext commitViewController: (UIViewController *)viewControllerToCommit {
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    if ([self isForceTouchAvailable]) {
        if (!self.previewingContext) {
            self.previewingContext = [self registerForPreviewingWithDelegate:self sourceView:self.view];
        }
    } else {
        if (self.previewingContext) {
            [self unregisterForPreviewingWithContext:self.previewingContext];
            self.previewingContext = nil;
        }
    }
} */

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.searchController setActive:NO];
	UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    [self.view.window removeGestureRecognizer:self.tapGesture];
	if([self.delegate respondsToSelector:@selector(bookmarkTableViewControllerDismissed:)]) {
		NSString *urlString = [NSString stringWithFormat:@"http://namu.wiki/go/%@",cell.textLabel.text];
		urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		[self.delegate bookmarkTableViewControllerDismissed:urlString];
	}
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *CellIdentifier = @"Cell";

	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];

    NSString *theme = [[NSUserDefaults standardUserDefaults] stringForKey:@"theme"];
    if ([theme isEqualToString:@"black"] || [theme isEqualToString:@"blackorange"]) {
        cell.backgroundColor = [UIColor blackColor];
        cell.textLabel.textColor = [UIColor whiteColor];
        
        UIView *selectionColor = [[UIView alloc] init];
        selectionColor.backgroundColor = [UIColor colorWithRed:0.22 green:0.23 blue:0.24 alpha:1.00];
        cell.selectedBackgroundView = selectionColor;
    }
    
    if (self.isSearching == YES) {
		cell.textLabel.text = self.searchResults[indexPath.row];
		// cell.imageView.image = [[UIImage imageNamed:@"Star"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
	} else {
        if (self.segmentedControl.selectedSegmentIndex == 1) {
            cell.textLabel.text = self.historiesArray[indexPath.row];
        } else {
            cell.textLabel.text = self.bookmarksArray[indexPath.row];
        }
		
		// cell.imageView.image = [cell.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
	}

	return cell;
}

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope
{
	NSPredicate *resultPredicate = [NSPredicate predicateWithFormat:@"self contains [c] %@", searchText];
	self.searchResults = [self.bookmarksMutableArray filteredArrayUsingPredicate:resultPredicate];
    
    
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
	/* [self filterContentForSearchText:searchController.searchBar.text
							   scope:[[self.searchController.searchBar scopeButtonTitles]
									  objectAtIndex:[self.searchController.searchBar
													 selectedScopeButtonIndex]]]; */
    NSPredicate *resultPredicate = [NSPredicate predicateWithFormat:@"self contains [c] %@", searchController.searchBar.text];
    self.searchResults = [self.bookmarksMutableArray filteredArrayUsingPredicate:resultPredicate];
    // self.bookmarksMutableArray = [[self.bookmarksArray filteredArrayUsingPredicate:resultPredicate] mutableCopy];
    self.isSearching = YES;
    [self.tableView reloadData];
}

- (void)willDismissSearchController:(UISearchController *)searchController {

    self.isSearching = NO;
    [self.tableView reloadData];
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {

    return YES;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.segmentedControl.selectedSegmentIndex == 1)
        return NO;
    else
        return YES;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
	id object = [self.bookmarksMutableArray objectAtIndex:fromIndexPath.row];
	[self.bookmarksMutableArray removeObjectAtIndex:fromIndexPath.row];
	[self.bookmarksMutableArray insertObject:object atIndex:toIndexPath.row];
	
	[self saveBookmarks];
	// [NSKeyedArchiver archiveRootObject:self.starsMutableArray toFile:fileAtPath];
	
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.segmentedControl.selectedSegmentIndex == 1) {
        if (editingStyle == UITableViewCellEditingStyleDelete) {
            [_historiesMutableArray removeObjectAtIndex:indexPath.row];
            [self saveHistories];
        
            
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
    }
    else {
        if (editingStyle == UITableViewCellEditingStyleDelete) {
            [_bookmarksMutableArray removeObjectAtIndex:indexPath.row];
            [self saveBookmarks];
            
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
    }
}

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView {
    self.navigationItem.leftBarButtonItem.enabled = NO;
    self.navigationController.toolbarHidden = YES;
    NSString *text;
    if (self.segmentedControl.selectedSegmentIndex == 1)
        text = @"방문 기록이 없습니다.";
    else
        text = @"즐겨찾기가 없습니다.";

	UIColor *color = [UIColor darkGrayColor];
    NSString *theme = [[NSUserDefaults standardUserDefaults] stringForKey:@"theme"];
    if ([theme isEqualToString:@"black"] || [theme isEqualToString:@"blackorange"])
        color = [UIColor whiteColor];
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont boldSystemFontOfSize:20.0],
                                 NSForegroundColorAttributeName: color};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];

}

- (NSAttributedString *)descriptionForEmptyDataSet:(UIScrollView *)scrollView {
	
    NSString *text;
	if (self.segmentedControl.selectedSegmentIndex == 1)
        text = @"위키를 탐험해보세요! (´･ω･`)";
    else
        text = @"하단의 별 버튼을 이용하여 자주 찾는 항목을 즐겨찾기에 추가해보세요.";
        
	NSMutableParagraphStyle *paragraph = [NSMutableParagraphStyle new];
	paragraph.lineBreakMode = NSLineBreakByWordWrapping;
	paragraph.alignment = NSTextAlignmentCenter;
	
	NSDictionary *attributes = @{NSFontAttributeName: [UIFont systemFontOfSize:14.0],
								 NSForegroundColorAttributeName: [UIColor lightGrayColor],
								 NSParagraphStyleAttributeName: paragraph};
	
	return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (UIImage *)imageForEmptyDataSet:(UIScrollView *)scrollView
{
    NSString *theme = [[NSUserDefaults standardUserDefaults] stringForKey:@"theme"];
    if ([theme isEqualToString:@"black"] || [theme isEqualToString:@"blackorange"])
        return nil;
    else {
        if (self.segmentedControl.selectedSegmentIndex == 1)
            return [UIImage imageNamed:@"History"];
        else
            return [UIImage imageNamed:@"Star"];
    }
}


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)saveBookmarks {
	NSString *filePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	NSString *fileName =  @"bookmarksFile";
	NSString *fileAtPath = [filePath stringByAppendingPathComponent:fileName];
	[_bookmarksMutableArray writeToFile:fileAtPath atomically:NO];
    _bookmarksArray = _bookmarksMutableArray;
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"use_icloud"] == YES) {
        [[NSUbiquitousKeyValueStore defaultStore] setArray:_bookmarksArray forKey:@"bookmarksFile"];
    }
}

- (void)saveHistories {
    NSString *filePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *fileName =  @"historiesFile";
    NSString *fileAtPath = [filePath stringByAppendingPathComponent:fileName];
    [_historiesMutableArray writeToFile:fileAtPath atomically:NO];

    _historiesArray = _historiesMutableArray;
}



- (IBAction)typeChanged:(UISegmentedControl *)sender
{
    self.navigationItem.leftBarButtonItem.enabled = YES;
    self.navigationController.toolbarHidden = NO;
    if (self.segmentedControl.selectedSegmentIndex == 1) {
        self.backupButton.enabled = NO;
    } else {
        self.backupButton.enabled = YES;
    }
    [self.tableView reloadData];
}

- (IBAction)touchClearButton:(id)sender {
    NSString *actionSheetTitle;
    if (self.segmentedControl.selectedSegmentIndex == 1)
        actionSheetTitle = @"방문 기록을 모두 지우겠습니까?";
    else
        actionSheetTitle = @"즐겨찾기를 모두 지우겠습니까?";
    
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:actionSheetTitle
                                                                         message:@"지운 후 복구할 수 없습니다."
                                                                  preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *yesAction = [UIAlertAction actionWithTitle:@"모두 지우기"
                                                        style:UIAlertActionStyleDestructive
                                                      handler:^(UIAlertAction * action) {
                                                          if (self.segmentedControl.selectedSegmentIndex == 1) {
                                                              NSString *filePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
                                                              NSString *fileName =  @"historiesFile";
                                                              NSString *fileAtPath = [filePath stringByAppendingPathComponent:fileName];
                                                              [_historiesMutableArray removeAllObjects];
                                                              [_historiesMutableArray writeToFile:fileAtPath atomically:NO];
                                                              [self saveHistories];
                                                          }
                                                          else {
                                                              NSString *filePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
                                                              NSString *fileName =  @"bookmarksFile";
                                                              NSString *fileAtPath = [filePath stringByAppendingPathComponent:fileName];
                                                              [_bookmarksMutableArray removeAllObjects];
                                                              [_bookmarksMutableArray writeToFile:fileAtPath atomically:NO];
                                                              [self saveBookmarks];
                                                          }
                                                          [self.tableView reloadData];
                                                          self.tableView.tableFooterView = [UIView new];

                                                      }];
    [actionSheet addAction:yesAction];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"취소"
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * action) {
                                                             [actionSheet dismissViewControllerAnimated:YES completion:nil];
                                                         }];
    [actionSheet addAction:cancelAction];
    
    actionSheet.popoverPresentationController.sourceView = self.view;
    actionSheet.popoverPresentationController.sourceRect = self.view.bounds;
    actionSheet.popoverPresentationController.barButtonItem = _clearButton;
    
    [self presentViewController:actionSheet animated:YES completion:nil];
}

- (IBAction)touchBackupButton:(id)sender {
    
    NSMutableString *writeString = [NSMutableString stringWithCapacity:0];
    for (int i=0; i<[_bookmarksArray count]; i++) {
        [writeString appendString:[NSString stringWithFormat:@"%@\n",_bookmarksArray[i]]];
    }
/*
    NSString *filePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSURL *objectsToShare;

    if (self.segmentedControl.selectedSegmentIndex == 1) {
        objectsToShare = [NSURL fileURLWithPath:[filePath stringByAppendingPathComponent:@"historiesFile"]];
    } else {
        objectsToShare = [NSURL fileURLWithPath:[filePath stringByAppendingPathComponent:@"bookmarksFile"]];
    } */
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString * cachesDirectory = [paths objectAtIndex:0];
    NSString * filePath = [cachesDirectory stringByAppendingPathComponent:@"NamuViewerBookmarks.csv"];
    [writeString writeToFile:filePath atomically:NO encoding:NSUTF8StringEncoding error:nil];
    UIActivityViewController *controller = [[UIActivityViewController alloc] initWithActivityItems:@[[NSURL fileURLWithPath:filePath]] applicationActivities:nil];
    [self presentViewController:controller animated:YES completion:nil];
    
    [[NSFileManager defaultManager] removeItemAtPath:[filePath stringByAppendingPathComponent:@"NamuViewerBookmarks.csv"] error:NULL];
}

- (BOOL)isForceTouchAvailable {
    BOOL isForceTouchAvailable = NO;
    if ([self.traitCollection respondsToSelector:@selector(forceTouchCapability)]) {
        isForceTouchAvailable = self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable;
    }
    return isForceTouchAvailable;
}

#pragma mark - Observer

- (void)storeDidChange:(NSNotification *)notification
{
    // Retrieve the changes from iCloud
    _bookmarksArray = [[[NSUbiquitousKeyValueStore defaultStore] arrayForKey:@"bookmarksFile"] mutableCopy];
    _bookmarksMutableArray = [_bookmarksArray mutableCopy];
    
    // Reload the table view to show changes
    [self.tableView reloadData];
}

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
- (void)setupCoreSpotlightSearch {
    CSSearchableItemAttributeSet *attributeSet;
    attributeSet = [[CSSearchableItemAttributeSet alloc]
                    initWithItemContentType:(NSString *)kUTTypeImage];
    
    attributeSet.title = @"My First Spotlight Search";
    attributeSet.contentDescription = @"This is my first spotlight Search";
    
    attributeSet.keywords = self.bookmarksArray;
    
    CSSearchableItem *item = [[CSSearchableItem alloc]
                              initWithUniqueIdentifier:@"com.deeplink"
                              domainIdentifier:@"spotlight.sample"
                              attributeSet:attributeSet];
    
    [[CSSearchableIndex defaultSearchableIndex] indexSearchableItems:@[item]
                                                   completionHandler: ^(NSError * __nullable error) {
                                                       if (!error)
                                                           NSLog(@"Search item indexed");
                                                   }];
} */
@end
