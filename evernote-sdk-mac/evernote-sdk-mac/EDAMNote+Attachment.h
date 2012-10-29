//
//  EDAMNote+Attachment.h
//  EverDesktop
//
//  Created by Atsushi Nagase on 10/29/12.
//  Copyright (c) 2012 LittleApps Inc. All rights reserved.
//

#import "EDAMTypes.h"

@interface EDAMNote (Attachment)

- (id)initWithAttachmentURL:(NSURL *)attachmentURL;
- (void)attachFileWithURL:(NSURL *)attachmentURL;
- (void)appendContent:(NSString *)content;
- (NSString *)mediaTagWithAppendingResourceFromURL:(NSURL *)attachmentURL;

@end
