//
//  main.m
//  renderFrame
//
//  Created by Callum Smits on 19/09/2014.
//  Copyright (c) 2014 a. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "modelObjectCache.h"
#import "renderManager.h"
#import "globalSettings.h"
#import "cameraObject.h"

int main(int argc, const char * argv[])
{

    @autoreleasepool {
        
        if (argc != 3) {
            return 1;
        }
        NSString *useGPUString = [NSString stringWithCString:argv[1] encoding:NSUTF8StringEncoding];
        NSString *fileName = [NSString stringWithCString:argv[2] encoding:NSUTF8StringEncoding];
        int deviceType = CL_DEVICE_TYPE_CPU;
        if ([useGPUString intValue] > 0) {
            deviceType = CL_DEVICE_TYPE_GPU;
        }
        
        modelObjectCache *frameToRender = [[modelObjectCache alloc] initWithFile:fileName];
        NSSize imageSize;
        imageSize.width = kImageWidth;
        imageSize.height = kImageHeight;
        renderManager *r = [[renderManager alloc] initWithImageSize:imageSize deviceType:deviceType];
        [r loadLightDataFromArray:frameToRender.light_sources withAmbient:frameToRender.ambient_light numLights:frameToRender.numLights];
        
        [r loadDataFromCache:frameToRender];
        if (![r renderImage]) {
            return 1;
        };
        [r saveImage];
    }
    return 0;
}

