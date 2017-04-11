//
//  GRRequest.h
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

#import "GRRequestProtocol.h"
#import "GRError.h"
#import "GRStreamInfo.h"

@class GRRequest;
@class GRDownloadRequest;
@class GRUploadRequest;

@interface GRRequest : NSObject <NSStreamDelegate, GRRequestProtocol>
{
    NSString *_path;
}

@property (nonatomic, weak) id <GRRequestDelegate> delegate;

/** If set, the delegate is be responsible for validating SSL server trust. 
 Should be set before starting request. The delegate will only be called when `manualSSLCertificateValidation` set to YES. */
@property (nonatomic, weak) id <GRRequesSSLServerTrustDelegate> serverTrustDelegate;

@property (nonatomic, weak) id <GRRequestDataSource> dataSource;

@property (nonatomic, readonly) long bytesSent;                 // will have bytes from the last FTP call
@property (nonatomic, readonly) long totalBytesSent;            // will have bytes total sent
@property (nonatomic, assign) BOOL didOpenStream;               // whether the stream opened or not
@property (nonatomic, assign) BOOL cancelDoesNotCallDelegate;   // cancel closes stream without calling delegate
@property (nonatomic, assign) BOOL manualSSLCertificateValidation;

/** The encoding used for resource names.
 See CFStringEncodings and CFStringBuiltInEncodings.
 Defaults to kCFStringEncodingUTF8. */
@property (nonatomic, assign) CFStringEncoding encoding;


/** The queue for input/output streams. Default is the main queue. */
@property (nonatomic, strong) dispatch_queue_t queue;

/** Whether request should try to perisist connection or not. Defaults to NO. */
@property (nonatomic, assign) BOOL attemptPersistentConnection;

- (instancetype)initWithDelegate:(id<GRRequestDelegate>)aDelegate datasource:(id<GRRequestDataSource>)aDatasource;

/** 
 Implements custem SSL trust validation.
 Can close the stream, if certificate is not trusted by 'serverTrustDelegate'. Subclasses must call super. 
 */
- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent  __attribute__((objc_requires_super));

@end
