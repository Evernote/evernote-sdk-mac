/*
 * ENCredentials.m
 * evernote-sdk-ios
 *
 * Copyright 2012 Evernote Corporation
 * All rights reserved. 
 * 
 * Redistribution and use in source and binary forms, with or without modification, 
 * are permitted provided that the following conditions are met:
 *  
 * 1. Redistributions of source code must retain the above copyright notice, this 
 *    list of conditions and the following disclaimer.
 *     
 * 2. Redistributions in binary form must reproduce the above copyright notice, 
 *    this list of conditions and the following disclaimer in the documentation 
 *    and/or other materials provided with the distribution.
 *  
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE 
 * OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF 
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "ENCredentials.h"
#include <CoreFoundation/CoreFoundation.h>
#include <Security/Security.h>
#include <CoreServices/CoreServices.h>

@interface ENCredentials()

@end

@implementation ENCredentials

@synthesize host = _host;
@synthesize edamUserId = _edamUserId;
@synthesize noteStoreUrl = _noteStoreUrl;
@synthesize webApiUrlPrefix = _webApiUrlPrefix;
@synthesize authenticationToken = _authenticationToken;

- (id)initWithHost:(NSString *)host
        edamUserId:(NSString *)edamUserId
      noteStoreUrl:(NSString *)noteStoreUrl
   webApiUrlPrefix:(NSString *)webApiUrlPrefix
authenticationToken:(NSString *)authenticationToken
{
    self = [super init];
    if (self) {
        self.host = host;
        self.edamUserId = edamUserId;
        self.noteStoreUrl = noteStoreUrl;
        self.webApiUrlPrefix = webApiUrlPrefix;
        self.authenticationToken = authenticationToken;
    }
    return self;
}

- (BOOL)saveToKeychain
{
    // auth token gets saved to the keychain
    OSStatus status;
    
    //needed items to save token to keychain
    const char * service=[self.host UTF8String];
    const char * account=[self.edamUserId UTF8String];
    void * password=(void *)[_authenticationToken UTF8String];
    UInt32 serviceLen=(UInt32)strlen(service);
    UInt32 accountLen=(UInt32)strlen(account);
    UInt32 passwordLen=(UInt32)strlen(password);
    
    //save the token
    status=SecKeychainAddGenericPassword(NULL, serviceLen, service, accountLen,
                                         account, passwordLen, password, NULL);
    
    if (status!=noErr) {
        CFStringRef error=SecCopyErrorMessageString(status, NULL);
        NSLog(@"Error saving to keychain: %@ %i",error, status);
        CFRelease(error);
        return NO;
    } 
    return YES;
    
}

- (void)deleteFromKeychain
{
    OSStatus status;
    
    //needed for find function to find the item to delete
    const char * service=[self.host UTF8String];
    const char * account=[self.edamUserId UTF8String];
    UInt32 serviceLen=(UInt32)strlen(service);
    UInt32 accountLen=(UInt32)strlen(account);

    //will be populated by SecKeychainFindGenericPassword function call
    UInt32 passwordLen;
    void * password=nil;
    SecKeychainItemRef itemRef=nil;
    
    //find the item ref so we can delete it.
    status=SecKeychainFindGenericPassword(NULL, serviceLen, service, accountLen,
                                          account, &passwordLen, &password, &itemRef);
    
    if (status!=noErr) {
        return; //We can't find the item, so we can't delete the item. Nothing more to do here
    }
    else{
        SecKeychainItemFreeContent(NULL, password); //we don't need the password here, so we are deleting it.
    }
    
    //delete the item
    SecKeychainItemDelete(itemRef);
    CFRelease(itemRef); //delete the item ref now that we are done with it.
}

- (NSString *)authenticationToken
{
    OSStatus status;
    const char * service=[self.host UTF8String];
    const char * account=[self.edamUserId UTF8String];
    UInt32 serviceLen=(UInt32)strlen(service);
    UInt32 accountLen=(UInt32)strlen(account);
    
    //Will be populated by SecKeychainFindGenericPassword function call
    void * password=nil;
    UInt32 passwordLen;
    SecKeychainItemRef itemRef=nil;
    
    status=SecKeychainFindGenericPassword(NULL, serviceLen, service, accountLen,
                                          account, &passwordLen, &password, &itemRef);
    
    if (status!=noErr || password==nil) {
        CFStringRef error=SecCopyErrorMessageString(status, NULL);
        NSLog(@"Error getting password from keychain: %@ %i",error, status);
        CFRelease(error);
        return nil;
    }
    
    NSString *token=[NSString stringWithUTF8String:password];
    
    if(password!=nil)
        SecKeychainItemFreeContent(NULL, password);
    CFRelease(itemRef);
    return token;
}

#pragma mark - NSCoding

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:self.host forKey:@"host"];
    [encoder encodeObject:self.edamUserId forKey:@"edamUserId"];
    [encoder encodeObject:self.noteStoreUrl forKey:@"noteStoreUrl"];
    [encoder encodeObject:self.webApiUrlPrefix forKey:@"webApiUrlPrefix"];
}

- (id)initWithCoder:(NSCoder *)decoder {
    if((self = [super init])) {
        self.host = [decoder decodeObjectForKey:@"host"];
        self.edamUserId = [decoder decodeObjectForKey:@"edamUserId"];
        self.noteStoreUrl = [decoder decodeObjectForKey:@"noteStoreUrl"];
        self.webApiUrlPrefix = [decoder decodeObjectForKey:@"webApiUrlPrefix"];
    }
    return self;
}

@end
