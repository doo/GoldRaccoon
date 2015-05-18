//
//  GRResource.h
//  DooTheSnap
//
//  Created by Constantine Fry on 18/05/15.
//  Copyright (c) 2015 doo. All rights reserved.
//

#import <Foundation/Foundation.h>

/** The resource info. */
@interface GRResource : NSObject

/** Returns kCFFTPResourceName from resource info. */
@property(nonatomic, readonly) NSString *name;

/** Returns whether kCFFTPResourceType == DT_DIR, or not. */
@property(nonatomic, readonly) BOOL isDirectory;

/** The resource info. */
@property(nonatomic, readonly) NSDictionary *resourceInfo;

-(instancetype)initWithResourceDictionary:(NSDictionary *)dictionary;

@end

