//
//  sceneController.h
//  rt1
//
//  Created by Stock Lab on 8/05/2014.
//  Copyright (c) 2014 a. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cameraObject.h"
#import "modelObject.h"
#import "globalSettings.h"


@interface sceneController : NSObject {
    cameraObject *camera;
    NSSize imageSize;
    int num_lights;
    LightSourceDef  light_sources[kMaxNumLights];
    RGBColour       ambient_light;
    modelObject *world;
}

@property (nonatomic, strong) cameraObject *camera;
@property (nonatomic, strong) modelObject *world;
@property (nonatomic) int num_lights;
@property (nonatomic) RGBColour ambient_light;
@property (nonatomic) NSSize imageSize;

- (void)initScene;
- (void)sceneManagementForFrame:(int)f;
- (LightSourceDef *)light_sources;

@end
