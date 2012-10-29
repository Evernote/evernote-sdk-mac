//
//  EDAMNote+Attachment.m
//  EverDesktop
//
//  Created by Atsushi Nagase on 10/29/12.
//  Copyright (c) 2012 LittleApps Inc. All rights reserved.
//

#import "EDAMNote+Attachment.h"
#import "NSData+md5.h"

#define kENMLPrefix @"<?xml version=\"1.0\" encoding=\"UTF-8\"?><!DOCTYPE en-note SYSTEM \"http://xml.evernote.com/pub/enml2.dtd\"><en-note style=\"word-wrap: break-word; -webkit-nbsp-mode: space; -webkit-line-break: after-white-space;\">"
#define kENMLSuffix @"</en-note>"

@implementation EDAMNote (Attachment)

- (id)initWithAttachmentURL:(NSURL *)attachmentURL {
  if(self = [super init]) {
    [self attachFileWithURL:attachmentURL];
    self.title = attachmentURL.lastPathComponent;
  }
  return self;
}

- (void)attachFileWithURL:(NSURL *)attachmentURL {
  [self appendContent:[self mediaTagWithAppendingResourceFromURL:attachmentURL]];
}

- (void)appendContent:(NSString *)content {
  NSString *newContent = self.content.copy;
  if(!(newContent&&newContent.length>0))
    newContent = kENMLPrefix;
  newContent = [newContent stringByReplacingOccurrencesOfString:kENMLSuffix withString:@""];
  newContent = [newContent stringByAppendingFormat:@"%@\n%@", content, kENMLSuffix];
  //
  NSError *error = nil;
  NSRegularExpression *re1 = [NSRegularExpression regularExpressionWithPattern:@"<img[^>]+>" options:NSRegularExpressionCaseInsensitive error:&error];
  if(error) [NSException raise:error.domain format:@"%@", error.localizedDescription];
  NSRegularExpression *re2 = [NSRegularExpression regularExpressionWithPattern:@"(src|alt|title)=\"([^\"]+)\"" options:NSRegularExpressionCaseInsensitive error:&error];
  if(error) [NSException raise:error.domain format:@"%@", error.localizedDescription];
  NSTextCheckingResult *match1 = nil;
  do {
    match1 = [re1 firstMatchInString:newContent options:0 range:NSMakeRange(0, newContent.length)];
    if(!match1||match1.range.location==NSNotFound) break;
    NSString *img = [newContent substringWithRange:match1.range];
    NSArray *matches2 = [re2 matchesInString:img options:0 range:NSMakeRange(0, img.length)];
    NSURL *imageURL = nil;
    for (NSTextCheckingResult *match2 in matches2) {
      if(match2.numberOfRanges == 3) {
        NSString *k = [img substringWithRange:[match2 rangeAtIndex:1]];
        NSString *v = [img substringWithRange:[match2 rangeAtIndex:2]];
        if([k isEqualToString:@"src"]) {
          imageURL = [NSURL URLWithString:v];
          break;
        }
      }
    }
    NSString *mediaTag = [self mediaTagWithAppendingResourceFromURL:imageURL];
    newContent = [newContent stringByReplacingCharactersInRange:match1.range withString:mediaTag?mediaTag:@""];
  } while(YES);
  self.content = newContent;
}

- (NSString *)mediaTagWithAppendingResourceFromURL:(NSURL *)attachmentURL {
  NSString *ext = attachmentURL.pathExtension;
  NSString *mimeType = [self mimeTypeForExtention:ext];
  EDAMResource *res = [[EDAMResource alloc] init];
  res.attributes = [[EDAMResourceAttributes alloc] init];
  res.attributes.sourceURL = attachmentURL.absoluteString;
  res.attributes.fileName = attachmentURL.lastPathComponent;
  res.attributes.clientWillIndex = YES;
  NSData *rawdata = nil;
  NSImageRep *rep = [NSImageRep imageRepWithContentsOfURL:attachmentURL];
  NSInteger width = 0;
  NSInteger height = 0;
  if(rep) {
    width = rep.pixelsWide;
    height = rep.pixelsHigh;
  }
  if([rep isKindOfClass:[NSBitmapImageRep class]]) {
    NSBitmapImageRep *bitmapRep = (NSBitmapImageRep *)rep;
    if([mimeType isEqualToString:@"image/jpeg"]) {
      rawdata = [bitmapRep representationUsingType:NSJPEGFileType properties:@{ NSImageCompressionFactor: @(0.8) }];
    } else if([mimeType isEqualToString:@"image/gif"]) {
      rawdata = [bitmapRep representationUsingType:NSGIFFileType properties:@{}];
    } else {
      rawdata = [bitmapRep representationUsingType:NSPNGFileType properties:@{}];
      mimeType = @"image/png";
    }
  } else if([rep isKindOfClass:[NSPDFImageRep class]]) {
    NSPDFImageRep *pdfRep = (NSPDFImageRep *)rep;
    rawdata = [pdfRep PDFRepresentation];
    mimeType = @"application/pdf";
  }
  if(!rawdata) rawdata = [NSData dataWithContentsOfURL:attachmentURL];
  if(!rawdata) return nil;
  EDAMData *data = [[EDAMData alloc] initWithBodyHash:rawdata size:(int)[rawdata length] body:rawdata];
  [res setData:data];
  [res setRecognition:data];
  res.attributes.attachment = !mimeType;
  self.resources = self.resources ? [self.resources arrayByAddingObject:res] : @[res];
  [res setMime:mimeType];
  NSString *sizeAtr = width > 0 && height > 0 ? [NSString stringWithFormat:@"height=\"%ld\" width=\"%ld\" ", height, width] : @"";
  if(!mimeType) mimeType = @"";
  return [NSString stringWithFormat:@"<en-media type=\"%@\" %@hash=\"%@\"/>", mimeType, sizeAtr, rawdata.md5];
}

//
// Returns mime-type string if embeddable
//
// http://dev.evernote.com/documentation/cloud/chapters/Resources.php#types
//
- (NSString *)mimeTypeForExtention:(NSString *)extention {
  extention = [extention lowercaseString];
  if([extention isEqualToString:@"gif"])
    return @"image/gif";
  if([extention isEqualToString:@"png"])
    return  @"image/png";
  if([@[@"jpg", @"jpeg", @"jpe", @"jig", @"jfif", @"jfi"] indexOfObject:extention] != NSNotFound)
    return @"image/jpeg";
  if([@[@"wav", @"wave"] indexOfObject:extention] != NSNotFound)
    return @"audio/wav";
  if([extention isEqualToString:@"mp3"])
    return  @"audio/mpeg";
  if([extention isEqualToString:@"amr"])
    return  @"audio/amr";
  if([extention isEqualToString:@"pdf"])
    return  @"application/pdf";
  return nil;
}

@end
