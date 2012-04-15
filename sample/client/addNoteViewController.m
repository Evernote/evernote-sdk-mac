//
//  FirstViewController.m
//  client
//
//  Evernote API sample code is provided under the terms specified in the file LICENSE.txt which was included with this distribution.
//

#import <CommonCrypto/CommonDigest.h> 
#import "addNoteViewController.h"

#import "evernote.h"
#import "NSDataMD5Additions.h"

@implementation addNoteViewController


@synthesize notebookPicker,titleNote, sendNote, imageView;



// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    if ([consumerKey isEqualToString:@"XXXXXXXX" ]) {
        
        // Alerting the user that the note was created
        UIAlertView *alertDone = [[UIAlertView alloc] initWithTitle: @"Evernote" message: @"Please set your API key in Evernote.m" delegate: self cancelButtonTitle: @"Ok" otherButtonTitles: nil];
        
        [alertDone show];
        [alertDone release];
        
        return;
    }
    
    
    
    [sendNote addTarget:self action:@selector(sendNoteEvernote:)
         forControlEvents:UIControlEventTouchDown];
    
    
    // We are going to initialize the values in the picker
    //Initialize the array.
    listOfItems = [[NSMutableArray alloc] init];
    indexArray = [[NSMutableArray alloc] init];
    
    
    // Loading all the notebooks linked to the account
    NSArray *noteBooks = (NSArray *)[[Evernote sharedInstance] listNotebooks];
    
    // Populating the array
    for (int i = 0; i < [noteBooks count]; i++) {
        
        EDAMNotebook* notebook = (EDAMNotebook*)[noteBooks objectAtIndex:i];
        [listOfItems addObject:[notebook name]];
        [indexArray addObject:[notebook guid]];

    }

    // Initialize the picker
    notebookPicker= [[UIPickerView alloc] initWithFrame:CGRectMake(0, 200, 320, 200)];
    [notebookPicker selectRow:1 inComponent:0 animated:NO];
    
    [super viewDidLoad];
}




/************************************************************
 *
 *  Function that sends the note to Evernote
 *  Started by the submit button
 *
 ************************************************************/

-(IBAction)sendNoteEvernote:(id)sender{
    
    // Closing controls
    [titleNote resignFirstResponder];
    
    // Creating the Note Object
    EDAMNote * note = [[[EDAMNote alloc] init]autorelease];
    
    // Setting initial values sent by the user
    note.title = titleNote.text;
    note.notebookGuid = [indexArray objectAtIndex:[notebookPicker selectedRowInComponent:0]]; 
   
    // Simple example ENML we are going to use as content for our note
    NSString * ENML = [[[NSString alloc] initWithString: @"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE en-note SYSTEM \"http://xml.evernote.com/pub/enml2.dtd\">\n<en-note>Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."]autorelease];
    
    
    // Loading the data of the image
    NSData * imageNSData =   UIImagePNGRepresentation([imageView image]);
    NSUInteger * imageSize = (NSUInteger *)[imageNSData length];
    NSString * hash; 
    EDAMResource * imageResource = nil;
    
    
    if (imageSize > 0) {
        // The user has selected an image
        NSLog(@"We have an image");
        
        // Calculating the md5
        hash = [[[imageNSData md5] description] stringByReplacingOccurrencesOfString:@" " withString:@""];
        hash = [hash substringWithRange:NSMakeRange(1, [hash length] - 2)];

        // 1) create the data EDAMData using the hash, the size and the data of the image
        EDAMData * imageData = [[EDAMData alloc] initWithBodyHash:[hash dataUsingEncoding: NSASCIIStringEncoding] size:[imageNSData length] body:imageNSData];

        
        // 2) Create an EDAMResourceAttributes object with other important attributes of the file
        EDAMResourceAttributes * imageAttributes = [[[EDAMResourceAttributes alloc] init] autorelease];
        [imageAttributes setFileName:@"example.png"];
        
        // 3) create an EDAMResource the hold the mime, the data and the attributes
        imageResource  = [[[EDAMResource alloc]init]autorelease];
        [imageResource setMime:@"image/png"];
        [imageResource setData:imageData];
        [imageResource setAttributes:imageAttributes];
        
        // We are quickly the ENML code for the image to the content
        NSString * imageENML = [NSString stringWithFormat:@"<en-media type=\"image/png\" hash=\"%@\"/>", hash];
        ENML = [NSString stringWithFormat:@"%@%@", ENML, imageENML];

        
    }
    
    // We are transforming the resource into a array to attach it to the note
    NSArray * resources = [[NSArray alloc] initWithObjects:imageResource, nil];
    
    ENML = [NSString stringWithFormat:@"%@%@", ENML, @"</en-note>"];
    NSLog(@"%@", ENML);
    
    // Adding the content & resources to the note
    [note setContent:ENML];
    [note setResources:resources];

    // Saving the note on the Evernote servers
    // Simple error management
    @try {
        [[Evernote sharedInstance] createNote:note];
    }
    @catch (EDAMUserException * e) {
        NSString * errorMessage = [NSString stringWithFormat:@"Error saving note: error code %i", [e errorCode]];
        UIAlertView *alertDone = [[UIAlertView alloc] initWithTitle: @"Evernote" message: errorMessage delegate: self cancelButtonTitle: @"Ok" otherButtonTitles: nil];
        
        [alertDone show];
        [alertDone release];
        return;
    }
    
    // Alerting the user that the note was created
    UIAlertView *alertDone = [[UIAlertView alloc] initWithTitle: @"Evernote" message: @"Note was saved" delegate: self cancelButtonTitle: @"Ok" otherButtonTitles: nil];
    
    [alertDone show];
    [alertDone release];
}



/************************************************************
 *
 *  Functions used by the picker view
 *
 ************************************************************/

-(IBAction)buttonPressed:(id)sender{
    
    // User requested to see the picker
    [titleNote resignFirstResponder];
    [self.view addSubview:notebookPicker];
    notebookPicker.delegate = self;
    notebookPicker.showsSelectionIndicator = YES;
    
    doneButtonPicker = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    
    [doneButtonPicker setTitle:@"ok" forState:UIControlStateNormal];
    [doneButtonPicker addTarget:self action:@selector(doneWithpickerView:)
         forControlEvents:UIControlEventTouchDown];
    doneButtonPicker.frame = CGRectMake(265.0,202.0,  52.0, 30.0);
    
    
    [self.view addSubview:doneButtonPicker];
}

-(IBAction)doneWithpickerView:(id)sender{
    // When the user is done with the picker
    [notebookPicker removeFromSuperview]; 
    [doneButtonPicker removeFromSuperview];
    
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView;
{
    return 1;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{

}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component;
{
    return [listOfItems count];
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component;
{
    return [listOfItems objectAtIndex:row];
}




/************************************************************
 *
 *  Functions used by the image picker
 *
 ************************************************************/

// Open the image picker
-(IBAction)getPhoto:(id)sender{
    
    [titleNote resignFirstResponder];
    UIImagePickerController * picker = [[UIImagePickerController alloc] init];
	picker.delegate = self;
    picker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
	
    
	[self presentModalViewController:picker animated:YES];
    
}

// The user has selected the image
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
	[picker dismissModalViewControllerAnimated:YES];
	imageView.image = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
    
}


- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)release
{
    
}


- (void)dealloc
{
    [doneButtonPicker release];
    [titleNote release];
    [sendNote release];
    [imageView release];
    [notebookPicker release];
    [super dealloc];
}


@end
