//
//  NoteViewController.m
//  client
//
//  Evernote API sample code is provided under the terms specified in the file LICENSE.txt which was included with this distribution.
//

#import "NoteViewController.h"
#import "evernote.h"


@implementation NoteViewController {
}


@synthesize guid, noteImage, noteNavigation, noteContent;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}


/************************************************************
 *
 *  Function that loads all the information concerning 
 *  the note we are viewing
 *
 ************************************************************/

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Load the EDAMNote object that has guid we have stored in the object
    EDAMNote * note = [(Evernote *)[Evernote sharedInstance] getNote:guid];
    
    // As an example, we are going to show the first element if it is an image
    if ([note.resources count] >0) {
        EDAMResource * resource = [note.resources objectAtIndex:0];
        
        // If the first resource is an image/png, we are going to show it
        if ([resource.mime isEqualToString: @"image/png"]) {
            // Linking the data to the view
            UIImage * tmpImage = [[UIImage alloc] initWithData:resource.data.body];
            noteImage.image = tmpImage;
            
        }
    }
    // Changing the navigation title & the content block
    noteNavigation.topItem.title = [note title];
    noteContent.text = [note content];
    
    // Adding a back button to close the windows
    UIBarButtonItem* doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(goBack:)];
  
    UINavigationItem *item = [[[UINavigationItem alloc] init] autorelease];
    item.leftBarButtonItem = doneButton;
    item.hidesBackButton = YES;
    [noteNavigation pushNavigationItem:item animated:NO];
    noteNavigation.topItem.title = [note title];
    
    
}

/************************************************************
 *
 *  Function that closes the view
 *  On the back click
 *
 ************************************************************/

-(void)goBack:(id)sender
{
    [self.parentViewController dismissModalViewControllerAnimated:true];
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc
{
    [noteImage release];
    [noteNavigation release];
    [noteContent release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle



@end
