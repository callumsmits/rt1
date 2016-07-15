//
//  rendererObject.h
//  rt1
//
//  Created by Stock Lab on 8/05/2014.
//  Copyright (c) 2014 a. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenCL/opencl.h>
#import "sceneController.h"

#define kWGSGPU 256
#define kWGSCPU 1
#define k2DWGSGPU 16
#define k2DWGSCPU 1
#define kTestRenderSize 64
#define kSamplerMaxWidth 8192
#define FLOAT_ERROR 0.0001
#define SOFT_SHADOW_SAMPLES 16

typedef struct _octree {
    Vector position;
    float radius;
    unsigned int hit;
    unsigned int miss;
    int leafNode;
    unsigned int leafStart;
    unsigned int leafMembers;
    int leafMembersSum;
    int a2;
} octree;

typedef struct _octreeImage {
    float x, y, z;
    float radius;
    unsigned int hit, miss, start, numMembers;
} octreeImage;

typedef struct _octreeData {
    Vector position;
    float radius;
    unsigned int id;
    unsigned int clipApplied;
    unsigned int a1;
} octreeData;

@class modelObjectCache;
@class modelObject;

@interface rendererObject : NSObject {
    unsigned char *pixelsOut;
    float *rawPixels;
    int numPixels, startPixel;
    NSSize renderSize;
    modelObjectCache *camera;
    modelObject *world;
    bool runningOnGPU;
    bool available;
    cl_int  sceneNumLights;
    dispatch_semaphore_t entropySemaphore;
}

@property (nonatomic) int numPixels;
@property (nonatomic) int startPixel;
@property (nonatomic) NSSize renderSize;
@property (nonatomic, strong) modelObjectCache *camera;
@property (nonatomic, strong) modelObject *world;
@property (nonatomic) bool runningOnGPU;
@property (nonatomic) bool available;
@property (nonatomic) cl_int sceneNumLights;
@property (nonatomic, strong) dispatch_semaphore_t entropySemaphore;

- (void)setupDeviceCPU;
- (void)setupDeviceGPU;
- (bool)setupDevice:(cl_device_id)device;
- (void)generateEntropy;
- (void)printDeviceName;
- (void)loadModelDataFromWorld:(modelObject *)world;
- (void)loadOctree:(octree *)treeIn treeSize:(unsigned int)tSize treeLookupData:(unsigned int *)lookupDataIn lookupSize:(unsigned int)lSize;
- (void)loadOctreeImage:(octreeImage *)treeIn treeSize:(unsigned int)tSize dataImage:(octreeData *)data dataSize:(unsigned int)dSize;
- (void)loadLightDataFromArray:(LightSourceDef *)lightArray withAmbient:(RGBColour)ambient numLights:(int)numLights;
- (double)testRender;
- (BOOL)renderImage;
- (BOOL)splitRender;
- (BOOL)processImageColoursWithNumAliases:(int)aliases;
- (BOOL)sumImage1:(cl_mem)i1 andImage2:(cl_mem)i2 andStoreIn:(cl_mem)outImage width:(cl_int)w executionLimit:(cl_int)max global:(size_t *)g local:(size_t *)l;
- (void)saveImage;
- (void)releaseData;
- (unsigned char *)pixelBuffer;
- (float *)rawPixelBuffer;

@end
