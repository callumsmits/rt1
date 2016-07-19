//
//  renderManager.m
//  rt1
//
//  Created by Stock Lab on 19/05/2014.
//  Copyright (c) 2014 a. All rights reserved.
//

#import "renderManager.h"
#import "rendererObject.h"
#include <AppKit/AppKit.h>
#include <mach/mach_time.h>
#include "vector_ops.h"

#define kNoAvailableRenderer -1

#define kMonolithicUseGPU 1


@interface renderManager () {
    NSMutableArray *_renderers;
    NSMutableArray *_imageData;
    octree *_worldOctree;
    unsigned int _octreeSize, _octreeLookupSize;
    unsigned int *_octreeLookup;
    dispatch_group_t _dispatch_group;
    cl_float4 *rawPixelAccumulator;
    NSMutableArray *_semaphoreArray;
}

@property (nonatomic, strong) NSMutableArray *_renderers;
@property (nonatomic, strong) NSMutableArray *_imageData;
@property (nonatomic, strong) NSMutableArray *_semaphoreArray;

- (int)getNextAvailableRenderer;
- (octree *)createOctreeWithWorld:(modelObject *)world size:(unsigned int *)size lookupTable:(unsigned int **)lookup lookupTableSize:(unsigned int *)tableSize;
- (void)printOctree:(octree *)tree size:(int)size;
- (void)printOctreeLookup:(unsigned int *)lookup size:(unsigned int)size;
- (void)partitionOctree:(octree *)tree minCorner:(Vector)min maxCorner:(Vector)max maxDepth:(int)maxDepth depth:(int)depth currentNode:(unsigned int)node;
- (void)addAtomWithPosition:(Vector)pos radius:(float)radius atomId:(int)atomId toTree:(octree *)tree currentNode:(unsigned int)node leafBaseNodeIndex:(int)leafBaseNodeIndex atomArrays:(NSMutableArray *)arrays;
@end

@implementation renderManager
@synthesize camera, renderSize;
@synthesize _renderers, _imageData, _semaphoreArray;

- (id)initWithImageSize:(NSSize)size deviceType:(cl_int)deviceType {
    if (self = [super init]) {
        self.camera = nil;
        self.renderSize = size;
        _worldOctree = NULL;
        _octreeLookup = NULL;
        _dispatch_group = dispatch_group_create();
        self._semaphoreArray = [NSMutableArray arrayWithCapacity:0];
        
        int err;
        cl_uint numDevices;
        cl_device_id device_id[kMaxNumDevices];
        
        err = clGetDeviceIDs(NULL, deviceType, kMaxNumDevices, device_id, &numDevices);
        if (err != CL_SUCCESS)
        {
            printf("Error: Failed to get a device list!\n");
            return nil;
        }
        
//        NSLog(@"Detected %u OpenCL devices", numDevices);
        
        dispatch_semaphore_t entropySemaphore = dispatch_semaphore_create(1);
        
        self._renderers = [NSMutableArray arrayWithCapacity:numDevices];
        int startDevice = numDevices == 2 ? 1 : 0;
//        int startDevice = 0;
        for (int i = startDevice; i < numDevices; i++) {
            rendererObject *r = [[rendererObject alloc] init];
            //            r.camera = c;
            r.entropySemaphore = entropySemaphore;
            r.renderSize = size;
            r.numPixels = (size.width * size.height) / numDevices;
            if (i == numDevices - 1) {
                r.numPixels = size.width * size.height - i * r.numPixels;
            }
            cl_device_type type;
            err = clGetDeviceInfo(device_id[i], CL_DEVICE_TYPE, sizeof(cl_device_type), &type, NULL);
            if (type == CL_DEVICE_TYPE_CPU) {
                r.runningOnGPU = NO;
            } else if (type == CL_DEVICE_TYPE_GPU) {
                r.runningOnGPU = YES;
            }
            r.startPixel = i * r.numPixels;
            r.sceneNumLights = kMaxNumLights;
            if ([r setupDevice:device_id[i]]) {
                [_renderers addObject:r];
//                NSLog(@"Device configured correctly");
            }
        }
        
        int pixelsOutSize = sizeof(cl_uchar4) * size.width * size.height;
        pixelsOut = malloc(pixelsOutSize);
        int rawPixelAccumulatorSize = sizeof(cl_float4) * size.width * size.height;
        rawPixelAccumulator = (cl_float4 *)malloc(rawPixelAccumulatorSize);
        
    }
    return self;
}

- (id)initWithImageSize:(NSSize)size {
    
    if (self = [super init]) {
        self.camera = nil;
        self.renderSize = size;
        _worldOctree = NULL;
        _octreeLookup = NULL;
        _dispatch_group = dispatch_group_create();
        self._semaphoreArray = [NSMutableArray arrayWithCapacity:0];
        
        int err;
        cl_uint numDevices;
        cl_device_id device_id[kMaxNumDevices];
        
        cl_int computeDeviceType;
        
        if (kMonolithicUseGPU == 1) {
            computeDeviceType = CL_DEVICE_TYPE_GPU;
        } else {
            computeDeviceType = CL_DEVICE_TYPE_CPU;
        }
        
        err = clGetDeviceIDs(NULL, computeDeviceType, kMaxNumDevices, device_id, &numDevices);
        if (err != CL_SUCCESS)
        {
            printf("Error: Failed to get a device list!\n");
            return nil;
        }
        
        NSLog(@"Detected %u OpenCL devices", numDevices);
        
        dispatch_semaphore_t entropySemaphore = dispatch_semaphore_create(1);

        self._renderers = [NSMutableArray arrayWithCapacity:numDevices];
        for (int i = 0; i < numDevices; i++) {
            rendererObject *r = [[rendererObject alloc] init];
//            r.camera = c;
            r.entropySemaphore = entropySemaphore;
            r.renderSize = size;
            r.numPixels = (size.width * size.height) / numDevices;
            if (i == numDevices - 1) {
                r.numPixels = size.width * size.height - i * r.numPixels;
            }
            cl_device_type type;
            err = clGetDeviceInfo(device_id[i], CL_DEVICE_TYPE, sizeof(cl_device_type), &type, NULL);
            if (type == CL_DEVICE_TYPE_CPU) {
                r.runningOnGPU = NO;
            } else if (type == CL_DEVICE_TYPE_GPU) {
                r.runningOnGPU = YES;
            }
            r.startPixel = i * r.numPixels;
            r.sceneNumLights = kMaxNumLights;
            if ([r setupDevice:device_id[i]]) {
                [_renderers addObject:r];
                NSLog(@"Device configured correctly");
            }
        }

        int pixelsOutSize = sizeof(cl_uchar4) * size.width * size.height;
        pixelsOut = malloc(pixelsOutSize);
        int rawPixelAccumulatorSize = sizeof(cl_float4) * size.width * size.height;
        rawPixelAccumulator = (cl_float4 *)malloc(rawPixelAccumulatorSize);
        
    }
    return self;
}

- (void)printOctree:(octree *)tree size:(int)size {
    for (int i = 0; i < size; i++) {
        printf("i: %d, pos: %.2f %.2f %.2f %.2f r: %.2f leaf: %d, hit: %u, miss: %u leafStart: %d leafMembers: %d\n", i, tree[i].position.x, tree[i].position.y, tree[i].position.z, tree[i].position.w, tree[i].radius, tree[i].leafNode, tree[i].hit, tree[i].miss, tree[i].leafStart, tree[i].leafMembers);
    }
}

- (void)printOctreeImage:(octreeImage *)tree size:(int)size {
    for (int i = 0; i < size; i++) {
        float *base = (float*)tree + i * 8;
        unsigned int *uiBase = (unsigned int *)tree + i * 8;
        printf("i: %d, pos: %.2f %.2f %.2f, radius: %.2f, hit: %u, miss: %u, start: %u, num: %u\n", i, *base, *(base + 1), *(base + 2), *(base + 3), *(uiBase + 4), *(uiBase + 5), *(uiBase + 6), *(uiBase + 7));
//        printf("i: %d, pos: %.2f %.2f %.2f, radius: %.2f, hit: %u, miss: %u, start: %u, num: %u\n", i, tree[i].x, tree[i].y, tree[i].z, tree[i].radius, tree[i].hit, tree[i].miss, tree[i].start, tree[i].numMembers);
    }
}

- (void)printOctreeImageData:(octreeData *)data size:(int)size {
    for (int i = 0; i < size; i++) {
        float *base = (float *)data + i * 8;
        unsigned int *uiBase = (unsigned int *)data + i * 8;
        printf("i: %d, Pos: %.2f, %.2f, %.2f, %.2f, Rad: %.2f, id: %u\n", i, *base, *(base + 1), *(base + 2), *(base + 3), *(base + 4), *(uiBase + 5));
    }
}

- (void)printOctreeLookup:(unsigned int *)lookup size:(unsigned int)size {
    for (int i = 0; i < size; i++) {
        printf("i: %d, l: %u\n", i, lookup[i]);
    }
}

- (void)partitionOctree:(octree *)tree minCorner:(Vector)min maxCorner:(Vector)max maxDepth:(int)maxDepth depth:(int)depth currentNode:(unsigned int)node {
    
    Vector center = vector_lerp(min, max, 0.5);
    center.w = 1;
    tree[node].position = center;
    tree[node].radius = vector_size(vector_subtract(center, min));
    
    if (depth < maxDepth) {
        //Assign children
        Vector newMin = min;
        Vector newMax = center;
        unsigned int newIndexBase = tree[node].hit;
        [self partitionOctree:tree minCorner:newMin maxCorner:newMax maxDepth:maxDepth depth:depth + 1 currentNode:newIndexBase];
        //X shift
        newMin = min;
        newMax = center;
        newMin.x = center.x;
        newMax.x = max.x;
        newIndexBase++;
        [self partitionOctree:tree minCorner:newMin maxCorner:newMax maxDepth:maxDepth depth:depth + 1 currentNode:newIndexBase];
        //Z shift
        newMin = min;
        newMax = center;
        newMin.z = center.z;
        newMax.z = max.z;
        newIndexBase++;
        [self partitionOctree:tree minCorner:newMin maxCorner:newMax maxDepth:maxDepth depth:depth + 1 currentNode:newIndexBase];
        //XZ shift
        newMin = min;
        newMax = center;
        newMin.x = center.x;
        newMax.x = max.x;
        newMin.z = center.z;
        newMax.z = max.z;
        newIndexBase++;
        [self partitionOctree:tree minCorner:newMin maxCorner:newMax maxDepth:maxDepth depth:depth + 1 currentNode:newIndexBase];
        //Y shift
        newMin = min;
        newMax = center;
        newMin.y = center.y;
        newMax.y = max.y;
        newIndexBase++;
        [self partitionOctree:tree minCorner:newMin maxCorner:newMax maxDepth:maxDepth depth:depth + 1 currentNode:newIndexBase];
        //YX shift
        newMin = min;
        newMax = center;
        newMin.x = center.x;
        newMax.x = max.x;
        newMin.y = center.y;
        newMax.y = max.y;
        newIndexBase++;
        [self partitionOctree:tree minCorner:newMin maxCorner:newMax maxDepth:maxDepth depth:depth + 1 currentNode:newIndexBase];
        //YZ shift
        newMin = min;
        newMax = center;
        newMin.y = center.y;
        newMax.y = max.y;
        newMin.z = center.z;
        newMax.z = max.z;
        newIndexBase++;
        [self partitionOctree:tree minCorner:newMin maxCorner:newMax maxDepth:maxDepth depth:depth + 1 currentNode:newIndexBase];
        //XYZ shift
        newMin = min;
        newMax = center;
        newMin.x = center.x;
        newMax.x = max.x;
        newMin.y = center.y;
        newMax.y = max.y;
        newMin.z = center.z;
        newMax.z = max.z;
        newIndexBase++;
        [self partitionOctree:tree minCorner:newMin maxCorner:newMax maxDepth:maxDepth depth:depth + 1 currentNode:newIndexBase];
    }
}

- (void)addAtomWithPositionOld:(Vector)pos radius:(float)radius atomId:(int)atomId toTree:(octree *)tree currentNode:(unsigned int)node leafBaseNodeIndex:(int)leafBaseNodeIndex atomArrays:(NSMutableArray *)arrays {

    if (node == UINT32_MAX) {
        return;
    }
    Vector currentNodePos = tree[node].position;
    float currentNodeRadius = tree[node].radius;
    float distanceToNode = vector_size(vector_subtract(pos, currentNodePos));
    if (distanceToNode < currentNodeRadius + radius) {
        if (!tree[node].leafNode) {
            [self addAtomWithPosition:pos radius:radius atomId:(int)atomId toTree:tree currentNode:tree[node].hit leafBaseNodeIndex:leafBaseNodeIndex atomArrays:arrays];
        } else {
            NSMutableArray *nodeArray = [arrays objectAtIndex:node - leafBaseNodeIndex];
            dispatch_semaphore_t nodeArraySemaphore = [_semaphoreArray objectAtIndex:node - leafBaseNodeIndex];
            dispatch_semaphore_wait(nodeArraySemaphore, DISPATCH_TIME_FOREVER);
            [nodeArray addObject:[NSNumber numberWithInt:atomId]];
            dispatch_semaphore_signal(nodeArraySemaphore);
            if (distanceToNode + radius < currentNodeRadius) {
                return;
            }
            [self addAtomWithPosition:pos radius:radius atomId:atomId toTree:tree currentNode:tree[node].miss leafBaseNodeIndex:leafBaseNodeIndex atomArrays:arrays];
        }
    } else {
            [self addAtomWithPosition:pos radius:radius atomId:(int)atomId toTree:tree currentNode:tree[node].miss leafBaseNodeIndex:leafBaseNodeIndex atomArrays:arrays];
    }
}

- (void)addAtomWithPosition:(Vector)pos radius:(float)radius atomId:(int)atomId toTree:(octree *)tree currentNode:(unsigned int)node leafBaseNodeIndex:(int)leafBaseNodeIndex atomArrays:(NSMutableArray *)arrays {
    
    unsigned int currentNode = node;
    while (currentNode != UINT32_MAX) {
        Vector currentNodePos = tree[currentNode].position;
        float currentNodeRadius = tree[currentNode].radius;
        float distanceToNode = vector_size(vector_subtract(pos, currentNodePos));
        if (distanceToNode < currentNodeRadius + radius) {
            if (!tree[currentNode].leafNode) {
                currentNode = tree[currentNode].hit;
                //                [self addAtomWithPosition:pos radius:radius atomId:(int)atomId toTree:tree currentNode:tree[node].hit leafBaseNodeIndex:leafBaseNodeIndex atomArrays:arrays];
            } else {
                NSMutableArray *nodeArray = [arrays objectAtIndex:currentNode - leafBaseNodeIndex];
                dispatch_semaphore_t nodeArraySemaphore = [_semaphoreArray objectAtIndex:currentNode - leafBaseNodeIndex];
                dispatch_semaphore_wait(nodeArraySemaphore, DISPATCH_TIME_FOREVER);
                [nodeArray addObject:[NSNumber numberWithInt:atomId]];
                dispatch_semaphore_signal(nodeArraySemaphore);
                if (distanceToNode + radius < currentNodeRadius) {
                    //                    return;
                    currentNode = UINT32_MAX;
                } else {
                    currentNode = tree[currentNode].miss;
                }
                //                [self addAtomWithPosition:pos radius:radius atomId:atomId toTree:tree currentNode:tree[node].miss leafBaseNodeIndex:leafBaseNodeIndex atomArrays:arrays];
            }
        } else {
            currentNode = tree[currentNode].miss;
            //            [self addAtomWithPosition:pos radius:radius atomId:(int)atomId toTree:tree currentNode:tree[node].miss leafBaseNodeIndex:leafBaseNodeIndex atomArrays:arrays];
        }
    }
}

- (octree *)createOctreeWithWorld:(modelObject *)world size:(unsigned int *)size lookupTable:(unsigned int **)lookup lookupTableSize:(unsigned int *)tableSize {
    //Find the depth of the tree
    int d = 1;
    while (powf(8, d+1) < world.numModelData) {
        d++;
    }
    
    //Calculate how many octree nodes are needed
    int n = 0;
    for (int i = 0; i <= d; i++) {
        n += (int)powf(8, i);
    }
    
    octree *new = (octree *)malloc(sizeof(octree) * n);
    
    //create links between nodes
    int nodes = 0, prevNodes = 0;
    for (int i = 0; i <= d; i++) {
        int layerNodes = (int)powf(8, i);
        for (int j = 0; j < layerNodes; j++) {
            if (i == d) {
                new[nodes + j].leafNode = YES;
                new[nodes + j].hit = nodes + j + 1;
                new[nodes + j].miss = nodes + j + 1;
            } else {
                new[nodes + j].leafNode = NO;
                new[nodes + j].hit = nodes + layerNodes + j * 8;
                new[nodes + j].miss = nodes + j + 1;
                new[nodes + j].leafMembers = 0;
            }
            if (j % 8 == 7) {
                new[nodes + j].miss = prevNodes + j / 8 + 1;
                if (i == d) {
                    new[nodes + j].hit = prevNodes + j / 8 + 1;
                }
            } else {
                new[nodes + j].miss = nodes + j + 1;
            }
            
        }
        new[nodes + layerNodes - 1].miss = -1;
        if (i == d) {
            new[nodes + layerNodes - 1].hit = -1;
        }
        prevNodes = nodes;
        nodes += layerNodes;
    }
    
    //Find data limits
    float xMin = 0, xMax = 0, yMin = 0, yMax = 0, zMin = 0, zMax = 0;
    for (int i = 0; i < world.numModelData; i++) {
        float *atom = world.transformedModelData + NUM_ATOMDATA * i;
        float x = *(atom + X);
        float y = *(atom + Y);
        float z = *(atom + Z);
        if (i == 0) {
            xMin = xMax = x;
            yMin = yMax = y;
            zMin = zMax = z;
        } else {
            if (x < xMin) {
                xMin = x;
            } else if (x > xMax) {
                xMax = x;
            }
            if (y < yMin) {
                yMin = y;
            } else if (y > yMax) {
                yMax = y;
            }
            if (z < zMin) {
                zMin = z;
            } else if (z > zMax) {
                zMax = z;
            }
        }
    }
    //Adjust the dimensions for the VDW radii
    xMin = xMin - 1.8;
    xMax = xMax + 1.8;
    yMin = yMin - 1.8;
    yMax = yMax + 1.8;
    zMin = zMin - 1.8;
    zMax = zMax + 1.8;

    Vector minCorner, maxCorner;
    minCorner.x = xMin; minCorner.y = yMin; minCorner.z = zMin; minCorner.w = 1.0;
    maxCorner.x = xMax; maxCorner.y = yMax; maxCorner.z = zMax; maxCorner.w = 1.0;
    
    [self partitionOctree:new minCorner:minCorner maxCorner:maxCorner maxDepth:d depth:0 currentNode:0];
    
    //Load data into the octree
    int leafNodes = (int)powf(8, d);
    NSMutableArray *atomIndexArrays = [NSMutableArray arrayWithCapacity:leafNodes];
    bool recreateSemaphores = NO;
    if ([_semaphoreArray count] != leafNodes) {
        self._semaphoreArray = [NSMutableArray arrayWithCapacity:leafNodes];
        recreateSemaphores = YES;
    }
    for (int i = 0; i < leafNodes; i++) {
        [atomIndexArrays addObject:[NSMutableArray arrayWithCapacity:0]];
        if (recreateSemaphores) {
            [_semaphoreArray addObject:dispatch_semaphore_create(1)];
        }
    }
    
    
    for (int i = 0; i < world.numModelData; i++) {
        dispatch_group_async(_dispatch_group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
            float *atom = world.transformedModelData + NUM_ATOMDATA * i;
            Vector pos;
            float radius;
            pos.x = *(atom + X);
            pos.y = *(atom + Y);
            pos.z = *(atom + Z);
            pos.w = 1.0;
            radius = *(atom + VDW);
            [self addAtomWithPosition:pos radius:radius atomId:i toTree:new currentNode:0 leafBaseNodeIndex:prevNodes atomArrays:atomIndexArrays];
        });
    }
    
    dispatch_group_wait(_dispatch_group, DISPATCH_TIME_FOREVER);
    
    //Convert the arrays into an index array
    int indexSize = 0;
    for (int i = 0; i < leafNodes; i++) {
        indexSize += [[atomIndexArrays objectAtIndex:i] count];
    }
    
    unsigned int *index = (unsigned int *)malloc(sizeof(unsigned int) * indexSize);
    int currentIndex = 0;
    for (int i = 0; i < leafNodes; i++) {
        new[prevNodes + i].leafStart = currentIndex;
        int startIndex = currentIndex;
        NSMutableArray *atomIndices = [atomIndexArrays objectAtIndex:i];
        for (int j = 0; j < [atomIndices count]; j++) {
            index[currentIndex] = (unsigned int)[[atomIndices objectAtIndex:j] integerValue];
            currentIndex++;
        }
        new[prevNodes + i].leafMembers = currentIndex - startIndex;
    }
    
    *tableSize = indexSize;
    *lookup = index;
    *size = n;
    return new;
}

- (void)loadModelDataFromWorld:(modelObject *)world {
    NSEnumerator *rEnum = [_renderers objectEnumerator];
    rendererObject *r;
    
    if (_worldOctree) {
        free(_worldOctree);
    }
    if (_octreeLookup) {
        free(_octreeLookup);
    }
    
    printf("Constructing Octree...");
    _worldOctree = [self createOctreeWithWorld:world size:&_octreeSize lookupTable:&_octreeLookup lookupTableSize:&_octreeLookupSize];
    
    int imageHeight = (_octreeSize * 2) / kSamplerMaxWidth + 1;
    if (imageHeight < 2) {
        imageHeight = 2;
    }
    int treeHeight = imageHeight;
    octreeImage *newTree = (octreeImage *)malloc(sizeof(octreeImage) * kSamplerMaxWidth * imageHeight);
    for (int i = 0; i < _octreeSize; i++) {
        newTree[i].x = _worldOctree[i].position.x;
        newTree[i].y = _worldOctree[i].position.y;
        newTree[i].z = _worldOctree[i].position.z;
        newTree[i].radius = _worldOctree[i].radius;
        newTree[i].hit = _worldOctree[i].hit;
        newTree[i].miss = _worldOctree[i].miss;
        newTree[i].start = _worldOctree[i].leafStart;
        newTree[i].numMembers = _worldOctree[i].leafMembers;
    }
    
    imageHeight = (_octreeLookupSize * 2) / kSamplerMaxWidth + 1;
    if (imageHeight < 2) {
        imageHeight = 2;
    }
    octreeData *newData = (octreeData *)malloc(sizeof(octreeData) * kSamplerMaxWidth * imageHeight);
    for (int i = 0; i < _octreeLookupSize; i++) {
        unsigned int atomIndex = _octreeLookup[i];
        float *atom = world.transformedModelData + NUM_ATOMDATA * atomIndex;
        newData[i].position.x = *(atom + X);
        newData[i].position.y = *(atom + Y);
        newData[i].position.z = *(atom + Z);
        newData[i].position.w = *(atom + VDW);
        newData[i].radius = *(atom + VDW);
        newData[i].id = atomIndex;
        newData[i].clipApplied = *(atom + CLIP_APPLIED);
    }
    
//    NSLog(@"Tree height: %d, Data height: %d", treeHeight, imageHeight);
//    [self printOctreeImage:newTree size:_octreeSize];
//    [self printOctreeImageData:newData size:_octreeLookupSize];
//    [self printOctree:_worldOctree size:_octreeSize];
//    [self printOctreeLookup:_octreeLookup size:_octreeLookupSize];
    while (r = [rEnum nextObject]) {;
        [r loadModelDataFromWorld:world];
//        [r loadOctree:_worldOctree treeSize:_octreeSize treeLookupData:_octreeLookup lookupSize:_octreeLookupSize];
        [r loadOctreeImage:newTree treeSize:_octreeSize dataImage:newData dataSize:_octreeLookupSize];
        r.camera = camera;
        r.world = world;
    }
    free(newTree);
    free(newData);
}

- (void)loadDataFromCache:(modelObjectCache *)cache {

    NSEnumerator *rEnum = [_renderers objectEnumerator];
    rendererObject *r;

    while (r = [rEnum nextObject]) {;
        [r loadModelDataFromWorld:(modelObject *)cache];
        //        [r loadOctree:_worldOctree treeSize:_octreeSize treeLookupData:_octreeLookup lookupSize:_octreeLookupSize];
        [r loadOctreeImage:cache.treeImage treeSize:[cache octreeSize] dataImage:cache.treeData dataSize:[cache octreeLookupSize]];
        r.camera = cache;
        r.world = (modelObject *)cache;
    }
}


- (void)loadLightDataFromArray:(LightSourceDef *)lightArray withAmbient:(RGBColour)ambient numLights:(int)numLights {
    NSEnumerator *rEnum = [_renderers objectEnumerator];
    rendererObject *r;
    
    while (r = [rEnum nextObject]) {
        [r loadLightDataFromArray:lightArray withAmbient:ambient numLights:numLights];
    }
}

- (int)getNextAvailableRenderer {
    
    for (int i = (int)[_renderers count]-1; i >= 0; i--) {
        if ([[_renderers objectAtIndex:i] available] == YES) {
            return i;
        }
    }
    
    return kNoAvailableRenderer;
}

- (BOOL)renderImage {
    rendererObject *r;
    
//    NSLog(@"Starting renderers...");
//    printf(" Starting renderers...\n");
    int currentAlias = 0;
    NSMutableArray *aliasImages = [NSMutableArray arrayWithCapacity:kaaQuality];

    while (currentAlias < kaaQuality) {
        int rendererNum = [self getNextAvailableRenderer];
        if (rendererNum != kNoAvailableRenderer) {
            printf("%.0f%% ", (float)currentAlias / (float)kaaQuality * 100.0f);
            r = [_renderers objectAtIndex:rendererNum];
            r.available = NO;
            currentAlias++;
            dispatch_queue_priority_t priority;
            priority = r.runningOnGPU == YES ? DISPATCH_QUEUE_PRIORITY_DEFAULT : DISPATCH_QUEUE_PRIORITY_LOW;
            dispatch_async(dispatch_get_global_queue(priority, 0), ^(void){
                r.startPixel = 0;
                r.numPixels = renderSize.width * renderSize.height;
//                if (r.runningOnGPU) {
//                    printf("G");
//                } else {
//                    printf("C");
//                }
//                [r renderImage];
                [r splitRender];
                cl_float4 *rawImage = (cl_float4 *)[r rawPixelBuffer];
                NSData *imageData = [NSData dataWithBytes:rawImage length:sizeof(cl_float4) * renderSize.width * renderSize.height];
                [aliasImages addObject:imageData];
                if (kTakeARest) {
                    usleep(500000);
                }
                r.available = YES;
            });
        }
//        printf("CP: %d, renderer: %d\n", currentPixel, rendererNum);
        usleep(2000);
    }
    
//    for (int i = 0; i < [_renderers count]; i++) {
//        r = [_renderers objectAtIndex:i];
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
//            success[i] = [r renderImage];
//            complete[i] = YES;
//        });
//    }
    
    bool jobsComplete = NO;
    while (!jobsComplete) {
        usleep(500);
        jobsComplete = YES;
        for (int i = 0; i < [_renderers count]; i++) {
            r = [_renderers objectAtIndex:i];
            jobsComplete &= r.available;
        }
    }

    NSEnumerator *imageEnum = [aliasImages objectEnumerator];
    NSData *image;
    memset(rawPixelAccumulator, 0, sizeof(cl_float4) * renderSize.width * renderSize.height);
    while (image = [imageEnum nextObject]) {
        cl_float4 *rawImage = (cl_float4 *)[image bytes];
        for (int i = 0; i < renderSize.width * renderSize.height; i++) {
            rawPixelAccumulator[i].x += rawImage[i].x;
            rawPixelAccumulator[i].y += rawImage[i].y;
            rawPixelAccumulator[i].z += rawImage[i].z;
            rawPixelAccumulator[i].w += rawImage[i].w;
        }
    }

    //Now copy the image data back to a device for final colour scaling
    int rendererNum = [self getNextAvailableRenderer];
    if (rendererNum != kNoAvailableRenderer) {
        r = [_renderers objectAtIndex:rendererNum];
        cl_float4 *rawImage = (cl_float4 *)[r rawPixelBuffer];
        memcpy(rawImage, rawPixelAccumulator, sizeof(cl_float4) * renderSize.width * renderSize.height);
        
        [r processImageColoursWithNumAliases:kaaQuality];
        
        unsigned char *pixelsFromRenderer = [r pixelBuffer];
        memcpy(pixelsOut, pixelsFromRenderer, renderSize.width * renderSize.height * 4);
        
    } else {
        NSLog(@"Error: No available renderer for final image processing");
        return false;
    }
    
    
//    int pixelsPerRender = (renderSize.width * renderSize.height) / [_renderers count];
//    for (int i = 0; i < [_renderers count]; i++) {
//        r = [_renderers objectAtIndex:i];
//        unsigned char *pixelsFromRenderer = [r pixelBuffer];
//        memcpy(pixelsOut + i * 4 * pixelsPerRender, pixelsFromRenderer, r.numPixels*4);
//    }
    
//    r = [_renderers objectAtIndex:1];
//    unsigned char *pixelsFromRenderer = [r pixelBuffer];
//    memcpy(pixelsOut, pixelsFromRenderer, renderSize.width * renderSize.height * 4);

//    NSLog(@"Rendering complete");
    printf("100%%\n");
    return true;
}

- (void)saveImage {
    NSString *outputBase = @kRenderOutputRoot;
    NSData *imageData = [NSData dataWithBytes:pixelsOut length:renderSize.width * renderSize.height * 4];
    [imageData writeToFile:[outputBase stringByAppendingString:@"output.dat"] atomically:YES];
    static int imageNum = 0;
    NSBitmapImageRep *repGen = [[NSBitmapImageRep alloc]
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
    
    NSBitmapImageRep *rep = [repGen bitmapImageRepByRetaggingWithColorSpace:[NSColorSpace sRGBColorSpace]];
    
    for (int i = 0; i < renderSize.height; i++ )
    {
        for (int j = 0; j < renderSize.width; j++ )
        {
            NSUInteger colourArray[4] = {pixelsOut[4 * (i * (int)renderSize.width + j) + 1], pixelsOut[4 * (i * (int)renderSize.width + j) + 2], pixelsOut[4 * (i * (int)renderSize.width + j) + 3], pixelsOut[4 * (i * (int)renderSize.width + j)]};
            
            [rep setPixel:colourArray atX:j y:i];
        }
    }
    
    
//    NSLog(@"Finished frame ");
    
    NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:NSImageInterlaced];
    NSData *pngRep = [rep representationUsingType:NSPNGFileType properties:options];
    [pngRep writeToFile:[outputBase stringByAppendingString:@"output.png"] atomically:YES];
    NSString *imageSeqName = [NSString stringWithFormat:[outputBase stringByAppendingString:@"images/output_%06d.png"], imageNum];
    [pngRep writeToFile:imageSeqName atomically:YES];
    imageNum++;
}

- (unsigned char *)pixelBuffer {
    return pixelsOut;
}

@end
