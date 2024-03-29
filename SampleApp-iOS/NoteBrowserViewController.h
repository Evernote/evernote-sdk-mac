//
//  NoteBrowserViewController.h
//  evernote-sdk-ios
//
//  Created by Mustafa Furniturewala on 2/6/13.
//  Copyright (c) 2013 n/a. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

@interface NoteBrowserViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIBarButtonItem *btnPrev;

@property (weak, nonatomic) IBOutlet WKWebView *webView;
- (IBAction)nextNote:(id)sender;
- (IBAction)previousNote:(id)sender;

@end
