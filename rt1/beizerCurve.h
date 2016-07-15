//
//  beizerCurve.h
//  rt1
//
//  Created by Stock Lab on 14/05/2014.
//  Copyright (c) 2014 a. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "typedefs.h"

typedef struct _spacingPoint {
    Vector point;
    Vector normal;
} spacingPoint;

typedef struct _pointWithDerivative {
    Vector point;
    Vector derivative;
} pointWithDerivative;

@interface beizerCurve : NSObject {
    
}


- (void)addCurveWithStartPoint:(Vector)s i1:(Vector)i1 i2:(Vector)i2 end:(Vector)end;
- (void)addCurveWithI1:(Vector)i1 i2:(Vector)i2 end:(Vector)end;
- (void)addCurveWithSymmetricalJoinToBeginningWithStartPoint:(Vector)s i1:(Vector)i1;
- (void)addCurveWithSymmetricalJoinWithI2:(Vector)i2 end:(Vector)end;
- (void)addCurveWithStartPoint:(Vector)s momentumVector:(Vector)mv i2:(Vector)i2 end:(Vector)end;
- (void)addCurveWithSymmetricalJoinToBeginningWithStartPoint:(Vector)s momentumVector:(Vector)mv;
- (Vector)getValueAtT:(float)t;
- (Vector)getDerivativeAtT:(float)t;
- (Vector)getNormalAtT:(float)t withCrossVector:(Vector)c;
- (void)generatePointsAndNormalsWithSpacing:(float)spacing offset:(float)offset crossVector:(Vector)cv intoArray:(spacingPoint **)data withCalculatedPoints:(int *)numCalculatedPoints;
- (void)generatePointsAndDerivativesWithSpacing:(float)spacing offset:(float)offset intoArray:(pointWithDerivative **)data withCalculatedPoints:(int *)numCalculatedPoints;
- (int)curveSegments;
- (float)lengthWithResolution:(float)res;
- (NSData *)getDataForSegment:(int)segment;
- (beizerCurve *)curveByInterpolatingWithCurve:(beizerCurve *)destination fraction:(float)f;
- (beizerCurve *)curveBySplittingAtPoint:(float)t startCurve:(bool)start;
- (id)initWithSVGPath:(NSString *)d;
- (void)scaleWithScaleCurve:(beizerCurve *)scaleCurve scaleLengthAngstroms:(float)scaleLength;
- (beizerCurve *)curveBySubtractingNormalWithScale:(float)normalDist segmentations:(int)segments crossVector:(Vector)cv;
- (float)tValueClosestToPoint:(Vector)p withResolution:(float)res;
- (bool)xySurroundsPoint:(Vector)p withResolution:(float)res;
- (void)getMinCornerVector:(Vector *)cMin andMaxCornerVector:(Vector *)cMax withResolution:(float)res;
- (Vector)dimensionsWithResolution:(float)res;
- (float)tValueForFirstIntersectionWithLineSegmentDefinedByPoint:(Vector)point1 andPoint:(Vector)point2 withResolution:(float)res;
- (float)tValueForClosestIntersectionToPoint:(Vector)point1 withLineSegmentFormedToPoint:(Vector)point2 withResolution:(float)res;
- (int)durationForXIntegralResult:(float)desiredFinalValue;

@end
