//
//  GRResource.m
//  DooTheSnap
//
//  Created by Constantine Fry on 18/05/15.
//  Copyright (c) 2015 doo. All rights reserved.
//

#import "GRResource.h"

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

@end
