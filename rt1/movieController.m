//
//  movieController.m
//  rt1
//
//  Created by Stock Lab on 8/05/2014.
//  Copyright (c) 2014 a. All rights reserved.
//

#import "movieController.h"
#import "movie.h"
#import "renderManager.h"
#import "modelObjectCache.h"

@interface movieController () {
    sceneController *sc;
    int totalFrames;
    movie *m;
    NSSize frameSize;
    renderManager *r;
    NSMutableArray *renderCache;
    int animFrame, renderFrame;
}

@property (nonatomic, strong) sceneController *sc;
@property (nonatomic, strong) movie *m;
@property (nonatomic, strong) renderManager *r;
@property (nonatomic, strong) NSMutableArray *renderCache;

- (void)processFrame;
- (BOOL)shouldRenderFrame;
- (void)renderLoop;

@end

@implementation movieController

@synthesize world, sc, m, r, renderCache;

- (void)setupMovieControllerWithScene:(modelObject *)newScene sceneController:(sceneController *)controller totalNumFrames:(int)nf frameSize:(NSSize)s {
    self.world = newScene;
    animFrame = renderFrame = 0;
    self.sc = controller;
    totalFrames = nf;
    frameSize = s;
    m = [[movie alloc] init];
    [m setupProResVideoWithPath:@"/Users/stocklab/Documents/Callum/rt1NG/output.mov" withSize:frameSize];
    
    r = [[renderManager alloc] initWithImageSize:frameSize];
    r.camera = sc.camera;
//    [r setupDeviceCPU];
    [r loadLightDataFromArray:[sc light_sources] withAmbient:sc.ambient_light numLights:sc.num_lights];
    self.renderCache = [NSMutableArray arrayWithCapacity:0];

}

- (void)renderMovieST {
    while (animFrame < totalFrames) {
        @autoreleasepool {
            [sc sceneManagementForFrame:animFrame];
            printf("Animating...");
            bool worldMoved = [world calculateAnimationWithFrame:animFrame];
            if (worldMoved || (animFrame == 0)) {
                [world applyTransformation];
                [world loadData];
                [sc.camera calculateCameraAnimationWithFrame:0];
            }
            if (([sc.camera calculateCameraAnimationWithFrame:animFrame] || worldMoved || (animFrame == 0)) && [self shouldRenderFrame]) {
                printf("Rendering Frame: %d/%d (%.1f%%), %d atoms, %d scene lights...", animFrame, totalFrames, (float)animFrame / (float)totalFrames * 100, [world numModelData], [world numIntrinsicLights]);
                [world logModelData];
                [r loadModelDataFromWorld:world];
                [r renderImage];
            }
            [r saveImage];
            [m addFrameToMovieFromBuffer:r.pixelBuffer];
            animFrame++;
        }
    }
    
    [m finishMovie];
}


- (void)renderMovie {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        [self renderLoop];
    });
    while (renderFrame < totalFrames) {
        @autoreleasepool {
            if ([renderCache count] > 0) {
                id newFrame = [renderCache objectAtIndex:0];
                if ([newFrame isKindOfClass:[NSNumber class]]) {
                    //No rendering required
                    printf("Not Rendering Frame: %d/%d (%.1f%%)\n", renderFrame, totalFrames, (float)renderFrame / (float)totalFrames * 100);
                } else {
                    printf("Rendering Frame: %d/%d (%.1f%%), %d atoms, %d scene lights...", renderFrame, totalFrames, (float)renderFrame / (float)totalFrames * 100, [(modelObjectCache *)newFrame numModelData], [(modelObjectCache *)newFrame numIntrinsicLights]);
                    modelObjectCache *frameToRender = newFrame;
                    [r loadDataFromCache:frameToRender];
                    [r renderImage];
                    [r saveImage];
                }
                
                [m addFrameToMovieFromBuffer:r.pixelBuffer];
                renderFrame++;
                [renderCache removeObjectAtIndex:0];
                
            }
        }
        [NSThread sleepForTimeInterval:0.1];
    }
    
    [m finishMovie];
}

- (void)renderLoop {
    while (animFrame < totalFrames) {
        @autoreleasepool {
            if ([renderCache count] < 10) {
                [self processFrame];
                animFrame++;
            } else {
                [NSThread sleepForTimeInterval:1.0];
            }
        }
    }
}


- (BOOL)shouldRenderFrame {
    //    if ((f == 0) || ((f > 1250) && (f % 10 == 0))) {
//    if ((animFrame<1) || (animFrame > 360)) {
//    if (animFrame % 2 == 0) {
        return YES;
//    }
    //    }
//    return NO;
}

- (void)processFrame {
    if (animFrame < totalFrames) {
        //        [self addFrameToMovie];
//        NSLog(@"Starting Frame: %d", frame);
//        printf("Starting Frame: %d...Updating scene...", animFrame);
        [sc sceneManagementForFrame:animFrame];
//        printf("Animating...");
        bool worldMoved = [world calculateAnimationWithFrame:animFrame];
        if (worldMoved || (animFrame == 0)) {
            [world applyTransformation];
            [world loadData];
            [sc.camera calculateCameraAnimationWithFrame:0];
        }
        if (([sc.camera calculateCameraAnimationWithFrame:animFrame] || worldMoved || (animFrame == 0)) && [self shouldRenderFrame]) {
//            [r renderImage];
            modelObjectCache *newCache = [[modelObjectCache alloc] initWithModelObject:world camera:sc.camera];
            [renderCache addObject:newCache];
        } else {
            [renderCache addObject:[NSNumber numberWithInt:0]];
        }
    }
}

@end
