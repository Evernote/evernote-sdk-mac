//
//  NSDataMD5Additions.m
//  Copyright 2011 Evernote Corp. All rights reserved.
//

#import "NSDataMD5Additions.h"
#import "MD5.h"

@implementation NSData (NSDataMD5Additions)

// see .h
- (NSData *) md5
{
	
  MD5_CTX mdContext;

  MD5Init (&mdContext);
  MD5Update (&mdContext, [self bytes], [self length]);
  MD5Final (&mdContext);

  NSMutableData * md5Data = [NSMutableData dataWithBytes:(mdContext.digest) length: 16];

  return md5Data;
}


@end
