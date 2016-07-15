//
//  sceneLoader.m
//  rt1
//
//  Created by Stock Lab on 8/05/2014.
//  Copyright (c) 2014 a. All rights reserved.
//

#import "sceneLoader.h"
#import "beizerCurve.h"
#import "NAModelObject.h"
#import "colourPalette.h"
#import "vector_ops.h"

@interface sceneLoader () {
    dispatch_group_t _dispatch_group;
}

@end

@implementation sceneLoader

- (id)init {
    
    if (self = [super init]) {
        _dispatch_group = dispatch_group_create();
    }
    
    return self;
}


- (modelObject *)loadScene {
    
    modelObject *world = [[modelObject alloc] init];
    
    return world;
}

@end
