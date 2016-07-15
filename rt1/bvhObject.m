//
//  bvhObject.m
//  present
//
//  Created by Callum Smits on 9/07/13.
//  Copyright (c) 2013 Callum Smits. All rights reserved.
//

#import "bvhObject.h"
#import "matrix_ops.h"

@implementation bvhObject

@synthesize x, y, z, radius, leafNode, children, atoms;

- (id)initWithX:(float)newX Y:(float)newY Z:(float)newZ radius:(float)newRadius isLeafNode:(bool)newLeafNode {
    
    self = [super init];
    if (self) {
        x = newX;
        y = newY;
        z = newZ;
        radius = newRadius;
        leafNode = newLeafNode;
        atoms = 0;
        self.children = [NSMutableArray arrayWithCapacity:0];
    }
    
    return self;
}

- (id)copyWithTransform:(Matrix)transform {
    Vector pos;
    pos.x = self.x;
    pos.y = self.y;
    pos.z = self.z;
    pos.w = 1.0;
    
    Vector newPos = vectorMatrixMultiply(transform, pos);
    
    bvhObject *new = [[bvhObject alloc] initWithX:newPos.x Y:newPos.y Z:newPos.z radius:self.radius isLeafNode:self.leafNode];
    new.atoms = atoms;
    if ((self.leafNode == YES) && (new)) {
        new.children = [NSMutableArray arrayWithArray:self.children];
    } else if ((self.leafNode == NO) && (new)) {
        new.children = [NSMutableArray arrayWithCapacity:[self.children count]];
        for (int i = 0; i < [self.children count]; i++) {
            bvhObject *child = [self.children objectAtIndex:i];
            [new.children addObject:[child copyWithTransform:transform]];
        }
    }
    
    return new;
}

- (NSUInteger) hash {
    return abs((int)(x * 1000)) + abs((int)(y * 1000)) + abs((int)(z * 1000) + abs((int)(radius * 1000)));
}

- (BOOL) isEqual:(id)object {
    if ([object class] == [self class]) {
        bvhObject *o = object;
        if ((x == o.x) && (y == o.y) && (z == o.z) && (radius == o.radius)) {
            return YES;
        }
    }
    return NO;
}

@end
