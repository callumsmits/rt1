//
//  randomNumberGenerator.h
//  rt1
//
//  Created by Callum Smits on 10/05/2014.
//  Copyright (c) 2014 a. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface randomNumberGenerator : NSObject {
    
}

+ (id) sharedInstance;
- (uint8_t)getRandomByte;
- (int16_t)getRandomShort;
- (uint16_t)getRandomUShort;
- (uint32_t)getRandomUInt;
@end
