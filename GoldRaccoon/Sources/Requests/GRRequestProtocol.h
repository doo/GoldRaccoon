//
//  GRRequestDelegate.h
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

#import <Foundation/Foundation.h>

@class GRRequest;
@class GRError;
@class GRStreamInfo;

@protocol GRRequesSSLServerTrustDelegate;

@protocol GRRequestProtocol <NSObject>

@property (nonatomic, assign) BOOL passiveMode;
@property (nonatomic, copy) NSString *uuid;

@property (nonatomic, copy) NSString *path;
@property (nonatomic, strong) NSError *error;
@property (nonatomic, strong) GRStreamInfo *streamInfo;

@property (nonatomic, assign) float maximumSize;
@property (nonatomic, assign) float percentCompleted;

@property (nonatomic, assign) BOOL implicitSSL;

/** If set, the delegate is be responsible for validating SSL server trust. Should be set before starting request. */
@property (nonatomic, weak) id <GRRequesSSLServerTrustDelegate> serverTrustDelegate;

/** The queue for input/output streams. Default is the main queue. */
@property (nonatomic, strong) dispatch_queue_t queue;

- (NSURL *)fullURL;
- (NSURL *)fullURLWithEscape;
- (void)start;
- (void)cancelRequest;

@end

@protocol GRDataExchangeRequestProtocol <GRRequestProtocol>

@property (nonatomic, copy) NSString *localFilePath;
@property (nonatomic, readonly) NSString *fullRemotePath;

@end

@protocol GRRequestDelegate <NSObject>

@required
- (void)requestCompleted:(id<GRRequestProtocol>)request;
- (void)requestFailed:(id<GRRequestProtocol>)request;

@optional
- (void)percentCompleted:(float)percent forRequest:(id<GRRequestProtocol>)request;
- (void)dataAvailable:(NSData *)data forRequest:(id<GRDataExchangeRequestProtocol>)request;
- (BOOL)shouldOverwriteFile:(NSString *)filePath forRequest:(id<GRDataExchangeRequestProtocol>)request;

@end

@protocol GRRequesSSLServerTrustDelegate <NSObject>
@required

- (void)request:(id<GRRequestProtocol>)request
    didReceiveSSLServerTrust:(SecTrustRef)serverTrust
    completionHandler:(void (^)(BOOL trust))completionHandler;



@end

@protocol GRRequestDataSource <NSObject>

@required
- (NSString *)hostnameForRequest:(id<GRRequestProtocol>)request;
- (NSString *)usernameForRequest:(id<GRRequestProtocol>)request;
- (NSString *)passwordForRequest:(id<GRRequestProtocol>)request;

@optional
- (long)dataSizeForUploadRequest:(id<GRDataExchangeRequestProtocol>)request;
- (NSData *)dataForUploadRequest:(id<GRDataExchangeRequestProtocol>)request;

@end
