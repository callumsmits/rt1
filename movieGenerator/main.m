//
//  main.m
//  movieGenerator
//
//  Created by Callum Smits on 19/09/2014.
//  Copyright (c) 2014 a. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "movie.h"
#import "globalSettings.h"

#define kMaxSequentialGPUFails 5
#define kFramesBeforeRetryingGPU 50

int launchRenderer(NSString *launchPath, NSString *frameName, bool GPU) {
    NSString *gpuString;
    if (GPU) {
        gpuString = @"1";
    } else {
        gpuString = @"0";
    }
    NSArray *arguments = [NSArray arrayWithObjects:gpuString, frameName, nil];
    NSTask *renderer = [NSTask launchedTaskWithLaunchPath:launchPath arguments:arguments];
    [renderer waitUntilExit];
    return [renderer terminationStatus];

}

int main(int argc, const char * argv[])
{

    @autoreleasepool {
        
        NSSize frameSize;
        frameSize.width = kImageWidth;
        frameSize.height = kImageHeight;
        movie *m = [[movie alloc] init];
        NSString *outputBase = @kRenderOutputRoot;
        [m setupVideoWithPath:[outputBase stringByAppendingString:@kMovieOutputName] withSize:frameSize];
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        int pixelsOutSize = sizeof(char) * 4 * frameSize.width * frameSize.height;
        unsigned char *pixelsOut = (unsigned char *)malloc(pixelsOutSize);
        bool useGPU = kMovieGeneratorUseGPU;
        int gpuMisses = 0;
        int cpuRenders = 0;
        for (int animFrame = 0; animFrame < kNumFramesToRender; animFrame++) {
            @autoreleasepool {
                printf("Rendering Frame: %d/%d (%.1f%%) ", animFrame, kNumFramesToRender, 100.0 * (float)animFrame/(float)kNumFramesToRender);
                NSString *frameName = [NSString stringWithFormat:[outputBase stringByAppendingString:@"animationData/frameData_%06d.dat"], animFrame];
                NSString *appParentDirectory = [[NSBundle mainBundle] bundlePath];
                NSString *launchPath = [appParentDirectory stringByAppendingString:@"/renderFrame"];
                if ([fileManager fileExistsAtPath:frameName]) {
                    if (useGPU) {
                        printf("- trying GPU... ");
                        if (launchRenderer(launchPath, frameName, YES) > 0) {
                            printf(" trying CPU...");
                            if (launchRenderer(launchPath, frameName, NO) == 0) {
                            } else {
                                printf("Even the cpu didn't work...\n");
                            }
                            gpuMisses++;
                            if (gpuMisses > kMaxSequentialGPUFails) {
                                useGPU = NO;
                                cpuRenders = kFramesBeforeRetryingGPU;
                                printf("The GPU is having issues - giving it a rest...");
                            }
                        } else {
                            gpuMisses = 0;
                        }
                    } else {
                        printf(" trying CPU...");
                        if (launchRenderer(launchPath, frameName, NO) == 0) {
                        } else {
                            printf("Even the cpu didn't work...\n");
                        }
                        cpuRenders--;
                        if (cpuRenders == 0) {
                            useGPU = kMovieGeneratorUseGPU;
                            gpuMisses = 0;
                        }
                    }
                    
                    NSString *frameImageName = [outputBase stringByAppendingString:@"output.dat"];
                    NSData *imageData = [NSData dataWithContentsOfFile:frameImageName];
                    [imageData getBytes:pixelsOut length:pixelsOutSize];
                    [m addFrameToMovieFromBuffer:pixelsOut];
                } else {
                    [m addFrameToMovieFromBuffer:pixelsOut];
                }
            }
        }
        
        [m finishMovie];
        free(pixelsOut);
    }
    return 0;
}

