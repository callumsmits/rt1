//
//  ray.m
//  rt1
//
//  Created by Stock Lab on 8/05/2014.
//  Copyright (c) 2014 a. All rights reserved.
//

#import "ray.h"
#import "rendererObject.h"

@interface ray () {
    rendererObject *r;
}

@property (nonatomic, strong) rendererObject *r;

@end

@implementation ray

@synthesize r;

- (void)initRenderer {
    self.r = [[rendererObject alloc] init];
    
}

- (void)renderFrame {
    
}

@end
