//
//  cameraObject.m
//  present
//
//  Created by Callum Smits on 11/07/13.
//  Copyright (c) 2013 Callum Smits. All rights reserved.
//

#import "cameraObject.h"
#import "ray.h"
#import "vector_ops.h"

@interface cameraObject () {
    Vector _ot1, _ot2, _ot3, _ot4;
    int _otDestinationFrame, _otAnimationDuration, _otStartFrame;
    bool _otAnimation;
    Vector _la1, _la2;
    int _laDestinationFrame, _laAnimationDuration, _laStartFrame;
    bool _laAnimation;
    int _previousFrame;
    Vector _up1, _up2;
    int _upDestinationFrame, _upAnimationDuration, _upStartFrame;
    bool _upAnimation;
    float _ll1, _ll2, _a1, _a2, _fl1, _fl2;
    int _llDestinationFrame, _llAnimationDuration, _llStartFrame, _aDestinationFrame, _aAnimationDuration, _aStartFrame, _flDestinationFrame, _flAnimationDuration, _flStartFrame;
    bool _llAnimation, _aAnimation, _flAnimation, _cpAnimation, _foAnimation;
    float _cp1, _cp2;
    int _cpDestinationFrame, _cpAnimationDuration, _cpStartFrame;
    float _foDistance;
    modelObject *_foObject, *_foWorld, *_foParent;
}

- (void)calculateTranslationAnimationWithFrame:(int)frame;
- (void)calculateFocalLengthWithFrame:(int)frame;
- (void)calculateCameraLookAtAnimationWithFrame:(int)frame;
- (void)calculateUpOrientationWithFrame:(int)frame;
- (void)calculateLensLengthAnimationWithFrame:(int)frame;
- (void)calculateApertureWithFrame:(int)frame;
- (void)calculateClipPlaneWithFrame:(int)frame;
- (void)calculateFollowObjectAnimationWithFrame:(int)frame;
- (void)generateRays;

@end

@implementation cameraObject

@synthesize viewRaysChanged, totalNumRays, viewOriginCentralRayDirection, viewOriginCentralRayStart, viewOriginRayStart, cl_viewOriginRayDirectionsArray;
@synthesize aperture, focalLength, actualNumRays, clookAtPoint, cUpOrientation, lensLength, viewWidth;
@synthesize hazeColour, hazeLength, hazeStartDistanceFromCamera, clipPlaneDistanceFromCamera, clipPlaneEnabled;
@synthesize viewOrigin, lookAtPoint, upOrientation;

- (id) init {
    
    self = [super init];
    if (self) {
        cl_viewOriginRayDirectionsArray = nil;
        
        //choose some defaults for the rest...
        windowSize.width = 800;
        windowSize.height = 800;
        viewOrigin.x = viewOrigin.y = 0;
        viewOrigin.z = -100.0;
        viewOrigin.w = 1.0;
        lookAtPoint.x = lookAtPoint.y = lookAtPoint.z = 0.0;
        lookAtPoint.w = 1.0;
        upOrientation.x = upOrientation.z = upOrientation.w = 0.0;
        upOrientation.y = 1.0;
        viewWidth = 20;
        lensLength = 50;
        aperture = 0;
        focalLength = 100;
        clipPlaneEnabled = NO;
        _otAnimation = NO;
        _laAnimation = NO;
        _upAnimation = NO;
        _llAnimation = NO;
        _flAnimation = NO;
        _aAnimation = NO;
        _cpAnimation = NO;
        _foAnimation = NO;
        _previousFrame = 0;
        
        [self generateRays];
    }
    
    return self;
}

- (id)initWithCameraOrigin:(Vector)origin lookAt:(Vector)destination upOrientation:(Vector)up windowSize:(CGSize)size viewWidth:(float)width lensLength:(float)length aperture:(float)newAperture focalLength:(float)newFocalLength {
    self = [super init];
    if (self) {
        cl_viewOriginRayDirectionsArray = nil;
        
        windowSize = size;
        viewOrigin = origin;
        lookAtPoint = destination;
        viewWidth = width;
        lensLength = length;
        upOrientation = up;
        aperture = newAperture;
        focalLength = newFocalLength;
        clipPlaneEnabled = NO;
        _otAnimation = NO;
        _laAnimation = NO;
        _upAnimation = NO;
        _llAnimation = NO;
        _flAnimation = NO;
        _aAnimation = NO;
        _cpAnimation = NO;
        _foAnimation = NO;
        _previousFrame = 0;
        
        [self generateRays];
    }
    
    return self;
}

- (bool)calculateCameraAnimationWithFrame:(int)frame {
    if (_otAnimation || _upAnimation || _laAnimation || _llAnimation || _flAnimation || _aAnimation || _cpAnimation || _foAnimation) {
        if (_otAnimation) {
            [self calculateTranslationAnimationWithFrame:frame];
        }
        if (_upAnimation) {
            [self calculateUpOrientationWithFrame:frame];
        }
        if (_laAnimation) {
            [self calculateCameraLookAtAnimationWithFrame:frame];
        }
        if (_llAnimation) {
            [self calculateLensLengthAnimationWithFrame:frame];
        }
        if (_flAnimation) {
            [self calculateFocalLengthWithFrame:frame];
        }
        if (_aAnimation) {
            [self calculateApertureWithFrame:frame];
        }
        if (_cpAnimation) {
            [self calculateClipPlaneWithFrame:frame];
        }
        if (_foAnimation) {
            [self calculateFollowObjectAnimationWithFrame:frame];
        }
        [self generateRays];
        _previousFrame = frame;
        return YES;
        
    } else {
        
        _previousFrame = frame;
        return NO;
        
    }
}

- (void)calculateTranslationAnimationWithFrame:(int)frame {
    
    if (frame == _otDestinationFrame) {
        viewOrigin = _ot4;
        _otAnimation = NO;
    } else {
        CGFloat s = M_PI * (frame - _otStartFrame)/(CGFloat)_otAnimationDuration - M_PI_2;
        CGFloat t = 0.5 + 0.5 * sinf(s);
        viewOrigin.x = powf(1-t, 3) * _ot1.x + 3 * powf(1-t, 2) * t * _ot2.x + 3 * (1-t) * t * t * _ot3.x + powf(t, 3) * _ot4.x;
        viewOrigin.y = powf(1-t, 3) * _ot1.y + 3 * powf(1-t, 2) * t * _ot2.y + 3 * (1-t) * t * t * _ot3.y + powf(t, 3) * _ot4.y;
        viewOrigin.z = powf(1-t, 3) * _ot1.z + 3 * powf(1-t, 2) * t * _ot2.z + 3 * (1-t) * t * t * _ot3.z + powf(t, 3) * _ot4.z;
    }
}


- (void)animateViewOriginTranslationTo:(Vector)end intermediate1:(Vector)i1 intermediate2:(Vector)i2 duration:(int)numFrames {
    _ot1 = viewOrigin;
    _ot2 = i1;
    _ot3 = i2;
    _ot4 = end;
    
    _otDestinationFrame = numFrames + _previousFrame;
    _otAnimationDuration = numFrames;
    _otStartFrame = _previousFrame;
    _otAnimation = YES;
}

- (void)animateViewLookAtTranslationTo:(Vector)end duration:(int)numFrames {
    _la1 = lookAtPoint;
    _la2 = end;
    
    _laDestinationFrame = numFrames + _previousFrame;
    _laAnimationDuration = numFrames;
    _laStartFrame = _previousFrame;
    _laAnimation = YES;
}

- (void)calculateCameraLookAtAnimationWithFrame:(int)frame {
    if (frame == _laDestinationFrame) {
        lookAtPoint = _la2;
        _laAnimation = NO;
    } else {
        CGFloat s = M_PI * (frame - _laStartFrame)/(CGFloat)_laAnimationDuration - M_PI_2;
        CGFloat t = 0.5 + 0.5 * sinf(s);
        lookAtPoint.x = (1-t) * _la1.x + t * _la2.x;
        lookAtPoint.y = (1-t) * _la1.y + t * _la2.y;
        lookAtPoint.z = (1-t) * _la1.z + t * _la2.z;
    }

}

- (void)animateUpOrientationTo:(Vector)end duration:(int)numFrames {
    _up1 = upOrientation;
    _up2 = end;
    
    _upDestinationFrame = numFrames + _previousFrame;
    _upAnimationDuration = numFrames;
    _upStartFrame = _previousFrame;
    _upAnimation = YES;

}

- (void)calculateUpOrientationWithFrame:(int)frame {
    if (frame == _upDestinationFrame) {
        upOrientation = _up2;
        _upAnimation = NO;
    } else {
        CGFloat s = M_PI * (frame - _upStartFrame)/(CGFloat)_upAnimationDuration - M_PI_2;
        CGFloat t = 0.5 + 0.5 * sinf(s);
        upOrientation.x = (1-t) * _up1.x + t * _up2.x;
        upOrientation.y = (1-t) * _up1.y + t * _up2.y;
        upOrientation.z = (1-t) * _up1.z + t * _up2.z;
    }

}

- (void)animateLensLengthTo:(float)end duration:(int)numFrames {
    _ll1 = lensLength;
    _ll2 = end;
    
    _llDestinationFrame = numFrames + _previousFrame;
    _llAnimationDuration = numFrames;
    _llStartFrame = _previousFrame;
    _llAnimation = YES;

}

- (void)calculateLensLengthAnimationWithFrame:(int)frame {
    if (frame == _llDestinationFrame) {
        lensLength = _ll2;
        _llAnimation = NO;
    } else {
        CGFloat s = M_PI * (frame - _llStartFrame)/(CGFloat)_llAnimationDuration - M_PI_2;
        CGFloat t = 0.5 + 0.5 * sinf(s);
        lensLength =  (1-t) * _ll1 + t * _ll2;
    }

}

- (void)animateFollowModelObject:(modelObject *)model parent:(modelObject *)parent world:(modelObject *)world distanceFromCentreOfMass:(float)distance {
    _foAnimation = YES;
    _foObject = model;
    _foDistance = distance;
    _foWorld = world;
    _foParent = parent;
}

- (void)calculateFollowObjectAnimationWithFrame:(int)frame {
    
//    Vector currentModelPosition = [_foObject centerOfMass];
    Vector objectCoord = [_foObject centerOfMass];
//    printf("Model COM: %f %f %f\n", objectCoord.x, objectCoord.y, objectCoord.z);
    Vector currentModelPosition;
    if (_foObject == _foParent) {
        currentModelPosition = objectCoord;
    } else {
        currentModelPosition = [_foWorld transformCoordinate:objectCoord inSystemOfChild:_foParent];
    }
//    printf("Current model position: %f %f %f\n", currentModelPosition.x, currentModelPosition.y, currentModelPosition.z);
    
    Vector originDirection = unit_vector(vector_subtract(lookAtPoint, currentModelPosition));
//    printf("Current origindir: %f %f %f\n", originDirection.x, originDirection.y, originDirection.z);
    viewOrigin = vector_add(currentModelPosition, vector_scale(originDirection, _foDistance));
//    printf("Current origin: %f %f %f\n", viewOrigin.x, viewOrigin.y, viewOrigin.z);
}

- (void)animateApertureTo:(float)end duration:(int)numFrames {
    _a1 = aperture;
    _a2 = end;
    
    _aDestinationFrame = numFrames + _previousFrame;
    _aAnimationDuration = numFrames;
    _aStartFrame = _previousFrame;
    _aAnimation = YES;
}

- (void)calculateApertureWithFrame:(int)frame {
    if (frame == _aDestinationFrame) {
        aperture = _a2;
        _aAnimation = NO;
    } else {
        CGFloat s = M_PI * (frame - _aStartFrame)/(CGFloat)_aAnimationDuration - M_PI_2;
        CGFloat t = 0.5 + 0.5 * sinf(s);
        aperture =  (1-t) * _a1 + t * _a2;
    }

}

- (void)animateFocalLenghTo:(float)end duration:(int)numFrames {
    _fl1 = focalLength;
    _fl2 = end;
    
    _flDestinationFrame = numFrames + _previousFrame;
    _flAnimationDuration = numFrames;
    _flStartFrame = _previousFrame;
    _flAnimation = YES;

}

- (void)calculateFocalLengthWithFrame:(int)frame {
    if (frame == _flDestinationFrame) {
        focalLength = _fl2;
        _flAnimation = NO;
    } else {
        CGFloat s = M_PI * (frame - _flStartFrame)/(CGFloat)_flAnimationDuration - M_PI_2;
        CGFloat t = 0.5 + 0.5 * sinf(s);
        focalLength =  (1-t) * _fl1 + t * _fl2;
    }

}

- (void)animateClipPlaneTo:(float)end duration:(int)numFrames {
    _cp1 = clipPlaneDistanceFromCamera;
    _cp2 = end;
    
    _cpDestinationFrame = numFrames + _previousFrame;
    _cpAnimationDuration = numFrames;
    _cpStartFrame = _previousFrame;
    _cpAnimation = YES;
}

- (void)calculateClipPlaneWithFrame:(int)frame {
    if (frame == _cpDestinationFrame) {
        self.clipPlaneDistanceFromCamera = _cp2;
        _cpAnimation = NO;
    } else {
        CGFloat s = M_PI * (frame - _cpStartFrame)/(CGFloat)_cpAnimationDuration - M_PI_2;
        CGFloat t = 0.5 + 0.5 * sinf(s);
        self.clipPlaneDistanceFromCamera =  (1-t) * _cp1 + t * _cp2;
    }
}

- (void)generateRays {

    CGFloat w = windowSize.width;
    CGFloat h = windowSize.height;
    aspectRatio = w / h;
    
    RayDef ray;
    
    ray.start.x = viewOrigin.x;
    ray.start.y = viewOrigin.y;
    //    ray.start.z = -40;
    ray.start.z = viewOrigin.z;
    ray.start.w = 1;
    
    clookAtPoint.x = lookAtPoint.x;
    clookAtPoint.y = lookAtPoint.y;
    clookAtPoint.z = lookAtPoint.z;
    clookAtPoint.w = lookAtPoint.w;
    
    cUpOrientation.x = upOrientation.x;
    cUpOrientation.y = upOrientation.y;
    cUpOrientation.z = upOrientation.z;
    cUpOrientation.w = upOrientation.w;
    
    viewOriginRayStart.x = ray.start.x;
    viewOriginRayStart.y = ray.start.y;
    viewOriginRayStart.z = ray.start.z;
    viewOriginRayStart.w = ray.start.w;
    
    viewRaysChanged = YES;
}

- (void)setWindowSize:(CGSize)size withRayCalculations:(bool)recalculate {
    windowSize = size;
    if (recalculate) {
        [self generateRays];
    }
}

- (void)setLookAtPoint:(Vector)destination withRayCalculations:(bool)recalculate {
    lookAtPoint = destination;
    if (recalculate) {
        [self generateRays];
    }
}

- (void)setCameraOrigin:(Vector)origin withRayCalculations:(bool)recalculate {
    viewOrigin = origin;
    if (recalculate) {
        [self generateRays];
    }
}

- (void)setUpOrientation:(Vector)up withRayCalculations:(bool)recalculate {
    upOrientation = up;
    if (recalculate) {
        [self generateRays];
    }
}

- (void)setViewWidth:(float)width withRayCalculations:(bool)recalculate {
    viewWidth = width;
    if (recalculate) {
        [self generateRays];
    }
}

- (void)setLensLength:(float)length withRayCalculations:(bool)recalculate {
    lensLength = length;
    if (recalculate) {
        [self generateRays];
    }
}


@end
