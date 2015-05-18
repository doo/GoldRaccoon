//
//  GRResource.m
//  DooTheSnap
//
//  Created by Constantine Fry on 18/05/15.
//  Copyright (c) 2015 doo. All rights reserved.
//

#import "GRResource.h"
#import "sys/dirent.h"

@interface GRResource()

@property(nonatomic, strong) NSDictionary *resourceInfo;

@end

@implementation GRResource

-(instancetype)initWithResourceDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        _resourceInfo = dictionary;
    }
    return self;
}

- (NSString *)name {
    return self.resourceInfo[(id)kCFFTPResourceName];
}

- (BOOL)isDirectory {
    return [self.resourceInfo[(id)kCFFTPResourceType] intValue] == DT_DIR;
}

@end
