//
//  TocViewController.m
//  namuViewer
//

#import "TocViewController.h"
#import <TFHpple/TFHpple.h>

@interface TocViewController ()
@property NSMutableArray *tocItems;
@property UITapGestureRecognizer *tapGesture;

@property NSMutableArray *commands;
@end

@implementation TocViewController



- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    UIBarButtonItem *doneButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Close"] style:UIBarButtonItemStyleDone target:self action:@selector(dismissModal:)];
    self.navigationItem.rightBarButtonItem = doneButtonItem;

    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.tableView.bounds.size.width, 0.01f)];
    
/*
    WKWebViewConfiguration *webViewConfig = [[WKWebViewConfiguration alloc] init];
    _webView = [[WKWebView alloc] initWithFrame:self.view.frame configuration:webViewConfig];
    _webView.navigationDelegate = self;
    _webView.UIDelegate = self;
    
    if (!self.html) self.html = @"...";
    [_webView loadHTMLString:self.html baseURL:nil];
    self.view = _webView; */
    NSData  * data      = [self.html dataUsingEncoding:NSUTF8StringEncoding];
    TFHpple * doc       = [[TFHpple alloc] initWithHTMLData:data];
    NSArray * elements  = [doc searchWithXPathQuery:@"//div[@class='toc-indent']//span[@class='toc-item']"];
    
    self.tocItems = [[NSMutableArray alloc] initWithCapacity:0];
    for (TFHppleElement *element in elements) {
        /*
        if ([[[element parent] objectForKey:@"class"] isEqualToString:@"toc-indent"]) {
            NSLog(@"%@", [element parent]);
        } */
        NSDictionary *dic = @{
                              @"no":[[element firstChild] content],
                              @"title":[element content],
                              @"indent":@0
                              };
        [self.tocItems addObject:dic];
    
    }
    
    [self changeTheme];

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

- (void)dismissModal:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)changeTheme {
    NSString *theme = [[NSUserDefaults standardUserDefaults] stringForKey:@"theme"];
    
    UIColor *tintColor = [UIColor colorWithRed:0.00 green:0.51 blue:0.46 alpha:1.00];
    if ([theme isEqualToString:@"namu"]) {
        self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
        self.navigationController.navigationBar.barTintColor = tintColor;
        self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
        
        self.navigationController.toolbar.barStyle = UIBarStyleBlack;
        self.navigationController.toolbar.barTintColor = tintColor;
        self.navigationController.toolbar.tintColor = [UIColor whiteColor];
    } else if ([theme isEqualToString:@"black"]) {
        self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
        self.navigationController.navigationBar.barTintColor = nil;
        self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
        
        self.navigationController.toolbar.barStyle = UIBarStyleBlack;
        self.navigationController.toolbar.barTintColor = nil;
        self.navigationController.toolbar.tintColor = [UIColor whiteColor];
        
        self.tableView.backgroundColor = [UIColor colorWithRed:0.22 green:0.23 blue:0.24 alpha:1.00];
        self.tableView.separatorColor = [UIColor colorWithWhite:.5f alpha:.5f];
    } else if ([theme isEqualToString:@"blackorange"]) {
        UIColor *orangeColor = [UIColor colorWithRed:0.79 green:0.53 blue:0.09 alpha:1.00];
        self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
        self.navigationController.navigationBar.barTintColor = nil;
        self.navigationController.navigationBar.tintColor = orangeColor;
        
        self.navigationController.toolbar.barStyle = UIBarStyleBlack;
        self.navigationController.toolbar.barTintColor = nil;
        self.navigationController.toolbar.tintColor = orangeColor;
        
        self.tableView.backgroundColor = [UIColor colorWithRed:0.22 green:0.23 blue:0.24 alpha:1.00];
        self.tableView.separatorColor = [UIColor colorWithWhite:.5f alpha:.5f];

    } else if ([theme isEqualToString:@"ios"]) {
        self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
        self.navigationController.navigationBar.barTintColor = nil;
        self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0];
        
        self.navigationController.toolbar.barStyle = UIBarStyleDefault;
        self.navigationController.toolbar.barTintColor = nil;
        self.navigationController.toolbar.tintColor = [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0];
    } else {
        self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
        self.navigationController.navigationBar.barTintColor = nil;
        self.navigationController.navigationBar.tintColor = tintColor;
        
        self.navigationController.toolbar.barStyle = UIBarStyleDefault;
        self.navigationController.toolbar.barTintColor = nil;
        self.navigationController.toolbar.tintColor = tintColor;
    }
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    return self.tocItems.count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.delegate tocTableViewControllerDismissed:self.tocItems[indexPath.row][@"no"]];
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
    
    cell.textLabel.text = self.tocItems[indexPath.row][@"title"];
    
    return cell;
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

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

@end
