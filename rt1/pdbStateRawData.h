//
//  pdbStateRawData.h
//  rt1
//
//  Created by Callum Smits on 8/05/2014.
//  Copyright (c) 2014 a. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "bvhObject.h"

@interface pdbStateRawData : NSObject {
    float *stateModelData;
    bvhObject *stateBVH;
}

@property (nonatomic) float *stateModelData;
@property (nonatomic, strong) bvhObject *stateBVH;

@end
