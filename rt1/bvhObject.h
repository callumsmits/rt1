//
//  bvhObject.h
//  present
//
//  Created by Callum Smits on 9/07/13.
//  Copyright (c) 2013 Callum Smits. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "typedefs.h"

@interface bvhObject : NSObject {
    float x, y, z, radius;
    bool leafNode;
    unsigned long atoms;
    NSMutableArray *children;
}

@property (nonatomic) float x;
@property (nonatomic) float y;
@property (nonatomic) float z;
@property (nonatomic) float radius;
@property (nonatomic) bool leafNode;
@property (nonatomic) unsigned long atoms;
@property (nonatomic) NSMutableArray *children;

- (id)initWithX:(float)newX Y:(float)newY Z:(float)newZ radius:(float)newRadius isLeafNode:(bool)newLeafNode;
- (id)copyWithTransform:(Matrix)transform;

@end
