//
//  rendererObject.m
//  rt1
//
//  Created by Stock Lab on 8/05/2014.
//  Copyright (c) 2014 a. All rights reserved.
//

#import "rendererObject.h"
#include <sys/stat.h>
#include <AppKit/AppKit.h>
#include "calculateGaussianParameters.h"
#include "rngForRenderers.h"
#include "vector_ops.h"
#include "prefixSumScan.h"
#import "modelObjectCache.h"
#import "modelObject.h"

#define NO_INTERSECTION MAXFLOAT

static char *
load_program_source(const char *filename)
{
    struct stat statbuf;
    FILE        *fh;
    char        *source;
    
    fh = fopen(filename, "r");
    if (fh == 0)
    return 0;
    
    stat(filename, &statbuf);
    source = (char *) malloc(statbuf.st_size + 1);
    fread(source, statbuf.st_size, 1, fh);
    source[statbuf.st_size] = '\0';
    
    return source;
}

@interface rendererObject () {
    BOOL configured;
    NSString *deviceName;
    cl_device_id     device_id[2];
    cl_context       context;
    cl_kernel        kernel, generateRay, intersectRay, detectIntersectingRays, generateLightingRays, rayDataLightingIntersect, selectIntersectionsFromRays;
    cl_kernel        generateImage, convertToARGB_32Bit, countIntrinsicLightingRays, generateIntrinsicLightingRays, sumImages, copyBuffer;
    cl_kernel        blurVertical, blurHorizontal, generateImageIntrinsicObjects, generateImageHaze, hdrScaleRGBA, rayDataLightingIntersectImage;
    cl_kernel        generateImageIntrinsicCrudeLight, generateImageIntrinsicRayLight, convertLinearColoursToImage, generateImageIntrinsicRayLightCombinedkernel;
    cl_kernel        screenIntrinsicLights, zeroBuffer;
    cl_command_queue queue;
    cl_program       program;
    cl_mem			 cl_pixelsOut, cl_atomDataIn, cl_bvhIn, cl_bvhLookUpDataIn, cl_lightsIn, cl_intrinsicLightsIn, cl_tree, cl_treeLookup;
    cl_mem           cl_rays, cl_rayCull, cl_tValues, cl_points, cl_normals, cl_object_ids;
    cl_mem           cl_treeImage, cl_treeData, cl_entropyPool, cl_intersection, cl_intersectionScan, cl_sum;
    cl_mem           cl_intersectionPoints, cl_intersectionNormals, cl_intersectionIndex, cl_intersectionObjectIds, cl_intersectionTValues;
    cl_mem           cl_intersectionRays, cl_sceneLightRays, cl_sceneLightRayTValues, cl_Image, cl_intrinsicObjectImage, cl_intrinsicLightImage;
    cl_mem           cl_intrinsicIntersectionLightBuffer, cl_intrinsicRaysNeeded, cl_intrinsicRayIndex, cl_intrinsicSum;
    cl_mem           cl_intrinsicLightRays, cl_intrinsicLightRayTValuesImage, cl_mask, cl_blurOut1, cl_blurOut2, cl_blurOut, cl_summedImage;
    size_t  pixelsOutSize, atomDataSize, bvhInSize, bvhLookupDataInSize, lightsInSize, intrinsicLightsInSize, treeSize, treeLookupSize, rawPixelsOutSize;
    cl_float4   cl_ambientLight;
    cl_ulong  worldNumModelData;
    cl_int  numIntrinsicLights;
    cl_uint *entropyPool;
    int maskSize;
    octree *originalTree;
    prefixSumScan *scan;
    float *originalIntrinsicLightData;
}

@property (nonatomic, strong) NSString *deviceName;
@property (nonatomic, strong) prefixSumScan *scan;

- (BOOL)setupDeviceIsGPU:(bool) gpu;

@end

@implementation rendererObject

@synthesize numPixels, startPixel, camera, renderSize;
@synthesize runningOnGPU, deviceName, available;
@synthesize scan, entropySemaphore;
@synthesize  sceneNumLights, world;

- (unsigned char *)pixelBuffer {
    return pixelsOut;
}

- (float *)rawPixelBuffer {
    return rawPixels;
}

- (void)setupDeviceCPU {
    if (configured) {
        return;
    }
    configured = [self setupDeviceIsGPU:false];
}

- (void)setupDeviceGPU {
    if (configured) {
        return;
    }
    configured = [self setupDeviceIsGPU:true];
}

- (BOOL)setupDeviceIsGPU:(bool) gpu {
    pixelsOut = nil;
    cl_pixelsOut = nil;
    cl_atomDataIn = nil;
    cl_bvhIn = nil;
    cl_bvhLookUpDataIn = nil;
    cl_lightsIn = nil;
    cl_intrinsicLightsIn = nil;
    int err;
    runningOnGPU = gpu;
    
    err = clGetDeviceIDs(NULL, gpu ? CL_DEVICE_TYPE_GPU : CL_DEVICE_TYPE_CPU, 1, device_id, NULL);
    if (err != CL_SUCCESS)
    {
        printf("Error: Failed to create a device group!\n");
        return false;
    }
    
    return [self setupDevice:device_id[0]];
}

- (void)printDeviceName {
    fprintf(stdout, "%s", [deviceName cStringUsingEncoding:NSUTF8StringEncoding]);
}

- (bool)setupDevice:(cl_device_id)device {
    pixelsOut = nil;
    rawPixels = nil;
    cl_pixelsOut = nil;
    cl_atomDataIn = nil;
    cl_bvhIn = nil;
    cl_bvhLookUpDataIn = nil;
    cl_lightsIn = nil;
    cl_intrinsicLightsIn = nil;
    originalIntrinsicLightData = nil;
    int err;
    
    char name[128];
    clGetDeviceInfo(device, CL_DEVICE_NAME, 128, name, NULL);
//    fprintf(stdout, "%s\n", name);
    unsigned long memSize, gMemSize;
    size_t dimension[3], imageWidth, imageHeight;
    clGetDeviceInfo(device, CL_DEVICE_LOCAL_MEM_SIZE, sizeof(memSize), &memSize, NULL);
//    fprintf(stdout, "Local memory available: %ld\n", memSize);
    clGetDeviceInfo(device, CL_DEVICE_GLOBAL_MEM_SIZE, sizeof(gMemSize), &gMemSize, NULL);
//    fprintf(stdout, "Global memory available: %ld\n", gMemSize);
    self.deviceName = [NSString stringWithFormat:@"%s", name];
    clGetDeviceInfo(device, CL_DEVICE_MAX_WORK_ITEM_SIZES, sizeof(dimension), &dimension, NULL);
    clGetDeviceInfo(device, CL_DEVICE_IMAGE2D_MAX_WIDTH, sizeof(imageWidth), &imageWidth, NULL);
    clGetDeviceInfo(device, CL_DEVICE_IMAGE2D_MAX_HEIGHT, sizeof(imageHeight), &imageHeight, NULL);
//    NSLog(@"%s: %ld b local, %ld b global memory, %ld x %ld image max %ld %ld %ld", name, memSize, gMemSize, imageWidth, imageHeight, dimension[0], dimension[1], dimension[2]);
    
    // Create a compute context
    //
    context = clCreateContext(0, 1, &device, NULL, NULL, &err);
    if (!context)
    {
        printf("Error: Failed to create a compute context!\n");
        return false;
    }
    
    // Create a command queue
    //
    queue = clCreateCommandQueue(context, device, CL_QUEUE_PROFILING_ENABLE, &err);
    if (!queue)
    {
        printf("Error: Failed to create a command queue!\n");
        return false;
    }
    
    int wgs;
    wgs = runningOnGPU ? kWGSGPU : kWGSCPU;
    self.scan = [[prefixSumScan alloc] init];
    [scan initPreScan:device queue:queue context:context wgs:wgs];
    
    // Load the compute program from disk into a cstring buffer
    //
    char *source;
//    if (runningOnGPU) {
//        source = load_program_source("/Users/stocklab/Documents/Callum/rt1NG/rt1/rt_splitKernel.cl");
    NSString *clRootPath = @kRenderCLKernelsPath;
    source = load_program_source([[clRootPath stringByAppendingString:@"rt_splitKernel.cl"] cStringUsingEncoding:NSUTF8StringEncoding]);
//    } else {
//        source = load_program_source("/Users/stocklab/Documents/Callum/rt1NG/rt1/rt_kernel.cl");
//        source = load_program_source("/Users/stocklab/Documents/Callum/rt1NG/rt1/rt_splitKernel.cl");
//    }
    
    if(!source)
    {
        printf("Error: Failed to load compute program from file!\n");
        return false;
    }
    
    // Create the compute program from the source buffer
    //
    program = clCreateProgramWithSource(context, 1, (const char **) & source, NULL, &err);
    if (!program || err != CL_SUCCESS)
    {
        printf("Error: Failed to create compute program!\n");
        return false;
    }
    
    // Build the program executable
    //
    err = clBuildProgram(program, 0, NULL, NULL, NULL, NULL);
    if (err != CL_SUCCESS)
    {
        size_t len;
        char buffer[8192];
        
        printf("Error: Failed to build program executable!\n");
        clGetProgramBuildInfo(program, device, CL_PROGRAM_BUILD_LOG, sizeof(buffer), buffer, &len);
        printf("%s\n", buffer);
        return false;
    }
    
    // Create the compute kernel from within the program
    //
    if (runningOnGPU) {
        generateRay = clCreateKernel(program, "rayGenerate", &err);
        intersectRay = clCreateKernel(program, "rayDataIntersect", &err);
        detectIntersectingRays = clCreateKernel(program, "detectIntersectingRays", &err);
        generateLightingRays = clCreateKernel(program, "generateLightingRays", &err);
        rayDataLightingIntersect = clCreateKernel(program, "rayDataLightingIntersect", &err);
        selectIntersectionsFromRays = clCreateKernel(program, "selectIntersectionsFromRays", &err);
        generateImage = clCreateKernel(program, "generateImage", &err);
        convertToARGB_32Bit = clCreateKernel(program, "convertToARGB_32Bit", &err);
        countIntrinsicLightingRays = clCreateKernel(program, "countIntrinsicLightingRays", &err);
        generateIntrinsicLightingRays = clCreateKernel(program, "generateIntrinsicLightingRays", &err);
        generateImageIntrinsicRayLight = clCreateKernel(program, "generateImageIntrinsicRayLight", &err);
        sumImages = clCreateKernel(program, "sumImages", &err);
        blurHorizontal = clCreateKernel(program, "gaussianRGBAPassHoriz", &err);
        blurVertical = clCreateKernel(program, "gaussianRGBAPassVert", &err);
        generateImageIntrinsicObjects = clCreateKernel(program, "generateImageIntrinsicObjects", &err);
        generateImageHaze = clCreateKernel(program, "generateImageHaze", &err);
        hdrScaleRGBA = clCreateKernel(program, "hdrScaleRGBA", &err);
        rayDataLightingIntersectImage = clCreateKernel(program, "rayDataLightingIntersectImage", &err);
        generateImageIntrinsicCrudeLight = clCreateKernel(program, "generateImageIntrinsicCrudeLight", &err);
        convertLinearColoursToImage = clCreateKernel(program, "convertLinearColoursToImage", &err);
        generateImageIntrinsicRayLightCombinedkernel = clCreateKernel(program, "generateImageIntrinsicRayLightCombinedkernel", &err);
        copyBuffer = clCreateKernel(program, "copyBuffer", &err);
        screenIntrinsicLights = clCreateKernel(program, "screenIntrinsicLights", &err);
        zeroBuffer = clCreateKernel(program, "zeroBuffer", &err);
    } else {
        generateRay = clCreateKernel(program, "rayGenerate", &err);
        intersectRay = clCreateKernel(program, "rayDataIntersect", &err);
        detectIntersectingRays = clCreateKernel(program, "detectIntersectingRaysAtomic", &err);
        generateLightingRays = clCreateKernel(program, "generateLightingRays", &err);
        rayDataLightingIntersect = clCreateKernel(program, "rayDataLightingIntersect", &err);
        selectIntersectionsFromRays = clCreateKernel(program, "selectIntersectionsFromRays", &err);
        generateImage = clCreateKernel(program, "generateImage", &err);
        convertToARGB_32Bit = clCreateKernel(program, "convertToARGB_32Bit", &err);
        countIntrinsicLightingRays = clCreateKernel(program, "countIntrinsicLightingRaysAtomic", &err);
        generateIntrinsicLightingRays = clCreateKernel(program, "generateIntrinsicLightingRays", &err);
        generateImageIntrinsicRayLight = clCreateKernel(program, "generateImageIntrinsicRayLight", &err);
        sumImages = clCreateKernel(program, "sumImages", &err);
        blurHorizontal = clCreateKernel(program, "gaussianRGBAPassHoriz", &err);
        blurVertical = clCreateKernel(program, "gaussianRGBAPassVert", &err);
        generateImageIntrinsicObjects = clCreateKernel(program, "generateImageIntrinsicObjects", &err);
        generateImageHaze = clCreateKernel(program, "generateImageHaze", &err);
        hdrScaleRGBA = clCreateKernel(program, "hdrScaleRGBA", &err);
        rayDataLightingIntersectImage = clCreateKernel(program, "rayDataLightingIntersectImage", &err);
        generateImageIntrinsicCrudeLight = clCreateKernel(program, "generateImageIntrinsicCrudeLight", &err);
        convertLinearColoursToImage = clCreateKernel(program, "convertLinearColoursToImage", &err);
        generateImageIntrinsicRayLightCombinedkernel = clCreateKernel(program, "generateImageIntrinsicRayLightCombinedkernel", &err);
        copyBuffer = clCreateKernel(program, "copyBuffer", &err);
        screenIntrinsicLights = clCreateKernel(program, "screenIntrinsicLights", &err);
        zeroBuffer = clCreateKernel(program, "zeroBuffer", &err);
        //        kernel = clCreateKernel(program, "raytrace", &err);
    }
    if (err != CL_SUCCESS)
    {
        printf("Error: Failed to create compute kernels!\n");
        return false;
    }
    
    pixelsOutSize = sizeof(cl_uchar4) * renderSize.width * renderSize.height;
    pixelsOut = malloc(pixelsOutSize);
    //cl_pixelsOut = gcl_malloc(pixelsOutSize, NULL, CL_MEM_WRITE_ONLY);
    cl_pixelsOut = clCreateBuffer(context, CL_MEM_READ_WRITE, pixelsOutSize, NULL, NULL);
    if (!cl_pixelsOut)
    {
        printf("Error: Failed to allocate destination array!\n");
        return false;
    }
    
    rawPixelsOutSize = sizeof(cl_float4) * renderSize.width * renderSize.height;
    rawPixels = malloc(rawPixelsOutSize);
    
//    int wgs;
//    wgs = runningOnGPU ? kWGSGPU : kWGSCPU;
//    int numRays = wgs * ceil((float)(renderSize.width * renderSize.height) / (float)wgs);
    int numRays = renderSize.width * renderSize.height;
    size_t raySize = sizeof(cl_float8) * numRays;

    cl_image_format fmt;
    fmt.image_channel_order = CL_RGBA;
    fmt.image_channel_data_type = CL_FLOAT;
    cl_image_desc desc;
    desc.image_type = CL_MEM_OBJECT_IMAGE2D;
    desc.image_width = kSamplerMaxWidth;
    desc.image_height = (numRays * 2) / kSamplerMaxWidth + 1;
    if (desc.image_height < 2) {
        desc.image_height = 2;
    }
    desc.image_depth = 1;
    desc.image_row_pitch = 0;
    desc.image_slice_pitch = 0;
    desc.num_mip_levels = 0;
    desc.num_samples = 0;
    desc.buffer = NULL;
    
    cl_rays = clCreateImage(context, CL_MEM_READ_WRITE, &fmt, &desc, NULL, &err);
//    cl_rays = clCreateBuffer(context, CL_MEM_READ_WRITE, raySize, NULL, NULL);
    if (!cl_rays)
    {
        printf("Error: Failed to allocate ray array!\n");
        return false;
    }
//    cl_rayCull = clCreateBuffer(context, CL_MEM_READ_WRITE, raySize, NULL, NULL);
//    if (!cl_rayCull)
//    {
//        printf("Error: Failed to allocate trimmed ray array!\n");
//        return false;
//    }
    desc.image_height = (numRays) / kSamplerMaxWidth + 1;
    if (desc.image_height < 2) {
        desc.image_height = 2;
    }
    cl_points = clCreateImage(context, CL_MEM_READ_WRITE, &fmt, &desc, NULL, &err);
//    cl_points = clCreateBuffer(context, CL_MEM_READ_WRITE, sizeof(cl_float4) * numRays, NULL, NULL);
    if (!cl_points)
    {
        printf("Error: Failed to allocate ray points array!\n");
        return false;
    }
    cl_normals = clCreateImage(context, CL_MEM_READ_WRITE, &fmt, &desc, NULL, &err);
//    cl_normals = clCreateBuffer(context, CL_MEM_READ_WRITE, sizeof(cl_float4) * numRays, NULL, NULL);
    if (!cl_normals)
    {
        printf("Error: Failed to allocate ray normals array!\n");
        return false;
    }
    fmt.image_channel_order = CL_RGBA;
    cl_tValues = clCreateImage(context, CL_MEM_READ_WRITE, &fmt, &desc, NULL, &err);
//    cl_tValues = clCreateBuffer(context, CL_MEM_READ_WRITE, sizeof(float) * numRays, NULL, NULL);
    if (!cl_tValues)
    {
        printf("Error: Failed to allocate ray tValue array!\n");
        return false;
    }
    cl_float fillFloat = MAXFLOAT;
    size_t origin[3] = {0,0,0};
    size_t region[3]; region[0] = kSamplerMaxWidth; region[1] = desc.image_height; region[2] = 1;
    clEnqueueFillImage(queue, cl_tValues, &fillFloat, origin, region, 0, NULL, NULL);
//    clEnqueueFillBuffer(queue, cl_tValues, &fillFloat, sizeof(fillFloat), 0, sizeof(float) * numRays, 0, NULL, NULL);

    fmt.image_channel_data_type = CL_UNSIGNED_INT32;
    cl_object_ids = clCreateImage(context, CL_MEM_READ_WRITE, &fmt, &desc, NULL, &err);
//    cl_object_ids = clCreateBuffer(context, CL_MEM_READ_WRITE, sizeof(unsigned int) * numRays, NULL, NULL);
    if (!cl_object_ids)
    {
        printf("Error: Failed to allocate ray object ids array!\n");
        return false;
    }
    
    entropyPool = (cl_uint *)malloc(sizeof(cl_uint) * renderSize.width * renderSize.height);

    cl_entropyPool = clCreateBuffer(context, CL_MEM_READ_ONLY, sizeof(cl_uint) * renderSize.width * renderSize.height, NULL, 0);
    if (!cl_entropyPool) {
        NSLog(@"Error: Failed to allocate entropy pool");
        return false;
    }

    cl_intersection = clCreateBuffer(context, CL_MEM_READ_WRITE, sizeof(cl_uint) * renderSize.width * renderSize.height, NULL, NULL);
    cl_intersectionScan = clCreateBuffer(context, CL_MEM_READ_WRITE, sizeof(cl_uint) * renderSize.width * renderSize.height, NULL, NULL);
    cl_sum = clCreateBuffer(context, CL_MEM_READ_WRITE, sizeof(cl_uint), NULL, NULL);

    //Just allocate buffers large enough to deal with the full image!
    cl_intersectionPoints = clCreateBuffer(context, CL_MEM_READ_WRITE, sizeof(cl_float4) * renderSize.width * renderSize.height, NULL, NULL);
    cl_intersectionNormals = clCreateBuffer(context, CL_MEM_READ_WRITE, sizeof(cl_float4) * renderSize.width * renderSize.height, NULL, NULL);
    cl_intersectionIndex = clCreateBuffer(context, CL_MEM_READ_WRITE, sizeof(cl_uint) * renderSize.width * renderSize.height, NULL, NULL);
    cl_intersectionObjectIds = clCreateBuffer(context, CL_MEM_READ_WRITE, sizeof(cl_uint) * renderSize.width * renderSize.height, NULL, NULL);
    cl_intersectionTValues = clCreateBuffer(context, CL_MEM_READ_WRITE, sizeof(cl_float) * renderSize.width * renderSize.height, NULL, NULL);
    cl_intersectionRays = clCreateBuffer(context, CL_MEM_READ_WRITE, sizeof(cl_float8) * renderSize.width * renderSize.height, NULL, NULL);
    if (!cl_intersectionPoints) {
        NSLog(@"Error: Failed to allocate intersection points");
        return false;
    }
    if (!cl_intersectionNormals) {
        NSLog(@"Error: Failed to allocate intersection normals");
        return false;
    }
    if (!cl_intersectionIndex) {
        NSLog(@"Error: Failed to allocate intersection index");
        return false;
    }
    if (!cl_intersectionObjectIds) {
        NSLog(@"Error: Failed to allocate intersection object ids");
        return false;
    }
    if (!cl_intersectionTValues) {
        NSLog(@"Error: Failed to allocate intersection t values");
        return false;
    }
    if (!cl_intersectionRays) {
        NSLog(@"Error: Failed to allocate intersection rays");
        return false;
    }

    cl_sceneLightRays = clCreateBuffer(context, CL_MEM_READ_WRITE, sizeof(cl_float8) * sceneNumLights * renderSize.width * renderSize.height, NULL, NULL);
    if (!cl_sceneLightRays) {
        NSLog(@"Error: Failed to create scene lighting array");
        return false;
    }

    cl_sceneLightRayTValues = clCreateBuffer(context, CL_MEM_READ_WRITE, sizeof(float) * sceneNumLights * renderSize.width * renderSize.height, NULL, NULL);
    if (!cl_sceneLightRayTValues) {
        NSLog(@"Error: Failed to create lighting t-values array");
        return false;
    }

    fmt.image_channel_order = CL_RGBA;
    fmt.image_channel_data_type = CL_FLOAT;
    desc.image_type = CL_MEM_OBJECT_IMAGE2D;
    desc.image_width = renderSize.width;
    desc.image_height = renderSize.height;
    desc.image_depth = 1;
    desc.image_row_pitch = 0;
    desc.image_slice_pitch = 0;
    desc.num_mip_levels = 0;
    desc.num_samples = 0;
    desc.buffer = NULL;
    
    cl_Image = clCreateImage(context, CL_MEM_READ_WRITE, &fmt, &desc, NULL, &err);
    cl_intrinsicObjectImage = clCreateImage(context, CL_MEM_READ_WRITE, &fmt, &desc, NULL, &err);
    cl_intrinsicLightImage = clCreateImage(context, CL_MEM_READ_WRITE, &fmt, &desc, NULL, &err);
    if (!cl_Image) {
        NSLog(@"Error: Failed to create output image buffer");
    }
    if (!cl_intrinsicObjectImage) {
        NSLog(@"Error: Failed to create output image buffer");
    }
    if (!cl_intrinsicLightImage) {
        NSLog(@"Error: Failed to create output image buffer");
    }

    cl_intrinsicIntersectionLightBuffer = clCreateBuffer(context, CL_MEM_READ_WRITE, sizeof(cl_float4) * renderSize.width * renderSize.height, NULL, NULL);

    cl_intrinsicRaysNeeded = clCreateBuffer(context, CL_MEM_READ_WRITE, sizeof(cl_uint) * renderSize.width * renderSize.height, NULL, NULL);
    cl_intrinsicRayIndex = clCreateBuffer(context, CL_MEM_READ_WRITE, sizeof(cl_uint) * renderSize.width * renderSize.height, NULL, NULL);
    if ((!cl_intrinsicRaysNeeded) || (!cl_intrinsicRayIndex)) {
        NSLog(@"Error: Failed to allocated intrinsic ray needed arrays");
        return false;
    }
    cl_intrinsicSum = clCreateBuffer(context, CL_MEM_READ_WRITE, sizeof(cl_uint), NULL, NULL);

    //    cl_image_format fmt;
    fmt.image_channel_order = CL_RGBA;
    fmt.image_channel_data_type = CL_FLOAT;
    //    cl_image_desc desc;
    desc.image_type = CL_MEM_OBJECT_IMAGE2D;
    desc.image_width = kSamplerMaxWidth;
    desc.image_height = (SOFT_SHADOW_SAMPLES * renderSize.width * renderSize.height * 2) / kSamplerMaxWidth + 1;
    if (desc.image_height < 2) {
        desc.image_height = 2;
    }
    desc.image_depth = 1;
    desc.image_row_pitch = 0;
    desc.image_slice_pitch = 0;
    desc.num_mip_levels = 0;
    desc.num_samples = 0;
    desc.buffer = NULL;
    
    cl_intrinsicLightRays = clCreateImage(context, CL_MEM_READ_WRITE, &fmt, &desc, NULL, &err);
    if (!cl_intrinsicLightRays) {
        NSLog(@"Error: Failed to allocate intrinsic light ray array");
        return false;
    }
    
    desc.image_height = (SOFT_SHADOW_SAMPLES * renderSize.width * renderSize.height) / kSamplerMaxWidth + 1;
    if (desc.image_height < 2) {
        desc.image_height = 2;
    }
    
    cl_intrinsicLightRayTValuesImage = clCreateImage(context, CL_MEM_READ_WRITE, &fmt, &desc, NULL, &err);;
    if (!cl_intrinsicLightRayTValuesImage) {
        NSLog(@"Error: Failed to create lighting tValues image");
        return false;
    }

    float * mask = createGaussianMask(4.0f, &maskSize);
    cl_mask = clCreateBuffer(context, CL_MEM_READ_ONLY, sizeof(cl_float) * (maskSize*2+1), NULL, &err);
    if (!cl_mask) {
        NSLog(@"Error: Failed to allocate blur mask");
        return false;
    }
    err = clEnqueueWriteBuffer(queue, cl_mask, true, 0, sizeof(cl_float) * (maskSize*2+1), mask, 0, NULL, NULL);
    if (err != CL_SUCCESS) {
        NSLog(@"Error: Failed to copy mask data to OpenCL\n");
    }
    free(mask);
    clFinish(queue);
    
    fmt.image_channel_order = CL_RGBA;
    fmt.image_channel_data_type = CL_FLOAT;
    desc.image_type = CL_MEM_OBJECT_IMAGE2D;
    desc.image_width = renderSize.width;
    desc.image_height = renderSize.height;
    desc.image_depth = 1;
    desc.image_row_pitch = 0;
    desc.image_slice_pitch = 0;
    desc.num_mip_levels = 0;
    desc.num_samples = 0;
    desc.buffer = NULL;
    
    cl_blurOut1 = clCreateImage(context, CL_MEM_READ_WRITE, &fmt, &desc, NULL, &err);
    if (!cl_blurOut1) {
        NSLog(@"Error: Failed to create summed image");
        return false;
    }
    cl_blurOut2 = clCreateImage(context, CL_MEM_READ_WRITE, &fmt, &desc, NULL, &err);
    if (!cl_blurOut2) {
        NSLog(@"Error: Failed to create summed image");
        return false;
    }
    cl_blurOut = clCreateImage(context, CL_MEM_READ_WRITE, &fmt, &desc, NULL, &err);
    if (!cl_blurOut) {
        NSLog(@"Error: Failed to create summed image");
        return false;
    }
    cl_summedImage = clCreateImage(context, CL_MEM_READ_WRITE, &fmt, &desc, NULL, &err);
    if (!cl_summedImage) {
        NSLog(@"Error: Failed to create summed image");
        return false;
    }

    self.available = YES;
    
    return true;
}

- (void)generateEntropy {
    for (int i = 0; i < renderSize.width * renderSize.height; i++) {
        entropyPool[i] = [[rngForRenderers sharedInstance] getRandomUInt];
    }

}

- (void)loadModelDataFromWorld:(modelObject *)world {
    int err;
    
    if (cl_atomDataIn) {
        clReleaseMemObject(cl_atomDataIn);
    }
    if (cl_intrinsicLightsIn) {
        clReleaseMemObject(cl_intrinsicLightsIn);
    }

    worldNumModelData = world.numModelData;
    atomDataSize = sizeof(cl_float) * NUM_ATOMDATA * world.numModelData;
    cl_atomDataIn = clCreateBuffer(context, CL_MEM_READ_ONLY, atomDataSize, NULL, NULL);
    if (!cl_atomDataIn) {
        NSLog(@"Error: Failed to create atom data array\n");
    }
    err = clEnqueueWriteBuffer(queue, cl_atomDataIn, true, 0, atomDataSize, world.transformedModelData, 0, NULL, NULL);
    if (err != CL_SUCCESS) {
        NSLog(@"Error: Failed to copy atom data to OpenCL\n");
    }
    clFinish(queue);
//    cl_image_format fmt;
//    fmt.image_channel_order = CL_RGBA;
//    fmt.image_channel_data_type = CL_FLOAT;
//    cl_image_desc desc;
//    desc.image_type = CL_MEM_OBJECT_IMAGE2D;
//    desc.image_width = kSamplerMaxWidth;
//    desc.image_height = NUM_ATOMDATA * world.numModelData / kSamplerMaxWidth + 1;
//    if (desc.image_height < 2) {
//        desc.image_height = 2;
//    }
//    desc.image_depth = 1;
//    desc.image_row_pitch = 0;
//    desc.image_slice_pitch = 0;
//    desc.num_mip_levels = 0;
//    desc.num_samples = 0;
//    desc.buffer = NULL;
    
//    float *modelData = (float *)malloc(sizeof(float));
//    memcpy(modelData, world.transformedModelData, atomDataSize);
    
//    cl_atomDataIn = clCreateImage(context, CL_MEM_READ_ONLY, &fmt, &desc, NULL, &err);
//    if (!cl_atomDataIn) {
//        NSLog(@"Error: Failed to create atom data array\n");
//    }
//    size_t origin[3] = {0,0,0};
//    size_t region[3]; region[0] = kSamplerMaxWidth; region[1] = desc.image_height; region[2] = 1;
//    err = clEnqueueWriteImage(queue, cl_atomDataIn, CL_TRUE, origin, region, 0, 0, (const void *)treeIn, 0, NULL, NULL);
//    if (err != CL_SUCCESS) {
//        NSLog(@"Error: Failed to copy octree image data to OpenCL");
//    }

    
    if (world.numIntrinsicLights > 0) {
        numIntrinsicLights = world.numIntrinsicLights;
        intrinsicLightsInSize = sizeof(cl_float) * NUM_INTRINSIC_LIGHT_DATA * world.numIntrinsicLights;
        originalIntrinsicLightData = malloc(intrinsicLightsInSize);
        memcpy(originalIntrinsicLightData, world.transformedIntrinsicLights, intrinsicLightsInSize);
        cl_intrinsicLightsIn = clCreateBuffer(context, CL_MEM_READ_ONLY, intrinsicLightsInSize, NULL, NULL);
        if (!cl_intrinsicLightsIn) {
            NSLog(@"Error: Failed to create intrinsic light data array");
        }
        err = clEnqueueWriteBuffer(queue, cl_intrinsicLightsIn, true, 0, intrinsicLightsInSize, world.transformedIntrinsicLights, 0, NULL, NULL);
        if (err != CL_SUCCESS) {
            NSLog(@"Error: Failed to copy intrinsic light data to OpenCL");
        }
        clFinish(queue);
    } else {
        numIntrinsicLights = 0;
        intrinsicLightsInSize = 0;
        cl_intrinsicLightsIn = nil;
    }
    
}

- (void)loadOctree:(octree *)treeIn treeSize:(unsigned int)tSize treeLookupData:(unsigned int *)lookupDataIn lookupSize:(unsigned int)lSize {
    int err;
    
    if (cl_tree) {
        clReleaseMemObject(cl_tree);
    }
    if (cl_treeLookup) {
        clReleaseMemObject(cl_treeLookup);
    }
    
    originalTree = treeIn;
    treeSize = sizeof(octree) * tSize;
    cl_tree = clCreateBuffer(context, CL_MEM_READ_ONLY, treeSize, NULL, NULL);
    if (!cl_tree) {
        NSLog(@"Error: Failed to create octree data array\n");
    }
    err = clEnqueueWriteBuffer(queue, cl_tree, true, 0, treeSize, treeIn, 0, NULL, NULL);
    if (err != CL_SUCCESS) {
        NSLog(@"Error: Failed to copy octree data to OpenCL\n");
    }
    clFinish(queue);
    
    treeLookupSize = sizeof(unsigned int) * lSize;
    cl_treeLookup = clCreateBuffer(context, CL_MEM_READ_ONLY, treeLookupSize, NULL, NULL);
    if (!cl_treeLookup) {
        NSLog(@"Error: Failed to create octree lookup data array\n");
    }
    err = clEnqueueWriteBuffer(queue, cl_treeLookup, true, 0, treeLookupSize, lookupDataIn, 0, NULL, NULL);
    if (err != CL_SUCCESS) {
        NSLog(@"Error: Failed to copy octree lookup data to OpenCL\n");
    }
    clFinish(queue);

}

- (void)loadOctreeImage:(octreeImage *)treeIn treeSize:(unsigned int)tSize dataImage:(octreeData *)data dataSize:(unsigned int)dSize {
    
    int err;
    if (cl_treeImage) {
        clReleaseMemObject(cl_treeImage);
    }
    if (cl_treeData) {
        clReleaseMemObject(cl_treeData);
    }
    cl_image_format fmt;
    fmt.image_channel_order = CL_RGBA;
    fmt.image_channel_data_type = CL_UNSIGNED_INT32;
    cl_image_desc desc;
    desc.image_type = CL_MEM_OBJECT_IMAGE2D;
    desc.image_width = kSamplerMaxWidth;
    desc.image_height = (tSize * 2) / kSamplerMaxWidth + 1;
    if (desc.image_height < 2) {
        desc.image_height = 2;
    }
    desc.image_depth = 1;
    desc.image_row_pitch = 0;
    desc.image_slice_pitch = 0;
    desc.num_mip_levels = 0;
    desc.num_samples = 0;
    desc.buffer = NULL;
    
//    cl_treeImage = clCreateImage2D(context, CL_MEM_COPY_HOST_PTR, &fmt, kSamplerMaxWidth, 8, 0, treeIn, &err);
//    cl_treeImage = clCreateImage(context, CL_MEM_COPY_HOST_PTR, &fmt, &desc, treeIn, &err);
    cl_treeImage = clCreateImage(context, CL_MEM_READ_ONLY, &fmt, &desc, NULL, &err);
    if (!cl_treeImage) {
        NSLog(@"Error: Failed to create octree image");
    }
    size_t origin[3] = {0,0,0};
    size_t region[3]; region[0] = kSamplerMaxWidth; region[1] = desc.image_height; region[2] = 1;
    err = clEnqueueWriteImage(queue, cl_treeImage, CL_TRUE, origin, region, 0, 0, (const void *)treeIn, 0, NULL, NULL);
    if (err != CL_SUCCESS) {
        NSLog(@"Error: Failed to copy octree image data to OpenCL");
    }
    
    desc.image_height = (dSize * 2) / kSamplerMaxWidth + 1;
    if (desc.image_height < 2) {
        desc.image_height = 2;
    }
    cl_treeData = clCreateImage(context, CL_MEM_READ_ONLY, &fmt, &desc, NULL, &err);
    if (!cl_treeData) {
        NSLog(@"Error: Failed to create octree data image");
    }
    region[1] = desc.image_height;
    err = clEnqueueWriteImage(queue, cl_treeData, CL_TRUE, origin, region, 0, 0, data, 0, NULL, NULL);
    if (err != CL_SUCCESS) {
        NSLog(@"Error: Failed to copy data image to OpenCL");
    }
}

- (void)loadLightDataFromArray:(LightSourceDef *)lightArray withAmbient:(RGBColour)ambient numLights:(int)numLights {
    sceneNumLights = numLights;
    
    cl_ambientLight.x = ambient.red;
    cl_ambientLight.y = ambient.green;
    cl_ambientLight.z = ambient.blue;
    
    float *lights = (float*)malloc(sizeof(cl_float8) * numLights);
    for (int i = 0; i < numLights; i++) {
        lights[i * 8 + X] = lightArray[i].position.x;
        lights[i * 8 + Y] = lightArray[i].position.y;
        lights[i * 8 + Z] = lightArray[i].position.z;
        lights[i * 8 + VDW] = lightArray[i].position.w;
        lights[i * 8 + 4] = lightArray[i].colour.red;
        lights[i * 8 + 5] = lightArray[i].colour.green;
        lights[i * 8 + 6] = lightArray[i].colour.blue;
    }
    
    if (cl_lightsIn) {
        clReleaseMemObject(cl_lightsIn);
    }
    cl_lightsIn = clCreateBuffer(context, CL_MEM_READ_ONLY, sizeof(cl_float8) * numLights, NULL, NULL);
    if (!cl_lightsIn) {
        NSLog(@"Error: Failed to create light data array\n");
    }
    int err;
    err = clEnqueueWriteBuffer(queue, cl_lightsIn, true, 0, sizeof(cl_float8) * numLights, lights, 0, NULL, NULL);
    if (err != CL_SUCCESS) {
        NSLog(@"Error: Failed to copy light data to OpenCL\n");
    }
    
    free(lights);

}

- (double)testRender {
    CGSize original;
    
    original = renderSize;
    
    renderSize.width = kTestRenderSize;
    renderSize.height = kTestRenderSize;
    
    cl_event event;
    int err;
    cl_float4 rayOrigin = camera.viewOriginRayStart;
    cl_float4 lookAtPoint = camera.clookAtPoint;
    cl_float4 upOrientation = camera.cUpOrientation;
    cl_int aaQuality = kaaQuality;
    cl_int width = renderSize.width;
    cl_int height = renderSize.height;
    cl_float cameraWidth = camera.viewWidth;
    cl_float cameraAperture = camera.aperture;
    cl_float cameraFocalLength = camera.focalLength;
    cl_float cameraLensLength = camera.lensLength;
    cl_int maxNumRays = renderSize.width * renderSize.height;
    err = clSetKernelArg(kernel,  0, sizeof(cl_mem), &cl_pixelsOut);
    err |= clSetKernelArg(kernel, 1, sizeof(startPixel), &startPixel);
    err |= clSetKernelArg(kernel, 2, sizeof(cl_float4), &rayOrigin);
    err |= clSetKernelArg(kernel, 3, sizeof(cl_float4), &lookAtPoint);
    err |= clSetKernelArg(kernel, 4, sizeof(cl_float4), &upOrientation);
    err |= clSetKernelArg(kernel, 5, sizeof(cl_int), &aaQuality);
    err |= clSetKernelArg(kernel, 6, sizeof(cl_int), &width);
    err |= clSetKernelArg(kernel, 7, sizeof(cl_int), &height);
    err |= clSetKernelArg(kernel, 8, sizeof(cl_float), &cameraWidth);
    err |= clSetKernelArg(kernel, 9, sizeof(cl_float), &cameraAperture);
    err |= clSetKernelArg(kernel, 10, sizeof(cl_float), &cameraFocalLength);
    err |= clSetKernelArg(kernel, 11, sizeof(cl_float), &cameraLensLength);
    err |= clSetKernelArg(kernel, 12, sizeof(cl_mem), &cl_atomDataIn);
    err |= clSetKernelArg(kernel, 13, sizeof(cl_ulong), &worldNumModelData);
//    err |= clSetKernelArg(kernel, 14, sizeof(cl_mem), &cl_bvhIn);
//    err |= clSetKernelArg(kernel, 15, sizeof(cl_mem), &cl_bvhLookUpDataIn);
    err |= clSetKernelArg(kernel, 14, sizeof(cl_mem), &cl_tree);
    err |= clSetKernelArg(kernel, 15, sizeof(cl_mem), &cl_treeLookup);
    err |= clSetKernelArg(kernel, 16, sizeof(cl_float4), &cl_ambientLight);
    err |= clSetKernelArg(kernel, 17, sizeof(cl_int), &sceneNumLights);
    err |= clSetKernelArg(kernel, 18, sizeof(cl_mem), &cl_lightsIn);
    err |= clSetKernelArg(kernel, 19, sizeof(cl_int), &numIntrinsicLights);
    err |= clSetKernelArg(kernel, 20, sizeof(cl_mem), &cl_intrinsicLightsIn);
    err |= clSetKernelArg(kernel, 21, sizeof(cl_int), &maxNumRays);
    
    if (err != CL_SUCCESS)
    {
        printf("Error: Failed to set kernel arguments!\n");
        return false;
    }
    
    size_t global[1], local[1];
    int wgs;
    wgs = runningOnGPU ? kWGSGPU : kWGSCPU;
    global[0] = wgs * ceil((float)numPixels / (float)wgs);
    local[0] = wgs;
    
    //Just in case
    clFinish(queue);
    
    err = clEnqueueNDRangeKernel(queue, kernel, 1, NULL, global, local, 0, NULL, &event);
    if (err)
    {
        printf("Error: Failed to execute kernel!\n");
        return false;
    }
    clWaitForEvents(1, &event);
    
    cl_ulong timeStart, timeEnd;
    double totalTime;
    
    clGetEventProfilingInfo(event, CL_PROFILING_COMMAND_START, sizeof(timeStart), &timeStart, NULL);
    clGetEventProfilingInfo(event, CL_PROFILING_COMMAND_END, sizeof(timeEnd), &timeEnd, NULL);
    totalTime = timeEnd - timeStart;
    
    clFinish(queue);
    renderSize = original;
    
    return totalTime;
}

- (BOOL)processIntrinsicLightNumber:(int)ilNum numIntersectingRays:(int)intersectingRays intersectionTValues:(cl_mem)tValues intersectionPoints:(cl_mem)points intersectionNormals:(cl_mem)normals intersectionRays:(cl_mem)rays intersectionObjects:(cl_mem)objects wgs:(uint)wgs currentImage:(cl_mem)image raysNeeded:(cl_mem)raysNeeded rayIndex:(cl_mem)rayIndex hostRayIndex:(unsigned int*)hostRayIndex sum:(cl_mem)cl_sum rayImage:(cl_mem)cl_intrinsicLightRays tValueImage:(cl_mem)cl_intrinsicLightRayTValuesImage {
    
    int err;
    uint width = renderSize.width;

    size_t rayIntersectionsSize[1], local[1];
    rayIntersectionsSize[0] = wgs * ceil((float)intersectingRays / (float)wgs);
    local[0] = wgs;

    uint intrinsicRays = 0;
    Vector ilpos, ilColour;
    ilpos.x = world.transformedIntrinsicLights[ilNum * NUM_INTRINSIC_LIGHT_DATA + XI];
    ilpos.y = world.transformedIntrinsicLights[ilNum * NUM_INTRINSIC_LIGHT_DATA + YI];
    ilpos.z = world.transformedIntrinsicLights[ilNum * NUM_INTRINSIC_LIGHT_DATA + ZI];
    ilpos.w = 1.0;
    ilColour.x = world.transformedIntrinsicLights[ilNum * NUM_INTRINSIC_LIGHT_DATA + RED];
    ilColour.y = world.transformedIntrinsicLights[ilNum * NUM_INTRINSIC_LIGHT_DATA + GREEN];
    ilColour.z = world.transformedIntrinsicLights[ilNum * NUM_INTRINSIC_LIGHT_DATA + BLUE];
    float ilVDW = world.transformedIntrinsicLights[ilNum * NUM_INTRINSIC_LIGHT_DATA + VDW];
    float ilCutoffDist = world.transformedIntrinsicLights[ilNum * NUM_INTRINSIC_LIGHT_DATA + CUTOFF];
    uint mode = world.transformedIntrinsicLights[ilNum * NUM_INTRINSIC_LIGHT_DATA + MODE];

    
    if (mode >=REAL_POINT_SOURCE) {
        
        /*err = clSetKernelArg(generateImageIntrinsicRayLightCombinedkernel, 0, sizeof(cl_mem), &outImage);
        err |= clSetKernelArg(generateImageIntrinsicRayLightCombinedkernel, 1, sizeof(cl_mem), &rays);
        err |= clSetKernelArg(generateImageIntrinsicRayLightCombinedkernel, 2, sizeof(cl_mem), &points);
        err |= clSetKernelArg(generateImageIntrinsicRayLightCombinedkernel, 3, sizeof(cl_mem), &normals);
        err |= clSetKernelArg(generateImageIntrinsicRayLightCombinedkernel, 4, sizeof(cl_mem), &objects);
        err |= clSetKernelArg(generateImageIntrinsicRayLightCombinedkernel, 5, sizeof(cl_mem), &inImage);
        err |= clSetKernelArg(generateImageIntrinsicRayLightCombinedkernel, 6, sizeof(cl_mem), &cl_atomDataIn);
        err |= clSetKernelArg(generateImageIntrinsicRayLightCombinedkernel, 7, sizeof(cl_float4), &ilpos);
        err |= clSetKernelArg(generateImageIntrinsicRayLightCombinedkernel, 8, sizeof(cl_float4), &ilColour);
        err |= clSetKernelArg(generateImageIntrinsicRayLightCombinedkernel, 9, sizeof(cl_float), &ilVDW);
        err |= clSetKernelArg(generateImageIntrinsicRayLightCombinedkernel, 10, sizeof(cl_float), &ilCutoffDist);
        err |= clSetKernelArg(generateImageIntrinsicRayLightCombinedkernel, 11, sizeof(cl_uint), &mode);
        err |= clSetKernelArg(generateImageIntrinsicRayLightCombinedkernel, 12, sizeof(cl_mem), &cl_treeImage);
        err |= clSetKernelArg(generateImageIntrinsicRayLightCombinedkernel, 13, sizeof(cl_mem), &cl_treeData);
        err |= clSetKernelArg(generateImageIntrinsicRayLightCombinedkernel, 14, sizeof(cl_int), &intersectingRays);
        
        if (err != CL_SUCCESS) {
            NSLog(@"Error: Failed to set kernel arguments for generate intrinsic image kernel");
            return false;
        }
        
        err = clEnqueueNDRangeKernel(queue, generateImageIntrinsicRayLightCombinedkernel, 1, NULL, rayIntersectionsSize, local, 0, NULL, NULL);
        clFinish(queue);
        
        if (err != CL_SUCCESS) {
            NSLog(@"Error: Failed to execute intrinsic image generation kernel");
            return false;
        }*/

        
        
//        uint fillInt = 0;
//        err = clEnqueueFillBuffer(queue, cl_intrinsicRaysNeeded, &fillInt, sizeof(fillInt), 0, sizeof(cl_uint) * intersectingRays, 0, NULL, NULL);
//        if (err != CL_SUCCESS) {
//            NSLog(@"Error filling intrinsic ray scan buffers");
//            return false;
//        }
        
        
        if (self.runningOnGPU) {
            err = clSetKernelArg(countIntrinsicLightingRays, 0, sizeof(cl_mem), &points);
            err |= clSetKernelArg(countIntrinsicLightingRays, 1, sizeof(cl_float4), &ilpos);
            err |= clSetKernelArg(countIntrinsicLightingRays, 2, sizeof(cl_float), &ilVDW);
            err |= clSetKernelArg(countIntrinsicLightingRays, 3, sizeof(cl_float), &ilCutoffDist);
            err |= clSetKernelArg(countIntrinsicLightingRays, 4, sizeof(cl_uint), &mode);
            err |= clSetKernelArg(countIntrinsicLightingRays, 5, sizeof(cl_mem), &raysNeeded);
            err |= clSetKernelArg(countIntrinsicLightingRays, 6, sizeof(cl_int), &intersectingRays);
        } else {
            err = clSetKernelArg(countIntrinsicLightingRays, 0, sizeof(cl_mem), &points);
            err |= clSetKernelArg(countIntrinsicLightingRays, 1, sizeof(cl_float4), &ilpos);
            err |= clSetKernelArg(countIntrinsicLightingRays, 2, sizeof(cl_float), &ilVDW);
            err |= clSetKernelArg(countIntrinsicLightingRays, 3, sizeof(cl_float), &ilCutoffDist);
            err |= clSetKernelArg(countIntrinsicLightingRays, 4, sizeof(cl_uint), &mode);
            err |= clSetKernelArg(countIntrinsicLightingRays, 5, sizeof(cl_mem), &rayIndex);
            err |= clSetKernelArg(countIntrinsicLightingRays, 6, sizeof(cl_mem), &cl_sum);
            err |= clSetKernelArg(countIntrinsicLightingRays, 7, sizeof(cl_int), &intersectingRays);
        }
        
        err = clEnqueueNDRangeKernel(queue, countIntrinsicLightingRays, 1, NULL, rayIntersectionsSize, local, 0, NULL, NULL);
        
        clFinish(queue);
        if (err != CL_SUCCESS) {
            NSLog(@"Error: could not execute count intrinsic light rays kernel");
            return false;
        }
        
        
        if (self.runningOnGPU) {
            [scan PreScanBuffer:rayIndex inputData:raysNeeded maxGroupSize:wgs maxWorkItemCount:wgs elementCount:intersectingRays];
            
            //Just get the last number initially
            err = clEnqueueReadBuffer(queue, rayIndex, CL_TRUE, sizeof(cl_uint) * (intersectingRays - 1), sizeof(cl_uint), hostRayIndex, 0, NULL, NULL);
            if (err != CL_SUCCESS) {
                NSLog(@"Error: Failed to retrieve number of intrinsic rays required from the device");
                return false;
            }
            
            clFinish(queue);
            
            intrinsicRays = hostRayIndex[0];
            if (intrinsicRays > intersectingRays * SOFT_SHADOW_SAMPLES) {
                NSLog(@"Error: Impossible number of intrinsic rays - searching for outlier...");
                err = clEnqueueReadBuffer(queue, rayIndex, CL_TRUE, 0, sizeof(cl_uint) * intersectingRays, hostRayIndex, 0, NULL, NULL);
                if (err != CL_SUCCESS) {
                    NSLog(@"Error: Failed to retrieve number of intrinsic rays required from the device");
                    return false;
                }
                
                clFinish(queue);

                unsigned int *hraysNeeded = (unsigned int *)malloc(sizeof(unsigned int) * intersectingRays);
                clEnqueueReadBuffer(queue, raysNeeded, CL_TRUE, 0, sizeof(cl_uint) * intersectingRays, hraysNeeded, 0, NULL, NULL);
                clFinish(queue);
                unsigned int cumulative = 0;
                for (int j = 0; j < intersectingRays; j++) {
                    if (hraysNeeded[j] > SOFT_SHADOW_SAMPLES) {
                        printf("Error found at position %u - value: %u\n", j, hraysNeeded[j]);
                    }
                    if (hostRayIndex[j] != cumulative) {
                        printf("Error found in scan at position %u - value: %u, should be %u\n", j, hostRayIndex[j], cumulative);
                    }
                    cumulative += hraysNeeded[j];
                }
                free(hraysNeeded);
                printf("Search complete\n");
            }
        } else {
            err = clEnqueueReadBuffer(queue, cl_sum, CL_TRUE, 0, sizeof(cl_uint), &intrinsicRays, 0, NULL, NULL);
        }
        
        
        //Now generate the rays
        
            //Generate entropy for primary ray generation
//            unsigned int *rayEntropy = (unsigned int *)malloc(sizeof(unsigned int) * intersectingRays);
//            dispatch_semaphore_wait(entropySemaphore, DISPATCH_TIME_FOREVER);
//            for (int i = 0; i < intersectingRays; i++) {
//                rayEntropy[i] = [[rngForRenderers sharedInstance] getRandomUInt];
//            }
//            dispatch_semaphore_signal(entropySemaphore);
//            cl_mem cl_intrinsicRayEntropy = clCreateBuffer(context, CL_MEM_READ_WRITE, sizeof(cl_uint) * intersectingRays, NULL, NULL);
//            err = clEnqueueWriteBuffer(queue, cl_intrinsicRayEntropy, true, 0, sizeof(unsigned int) * intersectingRays, rayEntropy, 0, NULL, NULL);
//            clFinish(queue);
            
//            if (err != CL_SUCCESS) {
//                NSLog(@"Error: Failed to copy intrinsic ray entropy pool to the device");
//                return false;
//            }
            
//            free(rayEntropy);
        
        if (intrinsicRays > 0) {

            err = clSetKernelArg(generateIntrinsicLightingRays, 0, sizeof(cl_mem), &cl_intrinsicLightRays);
            err |= clSetKernelArg(generateIntrinsicLightingRays, 1, sizeof(cl_mem), &rayIndex);
            err |= clSetKernelArg(generateIntrinsicLightingRays, 2, sizeof(cl_mem), &rays);
            err |= clSetKernelArg(generateIntrinsicLightingRays, 3, sizeof(cl_mem), &points);
            err |= clSetKernelArg(generateIntrinsicLightingRays, 4, sizeof(cl_mem), &normals);
            err |= clSetKernelArg(generateIntrinsicLightingRays, 5, sizeof(cl_float4), &ilpos);
            err |= clSetKernelArg(generateIntrinsicLightingRays, 6, sizeof(cl_float), &ilVDW);
            err |= clSetKernelArg(generateIntrinsicLightingRays, 7, sizeof(cl_float), &ilCutoffDist);
            err |= clSetKernelArg(generateIntrinsicLightingRays, 8, sizeof(cl_uint), &mode);
//            err |= clSetKernelArg(generateIntrinsicLightingRays, 9, sizeof(cl_mem), &cl_intrinsicRayEntropy);
            err |= clSetKernelArg(generateIntrinsicLightingRays, 9, sizeof(cl_uint), &intersectingRays);
            
            if (err != CL_SUCCESS) {
                NSLog(@"Error: Failed to set arguments for generate intrinsic rays kernel");
                return false;
            }
            
            err = clEnqueueNDRangeKernel(queue, generateIntrinsicLightingRays, 1, NULL, rayIntersectionsSize, local, 0, NULL, NULL);
            
            clFinish(queue);
            if (err != CL_SUCCESS) {
                NSLog(@"Error: Failed to execute intrinsic light ray generation kernel");
                return false;
            }
//            clReleaseMemObject(cl_intrinsicRayEntropy);
            
            //Now check for intersections
            
            err = clSetKernelArg(rayDataLightingIntersectImage, 0, sizeof(cl_mem), &cl_intrinsicLightRays);
            err |= clSetKernelArg(rayDataLightingIntersectImage, 1, sizeof(cl_mem), &cl_intrinsicLightRayTValuesImage);
            err |= clSetKernelArg(rayDataLightingIntersectImage, 2, sizeof(cl_mem), &cl_treeImage);
            err |= clSetKernelArg(rayDataLightingIntersectImage, 3, sizeof(cl_mem), &cl_treeData);
            err |= clSetKernelArg(rayDataLightingIntersectImage, 4, sizeof(cl_float), &ilCutoffDist);
            err |= clSetKernelArg(rayDataLightingIntersectImage, 5, sizeof(cl_int), &intrinsicRays);
            
            if (err != CL_SUCCESS) {
                NSLog(@"Error: Failed to set kernel arguments for intrinsic light ray intersection test kernel");
                return false;
            }
            
            size_t intrinsicLightingSize[1];
            intrinsicLightingSize[0] = wgs * ceil((float)intrinsicRays / (float)wgs);
            
            err = clEnqueueNDRangeKernel(queue, rayDataLightingIntersectImage, 1, NULL, intrinsicLightingSize, local, 0, NULL, NULL);
            
            if (err != CL_SUCCESS) {
                NSLog(@"Error: Failed to execute intrinsic light ray intersection kernel");
                return false;
            }
            
            clFinish(queue);
            
            err = clSetKernelArg(generateImageIntrinsicRayLight, 0, sizeof(cl_mem), &image);
            err |= clSetKernelArg(generateImageIntrinsicRayLight, 1, sizeof(cl_int), &width);
            err |= clSetKernelArg(generateImageIntrinsicRayLight, 2, sizeof(cl_mem), &rays);
            err |= clSetKernelArg(generateImageIntrinsicRayLight, 3, sizeof(cl_mem), &tValues);
            err |= clSetKernelArg(generateImageIntrinsicRayLight, 4, sizeof(cl_mem), &points);
            err |= clSetKernelArg(generateImageIntrinsicRayLight, 5, sizeof(cl_mem), &normals);
            err |= clSetKernelArg(generateImageIntrinsicRayLight, 6, sizeof(cl_mem), &objects);
            err |= clSetKernelArg(generateImageIntrinsicRayLight, 7, sizeof(cl_mem), &cl_atomDataIn);
            err |= clSetKernelArg(generateImageIntrinsicRayLight, 8, sizeof(cl_float4), &ilpos);
            err |= clSetKernelArg(generateImageIntrinsicRayLight, 9, sizeof(cl_float4), &ilColour);
            err |= clSetKernelArg(generateImageIntrinsicRayLight, 10, sizeof(cl_float), &ilVDW);
            err |= clSetKernelArg(generateImageIntrinsicRayLight, 11, sizeof(cl_float), &ilCutoffDist);
            err |= clSetKernelArg(generateImageIntrinsicRayLight, 12, sizeof(cl_uint), &mode);
            err |= clSetKernelArg(generateImageIntrinsicRayLight, 13, sizeof(cl_mem), &cl_intrinsicLightRayTValuesImage);
            err |= clSetKernelArg(generateImageIntrinsicRayLight, 14, sizeof(cl_mem), &rayIndex);
            err |= clSetKernelArg(generateImageIntrinsicRayLight, 15, sizeof(cl_mem), &cl_intrinsicLightRays);
            err |= clSetKernelArg(generateImageIntrinsicRayLight, 16, sizeof(cl_int), &intersectingRays);
            
            if (err != CL_SUCCESS) {
                NSLog(@"Error: Failed to set kernel arguments for generate intrinsic image kernel");
                return false;
            }
            
            err = clEnqueueNDRangeKernel(queue, generateImageIntrinsicRayLight, 1, NULL, rayIntersectionsSize, local, 0, NULL, NULL);
            clFinish(queue);
            
            if (err != CL_SUCCESS) {
                NSLog(@"Error: Failed to execute intrinsic image generation kernel");
                return false;
            }

//        } else {
//            err = clEnqueueCopyBuffer(queue, inImage, outImage, 0, 0, sizeof(cl_float4) * intersectingRays, 0, NULL, NULL);
//            clFinish(queue);
            
//            err = clSetKernelArg(copyBuffer, 0, sizeof(cl_mem), &outImage);
//            err |= clSetKernelArg(copyBuffer, 1, sizeof(cl_mem), &inImage);
//            err |= clSetKernelArg(copyBuffer, 2, sizeof(cl_int), &intersectingRays);
//            if (err != CL_SUCCESS) {
//                NSLog(@"Error: Failed to set kernel arguments to copy intrinsic image data");
//                return false;
//            }
//            err = clEnqueueNDRangeKernel(queue, copyBuffer, 1, NULL, rayIntersectionsSize, local, 0, NULL, NULL);
//            if (err != CL_SUCCESS) {
//                NSLog(@"Error: Failed to copy intrinsic image data");
//                return false;
//            }

        }
    } else {
        
        
        err = clSetKernelArg(generateImageIntrinsicCrudeLight, 0, sizeof(cl_mem), &image);
        err |= clSetKernelArg(generateImageIntrinsicCrudeLight, 1, sizeof(cl_int), &width);
        err |= clSetKernelArg(generateImageIntrinsicCrudeLight, 2, sizeof(cl_mem), &rays);
        err |= clSetKernelArg(generateImageIntrinsicCrudeLight, 3, sizeof(cl_mem), &points);
        err |= clSetKernelArg(generateImageIntrinsicCrudeLight, 4, sizeof(cl_mem), &normals);
        err |= clSetKernelArg(generateImageIntrinsicCrudeLight, 5, sizeof(cl_mem), &objects);
        err |= clSetKernelArg(generateImageIntrinsicCrudeLight, 6, sizeof(cl_mem), &cl_atomDataIn);
        err |= clSetKernelArg(generateImageIntrinsicCrudeLight, 7, sizeof(cl_float4), &ilpos);
        err |= clSetKernelArg(generateImageIntrinsicCrudeLight, 8, sizeof(cl_float4), &ilColour);
        err |= clSetKernelArg(generateImageIntrinsicCrudeLight, 9, sizeof(cl_float), &ilVDW);
        err |= clSetKernelArg(generateImageIntrinsicCrudeLight, 10, sizeof(cl_float), &ilCutoffDist);
        err |= clSetKernelArg(generateImageIntrinsicCrudeLight, 11, sizeof(cl_uint), &mode);
        err |= clSetKernelArg(generateImageIntrinsicCrudeLight, 12, sizeof(cl_int), &intersectingRays);
        
        
        if (err != CL_SUCCESS) {
            NSLog(@"Error: Failed to set kernel arguments for generate intrinsic image kernel");
            return false;
        }
        
        err = clEnqueueNDRangeKernel(queue, generateImageIntrinsicCrudeLight, 1, NULL, rayIntersectionsSize, local, 0, NULL, NULL);
        clFinish(queue);

    }
    
    
    return true;
}

- (BOOL)splitRender {
    int err;
    
    //Generate entropy for primary ray generation
    dispatch_semaphore_wait(entropySemaphore, DISPATCH_TIME_FOREVER);
    [self generateEntropy];
    dispatch_semaphore_signal(entropySemaphore);
    
    //First generate primary rays
    cl_float4 rayOrigin = camera.viewOriginRayStart;
    cl_float4 lookAtPoint = camera.clookAtPoint;
    cl_float4 upOrientation = camera.cUpOrientation;
    cl_int width = renderSize.width;
    cl_int height = renderSize.height;
    cl_float cameraWidth = camera.viewWidth;
    cl_float cameraAperture = camera.aperture;
    cl_float cameraFocalLength = camera.focalLength;
    cl_float cameraLensLength = camera.lensLength;
    cl_int maxNumRays = renderSize.width * renderSize.height;
    cl_uint clipEnabled = camera.clipPlaneEnabled;
    cl_float clipDistance = camera.clipPlaneDistanceFromCamera;

    
    err = clEnqueueWriteBuffer(queue, cl_entropyPool, true, 0, sizeof(cl_uint) * renderSize.width * renderSize.height, entropyPool, 0, NULL, NULL);
    if (err != CL_SUCCESS) {
        NSLog(@"Error: Failed to copy entropy pool to OpenCL");
        return false;
    }
    clFinish(queue);

    err = clSetKernelArg(generateRay,  0, sizeof(cl_mem), &cl_rays);
//    err = clSetKernelArg(generateRay,  1, sizeof(cl_mem), &cl_rayDirection);
    err |= clSetKernelArg(generateRay, 1, sizeof(cl_mem), &cl_entropyPool);
    err |= clSetKernelArg(generateRay, 2, sizeof(startPixel), &startPixel);
    err |= clSetKernelArg(generateRay, 3, sizeof(cl_float4), &rayOrigin);
    err |= clSetKernelArg(generateRay, 4, sizeof(cl_float4), &lookAtPoint);
    err |= clSetKernelArg(generateRay, 5, sizeof(cl_float4), &upOrientation);
    err |= clSetKernelArg(generateRay, 6, sizeof(cl_int), &width);
    err |= clSetKernelArg(generateRay, 7, sizeof(cl_int), &height);
    err |= clSetKernelArg(generateRay, 8, sizeof(cl_float), &cameraWidth);
    err |= clSetKernelArg(generateRay, 9, sizeof(cl_float), &cameraAperture);
    err |= clSetKernelArg(generateRay, 10, sizeof(cl_float), &cameraFocalLength);
    err |= clSetKernelArg(generateRay, 11, sizeof(cl_float), &cameraLensLength);
    err |= clSetKernelArg(generateRay, 12, sizeof(cl_uint), &clipEnabled);
    err |= clSetKernelArg(generateRay, 13, sizeof(cl_float), &clipDistance);
    err |= clSetKernelArg(generateRay, 14, sizeof(cl_int), &maxNumRays);
    
    if (err != CL_SUCCESS)
    {
        printf("Error: Failed to set generate kernel arguments!\n");
        return false;
    }
    
    size_t global[1], local[1];
    int wgs;
    wgs = runningOnGPU ? kWGSGPU : kWGSCPU;
    global[0] = wgs * ceil((float)numPixels / (float)wgs);
    local[0] = wgs;
    
    //    NSLog(@"Starting Renderer");
    err = clEnqueueNDRangeKernel(queue, generateRay, 1, NULL, global, local, 0, NULL, NULL);
    if (err)
    {
        printf("Error: Failed to execute generate ray kernel!\n");
        return false;
    }
    clFinish(queue);
    //    NSLog(@"Rendering finished");

    
    //Then do object intersection
    err = clSetKernelArg(intersectRay, 0, sizeof(cl_mem), &cl_rays);
    err |= clSetKernelArg(intersectRay, 1, sizeof(cl_mem), &cl_tValues);
    err |= clSetKernelArg(intersectRay, 2, sizeof(cl_mem), &cl_points);
    err |= clSetKernelArg(intersectRay, 3, sizeof(cl_mem), &cl_normals);
    err |= clSetKernelArg(intersectRay, 4, sizeof(cl_mem), &cl_object_ids);
    err |= clSetKernelArg(intersectRay, 5, sizeof(startPixel), &startPixel);
    err |= clSetKernelArg(intersectRay, 6, sizeof(cl_mem), &cl_treeImage);
    err |= clSetKernelArg(intersectRay, 7, sizeof(cl_mem), &cl_treeData);
    err |= clSetKernelArg(intersectRay, 8, sizeof(cl_int), &maxNumRays);
    
    if (err != CL_SUCCESS)
    {
        printf("Error: Failed to set ray intersect kernel arguments!\n");
        return false;
    }
    
    err = clEnqueueNDRangeKernel(queue, intersectRay, 1, NULL, global, local, 0, NULL, NULL);
    if (err)
    {
        printf("Error: Failed to execute ray intersection kernel!\n");
        return false;
    }
    clFinish(queue);
    
//    cl_float *sceneTValues = (cl_float*)malloc(sizeof(cl_float) * width * height);
//    cl_float4 *scenePoints = (cl_float4*)malloc(sizeof(cl_float4) * width * height);
//    cl_float4 *sceneNormals = (cl_float4*)malloc(sizeof(cl_float4) * width * height);
//    cl_uint *sceneObjectIds = (cl_uint*)malloc(sizeof(cl_uint) * width * height);
//    cl_float8 *sceneRays = (cl_float8*)malloc(sizeof(cl_float8) * width * height);
    
//    err = clEnqueueReadBuffer(queue, cl_tValues, true, 0, sizeof(cl_float) * width * height, sceneTValues, 0, NULL, NULL);
//    err |= clEnqueueReadBuffer(queue, cl_points, true, 0, sizeof(cl_float4) * width * height, scenePoints, 0, NULL, NULL);
//    err |= clEnqueueReadBuffer(queue, cl_normals, true, 0, sizeof(cl_float4) * width * height, sceneNormals, 0, NULL, NULL);
//    err |= clEnqueueReadBuffer(queue, cl_object_ids, true, 0, sizeof(cl_uint) * width * height, sceneObjectIds, 0, NULL, NULL);
//    err |= clEnqueueReadBuffer(queue, cl_rays, true, 0, sizeof(cl_float8) * width * height, sceneRays, 0, NULL, NULL);
    
//    if (err != CL_SUCCESS) {
//        NSLog(@"Error: Failed to retrieve intersection data");
//        return false;
//    }

    //And count how many rays hit to allow generation of lighting rays
    cl_int fillInt = 0;
//    err = clEnqueueFillBuffer(queue, cl_intersection, &fillInt, sizeof(fillInt), 0, sizeof(cl_uint) * maxNumRays, 0, NULL, NULL);
//    err += clEnqueueFillBuffer(queue, cl_intersectionScan, &fillInt, sizeof(fillInt), 0, sizeof(cl_uint) * maxNumRays, 0, NULL, NULL);
//    err += clEnqueueFillBuffer(queue, cl_sum, &fillInt, sizeof(fillInt), 0, sizeof(cl_uint), 0, NULL, NULL);
//    if (err != CL_SUCCESS) {
//        NSLog(@"Error filling intersection buffers");
//        return false;
//    }
//    clFinish(queue);
    
    if (self.runningOnGPU) {
        err = clSetKernelArg(detectIntersectingRays, 0, sizeof(cl_mem), &cl_tValues);
        err |= clSetKernelArg(detectIntersectingRays, 1, sizeof(cl_mem), &cl_intersection);
        err |= clSetKernelArg(detectIntersectingRays, 2, sizeof(cl_int), &maxNumRays);
    } else {
        err = clSetKernelArg(detectIntersectingRays, 0, sizeof(cl_mem), &cl_tValues);
        err |= clSetKernelArg(detectIntersectingRays, 1, sizeof(cl_mem), &cl_intersection);
        err |= clSetKernelArg(detectIntersectingRays, 2, sizeof(cl_mem), &cl_sum);
        err |= clSetKernelArg(detectIntersectingRays, 3, sizeof(cl_int), &maxNumRays);
    }
    
    if (err != CL_SUCCESS) {
        NSLog(@"Error: Failed to set count intersecting rays kernel arguments");
        return false;
    }
    
    err = clEnqueueNDRangeKernel(queue, detectIntersectingRays, 1, NULL, global, local, 0, NULL, NULL);
    if (err) {
        NSLog(@"Failed to execute countIntersectingRays kernel");
        return false;
    }
    clFinish(queue);

    uint intersectingRays;// = 0, intersectingRaysCL;
    if (self.runningOnGPU) {
        [scan PreScanBuffer:cl_intersectionScan inputData:cl_intersection maxGroupSize:wgs maxWorkItemCount:wgs elementCount:maxNumRays];
        unsigned int *data = (unsigned int*)malloc(sizeof(cl_uint) * maxNumRays);
        err = clEnqueueReadBuffer(queue, cl_intersectionScan, true, 0, sizeof(cl_uint) * maxNumRays, data, 0, NULL, NULL);
        clFinish(queue);
        intersectingRays = data[maxNumRays - 1];
        free(data);
    } else {
        err = clEnqueueReadBuffer(queue, cl_sum, true, 0, sizeof(cl_uint), &intersectingRays, 0, NULL, NULL);
        clFinish(queue);
    }

    unsigned int image_height = (maxNumRays) / kSamplerMaxWidth + 1;
    if (image_height < 2) {
        image_height = 2;
    }
    size_t origin[3] = {0,0,0};
    size_t region[3]; region[0] = kSamplerMaxWidth; region[1] = image_height; region[2] = 1;
    /*cl_float4 *tValueBuffer = (cl_float4 *)malloc(sizeof(cl_float4) * image_height * kSamplerMaxWidth);

    err = clEnqueueReadImage(queue, cl_tValues, true, origin, region, 0, 0, tValueBuffer, 0, NULL, NULL);
    if (err) {
        NSLog(@"Error: Failed to read back tValues from the device");
        return false;
    }
    clFinish(queue);

    unsigned int *intersectionScan = (unsigned int *)malloc(sizeof(unsigned int) * maxNumRays);
    
    intersectingRays = 0;
    for (int i = 0; i < maxNumRays; i++) {
        intersectionScan[i] = intersectingRays;
        if (tValueBuffer[i].x < NO_INTERSECTION) {
            intersectingRays++;
        }
    }
    
    err = clEnqueueWriteBuffer(queue, cl_intersectionScan, true, 0, sizeof(cl_uint) * maxNumRays, intersectionScan, 0, NULL, NULL);
    if (err != CL_SUCCESS) {
        NSLog(@"Error: Failed to send intersection scan to the device");
        return false;
    }
    clFinish(queue);
    free(intersectionScan);*/
    
//    err = clEnqueueReadBuffer(queue, cl_sum, CL_TRUE, 0, sizeof(cl_int), &intersectingRaysCL, 0, NULL, NULL);
//    if (err != CL_SUCCESS) {
//        NSLog(@"Error: Failed to retrieve sum from the device");
//        return false;
//    }
    
//    for (int i = 0; i < maxNumRays; i++) {
//        if (sceneTValues[i] < NO_INTERSECTION) {
//            intersectingRays++;
//        }
//    }
    
//    printf("Intersecting Rays: %d\n", intersectingRays);
    
//    cl_float4 *intersectionPoints = (cl_float4*)malloc(sizeof(cl_float4) * intersectingRays);
//    cl_float4 *intersectionNormals = (cl_float4*)malloc(sizeof(cl_float4) * intersectingRays);
//    cl_uint *intersectionIndex = (cl_uint*)malloc(sizeof(cl_uint) * intersectingRays);
//    cl_uint *intersectionObjectIds = (cl_uint*)malloc(sizeof(cl_uint) * intersectingRays);
//    cl_float *intersectionTValues = (cl_float*)malloc(sizeof(cl_float) * intersectingRays);
//    cl_float8 *intersectionRays = (cl_float8*)malloc(sizeof(cl_float8) * intersectingRays);
    
//    int count = 0;
//    for (int i = 0; i < width * height; i++) {
//        if (sceneTValues[i] != NO_INTERSECTION) {
//            intersectionIndex[count] = i;
//            intersectionPoints[count] = scenePoints[i];
//            intersectionNormals[count] = sceneNormals[i];
//            intersectionTValues[count] = sceneTValues[i];
//            intersectionRays[count] = sceneRays[i];
//            intersectionObjectIds[count] = sceneObjectIds[i];
//            count++;
//        }
//    }
    
    //Now select the points, normals, t-values from the intersecting rays
//    err = clEnqueueFillBuffer(queue, cl_sum, &fillInt, sizeof(fillInt), 0, sizeof(int), 0, NULL, NULL);
//    if (err != CL_SUCCESS) {
//        NSLog(@"Error filling sum buffer");
//        return false;
//    }
//    clFinish(queue);
    
    err = clSetKernelArg(selectIntersectionsFromRays, 0, sizeof(cl_mem), &cl_tValues);
    if (runningOnGPU) {
        err |= clSetKernelArg(selectIntersectionsFromRays, 1, sizeof(cl_mem), &cl_intersectionScan);
    } else {
        err |= clSetKernelArg(selectIntersectionsFromRays, 1, sizeof(cl_mem), &cl_intersection);
    }
    err |= clSetKernelArg(selectIntersectionsFromRays, 2, sizeof(cl_mem), &cl_rays);
    err |= clSetKernelArg(selectIntersectionsFromRays, 3, sizeof(cl_mem), &cl_points);
    err |= clSetKernelArg(selectIntersectionsFromRays, 4, sizeof(cl_mem), &cl_normals);
    err |= clSetKernelArg(selectIntersectionsFromRays, 5, sizeof(cl_mem), &cl_object_ids);
    err |= clSetKernelArg(selectIntersectionsFromRays, 6, sizeof(cl_mem), &cl_intersectionTValues);
    err |= clSetKernelArg(selectIntersectionsFromRays, 7, sizeof(cl_mem), &cl_intersectionRays);
    err |= clSetKernelArg(selectIntersectionsFromRays, 8, sizeof(cl_mem), &cl_intersectionPoints);
    err |= clSetKernelArg(selectIntersectionsFromRays, 9, sizeof(cl_mem), &cl_intersectionNormals);
    err |= clSetKernelArg(selectIntersectionsFromRays, 10, sizeof(cl_mem), &cl_intersectionObjectIds);
    err |= clSetKernelArg(selectIntersectionsFromRays, 11, sizeof(cl_mem), &cl_intersectionIndex);
    err |= clSetKernelArg(selectIntersectionsFromRays, 12, sizeof(cl_int), &maxNumRays);
    
    if (err != CL_SUCCESS) {
        NSLog(@"Error: failed to set kernel arguments for select intersections kernel");
        return false;
    }
    
    err = clEnqueueNDRangeKernel(queue, selectIntersectionsFromRays, 1, NULL, global, local, 0, NULL, NULL);
    if (err) {
        NSLog(@"Failed to execute select intersections kernel");
        return false;
    }
    
    clFinish(queue);
    
    //Now generate general lighting rays
    
    err = clSetKernelArg(generateLightingRays, 0, sizeof(cl_mem), &cl_sceneLightRays);
    err |= clSetKernelArg(generateLightingRays, 1, sizeof(cl_mem), &cl_intersectionRays);
    err |= clSetKernelArg(generateLightingRays, 2, sizeof(cl_int), &sceneNumLights);
    err |= clSetKernelArg(generateLightingRays, 3, sizeof(cl_mem), &cl_lightsIn);
    err |= clSetKernelArg(generateLightingRays, 4, sizeof(cl_mem), &cl_intersectionPoints);
    err |= clSetKernelArg(generateLightingRays, 5, sizeof(cl_mem), &cl_intersectionNormals);
    err |= clSetKernelArg(generateLightingRays, 6, sizeof(cl_int), &intersectingRays);
    
    if (err != CL_SUCCESS) {
        NSLog(@"Error: Failed to set kernel arguments for light ray generation kernel");
        return false;
    }

    size_t rayIntersectionsSize[1];
    rayIntersectionsSize[0] = wgs * ceil((float)intersectingRays / (float)wgs);
    
    err = clEnqueueNDRangeKernel(queue, generateLightingRays, 1, NULL, rayIntersectionsSize, local, 0, NULL, NULL);
    
    clFinish(queue);

    if (err != CL_SUCCESS) {
        NSLog(@"Error: Failed to execute light ray generation kernel");
        return false;
    }
    
    //Now check for intersections on the general lighting rays
    int lightingIntersections = sceneNumLights * intersectingRays;
    
    err = clSetKernelArg(rayDataLightingIntersect, 0, sizeof(cl_mem), &cl_sceneLightRays);
    err |= clSetKernelArg(rayDataLightingIntersect, 1, sizeof(cl_mem), &cl_sceneLightRayTValues);
    err |= clSetKernelArg(rayDataLightingIntersect, 2, sizeof(cl_mem), &cl_treeImage);
    err |= clSetKernelArg(rayDataLightingIntersect, 3, sizeof(cl_mem), &cl_treeData);
    err |= clSetKernelArg(rayDataLightingIntersect, 4, sizeof(cl_int), &lightingIntersections);
    
    if (err != CL_SUCCESS) {
        NSLog(@"Error: Failed to set kernel arguments for light ray intersection test kernel");
        return false;
    }
    
    size_t lightingSize[1];
    lightingSize[0] = wgs * ceil((float)lightingIntersections / (float)wgs);
    
    err = clEnqueueNDRangeKernel(queue, rayDataLightingIntersect, 1, NULL, lightingSize, local, 0, NULL, NULL);

    clFinish(queue);

    if (err != CL_SUCCESS) {
        NSLog(@"Error: Failed to run light ray intersection test kernel");
        return false;
    }
    
    //Now generate an image based on all intersection data
    cl_image_format fmt;
    fmt.image_channel_order = CL_RGBA;
    fmt.image_channel_data_type = CL_FLOAT;
    cl_image_desc desc;
    desc.image_type = CL_MEM_OBJECT_IMAGE2D;
    desc.image_width = renderSize.width;
    desc.image_height = renderSize.height;
    desc.image_depth = 1;
    desc.image_row_pitch = 0;
    desc.image_slice_pitch = 0;
    desc.num_mip_levels = 0;
    desc.num_samples = 0;
    desc.buffer = NULL;
    
    cl_float4 fillColour;
    fillColour.x = fillColour.y = fillColour.z = fillColour.w = 0.0;
    region[0] = renderSize.width; region[1] = renderSize.height; region[2] = 1;
    err = clEnqueueFillImage(queue, cl_Image, &fillColour, origin, region, 0, NULL, NULL);
    if (err != CL_SUCCESS) {
        NSLog(@"Error: Failed to blank output image buffer");
    }
    err = clEnqueueFillImage(queue, cl_intrinsicObjectImage, &fillColour, origin, region, 0, NULL, NULL);
    if (err != CL_SUCCESS) {
        NSLog(@"Error: Failed to blank output intrinsic image buffer");
    }
    err = clEnqueueFillImage(queue, cl_intrinsicLightImage, &fillColour, origin, region, 0, NULL, NULL);
    if (err != CL_SUCCESS) {
        NSLog(@"Error: Failed to blank output intrinsic image buffer");
    }
    clFinish(queue);
    
    cl_float4 emptyFloat;
    emptyFloat.x = 0; emptyFloat.y = 0; emptyFloat.z = 0; emptyFloat.w = 0;
//    err = clEnqueueFillBuffer(queue, cl_intrinsicIntersectionLightBuffer, &emptyFloat, sizeof(emptyFloat), 0, sizeof(cl_float4) * intersectingRays, 0, NULL, NULL);
    err = clSetKernelArg(zeroBuffer, 0, sizeof(cl_mem), &cl_intrinsicIntersectionLightBuffer);
    err |= clSetKernelArg(zeroBuffer, 1, sizeof(cl_uint), &intersectingRays);
    if (err != CL_SUCCESS) {
        NSLog(@"Error setting arguments for zero intrinsic light buffer kernel");
        return false;
    }
    err = clEnqueueNDRangeKernel(queue, zeroBuffer, 1, NULL, rayIntersectionsSize, local, 0, NULL, NULL);
    
    clFinish(queue);
    
    if (err != CL_SUCCESS) {
        NSLog(@"Error: Failed to zero intrinsic light buffer");
        return false;
    }
    
    if (kRenderCorrectIntrinsicLighting) {
        
        //Prescreen intrinsic lights, so then only ones that are close to anything get lighting calculations performed
        unsigned int *screenLight = (unsigned int*)malloc(sizeof(unsigned int) * numIntrinsicLights);
        
        if (numIntrinsicLights) {
            
            cl_mem cl_screenLight = clCreateBuffer(context, CL_MEM_READ_WRITE, sizeof(cl_uint) * numIntrinsicLights, NULL, NULL);
            //    err = clEnqueueFillBuffer(queue, cl_screenLight, &fillInt, sizeof(fillInt), 0, sizeof(cl_uint) * numIntrinsicLights, 0, NULL, NULL);
            if (err != CL_SUCCESS) {
                NSLog(@"Error filling intrinsic light screen buffer");
                return false;
            }
            
            float tMax = camera.hazeStartDistanceFromCamera + camera.hazeLength;
            
            err = clSetKernelArg(screenIntrinsicLights, 0, sizeof(cl_mem), &cl_screenLight);
            err |= clSetKernelArg(screenIntrinsicLights, 1, sizeof(cl_mem), &cl_intrinsicLightsIn);
            err |= clSetKernelArg(screenIntrinsicLights, 2, sizeof(cl_mem), &cl_intersectionPoints);
            err |= clSetKernelArg(screenIntrinsicLights, 3, sizeof(cl_mem), &cl_intersectionNormals);
            err |= clSetKernelArg(screenIntrinsicLights, 4, sizeof(cl_mem), &cl_intersectionTValues);
            err |= clSetKernelArg(screenIntrinsicLights, 5, sizeof(cl_float), &tMax);
            err |= clSetKernelArg(screenIntrinsicLights, 6, sizeof(cl_uint), &numIntrinsicLights);
            err |= clSetKernelArg(screenIntrinsicLights, 7, sizeof(cl_uint), &intersectingRays);
            
            if (err != CL_SUCCESS) {
                NSLog(@"Error setting arguments for intrinsic light screening kernel");
                return false;
            }
            
            size_t intrinsicSize[1];
            intrinsicSize[0] = wgs * ceil((float)numIntrinsicLights / (float)wgs);
            
            err = clEnqueueNDRangeKernel(queue, screenIntrinsicLights, 1, NULL, intrinsicSize, local, 0, NULL, NULL);
            
            if (err != CL_SUCCESS) {
                NSLog(@"Error exectuing intrinsic light screening kernel");
                return false;
            }
            
            clFinish(queue);
            
            
            //    printf(" NIL: %d ", numIntrinsicLights);
            err = clEnqueueReadBuffer(queue, cl_screenLight, CL_TRUE, 0, sizeof(cl_uint) * numIntrinsicLights, screenLight, 0, NULL, NULL);
            clFinish(queue);
            if (err != CL_SUCCESS) {
                NSLog(@"Error: Failed to retreive intrinsic light screening results");
                return false;
            }
            clReleaseMemObject(cl_screenLight);
            
        }
        
        cl_uint *intrinsicRayIndex = (cl_uint*)malloc(sizeof(cl_uint) * intersectingRays);
        
        
        //    cl_image_format fmt;
        fmt.image_channel_order = CL_RGBA;
        fmt.image_channel_data_type = CL_FLOAT;
        //    cl_image_desc desc;
        desc.image_type = CL_MEM_OBJECT_IMAGE2D;
        desc.image_width = kSamplerMaxWidth;
        desc.image_height = (SOFT_SHADOW_SAMPLES * intersectingRays * 2) / kSamplerMaxWidth + 1;
        if (desc.image_height < 2) {
            desc.image_height = 2;
        }
        desc.image_depth = 1;
        desc.image_row_pitch = 0;
        desc.image_slice_pitch = 0;
        desc.num_mip_levels = 0;
        desc.num_samples = 0;
        desc.buffer = NULL;
        
        desc.image_height = (SOFT_SHADOW_SAMPLES * intersectingRays) / kSamplerMaxWidth + 1;
        if (desc.image_height < 2) {
            desc.image_height = 2;
        }
        
        for (int i = 0; i < numIntrinsicLights; i++) {
            //        imageSource = i & 1 ? cl_intrinsicIntersectionLight1 : cl_intrinsicIntersectionLight2;
            //        imageDestination = i & 1 ? cl_intrinsicIntersectionLight2 : cl_intrinsicIntersectionLight1;
            if (screenLight[i]) {
                if (!runningOnGPU) {
                    err = clEnqueueFillBuffer(queue, cl_sum, &fillInt, sizeof(fillInt), 0, sizeof(cl_uint), 0, NULL, NULL);
                    if (err != CL_SUCCESS) {
                        NSLog(@"Error filling intrinsic ray sum buffers");
                        return false;
                    }
                    clFinish(queue);
                }
                [self processIntrinsicLightNumber:i numIntersectingRays:intersectingRays intersectionTValues:cl_intersectionTValues intersectionPoints:cl_intersectionPoints intersectionNormals:cl_intersectionNormals intersectionRays:cl_intersectionRays intersectionObjects:cl_intersectionObjectIds wgs:wgs currentImage:cl_intrinsicIntersectionLightBuffer raysNeeded:cl_intrinsicRaysNeeded rayIndex:cl_intrinsicRaysNeeded hostRayIndex:intrinsicRayIndex sum:cl_intrinsicSum rayImage:cl_intrinsicLightRays tValueImage:cl_intrinsicLightRayTValuesImage];
            }
        }
        
        free(intrinsicRayIndex);
        free(screenLight);
        
        err = clSetKernelArg(convertLinearColoursToImage, 0, sizeof(cl_mem), &cl_intrinsicLightImage);
        err |= clSetKernelArg(convertLinearColoursToImage, 1, sizeof(cl_int), &width);
        err |= clSetKernelArg(convertLinearColoursToImage, 2, sizeof(cl_mem), &cl_intrinsicIntersectionLightBuffer);
        err |= clSetKernelArg(convertLinearColoursToImage, 3, sizeof(cl_mem), &cl_intersectionIndex);
        err |= clSetKernelArg(convertLinearColoursToImage, 4, sizeof(cl_int), &intersectingRays);
        
        if (err != CL_SUCCESS) {
            NSLog(@"Error: Failed to set kernel arguments for generate image kernel");
            return false;
        }
        
        err = clEnqueueNDRangeKernel(queue, convertLinearColoursToImage, 1, NULL, rayIntersectionsSize, local, 0, NULL, NULL);
        
        clFinish(queue);
        if (err != CL_SUCCESS) {
            NSLog(@"Error: Failed to create intrinsic light image");
            return false;
        }
    }
    
    err = clSetKernelArg(generateImageIntrinsicObjects, 0, sizeof(cl_mem), &cl_intrinsicObjectImage);
    err |= clSetKernelArg(generateImageIntrinsicObjects, 1, sizeof(cl_int), &width);
    err |= clSetKernelArg(generateImageIntrinsicObjects, 2, sizeof(cl_mem), &cl_intersectionTValues);
    err |= clSetKernelArg(generateImageIntrinsicObjects, 3, sizeof(cl_mem), &cl_intersectionRays);
    err |= clSetKernelArg(generateImageIntrinsicObjects, 4, sizeof(cl_mem), &cl_intersectionObjectIds);
    err |= clSetKernelArg(generateImageIntrinsicObjects, 5, sizeof(cl_mem), &cl_intersectionNormals);
    err |= clSetKernelArg(generateImageIntrinsicObjects, 6, sizeof(cl_mem), &cl_intersectionIndex);
    err |= clSetKernelArg(generateImageIntrinsicObjects, 7, sizeof(cl_mem), &cl_atomDataIn);
    err |= clSetKernelArg(generateImageIntrinsicObjects, 8, sizeof(cl_int), &intersectingRays);
    
    if (err != CL_SUCCESS) {
        NSLog(@"Error: Failed to set kernel arguments for generate image kernel");
        return false;
    }
    
    err = clEnqueueNDRangeKernel(queue, generateImageIntrinsicObjects, 1, NULL, rayIntersectionsSize, local, 0, NULL, NULL);
    
    clFinish(queue);
    
    if (err != CL_SUCCESS) {
        NSLog(@"Error: Failed to execute generate image kernel");
        return false;
    }
    

    err = clSetKernelArg(generateImage, 0, sizeof(cl_mem), &cl_Image);
    err |= clSetKernelArg(generateImage, 1, sizeof(cl_int), &width);
    err |= clSetKernelArg(generateImage, 2, sizeof(cl_mem), &cl_intersectionTValues);
    err |= clSetKernelArg(generateImage, 3, sizeof(cl_mem), &cl_intersectionRays);
    err |= clSetKernelArg(generateImage, 4, sizeof(cl_mem), &cl_intersectionObjectIds);
    err |= clSetKernelArg(generateImage, 5, sizeof(cl_mem), &cl_intersectionNormals);
    err |= clSetKernelArg(generateImage, 6, sizeof(cl_mem), &cl_intersectionIndex);
    err |= clSetKernelArg(generateImage, 7, sizeof(cl_mem), &cl_atomDataIn);
    err |= clSetKernelArg(generateImage, 8, sizeof(cl_int), &sceneNumLights);
    err |= clSetKernelArg(generateImage, 9, sizeof(cl_mem), &cl_lightsIn);
    err |= clSetKernelArg(generateImage, 10, sizeof(cl_mem), &cl_sceneLightRays);
    err |= clSetKernelArg(generateImage, 11, sizeof(cl_mem), &cl_sceneLightRayTValues);
    err |= clSetKernelArg(generateImage, 12, sizeof(cl_float4), &cl_ambientLight);
    err |= clSetKernelArg(generateImage, 13, sizeof(cl_int), &intersectingRays);
    
    if (err != CL_SUCCESS) {
        NSLog(@"Error: Failed to set kernel arguments for generate image kernel");
        return false;
    }
    
    err = clEnqueueNDRangeKernel(queue, generateImage, 1, NULL, rayIntersectionsSize, local, 0, NULL, NULL);

    clFinish(queue);

    if (err != CL_SUCCESS) {
        NSLog(@"Error: Failed to execute generate image kernel");
        return false;
    }
    

    fmt.image_channel_order = CL_RGBA;
    fmt.image_channel_data_type = CL_FLOAT;
    desc.image_type = CL_MEM_OBJECT_IMAGE2D;
    desc.image_width = renderSize.width;
    desc.image_height = renderSize.height;
    desc.image_depth = 1;
    desc.image_row_pitch = 0;
    desc.image_slice_pitch = 0;
    desc.num_mip_levels = 0;
    desc.num_samples = 0;
    desc.buffer = NULL;

    err = clSetKernelArg(blurVertical, 0, sizeof(cl_mem), &cl_intrinsicObjectImage);
    err |= clSetKernelArg(blurVertical, 1, sizeof(cl_mem), &cl_blurOut1);
    err |= clSetKernelArg(blurVertical, 2, sizeof(cl_int), &width);
    err |= clSetKernelArg(blurVertical, 3, sizeof(cl_int), &height);
    err |= clSetKernelArg(blurVertical, 4, sizeof(cl_mem), &cl_mask);
    err |= clSetKernelArg(blurVertical, 5, sizeof(cl_int), &maskSize);
    if (err != CL_SUCCESS) {
        NSLog(@"Error: Failed to set arguments for blur vertical kernel");
        return false;
    }
    
    size_t blurSize[1];
    blurSize[0] = wgs * ceil((float)width / (float)wgs);
    
    err = clEnqueueNDRangeKernel(queue, blurVertical, 1, NULL, blurSize, local, 0, NULL, NULL);
    if (err != CL_SUCCESS) {
        NSLog(@"Error: Failed to execute vertical blur");
        return false;
    }
    clFinish(queue);

    err = clSetKernelArg(blurHorizontal, 0, sizeof(cl_mem), &cl_blurOut1);
    err |= clSetKernelArg(blurHorizontal, 1, sizeof(cl_mem), &cl_blurOut2);
    err |= clSetKernelArg(blurHorizontal, 2, sizeof(cl_int), &width);
    err |= clSetKernelArg(blurHorizontal, 3, sizeof(cl_int), &height);
    err |= clSetKernelArg(blurHorizontal, 4, sizeof(cl_mem), &cl_mask);
    err |= clSetKernelArg(blurHorizontal, 5, sizeof(cl_int), &maskSize);

    blurSize[0] = wgs * ceil((float)height / (float)wgs);
    
    err = clEnqueueNDRangeKernel(queue, blurHorizontal, 1, NULL, blurSize, local, 0, NULL, NULL);
    if (err != CL_SUCCESS) {
        NSLog(@"Error: Failed to execute vertical blur");
        return false;
    }
    clFinish(queue);


    //Sum the blur outputs...
//    err = [self sumImage1:cl_blurOut1 andImage2:cl_blurOut2 andStoreIn:cl_blurOut width:width executionLimit:maxNumRays global:global local:local];
    
//    if (!err) {
//        NSLog(@"Error: Failed to sum blur vertical components");
//        return false;
//    }
    
    //Sum the light contributions
    
    cl_float hazeStart = camera.hazeStartDistanceFromCamera;
    cl_float hazeLength = camera.hazeLength;
    cl_float4 hazeColour = camera.hazeColour;
    cl_float desaturation = 0.0;
    err = clSetKernelArg(generateImageHaze, 0, sizeof(cl_mem), &cl_summedImage);
    err |= clSetKernelArg(generateImageHaze, 1, sizeof(cl_mem), &cl_Image);
    err |= clSetKernelArg(generateImageHaze, 2, sizeof(cl_mem), &cl_intrinsicObjectImage);
    err |= clSetKernelArg(generateImageHaze, 3, sizeof(cl_mem), &cl_intrinsicLightImage);
    err |= clSetKernelArg(generateImageHaze, 4, sizeof(cl_mem), &cl_blurOut2);
    err |= clSetKernelArg(generateImageHaze, 5, sizeof(cl_int), &width);
    err |= clSetKernelArg(generateImageHaze, 6, sizeof(cl_mem), &cl_tValues);
    err |= clSetKernelArg(generateImageHaze, 7, sizeof(cl_float), &hazeStart);
    err |= clSetKernelArg(generateImageHaze, 8, sizeof(cl_float), &hazeLength);
    err |= clSetKernelArg(generateImageHaze, 9, sizeof(cl_float4), &hazeColour);
    err |= clSetKernelArg(generateImageHaze, 10, sizeof(cl_float), &desaturation);
    err |= clSetKernelArg(generateImageHaze, 11, sizeof(cl_mem), &maxNumRays);
    
    if (err != CL_SUCCESS) {
        NSLog(@"Error: Failed to set kernel arguments for haze generation");
        return false;
    }
    
    err = clEnqueueNDRangeKernel(queue, generateImageHaze, 1, NULL, global, local, 0, NULL, NULL);
    if (err != CL_SUCCESS) {
        NSLog(@"Error: Failed to execute haze generation kernel");
        return false;
    }
    
    clFinish(queue);
//    err = [self sumImage1:cl_image andImage2:cl_intrinsicObjectImage andStoreIn:cl_summedImage width:width executionLimit:maxNumRays global:global local:local];
    
//    err = clSetKernelArg(sumImages, 0, sizeof(cl_mem), &cl_summedImage);
//    err |= clSetKernelArg(sumImages, 1, sizeof(cl_mem), &cl_image);
//    err |= clSetKernelArg(sumImages, 2, sizeof(cl_mem), &cl_intrinsicImage);
//    err |= clSetKernelArg(sumImages, 3, sizeof(cl_int), &width);
//    err |= clSetKernelArg(sumImages, 4, sizeof(cl_int), &maxNumRays);
    
//    if (err != CL_SUCCESS) {
//        NSLog(@"Error: Failed to set arguments for image summing kernel");
//        return false;
//    }
    
//    err = clEnqueueNDRangeKernel(queue, sumImages, 1, NULL, global, local, 0, NULL, NULL);
    
//    if (err != CL_SUCCESS) {
//        NSLog(@"Error: Failed to execute sum images kernel");
//        return false;
//    }
//    if (!err) {
//        NSLog(@"Error: Failed to complete final sum kernel");
//        return false;
//    }
    
    //Finally convert float image data to 32 bit
//    err = clSetKernelArg(convertToARGB_32Bit, 0, sizeof(cl_mem), &cl_pixelsOut);
//    err |= clSetKernelArg(convertToARGB_32Bit, 1, sizeof(cl_mem), &cl_summedImage);
//    err |= clSetKernelArg(convertToARGB_32Bit, 2, sizeof(cl_int), &width);
//    err |= clSetKernelArg(convertToARGB_32Bit, 3, sizeof(cl_int), &maxNumRays);
    
//    if (err != CL_SUCCESS) {
//        NSLog(@"Error: Failed to set arguments for colour conversion kernel");
//        return false;
//    }
    
//    err = clEnqueueNDRangeKernel(queue, convertToARGB_32Bit, 1, NULL, global, local, 0, NULL, NULL);

//    clFinish(queue);
    
//    err = clEnqueueReadBuffer(queue, cl_pixelsOut, true, 0, pixelsOutSize, pixelsOut, 0, NULL, NULL );
//    if (err)
//    {
//        printf("Error: Failed to read back results from the device!\n");
//        return false;
//    }
    
    err = clEnqueueReadImage(queue, cl_summedImage, true, origin, region, 0, 0, rawPixels, 0, NULL, NULL);
    if (err) {
        NSLog(@"Error: Failed to read back results from the device");
        return false;
    }

    clFinish(queue);

    //Free stuff
//    clReleaseMemObject(cl_sum);
    
    return true;

}

- (BOOL)processImageColoursWithNumAliases:(int)aliases {
    
    //Get min and max for each channel
    cl_float4 minC, maxC;
    cl_float4 *rawPixelsCl = (cl_float4 *)rawPixels;
    minC = maxC = rawPixelsCl[0];
    for (int i = 1; i < renderSize.width * renderSize.height; i++) {
        cl_float4 c = rawPixelsCl[i];
        //X
        if (c.x < minC.x) {
            minC.x = c.x;
        }
        if (c.x > maxC.x) {
            maxC.x = c.x;
        }
        //Y
        if (c.y < minC.y) {
            minC.y = c.y;
        }
        if (c.y > maxC.y) {
            maxC.y = c.y;
        }
        //Z
        if (c.z < minC.z) {
            minC.z = c.z;
        }
        if (c.z > maxC.z) {
            maxC.z = c.z;
        }
        //W
        if (c.w < minC.w) {
            minC.w = c.w;
        }
        if (c.w > maxC.w) {
            maxC.w = c.w;
        }
    }
    
#define HDR_SCALE_MIN 0.05f
#define HDR_SCALE_MAX 0.95f

    float scaleMin = aliases * HDR_SCALE_MIN;
    float scaleMax = aliases * HDR_SCALE_MAX;
    float max = (float)aliases;
    cl_float4 minScale, maxScale;
    minScale.x = minC.x < 0.0 ? scaleMin / (scaleMin - minC.x) : 1.0;
    minScale.y = minC.y < 0.0 ? scaleMin / (scaleMin - minC.y) : 1.0;
    minScale.z = minC.z < 0.0 ? scaleMin / (scaleMin - minC.z) : 1.0;
    minScale.w = minC.w < 0.0 ? scaleMin / (scaleMin - minC.w) : 1.0;
    maxScale.x = maxC.x > max ? (max - scaleMax) / (maxC.x - scaleMax) : 1.0;
    maxScale.y = maxC.y > max ? (max - scaleMax) / (maxC.y - scaleMax) : 1.0;
    maxScale.z = maxC.z > max ? (max - scaleMax) / (maxC.z - scaleMax) : 1.0;
    maxScale.w = maxC.w > max ? (max - scaleMax) / (maxC.w - scaleMax) : 1.0;

    cl_float4 minAdd, maxAdd;
    maxAdd.x = maxAdd.y = maxAdd.z = maxAdd.w = scaleMax;
    minAdd.x = fabsf(minC.x);
    minAdd.y = fabsf(minC.y);
    minAdd.z = fabsf(minC.z);
    minAdd.w = fabsf(minC.w);
    
    int err;
    
    cl_int width = renderSize.width;
    cl_int height = renderSize.height;
    cl_int maxNumRays = renderSize.width * renderSize.height;
    cl_image_format fmt;
    fmt.image_channel_order = CL_RGBA;
    fmt.image_channel_data_type = CL_FLOAT;
    cl_image_desc desc;
    desc.image_type = CL_MEM_OBJECT_IMAGE2D;
    desc.image_width = renderSize.width;
    desc.image_height = renderSize.height;
    desc.image_depth = 1;
    desc.image_row_pitch = 0;
    desc.image_slice_pitch = 0;
    desc.num_mip_levels = 0;
    desc.num_samples = 0;
    desc.buffer = NULL;
    
    cl_mem cl_image = clCreateImage(context, CL_MEM_READ_WRITE, &fmt, &desc, NULL, &err);
    if (!cl_image) {
        NSLog(@"Error: Failed to create scaling image buffer");
        return false;
    }
    cl_mem cl_imageIn = clCreateBuffer(context, CL_MEM_READ_WRITE, sizeof(cl_float4) * renderSize.width * renderSize.height, NULL, NULL);
    if (!cl_imageIn) {
        NSLog(@"Error: Failed to create image input buffer");
        return false;
    }
    err = clEnqueueWriteBuffer(queue, cl_imageIn, true, 0, sizeof(cl_float4) * renderSize.width * renderSize.height, rawPixels, 0, NULL, NULL);
    if (err != CL_SUCCESS) {
        NSLog(@"Error: Failed to copy image data to image input buffer");
        return false;
    }
    
    //Run scaling kernel
    err = clSetKernelArg(hdrScaleRGBA, 0, sizeof(cl_mem), &cl_image);
    err |= clSetKernelArg(hdrScaleRGBA, 1, sizeof(cl_mem), &cl_imageIn);
    err |= clSetKernelArg(hdrScaleRGBA, 2, sizeof(cl_int), &width);
    err |= clSetKernelArg(hdrScaleRGBA, 3, sizeof(cl_float4), &minScale);
    err |= clSetKernelArg(hdrScaleRGBA, 4, sizeof(cl_float4), &minAdd);
    err |= clSetKernelArg(hdrScaleRGBA, 5, sizeof(cl_float4), &maxScale);
    err |= clSetKernelArg(hdrScaleRGBA, 6, sizeof(cl_float4), &maxAdd);
    err |= clSetKernelArg(hdrScaleRGBA, 7, sizeof(cl_int), &aliases);
    err |= clSetKernelArg(hdrScaleRGBA, 8, sizeof(cl_int), &maxNumRays);
    
    if (err != CL_SUCCESS) {
        NSLog(@"Error: Failed to set scaling kernel arguments");
        return false;
    }
    
    size_t global[1], local[1];
    int wgs;
    wgs = runningOnGPU ? kWGSGPU : kWGSCPU;
    global[0] = wgs * ceil((float)numPixels / (float)wgs);
    local[0] = wgs;

    err = clEnqueueNDRangeKernel(queue, hdrScaleRGBA, 1, NULL, global, local, 0, NULL, NULL);
    if (err != CL_SUCCESS) {
        NSLog(@"Error: Failed to execute scaling kernel");
        return false;
    }
    clFinish(queue);
    
    //Finally convert float image data to 32 bit
    err = clSetKernelArg(convertToARGB_32Bit, 0, sizeof(cl_mem), &cl_pixelsOut);
    err |= clSetKernelArg(convertToARGB_32Bit, 1, sizeof(cl_mem), &cl_image);
    err |= clSetKernelArg(convertToARGB_32Bit, 2, sizeof(cl_int), &width);
    err |= clSetKernelArg(convertToARGB_32Bit, 3, sizeof(cl_int), &maxNumRays);
    
    if (err != CL_SUCCESS) {
        NSLog(@"Error: Failed to set arguments for colour conversion kernel");
        return false;
    }
    
    err = clEnqueueNDRangeKernel(queue, convertToARGB_32Bit, 1, NULL, global, local, 0, NULL, NULL);
    
    clFinish(queue);
    
    err = clEnqueueReadBuffer(queue, cl_pixelsOut, true, 0, pixelsOutSize, pixelsOut, 0, NULL, NULL );
    if (err)
    {
        printf("Error: Failed to read back results from the device!\n");
        return false;
    }
    clFinish(queue);

    clReleaseMemObject(cl_imageIn);
    clReleaseMemObject(cl_image);
    
    return true;
}

- (BOOL)sumImage1:(cl_mem)i1 andImage2:(cl_mem)i2 andStoreIn:(cl_mem)outImage width:(cl_int)w executionLimit:(cl_int)max global:(size_t *)g local:(size_t *)l {

    int err;
    
    err = clSetKernelArg(sumImages, 0, sizeof(cl_mem), &outImage);
    err |= clSetKernelArg(sumImages, 1, sizeof(cl_mem), &i1);
    err |= clSetKernelArg(sumImages, 2, sizeof(cl_mem), &i2);
    err |= clSetKernelArg(sumImages, 3, sizeof(cl_int), &w);
    err |= clSetKernelArg(sumImages, 4, sizeof(cl_int), &max);
    
    if (err != CL_SUCCESS) {
        NSLog(@"Error: Failed to set arguments for image summing kernel");
        return false;
    }
    
    err = clEnqueueNDRangeKernel(queue, sumImages, 1, NULL, g, l, 0, NULL, NULL);
    
    if (err != CL_SUCCESS) {
        NSLog(@"Error: Failed to execute sum images kernel");
        return false;
    }

    return true;
}

- (BOOL)renderImage {
    int err;
    cl_float4 rayOrigin = camera.viewOriginRayStart;
    cl_float4 lookAtPoint = camera.clookAtPoint;
    cl_float4 upOrientation = camera.cUpOrientation;
    cl_int aaQuality = kaaQuality;
    cl_int width = renderSize.width;
    cl_int height = renderSize.height;
    cl_float cameraWidth = camera.viewWidth;
    cl_float cameraAperture = camera.aperture;
    cl_float cameraFocalLength = camera.focalLength;
    cl_float cameraLensLength = camera.lensLength;
    cl_int maxNumRays = renderSize.width * renderSize.height;
    err = clSetKernelArg(kernel,  0, sizeof(cl_mem), &cl_pixelsOut);
    err |= clSetKernelArg(kernel, 1, sizeof(startPixel), &startPixel);
    err |= clSetKernelArg(kernel, 2, sizeof(cl_float4), &rayOrigin);
    err |= clSetKernelArg(kernel, 3, sizeof(cl_float4), &lookAtPoint);
    err |= clSetKernelArg(kernel, 4, sizeof(cl_float4), &upOrientation);
    err |= clSetKernelArg(kernel, 5, sizeof(cl_int), &aaQuality);
    err |= clSetKernelArg(kernel, 6, sizeof(cl_int), &width);
    err |= clSetKernelArg(kernel, 7, sizeof(cl_int), &height);
    err |= clSetKernelArg(kernel, 8, sizeof(cl_float), &cameraWidth);
    err |= clSetKernelArg(kernel, 9, sizeof(cl_float), &cameraAperture);
    err |= clSetKernelArg(kernel, 10, sizeof(cl_float), &cameraFocalLength);
    err |= clSetKernelArg(kernel, 11, sizeof(cl_float), &cameraLensLength);
    err |= clSetKernelArg(kernel, 12, sizeof(cl_mem), &cl_atomDataIn);
    err |= clSetKernelArg(kernel, 13, sizeof(cl_ulong), &worldNumModelData);
//    err |= clSetKernelArg(kernel, 14, sizeof(cl_mem), &cl_bvhIn);
//    err |= clSetKernelArg(kernel, 15, sizeof(cl_mem), &cl_bvhLookUpDataIn);
    err |= clSetKernelArg(kernel, 14, sizeof(cl_mem), &cl_tree);
    err |= clSetKernelArg(kernel, 15, sizeof(cl_mem), &cl_treeLookup);
    err |= clSetKernelArg(kernel, 16, sizeof(cl_float4), &cl_ambientLight);
    err |= clSetKernelArg(kernel, 17, sizeof(cl_int), &sceneNumLights);
    err |= clSetKernelArg(kernel, 18, sizeof(cl_mem), &cl_lightsIn);
    err |= clSetKernelArg(kernel, 19, sizeof(cl_int), &numIntrinsicLights);
    err |= clSetKernelArg(kernel, 20, sizeof(cl_mem), &cl_intrinsicLightsIn);
    err |= clSetKernelArg(kernel, 21, sizeof(cl_int), &maxNumRays);
    
    if (err != CL_SUCCESS)
    {
        printf("Error: Failed to set kernel arguments!\n");
        return false;
    }

    size_t global[1], local[1];
    int wgs;
    wgs = runningOnGPU ? kWGSGPU : kWGSCPU;
    global[0] = wgs * ceil((float)numPixels / (float)wgs);
    local[0] = wgs;
    
//    NSLog(@"Starting Renderer");
    err = clEnqueueNDRangeKernel(queue, kernel, 1, NULL, global, local, 0, NULL, NULL);
    if (err)
    {
        printf("Error: Failed to execute kernel!\n");
        return false;
    }
    clFinish(queue);
//    NSLog(@"Rendering finished");
    
    err = clEnqueueReadBuffer(queue, cl_pixelsOut, true, 0, pixelsOutSize, pixelsOut, 0, NULL, NULL );
    if (err)
    {
        printf("Error: Failed to read back results from the device!\n");
        return false;
    }
    
    return true;
}

- (void)saveImage {
    NSBitmapImageRep *rep = [[NSBitmapImageRep alloc]
                             initWithBitmapDataPlanes: nil  // allocate the pixel buffer for us
                             pixelsWide: renderSize.width
                             pixelsHigh: renderSize.height
                             bitsPerSample: 8
                             samplesPerPixel: 4
                             hasAlpha: YES
                             isPlanar: NO
                             colorSpaceName: @"NSCalibratedRGBColorSpace"
                             bytesPerRow: renderSize.width * 4     // passing 0 means "you figure it out"
                             bitsPerPixel: 32];   // this must agree with bitsPerSample and samplesPerPixel
    
        
    for (int i = 0; i < renderSize.height; i++ )
    {
        for (int j = 0; j < renderSize.width; j++ )
        {
            NSUInteger colourArray[4] = {pixelsOut[4 * (i * (int)renderSize.width + j) + 1], pixelsOut[4 * (i * (int)renderSize.width + j) + 2], pixelsOut[4 * (i * (int)renderSize.width + j) + 3], pixelsOut[4 * (i * (int)renderSize.width + j)]};
            
            [rep setPixel:colourArray atX:j y:i];
        }
    }
    
    
    NSLog(@"Finished frame ");
    
    NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:NSImageInterlaced];
    NSData *pngRep = [rep representationUsingType:NSPNGFileType properties:options];
    [pngRep writeToFile:@"/Users/stocklab/Documents/Callum/rt1NG/output.png" atomically:YES];
}

- (void)releaseData {
    clReleaseMemObject(cl_entropyPool);
    clReleaseMemObject(cl_intrinsicRaysNeeded);
    clReleaseMemObject(cl_intrinsicRayIndex);
    clReleaseMemObject(cl_intrinsicLightRays);
    clReleaseMemObject(cl_intrinsicLightRayTValuesImage);
    clReleaseMemObject(cl_intrinsicSum);
    clReleaseMemObject(cl_intersection);
    clReleaseMemObject(cl_intersectionScan);
    
    clReleaseMemObject(cl_intersectionPoints);
    clReleaseMemObject(cl_intersectionNormals);
    clReleaseMemObject(cl_intersectionIndex);
    clReleaseMemObject(cl_intersectionObjectIds);
    clReleaseMemObject(cl_intersectionTValues);
    clReleaseMemObject(cl_intersectionRays);
    clReleaseMemObject(cl_sceneLightRays);
    clReleaseMemObject(cl_sceneLightRayTValues);
    clReleaseMemObject(cl_Image);
    clReleaseMemObject(cl_intrinsicObjectImage);
    clReleaseMemObject(cl_intrinsicLightImage);
    clReleaseMemObject(cl_intrinsicIntersectionLightBuffer);
    clReleaseMemObject(cl_mask);
    clReleaseMemObject(cl_blurOut);
    clReleaseMemObject(cl_blurOut1);
    clReleaseMemObject(cl_blurOut2);
    clReleaseMemObject(cl_summedImage);

    clReleaseMemObject(cl_pixelsOut);
    clReleaseMemObject(cl_atomDataIn);
    clReleaseMemObject(cl_bvhLookUpDataIn);
    clReleaseMemObject(cl_bvhIn);
    clReleaseMemObject(cl_lightsIn);
    clReleaseKernel(kernel);
    clReleaseProgram(program);
    clReleaseCommandQueue(queue);
    clReleaseContext(context);
}

@end
