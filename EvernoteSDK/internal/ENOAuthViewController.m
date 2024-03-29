//
//  ENOAuthViewController.m
//  evernote-sdk-ios
//
//  Created by Matthew McGlincy on 5/26/12.
//  Copyright (c) 2012 n/a. All rights reserved.
//

#import "ENOAuthViewController.h"
#import "ENConstants.h"

@interface ENOAuthViewController() <WKNavigationDelegate>

@property (nonatomic, strong) NSURL *authorizationURL;
@property (nonatomic, strong) NSString *oauthCallbackPrefix;
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, copy) NSString* currentProfileName;
@property (nonatomic, strong) UIActivityIndicatorView* activityIndicator;
@property (nonatomic, assign) BOOL isSwitchingAllowed;
@property (nonatomic, strong) NSDate* startDate;

@end

@implementation ENOAuthViewController

@synthesize delegate = _delegate;
@synthesize authorizationURL = _authorizationURL;
@synthesize oauthCallbackPrefix = _oauthCallbackPrefix;
@synthesize webView = _webView;

- (void)dealloc
{
    self.delegate = nil;
    self.webView.navigationDelegate = nil;
    [self.webView stopLoading];
}

- (id)initWithAuthorizationURL:(NSURL *)authorizationURL 
           oauthCallbackPrefix:(NSString *)oauthCallbackPrefix
                   profileName:(NSString *)currentProfileName
                allowSwitching:(BOOL)isSwitchingAllowed
                      delegate:(id<ENOAuthDelegate>)delegate
{
    self = [super init];
    if (self) {
        self.authorizationURL = authorizationURL;
        self.oauthCallbackPrefix = oauthCallbackPrefix;
        self.currentProfileName = currentProfileName;
        self.delegate = delegate;
        self.isSwitchingAllowed = isSwitchingAllowed;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringFromTable(@"Cancel", @"EvernoteSDK", nil) style:UIBarButtonItemStylePlain target:self action:@selector(cancel:)];
    
    self.navigationItem.rightBarButtonItem = cancelItem;
    
    // adding an activity indicator
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [self.activityIndicator setHidesWhenStopped:YES];
    self.webView = [[WKWebView alloc] initWithFrame:self.view.bounds];
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.webView.navigationDelegate = self;
    [self.view addSubview:self.webView];
    self.activityIndicator.frame = CGRectMake((self.navigationController.view.frame.size.width - (self.activityIndicator.frame.size.width/2))/2,
                                              (self.navigationController.view.frame.size.height - (self.activityIndicator.frame.size.height/2) - 44)/2,
                                              self.activityIndicator.frame.size.width,
                                              self.activityIndicator.frame.size.height);
    [self.webView addSubview:self.activityIndicator];
    [self updateUIForNewProfile:self.currentProfileName
           withAuthorizationURL:self.authorizationURL];
}

- (void)cancel:(id)sender
{
    [self.webView stopLoading];
    if (self.delegate) {
        [self.delegate oauthViewControllerDidCancel:self];
    }
    self.delegate = nil;
}

- (void)switchProfile:(id)sender
{
    [self.webView stopLoading];
    // start a page flip animation 
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
    [UIView setAnimationDuration:1.0];
    [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft
                           forView:[[self navigationController] view]
                             cache:YES];
    [self.webView setNavigationDelegate:nil];
    // Blank out the web view
    [self.webView evaluateJavaScript:@"document.open();document.close()" completionHandler:^(NSString *doc, NSError * _Nullable error) { }];
    self.navigationItem.leftBarButtonItem = nil;
    [UIView commitAnimations];
}

- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
    [self.activityIndicator startAnimating];
    [self.delegate oauthViewControllerDidSwitchProfile:self];
}

- (void)updateUIForNewProfile:(NSString*)newProfile withAuthorizationURL:(NSURL*)authURL{
    self.authorizationURL = authURL;
    self.currentProfileName = newProfile;
    if(self.isSwitchingAllowed) {
        NSString *leftButtonTitle = nil;
        if([self.currentProfileName isEqualToString:ENBootstrapProfileNameChina]) {
            leftButtonTitle = NSLocalizedStringFromTable(@"Evernote-International", @"EvernoteSDK", nil);
        }
        else {
            leftButtonTitle = NSLocalizedStringFromTable(@"Evernote-China", @"EvernoteSDK", nil);
        }
        UIBarButtonItem* switchProfileButton = [[UIBarButtonItem alloc] initWithTitle:leftButtonTitle style:UIBarButtonItemStylePlain target:self action:@selector(switchProfile:)];
        self.navigationItem.leftBarButtonItem = switchProfileButton;
    }
    [self loadWebView];
}

- (void)loadWebView {
    [self.activityIndicator startAnimating];
    [self.webView setNavigationDelegate:self];
    [self.webView loadRequest:[NSURLRequest requestWithURL:self.authorizationURL]];
    self.startDate = [NSDate date];
}

- (BOOL)shouldAutorotate:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

# pragma mark - UIWebViewDelegate

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    [self.activityIndicator stopAnimating];
    if ([error.domain isEqualToString:@"WebKitErrorDomain"] && error.code == 102) {
        // ignore "Frame load interrupted" errors, which we get as part of the final oauth callback :P
        return;
    }
    
    if (error.code == NSURLErrorCancelled) {
        // ignore rapid repeated clicking (error code -999)
        return;
    }
    
    [self.webView stopLoading];

    if (self.delegate) {
        [self.delegate oauthViewController:self didFailWithError:error];
    }
}
    
    - (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
     if ([[webView.URL absoluteString] hasPrefix:self.oauthCallbackPrefix]) {
      // this is our OAuth callback prefix, so let the delegate handle it
      if (self.delegate) {
       [self.delegate oauthViewController:self receivedOAuthCallbackURL:webView.URL];
      }
      decisionHandler(WKNavigationActionPolicyCancel);
     } else {
      decisionHandler(WKNavigationActionPolicyAllow);
     }
    }

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
        [self.activityIndicator stopAnimating];
        self.startDate = [NSDate date];
        NSLog(@"OAuth Step 2 - Time Running is: %f",[self.startDate timeIntervalSinceNow] * -1);
    }
    
@end
