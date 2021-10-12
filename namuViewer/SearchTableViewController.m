//
//  SearchTableViewController.m
//  namuViewer
//

#import "SearchTableViewController.h"

@interface SearchTableViewController ()
@property NSMutableArray *autoCompleteArray;
@property NSOperationQueue *autoCompleteQueue;
@property UITapGestureRecognizer *tapGesture;

@end

@implementation SearchTableViewController

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    
    self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapBehind:)];
    [self.tapGesture setNumberOfTapsRequired:1];
    self.tapGesture.cancelsTouchesInView = NO;
    [self.view.window addGestureRecognizer:self.tapGesture];
    self.tapGesture.delegate = self;
}

- (void)didPresentSearchController:(UISearchController *)searchController
{

    [searchController.searchBar becomeFirstResponder];
}


- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{

    

    // [self.tableView reloadData];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [_searchField becomeFirstResponder];
    
    /* 
     [self.searchController setActive:YES];
     [self.searchController.searchBar becomeFirstResponder];
*/
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.view.window removeGestureRecognizer:self.tapGesture];
    [_searchField resignFirstResponder];
    [[self.autoCompleteQueue.operations lastObject] cancel];
    /*
     [self.searchController setActive:YES];
     [self.searchController.searchBar becomeFirstResponder];
     */
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [[self.autoCompleteQueue.operations lastObject] cancel];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;

    _searchField.delegate = self;

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Close"] style:UIBarButtonItemStyleDone target:self action:@selector(dismiss:)];

/*
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.delegate = self;
    self.searchController.searchBar.delegate = self;
    self.searchController.searchResultsUpdater = self;
    self.searchController.dimsBackgroundDuringPresentation = NO;
    self.searchController.searchBar.showsCancelButton = YES;
   

    self.searchController.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    // self.tableView.tableHeaderView = self.searchController.searchBar;
    [self.searchController.searchBar sizeToFit];
    self.searchController.hidesNavigationBarDuringPresentation = NO;
    */
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    

    /* CALayer *border = [CALayer layer];
    border.backgroundColor = [UIColor lightGrayColor].CGColor;

    border.frame = CGRectMake(0, self.tableView.tableHeaderView.frame.size.height - .5f, self.tableView.tableHeaderView.frame.size.width, .5f);
    
    [self.tableView.tableHeaderView.layer addSublayer:border]; */

	// TODO
//	if (@available(iOS 11.0, *)) {
//		self.navigationItem.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
//		self.navigationItem.hidesSearchBarWhenScrolling = NO;
//		self.navigationItem.searchController.dimsBackgroundDuringPresentation = NO;
//		self.navigationItem.rightBarButtonItem = NULL;
//		self.navigationItem.titleView = NULL;
//	}

	// iOS13 강제 라이트모드
	if (@available(iOS 13.0, *)) {
		self.navigationController.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
	}
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)dismiss:(id)sender{
    [[self.autoCompleteQueue.operations lastObject] cancel];
    [self dismissViewControllerAnimated:YES completion:nil];

}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.autoCompleteArray.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    NSString *theme = [[NSUserDefaults standardUserDefaults] stringForKey:@"theme"];
    
    if ([theme isEqualToString:@"black"] || [theme isEqualToString:@"blackorange"]) {
        cell.backgroundColor = [UIColor blackColor];
        cell.textLabel.textColor = [UIColor whiteColor];
        
        UIView *selectionColor = [[UIView alloc] init];
        selectionColor.backgroundColor = [UIColor colorWithRed:0.22 green:0.23 blue:0.24 alpha:1.00];
        cell.selectedBackgroundView = selectionColor;
    }

    // cell.textLabel.text = self.autoCompleteArray[indexPath.row];
    
    /*
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:self.autoCompleteArray[indexPath.row]];
    
    [attributedString addAttribute:NSForegroundColorAttributeName value:[UIColor grayColor] range:NSMakeRange(0,5)];
    */
    NSString *searchText = _searchField.text;
    NSString *resultsText;
    @try {
        resultsText = self.autoCompleteArray[indexPath.row];
    }
    @catch (NSException *exception) {
        self.autoCompleteArray = [NSMutableArray new];
        [self.tableView reloadData];
        NSLog(@"catched");
        return cell;
    }
    
    NSMutableAttributedString *mutableAttributedString = [[NSMutableAttributedString alloc] initWithString:resultsText];

    NSString * regexPattern = [NSString stringWithFormat:@"(%@)", searchText];

    // We create a case insensitive regex passing in our pattern
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexPattern options:NSRegularExpressionCaseInsensitive error:nil];
    
    NSRange range = NSMakeRange(0,resultsText.length);
    
    [regex enumerateMatchesInString:resultsText
                            options:kNilOptions
                              range:range
                         usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
                             
                             NSRange subStringRange = [result rangeAtIndex:1];
                             
                             // Make the range bold
                             [mutableAttributedString addAttribute:NSFontAttributeName
                                                             value:[UIFont boldSystemFontOfSize:16.0]
                                                             range:subStringRange];
                         }];

    cell.textLabel.attributedText = mutableAttributedString;
    
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    switch (indexPath.section) {
        case 0:{
            [self.view.window removeGestureRecognizer:self.tapGesture];
            if([self.delegate respondsToSelector:@selector(searchTableViewControllerDismissed:)]) {
                [[self.autoCompleteQueue.operations lastObject] cancel];
                NSString *urlString = [NSString stringWithFormat:@"http://namu.wiki/go/%@",cell.textLabel.text];
                urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                [self.delegate searchTableViewControllerDismissed:urlString];
                
            }
        
            [self dismissViewControllerAnimated:YES completion:nil];
            break;
        }
    }
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0)
        return CGFLOAT_MIN;
    return tableView.sectionHeaderHeight;
}

/*
- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView {
    
    NSString *text = @"나무위키 검색";
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont boldSystemFontOfSize:20.0],
                                 NSForegroundColorAttributeName: [UIColor darkGrayColor]};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (NSAttributedString *)descriptionForEmptyDataSet:(UIScrollView *)scrollView {
    
    NSString *text = @"나무위키에 검색할 항목을 입력해주세요.";
    
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
    return [UIImage imageNamed:@"Search"];
}
 */ 

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

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

- (IBAction)dismissModal:(id)sender {
    [self.view.window removeGestureRecognizer:self.tapGesture];
    [[self.autoCompleteQueue.operations lastObject] cancel];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == _searchField) {
        [textField resignFirstResponder];
        
        [self.view.window removeGestureRecognizer:self.tapGesture];
        
        if ([_searchField.text isEqualToString:@""]) {
            [self dismissModal:nil];
            return YES;
        }
        if([self.delegate respondsToSelector:@selector(searchTableViewControllerDismissed:)]) {
            [[self.autoCompleteQueue.operations lastObject] cancel];
            NSString *urlString = [NSString stringWithFormat:@"http://namu.wiki/go/%@", _searchField.text];
            urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            [self.delegate searchTableViewControllerDismissed:urlString];
        }

        [self dismissViewControllerAnimated:YES completion:nil];
        
        return NO;
    }
    return YES;
}

- (IBAction)searching:(id)sender {
    NSString *searchString = [_searchField.text lowercaseString];
    
    if ([searchString isEqualToString:@""]) {
        self.autoCompleteArray = [NSMutableArray new];
        [[self.autoCompleteQueue.operations lastObject] cancel];
        [self.tableView reloadData];
    } else {
        self.autoCompleteArray = [NSMutableArray new];
		NSLog(@"%@", [[NSString stringWithFormat:@"https://namu.wiki/internal/Complete?b=d770bd6d531077704&q=%@",searchString] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]);
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[[NSString stringWithFormat:@"https://namu.wiki/internal/Complete?b=d770bd6d531077704&q=%@",searchString] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
        self.autoCompleteQueue = [NSOperationQueue new];
        self.autoCompleteQueue.name = @"autoComplete";
        
        
        [NSURLConnection sendAsynchronousRequest:request queue:self.autoCompleteQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
            // NSLog(@"data:%@",[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil]);
            if ([data length] > 0 && error == nil){
                NSMutableDictionary *aca = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.autoCompleteArray = aca[@"data"];
                    
                    [self.tableView reloadData];
                    // NSLog(@"%@ %@",searchString,self.autoCompleteArray);
                    // NSLog(@"%lu",(unsigned long)self.autoCompleteArray.count);
                    [[self.autoCompleteQueue.operations lastObject] cancel];
                });
            }
            else if ([data length] == 0 && error == nil)
                NSLog(@"emptydata"); // empty
            else if (error != nil && error.code == NSURLErrorTimedOut)
                NSLog(@"timeout"); // timeout
            else if (error != nil)
                NSLog(@"downloaderror"); // timeout
            else {
                self.autoCompleteArray = [NSMutableArray new];
                [self.tableView reloadData];
            }
        }];
        
    }
}

/*
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat sectionHeaderHeight = self.tableView.sectionHeaderHeight;
    if (scrollView.contentOffset.y<=sectionHeaderHeight&&scrollView.contentOffset.y>=0) {
        scrollView.contentInset = UIEdgeInsetsMake(-scrollView.contentOffset.y, 0, 0, 0);
    } else if (scrollView.contentOffset.y>=sectionHeaderHeight) {
        scrollView.contentInset = UIEdgeInsetsMake(-sectionHeaderHeight, 0, 0, 0);
    }
}
*/


- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView {
    self.navigationItem.leftBarButtonItem.enabled = NO;
    self.navigationController.toolbarHidden = YES;
    NSString *text = @"검색";
    
    UIColor *color = [UIColor darkGrayColor];
    
    NSString *theme = [[NSUserDefaults standardUserDefaults] stringForKey:@"theme"];
    if ([theme isEqualToString:@"black"] || [theme isEqualToString:@"blackorange"])
        color = [UIColor whiteColor];

    NSDictionary *attributes = @{/*NSFontAttributeName: [UIFont boldSystemFontOfSize:20.0],*/
                                 NSForegroundColorAttributeName: color};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (NSAttributedString *)descriptionForEmptyDataSet:(UIScrollView *)scrollView {
    
    NSString *text = @"찾고 싶은 항목을 입력해주세요.";
    
    NSMutableParagraphStyle *paragraph = [NSMutableParagraphStyle new];
    paragraph.lineBreakMode = NSLineBreakByWordWrapping;
    paragraph.alignment = NSTextAlignmentCenter;
    
    NSDictionary *attributes = @{/* NSFontAttributeName: [UIFont systemFontOfSize:14.0],*/
                                 NSForegroundColorAttributeName: [UIColor lightGrayColor],
                                 NSParagraphStyleAttributeName: paragraph};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

//- (UIImage *)imageForEmptyDataSet:(UIScrollView *)scrollView
//{
//    NSString *theme = [[NSUserDefaults standardUserDefaults] stringForKey:@"theme"];
//    if ([theme isEqualToString:@"black"] || [theme isEqualToString:@"blackorange"])
//        return nil;
//    else
//        return [UIImage imageNamed:@"EmptyDataSearch"];
//}

- (CGFloat)verticalOffsetForEmptyDataSet:(UIScrollView *)scrollView
{
    return -64;
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




@end
