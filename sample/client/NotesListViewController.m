//
//  SecondViewController.m
//  client
//
//  Evernote API sample code is provided under the terms specified in the file LICENSE.txt which was included with this distribution.
//

#import "NotesListViewController.h"
#import "NoteViewController.h"
#import "Evernote.h"


@implementation NotesListViewController

 

//viewDidLoad method declared in RootViewController.m
- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    //Initialize the arrays
    listOfItems = [[NSMutableArray alloc] init];
    indexArray = [[NSMutableArray alloc] init];

    
    // Loading all the notebooks linked to the account using the evernote API
    NSArray *noteBooks = (NSArray *)[[Evernote sharedInstance] listNotebooks];
    
    for (int i = 0; i < [noteBooks count]; i++) {
        
        // listing all the notes for every notebook
        
        // Accessing notebook
        EDAMNotebook* notebook = (EDAMNotebook*)[noteBooks objectAtIndex:i];
        
        // Creating & configuring filter to load specific notebook 
        EDAMNoteFilter * filter = [[EDAMNoteFilter alloc] init];
        [filter setNotebookGuid:[notebook guid]];
        
        // Searching on the Evernote API
        EDAMNoteList * notes = [[Evernote sharedInstance] findNotes:filter];
        
        for (int j = 0; j < [[notes notes] count]; j++) {
            // Populating the arrays
            EDAMNote* note = (EDAMNote*)[[notes notes] objectAtIndex:j];
            [listOfItems addObject:[note title]];
            [indexArray addObject:[note guid]];
        }
        
    }
    
    
    
}

/************************************************************
 *
 *  Function opening the next view
 *
 ************************************************************/

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    NSString * guid = (NSString *)[indexArray objectAtIndex:[indexPath row]]; 

    NoteViewController* noteViewController = [[[NoteViewController alloc] initWithNibName:@"NoteViewController" bundle:nil] autorelease];
    [noteViewController setGuid:guid];
    [self presentModalViewController:noteViewController animated:true];
}


/************************************************************
 *
 *  Function deleting a note
 *
 ************************************************************/

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString * guid = (NSString *)[indexArray objectAtIndex:[indexPath row]]; 
    
    // Sending the note to the trash
    [[Evernote sharedInstance] deleteNote:guid];
    
    // Removing the note from our cache
    [listOfItems removeObjectAtIndex:[indexPath row]];
    [[self tableView] reloadData];
    
}



/************************************************************
 *
 *  Functions configuring the listView
 *
 ************************************************************/

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [listOfItems count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
    }
    
    NSString *cellValue = [listOfItems objectAtIndex:indexPath.row];
    cell.textLabel.text = cellValue;
    
    return cell;
}


//dealloc method declared in RootViewController.m
- (void)dealloc {
    
    [listOfItems release];
    [indexArray release];
    [super dealloc];
}

@end
