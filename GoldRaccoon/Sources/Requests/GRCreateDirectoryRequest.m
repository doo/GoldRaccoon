//
//  GRCreateDirectoryRequest.m
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

#import "GRCreateDirectoryRequest.h"
#import "GRListingRequest.h"

@interface GRCreateDirectoryRequest () <GRRequestDelegate, GRRequestDataSource, GRRequesSSLServerTrustDelegate>

@property GRListingRequest *listrequest;

@end

@implementation GRCreateDirectoryRequest

@synthesize listrequest;

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
    if ([self hostnameForRequest:self] == nil) {
        self.error = [GRError errorWithCode:kGRFTPClientHostnameIsNil];
        [self.delegate requestFailed:self];
        return;
    }
    
    // we first list the directory to see if our folder is up already
    self.listrequest = [[GRListingRequest alloc] initWithDelegate:self datasource:self];
    self.listrequest.path = [self.path stringByDeletingLastPathComponent];
    self.listrequest.queue = self.queue;
    if (self.serverTrustDelegate != nil) {
        self.listrequest.serverTrustDelegate = self;
    }
    [self.listrequest start];
}

#pragma mark - GRRequestDelegate

- (void)requestCompleted:(GRRequest *)request
{
    NSString *directoryName = [[self.path lastPathComponent] stringByTrimmingCharactersInSet:
                               [NSCharacterSet characterSetWithCharactersInString:@"/"]];

    if ([self.listrequest fileExists:directoryName]) {
        NSError *error = [GRError errorWithCode:kGRFTPClientCantOverwriteDirectory];
        [self.streamInfo streamError:self error:error];
    }
    else {
        // open the write stream and check for errors calling delegate methods
        // if things fail. This encapsulates the streamInfo object and cleans up our code.
        [self.streamInfo openWrite:self];
    }
}

- (void)request:(id<GRRequestProtocol>)request
didReceiveSSLServerTrust:(SecTrustRef)serverTrust
completionHandler:(void (^)(BOOL))completionHandler {
    [self.serverTrustDelegate request:self didReceiveSSLServerTrust:serverTrust completionHandler:completionHandler];
}


- (void)requestFailed:(GRRequest *)request
{
    self.error = request.error;
    [self.delegate requestFailed:self];
}

- (BOOL)shouldOverwriteFile:(NSString *)filePath forRequest:(id<GRDataExchangeRequestProtocol>)request
{
    return NO;
}

#pragma mark - GRRequestDataSource

- (NSString *)hostnameForRequest:(id<GRRequestProtocol>)request
{
    return [self.dataSource hostnameForRequest:self];
}

- (NSString *)usernameForRequest:(id<GRRequestProtocol>)request
{
    return [self.dataSource usernameForRequest:self];
}

- (NSString *)passwordForRequest:(id<GRRequestProtocol>)request
{
    return [self.dataSource passwordForRequest:self];
}

#pragma mark - NSStreamDelegate

- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent
{
    [super stream:theStream handleEvent:streamEvent];
    
    // see if we have cancelled the runloop
    if ([self.streamInfo checkCancelRequest:self]) {
        return;
    }
    
    switch (streamEvent) {
        // XCode whines about this missing - which is why it is here
        case NSStreamEventNone:
        case NSStreamEventHasBytesAvailable:
        case NSStreamEventHasSpaceAvailable: {
            break;
        }
            
        case NSStreamEventOpenCompleted: {
            self.didOpenStream = YES;
            break;
        }

        case NSStreamEventErrorOccurred: {
            // perform callbacks and close out streams
            [self.streamInfo streamError:self error:[theStream streamError]];
            break;
        }
            
        case NSStreamEventEndEncountered: {
            // perform callbacks and close out streams
            [self.streamInfo streamComplete:self];
            break;
        }
            
        default:
            break;
    }
}

@end
