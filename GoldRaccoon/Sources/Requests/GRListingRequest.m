//
//  GRListingRequest.m
//  GoldRaccoon
//  v1.0.1
//
//  Created by Valentin Radu on 8/23/11.
//  Copyright 2011 Valentin Radu. All rights reserved.
//
//  Modified and/or redesigned by Lloyd Sargent to be ARC compliant.
//  Copyright 2012 Lloyd Sargent. All rights reserved.
//
//  Modified and redesigned by Alberto De Bortoli.
//  Copyright 2013 Alberto De Bortoli. All rights reserved.
//

#import "GRListingRequest.h"
#import "GRResource.h"
#import "sys/dirent.h"

@interface GRListingRequest ()

@property (nonatomic, strong) NSMutableData *receivedData;

@end

@implementation GRListingRequest

@synthesize filesInfo = _filesInfo;
@synthesize receivedData = _receivedData;

- (BOOL)fileExists:(NSString *)fileNamePath
{
    NSString *fileName = [[fileNamePath lastPathComponent] stringByTrimmingCharactersInSet:
                          [NSCharacterSet characterSetWithCharactersInString:@"/"]];
    
    for (GRResource *resource in self.filesInfo) {
        if ([fileName isEqualToString:resource.name]) {
            return YES;
        }
    }
    
    return NO;
}

- (NSString *)path
{
    // the path will always point to a directory, so we add the final slash to it
    // (if there was one before escaping/standardizing, it's *gone* now)
    NSString *directoryPath = [super path];
    if (![directoryPath hasSuffix: @"/"]) {
        directoryPath = [directoryPath stringByAppendingString:@"/"];
    }
    return directoryPath;
}

- (void)start
{
    self.maximumSize = LONG_MAX;
    
    // open the read stream and check for errors calling delegate methods
    // if things fail. This encapsulates the streamInfo object and cleans up our code.
    [self.streamInfo openRead:self];
}

- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent
{
    [super stream:theStream handleEvent:streamEvent];
    
    // see if we have cancelled the runloop
    if ([self.streamInfo checkCancelRequest:self]) {
        return;
    }
    
    NSData *data;
    switch (streamEvent) {
        case NSStreamEventOpenCompleted: {
			self.filesInfo = [NSMutableArray array];
            self.didOpenStream = YES;
            self.receivedData = [NSMutableData data];
            break;
        }
            
        case NSStreamEventHasBytesAvailable: {
            data = [self.streamInfo read:self];
            
            if (data) {
                [self.receivedData appendData:data];
            }
            else {
                NSError *error = [GRError errorWithCode:kGRFTPClientCantReadStream];
                [self.streamInfo streamError:self error:error];
            }
            break;
        }
            
        case NSStreamEventHasSpaceAvailable:
        break;
            
        case NSStreamEventErrorOccurred: {
            [self.streamInfo streamError:self error:[theStream streamError]];
            break;
        }
            
        case NSStreamEventEndEncountered: {
            NSUInteger  offset = 0;
            CFIndex     parsedBytes;
            uint8_t *bytes = (uint8_t *)[self.receivedData bytes];
            NSUInteger totalbytes = [self.receivedData length];
            
            do {
                CFDictionaryRef listingEntity = NULL;
                parsedBytes = CFFTPCreateParsedResourceListing(NULL, &bytes[offset], totalbytes - offset, &listingEntity);
                if (parsedBytes > 0) {
                    if (listingEntity != NULL) {
                        NSDictionary *dictionary = (__bridge_transfer NSDictionary *)listingEntity;
                        GRResource *resource = [[GRResource alloc] initWithResourceDictionary:dictionary];
                        self.filesInfo = [self.filesInfo arrayByAddingObject:resource];
                        resource.isDirectory = [dictionary[(id)kCFFTPResourceType] intValue] == DT_DIR;
                        
                        // CFFTPCreateParsedResourceListing assumes that the names are in MacRoman.
                        // To fix it we create data from string and read it with correct encoding.
                        // https://devforums.apple.com/message/155626#155626
                        resource.name = dictionary[(id)kCFFTPResourceName];
                        if (self.encoding != NSMacOSRomanStringEncoding) {
                            NSData *nameData = [resource.name dataUsingEncoding:NSMacOSRomanStringEncoding];
                            resource.name = [[NSString alloc] initWithData:nameData encoding:NSUTF8StringEncoding];
                        }
                    }
                    offset += parsedBytes;
                }
            } while (parsedBytes > 0);
            
            [self.streamInfo streamComplete:self];
            break;
        }
        
        default:
            break;
    }
}

@end
