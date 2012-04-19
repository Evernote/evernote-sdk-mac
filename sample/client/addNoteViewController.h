//
//  FirstViewController.h
//  client
//
//  Evernote API sample code is provided under the terms specified in the file LICENSE.txt which was included with this distribution.
//

#import <UIKit/UIKit.h>


@interface addNoteViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPickerViewDelegate> {
    UIPickerView * notebookPicker;
    NSMutableArray *listOfItems;
    NSMutableArray *indexArray;
    UIButton * doneButtonPicker;
    UITextField * titleNote;
    UIButton * sendNote;
    
    UIImageView * imageView;
}

@property (nonatomic, retain) IBOutlet UIPickerView * notebookPicker;
@property (nonatomic, retain) IBOutlet UITextField * titleNote;
@property (nonatomic, retain) IBOutlet UIButton * sendNote;


@property (nonatomic, retain) IBOutlet UIImageView * imageView;


- (IBAction) getPhoto:(id) sender;

@end
