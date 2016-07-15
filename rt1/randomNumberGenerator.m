//
//  randomNumberGenerator.m
//  rt1
//
//  Created by Callum Smits on 10/05/2014.
//  Copyright (c) 2014 a. All rights reserved.
//

#import "randomNumberGenerator.h"

@interface randomNumberGenerator () {
    FILE *fp;
}

@end

@implementation randomNumberGenerator 

+ (id)sharedInstance {
    static randomNumberGenerator *sharedGenerator = nil;
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

- (uint8_t)getRandomByte {
    return fgetc(fp);
}

- (int16_t)getRandomShort {
    int16_t value;
    for (int i=0; i<sizeof(value); i++) {
        uint8_t c = fgetc(fp);
        value |= (c << (8 * i));
    }
    return value;
}

- (uint16_t)getRandomUShort {
    uint16_t value;
    for (int i=0; i<sizeof(value); i++) {
        uint8_t c = fgetc(fp);
        value |= (c << (8 * i));
    }
    return value;
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
