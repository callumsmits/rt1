//
//  NABaseModelObject.m
//  rt1
//
//  Created by Callum Smits on 15/08/2014.
//  Copyright (c) 2014 a. All rights reserved.
//

#import "NABaseModelObject.h"

@implementation NABaseModelObject

- (id)initWithBase:(NSString *)base naType:(uint)type {

    if (self = [super init]) {
        pdbData *newBasePDB = [[NABasePDBData alloc] initWithBase:base naType:type];
        [self setModelWithPDBData:newBasePDB];
    }
    return self;
}

- (Vector)defaultModelOrientation {
    Vector d;
    d.x = 0;
    d.y = -1;
    d.z = 0;
    d.w = 0;
    
    return d;
}

- (Vector)defaultAxisOrientation {
    Vector d;
    d.x = 0;
    d.y = 0;
    d.z = 1;
    d.w = 0;
    
    return d;
}

@end
