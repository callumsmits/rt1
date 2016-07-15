//
//  modelObject.m
//  present
//
//  Created by Callum Smits on 11/07/13.
//  Copyright (c) 2013 Callum Smits. All rights reserved.
//

#import "modelObject.h"
#import "matrix_ops.h"
#import "vector_ops.h"
#import "randomNumberGenerator.h"

#define kPoolBorderProximity 5.0

@interface modelObject () {
    Matrix transform, inverseTransform;
    NSMutableArray *children;
    NSMutableArray *parentModels;
    NSMutableDictionary *childNames;
    pdbData *data;
    RGBColour currentDiffuseColour, currentSpecularColour, currentIntrinsicColour;
    bool hasModelData;
    NSUInteger _triggerRecopyModelData;
    Matrix _AnimationStart, _AnimationTransform, _AnimationStartInverse, _AnimationTransformInverse;
    Vector _t1, _t2, _t3, _t4;
    int _tDestinationFrame, _tAnimationDuration, _tStartFrame;
    bool _tAnimation;
    Vector _curveModelOrientation, _curveAttachPoint;
    modelObject *_curveOriginalModel;
    beizerCurve *_startCurve, *_curve, *_destinationCurve;
    float _curveSpacing, _curveAttachTValue, _curveDestinationTValue, _curveStartTValue;
    int _curveDestinationFrame, _curveAnimationDuration, _curveStartFrame, _curveTAnimationDuration, _curveTDestinationFrame, _curveTStartFrame;
    bool _curveAnimation, _childrenSpacedAlongCurve, _attachedToCurve, _curveTAnimation;
    beizerCurve *_diffusionInnerStartCurve, *_diffusionInnerDestinationCurve, *_diffusionOuterStartCurve, *_diffusionOuterDestinationCurve;
    int _diffusionCurveDestinationFrame, _diffusionCurveAnimationDuration, _diffusionCurveStartFrame;
    bool _diffusionCurveAnimation;
    Vector _lt1, _lt2;
    modelObject *_ltTargetModel;
    float _ltTargetState, _ltStartState;
    int _ltDestinationFrame, _ltAnimationDuration, _ltStartFrame;
    bool _ltAnimation, _ltDurationCycleRequired;
    int _ctDestinationFrame, _ctAnimationDuration, _ctStartFrame;
    float _ctTargetState, _ctStartState;
    modelObject *_ctTargetModel;
    bool _ctAnimation, _ctDurationCycleRequired;
    float _rX1, _rY1, _rZ1, _rX2, _rY2, _rZ2;
    int _rDestinationFrame, _rAnimationDuration, _rStartFrame;
    bool _rAnimation;
    Vector _raAxis;
    float _raAngle, _raTargetState, _raStartState;
    modelObject *_raTargetModel;
    int _raDestinationFrame, _raAnimationDuration, _raStartFrame;
    bool _raAnimation, _raDurationCycleRequired;
    RGBColour _d1, _d2;
    int _dDestinationFrame, _dAnimationDuration, _dStartFrame;
    bool _dAnimation;
    RGBColour _s1, _s2;
    int _sDestinationFrame, _sAnimationDuration, _sStartFrame;
    bool _sAnimation;
    bool _specColour, _diffuseColour, _intrinsicColour;
    float _intrinsicDistance;
    int _intrinsicMode;
    RGBColour _i1, _i2;
    int _iDestinationFrame, _iAnimationDuration, _iStartFrame;
    bool _iAnimation;
    int _previousFrame;
    bool _stateAnimation, _stateCycle;
    float _stateChangeRate, _state;
    int _stateOffset, _stateStartFrame, _stateAnimationDuration;
    bool _stateChangeRateAnimation;
    int _stateChangeRateStartFrame, _stateChangeRateAnimationDuration, _stateChangeRateDestinationFrame;;
    beizerCurve *_stateChangeRateCurve;
    bool _stateWobbleEnabled;
    float _stateWobbleMax, _stateWobbleChangeMagnitude, _stateBeforeWobble, _stateCurrentWobble, _stateNextWobble, _stateWobbleMin;
    bool _wobbleEnabled;
    float _wobbleMaxRadius, _wobbleChangeMagnitude;
    int _wobbleNumAtoms;
    float *_wobbleVectors;
    Vector _poolMinCorner, _poolSize, _poolMaxCorner, _poolNewMoleculeEntryPoint;
    modelObject *_poolOriginalModel;
    bool _pool, _poolDiffusion, _poolReplacement;
    unsigned int _poolType;
    float _poolDiffusionTMax, _poolDiffusionTChange, _poolDiffusionRMax, _poolDiffusionRChange;
    beizerCurve *_poolOutsideCurve, *_poolInsideCurve;
    NSMutableArray *_poolExclusionZones;
    NSMutableArray *_rotationEnergyEvents;
    bool _diffusionEnabled, _diffusionWithBorders, _diffusionRotationOnly, _diffusionWithCurvedBorders;
    Vector _diffusionMinCorner, _diffusionMaxCorner, _diffusionTranslateVector, _diffusionRotateVector, _diffusionTranslateChangeVector, _diffusionRotateChangeVector;
    float _diffusionTranslateChangeMagnitude, _diffusionRotateChangeMagnitude, _diffusionTranslateMaxSpeed, _diffusionRotateMaxSpeed, _diffusionZNear, _diffusionZFar, _diffusionGridZForInsideNormal;
    beizerCurve *_diffusionOutsideCurve, *_diffusionInsideCurve;
    bool **atomCopiedArray;
    int atomCopiedChildren;
    int *atomCopiedChildrenNumMembers;
    bool _positionChangeSinceLastAverageCalculation;
    Vector _encompassingSphere, _com;
    bool _clipSet, _clipApplied;
    dispatch_group_t _dispatch_group;
    dispatch_semaphore_t _childModificationSemaphore;
}

@property (nonatomic, strong) NSMutableArray *children;
@property (nonatomic, strong) NSMutableArray *parentModels;
@property (nonatomic, strong) NSMutableDictionary *childNames;
@property (nonatomic, strong) NSMutableArray *_poolExclusionZones;
@property (nonatomic, strong) pdbData *data;
@property (nonatomic, strong) beizerCurve *_startCurve;
@property (nonatomic, strong) beizerCurve *_curve;
@property (nonatomic, strong) beizerCurve *_destinationCurve;
@property (nonatomic, strong) beizerCurve *_diffusionInnerStartCurve;
@property (nonatomic, strong) beizerCurve *_diffusionInnerDestinationCurve;
@property (nonatomic, strong) beizerCurve *_diffusionOuterStartCurve;
@property (nonatomic, strong) beizerCurve *_diffusionOuterDestinationCurve;
@property (nonatomic, strong) beizerCurve *_poolOutsideCurve;
@property (nonatomic, strong) beizerCurve *_poolInsideCurve;
@property (nonatomic, strong) beizerCurve *_diffusionOutsideCurve;
@property (nonatomic, strong) beizerCurve *_diffusionInsideCurve;
@property (nonatomic, strong) modelObject *_curveOriginalModel;
@property (nonatomic, strong) modelObject *_poolOriginalModel;
@property (nonatomic, strong) beizerCurve *_stateChangeRateCurve;
@property (nonatomic, strong) modelObject *_ltTargetModel;
@property (nonatomic, strong) modelObject *_raTargetModel;
@property (nonatomic, strong) modelObject *_ctTargetModel;


- (void)recopyAllModelData;
- (void)recopyLightData;
//- (void)recopyLightDataForChild:(modelObject *)child;
- (void)calculateStateChangeRateAnimationWithFrame:(int)frame;
- (void)calculateCurveTAnimationWithFrame:(int)frame;
- (void)calculateCurveAnimationWithFrame:(int)frame;
- (void)calculateTranslationAnimationWithFrame:(int)frame;
- (void)calculateLinearTranslationAnimationWithFrame:(int)frame;
- (void)calculateRotationAnimationWithFrame:(int)frame;
- (void)calculateSpecularColourAnimationWithFrame:(int)frame;
- (void)calculateDiffuseColourAnimationWithFrame:(int)frame;
- (void)calculateIntrinsicColourAnimationWithFrame:(int)frame;
- (void)calculatePositionOnCurve:(beizerCurve *)curve;
- (void)calculateTranslationAlongCurveAnimationWithFrame:(int)frame;
- (bool)selfCurrentlyAnimating;
- (void)resetAnimationTranslation;
- (void)animationTranslateToX:(float)x Y:(float)y Z:(float)z;
- (void)animationEndTranslateToX:(float)x Y:(float)y Z:(float)z;
- (void)animationRotateAroundVector:(Vector)axis angle:(float)a;
- (void)expandWobble;
- (void)decreaseWobble;
- (void)calculateDiffusion;
- (void)calculateRotationDiffusion;
- (void)triggerDataRecopy;
- (void)copyAnimationStartMatrices;

@end

@implementation modelObject

@synthesize transformedBvhObjects, transformedLookupData, transformedModelData, transformedBvhData, numBVH, numLookupData, numModelData;
@synthesize children, data, childNames, parentModels;
@synthesize _startCurve, _destinationCurve, _curve, _curveOriginalModel, _poolOriginalModel;
@synthesize numIntrinsicLights, transformedIntrinsicLights;
@synthesize interModelAtomOverlapsAllowed;
@synthesize _poolExclusionZones, _poolInsideCurve, _poolOutsideCurve, _diffusionInsideCurve, _diffusionOutsideCurve;
@synthesize _stateChangeRateCurve;
@synthesize _diffusionInnerDestinationCurve, _diffusionInnerStartCurve, _diffusionOuterDestinationCurve, _diffusionOuterStartCurve;
@synthesize _ltTargetModel, _raTargetModel, _ctTargetModel;

- (id)init {
    
    self = [super init];
    if (self) {
        loadIdentityMatrix(&transform);
        loadIdentityMatrix(&inverseTransform);
        transformedModelData = nil;
        hasModelData = NO;
        self.transformedBvhObjects = [NSMutableArray arrayWithCapacity:0];
        self.children = [NSMutableArray arrayWithCapacity:0];
        self.parentModels = [NSMutableArray arrayWithCapacity:0];
        self.childNames = [NSMutableDictionary dictionaryWithCapacity:0];
        self._poolExclusionZones = [NSMutableArray arrayWithCapacity:0];
        self._poolOutsideCurve = nil;
        self._poolInsideCurve = nil;
        self._diffusionOutsideCurve = nil;
        self._diffusionInsideCurve = nil;
        self._diffusionInnerStartCurve = nil;
        self._diffusionInnerDestinationCurve = nil;
        self._diffusionOuterStartCurve = nil;
        self._diffusionOuterDestinationCurve = nil;
        self._ltTargetModel = nil;
        self._raTargetModel = nil;
        self._ctTargetModel = nil;
        _tAnimation = NO;
        _ltAnimation = NO;
        _rAnimation = NO;
        _sAnimation = NO;
        _dAnimation = NO;
        _stateAnimation = NO;
        _stateWobbleEnabled = NO;
        _wobbleEnabled = NO;
        _diffusionEnabled = NO;
        _positionChangeSinceLastAverageCalculation = YES;
        _triggerRecopyModelData = 0;
        _pool = NO;
        _specColour = _diffuseColour = _intrinsicColour = NO;
        _intrinsicMode = CRUDE_ONE_FACE;
        _state = 0;
        _stateCycle = NO;
        interModelAtomOverlapsAllowed = YES;
        atomCopiedArray = nil;
        atomCopiedChildren = 0;
        _previousFrame = -1;
        _clipSet = NO;
        _clipApplied = NO;
        _dispatch_group = dispatch_group_create();
        _childModificationSemaphore = dispatch_semaphore_create(1);
    }
    return self;
}

- (id)initWithPDBData:(pdbData *)newModel {

    self = [super init];
    if (self) {
        self.transformedBvhObjects = [NSMutableArray arrayWithCapacity:0];
        loadIdentityMatrix(&transform);
        loadIdentityMatrix(&inverseTransform);
        transformedModelData = nil;
        self.children = [NSMutableArray arrayWithCapacity:0];
        self.parentModels = [NSMutableArray arrayWithCapacity:0];
        self.childNames = [NSMutableDictionary dictionaryWithCapacity:0];
        self._poolExclusionZones = [NSMutableArray arrayWithCapacity:0];
        self._poolOutsideCurve = nil;
        self._poolInsideCurve = nil;
        self._diffusionOutsideCurve = nil;
        self._diffusionInsideCurve = nil;
        self._diffusionInnerStartCurve = nil;
        self._diffusionInnerDestinationCurve = nil;
        self._diffusionOuterStartCurve = nil;
        self._diffusionOuterDestinationCurve = nil;
        self._ltTargetModel = nil;
        self._raTargetModel = nil;
        self._ctTargetModel = nil;
        [self setModelWithPDBData:newModel];
        _tAnimation = NO;
        _ltAnimation = NO;
        _rAnimation = NO;
        _sAnimation = NO;
        _dAnimation = NO;
        _stateWobbleEnabled = NO;
        _wobbleEnabled = NO;
        _diffusionEnabled = NO;
        _positionChangeSinceLastAverageCalculation = YES;
        _triggerRecopyModelData = 0;
        _pool = NO;
        _specColour = _diffuseColour = _intrinsicColour = NO;
        _intrinsicMode = CRUDE_ONE_FACE;
        _state = 0;
        _stateCycle = NO;
        interModelAtomOverlapsAllowed = YES;
        atomCopiedArray = nil;
        atomCopiedChildren = 0;
        _previousFrame = -1;
        _clipSet = NO;
        _clipApplied = NO;
        _dispatch_group = dispatch_group_create();
        _childModificationSemaphore = dispatch_semaphore_create(1);
    }
    
    return self;
}

- (void)addCircleOfModel:(modelObject *)originalModel numMembers:(int)num radius:(float)radius {

    float angle = 2* M_PI / num;
    
    int i;
    for (i = 0; i < num; i++) {
        modelObject *new = [[modelObject alloc] init];
        [new addChildModel:originalModel];
        
//        float x = cos(angle * i) * radius;
//        float y = 0;
//        float z = sin(angle * i) * radius;
        
        [new translateToX:radius Y:0 Z:0];
        [new rotateAroundX:0 Y:angle * i Z:0];
        [self addChildModel:new];
    }

}

- (void)addCircleOfModel:(modelObject *)originalModel withAngleOffset:(float)startAngle numMembers:(int)num radius:(float)radius {

    float angle = 2* M_PI / num;
    
    int i;
    for (i = 0; i < num; i++) {
        modelObject *new = [[modelObject alloc] init];
        [new addChildModel:originalModel];
        
        //        float x = cos(angle * i) * radius;
        //        float y = 0;
        //        float z = sin(angle * i) * radius;
        
        [new translateToX:radius Y:0 Z:0];
        [new rotateAroundX:0 Y:startAngle + angle * i Z:0];
        [self addChildModel:new];
    }
    
}

- (void)addGridOfModel:(modelObject *)originalModel xNumMembers:(int)xNum xSpacing:(float)xSpace zNumMembers:(int)zNum zSpacing:(float)zSpace {
    
    for (int i = -xNum / 2; i < xNum / 2; i++) {
        for (int j = -zNum / 2; j < zNum / 2; j++) {
            modelObject *new = [[modelObject alloc] init];
            [new addChildModel:originalModel];
            
            [new translateToX:i * xSpace Y:0 Z:j * zSpace];
//            [self addChildModel:new];
            dispatch_semaphore_wait(_childModificationSemaphore, DISPATCH_TIME_FOREVER);
            [children addObject:new];
            [new addParentModel:self];
            dispatch_semaphore_signal(_childModificationSemaphore);

        }
    }
    [self recopyAllModelData];
    if (_wobbleEnabled) {
        [self expandWobble];
    }
    [self applyTransformation];
    [self triggerDataRecopy];

}


- (void)addGridOfModel:(modelObject *)originalModel xNumMembers:(int)xNum xSpacing:(float)xSpace zNumMembers:(int)zNum zSpacing:(float)zSpace excludedPoint:(Vector)p withRadius:(float)exlusionRadius {
    for (int i = -xNum / 2; i < xNum / 2; i++) {
        for (int j = -zNum / 2; j < zNum / 2; j++) {
            float x = i * xSpace;
            float z = j * zSpace;
            
            float distFromPoint = sqrtf((p.x - x) * (p.x - x) + (p.y - 0) * (p.y - 0) + (p.z - z) * (p.z - z));

            if (distFromPoint > exlusionRadius) {
                modelObject *new = [[modelObject alloc] init];
                [new addChildModel:originalModel];
                
                [new translateToX:i * xSpace Y:0 Z:j * zSpace];
                //            [self addChildModel:new];
                dispatch_semaphore_wait(_childModificationSemaphore, DISPATCH_TIME_FOREVER);
                [children addObject:new];
                [new addParentModel:self];
                dispatch_semaphore_signal(_childModificationSemaphore);
            }
        }
    }
    [self recopyAllModelData];
    if (_wobbleEnabled) {
        [self expandWobble];
    }
    [self applyTransformation];
    [self triggerDataRecopy];
    
}

- (void)setName:(NSString *)name forChild:(modelObject *)child {
    [childNames setObject:child forKey:name];
}

- (modelObject *)getChildWithName:(NSString *)name {
    return [childNames objectForKey:name];
}

- (modelObject *)getChildClosestToPoint:(Vector)p {
    NSEnumerator *childEnum = [children objectEnumerator];
    modelObject *child;
    
    modelObject *closest = [childEnum nextObject];
    
    if (!closest) {
        return nil;
    }
    
    while (child = [childEnum nextObject]) {
        if (vector_size([child currentTranslation]) < vector_size([closest currentTranslation])) {
            closest = child;
        }
    }
    
    return closest;
}

- (void)addChildModel:(modelObject *)child onToCurve:(beizerCurve *)curve curveFraction:(float)f modelOrientation:(Vector)o modelAttachmentPoint:(Vector)p {
    
    modelObject *new = [[modelObject alloc] init];
    [new addChildModel:child];
    
    self._curve = curve;
    _curveAttachTValue = f;
    _curveModelOrientation = unit_vector(o);
    _curveAttachPoint = p;
    
    [self calculatePositionOnCurve:curve];
    
    [self addChildModel:new];
    
    _attachedToCurve = YES;
}

- (void)calculatePositionOnCurve:(beizerCurve *)curve {
    Vector gridDirection;
    gridDirection.x = 0;
    gridDirection.y = 0;
    gridDirection.z = 1.0;
    gridDirection.w = 0.0;
    
    
    Vector n = [curve getNormalAtT:_curveAttachTValue withCrossVector:gridDirection];
    Vector rotationAxis = unit_vector(vector_cross(_curveModelOrientation, n));
    float angle = acosf(vector_dot_product(_curveModelOrientation, n));
    if ([self selfCurrentlyAnimating]) {
        [self resetAnimationTranslation];
    }
    if (angle > 0) {
        if ([self selfCurrentlyAnimating]) {
            [self animationRotateAroundVector:rotationAxis angle:angle];
        } else {
            [self rotateAroundVector:rotationAxis byAngle:angle];
        }
    }
    
    Vector curvePoint = [curve getValueAtT:_curveAttachTValue];
    Vector newAttachmentPoint;
    if (angle > 0) {
        Matrix tempMatrix = matrixToRotateAroundAxisByAngle(rotationAxis, angle);
        newAttachmentPoint = vectorMatrixMultiply(tempMatrix, _curveAttachPoint);
    } else {
        newAttachmentPoint = _curveAttachPoint;
    }
    Vector translation = vector_subtract(curvePoint, newAttachmentPoint);
    
    if ([self selfCurrentlyAnimating]) {
        [self animationTranslateToX:translation.x Y:translation.y Z:translation.z];
    } else {
        [self translateToX:translation.x Y:translation.y Z:translation.z];
    }
}

- (void)addParametricLineOfModel:(modelObject *)originalModel modelOrientation:(Vector)o spacing:(float)spacing offset:(float)offset bezierCurve:(beizerCurve *)curve {
    spacingPoint *spData;
    int dataSize;
    Vector oUnit = unit_vector(o);
    Vector gridDirection;
    gridDirection.x = 0;
    gridDirection.y = 0;
    gridDirection.z = 1.0;
    gridDirection.w = 0.0;
    
    [curve generatePointsAndNormalsWithSpacing:6.0 offset:offset crossVector:gridDirection intoArray:&spData withCalculatedPoints:&dataSize];
    
    for (int i = 0; i < dataSize; i++) {
        spacingPoint newSP = spData[i];
        modelObject *new = [[modelObject alloc] init];
        [new addChildModel:originalModel];
        
        Vector rotationAxis = unit_vector(vector_cross(oUnit, newSP.normal));
        float angle = acosf(vector_dot_product(oUnit, newSP.normal));
        if (angle > 0) {
            [new rotateAroundVector:rotationAxis byAngle:angle];
        }
        [new translateToX:newSP.point.x Y:newSP.point.y Z:newSP.point.z];
//        [self addChildModel:new];

        dispatch_semaphore_wait(_childModificationSemaphore, DISPATCH_TIME_FOREVER);
        [children addObject:new];
        [new addParentModel:self];
        dispatch_semaphore_signal(_childModificationSemaphore);
        
    }
    free(spData);
    [self recopyAllModelData];
    if (_wobbleEnabled) {
        [self expandWobble];
    }
    [self applyTransformation];
    [self triggerDataRecopy];

    _childrenSpacedAlongCurve = YES;
}

#define kPoolSquareType 0
#define kPoolCurvedType 1

- (void)setupPoolOfModel:(modelObject *)child numModels:(int)numModels boundingCorner1:(Vector)c1 boundingCorner2:(Vector)c2 newModelEntryPoint:(Vector)entryPoint {
    
    _poolMinCorner.x = fminf(c1.x, c2.x);
    _poolMinCorner.y = fminf(c1.y, c2.y);
    _poolMinCorner.z = fminf(c1.z, c2.z);
    
    _poolSize.x = fabsf(c1.x - c2.x);
    _poolSize.y = fabsf(c1.y - c2.y);
    _poolSize.z = fabsf(c1.z - c2.z);
    
    _poolNewMoleculeEntryPoint = entryPoint;
    
    _poolType = kPoolSquareType;
    _poolMaxCorner = vector_add(_poolMinCorner, _poolSize);
    _pool = YES;
    _poolDiffusion = NO;
    _poolReplacement = NO;
    
    for (int i = 0; i < numModels; i++) {
        modelObject *new = [[modelObject alloc] init];
        [new addChildModel:child];
        [self addChildModel:new];
        
        [new rotateAroundX:([[randomNumberGenerator sharedInstance] getRandomUShort] / (float)UINT16_MAX) * 2 * M_PI
                         Y:([[randomNumberGenerator sharedInstance] getRandomUShort] / (float)UINT16_MAX) * 2 * M_PI
                         Z:([[randomNumberGenerator sharedInstance] getRandomUShort] / (float)UINT16_MAX) * 2 * M_PI];
        float nx = 0, ny = 0, nz = 0;
        bool acceptablePosition = NO;
        while (!acceptablePosition) {
            nx = ([[randomNumberGenerator sharedInstance] getRandomUShort] / (float)UINT16_MAX) * _poolSize.x + _poolMinCorner.x;
            ny = ([[randomNumberGenerator sharedInstance] getRandomUShort] / (float)UINT16_MAX) * _poolSize.y + _poolMinCorner.y;
            nz = ([[randomNumberGenerator sharedInstance] getRandomUShort] / (float)UINT16_MAX) * _poolSize.z + _poolMinCorner.z;
            
            bool allowed = YES;
            
            NSEnumerator *positionEnum = [_poolExclusionZones objectEnumerator];
            modelObject *exclusionObject;
            Vector pos; pos.x = nx; pos.y = ny; pos.z = nz; pos.w = 1.0;
            while (exclusionObject = [positionEnum nextObject]) {
                Vector exclusionCenter = [exclusionObject positionAndRadiusOfEncompassingSphere];
                float radius = exclusionCenter.w;
                exclusionCenter.w = 1.0;
                
                allowed &= (vector_size(vector_subtract(pos, exclusionCenter)) > radius + kPoolBorderProximity);
            }
            acceptablePosition = allowed;
        }
        [new translateToX:nx Y:ny Z:nz];
    }
    
    self._poolOriginalModel = child;
    
}

- (void)setupCurveBasedPoolOfModel:(modelObject *)child numModels:(int)numModels boundingCurve:(beizerCurve *)curve innerCurve:(beizerCurve *)iCurve nearZLimit:(float)zNear farZLimit:(float)zFar newModelEntryPoint:(Vector)entryPoint {
    _poolNewMoleculeEntryPoint = entryPoint;
    
    _poolType = kPoolCurvedType;
    _pool = YES;
    _poolDiffusion = NO;
    _poolReplacement = NO;

    _poolOutsideCurve = curve;
    _poolInsideCurve = iCurve;
    Vector min, max;
    min.z = fminf(zNear, zFar);
    max.z = fmaxf(zNear, zFar);
    _poolMinCorner = min;
    _poolMaxCorner = max;
    _poolSize.z = fabsf(max.z - min.z);
    
    //Procedure for adding children is to choose random t-value on the outer curve
    //If no inner curve then just get this point and normal, choose random distance along the normal based on dimension of outer curve
    //Then check inside curve
    
    //If there is an inner curve, choose random point on inner curve and get normal
    //Calculate intersection between normal and both the inner and outer curves
    //Choose the one that is closer, then choose a random point between chose inner point and closest intersection
    //Finally check that it is inside outer and outside inner

    Vector outerCurveDimensions = [_poolOutsideCurve dimensionsWithResolution:1.0];
    float scaleDist;
//    if (iCurve) {
//        scaleDist = (outerCurveDimensions.x / 2.0f + outerCurveDimensions.y / 2.0f) / 2.0f;
//    } else {
//        scaleDist = (outerCurveDimensions.x + outerCurveDimensions.y) / 2.0f;
//    }
    scaleDist = sqrtf(outerCurveDimensions.x*outerCurveDimensions.x + outerCurveDimensions.y*outerCurveDimensions.y);
    //Check if we have an irregularly shaped object...
    scaleDist = fminf(scaleDist, fminf(outerCurveDimensions.x, outerCurveDimensions.y));
    Vector gridDirection;
    gridDirection.x = 0;
    gridDirection.y = 0;
    gridDirection.z = -1.0;
    gridDirection.w = 0.0;
    Vector chosenPosition;
    //Check if the normals will point inside or outside the curve...
    float testT = 0;
    Vector testPoint = [_poolOutsideCurve getValueAtT:testT];
    Vector testNormal = [_poolOutsideCurve getNormalAtT:testT withCrossVector:gridDirection];
    chosenPosition = vector_add(testPoint, testNormal);
    if (![_poolOutsideCurve xySurroundsPoint:chosenPosition withResolution:1.0]) {
        scaleDist *= -1.0f;
    }
    
    for (int i = 0; i < numModels; i++) {
        modelObject *new = [[modelObject alloc] init];
        [new addChildModel:child];
        [self addChildModel:new];
        
        [new rotateAroundX:([[randomNumberGenerator sharedInstance] getRandomUShort] / (float)UINT16_MAX) * 2 * M_PI
                         Y:([[randomNumberGenerator sharedInstance] getRandomUShort] / (float)UINT16_MAX) * 2 * M_PI
                         Z:([[randomNumberGenerator sharedInstance] getRandomUShort] / (float)UINT16_MAX) * 2 * M_PI];
        float outerT, innerT;
        bool acceptablePosition = NO;
        
        while (!acceptablePosition) {
            
            bool allowed = YES;
            
            if (!iCurve) {
                outerT = ([[randomNumberGenerator sharedInstance] getRandomUShort] / (float)UINT16_MAX);
                Vector outerPoint = [_poolOutsideCurve getValueAtT:outerT];
                Vector outerNormal = [_poolOutsideCurve getNormalAtT:outerT withCrossVector:gridDirection];
                float dist = ([[randomNumberGenerator sharedInstance] getRandomUShort] / (float)UINT16_MAX) * scaleDist;
                chosenPosition = vector_add(outerPoint, vector_scale(outerNormal, dist));

                chosenPosition.w = 1;
                allowed &= [_poolOutsideCurve xySurroundsPoint:chosenPosition withResolution:1.0];
            } else {
//                float tForIntersection = [_poolInsideCurve tValueForFirstIntersectionWithLineSegmentDefinedByPoint:outerPoint andPoint:centerPoint withResolution:1.0];
                innerT = ([[randomNumberGenerator sharedInstance] getRandomUShort] / (float)UINT16_MAX);
                Vector innerPoint = [_poolInsideCurve getValueAtT:innerT];
                Vector innerNormal = [_poolInsideCurve getNormalAtT:innerT withCrossVector:gridDirection];
                innerPoint = vector_add(innerPoint, vector_scale(innerNormal, 0.1));
//                innerNormal = vector_scale(innerNormal, -1.0);
                Vector segmentSecondPoint = vector_add(innerPoint, vector_scale(innerNormal, scaleDist * 4));
//                float tOuterIntersection = [_poolOutsideCurve tValueForFirstIntersectionWithLineSegmentDefinedByPoint:innerPoint andPoint:segmentSecondPoint withResolution:1.0];
                float tOuterIntersection = [_poolOutsideCurve tValueForClosestIntersectionToPoint:innerPoint withLineSegmentFormedToPoint:segmentSecondPoint withResolution:1.0];
                float dist = 0, innerDist;
                bool useOuterPoint = YES;
                if (tOuterIntersection < 0) {
//                    NSLog(@"Error: Apparently inner curve is outside outer curve...");
                } else {
                    Vector outerPoint = [_poolOutsideCurve getValueAtT:tOuterIntersection];
                    dist = vector_size(vector_subtract(outerPoint, innerPoint));
                }
                
//                float tInnerIntersection = [_poolInsideCurve tValueForFirstIntersectionWithLineSegmentDefinedByPoint:innerPoint andPoint:segmentSecondPoint withResolution:1.0];
                float tInnerIntersection = [_poolInsideCurve tValueForClosestIntersectionToPoint:innerPoint withLineSegmentFormedToPoint:segmentSecondPoint withResolution:1.0];
                if (tInnerIntersection >= 0) {
                    Vector innerIntersectionPoint = [_poolInsideCurve getValueAtT:tInnerIntersection];
                    innerDist = vector_size(vector_subtract(innerIntersectionPoint, innerPoint));
                    if (innerDist < dist) {
                        useOuterPoint = NO;
                        dist = innerDist;
                    }
                }
                
                if ((tOuterIntersection > 0) || (!useOuterPoint && (tInnerIntersection >= 0))) {
                    
                } else {
                    allowed = NO;
                    dist = 0;
                }
                
                float fraction = ([[randomNumberGenerator sharedInstance] getRandomUShort] / (float)UINT16_MAX);
                chosenPosition = vector_add(innerPoint, vector_scale(innerNormal, dist * fraction));
                chosenPosition.w = 1;
                
                allowed &= [_poolOutsideCurve xySurroundsPoint:chosenPosition withResolution:1.0];
                allowed &= ![_poolInsideCurve xySurroundsPoint:chosenPosition withResolution:1.0];
            }
            
            //X Y fine, now choose Z
            chosenPosition.z = ([[randomNumberGenerator sharedInstance] getRandomUShort] / (float)UINT16_MAX) * _poolSize.z + _poolMinCorner.z;
            
            NSEnumerator *positionEnum = [_poolExclusionZones objectEnumerator];
            modelObject *exclusionObject;
            while (exclusionObject = [positionEnum nextObject]) {
                Vector exclusionCenter = [exclusionObject positionAndRadiusOfEncompassingSphere];
                float radius = exclusionCenter.w;
                exclusionCenter.w = 1.0;
                
                allowed &= (vector_size(vector_subtract(chosenPosition, exclusionCenter)) > radius + kPoolBorderProximity);
            }
            acceptablePosition = allowed;
        }
        [new translateToX:chosenPosition.x Y:chosenPosition.y Z:chosenPosition.z];
    }
    
    self._poolOriginalModel = child;
}

- (void)addPoolExclusionZoneBasedOn:(modelObject *)model {

    [_poolExclusionZones addObject:model];
    
    NSEnumerator *childEnum = [children objectEnumerator];
    modelObject *child;
    
    while (child = [childEnum nextObject]) {
        [child addPoolExclusionZoneBasedOn:model];
    }
}

- (void)changePoolReplacementTo:(bool)replacement {
    _poolReplacement = replacement;
}

- (void)addToPoolModel:(modelObject *)new {
    if (_pool) {
        modelObject *newPoolMember;
        newPoolMember = new;
        if (_poolDiffusion) {
            if (_poolType == kPoolCurvedType) {
                [new applyTransformation];
                Vector center = [new centerOfMass];
                center.w = 0;
                float distanceFromOrigin = vector_size(center);
                if (distanceFromOrigin > 1.0) {
                    //To stop looping, center new for rotation in a new model
                    [new translateToX:-center.x Y:-center.y Z:-center.z];
                    newPoolMember = [[modelObject alloc] init];
                    [newPoolMember addChildModel:new];
                    [newPoolMember enableDiffusionWithMaxTransSpeed:_poolDiffusionTMax maxRotSpeed:_poolDiffusionRMax transChangeSize:_poolDiffusionTChange rotChangeSize:_poolDiffusionRChange outsideCurve:_poolOutsideCurve insideCurve:_poolInsideCurve zNear:_poolMinCorner.z zFar:_poolMaxCorner.z];
                    [newPoolMember setDiffusionTranslateVector:center];
                } else {
                    [newPoolMember enableDiffusionWithMaxTransSpeed:_poolDiffusionTMax maxRotSpeed:_poolDiffusionRMax transChangeSize:_poolDiffusionTChange rotChangeSize:_poolDiffusionRChange outsideCurve:_poolOutsideCurve insideCurve:_poolInsideCurve zNear:_poolMinCorner.z zFar:_poolMaxCorner.z];
                }
            } else {
                [newPoolMember changeDiffusionBoundsMinCorner:_poolMinCorner maxCorner:_poolMaxCorner];
                [newPoolMember enableDiffusionWithMaxTransSpeed:_poolDiffusionTMax maxRotSpeed:_poolDiffusionRMax transChangeSize:_poolDiffusionTChange rotChangeSize:_poolDiffusionRChange minCorner:_poolMinCorner maxCorner:_poolMaxCorner];
            }
        }
        [self addChildModel:newPoolMember];
        if ([_poolExclusionZones count] > 0) {
            NSEnumerator *zoneEnum = [_poolExclusionZones objectEnumerator];
            modelObject *model;
            
            while (model = [zoneEnum nextObject]) {
                [newPoolMember addPoolExclusionZoneBasedOn:model];
            }
        }
    }
}

- (modelObject *)releaseFromPoolModel:(modelObject *)c {
    if (_pool) {
        [self deleteChildModel:c];
//        [children removeObject:c];
        
        if (_poolReplacement) {
            modelObject *new = [[modelObject alloc] init];
            [new addChildModel:_poolOriginalModel];
            
            [self addToPoolModel:new];

            if (_poolDiffusion) {
                [new setDiffusionTranslateVector:_poolNewMoleculeEntryPoint];
            }
            [new translateToX:_poolNewMoleculeEntryPoint.x Y:_poolNewMoleculeEntryPoint.y Z:_poolNewMoleculeEntryPoint.z];
        }
    }
    return c;
}

- (modelObject *)releaseFromPoolModelClosestToPoint:(Vector)p {
    return [self releaseFromPoolModel:[self getChildClosestToPoint:p]];
}

- (void)changePoolBoundsToCorner1:(Vector)c1 boundingCorner2:(Vector)c2 {
    _poolMinCorner.x = fminf(c1.x, c2.x);
    _poolMinCorner.y = fminf(c1.y, c2.y);
    _poolMinCorner.z = fminf(c1.z, c2.z);
    
    _poolSize.x = fabsf(c1.x - c2.x);
    _poolSize.y = fabsf(c1.y - c2.y);
    _poolSize.z = fabsf(c1.z - c2.z);
    
    _poolMaxCorner = vector_add(_poolMinCorner, _poolSize);
    
    NSEnumerator *childEnum = [children objectEnumerator];
    modelObject *child;
    
    while (child = [childEnum nextObject]) {
        [child changeDiffusionBoundsMinCorner:_poolMinCorner maxCorner:_poolMaxCorner];
    }
}

- (void)animatePoolDiffusionCurvesFrom:(beizerCurve *)innerStart to:(beizerCurve *)innerEnd and:(beizerCurve *)outerStart to:(beizerCurve *)outerEnd duration:(int)frames {
    if ((_pool) && (_poolType == kPoolCurvedType)) {
        
        NSEnumerator *childEnum = [children objectEnumerator];
        modelObject *child;
        
        while (child = [childEnum nextObject]) {
            [child animateDiffusionCurvesOuterFrom:outerStart to:outerEnd andInner:innerStart to:innerEnd duration:frames];
        }
        
        self._poolOutsideCurve = outerEnd;
        self._poolInsideCurve = innerEnd;

    }
}

- (void)resetTransformation {
    loadIdentityMatrix(&transform);
    loadIdentityMatrix(&inverseTransform);
}

- (void)resetAnimationTranslation {
    loadIdentityMatrix(&_AnimationTransform);
    loadIdentityMatrix(&_AnimationTransformInverse);
}

- (void)moveModelsToParametricLineWithModelOrientation:(Vector)o originalModel:(modelObject *)originalModel spacing:(float)spacing bezierCurve:(beizerCurve *)curve {
    spacingPoint *spData;
    int dataSize;
    Vector oUnit = unit_vector(o);
    Vector gridDirection;
    gridDirection.x = 0;
    gridDirection.y = 0;
    gridDirection.z = 1.0;
    gridDirection.w = 0.0;
    
    [curve generatePointsAndNormalsWithSpacing:6.0 offset:0 crossVector:gridDirection intoArray:&spData withCalculatedPoints:&dataSize];
    
    NSMutableArray *childrenCopy = [NSMutableArray arrayWithArray:children];
    NSEnumerator *childEnumerator = [childrenCopy objectEnumerator];
    modelObject *new;
    
    for (int i = 0; i < dataSize; i++) {
        spacingPoint newSP = spData[i];
        new = [childEnumerator nextObject];
        
        if (!new) {
            new = [[modelObject alloc] init];
            [new addChildModel:originalModel];
            [self addChildModel:new];
        }
        
        [new resetTransformation];
        Vector rotationAxis = unit_vector(vector_cross(oUnit, newSP.normal));
        float angle = acosf(vector_dot_product(oUnit, newSP.normal));
        if (angle > 0) {
            [new rotateAroundVector:rotationAxis byAngle:angle];
        }
        [new translateToX:newSP.point.x Y:newSP.point.y Z:newSP.point.z];
    }
    while (new = [childEnumerator nextObject]) {
        [self deleteChildModel:new];
    }
    free(spData);
}

- (void)setModelWithPDBData:(pdbData *)newModel {
    self.data = newModel;
    hasModelData = YES;
    [self recopyAllModelData];
}

- (bool)parentShouldRecopyModelData {
    if (_triggerRecopyModelData) {
        _triggerRecopyModelData--;
        return YES;
    }
    return NO;
}

- (void)triggerDataRecopy {
    _triggerRecopyModelData = [parentModels count];
}

- (void)addChildModel:(modelObject *)newChild {
    dispatch_semaphore_wait(_childModificationSemaphore, DISPATCH_TIME_FOREVER);
    [children addObject:newChild];
    [newChild addParentModel:self];
    dispatch_semaphore_signal(_childModificationSemaphore);
    
    [newChild setPreviousFrame:_previousFrame];
    [self recopyAllModelData];
    if (_wobbleEnabled) {
        [self expandWobble];
    }
    [self applyTransformation];
    [self triggerDataRecopy];
}

- (void)deleteChildModel:(modelObject *)child {
//    printf("Deleting model...");
    dispatch_semaphore_wait(_childModificationSemaphore, DISPATCH_TIME_FOREVER);
    [children removeObject:child];
    [child deleteParentModel:self];
    dispatch_semaphore_signal(_childModificationSemaphore);

    [self recopyAllModelData];
    if (_wobbleEnabled) {
        [self decreaseWobble];
    }
    [self applyTransformation];
    _triggerRecopyModelData = [parentModels count];
}

- (modelObject *)addAndTransformIntoCoordSystemChildModel:(modelObject *)newChild {
    dispatch_semaphore_wait(_childModificationSemaphore, DISPATCH_TIME_FOREVER);
    [children addObject:newChild];
    [newChild addParentModel:self];
    dispatch_semaphore_signal(_childModificationSemaphore);

    [newChild transformWithMatrix:inverseTransform inverseMatrix:transform];
    
    [self recopyAllModelData];
    if (_wobbleEnabled) {
        [self expandWobble];
    }
    [self applyTransformation];
    [self triggerDataRecopy];
    
    return newChild;
}

- (void)deleteAndTransformOutOfCoordSystemChildModel:(modelObject *)child {
    [self deleteChildModel:child];
    [child transformWithMatrix:transform inverseMatrix:inverseTransform];
}

- (void)addParentModel:(modelObject *)parent {
    [parentModels addObject:parent];
}

- (void)deleteParentModel:(modelObject *)exParent {
    [parentModels removeObject:exParent];
}

- (void)recopyAllModelData {
    
    self.numModelData = 0;
    for (int i = 0; i < [children count]; i++) {
        self.numModelData = numModelData + [[children objectAtIndex:i] numModelData];
    }
    if (hasModelData) {
        self.numModelData = numModelData + data.numAtoms;
    }
    if (transformedModelData) {
        free(transformedModelData);
    }
    self.transformedModelData = (float *)malloc(sizeof(float) * NUM_ATOMDATA * numModelData);
    if (interModelAtomOverlapsAllowed) {
        NSUInteger offset = 0;
        for (int i = 0; i < [children count]; i++) {
            modelObject *child = [children objectAtIndex:i];
            memcpy(transformedModelData + offset * NUM_ATOMDATA, child.transformedModelData, sizeof(float) * NUM_ATOMDATA * child.numModelData);
            offset = offset + child.numModelData;
        }
        if (hasModelData) {
            memcpy(transformedModelData + offset * NUM_ATOMDATA, data.modelData, sizeof(float) * NUM_ATOMDATA * data.numAtoms);
            offset = offset + data.numAtoms;
        }
    } else {
        if (atomCopiedArray) {
            for (int i = 0; i < atomCopiedChildren; i++) {
                bool *childCopiedArray = atomCopiedArray[i];
                free(childCopiedArray);
            }
            free(atomCopiedArray);
        }
        if (atomCopiedChildrenNumMembers) {
            free(atomCopiedChildrenNumMembers);
        }
        atomCopiedChildren = [children count];
        atomCopiedArray = (bool **)malloc(sizeof(bool *) * atomCopiedChildren);
        atomCopiedChildrenNumMembers = (int *)malloc(sizeof(int) * atomCopiedChildren);
        for (int i = 0; i < [children count]; i++) {
            atomCopiedArray[i] = (bool *)malloc(sizeof(bool) * [[children objectAtIndex:i] numModelData]);
        }
        NSUInteger offset = 0;
        //No overlaps with first model so just copy
        if ([children count] > 0) {
            modelObject *child = [children objectAtIndex:0];
            memcpy(transformedModelData + offset * NUM_ATOMDATA, child.transformedModelData, sizeof(float) * NUM_ATOMDATA * child.numModelData);
            offset = offset + child.numModelData;
            bool *childCopiedArray = atomCopiedArray[0];
            for (int i = 0; i < child.numModelData; i++) {
                childCopiedArray[i] = YES;
            }
        }
        //Now for the rest of the children copy atom by atom checking for clashes
        for (int i = 1; i < [children count]; i++) {
            NSUInteger offsetAtModelStart = offset;
            modelObject *child = [children objectAtIndex:i];
            bool *childCopiedArray = atomCopiedArray[i];
            for (int j = 0; j < child.numModelData; j++) {
                int k = 0;
                bool overlapFound = NO;
                Vector a;
                float *atom = child.transformedModelData + NUM_ATOMDATA * j;
                a.x = *(atom + X);
                a.y = *(atom + Y);
                a.z = *(atom + Z);
                a.w = 1;
                float ar = *(atom + VDW);
                while ((k < offsetAtModelStart) && (!overlapFound)) {
                    float *test = transformedModelData + k * NUM_ATOMDATA;
                    Vector t;
                    t.x = *(test + X);
                    t.y = *(test + Y);
                    t.z = *(test + Z);
                    t.w = 1;
                    float tr = *(test + VDW);
                    float dist = vector_size(vector_subtract(a, t));
                    if (dist < ar + tr) {
                        overlapFound = YES;
                    }
                    k++;
                }
                if (!overlapFound) {
                    memcpy(transformedModelData + offset * NUM_ATOMDATA, child.transformedModelData + j * NUM_ATOMDATA, sizeof(float) * NUM_ATOMDATA);
                    offset++;
                    childCopiedArray[j] = YES;
                } else {
                    childCopiedArray[j] = NO;
                }
            }
        }
        if (hasModelData) {
            memcpy(transformedModelData + offset * NUM_ATOMDATA, data.modelData, sizeof(float) * NUM_ATOMDATA * data.numAtoms);
            offset = offset + data.numAtoms;
        }

        //Cleanup
        self.numModelData = offset;
        float *temp = (float *)malloc(sizeof(float) * NUM_ATOMDATA * numModelData);
        memcpy(temp, transformedModelData, sizeof(float) * NUM_ATOMDATA * numModelData);
        if (transformedModelData) {
            free(transformedModelData);
        }
        self.transformedModelData = temp;
    }
    
    //Reapply lighting and clip settings for this model if enabled
    if (_clipSet) {
        for (int i = 0; i < (int)numModelData; i++) {
            float *atom = transformedModelData + NUM_ATOMDATA * i;
            *(atom + CLIP_APPLIED) = _clipApplied;
        }
    }
    if (_diffuseColour) {
        for (int i = 0; i < (int)numModelData; i++) {
            float *atom = transformedModelData + NUM_ATOMDATA * i;
            *(atom + DIFFUSE_R) = currentDiffuseColour.red;
            *(atom + DIFFUSE_G) = currentDiffuseColour.green;
            *(atom + DIFFUSE_B) = currentDiffuseColour.blue;
        }
    }
    if (_specColour) {
        for (int i = 0; i < (int)numModelData; i++) {
            float *atom = transformedModelData + NUM_ATOMDATA * i;
            *(atom + SPEC_R) = currentSpecularColour.red;
            *(atom + SPEC_G) = currentSpecularColour.green;
            *(atom + SPEC_B) = currentSpecularColour.blue;
        }
    }
    if (_intrinsicColour) {
        for (int i = 0; i < (int)numModelData; i++) {
            float *atom = transformedModelData + NUM_ATOMDATA * i;
            *(atom + INTRINSIC_R) = currentIntrinsicColour.red;
            *(atom + INTRINSIC_G) = currentIntrinsicColour.green;
            *(atom + INTRINSIC_B) = currentIntrinsicColour.blue;
        }
    }
}

- (void)recopyLightData {
    NSUInteger offset = 0;
    self.numIntrinsicLights = 0;
    if (_intrinsicColour) {
        self.numIntrinsicLights = numModelData;
    }
    for (int i = 0; i < [children count]; i++) {
        self.numIntrinsicLights = numIntrinsicLights + [[children objectAtIndex:i] numIntrinsicLights];
    }
    if ((!_intrinsicColour) && (hasModelData)) {
        if ((data.intrinsic_R > 0) || (data.intrinsic_G > 0) || (data.intrinsic_B > 0)) {
            self.numIntrinsicLights = numIntrinsicLights + (int)data.numAtoms;
        }
    }
    
    if (transformedIntrinsicLights) {
        free(transformedIntrinsicLights);
    }
    self.transformedIntrinsicLights = (float *)malloc(sizeof(float) * NUM_INTRINSIC_LIGHT_DATA * numIntrinsicLights);
    
    offset = 0;
    if (_intrinsicColour) {
        for (int i = 0; i < numModelData; i++) {
            float *atom = transformedModelData + NUM_ATOMDATA * i;
            float *intrinsicLight = transformedIntrinsicLights + NUM_INTRINSIC_LIGHT_DATA * i;
            *(intrinsicLight + XI) = *(atom + X);
            *(intrinsicLight + YI) = *(atom + Y);
            *(intrinsicLight + ZI) = *(atom + Z);
            *(intrinsicLight + VDWI) = *(atom + VDW);
            *(intrinsicLight + RED) = currentIntrinsicColour.red;
            *(intrinsicLight + GREEN) = currentIntrinsicColour.green;
            *(intrinsicLight + BLUE) = currentIntrinsicColour.blue;
            *(intrinsicLight + CUTOFF) = _intrinsicDistance;
            *(intrinsicLight + MODE) = _intrinsicMode;
        }
        offset += numModelData;
    }
    
    for (int i = 0; i < [children count]; i++) {
        modelObject *child = [children objectAtIndex:i];
        memcpy(transformedIntrinsicLights + offset * NUM_INTRINSIC_LIGHT_DATA, child.transformedIntrinsicLights, sizeof(float) * NUM_INTRINSIC_LIGHT_DATA * child.numIntrinsicLights);
        offset = offset + child.numIntrinsicLights;
    }
    if ((!_intrinsicColour) && (hasModelData)) {
        if ((data.intrinsic_R > 0) || (data.intrinsic_G > 0) || (data.intrinsic_B > 0)) {
            for (int i = 0; i < numModelData; i++) {
                float *atom = data.modelData + NUM_ATOMDATA * i;
                float *intrinsicLight = transformedIntrinsicLights + NUM_INTRINSIC_LIGHT_DATA * (i + offset);
                *(intrinsicLight + XI) = *(atom + X);
                *(intrinsicLight + YI) = *(atom + Y);
                *(intrinsicLight + ZI) = *(atom + Z);
                *(intrinsicLight + VDWI) = *(atom + VDW);
                *(intrinsicLight + RED) = currentIntrinsicColour.red;
                *(intrinsicLight + GREEN) = currentIntrinsicColour.green;
                *(intrinsicLight + BLUE) = currentIntrinsicColour.blue;
                *(intrinsicLight + CUTOFF) = _intrinsicDistance;
                *(intrinsicLight + MODE) = _intrinsicMode;
            }
        }
    }
}

- (void)changeDiffuseColourTo:(RGBColour)newColour {
    currentDiffuseColour = newColour;
    if (!_diffuseColour) {
        _diffuseColour = YES;
    }
    for (int i = 0; i < (int)numModelData; i++) {
        float *atom = transformedModelData + NUM_ATOMDATA * i;
        *(atom + DIFFUSE_R) = newColour.red;
        *(atom + DIFFUSE_G) = newColour.green;
        *(atom + DIFFUSE_B) = newColour.blue;
    }
}

- (void)changeSpecularColourTo:(RGBColour)newColour {
    currentSpecularColour = newColour;
    if (!_specColour) {
        _specColour = YES;
    }
    for (int i = 0; i < (int)numModelData; i++) {
        float *atom = transformedModelData + NUM_ATOMDATA * i;
        *(atom + SPEC_R) = newColour.red;
        *(atom + SPEC_G) = newColour.green;
        *(atom + SPEC_B) = newColour.blue;
    }
}

- (void)changeIntrinsicColourTo:(RGBColour)newColour withMaxDistance:(float)newDistance mode:(int)mode {
    currentIntrinsicColour = newColour;
    _intrinsicMode = mode;
    if ((newColour.red == 0) && (newColour.green == 0) && (newColour.blue == 0)) {
        _intrinsicColour = NO;
        self.numIntrinsicLights = 0;
        if (transformedIntrinsicLights) {
            free(transformedIntrinsicLights);
        }
        self.transformedIntrinsicLights = nil;
    } else {
        if (!_intrinsicColour) {
            _intrinsicColour = YES;
        }
        _intrinsicDistance = newDistance;
        for (int i = 0; i < (int)numModelData; i++) {
            float *atom = transformedModelData + NUM_ATOMDATA * i;
            *(atom + INTRINSIC_R) = newColour.red;
            *(atom + INTRINSIC_G) = newColour.green;
            *(atom + INTRINSIC_B) = newColour.blue;
        }
        self.numIntrinsicLights = numModelData;
        if (transformedIntrinsicLights) {
            free(transformedIntrinsicLights);
        }
        self.transformedIntrinsicLights = (float *)malloc(sizeof(float) * NUM_INTRINSIC_LIGHT_DATA * numIntrinsicLights);
        for (int i = 0; i < numModelData; i++) {
            float *atom = transformedModelData + NUM_ATOMDATA * i;
            float *intrinsicLight = transformedIntrinsicLights + NUM_INTRINSIC_LIGHT_DATA * i;
            *(intrinsicLight + XI) = *(atom + X);
            *(intrinsicLight + YI) = *(atom + Y);
            *(intrinsicLight + ZI) = *(atom + Z);
            *(intrinsicLight + VDWI) = *(atom + VDW);
            *(intrinsicLight + RED) = currentIntrinsicColour.red;
            *(intrinsicLight + GREEN) = currentIntrinsicColour.green;
            *(intrinsicLight + BLUE) = currentIntrinsicColour.blue;
            *(intrinsicLight + CUTOFF) = _intrinsicDistance;
            *(intrinsicLight + MODE) = _intrinsicMode;
        }
    }
}

- (void)enablePoolDiffusionWithMaxTransSpeed:(float)tMaxSpeed maxRotSpeed:(float)rMaxSpeed transChangeSize:(float)tMagnitude rotChangeSize:(float)rMagnitude {
    
    if (_pool) {
        _poolDiffusion = YES;
        _poolDiffusionTMax = tMaxSpeed;
        _poolDiffusionTChange = tMagnitude;
        _poolDiffusionRMax = rMaxSpeed;
        _poolDiffusionRChange = rMagnitude;
        for (int i = 0; i < [children count]; i++) {
            modelObject *child = [children objectAtIndex:i];
            if (_poolType == kPoolSquareType) {
                [child enableDiffusionWithMaxTransSpeed:tMaxSpeed maxRotSpeed:rMaxSpeed transChangeSize:tMagnitude rotChangeSize:rMagnitude minCorner:_poolMinCorner maxCorner:_poolMaxCorner];
            } else if (_poolType == kPoolCurvedType) {
                [child enableDiffusionWithMaxTransSpeed:tMaxSpeed maxRotSpeed:rMaxSpeed transChangeSize:tMagnitude rotChangeSize:rMagnitude outsideCurve:_poolOutsideCurve insideCurve:_poolInsideCurve zNear:_poolMinCorner.z zFar:_poolMaxCorner.z];
            }
            if ([_poolExclusionZones count] > 0) {
                NSEnumerator *zoneEnum = [_poolExclusionZones objectEnumerator];
                modelObject *model;
                
                while (model = [zoneEnum nextObject]) {
                    [child addPoolExclusionZoneBasedOn:model];
                }
            }
        }
    }
}

- (void)enableDiffusionRotationWithMaxSpeed:(float)rMaxSpeed rotChangeSize:(float)rMagnitude initialVector:(Vector)start {
    
//    if (![self selfCurrentlyAnimating]) {
//        copyMatrix(&_AnimationStart, transform);
//    }
    [self copyAnimationStartMatrices];

    _diffusionRotateMaxSpeed = rMaxSpeed;
    _diffusionRotateChangeMagnitude = rMagnitude;
    _diffusionRotationOnly = YES;
    
    _diffusionRotateVector.x = _diffusionRotateVector.y = _diffusionRotateVector.z = _diffusionRotateVector.w = 0;
    
    _diffusionRotateChangeVector = start;
    
}

- (void)setDiffusionTranslateVector:(Vector)translate {
    _diffusionTranslateVector = translate;
}

- (void)enableDiffusionWithMaxTransSpeed:(float)tMaxSpeed maxRotSpeed:(float)rMaxSpeed transChangeSize:(float)tMagnitude rotChangeSize:(float)rMagnitude outsideCurve:(beizerCurve *)outerCurve insideCurve:(beizerCurve *)insideCurve zNear:(float)zNear zFar:(float)zFar {

    //Need to reset translation prior to copying matrices
    //Stop looping around the start translation...
    //But set translation back once animation matrices are set
//    [self applyTransformation];
//    Vector center = [self positionAndRadiusOfEncompassingSphere];
//    [self translateToX:-center.x Y:-center.y Z:-center.z];
    [self copyAnimationStartMatrices];
//    [self translateToX:center.x Y:center.y Z:center.z];
    
    _diffusionTranslateMaxSpeed = tMaxSpeed;
    _diffusionTranslateChangeMagnitude = tMagnitude;
    _diffusionRotateMaxSpeed = rMaxSpeed;
    _diffusionRotateChangeMagnitude = rMagnitude;
    self._diffusionInsideCurve = insideCurve;
    self._diffusionOutsideCurve = outerCurve;
    _diffusionZNear = zNear;
    _diffusionZFar = zFar;
    _diffusionEnabled = YES;
    _diffusionWithCurvedBorders = YES;
    _diffusionWithBorders = NO;
    
    //Chech which way is in...
    Vector gridDirection;
    gridDirection.x = 0;
    gridDirection.y = 0;
    gridDirection.z = -1.0;
    gridDirection.w = 0.0;
    Vector chosenPosition;
    //Check if the normals will point inside or outside the curve...
    float testT = 0;
    Vector testPoint = [_diffusionOutsideCurve getValueAtT:testT];
    Vector testNormal = [_diffusionOutsideCurve getNormalAtT:testT withCrossVector:gridDirection];
    chosenPosition = vector_add(testPoint, testNormal);
    if ([_diffusionOutsideCurve xySurroundsPoint:chosenPosition withResolution:1.0]) {
        _diffusionGridZForInsideNormal = -1.0;
    } else {
        _diffusionGridZForInsideNormal = 1.0;
    }

    
    _diffusionTranslateVector = [self currentTranslation];
    _diffusionRotateVector.x = _diffusionRotateVector.y = _diffusionRotateVector.z = _diffusionRotateVector.w = 0;
    
    _diffusionTranslateChangeVector.x = ([[randomNumberGenerator sharedInstance] getRandomShort] / (float)INT16_MAX) * _diffusionTranslateMaxSpeed;
    _diffusionTranslateChangeVector.y = ([[randomNumberGenerator sharedInstance] getRandomShort] / (float)INT16_MAX) * _diffusionTranslateMaxSpeed;
    _diffusionTranslateChangeVector.z = ([[randomNumberGenerator sharedInstance] getRandomShort] / (float)INT16_MAX) * _diffusionTranslateMaxSpeed;
    _diffusionRotateChangeVector.x = ([[randomNumberGenerator sharedInstance] getRandomShort] / (float)INT16_MAX) * _diffusionRotateMaxSpeed;
    _diffusionRotateChangeVector.y = ([[randomNumberGenerator sharedInstance] getRandomShort] / (float)INT16_MAX) * _diffusionRotateMaxSpeed;
    _diffusionRotateChangeVector.z = ([[randomNumberGenerator sharedInstance] getRandomShort] / (float)INT16_MAX) * _diffusionRotateMaxSpeed;
    
}

- (void)enableDiffusionWithMaxTransSpeed:(float)tMaxSpeed maxRotSpeed:(float)rMaxSpeed transChangeSize:(float)tMagnitude rotChangeSize:(float)rMagnitude minCorner:(Vector)min maxCorner:(Vector)max {
    
//    if (![self selfCurrentlyAnimating]) {
//        copyMatrix(&_AnimationStart, transform);
//    }
//    [self copyAnimationStartMatrices];
    _diffusionTranslateVector = [self currentTranslation];
    [self translateToX:-_diffusionTranslateVector.x Y:-_diffusionTranslateVector.y Z:-_diffusionTranslateVector.z];
    [self copyAnimationStartMatrices];
    [self translateToX:_diffusionTranslateVector.x Y:_diffusionTranslateVector.y Z:_diffusionTranslateVector.z];


    _diffusionTranslateMaxSpeed = tMaxSpeed;
    _diffusionTranslateChangeMagnitude = tMagnitude;
    _diffusionRotateMaxSpeed = rMaxSpeed;
    _diffusionRotateChangeMagnitude = rMagnitude;
    _diffusionMinCorner = min;
    _diffusionMaxCorner = max;
    _diffusionEnabled = YES;
    _diffusionWithBorders = YES;
    _diffusionWithCurvedBorders = NO;
    
//    _diffusionTranslateVector.x = _diffusionTranslateVector.y = _diffusionTranslateVector.z = _diffusionTranslateVector.w = 0;
//    _diffusionRotateVector.x = _diffusionRotateVector.y = _diffusionRotateVector.z = _diffusionRotateVector.w = 0;
//    _diffusionTranslateVector = [self currentTranslation];
    _diffusionRotateVector.x = _diffusionRotateVector.y = _diffusionRotateVector.z = _diffusionRotateVector.w = 0;
    
    _diffusionTranslateChangeVector.x = ([[randomNumberGenerator sharedInstance] getRandomShort] / (float)INT16_MAX) * _diffusionTranslateMaxSpeed;
    _diffusionTranslateChangeVector.y = ([[randomNumberGenerator sharedInstance] getRandomShort] / (float)INT16_MAX) * _diffusionTranslateMaxSpeed;
    _diffusionTranslateChangeVector.z = ([[randomNumberGenerator sharedInstance] getRandomShort] / (float)INT16_MAX) * _diffusionTranslateMaxSpeed;
    _diffusionRotateChangeVector.x = ([[randomNumberGenerator sharedInstance] getRandomShort] / (float)INT16_MAX) * _diffusionRotateMaxSpeed;
    _diffusionRotateChangeVector.y = ([[randomNumberGenerator sharedInstance] getRandomShort] / (float)INT16_MAX) * _diffusionRotateMaxSpeed;
    _diffusionRotateChangeVector.z = ([[randomNumberGenerator sharedInstance] getRandomShort] / (float)INT16_MAX) * _diffusionRotateMaxSpeed;
}

- (void)enableDiffusionWithMaxTransSpeed:(float)tMaxSpeed maxRotSpeed:(float)rMaxSpeed transChangeSize:(float)tMagnitude rotChangeSize:(float)rMagnitude minCorner:(Vector)min maxCorner:(Vector)max initialVector:(Vector)start {
//    if (![self selfCurrentlyAnimating]) {
//        copyMatrix(&_AnimationStart, transform);
//    }
    [self copyAnimationStartMatrices];
    
    _diffusionTranslateMaxSpeed = tMaxSpeed;
    _diffusionTranslateChangeMagnitude = tMagnitude;
    _diffusionRotateMaxSpeed = rMaxSpeed;
    _diffusionRotateChangeMagnitude = rMagnitude;
    _diffusionMinCorner = min;
    _diffusionMaxCorner = max;
    _diffusionEnabled = YES;
    _diffusionWithBorders = YES;
    
    _diffusionTranslateVector.x = _diffusionTranslateVector.y = _diffusionTranslateVector.z = _diffusionTranslateVector.w = 0;
    _diffusionRotateVector.x = _diffusionRotateVector.y = _diffusionRotateVector.z = _diffusionRotateVector.w = 0;
    _diffusionTranslateVector = [self currentTranslation];
    _diffusionRotateVector.x = _diffusionRotateVector.y = _diffusionRotateVector.z = _diffusionRotateVector.w = 0;
    
    _diffusionTranslateChangeVector = start;
    _diffusionRotateChangeVector.x = 0;
    _diffusionRotateChangeVector.y = 0;
    _diffusionRotateChangeVector.z = 0;
}

- (void)setDiffusionTranslateChangeVector:(Vector)translate rotateChangeVector:(Vector)rotate {
    _diffusionTranslateChangeVector = translate;
    _diffusionRotateChangeVector = rotate;
}

- (Vector)getDiffusionRotationVector {
    return _diffusionRotateVector;
}

- (Vector)getDiffusionTranslationVectorAndEndDiffusionWithRotationChangeVector:(Vector *)rotation {
    _diffusionEnabled = NO;
    
    [self resetAnimationTranslation];
    [self resetTransformation];
    [self rotateAroundX:_diffusionRotateVector.x Y:_diffusionRotateVector.y Z:_diffusionRotateVector.z];
    [self translateToX:_diffusionTranslateVector.x Y:_diffusionTranslateVector.y Z:_diffusionTranslateVector.z];
    
    if (rotation) {
        *rotation = _diffusionRotateChangeVector;
    }
    
    return _diffusionTranslateChangeVector;
}

- (Vector)getDiffusionRotateChangeAndEndRotationDiffusion {

    _diffusionRotationOnly = NO;
    
    [self resetAnimationTranslation];
    [self resetTransformation];
    [self rotateAroundX:_diffusionRotateVector.x Y:_diffusionRotateVector.y Z:_diffusionRotateVector.z];
    
    return _diffusionRotateChangeVector;
}

- (void)changeDiffusionBoundsMinCorner:(Vector)c1 maxCorner:(Vector)c2 {
    
    _diffusionMinCorner = c1;
    _diffusionMaxCorner = c2;

}

- (void)changeDiffusionOuterCurve:(beizerCurve *)outerCurve andInnerCurve:(beizerCurve *)innerCurve {
    self._diffusionOutsideCurve = outerCurve;
    self._diffusionInsideCurve = innerCurve;
}

- (void)changePoolDiffusionMaxTransSpeed:(float)tMaxSpeed maxRotSpeed:(float)rMaxSpeed {

    _poolDiffusionTMax = tMaxSpeed;
    _poolDiffusionRMax = rMaxSpeed;

    NSEnumerator *poolEnum = [children objectEnumerator];
    modelObject *child;
    
    while (child = [poolEnum nextObject]) {
        [child changeDiffusionMaxTransSpeed:tMaxSpeed maxRotSpeed:rMaxSpeed];
    }
}

- (void)changePoolDiffusionNearZ:(float)zNear farZ:(float)zFar {
    
    _poolMinCorner.z = zNear;
    _poolMaxCorner.z = zFar;
    
    NSEnumerator *poolEnum = [children objectEnumerator];
    modelObject *child;
    
    while (child = [poolEnum nextObject]) {
        [self changeDiffusionNearZ:zNear farZ:zFar];
    }

}

- (void)changeDiffusionNearZ:(float)zNear farZ:(float)zFar {
    _diffusionZNear = zNear;
    _diffusionZFar = zFar;
}


- (void)changeDiffusionMaxTransSpeed:(float)tMaxSpeed maxRotSpeed:(float)rMaxSpeed {

    _diffusionTranslateMaxSpeed = tMaxSpeed;
    _diffusionRotateMaxSpeed = rMaxSpeed;
    
}

- (void)enableWobbleWithMaxRadius:(float)radius changeVectorSize:(float)magnitude {
//    if (![self selfCurrentlyAnimating]) {
//        copyMatrix(&_AnimationStart, transform);
//    }
    [self copyAnimationStartMatrices];
    _wobbleEnabled = YES;
    _wobbleMaxRadius = radius;
    _wobbleChangeMagnitude = magnitude;
    _wobbleNumAtoms = self.numModelData;
    
    _wobbleVectors = (float *)malloc(sizeof(float) * 3 * _wobbleNumAtoms);
    for (int i = 0; i < _wobbleNumAtoms; i++) {
        *(_wobbleVectors + i * 3 + 0) = ([[randomNumberGenerator sharedInstance] getRandomShort] / (float)INT16_MAX) * radius;
        *(_wobbleVectors + i * 3 + 1) = ([[randomNumberGenerator sharedInstance] getRandomShort] / (float)INT16_MAX) * radius;
        *(_wobbleVectors + i * 3 + 2) = ([[randomNumberGenerator sharedInstance] getRandomShort] / (float)INT16_MAX) * radius;
    }
}

- (void)enableModelStateWobbleWithMax:(float)wobbleMax changeSize:(float)magnitude minChangeSize:(float)min {
    _stateWobbleEnabled = YES;
    _stateWobbleMax = wobbleMax;
    _stateWobbleChangeMagnitude = magnitude;
    _stateBeforeWobble = _state;
    _stateWobbleMin = min;
    
    _stateCurrentWobble = 0;
    _stateNextWobble = _stateWobbleMin + ([[randomNumberGenerator sharedInstance] getRandomUShort] / (float)UINT16_MAX) * (_stateWobbleMax - _stateWobbleMin);
}

- (void)expandWobble {
    int prevWobbleNum = _wobbleNumAtoms;
    _wobbleNumAtoms = self.numModelData;
    
    
    float *newWobbleVectors = (float *)malloc(sizeof(float) * 3 * _wobbleNumAtoms);
    memcpy(newWobbleVectors, _wobbleVectors, sizeof(float) * 3 * prevWobbleNum);
    free(_wobbleVectors);
    _wobbleVectors = newWobbleVectors;
    for (int i = prevWobbleNum; i < _wobbleNumAtoms; i++) {
        *(_wobbleVectors + i * 3 + 0) = ([[randomNumberGenerator sharedInstance] getRandomShort] / (float)INT16_MAX) * _wobbleMaxRadius;
        *(_wobbleVectors + i * 3 + 1) = ([[randomNumberGenerator sharedInstance] getRandomShort] / (float)INT16_MAX) * _wobbleMaxRadius;
        *(_wobbleVectors + i * 3 + 2) = ([[randomNumberGenerator sharedInstance] getRandomShort] / (float)INT16_MAX) * _wobbleMaxRadius;
    }
    
}

- (void)decreaseWobble {
    _wobbleNumAtoms = self.numModelData;
}

- (void)setPreviousFrame:(int)frame {
    _previousFrame = frame;
}

- (float)getCurrentState {
    if (_stateWobbleEnabled) {
        return _stateBeforeWobble;
    }
    return _state;
}

- (int)getNumModelStates {
    if (data) {
        return [data numStates];
    } else {
        if ([children count] > 0) {
            modelObject *firstChild = [children objectAtIndex:0];
            return [firstChild getNumModelStates];
        }
        return 0;
    }
    return 0;
}

- (void)animateModelStateRateOfChangeWithCurve:(beizerCurve *)curve duration:(int)numFrames {
    
//    [self animateModelStateWithInitialOffset:0];
    _stateChangeRateAnimation = YES;
    self._stateChangeRateCurve = curve;
    _stateChangeRateStartFrame = _previousFrame;
    _stateChangeRateAnimationDuration = numFrames;
    _stateChangeRateDestinationFrame = numFrames + _previousFrame;
}

- (void)animateModelStateWithInitialOffset:(int)offset {
    [self copyAnimationStartMatrices];
//    if (![self selfCurrentlyAnimating]) {
//        copyMatrix(&_AnimationStart, transform);
//    }
    _stateOffset = offset;
    _stateAnimationDuration = [self getNumModelStates];
    _stateChangeRate = 1.0f;
    _stateStartFrame = _previousFrame;
    _stateAnimation = YES;
    _state = (float)_stateOffset;
}

- (void)animateModelStateWithInitialOffset:(int)offset initialSpeed:(float)rate {
    [self copyAnimationStartMatrices];

//    if (![self selfCurrentlyAnimating]) {
//        copyMatrix(&_AnimationStart, transform);
//    }
    _stateOffset = offset;
    _stateAnimationDuration = [self getNumModelStates];
    _stateChangeRate = rate;
    _stateStartFrame = _previousFrame;
    _stateAnimation = YES;
    _state = (float)_stateOffset;
}

- (void)animateMaintainModelsOnCurveFrom:(beizerCurve *)start to:(beizerCurve *)destination originalModel:(modelObject *)om modelOrientation:(Vector)o spacing:(float)s duration:(int)numFrames {
//    if (![self selfCurrentlyAnimating]) {
//        copyMatrix(&_AnimationStart, transform);
//    }
    [self copyAnimationStartMatrices];

    self._startCurve = start;
    self._destinationCurve = destination;
    self._curveOriginalModel = om;
    _curveModelOrientation = o;
    _curveSpacing = s;
    
    _curveDestinationFrame = numFrames + _previousFrame;
    _curveAnimationDuration = numFrames;
    _curveStartFrame = _previousFrame;
    _curveAnimation = YES;
}

- (void)animateDiffusionCurvesOuterFrom:(beizerCurve *)startOuter to:(beizerCurve *)endOuter andInner:(beizerCurve *)startInner to:(beizerCurve *)endInner duration:(int)numFrames {
 
    [self copyAnimationStartMatrices];
    
    self._diffusionInnerStartCurve = startInner;
    self._diffusionInnerDestinationCurve = endInner;
    self._diffusionOuterStartCurve = startOuter;
    self._diffusionOuterDestinationCurve = endOuter;
    
    _diffusionCurveDestinationFrame = numFrames + _previousFrame;
    _diffusionCurveAnimationDuration = numFrames;
    _diffusionCurveStartFrame = _previousFrame;
    _diffusionCurveAnimation = YES;
    
}

- (void)animateCurvePositionTo:(float)destination duration:(int)numFrames {
//    if (![self selfCurrentlyAnimating]) {
//        copyMatrix(&_AnimationStart, transform);
//    }
    [self copyAnimationStartMatrices];

    _curveDestinationTValue = destination;
    _curveStartTValue = _curveAttachTValue;
    
    _curveTAnimation = YES;
    _curveTAnimationDuration = numFrames;
    _curveTStartFrame = _previousFrame;
    _curveTDestinationFrame = numFrames + _previousFrame;
}

- (void)animateTranslationAlongCurve:(beizerCurve *)curve  durationModel:(modelObject *)target durationTargetState:(float)state {
    [self copyAnimationStartMatrices];
    
    self._curve = curve;
    
    self._ctTargetModel = target;
    _ctTargetState = state;
    _ctStartState = [_ctTargetModel getCurrentState];
    _ctDurationCycleRequired = _ctStartState > _ctTargetState;
    
    _ctAnimation = YES;
//    _ctAnimationDuration = [_ctTargetModel calculateFramesToArriveAtState:_ctTargetState];
//    _ctDestinationFrame = _ctAnimationDuration + _previousFrame;
//    _ctStartFrame = _previousFrame;
}

- (void)animateTranslationAlongCurve:(beizerCurve *)curve duration:(int)numFrames {
//    if (![self selfCurrentlyAnimating]) {
//        copyMatrix(&_AnimationStart, transform);
//    }
    [self copyAnimationStartMatrices];

    self._curve = curve;
    _ctAnimation = YES;
    _ctAnimationDuration = numFrames;
    _ctStartFrame = _previousFrame;
    _ctDestinationFrame = numFrames + _previousFrame;
    
}

- (void)animateTranslationTo:(Vector)end intermediate1:(Vector)i1 intermediate2:(Vector)i2 duration:(int)numFrames {

//    if (![self selfCurrentlyAnimating]) {
//        copyMatrix(&_AnimationStart, transform);
//    }
    [self copyAnimationStartMatrices];

    Vector empty;
    empty.x = empty.y = empty.z = empty.w = 0;
    _t1 = empty;
    _t2 = i1;
    _t3 = i2;
    _t4 = end;
    
    _tDestinationFrame = numFrames + _previousFrame;
    _tAnimationDuration = numFrames;
    _tStartFrame = _previousFrame;
    _tAnimation = YES;

}

- (void)animateLinearTranslationTo:(Vector)end durationModel:(modelObject *)target durationTargetState:(float)state {
    [self copyAnimationStartMatrices];
    
    Vector empty;
    empty.x = empty.y = empty.z = empty.w = 0;
    _lt1 = empty;
    _lt2 = end;
    
    self._ltTargetModel = target;
    _ltTargetState = state;
    _ltStartState = [_ltTargetModel getCurrentState];
    _ltDurationCycleRequired = _ltStartState > _ltTargetState;
    
//    _ltAnimationDuration = [_ltTargetModel calculateFramesToArriveAtState:_ltTargetState];
//    _ltDestinationFrame = _ltAnimationDuration + _previousFrame;
//    _ltStartFrame = _previousFrame;
    _ltAnimation = YES;

}


- (void)animateLinearTranslationTo:(Vector)end duration:(int)numFrames {
//    if (![self selfCurrentlyAnimating]) {
//        copyMatrix(&_AnimationStart, transform);
//    }
    [self copyAnimationStartMatrices];

    Vector empty;
    empty.x = empty.y = empty.z = empty.w = 0;
    _lt1 = empty;
    _lt2 = end;
    
    _ltDestinationFrame = numFrames + _previousFrame;
    _ltAnimationDuration = numFrames;
    _ltStartFrame = _previousFrame;
    _ltAnimation = YES;
    
}

- (void)animateRotationAroundX:(float)a Y:(float)b Z:(float)c  duration:(int)numFrames{
//    if (![self selfCurrentlyAnimating]) {
//        copyMatrix(&_AnimationStart, transform);
//    }
    [self copyAnimationStartMatrices];

    _rX1 = _rY1 = _rZ1 = 0;
    _rX2 = a;
    _rY2 = b;
    _rZ2 = c;
    
    _rDestinationFrame = numFrames + _previousFrame;
    _rAnimationDuration = numFrames;
    _rStartFrame = _previousFrame;
    _rAnimation = YES;
    
}
- (void)animateRotationAroundAxis:(Vector)axis byAngle:(float)angle durationModel:(modelObject *)target durationTargetState:(float)state {
    [self copyAnimationStartMatrices];
    
    _raAxis = axis;
    _raAngle = angle;
    
    self._raTargetModel = target;
    _raTargetState = state;
    _raStartState = [_raTargetModel getCurrentState];
    _raDurationCycleRequired = _raStartState > _raTargetState;
    
//    _raAnimationDuration = [_raTargetModel calculateFramesToArriveAtState:_raTargetState];
//    _raDestinationFrame = _raAnimationDuration + _previousFrame;
//    _raStartFrame = _previousFrame;
    _raAnimation = YES;

}

- (void)animateRotationAroundAxis:(Vector)axis byAnglePerFrame:(float)angle {
    [self copyAnimationStartMatrices];
    
    _raAxis = axis;
    _raAngle = angle;
    
    _raDestinationFrame = -1;
    _raAnimationDuration = -1;
    _raStartFrame = _previousFrame;
    _raAnimation = YES;
    
}

- (void)animateRotationAroundAxis:(Vector)axis byAnglePerEvent:(float)angle durationPerEvent:(int)numFrames {
    _raAxis = axis;
    _raAngle = angle;
    
    _raDestinationFrame = -2;
    _raAnimationDuration = -2;
    _raStartFrame = numFrames;
    _raAnimation = YES;
    
    _rotationEnergyEvents = [NSMutableArray arrayWithCapacity:0];
    
}

- (void)animateRotationAroundAxisEnergyEvent {
    [_rotationEnergyEvents addObject:[NSNumber numberWithInt:_previousFrame]];
}

- (void)animateRotationAroundAxis:(Vector)axis byAngle:(float)angle duration:(int)numFrames {
    [self copyAnimationStartMatrices];
    
    _raAxis = axis;
    _raAngle = angle;
    
    _raDestinationFrame = numFrames + _previousFrame;
    _raAnimationDuration = numFrames;
    _raStartFrame = _previousFrame;
    _raAnimation = YES;
    
}

- (void)animateDiffuseColourTo:(RGBColour)newColour duration:(int)numFrames {
//    if (![self selfCurrentlyAnimating]) {
//        copyMatrix(&_AnimationStart, transform);
//    }
    [self copyAnimationStartMatrices];

    _d1 = currentDiffuseColour;
    _d2 = newColour;
    
    _dDestinationFrame = numFrames + _previousFrame;
    _dAnimationDuration = numFrames;
    _dStartFrame = _previousFrame;
    _dAnimation = YES;
    
}

- (void)animateSpecularColourTo:(RGBColour)newColour duration:(int)numFrames {
//    if (![self selfCurrentlyAnimating]) {
//        copyMatrix(&_AnimationStart, transform);
//    }
    [self copyAnimationStartMatrices];

    _s1 = currentSpecularColour;
    _s2 = newColour;
    
    _sDestinationFrame = numFrames + _previousFrame;
    _sAnimationDuration = numFrames;
    _sStartFrame = _previousFrame;
    _sAnimation = YES;
    
}

- (void)animateIntrinsicColourTo:(RGBColour)newColour withMaxDistance:(float)distance mode:(int)mode duration:(int)numFrames {
//    if (![self selfCurrentlyAnimating]) {
//        copyMatrix(&_AnimationStart, transform);
//    }
    [self copyAnimationStartMatrices];

    
    _intrinsicDistance = distance;
    _intrinsicMode = mode;
    if (!_intrinsicColour) {
        currentIntrinsicColour.red = 0;
        currentIntrinsicColour.green = 0;
        currentIntrinsicColour.blue = 0;
    }
    _i1 = currentIntrinsicColour;
    _i2 = newColour;
    
    _iDestinationFrame = numFrames + _previousFrame;
    _iAnimationDuration = numFrames;
    _iStartFrame = _previousFrame;
    _iAnimation = YES;
    
}

- (int)calculateFramesToArriveAtState:(float)targetState {
    //First must be state animation
    if (!_stateAnimation) {
        return 0;
    }
    if (targetState >= _stateAnimationDuration) {
        targetState = fmodf(targetState, _stateAnimationDuration);
    }
    float state = _state;
    float currentStateChangeRate = _stateChangeRate;
    int simulationFrame = _previousFrame;
    bool wrapAroundRequired = NO;
    if (targetState < state) {
        wrapAroundRequired = YES;
    }
    if (_stateChangeRateAnimation) {
        while (((wrapAroundRequired == YES) || (state < targetState)) && (simulationFrame != _stateChangeRateDestinationFrame)) {
            CGFloat t = (simulationFrame - _stateChangeRateStartFrame)/(CGFloat)_stateChangeRateAnimationDuration;
            Vector dst = [_stateChangeRateCurve getValueAtT:t];
            currentStateChangeRate = dst.x;
            state += currentStateChangeRate;
            simulationFrame++;
            if (state >= _stateAnimationDuration) {
                state = state - (float)_stateAnimationDuration;
                wrapAroundRequired = NO;
            }
        }
    }
    if (((state < targetState) || (wrapAroundRequired == YES)) && (currentStateChangeRate == 0)) {
        NSLog(@"Error - rate zero and will never reach simulation target!");
        return 0;
    }
    while ((wrapAroundRequired == YES) || (state < targetState)) {
        state += currentStateChangeRate;
        simulationFrame++;
        if (state >= _stateAnimationDuration) {
            state = state - (float)_stateAnimationDuration;
            wrapAroundRequired = NO;
        }
    }
    return simulationFrame - _previousFrame;
}

- (void)calculateStateChangeRateAnimationWithFrame:(int)frame {
    CGFloat t = (frame - _stateChangeRateStartFrame)/(CGFloat)_stateChangeRateAnimationDuration;
    
    Vector dst;
    dst = [_stateChangeRateCurve getValueAtT:t];
    _stateChangeRate = dst.x;
    
    if (frame == _stateChangeRateDestinationFrame) {
        _stateChangeRateAnimation = NO;
        self._stateChangeRateCurve = nil;
    }

}

- (void)calculateCurveTAnimationWithFrame:(int)frame {
    CGFloat s = M_PI * (frame - _curveTStartFrame)/(CGFloat)_curveTAnimationDuration - M_PI_2;
    CGFloat t = 0.5 + 0.5 * sinf(s);
    
    _curveAttachTValue = (1-t) * _curveStartTValue + t * _curveDestinationTValue;
    if (!_curveAnimation) {
        [self calculatePositionOnCurve:_curve];        
    }
    
    if (frame == _curveTDestinationFrame) {
        _curveTAnimation = NO;
    }
}

- (void)calculateTranslationAlongCurveAnimationWithFrame:(int)frame {
//    CGFloat s = M_PI * (frame - _ctStartFrame)/(CGFloat)_ctAnimationDuration - M_PI_2;
//    CGFloat t = 0.5 + 0.5 * sinf(s);
    
    
    CGFloat t;
    if (_ctTargetModel) {
        float startState;
        if (_ctStartState > _ctTargetState) {
            startState = _ctStartState - [_ctTargetModel getNumModelStates];
        } else {
            startState = _ctStartState;
        }
        float currentState;
        if (_ctDurationCycleRequired && ([_ctTargetModel getCurrentState] > _ctTargetState)) {
            currentState = [_ctTargetModel getCurrentState] - [_ctTargetModel getNumModelStates];
        } else {
            currentState = [_ctTargetModel getCurrentState];
            _ctDurationCycleRequired = NO;
        }
        t = (currentState - startState)/(float)(_ctTargetState - startState);
    } else {
        t = (frame - _ctStartFrame)/(CGFloat)_ctAnimationDuration;
    }
    
    if (t > 1.0f) {
        t = 1.0f;
    }
    
    Vector dst;
    dst = [_curve getValueAtT:t];
    [self animationTranslateToX:dst.x Y:dst.y Z:dst.z];
    
    if (_ctTargetModel) {
        if (t >= 1.0f - 0.0001) {
            _ctAnimation = NO;
            self._curve = nil;
            self._ctTargetModel = nil;
            if ([self selfCurrentlyAnimating]) {
                [self animationEndTranslateToX:dst.x Y:dst.y Z:dst.z];
            }
        }
    } else {
        if (frame >= _ctDestinationFrame) {
            _ctAnimation = NO;
            self._curve = nil;
            self._ctTargetModel = nil;
            if ([self selfCurrentlyAnimating]) {
                [self animationEndTranslateToX:dst.x Y:dst.y Z:dst.z];
            }
        }
    }
}

- (void)endTranslationAlongCurveAnimation {
    _ctAnimation = NO;
    self._curve = nil;    
}

- (void)calculateCurveAnimationWithFrame:(int)frame {
    CGFloat s = M_PI * (frame - _curveStartFrame)/(CGFloat)_curveAnimationDuration - M_PI_2;
    CGFloat t = 0.5 + 0.5 * sinf(s);
    
    beizerCurve *iCurve = [_startCurve curveByInterpolatingWithCurve:_destinationCurve fraction:(float)t];
    self._curve = iCurve;
    
    if (_childrenSpacedAlongCurve) {
        [self moveModelsToParametricLineWithModelOrientation:_curveModelOrientation originalModel:_curveOriginalModel spacing:_curveSpacing bezierCurve:iCurve];
    } else if (_attachedToCurve) {
        [self calculatePositionOnCurve:iCurve];
    }
    
    if (frame == _curveDestinationFrame) {
        _curveAnimation = NO;
        self._startCurve = _destinationCurve;
        self._destinationCurve = nil;
    }
}

- (void)calculateDiffusionCurveAnimationWithFrame:(int)frame {
    CGFloat s = M_PI * (frame - _diffusionCurveStartFrame)/(CGFloat)_diffusionCurveAnimationDuration - M_PI_2;
    CGFloat t = 0.5 + 0.5 * sinf(s);
    
    beizerCurve *outerCurve = [_diffusionOuterStartCurve curveByInterpolatingWithCurve:_diffusionOuterDestinationCurve fraction:(float)t];
    self._diffusionOutsideCurve = outerCurve;

    beizerCurve *innerCurve = [_diffusionInnerStartCurve curveByInterpolatingWithCurve:_diffusionInnerDestinationCurve fraction:(float)t];
    self._diffusionInsideCurve = innerCurve;
    
    if (_pool && (_poolType == kPoolCurvedType)) {
        NSEnumerator *poolEnum = [children objectEnumerator];
        modelObject *child;
        
        while (child = [poolEnum nextObject]) {
            [child changeDiffusionOuterCurve:_diffusionOutsideCurve andInnerCurve:_diffusionInsideCurve];
        }
    }

    if (frame == _diffusionCurveDestinationFrame) {
        _diffusionCurveAnimation = NO;
        self._diffusionInsideCurve = _diffusionInnerDestinationCurve;
        self._diffusionOutsideCurve = _diffusionOuterDestinationCurve;
    }
    
}

- (void)calculateTranslationAnimationWithFrame:(int)frame {
    
    CGFloat s = M_PI * (frame - _tStartFrame)/(CGFloat)_tAnimationDuration - M_PI_2;
    CGFloat t = 0.5 + 0.5 * sinf(s);
    float x = powf(1-t, 3) * _t1.x + 3 * powf(1-t, 2) * t * _t2.x + 3 * (1-t) * t * t * _t3.x + powf(t, 3) * _t4.x;
    float y = powf(1-t, 3) * _t1.y + 3 * powf(1-t, 2) * t * _t2.y + 3 * (1-t) * t * t * _t3.y + powf(t, 3) * _t4.y;
    float z = powf(1-t, 3) * _t1.z + 3 * powf(1-t, 2) * t * _t2.z + 3 * (1-t) * t * t * _t3.z + powf(t, 3) * _t4.z;
    
    [self animationTranslateToX:x Y:y Z:z];
    
    if (frame == _tDestinationFrame) {
        _tAnimation = NO;
    }
    
}

- (void)calculateLinearTranslationAnimationWithFrame:(int)frame {
    
    CGFloat s, t;
    if (_ltTargetModel) {
        float startState;
        if (_ltStartState > _ltTargetState) {
            startState = _ltStartState - [_ltTargetModel getNumModelStates];
        } else {
            startState = _ltStartState;
        }
        float currentState;
        if (_ltDurationCycleRequired && ([_ltTargetModel getCurrentState] > _ltTargetState)) {
            currentState = [_ltTargetModel getCurrentState] - [_ltTargetModel getNumModelStates];
        } else {
            currentState = [_ltTargetModel getCurrentState];
            _ltDurationCycleRequired = NO;
        }
        s = M_PI * (currentState - startState)/(float)(_ltTargetState - startState) - M_PI_2;
    } else {
        if (_ltAnimationDuration == 0) {
            s = M_PI_2;
        } else {
            s = M_PI * (frame - _ltStartFrame)/(CGFloat)_ltAnimationDuration - M_PI_2;
        }
    }
    
    t = 0.5 + 0.5 * sinf(s);
    if (t > 1.0f) {
        t = 1.0f;
    }
    float x = (1-t) * _lt1.x + t * _lt2.x;
    float y = (1-t) * _lt1.y + t * _lt2.y;
    float z = (1-t) * _lt1.z + t * _lt2.z;
    
    [self animationTranslateToX:x Y:y Z:z];
    
    if (_ltTargetModel) {
        if (t >= 1.0f - 0.0001) {
            _ltAnimation = NO;
            self._ltTargetModel = nil;
            if ([self selfCurrentlyAnimating]) {
                [self animationEndTranslateToX:x Y:y Z:z];
            }
        }
    } else {
        if (frame >= _ltDestinationFrame) {
            _ltAnimation = NO;
            self._ltTargetModel = nil;
            if ([self selfCurrentlyAnimating]) {
                [self animationEndTranslateToX:x Y:y Z:z];
            }
        }
    }
    
}

- (void)calculateRotationAnimationWithFrame:(int)frame {
    CGFloat s = M_PI * (frame - _rStartFrame)/(CGFloat)_rAnimationDuration - M_PI_2;
    CGFloat t = 0.5 + 0.5 * sinf(s);
    float a = (1-t) * _rX1 + t * _rX2;
    float b = (1-t) * _rY1 + t * _rY2;
    float c = (1-t) * _rZ1 + t * _rZ2;

    [self animationRotateAroundX:a Y:b Z:c];
    
    if (frame == _rDestinationFrame) {
        _rAnimation = NO;
    }

}

- (void)calculateRotationAxisAnimationWithFrame:(int)frame {
    CGFloat s, t;
    
    //AnimationDuration and DestinationFrame == -2 signals that the rotation is event driven
    if ((_raAnimationDuration == -2) && (_raDestinationFrame == -2)) {
        NSEnumerator *startFrameEnumerator = [_rotationEnergyEvents objectEnumerator];
        
        float rotation = 0;
        NSNumber *startFrame;
        while (startFrame = [startFrameEnumerator nextObject]) {
            for (int f = 0; f < frame; f++) {
                if ([startFrame intValue] + _raStartFrame > f) {
                    int framesFromStart = f - [startFrame intValue];
                    if (framesFromStart > 0) {
                        rotation += (cos((float)framesFromStart / (float)_raStartFrame * 2 * M_PI -M_PI) + 1) / (2 * M_PI) * _raAngle;                        
                    }
                }
            }
        }
        
        [self animationRotateAroundVector:_raAxis angle:rotation];
    } else {
        if (_raTargetModel) {
            float startState;
            if (_raStartState > _raTargetState) {
                startState = _raStartState - [_raTargetModel getNumModelStates];
            } else {
                startState = _raStartState;
            }
            float currentState;
            if (_raDurationCycleRequired && ([_raTargetModel getCurrentState] > _raTargetState)) {
                currentState = [_raTargetModel getCurrentState] - [_raTargetModel getNumModelStates];
            } else {
                currentState = [_raTargetModel getCurrentState];
                _raDurationCycleRequired = NO;
            }
            s = M_PI * (currentState - startState)/(float)(_raTargetState - startState) - M_PI_2;
        } else {
            s = M_PI * (frame - _raStartFrame)/(CGFloat)_raAnimationDuration - M_PI_2;
        }
        
        t = 0.5 + 0.5 * sinf(s);
        if (t > 1.0f) {
            t = 1.0f;
        }
        
        float rotation;
        //AnimationDuration and DestinationFrame == -1 signals that the rotation is constant
        if ((_raAnimationDuration == -1) && (_raDestinationFrame == -1)) {
            rotation = _raAngle * (frame - _raStartFrame);
        } else {
            rotation = _raAngle * t;
        }
        
        [self animationRotateAroundVector:_raAxis angle:rotation];
        
        if (!((_raAnimationDuration == -1) && (_raDestinationFrame == -1))) {
            if (_raTargetModel) {
                if (t >= 1.0f - 0.0001) {
                    _raAnimation = NO;
                    self._raTargetModel = nil;
                }
            } else {
                if (frame >= _raDestinationFrame) {
                    _raAnimation = NO;
                    self._raTargetModel = nil;
                }
            }
        }
    }
}

- (void)calculateSpecularColourAnimationWithFrame:(int)frame {
    RGBColour i;
    
    if (!_specColour) {
        _specColour = YES;
    }
    
    CGFloat s = M_PI * (frame - _sStartFrame)/(CGFloat)_sAnimationDuration - M_PI_2;
    CGFloat t = 0.5 + 0.5 * sinf(s);
    i.red = (1-t) * _s1.red + t * _s2.red;
    i.green = (1-t) * _s1.green + t * _s2.green;
    i.blue = (1-t) * _s1.blue + t * _s2.blue;
    
    [self changeSpecularColourTo:i];
    currentSpecularColour = i;
    
    if (frame == _sDestinationFrame) {
        _sAnimation = NO;
    }
    
}

- (void)calculateDiffuseColourAnimationWithFrame:(int)frame {

    if (!_diffuseColour) {
        _diffuseColour = YES;
    }
    
    RGBColour i;
    CGFloat s = M_PI * (frame - _dStartFrame)/(CGFloat)_dAnimationDuration - M_PI_2;
    CGFloat t = 0.5 + 0.5 * sinf(s);
    i.red = (1-t) * _d1.red + t * _d2.red;
    i.green = (1-t) * _d1.green + t * _d2.green;
    i.blue = (1-t) * _d1.blue + t * _d2.blue;
    
    [self changeDiffuseColourTo:i];
    currentDiffuseColour = i;
    
    if (frame == _dDestinationFrame) {
        _dAnimation = NO;
    }
    
}

- (void)calculateIntrinsicColourAnimationWithFrame:(int)frame {
    
    if (!_intrinsicColour) {
        _intrinsicColour = YES;
    }
    
    RGBColour i;
    CGFloat s = M_PI * (frame - _iStartFrame)/(CGFloat)_iAnimationDuration - M_PI_2;
    CGFloat t = 0.5 + 0.5 * sinf(s);
    i.red = (1-t) * _i1.red + t * _i2.red;
    i.green = (1-t) * _i1.green + t * _i2.green;
    i.blue = (1-t) * _i1.blue + t * _i2.blue;
    
    [self changeIntrinsicColourTo:i withMaxDistance:_intrinsicDistance mode:_intrinsicMode];
    currentIntrinsicColour = i;
    
    if (frame == _iDestinationFrame) {
        _iAnimation = NO;
        if ((currentIntrinsicColour.red == 0) && (currentIntrinsicColour.green == 0) && (currentIntrinsicColour.blue == 0)) {
            _intrinsicColour = NO;
        }
    }

}

- (void)calculateDiffusion {
    Vector pos = [self currentTranslation];
    
    Vector adj;
    adj.x = adj.y = adj.z = 0;
    bool relocationRequired = NO;
    Vector relocationTranslation;
    if (_diffusionWithBorders) {
        if (pos.x - kPoolBorderProximity < _diffusionMinCorner.x) {
            adj.x = _diffusionTranslateChangeMagnitude * (1 - (pos.x - _diffusionMinCorner.x) / kPoolBorderProximity);
        } else if (pos.x + kPoolBorderProximity > _diffusionMaxCorner.x) {
            adj.x = -1 * _diffusionTranslateChangeMagnitude * (1 - (_diffusionMaxCorner.x - pos.x) / kPoolBorderProximity);
        }
        
        if (pos.y - kPoolBorderProximity < _diffusionMinCorner.y) {
            adj.y = _diffusionTranslateChangeMagnitude * (1 - (pos.y - _diffusionMinCorner.y) / kPoolBorderProximity);
        } else if (pos.y + kPoolBorderProximity > _diffusionMaxCorner.y) {
            adj.y = -1 * _diffusionTranslateChangeMagnitude * (1 - (_diffusionMaxCorner.y - pos.y) / kPoolBorderProximity);
        }
        if (pos.z - kPoolBorderProximity < _diffusionMinCorner.z) {
            adj.z = _diffusionTranslateChangeMagnitude * (1 - (pos.z - _diffusionMinCorner.z) / kPoolBorderProximity);
        } else if (pos.z + kPoolBorderProximity > _diffusionMaxCorner.z) {
            adj.z = -1 * _diffusionTranslateChangeMagnitude * (1 - (_diffusionMaxCorner.z - pos.z) / kPoolBorderProximity);
        }
    } else if (_diffusionWithCurvedBorders) {
        Vector xyPos = pos;
        xyPos.z = 0;
        float outerT = [_diffusionOutsideCurve tValueClosestToPoint:xyPos withResolution:1.0];
        Vector outerClosestPoint = [_diffusionOutsideCurve getValueAtT:outerT];
        outerClosestPoint.w = 1.0;
        bool inside = [_diffusionOutsideCurve xySurroundsPoint:xyPos withResolution:1.0];
        float outerDist = vector_size(vector_subtract(outerClosestPoint, xyPos));
        if (!inside) {
            Vector gridDirection;
            gridDirection.x = 0;
            gridDirection.y = 0;
            gridDirection.z = _diffusionGridZForInsideNormal;
            gridDirection.w = 0.0;
            
//            Vector normal = [_diffusionOutsideCurve getNormalAtT:outerT withCrossVector:gridDirection];
            Vector normal = unit_vector(vector_subtract(outerClosestPoint, xyPos));
            Vector move = vector_scale(normal, outerDist);
            adj = vector_add(adj, move);
            
            if (outerDist > kPoolBorderProximity) {
                relocationRequired = YES;
//                relocationTranslation = vector_subtract(outerClosestPoint, pos);
            }
        }else if (outerDist < kPoolBorderProximity) {
            Vector gridDirection;
            gridDirection.x = 0;
            gridDirection.y = 0;
            gridDirection.z = _diffusionGridZForInsideNormal;
            gridDirection.w = 0.0;
            
            Vector normal = [_diffusionOutsideCurve getNormalAtT:outerT withCrossVector:gridDirection];
            Vector move = vector_scale(normal, _diffusionTranslateMaxSpeed * (1 - outerDist / kPoolBorderProximity));
            adj = vector_add(adj, move);
        }
        if (_diffusionInsideCurve) {
            float innerT = [_diffusionInsideCurve tValueClosestToPoint:xyPos withResolution:1.0];
            Vector innerClosestPoint = [_diffusionInsideCurve getValueAtT:innerT];
            float innerDist = vector_size(vector_subtract(innerClosestPoint, xyPos));
            if (innerDist < kPoolBorderProximity) {
                Vector gridDirection;
                gridDirection.x = 0;
                gridDirection.y = 0;
                gridDirection.z = 1.0;
                gridDirection.w = 0.0;
                
                Vector normal = [_diffusionInsideCurve getNormalAtT:innerT withCrossVector:gridDirection];
                Vector move = vector_scale(normal, _diffusionTranslateMaxSpeed * (1 - innerDist / kPoolBorderProximity));
                adj = vector_add(adj, move);
            }
        }
        //XY dealt with curve, do Z manually
        if (pos.z + kPoolBorderProximity > _diffusionZFar) {
            adj.z = -1 * _diffusionTranslateChangeMagnitude * (1 - (_diffusionZFar - pos.z) / kPoolBorderProximity);
        } else if (pos.z - kPoolBorderProximity < _diffusionZNear) {
            adj.z = _diffusionTranslateChangeMagnitude * (1 - (pos.z - _diffusionZNear) / kPoolBorderProximity);
        }
    }
    //Weight the exclusion zones up to really prevent things from going through...
    if ([_poolExclusionZones count] > 0) {
        NSEnumerator *positionEnum = [_poolExclusionZones objectEnumerator];
        modelObject *exclusionObject;
        
        while (exclusionObject = [positionEnum nextObject]) {
            Vector exclusionCenter = [exclusionObject positionAndRadiusOfEncompassingSphere];
            float radius = exclusionCenter.w;
            exclusionCenter.w = 1.0;
            
            if (vector_size(vector_subtract(pos, exclusionCenter)) < radius + kPoolBorderProximity) {
                Vector dir = unit_vector(vector_subtract(pos, exclusionCenter));
                float scale;
                float lengthPastRadius = vector_size(vector_subtract(pos, exclusionCenter)) - radius;
                if (lengthPastRadius < 0) {
                    scale = _diffusionTranslateChangeMagnitude * 6;
                } else {
                    scale = lengthPastRadius / kPoolBorderProximity * _diffusionTranslateChangeMagnitude;
                }
                dir = vector_scale(dir, scale);
                adj = vector_add(adj, dir);
            }
        }

    }
    
//    if (fabsf(adj.x) > 0.1) {
//        _diffusionTranslateChangeVector.x = _diffusionTranslateChangeVector.x + adj.x;
//    } else {
        _diffusionTranslateChangeVector.x = _diffusionTranslateChangeVector.x + ([[randomNumberGenerator sharedInstance] getRandomShort] / (float)INT16_MAX) * _diffusionTranslateChangeMagnitude + adj.x;
//    }
//    if (fabsf(adj.y) > 0.1) {
//        _diffusionTranslateChangeVector.y = _diffusionTranslateChangeVector.y + adj.y;
//    } else {
        _diffusionTranslateChangeVector.y = _diffusionTranslateChangeVector.y + ([[randomNumberGenerator sharedInstance] getRandomShort] / (float)INT16_MAX) * _diffusionTranslateChangeMagnitude + adj.y;
//    }
//    if (fabsf(adj.z > 0.1)) {
//        _diffusionTranslateChangeVector.z = _diffusionTranslateChangeVector.z + adj.z;
//    } else {
        _diffusionTranslateChangeVector.z = _diffusionTranslateChangeVector.z + ([[randomNumberGenerator sharedInstance] getRandomShort] / (float)INT16_MAX) * _diffusionTranslateChangeMagnitude + adj.z;
//    }
    _diffusionTranslateChangeVector.w = 0;
    
    float len = vector_size(_diffusionTranslateChangeVector);
    if ((len > _diffusionTranslateMaxSpeed) && (!relocationRequired)) {
        _diffusionTranslateChangeVector = vector_scale(_diffusionTranslateChangeVector, _diffusionTranslateMaxSpeed/len);
    }
    
    _diffusionRotateChangeVector.x = _diffusionRotateChangeVector.x + ([[randomNumberGenerator sharedInstance] getRandomShort] / (float)INT16_MAX) * _diffusionRotateChangeMagnitude;
    _diffusionRotateChangeVector.y = _diffusionRotateChangeVector.y + ([[randomNumberGenerator sharedInstance] getRandomShort] / (float)INT16_MAX) * _diffusionRotateChangeMagnitude;
    _diffusionRotateChangeVector.z = _diffusionRotateChangeVector.z + ([[randomNumberGenerator sharedInstance] getRandomShort] / (float)INT16_MAX) * _diffusionRotateChangeMagnitude;
    _diffusionRotateChangeVector.w = 0;
    
    len = vector_size(_diffusionRotateChangeVector);
    if (len > _diffusionRotateMaxSpeed) {
        _diffusionRotateChangeVector = vector_scale(_diffusionRotateChangeVector, _diffusionRotateMaxSpeed/len);
    }
    
    _diffusionRotateVector = vector_add(_diffusionRotateVector, _diffusionRotateChangeVector);
//    if (relocationRequired) {
//        _diffusionTranslateVector = vector_add(_diffusionTranslateVector, relocationTranslation);
//    } else {
        _diffusionTranslateVector = vector_add(_diffusionTranslateVector, _diffusionTranslateChangeVector);
//    }
    [self resetAnimationTranslation];
    [self animationRotateAroundX:_diffusionRotateVector.x Y:_diffusionRotateVector.y Z:_diffusionRotateVector.z];
    [self animationTranslateToX:_diffusionTranslateVector.x Y:_diffusionTranslateVector.y Z:_diffusionTranslateVector.z];
//    printf("\nf: %i, adj: %.2f %.2f %.2f, tc: %.2f %.2f %.2f r: %.2f %.2f %.2f, t: %.2f %.2f %.2f\n", _previousFrame, adj.x, adj.y, adj.z, _diffusionTranslateChangeVector.x, _diffusionTranslateChangeVector.y, _diffusionTranslateChangeVector.z, _diffusionRotateVector.x, _diffusionRotateVector.y, _diffusionRotateVector.z, _diffusionTranslateVector.x, _diffusionTranslateVector.y, _diffusionTranslateVector.z);
}

- (void)calculateRotationDiffusion {
    _diffusionRotateChangeVector.x = _diffusionRotateChangeVector.x + ([[randomNumberGenerator sharedInstance] getRandomShort] / (float)INT16_MAX) * _diffusionRotateChangeMagnitude;
    _diffusionRotateChangeVector.y = _diffusionRotateChangeVector.y + ([[randomNumberGenerator sharedInstance] getRandomShort] / (float)INT16_MAX) * _diffusionRotateChangeMagnitude;
    _diffusionRotateChangeVector.z = _diffusionRotateChangeVector.z + ([[randomNumberGenerator sharedInstance] getRandomShort] / (float)INT16_MAX) * _diffusionRotateChangeMagnitude;
    _diffusionRotateChangeVector.w = 0;
    
    float len = vector_size(_diffusionRotateChangeVector);
    if (len > _diffusionRotateMaxSpeed) {
        _diffusionRotateChangeVector = vector_scale(_diffusionRotateChangeVector, _diffusionRotateMaxSpeed/len);
    }
    
    _diffusionRotateVector = vector_add(_diffusionRotateVector, _diffusionRotateChangeVector);
    [self animationRotateAroundX:_diffusionRotateVector.x Y:_diffusionRotateVector.y Z:_diffusionRotateVector.z];
}

- (bool)hasClipSet {
    bool clipSet = _clipSet;
    
    for (int i = 0; i < [children count]; i++) {
        clipSet = clipSet || [[children objectAtIndex:i] hasClipSet];
    }
    
    return clipSet;
}

- (void)setClipForModelTo:(bool)clipEnabled {
    _clipSet = YES;
    _clipApplied = clipEnabled;
    
    for (int i = 0; i < (int)numModelData; i++) {
        float *atom = transformedModelData + NUM_ATOMDATA * i;
        *(atom + CLIP_APPLIED) = _clipApplied;
    }

}

- (bool)hasDiffuseColour {
    bool customColour = _diffuseColour;
    
    for (int i = 0; i < [children count]; i++) {
        customColour = customColour || [[children objectAtIndex:i] hasDiffuseColour];
    }
    
    return customColour;
}

- (bool)hasSpecColour {
    bool customColour = _specColour;
    
    for (int i = 0; i < [children count]; i++) {
        customColour = customColour || [[children objectAtIndex:i] hasSpecColour];
    }
    
    return customColour;
}

- (bool)hasIntrinsicColour {
    bool customColour = _intrinsicColour;
    
    for (int i = 0; i < [children count]; i++) {
        customColour = customColour || [[children objectAtIndex:i] hasIntrinsicColour];
    }
    
    return customColour;
}

- (bool)animatingModelStates {
    return _stateAnimation;
}

- (NSArray *)animatingModelStateChildren {
    NSEnumerator *childEnum = [children objectEnumerator];
    modelObject *child;
    
    NSMutableArray *stateAnimChildren = [NSMutableArray arrayWithCapacity:[children count]];
    while (child = [childEnum nextObject]) {
        if ([child animatingModelStates]) {
            [stateAnimChildren addObject:child];
        }
    }
    
    return stateAnimChildren;
}

- (void)setState:(float)s {
    _state = s;
}

- (bool)hasModelStateCycled {
    return _stateCycle;
}

- (bool)calculateAnimationWithFrame:(int)frame {

    bool animationOccured = NO;
    if (frame != _previousFrame) {

        if (_pool) {
            dispatch_semaphore_wait(_childModificationSemaphore, DISPATCH_TIME_FOREVER);
//            printf("Animating pool");
            NSMutableArray *childAnimationOccured = [NSMutableArray arrayWithCapacity:[children count]];
            for (int i = 0; i < [children count]; i++) {
                dispatch_group_async(_dispatch_group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
                    [childAnimationOccured addObject:[NSNumber numberWithBool:[[children objectAtIndex:i] calculateAnimationWithFrame:frame]]];
                });
            }
            dispatch_group_wait(_dispatch_group, DISPATCH_TIME_FOREVER);
//            printf("Animation Finished");
            for (int i = 0; i < [childAnimationOccured count]; i++) {
                animationOccured |= [[childAnimationOccured objectAtIndex:i] boolValue];
            }
//            printf("Animation Count finished\n");
            dispatch_semaphore_signal(_childModificationSemaphore);

        } else {
            for (int i = 0; i < [children count]; i++) {
                animationOccured |= [[children objectAtIndex:i] calculateAnimationWithFrame:frame];
            }
        }
        
        copyMatrix(&_AnimationTransform, _AnimationStart);
        copyMatrix(&_AnimationTransformInverse, _AnimationStartInverse);
        if ([self selfCurrentlyAnimating]) {
            if (_stateChangeRateAnimation) {
                [self calculateStateChangeRateAnimationWithFrame:frame];
            }
            if (_stateAnimation) {
                if (_stateWobbleEnabled) {
                    _stateBeforeWobble = _stateBeforeWobble + _stateChangeRate;
                    if (_stateBeforeWobble >= _stateAnimationDuration) {
                        _stateBeforeWobble = _stateBeforeWobble - (float)_stateAnimationDuration;
                        _stateCycle = YES;
                    } else {
                        _stateCycle = NO;
                    }
                    static bool dir = YES;
                    if (dir) {
                        _stateCurrentWobble += _stateWobbleChangeMagnitude;
                        if (_stateCurrentWobble > _stateNextWobble) {
                            dir = NO;
                            _stateNextWobble = _stateWobbleMin + ([[randomNumberGenerator sharedInstance] getRandomUShort] / (float)UINT16_MAX) * (_stateWobbleMax - _stateWobbleMin);
                            _stateNextWobble *= -1.0f;
                        }
                    } else {
                        _stateCurrentWobble -= (_stateWobbleChangeMagnitude + _stateChangeRate);
                        if (_stateCurrentWobble < _stateNextWobble) {
                            dir = YES;
                            _stateNextWobble = _stateWobbleMin + ([[randomNumberGenerator sharedInstance] getRandomUShort] / (float)UINT16_MAX) * (_stateWobbleMax - _stateWobbleMin);
                        }
                    }
                    _state = _stateBeforeWobble + _stateCurrentWobble;
                } else {
                    _state = _state + _stateChangeRate;
                    if (_state >= _stateAnimationDuration) {
                        _state = _state - (float)_stateAnimationDuration;
                        _stateCycle = YES;
                    } else {
                        _stateCycle = NO;
                    }
                }
                NSEnumerator *childEnum = [children objectEnumerator];
                modelObject *c;
                while (c = [childEnum nextObject]) {
                    [c setState:_state];
                }
            }
            if (_diffusionRotationOnly) {
                [self calculateRotationDiffusion];
            }
            if (_curveTAnimation) {
                [self calculateCurveTAnimationWithFrame:frame];
            }
            if (_curveAnimation) {
                [self calculateCurveAnimationWithFrame:frame];
            }
            if (_diffusionCurveAnimation) {
                [self calculateDiffusionCurveAnimationWithFrame:frame];
            }
            if (_diffusionEnabled) {
                [self calculateDiffusion];
            }
            if (_ctAnimation) {
                [self calculateTranslationAlongCurveAnimationWithFrame:frame];
            }
            if (_dAnimation) {
                [self calculateDiffuseColourAnimationWithFrame:frame];
            }
            if (_sAnimation) {
                [self calculateSpecularColourAnimationWithFrame:frame];
            }
            if (_iAnimation) {
                [self calculateIntrinsicColourAnimationWithFrame:frame];
            }
            if (_raAnimation) {
                [self calculateRotationAxisAnimationWithFrame:frame];
            }
            if (_rAnimation) {
                [self calculateRotationAnimationWithFrame:frame];
            }
            if (_ltAnimation) {
                [self calculateLinearTranslationAnimationWithFrame:frame];
            }
            if (_tAnimation) {
                [self calculateTranslationAnimationWithFrame:frame];
            }
            copyMatrix(&transform, _AnimationTransform);
            copyMatrix(&inverseTransform, _AnimationTransformInverse);
            animationOccured = YES;
            _positionChangeSinceLastAverageCalculation = YES;
        }
        _previousFrame = frame;
        
    }
    return animationOccured;
}

- (bool)selfCurrentlyAnimating {
    if (_tAnimation || _ltAnimation || _rAnimation || _sAnimation || _dAnimation || _iAnimation || _stateAnimation || _curveAnimation || _curveTAnimation || _wobbleEnabled || _diffusionEnabled || _ctAnimation || _diffusionRotationOnly || _diffusionCurveAnimation || _raAnimation) {
        return YES;
    }
    return NO;
}

//- (bool)currentlyAnimating {
//    if ([self selfCurrentlyAnimating]) {
//        return YES;
//    } else {
//        bool childrenAnimating = NO;
//        for (int i = 0; i < [children count]; i++) {
//            childrenAnimating = childrenAnimating || [[children objectAtIndex:i] currentlyAnimating];
//        }
//        return childrenAnimating;
//    }
//}

- (void)copyAnimationStartMatrices {
    if (![self selfCurrentlyAnimating]) {
        copyMatrix(&_AnimationStart, transform);
        copyMatrix(&_AnimationStartInverse, inverseTransform);
    }

}

- (void)animationTranslateToX:(float)x Y:(float)y Z:(float)z {
    Matrix tempMatrix;
    
    makeMatrix(&tempMatrix,
               1, 0, 0, x,
               0, 1, 0, y,
               0, 0, 1, z,
               0, 0, 0, 1);
    
    multiplyMatrix(tempMatrix, &_AnimationTransform);
    
    makeMatrix(&tempMatrix,
               1, 0, 0, -x,
               0, 1, 0, -y,
               0, 0, 1, -z,
               0, 0, 0, 1);
    rightMultiplyMatrix(&_AnimationTransformInverse, tempMatrix);
}

- (void)animationEndTranslateToX:(float)x Y:(float)y Z:(float)z {
    Matrix tempMatrix;
    
    makeMatrix(&tempMatrix,
               1, 0, 0, x,
               0, 1, 0, y,
               0, 0, 1, z,
               0, 0, 0, 1);
    
    multiplyMatrix(tempMatrix, &_AnimationStart);
    
    makeMatrix(&tempMatrix,
               1, 0, 0, -x,
               0, 1, 0, -y,
               0, 0, 1, -z,
               0, 0, 0, 1);
    rightMultiplyMatrix(&_AnimationStartInverse, tempMatrix);
}

- (void)animationRotateAroundX:(float)a Y:(float)b Z:(float)c {
    Matrix tempMatrix;
    
    makeMatrix(&tempMatrix,
               1, 0, 0, 0,
               0, cos(a), -sin(a), 0,
               0, sin(a), cos(a), 0,
               0, 0, 0, 1);
    multiplyMatrix(tempMatrix, &_AnimationTransform);
    
    makeMatrix(&tempMatrix,
               cos(b), 0, sin(b), 0,
               0, 1, 0, 0,
               -sin(b), 0, cos(b), 0,
               0, 0, 0, 1);
    multiplyMatrix(tempMatrix, &_AnimationTransform);
    
    makeMatrix(&tempMatrix,
               cos(c), -sin(c), 0, 0,
               sin(c), cos(c), 0, 0,
               0, 0, 1, 0,
               0, 0, 0, 1);
    multiplyMatrix(tempMatrix, &_AnimationTransform);

    //Inverse
    makeMatrix(&tempMatrix,
               1, 0, 0, 0,
               0, cos(-a), -sin(-a), 0,
               0, sin(-a), cos(-a), 0,
               0, 0, 0, 1);
    rightMultiplyMatrix(&_AnimationTransformInverse, tempMatrix);
    
    makeMatrix(&tempMatrix,
               cos(-b), 0, sin(-b), 0,
               0, 1, 0, 0,
               -sin(-b), 0, cos(-b), 0,
               0, 0, 0, 1);
    rightMultiplyMatrix(&_AnimationTransformInverse, tempMatrix);
    
    makeMatrix(&tempMatrix,
               cos(-c), -sin(-c), 0, 0,
               sin(-c), cos(-c), 0, 0,
               0, 0, 1, 0,
               0, 0, 0, 1);
    rightMultiplyMatrix(&_AnimationTransformInverse, tempMatrix);

}

- (void)animationRotateAroundVector:(Vector)axis angle:(float)a {
    Matrix tempMatrix;
    
    tempMatrix = matrixToRotateAroundAxisByAngle(axis, a);
    multiplyMatrix(tempMatrix, &_AnimationTransform);

    tempMatrix = matrixToRotateAroundAxisByAngle(axis, -a);
    rightMultiplyMatrix(&_AnimationTransformInverse, tempMatrix);
}

- (void)transformWithMatrix:(Matrix)m inverseMatrix:(Matrix)i {
    
    multiplyMatrix(m, &transform);
    rightMultiplyMatrix(&inverseTransform, i);
}

     
- (void)translateToX:(float)x Y:(float)y Z:(float)z {
    Matrix tempMatrix;
    
    makeMatrix(&tempMatrix,
               1, 0, 0, x,
               0, 1, 0, y,
               0, 0, 1, z,
               0, 0, 0, 1);
    
    multiplyMatrix(tempMatrix, &transform);
    
    //Inverse
    makeMatrix(&tempMatrix,
               1, 0, 0, -x,
               0, 1, 0, -y,
               0, 0, 1, -z,
               0, 0, 0, 1);
    rightMultiplyMatrix(&inverseTransform, tempMatrix);
}

- (void)rotateAroundX:(float)a Y:(float)b Z:(float)c {
    Matrix tempMatrix;
    
    makeMatrix(&tempMatrix,
               1, 0, 0, 0,
               0, cos(a), -sin(a), 0,
               0, sin(a), cos(a), 0,
               0, 0, 0, 1);
    multiplyMatrix(tempMatrix, &transform);
    
    makeMatrix(&tempMatrix,
               cos(b), 0, sin(b), 0,
               0, 1, 0, 0,
               -sin(b), 0, cos(b), 0,
               0, 0, 0, 1);
    multiplyMatrix(tempMatrix, &transform);
    
    makeMatrix(&tempMatrix,
               cos(c), -sin(c), 0, 0,
               sin(c), cos(c), 0, 0,
               0, 0, 1, 0,
               0, 0, 0, 1);
    multiplyMatrix(tempMatrix, &transform);
    
    //Inverse
    makeMatrix(&tempMatrix,
               1, 0, 0, 0,
               0, cos(-a), -sin(-a), 0,
               0, sin(-a), cos(-a), 0,
               0, 0, 0, 1);
    rightMultiplyMatrix(&inverseTransform, tempMatrix);
    
    makeMatrix(&tempMatrix,
               cos(-b), 0, sin(-b), 0,
               0, 1, 0, 0,
               -sin(-b), 0, cos(-b), 0,
               0, 0, 0, 1);
    rightMultiplyMatrix(&inverseTransform, tempMatrix);
    
    makeMatrix(&tempMatrix,
               cos(-c), -sin(-c), 0, 0,
               sin(-c), cos(-c), 0, 0,
               0, 0, 1, 0,
               0, 0, 0, 1);
    rightMultiplyMatrix(&inverseTransform, tempMatrix);
    

}

- (void)rotateAroundVector:(Vector)axis byAngle:(float)rotationAngle {
    Matrix tempMatrix;
    
/*    float t = 1 - cosf(rotationAngle);
    float c = cosf(rotationAngle);
    float s = sinf(rotationAngle);
    makeMatrix(&tempMatrix,
               t * axis.x * axis.x + c, t * axis.x * axis.y - s * axis.z, t * axis.x * axis.z + s * axis.y, 0,
               t * axis.x * axis.y + s * axis.z, t * axis.y * axis.y + c, t * axis.y * axis.z - s * axis.x, 0,
               t * axis.x * axis.z - s * axis.y, t * axis.y * axis.z + s * axis.x, t * axis.z * axis.z + c, 0,
               0, 0, 0, 1);*/
    tempMatrix = matrixToRotateAroundAxisByAngle(axis, rotationAngle);
    multiplyMatrix(tempMatrix, &transform);
    
    tempMatrix = matrixToRotateAroundAxisByAngle(axis, -rotationAngle);
    rightMultiplyMatrix(&inverseTransform, tempMatrix);
    
}

- (void)centerPDBModelOnOrigin {
    [self translateToX:-1.0 * data.bvhMain.x Y:-1.0 * data.bvhMain.y Z:-1.0 * data.bvhMain.z];
}

- (void)centerModelOnOrigin {
    int t = 0;
    float x = 0, y = 0, z = 0;
    
    if (hasModelData) {
        t++;
        x = data.bvhMain.x;
        y = data.bvhMain.y;
        z = data.bvhMain.z;
    }
    
    for (int i = 0; i < [transformedBvhObjects count]; i++) {
        t++;
        bvhObject *current = [transformedBvhObjects objectAtIndex:i];
        x = x + current.x;
        y = y + current.y;
        z = z + current.z;
    }
    x = x / (float)t;
    y = y / (float)t;
    z = z / (float)t;
    
    [self translateToX:-1.0 * x Y:-1.0 * y Z:-1.0 * z];
}

- (void)applyTransformation {
    
    if (_wobbleEnabled) {
        for (int i = 0; i < _wobbleNumAtoms; i++) {
//            *(_wobbleVectors + i * 3 + 0) = *(_wobbleVectors + i * 3 + 0) + ([[randomNumberGenerator sharedInstance] getRandomShort] / (float)INT16_MAX) * _wobbleChangeMagnitude;
//            *(_wobbleVectors + i * 3 + 1) = *(_wobbleVectors + i * 3 + 1) + ([[randomNumberGenerator sharedInstance] getRandomShort] / (float)INT16_MAX) * _wobbleChangeMagnitude;
//            *(_wobbleVectors + i * 3 + 2) = *(_wobbleVectors + i * 3 + 2) + ([[randomNumberGenerator sharedInstance] getRandomShort] / (float)INT16_MAX) * _wobbleChangeMagnitude;
            Vector wobbleVector;
            wobbleVector.x = *(_wobbleVectors + i * 3 + 0) + ([[randomNumberGenerator sharedInstance] getRandomShort] / (float)INT16_MAX) * _wobbleChangeMagnitude;
            wobbleVector.y = *(_wobbleVectors + i * 3 + 1) + ([[randomNumberGenerator sharedInstance] getRandomShort] / (float)INT16_MAX) * _wobbleChangeMagnitude;
            wobbleVector.z = *(_wobbleVectors + i * 3 + 2) + ([[randomNumberGenerator sharedInstance] getRandomShort] / (float)INT16_MAX) * _wobbleChangeMagnitude;
            float len = vector_size(wobbleVector);
            if (len > _wobbleMaxRadius) {
                wobbleVector = vector_scale(wobbleVector, _wobbleMaxRadius/len);
            }
            *(_wobbleVectors + i * 3 + 0) = wobbleVector.x;
            *(_wobbleVectors + i * 3 + 1) = wobbleVector.y;
            *(_wobbleVectors + i * 3 + 2) = wobbleVector.z;
            
        }

    }
    
    NSEnumerator *childEnumerator = [children objectEnumerator];
    modelObject *child;
    while (child = [childEnumerator nextObject]) {
        [child applyTransformation];
    }

    bool recopy = NO;
    for (int i = 0; i < [children count]; i++) {
        recopy |= [[children objectAtIndex:i] parentShouldRecopyModelData];
    }
    if (recopy) {
        [self recopyAllModelData];
        _triggerRecopyModelData = [parentModels count];
    }
    
    int models = (int)[children count];
    if (hasModelData) {
        models++;
    }
    
    self.transformedBvhObjects = [NSMutableArray arrayWithCapacity:models];
    
    NSUInteger offset = 0;
    NSUInteger intrinsicLightOffset = 0;

    if ([self hasIntrinsicColour]) {
        [self recopyLightData];
    }

//    childEnumerator = [children objectEnumerator];
    
//    while (child = [childEnumerator nextObject]) {
    for (int c = 0; c < [children count]; c++) {
        modelObject *child = [children objectAtIndex:c];
        
        bool *childCopiedArray;
        if (!interModelAtomOverlapsAllowed) {
            childCopiedArray = atomCopiedArray[c];
        }
//        [child applyTransformation];
        
//        if ([child parentShouldRecopyModelData]) {
//            [self recopyAllModelData];
//            _triggerRecopyModelData = [parentModels count];
//        }

        bool copyDiffuseColour = NO;
        bool copySpecColour = NO;
        bool copyIntrinsicColour = NO;
        bool copyClipSet = NO;
        if ((!_diffuseColour) && ([child hasDiffuseColour])) {
            copyDiffuseColour = YES;
        }
        if ((!_specColour) && ([child hasSpecColour])) {
            copySpecColour = YES;
        }
        if ((!_intrinsicColour) && ([child hasIntrinsicColour])) {
            copyIntrinsicColour = YES;
        }
        if ((!_clipSet) && ([child hasClipSet])) {
            copyClipSet = YES;
        }
        
        for (int i = 0; i < (int)child.numModelData; i++) {
            if ((interModelAtomOverlapsAllowed) || (childCopiedArray[i])) {
                Vector a;
                float *atom = child.transformedModelData + NUM_ATOMDATA * i;
                a.x = *(atom + X);
                a.y = *(atom + Y);
                a.z = *(atom + Z);
                a.w = 1;
                
                Vector r = vectorMatrixMultiply(transform, a);
                float *dst = transformedModelData + NUM_ATOMDATA * offset;
                
                if (_wobbleEnabled) {
                    *(dst + X) = r.x + *(_wobbleVectors + offset * 3 + 0);
                    *(dst + Y) = r.y + *(_wobbleVectors + offset * 3 + 1);
                    *(dst + Z) = r.z + *(_wobbleVectors + offset * 3 + 2);
                } else {
                    *(dst + X) = r.x;
                    *(dst + Y) = r.y;
                    *(dst + Z) = r.z;
                }
                
                if (copyDiffuseColour) {
                    *(dst + DIFFUSE_R) = *(atom + DIFFUSE_R);
                    *(dst + DIFFUSE_G) = *(atom + DIFFUSE_G);
                    *(dst + DIFFUSE_B) = *(atom + DIFFUSE_B);
                }
                if (copySpecColour) {
                    *(dst + SPEC_R) = *(atom + SPEC_R);
                    *(dst + SPEC_G) = *(atom + SPEC_G);
                    *(dst + SPEC_B) = *(atom + SPEC_B);
                }
                if (copyIntrinsicColour) {
                    *(dst + INTRINSIC_R) = *(atom + INTRINSIC_R);
                    *(dst + INTRINSIC_G) = *(atom + INTRINSIC_G);
                    *(dst + INTRINSIC_B) = *(atom + INTRINSIC_B);
                }
                if (copyClipSet) {
                    *(dst + CLIP_APPLIED) = *(atom + CLIP_APPLIED);
                } else if (_clipSet) {
                    *(dst + CLIP_APPLIED) = _clipApplied;
                }
                offset++;
            }
        }
        
        for (int i = 0; i < [child.transformedBvhObjects count]; i++) {
            bvhObject *current = [child.transformedBvhObjects objectAtIndex:i];
            bvhObject *transformedBVH = [current copyWithTransform:transform];
            [transformedBvhObjects addObject:transformedBVH];
        }

        if (child.hasIntrinsicColour) {
            for (int i = 0; i < child.numIntrinsicLights; i++) {
                Vector a;
                float *atom = child.transformedIntrinsicLights + NUM_INTRINSIC_LIGHT_DATA * i;
                a.x = *(atom + X);
                a.y = *(atom + Y);
                a.z = *(atom + Z);
                a.w = 1;

                Vector r = vectorMatrixMultiply(transform, a);
                float *dst = transformedIntrinsicLights + NUM_INTRINSIC_LIGHT_DATA * intrinsicLightOffset;
                *(dst + XI) = r.x;
                *(dst + YI) = r.y;
                *(dst + ZI) = r.z;
                intrinsicLightOffset++;
            }
        }
        
    }
    
    //Last Data directly here
    if (hasModelData) {
        bool dataWithIntrinsicLight = NO;
        if ((_intrinsicColour) || (data.intrinsic_R > 0) || (data.intrinsic_G > 0) || (data.intrinsic_B)) {
            dataWithIntrinsicLight = YES;
        }
//        [data selectState:_state];
        [data selectFractionalState:_state];
        for (int i = 0; i < (int)data.numAtoms; i++) {
            Vector a;
            float *atom = data.modelData + NUM_ATOMDATA * i;
            a.x = *(atom + X);
            a.y = *(atom + Y);
            a.z = *(atom + Z);
            a.w = 1;
            
            Vector r = vectorMatrixMultiply(transform, a);
            float *dst = transformedModelData + NUM_ATOMDATA * offset;
            if (_wobbleEnabled) {
                *(dst + X) = r.x + *(_wobbleVectors + offset * 3 + 0);
                *(dst + Y) = r.y + *(_wobbleVectors + offset * 3 + 1);
                *(dst + Z) = r.z + *(_wobbleVectors + offset * 3 + 2);
            } else {
                *(dst + X) = r.x;
                *(dst + Y) = r.y;
                *(dst + Z) = r.z;
            }
            if (dataWithIntrinsicLight) {
                float *light = transformedIntrinsicLights + NUM_INTRINSIC_LIGHT_DATA * intrinsicLightOffset;
                *(light + XI) = *(dst + X);
                *(light + YI) = *(dst + Y);
                *(light + ZI) = *(dst + Z);
                intrinsicLightOffset++;
            }
            offset++;
        }
     
        bvhObject *transformedBVH = [data.bvhMain copyWithTransform:transform];
        [transformedBvhObjects addObject:transformedBVH];
    }
//    [self logIntrinsicLightData];
}

- (Vector)averagePosition {
    NSEnumerator *bvhEnumerator = [transformedBvhObjects objectEnumerator];
    bvhObject *bvh;
    
    Vector pos;
    pos.x = pos.y = pos.z = pos.w = 0;
    while (bvh = [bvhEnumerator nextObject]) {
        pos.x += bvh.x;
        pos.y += bvh.y;
        pos.z += bvh.z;
    }
    pos.x = pos.x / [transformedBvhObjects count];
    pos.y = pos.y / [transformedBvhObjects count];
    pos.z = pos.z / [transformedBvhObjects count];
    
    return pos;
}

- (Vector)currentTranslation {
    Vector r;
    r.x = transform.element[0][3];
    r.y = transform.element[1][3];
    r.z = transform.element[2][3];
    r.w = transform.element[3][3];
    
    return r;
}

- (void)centerModelOnCenterOfMass {
    Vector com = [self centerOfMass];
    [self translateToX:-com.x Y:-com.y Z:-com.z];
}

- (Vector)centerOfMass {
    if (_positionChangeSinceLastAverageCalculation) {
        
        _com.x = _com.y = _com.z = 0;
        _com.w = 1.0;
        for (int i = 0; i < numModelData; i++) {
            float *atom = transformedModelData + NUM_ATOMDATA * i;
            float x = *(atom + X);
            float y = *(atom + Y);
            float z = *(atom + Z);
            _com.x += x;
            _com.y += y;
            _com.z += z;
        }
        _com.x = _com.x / (float)numModelData;
        _com.y = _com.y / (float)numModelData;
        _com.z = _com.z / (float)numModelData;;
    }
    return _com;

}

- (Vector)positionAndRadiusOfEncompassingSphere {
    
    if (_positionChangeSinceLastAverageCalculation) {
        
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
        
        Vector r;
        r.x = (xMin + xMax) / 2.0f;
        r.y = (yMin + yMax) / 2.0f;
        r.z = (zMin + zMax) / 2.0f;
        
        //Assume globular particles rather than square...
//        float xLen = r.x - xMin;
//        float yLen = r.y - yMin;
//        float zLen = r.z - zMin;
//        float maxLen = xLen;
//        if (yLen > maxLen)
//            maxLen = yLen;
//        if (zLen > maxLen)
//            maxLen = zLen;
//        r.w = maxLen;
        //Stick with safe encompassing sphere
        r.w = sqrtf((r.x - xMin) * (r.x - xMin) + (r.y - yMin) * (r.y - yMin) + (r.z - zMin) * (r.z - zMin));
        _encompassingSphere = r;
    }
    return _encompassingSphere;
}

- (Vector)transformWithCurrentTransform:(Vector)p {
    return vectorMatrixMultiply(transform, p);
}

- (Vector)transformCoordinate:(Vector)p inSystemOfChild:(modelObject *)target {
    
    Vector r;

    r.x = INFINITY;
    
    if (self == target) {
        r = [self transformWithCurrentTransform:p];
        return r;
    }
    if ([children count] == 0) {
//        NSLog(@"Error: No children in search for target!");
        r.x = r.y = r.z = r.w = INFINITY;
        return r;
    }// else if ([children count] > 1) {
//        NSLog(@"Error: More that one child in search for target - results not defined...");
//    }

    NSEnumerator *childEnum = [children objectEnumerator];
    modelObject *child;
    
    while ((child = [childEnum nextObject]) && (isinf(r.x))) {
        if (child == target) {
            r = [child transformWithCurrentTransform:p];
            if (isinf(r.x)) {
                return r;
            }
            r = [self transformWithCurrentTransform:r];
            return r;
        } else {
            r = [child transformCoordinate:p inSystemOfChild:target];
            if (!isinf(r.x)) {
                r = [self transformWithCurrentTransform:r];
            }
        }
    }
    
    return r;
}

- (void)transformIntoCurrentSystemModel:(modelObject *)m inSystemOfChild:(modelObject *)target {
    
    if (self == target) {
        [m transformWithMatrix:transform inverseMatrix:inverseTransform];
    } else if ([children count] == 0) {
        NSLog(@"Error: No children in search for target!");
    } else  {
        //Assume that the first child is what we want...
        modelObject *child = [children objectAtIndex:0];
        [child transformIntoCurrentSystemModel:m inSystemOfChild:target];
        [m transformWithMatrix:transform inverseMatrix:inverseTransform];
    }
        
}

- (void)deleteChildWithName:(NSString *)name {
    
    modelObject *childToDelete = [childNames objectForKey:name];
    if (childToDelete) {
        [self deleteChildModel:childToDelete];
    }
    
    NSEnumerator *childEnum = [children objectEnumerator];
    modelObject *child;
    
    while (child = [childEnum nextObject]) {
        [child deleteChildWithName:name];
    }
}

- (Vector)transformWithInverseTransform:(Vector)p {
    return vectorMatrixMultiply(inverseTransform, p);
}

- (bool)targetMolecule:(modelObject *)t requiredRotationAxis:(Vector *)rotAxis requiredRotationAngle:(float *)angle requiredTranslationVector:(Vector *)trans {
    
    //Check we have an identical number of atoms
    if (self.numModelData != t.numModelData) {
        NSLog(@"Error: Comparison between two objects with different number of atoms not performed!");
        return false;
    }
    
    //First make sure all coordinates are up to date
    [self applyTransformation];
    [t applyTransformation];
    
    //Get the center of mass of both
    Vector selfCOM = [self centerOfMass];
    Vector tCOM = [t centerOfMass];
    
    //Shift both to the center of mass
    [self translateToX:-selfCOM.x Y:-selfCOM.y Z:-selfCOM.z];
    [t translateToX:-tCOM.x Y:-tCOM.y Z:-tCOM.z];
    
    [self applyTransformation];
    [t applyTransformation];
    
    Matrix R, U;
    float E = 0;
    
    makeMatrix(&R, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
    
    for (int n = 0; n < numModelData; n++) {
        E += self.transformedModelData[n * NUM_ATOMDATA + X] * self.transformedModelData[n * NUM_ATOMDATA + X] + t.transformedModelData[n * NUM_ATOMDATA + X] * t.transformedModelData[n * NUM_ATOMDATA + X];
        E += self.transformedModelData[n * NUM_ATOMDATA + Y] * self.transformedModelData[n * NUM_ATOMDATA + Y] + t.transformedModelData[n * NUM_ATOMDATA + Y] * t.transformedModelData[n * NUM_ATOMDATA + Y];
        E += self.transformedModelData[n * NUM_ATOMDATA + Z] * self.transformedModelData[n * NUM_ATOMDATA + Z] + t.transformedModelData[n * NUM_ATOMDATA + Z] * t.transformedModelData[n * NUM_ATOMDATA + Z];
        
        R.element[0][0] += self.transformedModelData[n * NUM_ATOMDATA + 0] * t.transformedModelData[n * NUM_ATOMDATA + 0];
        R.element[0][1] += self.transformedModelData[n * NUM_ATOMDATA + 0] * t.transformedModelData[n * NUM_ATOMDATA + 1];
        R.element[0][2] += self.transformedModelData[n * NUM_ATOMDATA + 0] * t.transformedModelData[n * NUM_ATOMDATA + 2];
        R.element[1][0] += self.transformedModelData[n * NUM_ATOMDATA + 1] * t.transformedModelData[n * NUM_ATOMDATA + 0];
        R.element[1][1] += self.transformedModelData[n * NUM_ATOMDATA + 1] * t.transformedModelData[n * NUM_ATOMDATA + 1];
        R.element[1][2] += self.transformedModelData[n * NUM_ATOMDATA + 1] * t.transformedModelData[n * NUM_ATOMDATA + 2];
        R.element[2][0] += self.transformedModelData[n * NUM_ATOMDATA + 2] * t.transformedModelData[n * NUM_ATOMDATA + 0];
        R.element[2][1] += self.transformedModelData[n * NUM_ATOMDATA + 2] * t.transformedModelData[n * NUM_ATOMDATA + 1];
        R.element[2][2] += self.transformedModelData[n * NUM_ATOMDATA + 2] * t.transformedModelData[n * NUM_ATOMDATA + 2];
    }
    
    E *= 0.5;
    float residual;
    
    if (!calculate_rotation_matrix(R, &U, E, &residual)) {
        return false;
    }
    
    *rotAxis = rotationMatrixToAxisAndAngle(U, angle);\
    
    [self translateToX:selfCOM.x Y:selfCOM.y Z:selfCOM.z];
    [t translateToX:tCOM.x Y:tCOM.y Z:tCOM.z];
    
    [self applyTransformation];
    [t applyTransformation];
    
    selfCOM.w = 1.0;
    tCOM.w = 1.0;
    
    *trans = vector_subtract(tCOM, selfCOM);
    
    return true;
}

/*- (Vector)transformCoordinate:(Vector)p intoSystemOfChild:(modelObject *)target {
    Vector r;
    
    if ([children count] == 0) {
        NSLog(@"Error: No children in search for target!");
        r.x = r.y = r.z = r.w = 0;
        return r;
    } else if ([children count] > 1) {
        //        NSLog(@"Error: More that one child in search for target - results not defined...");
    }
    modelObject *child = [children objectAtIndex:0];
    if (child == target) {
        r = [self transformWithInverseTransform:p];
        r = [child transformWithInverseTransform:r];
    } else {
        r = [self transformWithInverseTransform:p];
        r = [child transformCoordinate:r inSystemOfChild:target];
    }
    
    return r;
}*/

- (void)loadData {
    //Setup the bvh arrays
    NSUInteger numMembers = 0;
    NSEnumerator *bvhEnumerator = [transformedBvhObjects objectEnumerator];
    bvhObject *bvhMain;
    NSUInteger numBVHObjects = [transformedBvhObjects count];
    
    while (bvhMain = [bvhEnumerator nextObject]) {
        numBVHObjects = numBVHObjects + [bvhMain.children count];
        numMembers = numMembers + [bvhMain.children count];
        for (int i = 0; i < [bvhMain.children count]; i++) {
            bvhObject *current = [bvhMain.children objectAtIndex:i];
            numMembers = numMembers + [current.children count];
        }
    }

    self.numLookupData = numMembers;
    self.numBVH = numBVHObjects;

    self.transformedBvhData = (bvhStruct *)malloc(sizeof(bvhStruct) * numBVH);
    self.transformedLookupData = (int *)malloc(sizeof(int) * numLookupData);
    
    int memberIndex = 0;
    int startRange, endRange = 0;
    int currentBVH = 0;


    bvhEnumerator = [transformedBvhObjects objectEnumerator];
    
    while (bvhMain = [bvhEnumerator nextObject]) {
        startRange = memberIndex;
        for (int i = 0; i < [bvhMain.children count]; i++) {
            transformedLookupData[memberIndex] = i + (int)[transformedBvhObjects count] + endRange;
            memberIndex++;
        }
        endRange = memberIndex;
        transformedBvhData[currentBVH].x = bvhMain.x;
        transformedBvhData[currentBVH].y = bvhMain.y;
        transformedBvhData[currentBVH].z = bvhMain.z;
        transformedBvhData[currentBVH].radius = bvhMain.radius;
        transformedBvhData[currentBVH].leafNode = NO;
        transformedBvhData[currentBVH].rangeStart = startRange;
        transformedBvhData[currentBVH].rangeEnd = endRange;
        currentBVH++;
    }
    
    bvhEnumerator = [transformedBvhObjects objectEnumerator];
    int atomOffset = 0;
    
    while (bvhMain = [bvhEnumerator nextObject]) {
        for (int i = 0; i < [bvhMain.children count]; i++) {
            startRange = memberIndex;
            bvhObject *current = [bvhMain.children objectAtIndex:i];
            for (int j = 0; j < [current.children count]; j++) {
                int object = (int)[[current.children objectAtIndex:j] integerValue];
                //Need to adjust this to reflect the number of atoms before in the transformed data...
                transformedLookupData[memberIndex] = object + atomOffset;
                memberIndex++;
            }
            endRange = memberIndex;
            transformedBvhData[currentBVH].x = current.x;
            transformedBvhData[currentBVH].y = current.y;
            transformedBvhData[currentBVH].z = current.z;
            transformedBvhData[currentBVH].radius = current.radius;
            transformedBvhData[currentBVH].leafNode = YES;
            transformedBvhData[currentBVH].rangeStart = startRange;
            transformedBvhData[currentBVH].rangeEnd = endRange;
            currentBVH++;
        }
        
        atomOffset = atomOffset + bvhMain.atoms;
    }

}

- (void)logModelData {
//    NSLog(@"BVH");
//    for (int i = 0; i < numBVH; i++) {
//        NSLog(@"%d: %f %f %f r:%f l:%d s:%d e:%d", i, transformedBvhData[i].x, transformedBvhData[i].y, transformedBvhData[i].z, transformedBvhData[i].radius, transformedBvhData[i].leafNode, transformedBvhData[i].rangeStart, transformedBvhData[i].rangeEnd);
//    }
//    NSLog(@"Lookup Data");
//    for (int i = 0; i < numLookupData; i++) {
//        NSLog(@"%d: %d", i, transformedLookupData[i]);
//    }
    NSLog(@"Model Data");
    for (int i = 0; i < numModelData; i++) {
        float *atom = transformedModelData + i * NUM_ATOMDATA;
//        NSLog(@"%d: %f %f %f %f", i, *(atom + X), *(atom + Y), *(atom + Z), *(atom + VDW));
        printf("%d: %f %f %f %f\n", i, *(atom + X), *(atom + Y), *(atom + Z), *(atom + VDW));
    }
}

- (void)logInitialModelData {
//    NSLog(@"Model Data");
    for (int i = 0; i < 10; i++) {
        float *atom = transformedModelData + i * NUM_ATOMDATA;
        //        NSLog(@"%d: %f %f %f %f", i, *(atom + X), *(atom + Y), *(atom + Z), *(atom + VDW));
        printf("%d: %f %f %f %f ", i, *(atom + X), *(atom + Y), *(atom + Z), *(atom + VDW));
    }
    
}

- (void)logClipData {
    printf("Clip\n");
    for (int i = 0; i < numModelData; i++) {
        float *atom = transformedModelData + i * NUM_ATOMDATA;
        printf("%d: %.2f\n", i, *(atom + CLIP_APPLIED));
    }
}

- (void)logIntrinsicLightData {
    NSLog(@"Intrinsic Light Data");
    for (int i = 0; i < numIntrinsicLights; i++) {
        float *light = transformedIntrinsicLights + i * NUM_INTRINSIC_LIGHT_DATA;
        NSLog(@"%d: %f %f %f %f %f %f %f %f %f", i, *(light + XI), *(light + YI), *(light + ZI), *(light + VDWI), *(light + RED), *(light + GREEN), *(light + BLUE), *(light + CUTOFF), *(light + MODE));
    }
}

@end
