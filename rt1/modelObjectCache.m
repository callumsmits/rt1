//
//  modelObjectCache.m
//  rt1
//
//  Created by Stock Lab on 18/07/2014.
//  Copyright (c) 2014 a. All rights reserved.
//

#import "modelObjectCache.h"
#import "vector_ops.h"

@interface modelObjectCache () {
    octree *_worldOctree;
    unsigned int _octreeSize, _octreeLookupSize;
    unsigned int *_octreeLookup;
    dispatch_group_t _dispatch_group;
    NSMutableArray *_semaphoreArray;
}

- (octree *)createOctreeWithSize:(unsigned int *)size lookupTable:(unsigned int **)lookup lookupTableSize:(unsigned int *)tableSize;
- (void)partitionOctree:(octree *)tree minCorner:(Vector)min maxCorner:(Vector)max maxDepth:(int)maxDepth depth:(int)depth currentNode:(unsigned int)node;
- (void)addAtomWithPosition:(Vector)pos radius:(float)radius atomId:(int)atomId toTree:(octree *)tree currentNode:(unsigned int)node leafBaseNodeIndex:(int)leafBaseNodeIndex atomArrays:(NSMutableArray *)arrays;
- (void)constructOctree;
@end

static NSString *vocrdKey = @"vocrd";
static NSString *vocrsKey = @"vocrs";
static NSString *vorsKey = @"vors";
static NSString *clapKey = @"clap";
static NSString *cupoKey = @"cupo";
static NSString *hcKey = @"hc";
static NSString *hlKey = @"hl";
static NSString *hsdfcKey = @"hsdfc";
static NSString *vwKey = @"vw";
static NSString *aKey = @"a";
static NSString *flKey = @"fl";
static NSString *llKey = @"ll";
static NSString *cpeKey = @"cpe";
static NSString *cpdfcKey = @"cpdfc";
static NSString *nmdKey = @"nmd";
static NSString *nilKey = @"nil";
static NSString *tmdKey = @"tmd";
static NSString *tilKey = @"til";
static NSString *alKey = @"al";
static NSString *laKey = @"la";
static NSString *nlKey = @"nl";

@implementation modelObjectCache

@synthesize numIntrinsicLights, numModelData, transformedIntrinsicLights, transformedModelData, treeImage, treeData;
@synthesize viewOriginCentralRayDirection, viewOriginCentralRayStart, viewOriginRayStart, clookAtPoint, cUpOrientation, hazeColour, hazeLength, hazeStartDistanceFromCamera;
@synthesize viewWidth, aperture, focalLength, lensLength, clipPlaneDistanceFromCamera, clipPlaneEnabled, ambient_light, numLights;

- (int)octreeSize {
    return _octreeSize;
}

- (int)octreeLookupSize {
    return _octreeLookupSize;
}

- (LightSourceDef *) light_sources {
    return light_sources;
}

- (id)initNoOctreeWithModelObject:(modelObject *)input camera:(cameraObject *)c sceneController:(sceneController *)sc {
    if (self = [super init]) {
        //Camera cache
        self.viewOriginCentralRayDirection = c.viewOriginCentralRayDirection;
        self.viewOriginCentralRayStart = c.viewOriginCentralRayStart;
        self.viewOriginRayStart = c.viewOriginRayStart;
        self.clookAtPoint = c.clookAtPoint;
        self.cUpOrientation = c.cUpOrientation;
        self.hazeColour = c.hazeColour;
        self.hazeLength = c.hazeLength;
        self.hazeStartDistanceFromCamera = c.hazeStartDistanceFromCamera;
        self.viewWidth = c.viewWidth;
        self.aperture = c.aperture;
        self.focalLength = c.focalLength;
        self.lensLength = c.lensLength;
        self.clipPlaneEnabled = c.clipPlaneEnabled;
        self.clipPlaneDistanceFromCamera = c.clipPlaneDistanceFromCamera;
        
        //Model cache
        self.numModelData = input.numModelData;
        self.numIntrinsicLights = input.numIntrinsicLights;
        self.transformedModelData = (float *)malloc(sizeof(float) * NUM_ATOMDATA * numModelData);
        memcpy(transformedModelData, input.transformedModelData, sizeof(float) * NUM_ATOMDATA * numModelData);
        self.transformedIntrinsicLights = (float *)malloc(sizeof(float) * NUM_INTRINSIC_LIGHT_DATA * numIntrinsicLights);
        memcpy(transformedIntrinsicLights, input.transformedIntrinsicLights, sizeof(float) * NUM_INTRINSIC_LIGHT_DATA * numIntrinsicLights);
        
        //Light cache
        self.ambient_light = sc.ambient_light;
        memcpy(light_sources, sc.light_sources, sizeof(LightSourceDef) * kMaxNumLights);
        self.numLights = sc.num_lights;
    }
    
    return self;
}

- (void)writeToFile:(NSString *)fileName {
    NSData *viewOriginCentralRayDirectionData = [NSData dataWithBytes:&viewOriginCentralRayDirection length:sizeof(viewOriginCentralRayDirection)];
    NSData *viewOriginCentralRayStartData = [NSData dataWithBytes:&viewOriginCentralRayStart length:sizeof(viewOriginCentralRayStart)];
    NSData *viewOriginRayStartData = [NSData dataWithBytes:&viewOriginRayStart length:sizeof(viewOriginRayStart)];
    NSData *clookAtPointData = [NSData dataWithBytes:&clookAtPoint length:sizeof(clookAtPoint)];
    NSData *cUpOrientationData = [NSData dataWithBytes:&cUpOrientation length:sizeof(cUpOrientation)];
    NSData *hazeColourData = [NSData dataWithBytes:&hazeColour length:sizeof(hazeColour)];
    NSNumber *hazeLengthNumber = [NSNumber numberWithFloat:hazeLength];
    NSNumber *hazeStartDistanceFromCameraNumber = [NSNumber numberWithFloat:hazeStartDistanceFromCamera];
    NSNumber *viewWidthNumber = [NSNumber numberWithFloat:viewWidth];
    NSNumber *apertureNumber = [NSNumber numberWithFloat:aperture];
    NSNumber *focalLengthNumber = [NSNumber numberWithFloat:focalLength];
    NSNumber *lensLengthNumber = [NSNumber numberWithFloat:lensLength];
    NSNumber *clipPlaneEnabledNumber = [NSNumber numberWithBool:clipPlaneEnabled];
    NSNumber *clipPlaneDistanceFromCameraNumber = [NSNumber numberWithFloat:clipPlaneDistanceFromCamera];
    NSNumber *numModelDataNumber = [NSNumber numberWithInt:numModelData];
    NSNumber *numIntrinsicLightsNumber = [NSNumber numberWithInt:numIntrinsicLights];
    NSData *modelData = [NSData dataWithBytes:transformedModelData length:sizeof(float) * NUM_ATOMDATA * numModelData];
    NSData *intrinsicLightData = [NSData dataWithBytes:transformedIntrinsicLights length:sizeof(float) * NUM_INTRINSIC_LIGHT_DATA * numIntrinsicLights];
    NSData *ambientLightData = [NSData dataWithBytes:&ambient_light length:sizeof(RGBColour)];
    NSData *lightSourcesData = [NSData dataWithBytes:light_sources length:sizeof(LightSourceDef) * kMaxNumLights];
    NSNumber *numLightsNumber = [NSNumber numberWithInt:numLights];
    
    NSDictionary *modelDictionary = [NSDictionary dictionaryWithObjectsAndKeys:viewOriginCentralRayDirectionData, vocrdKey,
                                    viewOriginCentralRayStartData, vocrsKey,
                                    viewOriginRayStartData, vorsKey,
                                    clookAtPointData, clapKey,
                                    cUpOrientationData, cupoKey,
                                    hazeColourData, hcKey,
                                    hazeLengthNumber, hlKey,
                                    hazeStartDistanceFromCameraNumber, hsdfcKey,
                                    viewWidthNumber, vwKey,
                                    apertureNumber, aKey,
                                    focalLengthNumber, flKey,
                                    lensLengthNumber, llKey,
                                    clipPlaneEnabledNumber, cpeKey,
                                    clipPlaneDistanceFromCameraNumber, cpdfcKey,
                                    numModelDataNumber, nmdKey,
                                    numIntrinsicLightsNumber, nilKey,
                                    modelData, tmdKey,
                                    intrinsicLightData, tilKey,
                                    ambientLightData, alKey,
                                    lightSourcesData, laKey,
                                    numLightsNumber, nlKey,
                                    nil];
    [modelDictionary writeToFile:fileName atomically:YES];
}

- (id)initWithFile:(NSString *)fileName {
    
    if (self = [super init]) {
        NSDictionary *modelDictionary = [NSDictionary dictionaryWithContentsOfFile:fileName];
        [[modelDictionary objectForKey:vocrdKey] getBytes:&viewOriginCentralRayDirection length:sizeof(viewOriginCentralRayDirection)];
        [[modelDictionary objectForKey:vocrsKey] getBytes:&viewOriginCentralRayStart length:sizeof(viewOriginCentralRayStart)];
        [[modelDictionary objectForKey:vorsKey] getBytes:&viewOriginRayStart length:sizeof(viewOriginRayStart)];
        [[modelDictionary objectForKey:clapKey] getBytes:&clookAtPoint length:sizeof(clookAtPoint)];
        [[modelDictionary objectForKey:cupoKey] getBytes:&cUpOrientation length:sizeof(cUpOrientation)];
        [[modelDictionary objectForKey:hcKey] getBytes:&hazeColour length:sizeof(hazeColour)];
        self.hazeStartDistanceFromCamera = [[modelDictionary objectForKey:hsdfcKey] floatValue];
        self.hazeLength = [[modelDictionary objectForKey:hlKey] floatValue];
        self.viewWidth = [[modelDictionary objectForKey:vwKey] floatValue];
        self.aperture = [[modelDictionary objectForKey:aKey] floatValue];
        self.focalLength = [[modelDictionary objectForKey:flKey] floatValue];
        self.lensLength = [[modelDictionary objectForKey:llKey] floatValue];
        self.clipPlaneEnabled = [[modelDictionary objectForKey:cpeKey] boolValue];
        self.clipPlaneDistanceFromCamera = [[modelDictionary objectForKey:cpdfcKey] floatValue];
        self.numModelData = [[modelDictionary objectForKey:nmdKey] intValue];
        self.numIntrinsicLights = [[modelDictionary objectForKey:nilKey] intValue];
        
        self.numLights = [[modelDictionary objectForKey:nlKey] intValue];
        [[modelDictionary objectForKey:alKey] getBytes:&ambient_light length:sizeof(RGBColour)];
        [[modelDictionary objectForKey:laKey] getBytes:light_sources length:sizeof(LightSourceDef) * kMaxNumLights];
        
        self.transformedModelData = (float *)malloc(sizeof(float) * NUM_ATOMDATA * numModelData);
        [[modelDictionary objectForKey:tmdKey] getBytes:transformedModelData length:sizeof(float) * NUM_ATOMDATA * numModelData];
        self.transformedIntrinsicLights = (float *)malloc(sizeof(float) * NUM_INTRINSIC_LIGHT_DATA * numIntrinsicLights);
        [[modelDictionary objectForKey:tilKey] getBytes:transformedIntrinsicLights length:sizeof(float) * NUM_INTRINSIC_LIGHT_DATA * numIntrinsicLights];

        [self constructOctree];
    }

    return self;
}

- (id)initWithModelObject:(modelObject *)input camera:(cameraObject *)c {
    
    if (self = [super init]) {
        //Camera cache
        self.viewOriginCentralRayDirection = c.viewOriginCentralRayDirection;
        self.viewOriginCentralRayStart = c.viewOriginCentralRayStart;
        self.viewOriginRayStart = c.viewOriginRayStart;
        self.clookAtPoint = c.clookAtPoint;
        self.cUpOrientation = c.cUpOrientation;
        self.hazeColour = c.hazeColour;
        self.hazeLength = c.hazeLength;
        self.hazeStartDistanceFromCamera = c.hazeStartDistanceFromCamera;
        self.viewWidth = c.viewWidth;
        self.aperture = c.aperture;
        self.focalLength = c.focalLength;
        self.lensLength = c.lensLength;
        self.clipPlaneEnabled = c.clipPlaneEnabled;
        self.clipPlaneDistanceFromCamera = c.clipPlaneDistanceFromCamera;
        
        //Model cache
        self.numModelData = input.numModelData;
        self.numIntrinsicLights = input.numIntrinsicLights;
        self.transformedModelData = (float *)malloc(sizeof(float) * NUM_ATOMDATA * numModelData);
        memcpy(transformedModelData, input.transformedModelData, sizeof(float) * NUM_ATOMDATA * numModelData);
        self.transformedIntrinsicLights = (float *)malloc(sizeof(float) * NUM_INTRINSIC_LIGHT_DATA * numIntrinsicLights);
        memcpy(transformedIntrinsicLights, input.transformedIntrinsicLights, sizeof(float) * NUM_INTRINSIC_LIGHT_DATA * numIntrinsicLights);
        
        [self constructOctree];
    }
    
    return self;
}

- (void)constructOctree {
    _dispatch_group = dispatch_group_create();
    _semaphoreArray = [NSMutableArray arrayWithCapacity:0];
    
    //        printf("Constructing Octree...");
    _worldOctree = [self createOctreeWithSize:&_octreeSize lookupTable:&_octreeLookup lookupTableSize:&_octreeLookupSize];
    
    int imageHeight = (_octreeSize * 2) / kSamplerMaxWidth + 1;
    if (imageHeight < 2) {
        imageHeight = 2;
    }
    //        int treeHeight = imageHeight;
    self.treeImage = (octreeImage *)malloc(sizeof(octreeImage) * kSamplerMaxWidth * imageHeight);
    for (int i = 0; i < _octreeSize; i++) {
        treeImage[i].x = _worldOctree[i].position.x;
        treeImage[i].y = _worldOctree[i].position.y;
        treeImage[i].z = _worldOctree[i].position.z;
        treeImage[i].radius = _worldOctree[i].radius;
        treeImage[i].hit = _worldOctree[i].hit;
        treeImage[i].miss = _worldOctree[i].miss;
        treeImage[i].start = _worldOctree[i].leafStart;
        treeImage[i].numMembers = _worldOctree[i].leafMembers;
    }
    
    imageHeight = (_octreeLookupSize * 2) / kSamplerMaxWidth + 1;
    if (imageHeight < 2) {
        imageHeight = 2;
    }
    self.treeData = (octreeData *)malloc(sizeof(octreeData) * kSamplerMaxWidth * imageHeight);
    for (int i = 0; i < _octreeLookupSize; i++) {
        unsigned int atomIndex = _octreeLookup[i];
        float *atom = transformedModelData + NUM_ATOMDATA * atomIndex;
        treeData[i].position.x = *(atom + X);
        treeData[i].position.y = *(atom + Y);
        treeData[i].position.z = *(atom + Z);
        treeData[i].position.w = *(atom + VDW);
        treeData[i].radius = *(atom + VDW);
        treeData[i].id = atomIndex;
        treeData[i].clipApplied = *(atom + CLIP_APPLIED);
        //            printf("i: %d, clipfloat: %.2f, clip: %u\n", i, *(atom + CLIP_APPLIED), treeData[i].clipApplied);
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

/*- (void)addAtomWithPosition:(Vector)pos radius:(float)radius atomId:(int)atomId toTree:(octree *)tree currentNode:(unsigned int)node leafBaseNodeIndex:(int)leafBaseNodeIndex atomArrays:(NSMutableArray *)arrays {
    
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
}*/

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

- (int)sumLeavesOfTree:(octree *)tree currentNode:(unsigned int)node {
    
    if (tree[node].leafNode) {
        tree[node].leafMembersSum = tree[node].leafMembers;
    } else {
        int sum = 0;
        for (int i = 0; i < 8; i++) {
            sum += [self sumLeavesOfTree:tree currentNode:tree[node].hit + i];
            tree[node].leafMembersSum = sum;
        }
    }
    
    return tree[node].leafMembersSum;

}

- (void)optimiseTree:(octree *)tree currentNode:(unsigned int)node {
    unsigned int currentNode = node;
    while (currentNode != UINT32_MAX) {
        unsigned int nextNode = tree[currentNode].hit;
        while ((nextNode != UINT32_MAX) && (tree[nextNode].leafMembersSum == 0)) {
            nextNode = tree[nextNode].miss;
        }
        tree[currentNode].hit = nextNode;
        currentNode = nextNode;
    }
}

- (octree *)createOctreeWithSize:(unsigned int *)size lookupTable:(unsigned int **)lookup lookupTableSize:(unsigned int *)tableSize {
    //Find the depth of the tree
    int d = 1;
    while (powf(8, d+1) < numModelData) {
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
    for (int i = 0; i < numModelData; i++) {
        float *atom = transformedModelData + NUM_ATOMDATA * i;
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
        _semaphoreArray = [NSMutableArray arrayWithCapacity:leafNodes];
        recreateSemaphores = YES;
    }
    for (int i = 0; i < leafNodes; i++) {
        [atomIndexArrays addObject:[NSMutableArray arrayWithCapacity:0]];
        if (recreateSemaphores) {
            [_semaphoreArray addObject:dispatch_semaphore_create(1)];
        }
    }
    
    dispatch_semaphore_t jobSemaphore = dispatch_semaphore_create(8);
    
    for (int i = 0; i < numModelData; i++) {
        dispatch_semaphore_wait(jobSemaphore, DISPATCH_TIME_FOREVER);
        dispatch_group_async(_dispatch_group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
            float *atom = transformedModelData + NUM_ATOMDATA * i;
            Vector pos;
            float radius;
            pos.x = *(atom + X);
            pos.y = *(atom + Y);
            pos.z = *(atom + Z);
            pos.w = 1.0;
            radius = *(atom + VDW);
            [self addAtomWithPosition:pos radius:radius atomId:i toTree:new currentNode:0 leafBaseNodeIndex:prevNodes atomArrays:atomIndexArrays];
            dispatch_semaphore_signal(jobSemaphore);
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
    
//    int totalmembers = [self sumLeavesOfTree:new currentNode:0];
//    [self optimiseTree:new currentNode:0];
    
    *tableSize = indexSize;
    *lookup = index;
    *size = n;
    return new;
}

- (void)dealloc {
    if (transformedModelData) {
        free(transformedModelData);
    }
    if (transformedIntrinsicLights) {
        free(transformedIntrinsicLights);
    }
    if (_worldOctree) {
        free(_worldOctree);
    }
    if (_octreeLookup) {
        free(_octreeLookup);
    }
    if (treeImage) {
        free(treeImage);
    }
    if (treeData) {
        free(treeData);
    }
    
}

@end

