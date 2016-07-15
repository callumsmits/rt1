//
//  modelObjectCache.h
//  rt1
//
//  Created by Stock Lab on 18/07/2014.
//  Copyright (c) 2014 a. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "modelObject.h"
#import "rendererObject.h"
#import "cameraObject.h"
#import "sceneController.h"

@interface modelObjectCache : NSObject {
    NSMutableArray *transformedBvhObjects;
    float *transformedModelData;
    int numModelData;
    int numIntrinsicLights;
    float *transformedIntrinsicLights;
    octreeImage *treeImage;
    octreeData *treeData;
    cl_float hazeStartDistanceFromCamera;
    cl_float hazeLength;
    cl_float4 hazeColour;
    cl_float4 viewOriginRayStart, clookAtPoint, cUpOrientation;
    cl_float4 viewOriginCentralRayStart, viewOriginCentralRayDirection;
    cl_uint clipPlaneEnabled;
    cl_float clipPlaneDistanceFromCamera;
    float viewWidth;
    float lensLength;
    float aperture;
    float focalLength;
    LightSourceDef light_sources[kMaxNumLights];
    RGBColour ambient_light;
    int numLights;
}

@property (nonatomic) float *transformedModelData;
@property (nonatomic) int numModelData;
@property (nonatomic) int numIntrinsicLights;
@property (nonatomic) float *transformedIntrinsicLights;
@property (nonatomic) octreeImage *treeImage;
@property (nonatomic) octreeData *treeData;
@property (nonatomic) cl_float4 viewOriginRayStart;
@property (nonatomic) cl_float4 viewOriginCentralRayStart;
@property (nonatomic) cl_float4 viewOriginCentralRayDirection;
@property (nonatomic) cl_float4 clookAtPoint;
@property (nonatomic) cl_float4 cUpOrientation;
@property (nonatomic) cl_float hazeStartDistanceFromCamera;
@property (nonatomic) cl_float hazeLength;
@property (nonatomic) cl_float4 hazeColour;
@property (nonatomic) cl_uint clipPlaneEnabled;
@property (nonatomic) cl_float clipPlaneDistanceFromCamera;
@property (nonatomic) float aperture;
@property (nonatomic) float focalLength;
@property (nonatomic) float lensLength;
@property (nonatomic) float viewWidth;
@property (nonatomic) RGBColour ambient_light;
@property (nonatomic) int numLights;

- (id)initWithModelObject:(modelObject *)input camera:(cameraObject *)c;
- (id)initNoOctreeWithModelObject:(modelObject *)input camera:(cameraObject *)c sceneController:(sceneController *)sc;
- (int)octreeSize;
- (int)octreeLookupSize;
- (void)writeToFile:(NSString *)fileName;
- (id)initWithFile:(NSString *)fileName;
- (LightSourceDef *)light_sources;

@end
