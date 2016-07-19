//
//  main.m
//  rt1
//
//  Created by Stock Lab on 8/05/2014.
//  Copyright (c) 2014 a. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "sceneController.h"
#import "movieController.h"
#import "globalSettings.h"
#import "modelObjectCache.h"

int main(int argc, const char * argv[])
{

    @autoreleasepool {
        sceneController *sc = [[sceneController alloc] init];
        [sc initScene];
        if (kMonolithic) {
            movieController *mc = [[movieController alloc] init];
            [mc setupMovieControllerWithScene:sc.world sceneController:sc totalNumFrames:kNumFramesToRender frameSize:sc.imageSize];
            if (kMonolithicMultithreadedRender) {
                [mc renderMovie];
            } else {
                [mc renderMovieST];
            }
        } else {
            modelObject *world = sc.world;
            NSString *outputBase = @kRenderOutputRoot;
            int animFrame;
            while (animFrame < kNumFramesToRender) {
                @autoreleasepool {
                    [sc sceneManagementForFrame:animFrame];
                    printf("Frame: %d/%d (%.1f%%), ", animFrame, kNumFramesToRender, (float)animFrame / (float)kNumFramesToRender * 100);
                    bool worldMoved = [world calculateAnimationWithFrame:animFrame];
                    if (worldMoved || (animFrame == 0)) {
                        [world applyTransformation];
                        [world loadData];
                        //                    [world logModelData];
                    }
                    if (([sc.camera calculateCameraAnimationWithFrame:animFrame] || worldMoved || (animFrame == 0))) {// && [self shouldRenderFrame]) {
                        printf("%d atoms, %d scene lights...", [world numModelData], [world numIntrinsicLights]);
                        modelObjectCache *newCache = [[modelObjectCache alloc] initNoOctreeWithModelObject:world camera:sc.camera sceneController:sc];
                        NSString *fileName = [NSString stringWithFormat:[outputBase stringByAppendingString:@"animationData/frameData_%06d.dat"], animFrame];
                        [newCache writeToFile:fileName];
                        printf("saved\n");
                    }
                    animFrame++;
                }
            }
        }

    }
    return 0;
}

