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

/** The resource name. */
@property(nonatomic, strong) NSString *name;

/** Whether resource is directory or not. */
@property(nonatomic, assign) BOOL isDirectory;

/** The resource info. */
@property(nonatomic, readonly) NSDictionary *resourceInfo;

-(instancetype)initWithResourceDictionary:(NSDictionary *)dictionary;

@end

