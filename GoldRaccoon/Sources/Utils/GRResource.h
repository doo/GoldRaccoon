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

/** 
 * The permissions of the resource. eg:
 * 365: 101 101 101
 * 493: 111 101 101
 * 511: 111 111 111
 */
@property(nonatomic, strong) NSNumber *permissions;

/** The owner of the resource. */
@property(nonatomic, strong) NSString *owner;

/** The group of the resource. */
@property(nonatomic, strong) NSString *group;

/**
  * The link of the resource.
  * If the item is a symbolic link the string will contain the path to the item the link references.
 */
@property(nonatomic, strong) NSString *link;

/** The size of the resource. Long long type. */
@property(nonatomic, strong) NSNumber *size;

/** The resource type as defined in sys/dirent.h. */
@property(nonatomic, strong) NSNumber *type;

/** The modification date. */
@property(nonatomic, strong) NSDate *modificationDate;


/** Whether resource is directory or not. */
@property(nonatomic, assign) BOOL isDirectory;

@end

