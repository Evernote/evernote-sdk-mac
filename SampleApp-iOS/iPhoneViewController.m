//
//  iPhoneViewController.m
//  OAuthTest
//
//  Created by Matthew McGlincy on 3/17/12.
//

#import "EvernoteSDK.h"
#import "iPhoneViewController.h"
#import "NSData+EvernoteSDK.h"
#import "ENMLUtility.h"


@implementation iPhoneViewController

@synthesize userLabel;
@synthesize listNotebooksButton;
@synthesize authenticateButton;
@synthesize logoutButton;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self updateButtonsForAuthentication];
}

- (void)didReceiveMemoryWarning
{
    [self setListNotebooksButton:nil];
    [self setUserLabel:nil];
    [self setAuthenticateButton:nil];
    [self setLogoutButton:nil];
    [self setListBusinessButton:nil];
    [self setBusinessLabel:nil];
    [self setSharedNotesButton:nil];
    [self setCreateBusinessNotebookButton:nil];
    [self setCreatePhotoButton:nil];
    [self setMoreButton:nil];
    [super didReceiveMemoryWarning];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotate:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (IBAction)authenticate:(id)sender 
{
    EvernoteSession *session = [EvernoteSession sharedSession];
    [session authenticateWithViewController:self completionHandler:^(NSError *error) {
        if (error || !session.isAuthenticated) {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Error" message:@"Could not authenticate" preferredStyle:(UIAlertControllerStyleAlert)];
            [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alertController animated:YES completion:nil];
        } else {
            NSLog(@"authenticated! noteStoreUrl:%@ webApiUrlPrefix:%@", session.noteStoreUrl, session.webApiUrlPrefix);
            [self updateButtonsForAuthentication];
        } 
    }];
}

- (void)showUserInfo
{
    EvernoteUserStore *userStore = [EvernoteUserStore userStore];
    [userStore getUserWithSuccess:^(EDAMUser *user) {
        self.userLabel.text = user.username;
        if(user.accounting.businessIdIsSet) {
            self.businessLabel.text = user.accounting.businessName;
        }
        else {
            self.businessLabel.text = @"Not a business user";
            self.listBusinessButton.enabled = NO;
            self.listBusinessButton.alpha = 0.5;
            self.createBusinessNotebookButton.enabled = NO;
            self.createBusinessNotebookButton.alpha = 0.5;

        }
    }
                          failure:^(NSError *error) {
                              NSLog(@"error %@", error);                                            
                          }];
}

- (IBAction)listNotes:(id)sender {
    EvernoteNoteStore *noteStore = [EvernoteNoteStore noteStore];
    [noteStore listNotebooksWithSuccess:^(NSArray *notebooks) {
        NSLog(@"notebooks: %@", notebooks);
    } failure:^(NSError *error) {
        NSLog(@"error %@", error);
    }];
}

- (IBAction)listBusinessNotebooks:(id)sender {
    EvernoteNoteStore *noteStore = [EvernoteNoteStore noteStore];
    [noteStore listBusinessNotebooksWithSuccess:^(NSArray *linkedNotebooks) {
        NSLog(@"Notebooks : %@",linkedNotebooks);
    } failure:^(NSError *error) {
        NSLog(@"Error : %@",error);
    }];
}

- (IBAction)createBusinessNotebook:(id)sender {
    EvernoteNoteStore *noteStore = [EvernoteNoteStore noteStore];
    EDAMNotebook* notebook = [[EDAMNotebook alloc] initWithGuid:nil name:@"test" updateSequenceNum:0 defaultNotebook:NO serviceCreated:0 serviceUpdated:0 publishing:nil published:NO stack:nil sharedNotebookIds:nil sharedNotebooks:nil businessNotebook:nil contact:nil restrictions:nil];
    [noteStore createBusinessNotebook:notebook success:^(EDAMLinkedNotebook *businessNotebook) {
        NSLog(@"Created a business notebook : %@",businessNotebook);
    } failure:^(NSError *error) {
        NSLog(@"Error : %@",error);
    }];
}

- (IBAction)listSharedNotes:(id)sender {
    // Get the users note store
    EvernoteNoteStore *defaultNoteStore = [EvernoteNoteStore noteStore];
    [defaultNoteStore listLinkedNotebooksWithSuccess:^(NSArray *linkedNotebooks) {
        if(linkedNotebooks.count >0) {
            EDAMNoteFilter* noteFilter = [[EDAMNoteFilter alloc] initWithOrder:0
                                                                     ascending:NO
                                                                         words:nil
                                                                  notebookGuid:nil
                                                                      tagGuids:nil
                                                                      timeZone:nil
                                                                      inactive:NO
                                                                    emphasized:nil];
            [defaultNoteStore listNotesForLinkedNotebook:linkedNotebooks[0]  withFilter:noteFilter success:^(EDAMNoteList *list) {
                NSLog(@"Shared notes : %@",list);
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Photo Note Created" message:list preferredStyle:(UIAlertControllerStyleAlert)];
                [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
                [self presentViewController:alertController animated:YES completion:nil];
            } failure:^(NSError *error) {
                NSLog(@"Error : %@",error);
            }];
        }
        else {
            NSLog(@"No linked notebooks.");
        }
        
    } failure:^(NSError *error) {
        NSLog(@"Error listing linked notes: %@",error);
    }];
}

- (IBAction)createPhotoNote:(id)sender {
    NSString* filePath = [[NSBundle mainBundle] pathForResource:@"evernote_logo_4c-sm" ofType:@"png"];
    NSData *myFileData = [NSData dataWithContentsOfFile:filePath];
    NSData *dataHash = [myFileData enmd5];
    EDAMData *edamData = [[EDAMData alloc] initWithBodyHash:dataHash size:myFileData.length body:myFileData];
    EDAMResource* resource = [[EDAMResource alloc] initWithGuid:nil noteGuid:nil data:edamData mime:@"image/png" width:0 height:0 duration:0 active:0 recognition:0 attributes:nil updateSequenceNum:0 alternateData:nil];
    NSString *noteContent = [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
                             "<!DOCTYPE en-note SYSTEM \"http://xml.evernote.com/pub/enml2.dtd\">"
                             "<en-note>"
                             "<span style=\"font-weight:bold;\">Hello photo note.</span>"
                             "<br />"
                             "<span>Evernote logo :</span>"
                             "<br />"
                             "%@"
                             "</en-note>",[ENMLUtility mediaTagWithDataHash:dataHash mime:@"image/png"]];
    NSMutableArray* resources = [NSMutableArray arrayWithArray:@[resource]];
    EDAMNote *newNote = [[EDAMNote alloc] initWithGuid:nil title:@"Test photo note" content:noteContent contentHash:nil contentLength:noteContent.length created:0 updated:0 deleted:0 active:YES updateSequenceNum:0 notebookGuid:nil tagGuids:nil resources:resources attributes:nil tagNames:nil];
    [[EvernoteNoteStore noteStore] setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        NSLog(@"Total bytes written : %lld , Total bytes expected to be written : %lld",totalBytesWritten,totalBytesExpectedToWrite);
    }];
    [[EvernoteNoteStore noteStore] createNote:newNote success:^(EDAMNote *note) {
        NSLog(@"Note created successfully.");
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Photo Note Created" message:nil preferredStyle:(UIAlertControllerStyleAlert)];
        [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alertController animated:YES completion:nil];
    } failure:^(NSError *error) {
        NSLog(@"Error creating note : %@",error);
    }];
}

- (void)updateButtonsForAuthentication 
{    
    EvernoteSession *session = [EvernoteSession sharedSession];

    if (session.isAuthenticated) {
        self.authenticateButton.enabled = NO;
        self.authenticateButton.alpha = 0.5;
        self.listNotebooksButton.enabled = YES;
        self.listNotebooksButton.alpha = 1.0;
        self.createPhotoButton.enabled = YES;
        self.createPhotoButton.alpha = 1.0;
        self.listBusinessButton.enabled = YES;
        self.listBusinessButton.alpha = 1.0;
        self.createBusinessNotebookButton.enabled = YES;
        self.createBusinessNotebookButton.alpha = 1.0;
        self.sharedNotesButton.enabled = YES;
        self.sharedNotesButton.alpha = 1.0;
        self.logoutButton.enabled = YES;
        self.logoutButton.alpha = 1.0;
        self.moreButton.enabled = YES;
        self.moreButton.alpha = 1.0;
        [self showUserInfo];
    } else {
        self.authenticateButton.enabled = YES;
        self.authenticateButton.alpha = 1.0;
        self.listNotebooksButton.enabled = NO;
        self.listNotebooksButton.alpha = 0.5;
        self.createPhotoButton.enabled = NO;
        self.createPhotoButton.alpha = 0.5;
        self.listBusinessButton.enabled = NO;
        self.listBusinessButton.alpha = 0.5;
        self.createBusinessNotebookButton.enabled = NO;
        self.createBusinessNotebookButton.alpha = 0.5;
        self.sharedNotesButton.enabled = NO;
        self.sharedNotesButton.alpha = 0.5;
        self.logoutButton.enabled = NO;
        self.logoutButton.alpha = 0.5;
        self.moreButton.enabled = NO;
        self.moreButton.alpha = 0.5;
        self.userLabel.text = @"(not authenticated)";
        self.businessLabel.text = @"(not authenticated)";
    }
}

- (IBAction)logout:(id)sender {
    [[EvernoteSession sharedSession] logout];
    [self updateButtonsForAuthentication];
}

@end
