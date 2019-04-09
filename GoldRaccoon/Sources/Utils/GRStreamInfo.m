//
//  GRStreamInfo.m
//  GoldRaccoon
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

#import "GRStreamInfo.h"
#import "GRRequest.h"

@implementation GRStreamInfo

- (instancetype)init
{
    self = [super init];
    if (self) {
        _writeStream = nil;
        _readStream = nil;
        _bytesThisIteration = 0;
        _bytesTotal = 0;
        _timeout = 30;
        _cancelRequestFlag = NO;
        _cancelDoesNotCallDelegate = NO;
    }
    
    return self;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

- (void)openRead:(GRRequest *)request
{
    if ([request.dataSource hostnameForRequest:request] == nil) {
        request.error = [GRError errorWithCode:kGRFTPClientHostnameIsNil];
        [request.streamInfo close:request];
        [request.delegate requestFailed:request];
        return;
    }
    
    // a little bit of C because I was not able to make NSInputStream play nice
    CFReadStreamRef readStreamRef = CFReadStreamCreateWithFTPURL(NULL, ( __bridge CFURLRef) request.fullURL);
    if (readStreamRef == NULL) {
        request.error = [GRError errorWithCode:kGRFTPClientCantOpenStream];
        [request.streamInfo close:request];
        [request.delegate requestFailed:request];
        return;
    }
    
    if (!request.attemptPersistentConnection) {
        CFReadStreamSetProperty(readStreamRef,
                                kCFStreamPropertyFTPAttemptPersistentConnection,
                                kCFBooleanFalse);
    }
   
    CFReadStreamSetProperty(readStreamRef, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
	CFReadStreamSetProperty(readStreamRef, kCFStreamPropertyFTPUsePassiveMode, request.passiveMode ? kCFBooleanTrue :kCFBooleanFalse);
    CFReadStreamSetProperty(readStreamRef, kCFStreamPropertyFTPFetchResourceInfo, kCFBooleanTrue);
    CFReadStreamSetProperty(readStreamRef, kCFStreamPropertyFTPUserName, (__bridge CFStringRef) [request.dataSource usernameForRequest:request]);
    CFReadStreamSetProperty(readStreamRef, kCFStreamPropertyFTPPassword, (__bridge CFStringRef) [request.dataSource passwordForRequest:request]);
    
    dispatch_queue_t queue = (request.queue == nil) ? dispatch_get_main_queue() : request.queue;
    CFReadStreamSetDispatchQueue(readStreamRef, queue);
    
    if (request.manualSSLCertificateValidation) {
        NSDictionary *sslSettings = @{(id)kCFStreamSSLValidatesCertificateChain:@(NO)};
        CFReadStreamSetProperty(readStreamRef, kCFStreamPropertySSLSettings, (__bridge CFDictionaryRef) sslSettings);
    }

    
    self.readStream = ( __bridge_transfer NSInputStream *) readStreamRef;
    
    self.readStream.delegate = request;
	[self.readStream open];
    
    request.didOpenStream = NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, self.timeout * NSEC_PER_SEC), request.queue, ^{
        if (!request.didOpenStream && request.error == nil) {
            request.error = [GRError errorWithCode:kGRFTPClientStreamTimedOut];
            [request.streamInfo close:request];
            [request.delegate requestFailed:request];
        }
    });
}

- (void)openWrite:(GRRequest *)request
{
    if ([request.dataSource hostnameForRequest:request] == nil) {
        request.error = [GRError errorWithCode:kGRFTPClientHostnameIsNil];
        [request.streamInfo close:request];
        [request.delegate requestFailed:request];
        return;
    }
    
    CFWriteStreamRef writeStreamRef = CFWriteStreamCreateWithFTPURL(NULL, ( __bridge CFURLRef) request.fullURL);
    
    if (writeStreamRef == NULL) {
        request.error = [GRError errorWithCode:kGRFTPClientCantOpenStream];
        [request.streamInfo close:request];
        [request.delegate requestFailed:request];
        return;
    }
    
    if (!request.attemptPersistentConnection) {
        CFWriteStreamSetProperty(writeStreamRef,
                                 kCFStreamPropertyFTPAttemptPersistentConnection,
                                 kCFBooleanFalse);
    }
    
    CFWriteStreamSetProperty(writeStreamRef, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
	CFWriteStreamSetProperty(writeStreamRef, kCFStreamPropertyFTPUsePassiveMode, request.passiveMode ? kCFBooleanTrue :kCFBooleanFalse);
    CFWriteStreamSetProperty(writeStreamRef, kCFStreamPropertyFTPFetchResourceInfo, kCFBooleanTrue);
    CFWriteStreamSetProperty(writeStreamRef, kCFStreamPropertyFTPUserName, (__bridge CFStringRef) [request.dataSource usernameForRequest:request]);
    CFWriteStreamSetProperty(writeStreamRef, kCFStreamPropertyFTPPassword, (__bridge CFStringRef) [request.dataSource passwordForRequest:request]);
    
    dispatch_queue_t queue = (request.queue == nil) ? dispatch_get_main_queue() : request.queue;
    CFWriteStreamSetDispatchQueue(writeStreamRef, queue);
    
    if (request.manualSSLCertificateValidation) {
        NSDictionary *sslSettings = @{(id)kCFStreamSSLValidatesCertificateChain:@(NO)};
        CFWriteStreamSetProperty(writeStreamRef, kCFStreamPropertySSLSettings, (__bridge CFDictionaryRef) sslSettings);
    }

    self.writeStream = ( __bridge_transfer NSOutputStream *) writeStreamRef;
    
    self.writeStream.delegate = request;
    [self.writeStream open];
    
    request.didOpenStream = NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, self.timeout * NSEC_PER_SEC), request.queue, ^{
        if (!request.didOpenStream && (request.error == nil)) {
            request.error = [GRError errorWithCode:kGRFTPClientStreamTimedOut];
            [request.streamInfo close:request];
            [request.delegate requestFailed:request];
        }
    });
}

#pragma clang diagnostic pop

- (BOOL)checkCancelRequest:(GRRequest *)request
{
    if (!self.cancelRequestFlag) {
        return NO;
    }
    
    [request.streamInfo close:request];
    // see if we don't want to call the delegate (set and forget)
    if (!self.cancelDoesNotCallDelegate) {
        [request.delegate requestCompleted:request];
    }
    
    return YES;
}

- (NSData *)read:(GRRequest *)request
{
    NSData *data;
    NSMutableData *bufferObject = [NSMutableData dataWithLength:kGRDefaultBufferSize];

    self.bytesThisIteration = [self.readStream read:(UInt8 *)[bufferObject bytes] maxLength:kGRDefaultBufferSize];
    self.bytesTotal += self.bytesThisIteration;
    
    // return the data
    if (self.bytesThisIteration > 0) {
        data = [NSData dataWithBytes:(UInt8 *)[bufferObject bytes] length:self.bytesThisIteration];
        request.percentCompleted = self.bytesTotal / request.maximumSize;
        
        if ([request.delegate respondsToSelector:@selector(percentCompleted:forRequest:)]) {
            [request.delegate percentCompleted:request.percentCompleted forRequest:request];
        }
        
        return data;
    }
    
    // return no data, but this isn't an error... just the end of the file
    else if (self.bytesThisIteration == 0) {
        return [NSData data]; // returns empty data object - means no error, but no data
    }
    
    // otherwise we had an error, return an error
    NSError *error = [GRError errorWithCode:kGRFTPClientCantReadStream];
    [self streamError:request error:error];
    
    return nil;
}

- (BOOL)write:(GRRequest *)request data:(NSData *)data
{
    self.bytesThisIteration = [self.writeStream write:[data bytes] maxLength:[data length]];
    self.bytesTotal += self.bytesThisIteration;
            
    if (self.bytesThisIteration > 0) {
        request.percentCompleted = self.bytesTotal / request.maximumSize;
        if ([request.delegate respondsToSelector:@selector(percentCompleted:forRequest:)]) {
            [request.delegate percentCompleted:request.percentCompleted forRequest:request];
        }
        
        return YES;
    }
    
    if (self.bytesThisIteration == 0) {
        return YES;
    }
    NSError *error = [GRError errorWithCode:kGRFTPClientCantReadStream];
    [self streamError:request error:error]; // perform callbacks and close out streams

    return NO;
}

- (void)streamError:(GRRequest *)request error:(NSError *)error
{
    [request.streamInfo close:request];
    request.error = [GRError proccessError:error];
    [request.delegate requestFailed:request];
}

- (void)streamComplete:(GRRequest *)request
{
    [request.streamInfo close:request];
    [request.delegate requestCompleted:request];
}

- (void)close:(GRRequest *)request
{
    if (self.readStream) {
//        [self.readStream close];
        self.readStream = nil;
    }
    
    if (self.writeStream) {
        [self.writeStream close];
        self.writeStream = nil;
    }
    
    request.streamInfo = nil;
}

@end
