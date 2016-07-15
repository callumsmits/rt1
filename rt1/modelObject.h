//
//  modelObject.h
//  present
//
//  Created by Callum Smits on 11/07/13.
//  Copyright (c) 2013 Callum Smits. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "pdbData.h"
#import "typedefs.h"
#import "beizerCurve.h"

typedef enum _atomData
{
    X,
    Y,
    Z,
    VDW,
    DIFFUSE_R,
    DIFFUSE_G,
    DIFFUSE_B,
    SPEC_R,
    SPEC_G,
    SPEC_B,
    INTRINSIC_R,
    INTRINSIC_G,
    INTRINSIC_B,
    MIRROR_FRAC,
    SHININESS,
    CLIP_APPLIED,
    NUM_ATOMDATA
} atomData;

typedef enum _atomCoordData
{
    cX,
    cY,
    cZ,
    cVDW,
    NUM_ATOMCOORDDATA
} atomCoordData;

typedef enum _intrinsicLightData
{
    XI,
    YI,
    ZI,
    VDWI,
    RED,
    GREEN,
    BLUE,
    CUTOFF,
    MODE,
    NUM_INTRINSIC_LIGHT_DATA
} intrinsicLightData;

typedef enum _intrinsicLightModes {
    CRUDE_ONE_FACE,
    CRUDE_TWO_FACE,
    REAL_POINT_SOURCE,
    REAL_BROAD_SOURCE,
    NUM_INTRINSIC_LIGHT_MODES
} intrinsicLightModes;

@interface modelObject : NSObject {
    NSMutableArray *transformedBvhObjects;
    float *transformedModelData;
    int *transformedLookupData;
    bvhStruct *transformedBvhData;
    int numBVH;
    int numModelData;
    int numLookupData;
    int numIntrinsicLights;
    float *transformedIntrinsicLights;
    bool interModelAtomOverlapsAllowed;
}

@property (nonatomic,strong) NSMutableArray *transformedBvhObjects;
@property (nonatomic) float *transformedModelData;
@property (nonatomic) int *transformedLookupData;
@property (nonatomic) bvhStruct *transformedBvhData;
@property (nonatomic) int numBVH;
@property (nonatomic) int numModelData;
@property (nonatomic) int numLookupData;
@property (nonatomic) int numIntrinsicLights;
@property (nonatomic) float *transformedIntrinsicLights;
@property (nonatomic) bool interModelAtomOverlapsAllowed;
- (id)initWithPDBData:(pdbData *)newModel;
- (void)setModelWithPDBData:(pdbData *)newModel;
- (void)setName:(NSString *)name forChild:(modelObject *)child;
- (modelObject *)getChildWithName:(NSString *)name;
- (modelObject *)getChildClosestToPoint:(Vector)p;
- (void)addChildModel:(modelObject *)newChild;
- (modelObject *)addAndTransformIntoCoordSystemChildModel:(modelObject *)newChild;
- (void)deleteChildModel:(modelObject *)child;
- (void)deleteAndTransformOutOfCoordSystemChildModel:(modelObject *)child;
- (void)addParentModel:(modelObject *)parent;
- (void)deleteParentModel:(modelObject *)exParent;
- (void)addCircleOfModel:(modelObject *)originalModel numMembers:(int)num radius:(float)radius;
- (void)addCircleOfModel:(modelObject *)originalModel withAngleOffset:(float)startAngle numMembers:(int)num radius:(float)radius;
- (void)addGridOfModel:(modelObject *)originalModel xNumMembers:(int)xNum xSpacing:(float)xSpace zNumMembers:(int)zNum zSpacing:(float)zSpace;
- (void)addGridOfModel:(modelObject *)originalModel xNumMembers:(int)xNum xSpacing:(float)xSpace zNumMembers:(int)zNum zSpacing:(float)zSpace excludedPoint:(Vector)p withRadius:(float)exlusionRadius;
- (void)addParametricLineOfModel:(modelObject *)originalModel modelOrientation:(Vector)o spacing:(float)spacing offset:(float)offset bezierCurve:(beizerCurve *)curve;
- (void)addChildModel:(modelObject *)child onToCurve:(beizerCurve *)curve curveFraction:(float)f modelOrientation:(Vector)o modelAttachmentPoint:(Vector)p;
- (void)moveModelsToParametricLineWithModelOrientation:(Vector)o originalModel:(modelObject *)originalModel spacing:(float)spacing bezierCurve:(beizerCurve *)curve;
- (void)setupPoolOfModel:(modelObject *)child numModels:(int)numModels boundingCorner1:(Vector)c1 boundingCorner2:(Vector)c2 newModelEntryPoint:(Vector)entryPoint;
- (void)setupCurveBasedPoolOfModel:(modelObject *)child numModels:(int)numModels boundingCurve:(beizerCurve *)curve innerCurve:(beizerCurve *)iCurve nearZLimit:(float)zNear farZLimit:(float)zFar newModelEntryPoint:(Vector)entryPoint;
- (void)addPoolExclusionZoneBasedOn:(modelObject *)model;
- (void)changePoolBoundsToCorner1:(Vector)c1 boundingCorner2:(Vector)c2;
- (void)animatePoolDiffusionCurvesFrom:(beizerCurve *)innerStart to:(beizerCurve *)innerEnd and:(beizerCurve *)outerStart to:(beizerCurve *)outerEnd duration:(int)frames;
- (void)addToPoolModel:(modelObject *)new;
- (void)changePoolReplacementTo:(bool)replacement;
- (modelObject *)releaseFromPoolModel:(modelObject *)c;
- (modelObject *)releaseFromPoolModelClosestToPoint:(Vector)p;
- (void)changeDiffuseColourTo:(RGBColour)newColour;
- (void)changeSpecularColourTo:(RGBColour)newColour;
- (void)changeIntrinsicColourTo:(RGBColour)newColour withMaxDistance:(float)newDistance mode:(int)mode;
- (void)translateToX:(float)x Y:(float)y Z:(float)z;
- (void)rotateAroundX:(float)a Y:(float)b Z:(float)c;
- (void)rotateAroundVector:(Vector)axis byAngle:(float)rotationAngle;
- (void)centerPDBModelOnOrigin;
- (void)centerModelOnOrigin;
- (void)applyTransformation;
- (void)loadData;
- (bool)parentShouldRecopyModelData;
- (void)logModelData;
- (void)logInitialModelData;
- (void)logIntrinsicLightData;
- (void)logClipData;
- (void)resetTransformation;
- (void)animateMaintainModelsOnCurveFrom:(beizerCurve *)start to:(beizerCurve *)destination originalModel:(modelObject *)om modelOrientation:(Vector)o spacing:(float)s duration:(int)numFrames;
- (void)animateDiffusionCurvesOuterFrom:(beizerCurve *)startOuter to:(beizerCurve *)endOuter andInner:(beizerCurve *)startInner to:(beizerCurve *)endInner duration:(int)numFrames;
- (void)animateCurvePositionTo:(float)destination duration:(int)numFrames;
- (void)animateTranslationTo:(Vector)end intermediate1:(Vector)i1 intermediate2:(Vector)i2 duration:(int)numFrames;
- (void)animateLinearTranslationTo:(Vector)end duration:(int)numFrames;
- (void)animateLinearTranslationTo:(Vector)end durationModel:(modelObject *)target durationTargetState:(float)state;
- (void)animateTranslationAlongCurve:(beizerCurve *)curve duration:(int)numFrames;
- (void)animateTranslationAlongCurve:(beizerCurve *)curve  durationModel:(modelObject *)target durationTargetState:(float)state;
- (void)endTranslationAlongCurveAnimation;
- (void)animateRotationAroundX:(float)a Y:(float)b Z:(float)c duration:(int)numFrames;
- (void)animateRotationAroundAxis:(Vector)axis byAngle:(float)angle duration:(int)numFrames;
- (void)animateRotationAroundAxis:(Vector)axis byAnglePerFrame:(float)angle;
- (void)animateRotationAroundAxis:(Vector)axis byAngle:(float)angle durationModel:(modelObject *)target durationTargetState:(float)state;
- (void)animateRotationAroundAxis:(Vector)axis byAnglePerEvent:(float)angle durationPerEvent:(int)numFrames;
- (void)animateRotationAroundAxisEnergyEvent;
- (void)animateDiffuseColourTo:(RGBColour)newColour duration:(int)numFrames;
- (void)animateSpecularColourTo:(RGBColour)newColour duration:(int)numFrames;
- (void)animateIntrinsicColourTo:(RGBColour)newColour withMaxDistance:(float)distance mode:(int)mode duration:(int)numFrames;
- (void)animateModelStateWithInitialOffset:(int)offset;
- (void)animateModelStateWithInitialOffset:(int)offset initialSpeed:(float)rate;
- (void)animateModelStateRateOfChangeWithCurve:(beizerCurve *)curve duration:(int)numFrames;
- (void)enableModelStateWobbleWithMax:(float)wobbleMax changeSize:(float)magnitude minChangeSize:(float)min;
- (void)enableWobbleWithMaxRadius:(float)radius changeVectorSize:(float)magnitude;
- (void)enableDiffusionWithMaxTransSpeed:(float)tMaxSpeed maxRotSpeed:(float)rMaxSpeed transChangeSize:(float)tMagnitude rotChangeSize:(float)rMagnitude minCorner:(Vector)min maxCorner:(Vector)max;
- (void)enableDiffusionWithMaxTransSpeed:(float)tMaxSpeed maxRotSpeed:(float)rMaxSpeed transChangeSize:(float)tMagnitude rotChangeSize:(float)rMagnitude minCorner:(Vector)min maxCorner:(Vector)max initialVector:(Vector)start;
- (void)enableDiffusionRotationWithMaxSpeed:(float)rMaxSpeed rotChangeSize:(float)rMagnitude initialVector:(Vector)start;
- (void)enableDiffusionWithMaxTransSpeed:(float)tMaxSpeed maxRotSpeed:(float)rMaxSpeed transChangeSize:(float)tMagnitude rotChangeSize:(float)rMagnitude outsideCurve:(beizerCurve *)outerCurve insideCurve:(beizerCurve *)insideCurve zNear:(float)zNear zFar:(float)zFar;
- (Vector)getDiffusionRotationVector;
- (Vector)getDiffusionTranslationVectorAndEndDiffusionWithRotationChangeVector:(Vector *)rotation;
- (Vector)getDiffusionRotateChangeAndEndRotationDiffusion;
- (void)setDiffusionTranslateChangeVector:(Vector)translate rotateChangeVector:(Vector)rotate;
- (void)setDiffusionTranslateVector:(Vector)translate;
- (void)changeDiffusionBoundsMinCorner:(Vector)c1 maxCorner:(Vector)c2;
- (void)changeDiffusionOuterCurve:(beizerCurve *)outerCurve andInnerCurve:(beizerCurve *)innerCurve;
- (void)changePoolDiffusionMaxTransSpeed:(float)tMaxSpeed maxRotSpeed:(float)rMaxSpeed;
- (void)changeDiffusionMaxTransSpeed:(float)tMaxSpeed maxRotSpeed:(float)rMaxSpeed;
- (void)enablePoolDiffusionWithMaxTransSpeed:(float)tMaxSpeed maxRotSpeed:(float)rMaxSpeed transChangeSize:(float)tMagnitude rotChangeSize:(float)rMagnitude;
- (void)changePoolDiffusionNearZ:(float)zNear farZ:(float)zFar;
- (void)changeDiffusionNearZ:(float)zNear farZ:(float)zFar;
- (bool)calculateAnimationWithFrame:(int)frame;
- (bool)hasDiffuseColour;
- (bool)hasSpecColour;
- (bool)hasIntrinsicColour;
- (bool)hasClipSet;
- (void)setClipForModelTo:(bool)clipEnabled;
- (bool)animatingModelStates;
- (NSArray *)animatingModelStateChildren;
- (Vector)averagePosition;
- (Vector)currentTranslation;
- (Vector)transformWithCurrentTransform:(Vector)p;
- (Vector)transformCoordinate:(Vector)p inSystemOfChild:(modelObject *)target;
- (void)transformIntoCurrentSystemModel:(modelObject *)m inSystemOfChild:(modelObject *)target;
- (void)deleteChildWithName:(NSString *)name;
- (Vector)transformWithInverseTransform:(Vector)p;
//- (Vector)transformCoordinate:(Vector)p intoSystemOfChild:(modelObject *)target;
- (Vector)positionAndRadiusOfEncompassingSphere;
- (Vector)centerOfMass;
- (void)centerModelOnCenterOfMass;
- (bool)targetMolecule:(modelObject *)t requiredRotationAxis:(Vector *)rot requiredRotationAngle:(float *)angle requiredTranslationVector:(Vector *)trans;
- (void)transformWithMatrix:(Matrix)m inverseMatrix:(Matrix)i;
- (void)setPreviousFrame:(int)frame;
- (float)getCurrentState;
- (void)setState:(float)s;
- (int)getNumModelStates;
- (bool)hasModelStateCycled;
- (int)calculateFramesToArriveAtState:(float)targetState;
//- (bool)currentlyAnimating;

@end
