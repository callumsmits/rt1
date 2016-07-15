//
//  renderManager.h
//  rt1
//
//  Created by Stock Lab on 19/05/2014.
//  Copyright (c) 2014 a. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenCL/OpenCL.h>
#import "sceneController.h"
#import "modelObjectCache.h"

#define kMaxNumDevices 10
#define kMaxRenderTime 1.0

@interface renderManager : NSObject {
    unsigned char *pixelsOut;
    NSSize renderSize;
    cameraObject *camera;
}

@property (nonatomic) NSSize renderSize;
@property (nonatomic, strong) cameraObject *camera;

- (id)initWithImageSize:(NSSize)size;
- (id)initWithImageSize:(NSSize)size deviceType:(cl_int)deviceType;
- (void)loadModelDataFromWorld:(modelObject *)world;
- (void)loadDataFromCache:(modelObjectCache *)cache;
- (void)loadLightDataFromArray:(LightSourceDef *)lightArray withAmbient:(RGBColour)ambient numLights:(int)numLights;
- (BOOL)renderImage;
- (unsigned char *)pixelBuffer;
- (void)saveImage;

@end
