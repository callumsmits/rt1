//
//  cameraObject.h
//  present
//
//  Created by Callum Smits on 11/07/13.
//  Copyright (c) 2013 Callum Smits. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenCL/OpenCL.h>
#import "typedefs.h"
#import "modelObject.h"

@interface cameraObject : NSObject {
    Vector viewOrigin;
    Vector lookAtPoint;
    Vector upOrientation;
    Vector viewDirection;
    float viewWidth;
    float aspectRatio;
    float lensLength;
    float aperture;
    float focalLength;
    bool viewRaysChanged;
    int totalNumRays;
    int actualNumRays;
    cl_float hazeStartDistanceFromCamera;
    cl_float hazeLength;
    cl_float4 hazeColour;
    cl_float4 viewOriginRayStart, clookAtPoint, cUpOrientation;
    cl_float4 viewOriginCentralRayStart, viewOriginCentralRayDirection;
    void *cl_viewOriginRayDirectionsArray;
    cl_uint clipPlaneEnabled;
    cl_float clipPlaneDistanceFromCamera;
    CGSize windowSize;
}

@property (nonatomic) Vector viewOrigin;
@property (nonatomic) Vector lookAtPoint;
@property (nonatomic) Vector upOrientation;
@property (nonatomic) bool viewRaysChanged;
@property (nonatomic) void *cl_viewOriginRayDirectionsArray;
@property (nonatomic) float aperture;
@property (nonatomic) float focalLength;
@property (nonatomic) float lensLength;
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
@property (nonatomic) int totalNumRays;
@property (nonatomic) int actualNumRays;
@property (nonatomic) float viewWidth;


- (id)initWithCameraOrigin:(Vector)origin lookAt:(Vector)destination upOrientation:(Vector)up windowSize:(CGSize)size viewWidth:(float)width lensLength:(float)length aperture:(float)newAperture focalLength:(float)newFocalLength;
- (void)setLookAtPoint:(Vector)destination withRayCalculations:(bool)recalculate;
- (void)setCameraOrigin:(Vector)origin withRayCalculations:(bool)recalculate;
- (void)setUpOrientation:(Vector)up withRayCalculations:(bool)recalculate;
- (void)setViewWidth:(float)width withRayCalculations:(bool)recalculate;
- (void)setLensLength:(float)length withRayCalculations:(bool)recalculate;
- (void)setWindowSize:(CGSize)size withRayCalculations:(bool)recalculate;
- (void)animateViewOriginTranslationTo:(Vector)end intermediate1:(Vector)i1 intermediate2:(Vector)i2 duration:(int)numFrames;
- (bool)calculateCameraAnimationWithFrame:(int)frame;
- (void)animateViewLookAtTranslationTo:(Vector)end duration:(int)numFrames;
- (void)animateUpOrientationTo:(Vector)end duration:(int)numFrames;
- (void)animateLensLengthTo:(float)end duration:(int)numFrames;
- (void)animateApertureTo:(float)end duration:(int)numFrames;
- (void)animateFocalLenghTo:(float)end duration:(int)numFrames;
- (void)animateClipPlaneTo:(float)end duration:(int)numFrames;
- (void)animateFollowModelObject:(modelObject *)model parent:(modelObject *)parent world:(modelObject *)world distanceFromCentreOfMass:(float)distance;

@end
