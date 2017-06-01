//
//  GRError.m
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

#import "GRError.h"

NSString *GRErrorDomain = @"GRErrorDomain";

@implementation GRError

+ (GRErrorCodes)errorCodeWithError:(NSError *)error
{
    // As suggested by RMaddy
    NSNumber *code = [error.userInfo objectForKey:(id)kCFFTPStatusCodeKey];
    if (code != nil) {
        return [code intValue];
    }
    return 0;
}

+ (NSError *)proccessError:(NSError *)error
{
    // As suggested by RMaddy
    NSNumber *code = [error.userInfo objectForKey:(id)kCFFTPStatusCodeKey];
    if (code != nil) {
        NSMutableDictionary *userInfo = [error.userInfo mutableCopy];
        if (userInfo == nil) {
            userInfo = [[NSMutableDictionary alloc] init];
        }
        NSString *message = [self messageForErrorCode:(GRErrorCodes)code.integerValue];
        if (message != nil) {
            userInfo[NSLocalizedDescriptionKey] = message;
        }
        return [NSError errorWithDomain:error.domain code:error.code userInfo:userInfo];
    }
    return error;
}

+ (NSError *)errorWithCode:(GRErrorCodes)code {
   return [NSError errorWithDomain:GRErrorDomain
                              code:code
                          userInfo:@{NSLocalizedDescriptionKey:[self messageForErrorCode:code]}];
}

+ (NSString *)messageForErrorCode:(GRErrorCodes)code {
    NSString *errorMessage = nil;
    switch (code) {
            // Client errors
        case kGRFTPClientSentDataIsNil:
            errorMessage = @"Data is nil.";
            break;
            
        case kGRFTPClientCantOpenStream:
            errorMessage = @"Unable to open stream.";
            break;
            
        case kGRFTPClientCantWriteStream:
            errorMessage = @"Unable to write to open stream.";
            break;
            
        case kGRFTPClientCantReadStream:
            errorMessage = @"Unable to read from open stream.";
            break;
            
        case kGRFTPClientHostnameIsNil:
            errorMessage = @"Hostname is nil.";
            break;
            
        case kGRFTPClientFileAlreadyExists:
            errorMessage = @"File already exists!";
            break;
            
        case kGRFTPClientCantOverwriteDirectory:
            errorMessage = @"Can't overwrite directory!";
            break;
            
        case kGRFTPClientStreamTimedOut:
            errorMessage = @"Connection timed out with no response from server.";
            break;
            
        case kGRFTPClientCantDeleteFileOrDirectory:
            errorMessage = @"Can't delete file or directory.";
            break;
            
        case kGRFTPClientMissingRequestDataAvailable:
            errorMessage = @"Delegate missing dataAvailable:forRequest:";
            break;
            
            // Server errors
        case kGRFTPServerAbortedTransfer:
            errorMessage = @"Server aborted transfer.";
            break;
            
        case kGRFTPServerResourceBusy:
            errorMessage = @"Resource is busy.";
            break;
            
        case kGRFTPServerCantOpenDataConnection:
            errorMessage = @"Server can't open data connection.";
            break;
            
        case kGRFTPServerUserNotLoggedIn:
            errorMessage = @"Not logged in.";
            break;
            
        case kGRFTPServerStorageAllocationExceeded:
            errorMessage = @"Server allocation exceeded!";
            break;
            
        case kGRFTPServerIllegalFileName:
            errorMessage = @"Illegal file name.";
            break;
            
        case kGRFTPServerFileNotAvailable:
            errorMessage = @"File or directory not available or directory already exists.";
            break;
            
        case kGRFTPServerUnknownError:
            errorMessage = @"Unknown FTP error!";
            break;
    }
    
    return errorMessage;
}


@end
