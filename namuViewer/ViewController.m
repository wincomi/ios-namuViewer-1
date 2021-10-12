//
//  ViewController.m
//  namuViewer
//

#import "ViewController.h"
#import <ARSafariActivity/ARSafariActivity.h>

@interface ViewController ()
@property UIRefreshControl *refreshControl;
@property NSMutableArray *bookmarksMutableArray, *historiesMutableArray, *autoComplateArray;

@property WKWebView *fnWebView;
@property UIAlertController *fnAlert;
@property UIActivityIndicatorView *fnActivityView;

@property UIActivityIndicatorView *titleViewActivityIndicator;
@property BOOL isStar;

@property NSMutableArray *commands;
@property NSUserActivity *handOffActivity;

@end

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];

	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(defaultsDidChange:) name:NSUserDefaultsDidChangeNotification
											   object:nil];

	// [self defaultsDidChange:nil];
	WKWebViewConfiguration *webViewConfig = [[WKWebViewConfiguration alloc] init];
	webViewConfig.allowsInlineMediaPlayback = YES;
	webViewConfig.allowsAirPlayForMediaPlayback = YES;
	webViewConfig.allowsPictureInPictureMediaPlayback = YES;

	_webView = [[WKWebView alloc] initWithFrame:self.view.frame configuration:webViewConfig];
	_webView.navigationDelegate = self;
	_webView.UIDelegate = self;

	_webView.scrollView.minimumZoomScale = 1;
	_webView.scrollView.maximumZoomScale = 6;

	_webView.allowsBackForwardNavigationGestures = YES;
	if (NSClassFromString(@"SFSafariViewController")) // check iOS9
	_webView.allowsLinkPreview = YES;

	self.view = _webView;

	if (@available(iOS 13.0, *)) {
		[self.navigationController.view setBackgroundColor:[UIColor systemBackgroundColor]];
	} else {
		[self.navigationController.view setBackgroundColor:[UIColor whiteColor]];
	}

	NSURL *url;
	NSString *openURLOnLoad = [[NSUserDefaults standardUserDefaults] stringForKey:@"openURLOnLoad"];
	if(openURLOnLoad)
	url = [NSURL URLWithString:openURLOnLoad];
	else
	url = [NSURL URLWithString:@"https://namu.wiki"];

	NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
	[_webView loadRequest:urlRequest];

	_handOffActivity = [[NSUserActivity alloc] initWithActivityType:@"com.wincomi.ios.namuViewer.url"];
	_handOffActivity.webpageURL = url;
	[_handOffActivity becomeCurrent];

	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"openURLOnLoad"];
	[[NSUserDefaults standardUserDefaults] synchronize];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(openURLNotification:) name:@"openURL" object:nil];

	/*
	 NSURLRequest *webViewRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://namu.wiki/w/"]];
	 [_webView loadRequest:webViewRequest];
	 */
	NSString *otherCSS;
	if ([[NSUserDefaults standardUserDefaults] stringForKey:@"fontsize"]) {
		otherCSS = [NSString stringWithFormat:@"body, th, td, input, select, textarea, button, div, p, li{font-size:%@rem !important}", [[NSUserDefaults standardUserDefaults] stringForKey:@"fontsize"]];
	}
	if ([[NSUserDefaults standardUserDefaults] stringForKey:@"lineheight"]) {
		otherCSS = [NSString stringWithFormat:@"%@body, th, td, input, select, textarea, button, div, p, li{line-height:%@ !important}", otherCSS, [[NSUserDefaults standardUserDefaults] stringForKey:@"lineheight"]];
	}


	// 광고 차단 v1.4.1
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"adblock"] == YES) {
		otherCSS = [NSString stringWithFormat:@"%@.adsense,.ad-card,.ad-bottom, div.ad, .adsbygoogle,div.ad,div[id^=\"google_ads\"]{display:none !important;}" ,otherCSS];
	}

	NSString *css = @"p.wiki-edit-date+div[id^=div-gpt-ad-]{overflow:hidden}.wiki-article .wiki-table-wrap{-webkit-overflow-scrolling:touch;}.footer{word-break:break-all}.live-list-card{display:none !important}"; // 글자 크기 엄청 크기 푸터 넘침 해결, 나무라이브 숨김 (v1.5.1)
	NSString *otherSettings = @"";
	// if ([[NSUserDefaults standardUserDefaults] boolForKey:@"use_fnAlert"] != NO)
	// otherSettings = @"namu.userSettings['enable_popfn'] = false;";


	NSString *namu_strike = [[NSUserDefaults standardUserDefaults] stringForKey:@"namu_strike"];
	if (namu_strike) {
		otherSettings = [NSString stringWithFormat:@"%@namu.userSettings['strike'] = '%@';", otherSettings, [[NSUserDefaults standardUserDefaults] stringForKey:@"namu_strike"]];
	}

	NSString *footnote_type = [[NSUserDefaults standardUserDefaults] stringForKey:@"footnote_type"];
	if ([footnote_type isEqual:@"app"]) {
		otherSettings = [NSString stringWithFormat:@"%@namu.userSettings['footnote_type'] = 'default';", otherSettings];
	} else if (footnote_type) {
		otherSettings = [NSString stringWithFormat:@"%@namu.userSettings['footnote_type'] = '%@';", otherSettings, footnote_type];
	}

	NSString *js = [NSString stringWithFormat:
					@"var styleNode = document.createElement('style');\n"
					"styleNode.type = \"text/css\";\n"
					"var styleText = document.createTextNode('%@%@');\n"
					"styleNode.appendChild(styleText);\n"
					"document.getElementsByTagName('head')[0].appendChild(styleNode);\n"
					"namu.userSettings['hide_navcontrol'] = true;%@namu.saveUserSettings();\n"
					//"jQuery('#searchInput').click(function(){webkit.messageHandlers.callbackHandler.postMessage('searchInputClicked');});"
					,css, otherCSS, otherSettings];

	// 페이지 검색 기능 추가 v1.5
	NSString *const FindInPageJS = @"function _namuviewer_find_in_page(text){/*var text=prompt(\"검색할 항목을 입력하세요:\",\"\");*/if(text==null||text.length==0){alert(\"검색 결과가 없습니다.\")}var spans=document.getElementsByClassName(\"labnol\");if(spans){for(var i=0;i<spans.length;i++){spans[i].style.backgroundColor=\"transparent\"}}function searchWithinNode(node,te,len){var pos,skip,spannode,middlebit,endbit,middleclone;skip=0;if(node.nodeType==3){pos=node.data.indexOf(te);if(pos>=0){spannode=document.createElement(\"span\");spannode.setAttribute(\"class\",\"labnol\");spannode.style.backgroundColor=\"yellow\";middlebit=node.splitText(pos);endbit=middlebit.splitText(len);middleclone=middlebit.cloneNode(true);spannode.appendChild(middleclone);middlebit.parentNode.replaceChild(spannode,middlebit);skip=1}}else if(node.nodeType==1&&node.childNodes&&node.tagName.toUpperCase()!=\"SCRIPT\"&&node.tagName.toUpperCase!=\"STYLE\"){for(var child=0;child<node.childNodes.length;++child){child=child+searchWithinNode(node.childNodes[child],te,len)}}return skip}searchWithinNode(document.body,text,text.length)}// Find in page Source: https://ctrlq.org/code/19509-find-on-page-bookmarklet";
	js = [NSString stringWithFormat:@"%@\n%@", js, FindInPageJS];

	WKUserScript *script = [[WKUserScript alloc] initWithSource:js injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:NO];
	[_webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:NULL];

	// [_webView.configuration.userContentController addScriptMessageHandler:self name:@"searchInputClicked"];
	[_webView.configuration.userContentController addUserScript:script];

	_refreshControl = [[UIRefreshControl alloc] init];
	[_webView.scrollView addSubview:_refreshControl];
	[_refreshControl addTarget:self action:@selector(reloadWebView) forControlEvents:UIControlEventValueChanged];

	NSString *filePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	//    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"use_icloud"] == YES) {
	//        _bookmarksMutableArray = [[[NSUbiquitousKeyValueStore defaultStore] arrayForKey:@"bookmarksFile"] mutableCopy];
	//    } else {
	//        _bookmarksMutableArray = [[NSMutableArray alloc] initWithContentsOfFile:[filePath stringByAppendingPathComponent:@"bookmarksFile"]];
	//    }
	//    _historiesMutableArray = [[NSMutableArray alloc] initWithContentsOfFile:[filePath stringByAppendingPathComponent:@"historiesFile"]];
	[self getbookmarkHistories];

	_tocButton.enabled = NO;

	NSString *customCSSFile = [filePath stringByAppendingPathComponent:@"custom.css"];
	if ([[NSFileManager defaultManager] fileExistsAtPath:customCSSFile]) {
		NSString *css = [NSString stringWithContentsOfFile:customCSSFile encoding: NSUTF8StringEncoding error: nil];
		css = [css stringByReplacingOccurrencesOfString:@"\n" withString:@""];

		NSString *js = [NSString stringWithFormat:
						@"var styleNode = document.createElement('style');styleNode.type = \"text/css\";var styleText = document.createTextNode('%@');styleNode.appendChild(styleText);document.getElementsByTagName('head')[0].appendChild(styleNode);", css];
		// NSLog(@"%@",js);
		[_webView.configuration.userContentController addUserScript:[[WKUserScript alloc] initWithSource:js injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:NO]];
	}

	// self.navigationItem.leftBarButtonItem = _goBackButton;
	self.navigationItem.title = @"나무위키";

	dispatch_async(dispatch_get_main_queue(), ^{
		[self changeTheme];
	});


	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"use_icloud"] == YES) {
		//  Observer to catch changes from iCloud
		NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(storeDidChange:)
													 name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification
												   object:store];

		[[NSUbiquitousKeyValueStore defaultStore] synchronize];
	}

}

- (void)getbookmarkHistories {
	NSString *filePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"use_icloud"] == YES) {
		_bookmarksMutableArray = [[[NSUbiquitousKeyValueStore defaultStore] arrayForKey:@"bookmarksFile"] mutableCopy];
	} else {
		_bookmarksMutableArray = [[NSMutableArray alloc] initWithContentsOfFile:[filePath stringByAppendingPathComponent:@"bookmarksFile"]];
	}
	_historiesMutableArray = [[NSMutableArray alloc] initWithContentsOfFile:[filePath stringByAppendingPathComponent:@"historiesFile"]];

}

- (void)defaultsDidChange:(NSNotification *)aNotification
{
	dispatch_async(dispatch_get_main_queue(), ^{
		[self changeTheme];
	});

	NSString *otherCSS;
	if ([[NSUserDefaults standardUserDefaults] stringForKey:@"fontsize"]) {
		otherCSS = [NSString stringWithFormat:@"body, th, td, input, select, textarea, button, div, p, li{font-size:%@rem !important}", [[NSUserDefaults standardUserDefaults] stringForKey:@"fontsize"]];
	}
	if ([[NSUserDefaults standardUserDefaults] stringForKey:@"lineheight"]) {
		otherCSS = [NSString stringWithFormat:@"%@body, th, td, input, select, textarea, button, div, p, li{line-height:%@ !important}", otherCSS, [[NSUserDefaults standardUserDefaults] stringForKey:@"lineheight"]];
	}

	// 광고 차단 v1.4.1
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"adblock"] == YES) {
		otherCSS = [NSString stringWithFormat:@"%@.adsense,.ad-card,.ad-bottom, div.ad, .adsbygoogle,div.ad,div[id^=\"google_ads\"]{display:none !important;}" ,otherCSS];
	}
	
	NSString *otherSettings = @"";
	NSString *footnote_type = [[NSUserDefaults standardUserDefaults] stringForKey:@"footnote_type"];
	if ([footnote_type isEqual:@"app"]) {
		otherSettings = [NSString stringWithFormat:@"%@namu.userSettings['footnote_type'] = 'default';", otherSettings];
	} else if (footnote_type) {
		otherSettings = [NSString stringWithFormat:@"%@namu.userSettings['footnote_type'] = '%@';", otherSettings, footnote_type];
	}

	NSString *js = [NSString stringWithFormat:
					@"var styleNode = document.createElement('style');\n"
					"styleNode.type = \"text/css\";\n"
					"var styleText = document.createTextNode('%@');\n"
					"styleNode.appendChild(styleText);\n"
					"document.getElementsByTagName('head')[0].appendChild(styleNode);\n"
					"namu.userSettings['hide_navcontrol'] = true;%@namu.saveUserSettings();\n"
					,otherCSS, otherSettings];

	dispatch_async(dispatch_get_main_queue(), ^{
		WKUserScript *script = [[WKUserScript alloc] initWithSource:js injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:NO];
		[_webView.configuration.userContentController addUserScript:script];
	});
}

- (void)changeTheme {
	NSString *theme = [[NSUserDefaults standardUserDefaults] stringForKey:@"theme"];

	UIColor *tintColor = [UIColor colorWithRed:0.00 green:0.51 blue:0.46 alpha:1.00];
	if ([theme isEqualToString:@"namu"]) {
		// 1.6.4
		NSDictionary *attrs = @{
			NSForegroundColorAttributeName :  [UIColor whiteColor],
		};
		self.navigationController.navigationBar.titleTextAttributes = attrs;

		self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
		self.navigationController.navigationBar.barTintColor = tintColor;
		self.navigationController.navigationBar.tintColor = [UIColor whiteColor];

		self.navigationController.toolbar.barStyle = UIBarStyleBlack;
		self.navigationController.toolbar.barTintColor = tintColor;
		self.navigationController.toolbar.tintColor = [UIColor whiteColor];
		_actionButton.tintColor = [UIColor whiteColor];
		_bookmarkButton.tintColor = [UIColor whiteColor];

		//        _drawer.barStyle = UIBarStyleDefault;
		//        _drawer.barTintColor = tintColor;
		//        _drawer.tintColor = [UIColor whiteColor];

		_titleViewActivityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
		self.view.backgroundColor = [UIColor whiteColor];
	} else if ([theme isEqualToString:@"black"]) {
		// 1.6.4
		NSDictionary *attrs = @{
			NSForegroundColorAttributeName :  [UIColor whiteColor],
		};
		self.navigationController.navigationBar.titleTextAttributes = attrs;

		self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
		self.navigationController.navigationBar.barTintColor = nil;
		self.navigationController.navigationBar.tintColor = [UIColor whiteColor];

		self.navigationController.toolbar.barStyle = UIBarStyleBlack;
		self.navigationController.toolbar.barTintColor = nil;
		self.navigationController.toolbar.tintColor = [UIColor whiteColor];
		_actionButton.tintColor = [UIColor whiteColor];
		_bookmarkButton.tintColor = [UIColor whiteColor];

		//        _drawer.barStyle = UIBarStyleBlackTranslucent;
		//        _drawer.barTintColor = nil;
		//        _drawer.tintColor = [UIColor whiteColor];

		_titleViewActivityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;

		self.view.backgroundColor = [UIColor blackColor];
	} else if ([theme isEqualToString:@"blackorange"]) {
		// 1.6.4
		NSDictionary *attrs = @{
			NSForegroundColorAttributeName :  [UIColor whiteColor],
		};
		self.navigationController.navigationBar.titleTextAttributes = attrs;

		UIColor *orangeColor = [UIColor colorWithRed:0.79 green:0.53 blue:0.09 alpha:1.00];
		self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
		self.navigationController.navigationBar.barTintColor = nil;
		self.navigationController.navigationBar.tintColor = orangeColor;

		self.navigationController.toolbar.barStyle = UIBarStyleBlack;
		self.navigationController.toolbar.barTintColor = nil;
		self.navigationController.toolbar.tintColor = orangeColor;
		_actionButton.tintColor = orangeColor;
		_bookmarkButton.tintColor = orangeColor;

		//        _drawer.barStyle = UIBarStyleBlackTranslucent;
		//        _drawer.barTintColor = nil;
		//        _drawer.tintColor = orangeColor;

		_titleViewActivityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;

		self.view.backgroundColor = [UIColor blackColor];
	} else if ([theme isEqualToString:@"ios"]) {
		// 1.6.4
		NSDictionary *attrs = @{
			NSForegroundColorAttributeName : [UIColor blackColor]
		};
		self.navigationController.navigationBar.titleTextAttributes = attrs;

		self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
		self.navigationController.navigationBar.barTintColor = nil;
		self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0];

		self.navigationController.toolbar.barStyle = UIBarStyleDefault;
		self.navigationController.toolbar.barTintColor = nil;
		self.navigationController.toolbar.tintColor = [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0];
		_actionButton.tintColor = nil;
		_bookmarkButton.tintColor = nil;

		//        _drawer.barStyle = UIBarStyleDefault;
		//        _drawer.barTintColor = nil;
		//        _drawer.tintColor = [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0];

		_titleViewActivityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
		self.view.backgroundColor = [UIColor whiteColor];
	} else {
		// 1.6.4
		dispatch_async(dispatch_get_main_queue(), ^{
			NSDictionary *attrs = @{
				NSForegroundColorAttributeName : [UIColor blackColor]
			};
			self.navigationController.navigationBar.titleTextAttributes = attrs;

			self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
			self.navigationController.navigationBar.barTintColor = nil;
			self.navigationController.navigationBar.tintColor = tintColor;

			self.navigationController.toolbar.barStyle = UIBarStyleDefault;
			self.navigationController.toolbar.barTintColor = nil;
			self.navigationController.toolbar.tintColor = tintColor;
		});
		_actionButton.tintColor = tintColor;
		_bookmarkButton.tintColor = tintColor;

		//        _drawer.barStyle = UIBarStyleDefault;
		//        _drawer.barTintColor = nil;
		//        _drawer.tintColor = tintColor;
		_titleViewActivityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
		self.view.backgroundColor = [UIColor whiteColor];
	}

}

#pragma mark - WebView


- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation {
	NSLog(@"didFinishNavigation");
	if(webView == _fnWebView){
		[_fnActivityView stopAnimating];
		return;
	}

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	_goBackButton.enabled = YES;
	_goForwardButton.enabled = YES;

//	_goBackButton.enabled = _webView.canGoBack;
//	_goForwardButton.enabled = _webView.canGoForward;


	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"disable_zoom"] != YES) {
		[_webView evaluateJavaScript:@"jQuery('meta[name=viewport]').attr('content', 'user-scalable=yes, initial-scale=1.0, maximum-scale=4.0, minimum-scale=1.0, width=device-width');" completionHandler: nil];
	}

	[_webView evaluateJavaScript:@"document.getElementById('toc').innerHTML" completionHandler:^(id result, NSError *error) {
		if (error == nil) {
			if (result != nil) {
				_tocButton.enabled = YES;

			} else
			_tocButton.enabled = NO;
		} else {
			_tocButton.enabled = NO;
			// NSLog(@"evaluateJavaScript error : %@", error.localizedDescription);
		}
	}];



	[_webView evaluateJavaScript:@"document.querySelectorAll('div.r + h1>a[href]')[0].innerText.trim()" completionHandler:^(id message, NSError *error) {
		NSString *wikiTitle = [message description];

		if (!wikiTitle) {
			return;
			/*
			 wikiTitle = _webView.title;
			 wikiTitle = [wikiTitle stringByReplacingOccurrencesOfString:@" - 나무위키" withString:@""];
			 */
		}
		if ([wikiTitle isEqualToString:@""])
		wikiTitle = @"";
		// _searchController.searchBar.placeholder = wikiTitle;

		self.navigationItem.title = @"나무위키";

		self.isStar = [_bookmarksMutableArray containsObject:wikiTitle];
		if (self.isStar) _starButton.image = [UIImage imageNamed:@"Star Highlight"];
		else _starButton.image = [UIImage imageNamed:@"Star"];

		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"enabled_history"] != NO) {
			if ([wikiTitle isEqualToString:@"나무위키:대문"]) return; // FrontPage는 최근 본 항목에 추가 안함
			if ([_webView.URL.absoluteString containsString:@"/search/"] ||
				[_webView.URL.absoluteString containsString:@"/xref/"] ||
				[_webView.URL.absoluteString containsString:@"/discuss/"] ||
				[_webView.URL.absoluteString containsString:@"/edit/"] ||
				[_webView.URL.absoluteString containsString:@"/delete/"] ||
				[_webView.URL.absoluteString containsString:@"/history/"] ||
				[_webView.URL.absoluteString containsString:@"/diff/"]
				) return; // 검색 결과는 추가 안함

			[self getbookmarkHistories];

			if(!_historiesMutableArray) _historiesMutableArray = [NSMutableArray new];
			if(_historiesMutableArray.count > 1 && [[_historiesMutableArray objectAtIndex:0] isEqual:wikiTitle]) return;

			[_historiesMutableArray insertObject:wikiTitle atIndex:0];

			NSString *filePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
			NSString *fileName =  @"historiesFile";
			NSString *fileAtPath = [filePath stringByAppendingPathComponent:fileName];
			if(![[NSFileManager defaultManager] fileExistsAtPath:fileAtPath])
			[[NSFileManager defaultManager] createFileAtPath:fileAtPath contents:nil attributes:nil];
			[_historiesMutableArray writeToFile:fileAtPath atomically:NO];
		}
	}];

}

- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures {
	NSString *urlString = [navigationAction.request.URL.absoluteString lowercaseString];

	// 1.3.19 나무라이브 광고 차단
	if ([urlString containsString:@"namu.live/static/ad"]) {
		return nil;
	}

	if(!([urlString hasPrefix:@"http://namu.wiki"] || [urlString hasPrefix:@"https://namu.wiki"])) {
		[self openURLonSafari:navigationAction.request.URL];

		return nil;
	} else {
		_handOffActivity.webpageURL = navigationAction.request.URL;
		[_handOffActivity becomeCurrent];
	}

	if (!navigationAction.targetFrame.isMainFrame) {
		[webView loadRequest:navigationAction.request];
		return nil;
	}

	return nil;
}


- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{

	NSString *urlString = [navigationAction.request.URL.absoluteString lowercaseString];
	//NSLog(@"%@", urlString);
	// 1.3.19 나무라이브 광고 차단
	if ([urlString containsString:@"namu.live/static/ad"]) {
		decisionHandler(WKNavigationActionPolicyCancel);
		return;
	}

	if(([urlString hasPrefix:@"http://namu.live"] || [urlString hasPrefix:@"https://namu.live"])) {
		[self openURLonSafari:navigationAction.request.URL];
		decisionHandler(WKNavigationActionPolicyCancel);
		return;
	}

	if (![[[NSUserDefaults standardUserDefaults] stringForKey:@"footnote_type"] isEqual:@"app"]) {
		decisionHandler(WKNavigationActionPolicyAllow);
		return;
	}
	if(webView == _fnWebView) {
		// NSString *urlString = [navigationAction.request.URL.absoluteString lowercaseString];

		if([urlString hasPrefix:@"/w/"]) {
			// NSLog(@"decidePolicyForNavigationAction %@", navigationAction.request.URL.absoluteString);
			[self dismissPopUpViewController];
			[_webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://namu.wiki%@", navigationAction.request.URL.absoluteString]]]];
		} else if([urlString hasPrefix:@"http"]) {

			[self dismissPopUpViewControllerWithcompletion:^{
				[self openURLonSafari:navigationAction.request.URL];
			}];

		}
	}
	else if ([navigationAction.request.URL.fragment hasPrefix:@"fn"]) {

		NSString *js = [NSString stringWithFormat:@"$($('[href=#%@]').attr('href')).parents().html();",[navigationAction.request.URL.fragment stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];

		[_webView evaluateJavaScript:js completionHandler:^(id message, NSError *error) {
			/*
			 _fnAlert = [UIAlertController alertControllerWithTitle:nil
			 message:nil
			 preferredStyle:UIAlertControllerStyleActionSheet];

			 // _fnAlert = [[UIAlertView alloc] initWithTitle:nil message:nil delegate:self cancelButtonTitle:@"닫기" otherButtonTitles:nil];
			 _fnAlert = [UIAlertController alertControllerWithTitle:@"\n\n\n\n\n\n\n\n\n\n" message:nil preferredStyle:UIAlertControllerStyleAlert];
			 UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"닫기" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
			 [_fnAlert dismissViewControllerAnimated:YES completion:nil];
			 }];
			 [_fnAlert addAction:cancelAction];
			 */
			_fnWebView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 8.f, 270.f, 250.f)];
			_fnWebView.navigationDelegate = self;
			_fnWebView.UIDelegate = self;
			// message = [message stringByReplacingOccurrencesOfString:@"/w/" withString:@"https://namu.wiki/w/"];
			NSString *fontsize = [[NSUserDefaults standardUserDefaults] stringForKey:@"fontsize"];
			if (!fontsize) fontsize = @"0.9";
			NSString *lineheight = [[NSUserDefaults standardUserDefaults] stringForKey:@"lineheight"];
			if (!lineheight) lineheight = @"1.5";

			message = [NSString stringWithFormat:@"<html><head><meta name='viewport' content='width=256, initial-scale=1.0, minimum-scale=1.0' /></head><body><div>%@</div><style>body{margin:8px;width:256px}div{font-size:%@rem;line-height:%@;font-family:AppleSDGothicNeo-Regular}a{color:#007AFF;text-decoration:none;}.wiki-link-external{color:#090}del{color:#999}</style></body></html>", message, fontsize, lineheight];

			[_fnWebView loadHTMLString:message baseURL:nil];
			[_fnWebView setBackgroundColor:[UIColor clearColor]];
			[_fnWebView setOpaque:NO];

			[_fnAlert.view addSubview:_fnWebView];
			// [_fnAlert setValue:_fnWebView forKey:@"accessoryView"];
			// [self presentViewController:_fnAlert animated:YES completion:nil];
			// [_fnAlert show];

			_fnActivityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
			_fnActivityView.frame = CGRectMake(0, 0, 30, 30);
			_fnActivityView.center = _fnWebView.center;
			_fnActivityView.hidesWhenStopped = YES;
			[_fnActivityView startAnimating];
			_fnActivityView.tag = 100;

			[_fnWebView addSubview:_fnActivityView];
			[_fnWebView bringSubviewToFront:_fnActivityView];


			_fnWebView.backgroundColor = [UIColor whiteColor];
			UIViewController *vc = [[UIViewController alloc] init];
			vc.view = _fnWebView;
			vc.view.frame = CGRectMake(0, 0, 270.0f, 230.0f);
			[self presentPopUpViewController:vc];
		}];

		decisionHandler(WKNavigationActionPolicyCancel);
		return;
	}

	decisionHandler(WKNavigationActionPolicyAllow);


}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqualToString:@"estimatedProgress"]) {
		// estimatedProgressが変更されたら、プログレスバーを更新する

		// [self.navigationController setSGProgressPercentage:self.webView.estimatedProgress * 100.0f];
	} else if ([keyPath isEqualToString:@"title"]) {
		// titleが変更されたら、ナビゲーションバーのタイトルを設定する
		self.title = self.webView.title;
	} else if ([keyPath isEqualToString:@"loading"]) {
		// loadingが変更されたら、ステータスバーのインジケーターの表示・非表示を切り替える
		[UIApplication sharedApplication].networkActivityIndicatorVisible = _webView.loading;


	} else if ([keyPath isEqualToString:@"canGoBack"]) {
		// canGoBackが変更されたら、「＜」ボタンの有効・無効を切り替える
	} else if ([keyPath isEqualToString:@"canGoForward"]) {
		// canGoForwardが変更されたら、「＞」ボタンの有効・無効を切り替える
	}
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation
{
	if (webView == _fnWebView) return;
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

	self.isStar = NO;
	_starButton.image = [UIImage imageNamed:@"Star"];
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	if(webView == _fnWebView) {
		return;
	}
	if ([error code] != NSURLErrorCancelled)  // only goes in if it is not -999
	{
		UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"╮(╯_╰\")╭\n오류가 발생하였습니다."
																	   message:[error localizedDescription]
																preferredStyle:UIAlertControllerStyleAlert];
		UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"확인"
														 style:UIAlertActionStyleCancel
													   handler:^(UIAlertAction * action) {
														   [alert dismissViewControllerAnimated:YES completion:nil];
													   }];
		[alert addAction:cancel];
		[self presentViewController:alert animated:YES completion:nil];
	}
}

/*
 - (void)userContentController:(WKUserContentController *)userContentController
 didReceiveScriptMessage:(WKScriptMessage *)message {
 if ([message.name isEqualToString: @"searchInputClicked"]) {
 NSLog(@"search");
 [self performSegueWithIdentifier:@"showSearch" sender:nil];
 }
 }
 */

- (void)reloadWebView {
	[_webView reload];
	[_refreshControl endRefreshing];
}

#pragma mark - Functions
- (void)openURLonSafari:(NSURL *)url {
	NSString *urlString = [NSString stringWithFormat:@"%@", url];
	// v1.5.6 나무라이브일 경우 Safari에서 열도록 함
	if (NSClassFromString(@"SFSafariViewController") && ![urlString containsString:@"namu.live"]) {
		SFSafariViewController *safariViewController = [[SFSafariViewController alloc] initWithURL:url];
		[self presentViewController:safariViewController animated:YES completion:nil];
		safariViewController.delegate = self;
	} else {
		int length = (int)urlString.length;
		// NSLog(@"%d",length);
		if(length > 50) urlString = [NSString stringWithFormat:@"%@...",[urlString substringToIndex:47]];

		UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Safari에서 열겠습니까?"
																	   message:[NSString stringWithFormat:@"%@\n\n이 링크는 외부 링크입니다.\n이 링크를 Safari에서 열겠습니까?", urlString]
																preferredStyle:UIAlertControllerStyleAlert];

		UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"취소"
														 style:UIAlertActionStyleCancel
													   handler:^(UIAlertAction * action) {
														   [alert dismissViewControllerAnimated:YES completion:nil];
													   }];
		[alert addAction:cancel];
		UIAlertAction *open = [UIAlertAction actionWithTitle:@"열기"
													   style:UIAlertActionStyleDefault
													 handler:^(UIAlertAction * action) {
														 [[UIApplication sharedApplication] openURL:url];
													 }];
		[alert addAction:open];

		[self presentViewController:alert animated:YES completion:nil];
	}
}


- (void)saveBookmarks {
	NSString *filePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	NSString *fileName =  @"bookmarksFile";
	NSString *fileAtPath = [filePath stringByAppendingPathComponent:fileName];
	if(![[NSFileManager defaultManager] fileExistsAtPath:fileAtPath])
	[[NSFileManager defaultManager] createFileAtPath:fileAtPath contents:nil attributes:nil];

	[_bookmarksMutableArray writeToFile:fileAtPath atomically:NO];
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"use_icloud"] == YES) {
		[[NSUbiquitousKeyValueStore defaultStore] setArray:[_bookmarksMutableArray copy] forKey:@"bookmarksFile"];
	}
}

- (void)searchTableViewControllerDismissed:(NSString *)urlString
{
	if(urlString) {
		NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
		[_webView loadRequest:request];
	}
}

- (void)bookmarkTableViewControllerDismissed:(NSString *)urlString {
	if(urlString) {
		NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
		[_webView loadRequest:request];
	}

	NSString *filePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	_bookmarksMutableArray = [[NSMutableArray alloc] initWithContentsOfFile:[filePath stringByAppendingPathComponent:@"bookmarksFile"]];
}

- (void)tocTableViewControllerDismissed:(NSString *)no
{
	if(no) {

		[_webView evaluateJavaScript:[NSString stringWithFormat:@"window.location.hash='#s-%@'", no] completionHandler:nil];
		/* NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@#s-%@", _webView.URL.absoluteString, no]]];
		 [_webView loadRequest:request]; */
	}
}

#pragma mark - Navigations
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

	if ([[segue identifier] isEqualToString:@"showSearch"]) {
		/*
		 [_webView stopLoading];
		 [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
		 [self.navigationController cancelProgress];
		 */
		SearchTableViewController *vc = (SearchTableViewController *)[[segue destinationViewController] topViewController];
		// SearchTableViewController *vc = [segue destinationViewController];
		// SearchTableViewController *vc = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"SearchTableViewController"];

		vc.preferredContentSize = CGSizeMake(375, 600);

		vc.delegate = self;
		/* UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:vc];
		 navigationController.modalPresentationStyle = UIModalPresentationFormSheet; */
		// [self presentViewController:vc animated:YES completion:nil];

	}
	else if ([[segue identifier] isEqualToString:@"showBookmarks"]) {
		// SearchTableViewController *vc = (SearchTableViewController *)[[segue destinationViewController] topViewController];
		BookmarkTableViewController *vc = (BookmarkTableViewController *)[[segue destinationViewController] topViewController];
		vc.preferredContentSize = CGSizeMake(375, 600);
		vc.delegate = self;
	} else if ([[segue identifier] isEqualToString:@"showMore"]) {
		[segue destinationViewController].preferredContentSize = CGSizeMake(375, 600);

	} else if ([[segue identifier] isEqualToString:@"showToc"]) {
		TocViewController *vc = (TocViewController *)[[segue destinationViewController] topViewController];
		vc.preferredContentSize = CGSizeMake(375, 600);
		vc.title = self.navigationItem.title;

		vc.delegate = self;
		__block NSString *html = nil;
		// 목차: jQuery('.wiki-article .wiki-macro-toc').html()
		[_webView evaluateJavaScript:@"document.getElementById('toc').innerHTML" completionHandler:^(id result, NSError *error) {
			if (error == nil) {
				if (result != nil) {
					html = [result description];

				}
			} else {
				NSLog(@"evaluateJavaScript error : %@", error.localizedDescription);
			}
		}];
		while (html == nil)
		{
			[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
		}
		if (!html || [html isEqualToString:@""]) vc.html = @"<meta name='viewport' content='user-scalable=no, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, width=device-width'>목차가 존재하지 않습니다.";
		else vc.html = [NSString stringWithFormat:@"<meta name='viewport' content='user-scalable=no, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, width=device-width'>%@<style>.toc-item{display:block}.toc-indent .toc-indent{padding-left: 20px}a{text-decoration:none}</style>", html];
	}
}

- (void)openURLNotification:(NSNotification *) notification {
	if ([[notification name] isEqualToString:@"openURL"]) {
		[self openURL:[[NSUserDefaults standardUserDefaults] stringForKey:@"openURLOnLoad"]];

		[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"openURLOnLoad"];
		[[NSUserDefaults standardUserDefaults] synchronize];

	}


}

- (void)openURL:(NSString *)urlString {
	//NSLog(@"url : %@", urlString);
	NSURL *url = [NSURL URLWithString:urlString];
	if (url == nil) return;
	if (!([[urlString lowercaseString] hasPrefix:@"http://namu.wiki"] || [[urlString lowercaseString] hasPrefix:@"https://namu.wiki"])) {
		CWStatusBarNotification *notification = [CWStatusBarNotification new];
		notification.notificationLabelBackgroundColor = [UIColor colorWithRed:1 green:0.58 blue:0 alpha:1];
		[notification displayNotificationWithMessage:@"위키 사이트 URL이 아닙니다." forDuration:5.0f];
	}
	if(urlString) {
		NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
		[_webView loadRequest:request];
	} else {
		CWStatusBarNotification *notification = [CWStatusBarNotification new];
		notification.notificationLabelBackgroundColor = [UIColor colorWithRed:1 green:0.58 blue:0 alpha:1];
		[notification displayNotificationWithMessage:@"URL이 올바르지 않거나 존재하지 않습니다." forDuration:5.0f];
	}
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

#pragma mark - Buttons action
- (IBAction)goBack:(id)sender {
	if (_webView.canGoBack) [_webView goBack];
}

- (IBAction)goForward:(id)sender {
	if (_webView.canGoForward) [_webView goForward];
}

- (IBAction)touchActionButton:(id)sender {
	NSString *urlString = _webView.URL.absoluteString;

	ARSafariActivity *safariActivity = [[ARSafariActivity alloc] init];

	UIActivityViewController *activities = [[UIActivityViewController alloc] initWithActivityItems:@[[NSURL URLWithString:urlString]] applicationActivities:@[safariActivity]];

	activities.popoverPresentationController.barButtonItem = _actionButton;

	[self presentViewController:activities animated:YES completion:nil];
}


- (IBAction)touchStarButton:(id)sender {
	[_webView evaluateJavaScript:@"document.querySelectorAll('div.r + h1>a[href]')[0].innerText.trim()" completionHandler:^(id message, NSError *error) {
		NSString *wikiTitle = [message description];
		if(!wikiTitle) {
			wikiTitle = _webView.title;
			wikiTitle = [wikiTitle stringByReplacingOccurrencesOfString:@" - 나무위키" withString:@""];
		}
		if(!wikiTitle || [wikiTitle isEqual:@""]) {
			CWStatusBarNotification *notification = [CWStatusBarNotification new];
			notification.notificationLabelBackgroundColor = [UIColor colorWithRed:1 green:0.58 blue:0 alpha:1];
			notification.notificationStyle = CWNotificationAnimationStyleTop;
			[notification displayNotificationWithMessage:@"아직 즐겨찾기에 추가할 수 없습니다." forDuration:1.0f];
			return;
		}
		if(self.isStar) {
			_starButton.image = [UIImage imageNamed:@"Star"];
			CWStatusBarNotification *notification = [CWStatusBarNotification new];
			notification.notificationLabelBackgroundColor = [UIColor colorWithRed:1 green:0.23 blue:0.19 alpha:1];
			notification.notificationStyle = CWNotificationAnimationStyleTop;
			[notification displayNotificationWithMessage:@"즐겨찾기에 제거되었습니다." forDuration:1.0f];
			[_bookmarksMutableArray removeObject:wikiTitle];
		} else {
			_starButton.image = [UIImage imageNamed:@"Star Highlight"];
			CWStatusBarNotification *notification = [CWStatusBarNotification new];
			notification.notificationLabelBackgroundColor = [UIColor colorWithRed:0.00 green:0.51 blue:0.46 alpha:1.00];
			// [UIColor colorWithRed:0.00 green:0.51 blue:0.46 alpha:1.00];
			notification.notificationStyle = CWNotificationAnimationStyleTop;
			[notification displayNotificationWithMessage:@"즐겨찾기에 추가되었습니다." forDuration:1.0f];

			[self getbookmarkHistories];

			if(!_bookmarksMutableArray) _bookmarksMutableArray = [NSMutableArray new];
			[_bookmarksMutableArray addObject:wikiTitle];
		}
		[self saveBookmarks];
		self.isStar = [_bookmarksMutableArray containsObject:wikiTitle];
		if(self.isStar) _starButton.image = [UIImage imageNamed:@"Star Highlight"];
		else _starButton.image = [UIImage imageNamed:@"Star"];

	}];
}

- (IBAction)touchMoreButton:(id)sender {
	NSString *theme = [[NSUserDefaults standardUserDefaults] stringForKey:@"theme"];

	UIColor *tintColor = [UIColor colorWithRed:0.00 green:0.51 blue:0.46 alpha:1.00];
	if([theme isEqualToString:@"blackorange"]) {
		tintColor = [UIColor colorWithRed:0.79 green:0.53 blue:0.09 alpha:1.00];
	}

	UIAlertController *actionSheet = [UIAlertController	alertControllerWithTitle:NULL message:NULL preferredStyle:UIAlertControllerStyleActionSheet];

	UIAlertAction* cancel = [UIAlertAction
							 actionWithTitle: @"취소"
							 style:UIAlertActionStyleCancel
							 handler:^(UIAlertAction * action)
							 {
								 [actionSheet dismissViewControllerAnimated:YES completion:nil];
							 }];
	if(![theme isEqualToString:@"ios"]) [cancel setValue:tintColor forKey:@"titleTextColor"];

	UIAlertAction *random = [UIAlertAction actionWithTitle:@"랜덤 페이지" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
		NSURL *url = [NSURL URLWithString:@"https://namu.wiki/random"];
		[_webView loadRequest:[NSURLRequest requestWithURL:url]];
	}];
	[random setValue:[UIImage imageNamed:@"Dice"] forKey:@"image"];
	if(![theme isEqualToString:@"ios"]) [random setValue:tintColor forKey:@"titleTextColor"];

	UIAlertAction *setStrike = [UIAlertAction actionWithTitle:@"취소선 설정" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
		[self setStrike:nil];
	}];
	[setStrike setValue:[UIImage imageNamed:@"Strike"] forKey:@"image"];
	if(![theme isEqualToString:@"ios"]) [setStrike setValue:tintColor forKey:@"titleTextColor"];

	/*
	 임시 삭제
	UIAlertAction *darkModeButton = [UIAlertAction actionWithTitle:@"다크 모드" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
		[self setDarkMode:nil];
	}];
	[darkModeButton setValue:[UIImage imageNamed:@"DarkMode"] forKey:@"image"];
	if(![theme isEqualToString:@"ios"]) [darkModeButton setValue:tintColor forKey:@"titleTextColor"];

	UIAlertAction *hideSidebarButton = [UIAlertAction actionWithTitle:@"사이드바 감추기" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
		[self hideSidebar:nil];
	}];
	[hideSidebarButton setValue:[UIImage imageNamed:@"HideSidebar"] forKey:@"image"];
	if(![theme isEqualToString:@"ios"]) [hideSidebarButton setValue:tintColor forKey:@"titleTextColor"];
*/
	if(_webView.URL != NULL) {
		UIAlertAction *safariButton = [UIAlertAction actionWithTitle:@"Safari에서 열기" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
			// 2019.03.03 (v1.5.2) Safari에서 열기 수정
			[self openURLonSafari:_webView.URL];
			// [[UIApplication sharedApplication] openURL:_webView.URL];
		}];
		if(![theme isEqualToString:@"ios"]) [safariButton setValue:tintColor forKey:@"titleTextColor"];
		[safariButton setValue:[UIImage imageNamed:@"Safari"] forKey:@"image"];
		[actionSheet addAction:safariButton];
	}

	// 페이지 내 검색 v1.5
	UIAlertAction *findInPageButton = [UIAlertAction actionWithTitle:@"페이지에서 찾기" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
		UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"페이지에서 찾기" message:@"" preferredStyle:UIAlertControllerStyleAlert];
		[alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
		}];
		UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"검색" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
			NSString *js = [NSString stringWithFormat:@"_namuviewer_find_in_page(\"%@\");", [[alertController textFields][0] text]];
			[_webView evaluateJavaScript:js completionHandler:nil];
		}];
		[alertController addAction:confirmAction];
		UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"취소" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
		}];
		[alertController addAction:cancelAction];
		[self presentViewController:alertController animated:YES completion:nil];

	}];
	[findInPageButton setValue:[UIImage imageNamed:@"Search"] forKey:@"image"];
	if(![theme isEqualToString:@"ios"]) [findInPageButton setValue:tintColor forKey:@"titleTextColor"];

	UIAlertAction *settingsButton = [UIAlertAction actionWithTitle:@"설정" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
		UINavigationController *nc = [self.storyboard instantiateViewControllerWithIdentifier:@"InfoNavigationController"];

		nc.modalPresentationStyle = UIModalPresentationFormSheet;
		nc.preferredContentSize = CGSizeMake(375, 600);
		[self presentViewController:nc animated:YES completion:nil];
	}];
	[settingsButton setValue:[UIImage imageNamed:@"Settings"] forKey:@"image"];
	if(![theme isEqualToString:@"ios"]) [settingsButton setValue:tintColor forKey:@"titleTextColor"];

	[actionSheet addAction:random];
//	[actionSheet addAction:setStrike];
//	[actionSheet addAction:darkModeButton];
//	if ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)) [actionSheet addAction:hideSidebarButton];
	[actionSheet addAction:findInPageButton]; // v1.5
	[actionSheet addAction:settingsButton];
	[actionSheet addAction:cancel];
	actionSheet.popoverPresentationController.barButtonItem = self.moreButton;
	actionSheet.popoverPresentationController.sourceView = self.view;
	[self presentViewController:actionSheet animated:YES completion:nil];
}

- (void)goRandomPage:(id)sender {
	NSURL *url = [NSURL URLWithString:@"https://namu.wiki/random"];
	[_webView loadRequest:[NSURLRequest requestWithURL:url]];
}

- (void)goActionEdit:(id)sender {
	[self goAction:@"edit"];
}

- (void)goActionDiscuss:(id)sender {
	[self goAction:@"discuss"];
}

- (void)goActionHistory:(id)sender {
	[self goAction:@"history"];
}

- (void)goActionBacklinks:(id)sender {
	[self goAction:@"xref"];
}

- (void)goAction:(NSString *)actionName{
	NSString *urlString = _webView.URL.absoluteString;
	urlString = [urlString stringByReplacingOccurrencesOfString:@"://namu.wiki/edit/" withString:[NSString stringWithFormat:@"://namu.wiki/w/"]];
	urlString = [urlString stringByReplacingOccurrencesOfString:@"://namu.wiki/discuss/" withString:[NSString stringWithFormat:@"://namu.wiki/w/"]];
	urlString = [urlString stringByReplacingOccurrencesOfString:@"://namu.wiki/xref/" withString:[NSString stringWithFormat:@"://namu.wiki/w/"]];
	urlString = [urlString stringByReplacingOccurrencesOfString:@"://namu.wiki/history/" withString:[NSString stringWithFormat:@"://namu.wiki/w/"]];

	urlString = [urlString stringByReplacingOccurrencesOfString:@"://namu.wiki/w/" withString:[NSString stringWithFormat:@"://namu.wiki/%@/", actionName]];
	NSURL *url = [NSURL URLWithString:urlString];
	NSURLRequest *request = [NSURLRequest requestWithURL:url];
	[_webView loadRequest:request];
}

- (void)setDarkMode:(id)sender {
	/* NSString *js = [NSString stringWithFormat:@"jQuery('#darkToggleLink').click();"]; */
	// 나무위키 사이트 변경 (2019-10-06)
	NSString *js = [NSString stringWithFormat:@"jQuery('input#wiki.dark_mode').attr('checked', true);"];

	[_webView evaluateJavaScript:js completionHandler:nil];
}


- (void)setStrike:(id)sender {
	UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:@"취소선 설정"
																		 message:@"취소선 제거 속성은 취소선을 제거하여 일반 글처럼 보이며, 숨기기 속성은 취소선을 보이지 않게 합니다."
																  preferredStyle:UIAlertControllerStyleActionSheet];

	UIAlertAction *show = [UIAlertAction actionWithTitle:@"그대로 보이기"
												   style:UIAlertActionStyleDefault
												 handler:^(UIAlertAction * action) {
													 [[NSUserDefaults standardUserDefaults] setValue:@"show" forKey:@"namu_strike"];

													 NSString *js = [NSString stringWithFormat:@"namu.userSettings['strike'] = 'show'; if(typeof applyUserCustom === \"function\"){applyUserCustom()};namu.saveUserSettings();window.location.reload();"];
													 [_webView evaluateJavaScript:js completionHandler:nil];
													 [actionSheet dismissViewControllerAnimated:YES completion:nil];

													 /* CWStatusBarNotification *notification = [CWStatusBarNotification new];
													  notification.notificationLabelBackgroundColor = [UIColor colorWithRed:0.00 green:0.51 blue:0.46 alpha:1.00];
													  notification.notificationStyle = CWNotificationAnimationStyleTop;
													  [notification displayNotificationWithMessage:@"새로고침 후 적용됩니다." forDuration:3.0f]; */
												 }];
	[show setValue:[[UIImage imageNamed:@"Strike"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forKey:@"image"];
	[actionSheet addAction:show];


	UIAlertAction *remove = [UIAlertAction actionWithTitle:@"취소선만 제거"
													 style:UIAlertActionStyleDefault
												   handler:^(UIAlertAction * action) {
													   [[NSUserDefaults standardUserDefaults] setValue:@"remove" forKey:@"namu_strike"];
													   NSString *js = [NSString stringWithFormat:@"namu.userSettings['strike'] = 'remove'; if(typeof applyUserCustom === \"function\"){applyUserCustom()}namu.saveUserSettings();window.location.reload();"];
													   [_webView evaluateJavaScript:js completionHandler:nil];
													   [actionSheet dismissViewControllerAnimated:YES completion:nil];
												   }];
	[remove setValue:[[UIImage imageNamed:@"Strike Remove"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forKey:@"image"];
	[actionSheet addAction:remove];
	UIAlertAction *hide = [UIAlertAction actionWithTitle:@"숨기기"
												   style:UIAlertActionStyleDefault
												 handler:^(UIAlertAction * action) {
													 [[NSUserDefaults standardUserDefaults] setValue:@"hide" forKey:@"namu_strike"];
													 NSString *js = [NSString stringWithFormat:@"namu.userSettings['strike'] = 'hide'; if(typeof applyUserCustom === \"function\"){applyUserCustom()}namu.saveUserSettings();window.location.reload();"];
													 [_webView evaluateJavaScript:js completionHandler:nil];
													 [actionSheet dismissViewControllerAnimated:YES completion:nil];
												 }];
	[hide setValue:[[UIImage imageNamed:@"Close"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forKey:@"image"];
	[actionSheet addAction:hide];
	UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"취소"
													 style:UIAlertActionStyleCancel
												   handler:^(UIAlertAction * action) {
													   [actionSheet dismissViewControllerAnimated:YES completion:nil];
												   }];
	[actionSheet addAction:cancel];

	// actionSheet.view.tintColor = [UIColor colorWithRed:0.00 green:0.51 blue:0.46 alpha:1.00];
	actionSheet.popoverPresentationController.sourceView = self.view;
	actionSheet.popoverPresentationController.sourceRect = self.view.bounds;
	//    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) actionSheet.popoverPresentationController.barButtonItem = _drawer.items[17];

	[self presentViewController:actionSheet animated:YES completion:nil];
}

- (void)hideSidebar:(id)sender {
	// v1.5.2
	NSString *js = [NSString stringWithFormat:@"namu.userSettings['hide_sidebar'] = !namu.userSettings['hide_sidebar'];if(typeof applyUserCustom === \"function\"){applyUserCustom()};namu.saveUserSettings();window.location.reload();"];

	[_webView evaluateJavaScript:js completionHandler:nil];

	if ([[UIDevice currentDevice] orientation] == UIInterfaceOrientationPortrait || [[UIDevice currentDevice] orientation] == UIInterfaceOrientationPortraitUpsideDown) {
		CWStatusBarNotification *notification = [CWStatusBarNotification new];
		notification.notificationLabelBackgroundColor = [UIColor colorWithRed:0.00 green:0.51 blue:0.46 alpha:1.00];
		notification.notificationStyle = CWNotificationAnimationStyleTop;
		[notification displayNotificationWithMessage:@"가로 화면에서 확인할 수 있습니다." forDuration:3.0f];

	}
}


- (void)showSettings:(id)sender {
	UINavigationController *nc = [self.storyboard instantiateViewControllerWithIdentifier:@"InfoNavigationController"];

	nc.modalPresentationStyle = UIModalPresentationFormSheet;
	nc.preferredContentSize = CGSizeMake(375, 600);
	[self presentViewController:nc animated:YES completion:nil];
}


/* - (UIViewController *)webView:(WKWebView *)webView previewingViewControllerForElement:(WKPreviewElementInfo *)elementInfo defaultActions:(NSArray<id<WKPreviewActionItem>> *)previewActions {


 UIViewController *vc = [[UIViewController alloc] init];
 vc.view = _webView;

 return vc;
 } */

- (NSArray *)keyCommands {
	if ([[[UIDevice currentDevice] systemVersion] compare:@"9.0" options:NSNumericSearch] != NSOrderedAscending) {
		if (!_commands) {
			UIKeyCommand *commandR = [UIKeyCommand keyCommandWithInput:@"r"
														 modifierFlags:UIKeyModifierCommand
																action:@selector(handleShortcut:)
												  discoverabilityTitle:@"새로고침"];
			UIKeyCommand *controlR = [UIKeyCommand keyCommandWithInput:@"r"
														 modifierFlags:UIKeyModifierControl
																action:@selector(handleShortcut:)
												  discoverabilityTitle:@"랜덤 이동"];
//			UIKeyCommand *controlD = [UIKeyCommand keyCommandWithInput:@"d"
//														 modifierFlags:UIKeyModifierControl
//																action:@selector(handleShortcut:)
//												  discoverabilityTitle:@"다크모드"];
			/* UIKeyCommand *controlT = [UIKeyCommand keyCommandWithInput:@"t"
			 modifierFlags:UIKeyModifierControl
			 action:@selector(handleShortcut:)
			 discoverabilityTitle:@"목차 보기"]; */

			UIKeyCommand *commandL = [UIKeyCommand keyCommandWithInput:@"l"
														 modifierFlags:UIKeyModifierCommand
																action:@selector(handleShortcut:)
												  discoverabilityTitle:@"검색"];
			UIKeyCommand *commandF = [UIKeyCommand keyCommandWithInput:@"f"
														 modifierFlags:UIKeyModifierCommand
																action:@selector(handleShortcut:)
												  discoverabilityTitle:@"검색"];
			UIKeyCommand *commandD = [UIKeyCommand keyCommandWithInput:@"d"
														 modifierFlags:UIKeyModifierCommand
																action:@selector(handleShortcut:)
												  discoverabilityTitle:@"즐겨찾기 추가"];
			UIKeyCommand *commandY = [UIKeyCommand keyCommandWithInput:@"y"
														 modifierFlags:UIKeyModifierCommand
																action:@selector(handleShortcut:)
												  discoverabilityTitle:@"즐겨찾기 보기"];
			UIKeyCommand *commandBack = [UIKeyCommand keyCommandWithInput:@"["
															modifierFlags:UIKeyModifierCommand
																   action:@selector(handleShortcut:)
													 discoverabilityTitle:@"뒤로"];
			UIKeyCommand *commandForward = [UIKeyCommand keyCommandWithInput:@"]"
															   modifierFlags:UIKeyModifierCommand
																	  action:@selector(handleShortcut:)
														discoverabilityTitle:@"앞으로"];
			UIKeyCommand *commandComma = [UIKeyCommand keyCommandWithInput:@","
															 modifierFlags:UIKeyModifierCommand
																	action:@selector(handleShortcut:)
													  discoverabilityTitle:@"설정"];
			_commands = [[NSMutableArray alloc] initWithArray:@[commandR, controlR, commandL, commandF, commandD, commandY, commandBack, commandForward, commandComma]];
		}
	} else {
		if (!_commands) {
			UIKeyCommand *commandR = [UIKeyCommand keyCommandWithInput:@"r"
														 modifierFlags:UIKeyModifierCommand
																action:@selector(handleShortcut:)];
			UIKeyCommand *controlR = [UIKeyCommand keyCommandWithInput:@"r"
														 modifierFlags:UIKeyModifierControl
																action:@selector(handleShortcut:)];
			UIKeyCommand *controlD = [UIKeyCommand keyCommandWithInput:@"d"
														 modifierFlags:UIKeyModifierControl
																action:@selector(handleShortcut:)];
			/* UIKeyCommand *controlT = [UIKeyCommand keyCommandWithInput:@"t"
			 modifierFlags:UIKeyModifierControl
			 action:@selector(handleShortcut:)
			 discoverabilityTitle:@"목차 보기"]; */

			UIKeyCommand *commandL = [UIKeyCommand keyCommandWithInput:@"l"
														 modifierFlags:UIKeyModifierCommand
																action:@selector(handleShortcut:)];
			UIKeyCommand *commandF = [UIKeyCommand keyCommandWithInput:@"f"
														 modifierFlags:UIKeyModifierCommand
																action:@selector(handleShortcut:)];
			UIKeyCommand *commandD = [UIKeyCommand keyCommandWithInput:@"d"
														 modifierFlags:UIKeyModifierCommand
																action:@selector(handleShortcut:)];
			UIKeyCommand *commandY = [UIKeyCommand keyCommandWithInput:@"y"
														 modifierFlags:UIKeyModifierCommand
																action:@selector(handleShortcut:)];
			UIKeyCommand *commandBack = [UIKeyCommand keyCommandWithInput:@"["
															modifierFlags:UIKeyModifierCommand
																   action:@selector(handleShortcut:)];
			UIKeyCommand *commandForward = [UIKeyCommand keyCommandWithInput:@"]"
															   modifierFlags:UIKeyModifierCommand
																	  action:@selector(handleShortcut:)];
			UIKeyCommand *commandComma = [UIKeyCommand keyCommandWithInput:@","
															 modifierFlags:UIKeyModifierCommand
																	action:@selector(handleShortcut:)];
			_commands = [[NSMutableArray alloc] initWithArray:@[commandR, controlR, controlD, commandL, commandF, commandD, commandY, commandBack, commandForward, commandComma]];
		}
	}
	return _commands;
}

- (void)handleShortcut:(UIKeyCommand *)keyCommand {
	if ([keyCommand.input isEqualToString:@"r"] && keyCommand.modifierFlags == UIKeyModifierControl) {
		[self goRandomPage:nil];
		return;
	}
	if ([keyCommand.input isEqualToString:@"d"] && keyCommand.modifierFlags == UIKeyModifierControl) {
		[self setDarkMode:nil];
		return;
	}
	if ([keyCommand.input isEqualToString:@"r"]) {
		[_webView reload];
	} else if ([keyCommand.input isEqualToString:@"l"] || [keyCommand.input isEqualToString:@"f"]) {
		[self performSegueWithIdentifier:@"showSearch" sender:nil];
	} else if ([keyCommand.input isEqualToString:@"d"]) {
		[self touchStarButton:nil];
	} else if ([keyCommand.input isEqualToString:@"y"]) {
		[self performSegueWithIdentifier:@"showBookmarks" sender:nil];
	} else if ([keyCommand.input isEqualToString:@"["]) {
		[self goBack:nil];
	} else if ([keyCommand.input isEqualToString:@"]"]) {
		[self goForward:nil];
	} else if ([keyCommand.input isEqualToString:@","]) {
		[self showSettings:nil];
	}

}

#pragma mark - Observer

- (void)storeDidChange:(NSNotification *)notification
{
	// Retrieve the changes from iCloud
	_bookmarksMutableArray = [[[NSUbiquitousKeyValueStore defaultStore] arrayForKey:@"bookmarksFile"] mutableCopy];

}


@end

