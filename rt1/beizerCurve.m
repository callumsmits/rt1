//
//  beizerCurve.m
//  rt1
//
//  Created by Stock Lab on 14/05/2014.
//  Copyright (c) 2014 a. All rights reserved.
//

#import "beizerCurve.h"
#import "vector_ops.h"

@interface beizerCurve () {
    int numCurves;
    NSMutableArray *curveControlPoints;
}

@property (nonatomic, strong) NSMutableArray *curveControlPoints;

- (Vector)getValueAtLocalT:(float)t forLocalCurve:(Vector *)points;
- (Vector)getDerivativeAtLocalT:(float)t forLocalCurve:(Vector *)points;
- (Vector)getNormalAtLocalT:(float)t withCrossVector:(Vector)c forLocalCurve:(Vector *)points;

@end

@implementation beizerCurve

@synthesize curveControlPoints;

- (id)init {
    if (self = [super init]) {
        numCurves = 0;
        self.curveControlPoints = [NSMutableArray arrayWithCapacity:1];
    }
    
    return self;
}

- (id)initWithSVGPath:(NSString *)d {

    if (self = [super init]) {
        numCurves = 0;
        self.curveControlPoints = [NSMutableArray arrayWithCapacity:1];
    
        NSArray *commandList = [d componentsSeparatedByString:@" "];
        
#define kNo_Command 0
#define kMoveToAbsolute 1
#define kMoveToRelative 2
#define kCurveRelative 3
#define kCurveAbsolute 4
#define kCompleteCurve 5
        
        NSString *moveToAbsoluteCommand = @"M";
        NSString *moveToRelativeCommand = @"m";
        NSString *curveRelativeCommand = @"c";
        NSString *curveAbsoluteCommand = @"C";
        NSString *completeCurveCommand = @"z";
        
        NSDictionary *commandDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                           [NSNumber numberWithInt:kMoveToAbsolute], moveToAbsoluteCommand,
                                           [NSNumber numberWithInt:kMoveToRelative], moveToRelativeCommand,
                                           [NSNumber numberWithInt:kCurveRelative], curveRelativeCommand,
                                           [NSNumber numberWithInt:kCurveAbsolute], curveAbsoluteCommand,
                                           [NSNumber numberWithInt:kCompleteCurve], completeCurveCommand,
                                           nil];
        
        int command = 0;
        NSEnumerator *commandEnum = [commandList objectEnumerator];
        NSString *currentCommand;
        Vector p; p.x = 0; p.y = 0; p.z = 0; p.w = 1.0;
        
        while (currentCommand = [commandEnum nextObject]) {
            NSNumber *lookupResult = [commandDictionary objectForKey:currentCommand];
            if (lookupResult) {
                command = [lookupResult intValue];
                switch (command) {
                    case kMoveToAbsolute:
                    {
                        NSString *coordString = [commandEnum nextObject];
                        NSArray *coordArray = [coordString componentsSeparatedByString:@","];
                        p.x = [[coordArray objectAtIndex:0] floatValue];
                        p.y = [[coordArray objectAtIndex:1] floatValue];
                        break;
                    }
                    case kMoveToRelative:
                    {
                        NSString *coordString = [commandEnum nextObject];
                        NSArray *coordArray = [coordString componentsSeparatedByString:@","];
                        p.x += [[coordArray objectAtIndex:0] floatValue];
                        p.y += [[coordArray objectAtIndex:1] floatValue];
                        break;
                    }
                    case kCurveRelative:
                    {
                        Vector i1, i2, end;
                        i1.z = i2.z = end.z = 0;
                        i1.w = i2.w = end.w = 1.0;
                        
                        NSString *coordString = [commandEnum nextObject];
                        NSArray *coordArray = [coordString componentsSeparatedByString:@","];
                        i1.x = p.x + [[coordArray objectAtIndex:0] floatValue];
                        i1.y = p.y + [[coordArray objectAtIndex:1] floatValue];
                        
                        coordString = [commandEnum nextObject];
                        coordArray = [coordString componentsSeparatedByString:@","];
                        i2.x = p.x + [[coordArray objectAtIndex:0] floatValue];
                        i2.y = p.y + [[coordArray objectAtIndex:1] floatValue];
                        
                        coordString = [commandEnum nextObject];
                        coordArray = [coordString componentsSeparatedByString:@","];
                        end.x = p.x + [[coordArray objectAtIndex:0] floatValue];
                        end.y = p.y + [[coordArray objectAtIndex:1] floatValue];
                        
                        if ([self curveSegments] > 0) {
                            [self addCurveWithI1:i1 i2:i2 end:end];
                        } else {
                            [self addCurveWithStartPoint:p i1:i1 i2:i2 end:end];
                        }
                        p = end;
                        break;
                    }
                    case kCurveAbsolute:
                    {
                        Vector i1, i2, end;
                        i1.z = i2.z = end.z = 0;
                        i1.w = i2.w = end.w = 1.0;
                        
                        NSString *coordString = [commandEnum nextObject];
                        NSArray *coordArray = [coordString componentsSeparatedByString:@","];
                        i1.x = [[coordArray objectAtIndex:0] floatValue];
                        i1.y = [[coordArray objectAtIndex:1] floatValue];
                        
                        coordString = [commandEnum nextObject];
                        coordArray = [coordString componentsSeparatedByString:@","];
                        i2.x = [[coordArray objectAtIndex:0] floatValue];
                        i2.y = [[coordArray objectAtIndex:1] floatValue];
                        
                        coordString = [commandEnum nextObject];
                        coordArray = [coordString componentsSeparatedByString:@","];
                        end.x = [[coordArray objectAtIndex:0] floatValue];
                        end.y = [[coordArray objectAtIndex:1] floatValue];
                        
                        if ([self curveSegments] > 0) {
                            [self addCurveWithI1:i1 i2:i2 end:end];
                        } else {
                            [self addCurveWithStartPoint:p i1:i1 i2:i2 end:end];
                        }
                        p = end;
                        break;
                    }
                    case kCompleteCurve:
                    {
                        Vector i1, i2, end;
                        i1.z = i2.z = end.z = 0;
                        i1.w = i2.w = end.w = 1.0;
                        
                        end = [self getValueAtT:0];
                        i1 = vector_lerp(p, end, 0.33);
                        i2 = vector_lerp(p, end, 0.66);
                        
                        if ((p.x != end.x) && (p.y != end.y) && (p.z != end.z)) {
                            [self addCurveWithI1:i1 i2:i2 end:end];
                        }
                        p = end;
                        break;
                    }
                        
                    default:
                        break;
                }
            } else {
                switch (command) {
                    case kMoveToAbsolute:
                    {
                        Vector i1, i2, end;
                        i1.z = i2.z = end.z = 0;
                        i1.w = i2.w = end.w = 1.0;
                        
//                        NSString *coordString = [commandEnum nextObject];
                        NSString *coordString = currentCommand;
                        NSArray *coordArray = [coordString componentsSeparatedByString:@","];
                        end.x = [[coordArray objectAtIndex:0] floatValue];
                        end.y = [[coordArray objectAtIndex:1] floatValue];
                        
                        i1 = vector_lerp(p, end, 0.66);
                        i2 = vector_lerp(p, end, 0.33);
                        //Standard says no line here, just update the point
                        //But inkscape seems to draw a line, so draw a line...
                        if ([self curveSegments] > 0) {
                            [self addCurveWithI1:i1 i2:i2 end:end];
                        } else {
                            [self addCurveWithStartPoint:p i1:i1 i2:i2 end:end];
                        }
                        p = end;
                        break;
                    }
                    case kMoveToRelative:
                    {
                        Vector i1, i2, end;
                        i1.z = i2.z = end.z = 0;
                        i1.w = i2.w = end.w = 1.0;
                        
//                        NSString *coordString = [commandEnum nextObject];
                        NSString *coordString = currentCommand;
                        NSArray *coordArray = [coordString componentsSeparatedByString:@","];
                        end.x = p.x + [[coordArray objectAtIndex:0] floatValue];
                        end.y = p.y + [[coordArray objectAtIndex:1] floatValue];
                        
                        i1 = vector_lerp(p, end, 0.66);
                        i2 = vector_lerp(p, end, 0.33);
                        //Standard says no line here, just update the point
                        //But inkscape seems to draw a line, so draw a line...
                        if ([self curveSegments] > 0) {
                            [self addCurveWithI1:i1 i2:i2 end:end];
                        } else {
                            [self addCurveWithStartPoint:p i1:i1 i2:i2 end:end];
                        }
                        p = end;
                        break;
                    }
                    case kCurveRelative:
                    {
                        Vector i1, i2, end;
                        i1.z = i2.z = end.z = 0;
                        i1.w = i2.w = end.w = 1.0;
                        
//                        NSString *coordString = [commandEnum nextObject];
                        NSString *coordString = currentCommand;
                        NSArray *coordArray = [coordString componentsSeparatedByString:@","];
                        i1.x = p.x + [[coordArray objectAtIndex:0] floatValue];
                        i1.y = p.y + [[coordArray objectAtIndex:1] floatValue];
                        
                        coordString = [commandEnum nextObject];
                        coordArray = [coordString componentsSeparatedByString:@","];
                        i2.x = p.x + [[coordArray objectAtIndex:0] floatValue];
                        i2.y = p.y + [[coordArray objectAtIndex:1] floatValue];
                        
                        coordString = [commandEnum nextObject];
                        coordArray = [coordString componentsSeparatedByString:@","];
                        end.x = p.x + [[coordArray objectAtIndex:0] floatValue];
                        end.y = p.y + [[coordArray objectAtIndex:1] floatValue];
                        
                        if ([self curveSegments] > 0) {
                            [self addCurveWithI1:i1 i2:i2 end:end];
                        } else {
                            [self addCurveWithStartPoint:p i1:i1 i2:i2 end:end];
                        }
                        p = end;
                        break;
                    }
                    case kCurveAbsolute:
                    {
                        Vector i1, i2, end;
                        i1.z = i2.z = end.z = 0;
                        i1.w = i2.w = end.w = 1.0;
                        
                        //                        NSString *coordString = [commandEnum nextObject];
                        NSString *coordString = currentCommand;
                        NSArray *coordArray = [coordString componentsSeparatedByString:@","];
                        i1.x = [[coordArray objectAtIndex:0] floatValue];
                        i1.y = [[coordArray objectAtIndex:1] floatValue];
                        
                        coordString = [commandEnum nextObject];
                        coordArray = [coordString componentsSeparatedByString:@","];
                        i2.x = [[coordArray objectAtIndex:0] floatValue];
                        i2.y = [[coordArray objectAtIndex:1] floatValue];
                        
                        coordString = [commandEnum nextObject];
                        coordArray = [coordString componentsSeparatedByString:@","];
                        end.x = [[coordArray objectAtIndex:0] floatValue];
                        end.y = [[coordArray objectAtIndex:1] floatValue];
                        
                        if ([self curveSegments] > 0) {
                            [self addCurveWithI1:i1 i2:i2 end:end];
                        } else {
                            [self addCurveWithStartPoint:p i1:i1 i2:i2 end:end];
                        }
                        p = end;
                        break;
                    }

                        
                    default:
                        break;
                }
            }
        }
        
    }
    
    return self;
}

- (void)scaleWithScaleCurve:(beizerCurve *)scaleCurve scaleLengthAngstroms:(float)scaleLength {

    float scaleCurveLength = [scaleCurve lengthWithResolution:1.0];
    float scaleFactor = scaleLength / scaleCurveLength;
    
    for (int i = 0; i < numCurves; i++) {

        Vector points[4];
        NSData *pointsData = [curveControlPoints objectAtIndex:i];
        [pointsData getBytes:points length:sizeof(Vector)*4];
        
        for (int j = 0; j < 4; j++) {
            points[j] = vector_scale(points[j], scaleFactor);
        }
        
        NSData *scaledPointsData = [NSData dataWithBytes:points length:sizeof(Vector)*4];
        [curveControlPoints replaceObjectAtIndex:i withObject:scaledPointsData];
    }
}
- (void)points:(Vector[4])inPoints splitAtT:(float)t intoFirstHalf:(Vector[4])firstPoints andSecondHalf:(Vector[4])secondPoints {
    Vector s4, s5, s6, s7, s8, s9;
    s4 = vector_lerp(inPoints[1], inPoints[0], t);
    s5 = vector_lerp(inPoints[2], inPoints[1], t);
    s6 = vector_lerp(inPoints[3], inPoints[2], t);
    s7 = vector_lerp(s5, s4, t);
    s8 = vector_lerp(s6, s5, t);
    s9 = vector_lerp(s8, s7, t);

    firstPoints[0] = inPoints[0];
    firstPoints[1] = s4;
    firstPoints[2] = s7;
    firstPoints[3] = s9;
    secondPoints[0] = s9;
    secondPoints[1] = s8;
    secondPoints[2] = s6;
    secondPoints[3] = inPoints[3];
}

- (beizerCurve *)curveBySubtractingNormalWithScale:(float)normalDist segmentations:(int)segments crossVector:(Vector)cv {
    beizerCurve *new = [[beizerCurve alloc] init];
    for (int i = 0; i < numCurves; i++) {

        Vector points[4], halfA[4],halfB[4], q[4][4], newPoints[4];
        NSData *pointsData = [curveControlPoints objectAtIndex:i];
        [pointsData getBytes:points length:sizeof(Vector)*4];

        [self points:points splitAtT:0.5 intoFirstHalf:halfA andSecondHalf:halfB];
        [self points:halfA splitAtT:0.5 intoFirstHalf:q[0] andSecondHalf:q[1]];
        [self points:halfB splitAtT:0.5 intoFirstHalf:q[2] andSecondHalf:q[3]];
        
        for (int j = 0; j < 4; j++) {
//            float localTStart = (float)j / (float)4;
//            float localTEnd = (float)(j + 1) / (float)4;
            Vector startNormal = [self getNormalAtLocalT:0 withCrossVector:cv forLocalCurve:q[j]];
            Vector endNormal = [self getNormalAtLocalT:1.0 withCrossVector:cv forLocalCurve:q[j]];
            
            newPoints[0] = vector_subtract(q[j][0], vector_scale(startNormal, normalDist));
            newPoints[1] = vector_subtract(q[j][1], vector_scale(startNormal, normalDist));
            newPoints[2] = vector_subtract(q[j][2], vector_scale(endNormal, normalDist));
            newPoints[3] = vector_subtract(q[j][3], vector_scale(endNormal, normalDist));
            
            [new addCurveWithStartPoint:newPoints[0] i1:newPoints[1] i2:newPoints[2] end:newPoints[3]];
            
        }
        
    }
    
    return new;
}

- (beizerCurve *)curveByInterpolatingWithCurve:(beizerCurve *)destination fraction:(float)f {
    if (numCurves != [destination curveSegments]) {
        NSLog(@"Invalid - trying to interpolate to curve with different number of component curves");
        return nil;
    }
    beizerCurve *new = [[beizerCurve alloc] init];
    for (int i = 0; i < numCurves; i++) {
        Vector sPoints[4];
        Vector ePoints[4];
        NSData *pointsData = [curveControlPoints objectAtIndex:i];
        [pointsData getBytes:sPoints length:sizeof(Vector)*4];
        NSData *ePointsData = [destination getDataForSegment:i];
        [ePointsData getBytes:ePoints length:sizeof(Vector)*4];
        Vector iPoints[4];
        float *fPoints = (float *)iPoints;
        float *fEPoints = (float *)ePoints;
        float *fSPoints = (float *)sPoints;
        for (int j = 0; j < (sizeof(Vector) / sizeof(float) * 4); j++) {
            fPoints[j] = (1-f) * fSPoints[j] + f * fEPoints[j];
        }
        [new addCurveWithStartPoint:iPoints[0] i1:iPoints[1] i2:iPoints[2] end:iPoints[3]];
    }
    return new;
}

- (NSData *)getDataForSegment:(int)segment {
    return [curveControlPoints objectAtIndex:segment];
}

- (int)curveSegments {
    return numCurves;
}

- (void)addCurveWithStartPoint:(Vector)s i1:(Vector)i1 i2:(Vector)i2 end:(Vector)end {
    
    numCurves++;
    Vector points[4];
    points[0] = s; points[1] = i1; points[2] = i2; points[3] = end;
    NSData *pointsData = [NSData dataWithBytes:points length:sizeof(Vector)*4];
    [curveControlPoints addObject:pointsData];
    
}

- (void)addCurveWithStartPoint:(Vector)s momentumVector:(Vector)mv i2:(Vector)i2 end:(Vector)end {

    numCurves++;
    Vector points[4];
    points[0] = s; points[1] = vector_add(s, vector_scale(mv, 5.0)); points[2] = i2; points[3] = end;
    NSData *pointsData = [NSData dataWithBytes:points length:sizeof(Vector)*4];
    [curveControlPoints addObject:pointsData];

}

- (void)addCurveWithI1:(Vector)i1 i2:(Vector)i2 end:(Vector)end {
    
    if (numCurves == 0) {
        NSLog(@"Invalid to add three points to uninitialised curve");
        return;
    }
    
    Vector points[4];
    NSData *pointsData = [curveControlPoints objectAtIndex:numCurves-1];
    [pointsData getBytes:points length:sizeof(Vector)*4];
    points[0] = points[3];
    
    numCurves++;
    points[1] = i1; points[2] = i2; points[3] = end;
    pointsData = [NSData dataWithBytes:points length:sizeof(Vector)*4];
    [curveControlPoints addObject:pointsData];

}

- (void)addCurveWithSymmetricalJoinWithI2:(Vector)i2 end:(Vector)end {
    if (numCurves == 0) {
        NSLog(@"Invalid to add three points to uninitialised curve");
        return;
    }
    
    Vector points[4];
    NSData *pointsData = [curveControlPoints objectAtIndex:numCurves-1];
    [pointsData getBytes:points length:sizeof(Vector)*4];
    
    Vector newPoints[4];
    newPoints[0] = points[3];
    newPoints[1] = vector_subtract(points[3], vector_subtract(points[2], points[3]));
    newPoints[2] = i2;
    newPoints[3] = end;
    numCurves++;
    pointsData = [NSData dataWithBytes:newPoints length:sizeof(Vector)*4];
    [curveControlPoints addObject:pointsData];
}

- (void)addCurveWithSymmetricalJoinToBeginningWithStartPoint:(Vector)s i1:(Vector)i1 {
    if (numCurves == 0) {
        NSLog(@"Invalid to add three points to uninitialised curve");
        return;
    }
    
    Vector points[4];
    NSData *pointsData = [curveControlPoints objectAtIndex:0];
    [pointsData getBytes:points length:sizeof(Vector)*4];
    
    Vector newPoints[4];
    newPoints[0] = s;
    newPoints[1] = i1;
    newPoints[2] = vector_subtract(points[0], vector_subtract(points[1], points[0]));
    newPoints[3] = points[0];
    numCurves++;
    pointsData = [NSData dataWithBytes:newPoints length:sizeof(Vector)*4];
    [curveControlPoints insertObject:pointsData atIndex:0];
}

- (void)addCurveWithSymmetricalJoinToBeginningWithStartPoint:(Vector)s momentumVector:(Vector)mv {
    if (numCurves == 0) {
        NSLog(@"Invalid to add three points to uninitialised curve");
        return;
    }

    Vector points[4];
    NSData *pointsData = [curveControlPoints objectAtIndex:0];
    [pointsData getBytes:points length:sizeof(Vector)*4];
    
    numCurves++;
    Vector newPoints[4];
    newPoints[0] = s;
    newPoints[1] = vector_add(s, vector_scale(mv, 5.0));
    newPoints[2] = vector_subtract(points[0], vector_subtract(points[1], points[0]));
    newPoints[3] = points[0];
    pointsData = [NSData dataWithBytes:newPoints length:sizeof(Vector)*4];
    [curveControlPoints insertObject:pointsData atIndex:0];

}


- (Vector)getValueAtT:(float)t {
    if ((t < 0) || (t > 1)) {
        NSLog(@"Invalid value to get bezier value");
        Vector a;
        a.x = a.y = a.z = a.w = 0;
        return a;
    }
    
    //Find which curve this t belongs to
    float tInc = 1.0 / numCurves;
    int i = numCurves;
    while (i * tInc > t) {
        i--;
    }
    if (i >= numCurves) {
        i = numCurves - 1;
    }
    if (i < 0) {
        i = 0;
    }
    
    
    float curveTMin = i * tInc;
    float curveTMax = (i + 1) * tInc;
    t = (t - curveTMin) / (curveTMax - curveTMin);
    Vector points[4];
    
    NSData *pointsData = [curveControlPoints objectAtIndex:i];
    [pointsData getBytes:points length:sizeof(Vector)*4];
    
    return [self getValueAtLocalT:t forLocalCurve:points];
}

- (Vector)getValueAtLocalT:(float)t forLocalCurve:(Vector *)points {
    Vector r;
    r.x = powf(1-t, 3) * points[0].x + 3 * powf(1-t, 2) * t * points[1].x + 3 * (1-t) * t * t * points[2].x + powf(t, 3) * points[3].x;
    r.y = powf(1-t, 3) * points[0].y + 3 * powf(1-t, 2) * t * points[1].y + 3 * (1-t) * t * t * points[2].y + powf(t, 3) * points[3].y;
    r.z = powf(1-t, 3) * points[0].z + 3 * powf(1-t, 2) * t * points[1].z + 3 * (1-t) * t * t * points[2].z + powf(t, 3) * points[3].z;
    
    return r;
}

- (Vector)getDerivativeAtT:(float)t {
    if ((t < 0) || (t > 1)) {
        NSLog(@"Invalid value to get bezier derivative value");
        Vector a;
        a.x = a.y = a.z = a.w = 0;
        return a;
    }
    
    //Find which curve this t belongs to
    float tInc = 1.0 / numCurves;
    int i = numCurves;
    while (i * tInc > t) {
        i--;
    }
    if (i >= numCurves) {
        i = numCurves - 1;
    }
    if (i < 0) {
        i = 0;
    }
    
    float curveTMin = i * tInc;
    float curveTMax = (i + 1) * tInc;
    t = (t - curveTMin) / (curveTMax - curveTMin);

    Vector points[4];
    NSData *pointsData = [curveControlPoints objectAtIndex:i];
    [pointsData getBytes:points length:sizeof(Vector)*4];
    
    return [self getDerivativeAtLocalT:t forLocalCurve:points];
}

- (Vector)getDerivativeAtLocalT:(float)t forLocalCurve:(Vector *)points {
    Vector r;
    r.x = powf(1-t, 2) * 3 * (points[1].x - points[0].x) + 6 * (1-t) * t * (points[2].x - points[1].x) + 3 * t * t * (points[3].x - points[2].x);
    r.y = powf(1-t, 2) * 3 * (points[1].y - points[0].y) + 6 * (1-t) * t * (points[2].y - points[1].y) + 3 * t * t * (points[3].y - points[2].y);
    r.z = powf(1-t, 2) * 3 * (points[1].z - points[0].z) + 6 * (1-t) * t * (points[2].z - points[1].z) + 3 * t * t * (points[3].z - points[2].z);
    
    return r;
}

- (Vector)getNormalAtT:(float)t withCrossVector:(Vector)c {
    Vector d = [self getDerivativeAtT:t];
    Vector r = unit_vector(vector_cross(unit_vector(d), unit_vector(c)));
    return r;
}

- (Vector)getNormalAtLocalT:(float)t withCrossVector:(Vector)c forLocalCurve:(Vector *)points {
    Vector d = [self getDerivativeAtLocalT:t forLocalCurve:points];
    Vector r = unit_vector(vector_cross(unit_vector(d), unit_vector(c)));
    return r;
}

- (Vector)intersectionBetweenLineSegmentsPoint1:(Vector)l1a Point2:(Vector)l1b line2Point1:(Vector)l2a line2Point2:(Vector)l2b {
    //Use vector w to indicate presence of interaction
    
    float A1 = l1b.y - l1a.y;// y2-y1
    float B1 = l1a.x - l1b.x;// x1-x2
    float C1 = A1 * l1a.x + B1 * l1a.y;// A*x1+B*y1
    
    float A2 = l2b.y - l2a.y;// y2-y1
    float B2 = l2a.x - l2b.x;// x1-x2
    float C2 = A2 * l2a.x + B2 * l2a.y;// A*x1+B*y1

    double det = A1*B2 - A2*B1;
    if (det == 0){
        Vector r; r.w = 0;
        return r;
    }
    double x = (B2*C1 - B1*C2)/det;
    double y = (A1*C2 - A2*C1)/det;
    
    //Check that the intersection is between the points
    if ((fminf(l1a.x, l1b.x) <= x) &&
        (fmaxf(l1a.x, l1b.x) >= x) &&
        (fminf(l1a.y, l1b.y) <= y) &&
        (fmaxf(l1a.y, l1b.y) >= y) &&
        (fminf(l2a.x, l2b.x) <= x) &&
        (fmaxf(l2a.x, l2b.x) >= x) &&
        (fminf(l2a.y, l2b.y) <= y) &&
        (fmaxf(l2a.y, l2b.y) >= y)) {

        Vector r; r.w = 1;
        r.x = x;
        r.y = y;
        return r;
    }
    
    Vector r; r.w = 0;
    return r;
}

- (float)tValueForClosestIntersectionToPoint:(Vector)point1 withLineSegmentFormedToPoint:(Vector)point2 withResolution:(float)res {
    
    Vector points[4];
    float spacing = res;
    bool intersectionFound = NO;
    float closestDistance = 0;
    float closestT = 0;
    
    for (int c = 0; c < numCurves; c++) {
        float l = 0;
        NSData *pointsData = [curveControlPoints objectAtIndex:c];
        [pointsData getBytes:points length:sizeof(Vector)*4];
        l = vector_size(vector_subtract(points[0], points[1])) + vector_size(vector_subtract(points[1], points[2])) + vector_size(vector_subtract(points[2], points[3]));
        
        int numPoints = 4 * l / spacing;
        Vector p;
        p = points[0];
        for (int i = 1; i < numPoints; i++) {
            CGFloat t = i * (1.0 / (float)numPoints);
            Vector j = [self getValueAtLocalT:t forLocalCurve:points];
            
            j.w = 0;
            
            Vector intersection = [self intersectionBetweenLineSegmentsPoint1:p Point2:j line2Point1:point1 line2Point2:point2];
            if (intersection.w > 0) {
                if (intersectionFound) {
                    Vector diff = vector_subtract(intersection, point1);
                    diff.w = 0;
                    float dist = vector_size(diff);
                    if (dist < closestDistance) {
                        closestT = (float)c / (float)numCurves + ((float)i / (float)numPoints) * (1.0f / (float)numCurves);
                        closestDistance = dist;
                    }
                } else {
                    intersectionFound = YES;
                    closestT = (float)c / (float)numCurves + ((float)i / (float)numPoints) * (1.0f / (float)numCurves);
                    Vector diff = vector_subtract(intersection, point1);
                    diff.w = 0;
                    closestDistance = vector_size(diff);
                }
            }
            p = j;
        }
    }
    
    if (intersectionFound) {
        return closestT;
    }
    
    //No intersection
    return -1;
}

- (float)tValueForFirstIntersectionWithLineSegmentDefinedByPoint:(Vector)point1 andPoint:(Vector)point2 withResolution:(float)res {

    Vector points[4];
    float spacing = res;
    
    for (int c = 0; c < numCurves; c++) {
        float l = 0;
        NSData *pointsData = [curveControlPoints objectAtIndex:c];
        [pointsData getBytes:points length:sizeof(Vector)*4];
        l = vector_size(vector_subtract(points[0], points[1])) + vector_size(vector_subtract(points[1], points[2])) + vector_size(vector_subtract(points[2], points[3]));
        
        int numPoints = 4 * l / spacing;
        Vector p;
        p = points[0];
        for (int i = 1; i < numPoints; i++) {
            CGFloat t = i * (1.0 / (float)numPoints);
            Vector j = [self getValueAtLocalT:t forLocalCurve:points];
            
            j.w = 0;
            
            Vector intersection = [self intersectionBetweenLineSegmentsPoint1:p Point2:j line2Point1:point1 line2Point2:point2];
            if (intersection.w > 0) {
                //Have intersection, so return current t
                float tV = (float)c / (float)numCurves + ((float)i / (float)numPoints) * (1.0f / (float)numCurves);
                return tV;
            }
            p = j;
        }
    }

    //No intersection, so return -1
    return -1;
}

- (float)tValueClosestToPoint:(Vector)p withResolution:(float)res {

    Vector points[4];
    float spacing = res;
    
    float closestDistance = MAXFLOAT;
    float closestT = 0;
    
    for (int c = 0; c < numCurves; c++) {
        float l = 0;
        NSData *pointsData = [curveControlPoints objectAtIndex:c];
        [pointsData getBytes:points length:sizeof(Vector)*4];
        l = vector_size(vector_subtract(points[0], points[1])) + vector_size(vector_subtract(points[1], points[2])) + vector_size(vector_subtract(points[2], points[3]));
        
        int numPoints = 4 * l / spacing;
        for (int i = 0; i < numPoints; i++) {
            CGFloat t = i * (1.0 / (float)numPoints);
            Vector j = [self getValueAtLocalT:t forLocalCurve:points];
            
            j.w = 1.0;
            float dist = vector_size(vector_subtract(j, p));
            if (dist < closestDistance) {
                closestDistance = dist;
                closestT = (float)c / (float)numCurves + ((float)i / (float)numPoints) * (1.0f / (float)numCurves);
            }
        }
    }
    
    return closestT;
    
}

- (bool)xySurroundsPoint:(Vector)p withResolution:(float)res {
    
    Vector points[4];
    float spacing = res;
        
    unsigned int crosses = 0;
    
    for (int c = 0; c < numCurves; c++) {
        float l = 0;
        NSData *pointsData = [curveControlPoints objectAtIndex:c];
        [pointsData getBytes:points length:sizeof(Vector)*4];
        l = vector_size(vector_subtract(points[0], points[1])) + vector_size(vector_subtract(points[1], points[2])) + vector_size(vector_subtract(points[2], points[3]));
        
        int numPoints = 4 * l / spacing;
        Vector prev;
        prev = points[0];
        for (int i = 1; i < numPoints; i++) {
            CGFloat t = i * (1.0 / (float)numPoints);
            Vector j = [self getValueAtLocalT:t forLocalCurve:points];
            
            j.w = 1.0;
            
            float floatError = 0.000001;
            if ((j.x > p.x) && (prev.x > p.x) &&
                (((j.y + floatError >= p.y) && (prev.y - floatError < p.y)) || ((j.y - floatError <= p.y) && (prev.y + floatError > p.y)))) {
                crosses++;
            }
            prev = j;
        }
    }

    //Point is inside the curve if crosses is odd
    bool inside = crosses & 1;
    return inside;
}

- (void)getMinCornerVector:(Vector *)cMin andMaxCornerVector:(Vector *)cMax withResolution:(float)res {
    Vector points[4];
    float spacing = res;
    Vector min, max;
    
    for (int c = 0; c < numCurves; c++) {
        float l = 0;
        NSData *pointsData = [curveControlPoints objectAtIndex:c];
        [pointsData getBytes:points length:sizeof(Vector)*4];
        l = vector_size(vector_subtract(points[0], points[1])) + vector_size(vector_subtract(points[1], points[2])) + vector_size(vector_subtract(points[2], points[3]));
        
        int numPoints = 4 * l / spacing;
        if (c == 0) {
            min = max = points[0];
        }
        for (int i = 0; i < numPoints; i++) {
            CGFloat t = i * (1.0 / (float)numPoints);
            Vector j = [self getValueAtLocalT:t forLocalCurve:points];
            
            j.w = 1;
            
            if (j.x < min.x) {
                min.x = j.x;
            }
            if (j.x > max.x) {
                max.x = j.x;
            }
            if (j.y < min.y) {
                min.y = j.y;
            }
            if (j.y > max.y) {
                max.y = j.y;
            }
        }
    }

    *cMin = min;
    *cMax = max;
}

- (Vector)dimensionsWithResolution:(float)res {

    Vector min, max;

    [self getMinCornerVector:&min andMaxCornerVector:&max withResolution:res];
    
    Vector d;
    d = vector_subtract(max, min);
    return d;
}

- (float)lengthWithResolution:(float)res {

    Vector points[4];
    float spacing = res;
    
    float cumulativeDistance = 0;
    for (int c = 0; c < numCurves; c++) {
        float l = 0;
        NSData *pointsData = [curveControlPoints objectAtIndex:c];
        [pointsData getBytes:points length:sizeof(Vector)*4];
        l = vector_size(vector_subtract(points[0], points[1])) + vector_size(vector_subtract(points[1], points[2])) + vector_size(vector_subtract(points[2], points[3]));
        
        int numPoints = 4 * l / spacing;
        Vector p;
        p = points[0];
        for (int i = 0; i < numPoints; i++) {
            CGFloat t = i * (1.0 / (float)numPoints);
            Vector j = [self getValueAtLocalT:t forLocalCurve:points];
            
            j.w = 0;
            cumulativeDistance = cumulativeDistance + vector_size(vector_subtract(j, p));
            p = j;
        }
    }

    return cumulativeDistance;
}

- (int)durationForXIntegralResult:(float)desiredFinalValue {
    
    Vector points[4];

    //Generate initial estimate
    float cumulative = 0;
    for (int c = 0; c < numCurves; c++) {
        
        NSData *pointsData = [curveControlPoints objectAtIndex:c];
        [pointsData getBytes:points length:sizeof(Vector)*4];
        
        cumulative += points[0].x;
        cumulative += points[1].x;
        cumulative += points[2].x;
        cumulative += points[3].x;
    }
    //scale by the number of curves
    cumulative = cumulative / (float)numCurves;

    int estimate = desiredFinalValue / cumulative;
    
    //calculate based on the estimate
    cumulative = 0;
    for (int i = 0; i < estimate; i++) {
        float t = (float)i / (float)estimate;
        cumulative += [self getValueAtT:t].x;
    }
    
    while (cumulative > desiredFinalValue) {
        estimate--;
        cumulative = 0;
        for (int i = 0; i < estimate; i++) {
            float t = (float)i / (float)estimate;
            cumulative += [self getValueAtT:t].x;
        }
    }
    
    int finalEstimate = estimate;
    
    while (cumulative < desiredFinalValue) {
        finalEstimate = estimate;
        estimate++;
        cumulative = 0;
        for (int i = 0; i < estimate; i++) {
            float t = (float)i / (float)estimate;
            cumulative += [self getValueAtT:t].x;
        }
    }
    
    return finalEstimate;
}

- (void)generatePointsAndNormalsWithSpacing:(float)spacing offset:(float)offset crossVector:(Vector)cv intoArray:(spacingPoint **)data withCalculatedPoints:(int *)numCalculatedPoints {
    
    //Generate rough estimate of arc length
    Vector points[4];
    spacingPoint **dataPoints = (spacingPoint **)malloc(sizeof(spacingPoint *) * [curveControlPoints count]);
    int *numDataPoints = (int *)malloc(sizeof(int) * [curveControlPoints count]);
    
    float cumulativeDistance = offset;
    for (int c = 0; c < numCurves; c++) {
        float l = 0;
        NSData *pointsData = [curveControlPoints objectAtIndex:c];
        [pointsData getBytes:points length:sizeof(Vector)*4];
        l = vector_size(vector_subtract(points[0], points[1])) + vector_size(vector_subtract(points[1], points[2])) + vector_size(vector_subtract(points[2], points[3]));

        int numPoints = 4 * l / spacing;
        dataPoints[c] = (spacingPoint *)malloc(sizeof(spacingPoint) * numPoints);
        spacingPoint *localArray = dataPoints[c];
        Vector p;
        p = points[0];
        int calculatedPoints = 0;
        for (int i = 0; i < numPoints; i++) {
            CGFloat t = i * (1.0 / (float)numPoints);
            Vector j = [self getValueAtLocalT:t forLocalCurve:points];
            
            j.w = 0;
            cumulativeDistance = cumulativeDistance + vector_size(vector_subtract(j, p));
            p = j;
            if (cumulativeDistance > spacing) {
                
                Vector n = [self getNormalAtLocalT:t withCrossVector:cv forLocalCurve:points];
                spacingPoint new;
                new.point = j;
                new.normal = n;
                localArray[calculatedPoints] = new;
                calculatedPoints++;
                
                cumulativeDistance = 0;
            }
        }
        numDataPoints[c] = calculatedPoints;
    }
    
    //Now make one array and clean up...
    int totalPoints = 0;
    for (int c = 0; c < [curveControlPoints count]; c++) {
        totalPoints = totalPoints + numDataPoints[c];
    }
    
    spacingPoint *returnData = (spacingPoint *)malloc(sizeof(spacingPoint) * totalPoints);
    int pointNum = 0;
    for (int c = 0; c < [curveControlPoints count]; c++) {
        spacingPoint *localArray = dataPoints[c];
        int numPoints = numDataPoints[c];
        for (int i = 0; i < numPoints; i++) {
            returnData[pointNum] = localArray[i];
            pointNum++;
        }
        free(localArray);
    }
    free(dataPoints);
    free(numDataPoints);
    
    *data = returnData;
    *numCalculatedPoints = totalPoints;
}

- (void)generatePointsAndDerivativesWithSpacing:(float)spacing offset:(float)offset intoArray:(pointWithDerivative **)data withCalculatedPoints:(int *)numCalculatedPoints {
    //Generate rough estimate of arc length
    Vector points[4];
    pointWithDerivative **dataPoints = (pointWithDerivative **)malloc(sizeof(pointWithDerivative *) * [curveControlPoints count]);
    int *numDataPoints = (int *)malloc(sizeof(int) * [curveControlPoints count]);
    
    float cumulativeDistance = offset;
    for (int c = 0; c < numCurves; c++) {
        float l = 0;
        NSData *pointsData = [curveControlPoints objectAtIndex:c];
        [pointsData getBytes:points length:sizeof(Vector)*4];
        l = vector_size(vector_subtract(points[0], points[1])) + vector_size(vector_subtract(points[1], points[2])) + vector_size(vector_subtract(points[2], points[3]));
        
        int numPoints = 4 * l / spacing;
        dataPoints[c] = (pointWithDerivative *)malloc(sizeof(pointWithDerivative) * numPoints);
        pointWithDerivative *localArray = dataPoints[c];
        Vector p;
        p = points[0];
        int calculatedPoints = 0;
        for (int i = 0; i < numPoints; i++) {
            CGFloat t = i * (1.0 / (float)numPoints);
            Vector j = [self getValueAtLocalT:t forLocalCurve:points];
            
            j.w = 0;
            cumulativeDistance = cumulativeDistance + vector_size(vector_subtract(j, p));
            p = j;
            if (cumulativeDistance > spacing) {
                
                Vector d = [self getDerivativeAtLocalT:t forLocalCurve:points];
                pointWithDerivative new;
                new.point = j;
                new.derivative = d;
                localArray[calculatedPoints] = new;
                calculatedPoints++;
                
                cumulativeDistance = 0;
            }
        }
        numDataPoints[c] = calculatedPoints;
    }
    
    //Now make one array and clean up...
    int totalPoints = 0;
    for (int c = 0; c < [curveControlPoints count]; c++) {
        totalPoints = totalPoints + numDataPoints[c];
    }
    
    pointWithDerivative *returnData = (pointWithDerivative *)malloc(sizeof(pointWithDerivative) * totalPoints);
    int pointNum = 0;
    for (int c = 0; c < [curveControlPoints count]; c++) {
        pointWithDerivative *localArray = dataPoints[c];
        int numPoints = numDataPoints[c];
        for (int i = 0; i < numPoints; i++) {
            returnData[pointNum] = localArray[i];
            pointNum++;
        }
        free(localArray);
    }
    free(dataPoints);
    free(numDataPoints);
    
    *data = returnData;
    *numCalculatedPoints = totalPoints;

}

- (beizerCurve *)curveBySplittingAtPoint:(float)t startCurve:(bool)start {
    if ((t < 0) || (t > 1)) {
        NSLog(@"Invalid value to get bezier value");
    }
    
    //Find which curve this t belongs to
    float tInc = 1.0 / numCurves;
    int i = numCurves;
    while (i * tInc > t) {
        i--;
    }
    if (i >= numCurves) {
        i = numCurves - 1;
    }
    if (i < 0) {
        i = 0;
    }
    
    float curveTMin = i * tInc;
    float curveTMax = (i + 1) * tInc;
    float localT = (t - curveTMin) / (curveTMax - curveTMin);
    Vector points[4];
    
    NSData *pointsData = [curveControlPoints objectAtIndex:i];
    [pointsData getBytes:points length:sizeof(Vector)*4];
    
    Vector p4, p5, p6, p7, p8, p9;
//    p4 = vector_lerp(points[0], points[1], localT);
//    p5 = vector_lerp(points[1], points[2], localT);
//    p6 = vector_lerp(points[2], points[3], localT);
//    p7 = vector_lerp(p4, p5, localT);
//    p8 = vector_lerp(p5, p6, localT);
//    p9 = vector_lerp(p7, p8, localT);
    p4 = vector_lerp(points[1], points[0], localT);
    p5 = vector_lerp(points[2], points[1], localT);
    p6 = vector_lerp(points[3], points[2], localT);
    p7 = vector_lerp(p5, p4, localT);
    p8 = vector_lerp(p6, p5, localT);
    p9 = vector_lerp(p8, p7, localT);

    beizerCurve *new = [[beizerCurve alloc] init];
    if (start) {
        for (int j = 0; j < i; j++) {
            Vector points[4];
            NSData *pointsData = [curveControlPoints objectAtIndex:j];
            [pointsData getBytes:points length:sizeof(Vector)*4];
            [new addCurveWithStartPoint:points[0] i1:points[1] i2:points[2] end:points[3]];
        }
        
        [new addCurveWithStartPoint:points[0] i1:p4 i2:p7 end:p9];
    } else {
        [new addCurveWithStartPoint:p9 i1:p8 i2:p6 end:points[3]];
        
        for (int j = i+1; j < numCurves; j++) {
            Vector points[4];
            NSData *pointsData = [curveControlPoints objectAtIndex:j];
            [pointsData getBytes:points length:sizeof(Vector)*4];
            [new addCurveWithStartPoint:points[0] i1:points[1] i2:points[2] end:points[3]];
        }
    }

    return new;
}

@end
