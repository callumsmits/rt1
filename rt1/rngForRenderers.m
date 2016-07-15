//
//  rngForRenderers.m
//  rt1
//
//  Created by Stock Lab on 18/07/2014.
//  Copyright (c) 2014 a. All rights reserved.
//

#import "rngForRenderers.h"

@interface rngForRenderers () {
    FILE *fp;
}

@end

@implementation rngForRenderers

+ (id)sharedInstance {
    static rngForRenderers *sharedGenerator = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedGenerator = [[self alloc] init];
    });
    return sharedGenerator;
}

- (id)init {
    if (self = [super init]) {
        fp = fopen("/dev/random", "r");
        
        if (!fp) {
            perror("randgetter");
            NSLog(@"Could not open /dev/random");
            return nil;
        }
    }
    return self;
}

- (uint32_t)getRandomUInt {
    uint32_t value;
    for (int i=0; i<sizeof(value); i++) {
        uint8_t c = fgetc(fp);
        value |= (c << (8 * i));
    }
    return value;
}

@end
