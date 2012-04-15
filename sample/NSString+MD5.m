//
//  NSString+MD5.m
//  Copyright 2011 Evernote Corporation. All rights reserved.
//

#import "NSString+MD5.h"
#import "NSDataMD5Additions.h"

@implementation NSString (MD5)

- (NSData *) md5 {
  return [[self dataUsingEncoding:NSUTF8StringEncoding] md5];
}

@end
