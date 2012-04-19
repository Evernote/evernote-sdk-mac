//
//  NoteViewController.h
//  client
//
//  Evernote API sample code is provided under the terms specified in the file LICENSE.txt which was included with this distribution.
//

#import <UIKit/UIKit.h>


@interface NoteViewController : UIViewController {

    UINavigationBar * noteNavigation;
    UITextView * noteContent;
    UIImageView * noteImage;
}

@property(nonatomic, assign) NSString * guid;
@property (nonatomic, retain) IBOutlet UIImageView * noteImage;
@property (nonatomic, retain) IBOutlet UINavigationBar * noteNavigation;
@property (nonatomic, retain) IBOutlet UITextView * noteContent;

-(void)goBack:(id)sender;

@end
