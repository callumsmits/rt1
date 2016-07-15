//
//  rngForRenderers.h
//  rt1
//
//  Created by Stock Lab on 18/07/2014.
//  Copyright (c) 2014 a. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface rngForRenderers : NSObject

+ (id) sharedInstance;
- (uint32_t)getRandomUInt;

@end
