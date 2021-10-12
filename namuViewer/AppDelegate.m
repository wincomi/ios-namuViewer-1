//
//  AppDelegate.m
//  namuViewer
//

#import "AppDelegate.h"
#import "SearchTableViewController.h"
#import "ViewController.h"

@interface AppDelegate ()
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	NSString *settingsBundle = [[NSBundle mainBundle] pathForResource:@"Settings" ofType:@"bundle"];
	if (!settingsBundle) {
		// NSLog(@"Could not find Settings.bundle");
	} else {
		NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:[settingsBundle stringByAppendingPathComponent:@"Root.plist"]];
		NSArray *preferences = [settings objectForKey:@"PreferenceSpecifiers"];

		NSMutableDictionary *defaultsToRegister = [[NSMutableDictionary alloc] initWithCapacity:[preferences count]];
		for(NSDictionary *prefSpecification in preferences) {
			NSString *key = [prefSpecification objectForKey:@"Key"];
			if(key) {
				[defaultsToRegister setObject:[prefSpecification objectForKey:@"DefaultValue"] forKey:key];
			}
		}

		[[NSUserDefaults standardUserDefaults] registerDefaults:defaultsToRegister];
	}

	if (@available(iOS 13.0, *)) {
		if ([[NSUserDefaults standardUserDefaults] boolForKey: @"ignoreDarkmode"] == YES) {
			[UIView appearance].overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
		}
	}

	return YES;
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
//	return YES;
//}
//
//- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
	if (!url) return NO;

	NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
	for (NSString *param in [url.query componentsSeparatedByString:@"&"]) {
		NSArray *elts = [param componentsSeparatedByString:@"="];
		if([elts count] < 2) continue;
		[params setObject:[elts objectAtIndex:1] forKey:[elts objectAtIndex:0]];
	}

	UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
	if ([@"namuviewer://search" isEqual:url.absoluteString]) {
		UINavigationController *nc = (UINavigationController *)self.window.rootViewController;
		[nc.topViewController performSegueWithIdentifier:@"showSearch" sender:nil];
		// [self.window.rootViewController presentViewController: [storyboard instantiateViewControllerWithIdentifier:@"SearchNavigationController"] animated:YES completion:nil];
	} else if ([@"namuviewer://bookmark" isEqual:url.absoluteString]) {
		UINavigationController *nc = [storyboard instantiateViewControllerWithIdentifier:@"BookmarkNavigationController"];
		// 홈 화면에서 나무위키 아이콘을 꾹 눌러서 즐겨찾기 항목으로 들어가 문서에 접속하면 그 문서로 가지 않고 나무위키 홈 화면으로 갑니다.
		BookmarkTableViewController *vc = (BookmarkTableViewController *)[nc topViewController];
		vc.delegate = (ViewController *)self.window.rootViewController;
		[self.window.rootViewController presentViewController: nc animated:YES completion:nil];
	}
	if([params valueForKey:@"url"]) {
		[[NSUserDefaults standardUserDefaults] setObject:[params valueForKey:@"url"] forKey:@"openURLOnLoad"];
		[[NSUserDefaults standardUserDefaults] synchronize];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"openURL" object:nil];
	} else if([params valueForKey:@"search"]) {
		NSString *urlString = [NSString stringWithFormat:@"https://namu.wiki/go/%@",[params valueForKey:@"search"]];
		NSURL *url = [NSURL URLWithString:urlString];
		urlString = [NSString stringWithFormat:@"%@",url];

		[[NSUserDefaults standardUserDefaults] setObject:urlString forKey:@"openURLOnLoad"];
		[[NSUserDefaults standardUserDefaults] synchronize];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"openURL" object:nil];
	}

	return YES;
}

- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))completionHandler {
	UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
	if ([shortcutItem.type isEqual:@"com.wincomi.ios.namuViewer.search"]) {
		UINavigationController *nc = (UINavigationController *)self.window.rootViewController;
		[nc.topViewController performSegueWithIdentifier:@"showSearch" sender:nil];
		/* UINavigationController *nc = [storyboard instantiateViewControllerWithIdentifier:@"SearchNavigationController"];
		 SearchTableViewController *vc = (SearchTableViewController *)[nc topViewController];
		 vc.delegate = self;
		 [self.window.rootViewController presentViewController:nc animated:YES completion:nil]; */
		completionHandler(true);
	} else if ([shortcutItem.type isEqual:@"com.wincomi.ios.namuViewer.bookmark"]) {
		[self.window.rootViewController presentViewController: [storyboard instantiateViewControllerWithIdentifier:@"BookmarkNavigationController"] animated:YES completion:nil];
		completionHandler(true);
	}
	completionHandler(false);
}

@end

