//
//  NAModelObject.m
//  rt1
//
//  Created by Callum Smits on 15/08/2014.
//  Copyright (c) 2014 a. All rights reserved.
//

#import "NAModelObject.h"
#import "vector_ops.h"
#import "matrix_ops.h"
#import "randomNumberGenerator.h"
#import "NABaseModelObject.h"

@interface NAModelObject () {
    beizerCurve *_dnaCurve;
    NSString *_sequence;
    unsigned int _NAType;
}

@property (nonatomic, strong) beizerCurve *_dnaCurve;
@property (nonatomic, strong) NSString *_sequence;

- (NSString *)complementaryBaseForBase:(NSString *)base;

@end

@implementation NAModelObject

@synthesize _dnaCurve, _sequence;

- (id)initWithCurve:(beizerCurve *)c initialOffset:(float)offset initialTwist:(float)it helicalTwist:(float)ht helicalRise:(float)hr nucleicAcidType:(unsigned int)type sequence:(NSString *)s {
    
    if (self = [super init]) {
        self._dnaCurve = c;
        self._sequence = s;
        _NAType = type;
        [self constructNAWithInitialOffset:offset initialTwist:it helicalTwist:ht helicalRise:hr nucleicAcidType:type];
    }
    
    return self;
}

- (void)constructNAWithInitialOffset:(float)offset initialTwist:(float)it helicalTwist:(float)ht helicalRise:(float)hr nucleicAcidType:(unsigned int)type {
    
    pointWithDerivative *points;
    int numPoints;
    
    [_dnaCurve generatePointsAndDerivativesWithSpacing:hr offset:offset intoArray:&points withCalculatedPoints:&numPoints];
    
    float twist = it;

    for (int i = 0; i < numPoints; i++) {

        Vector helicalAxis = points[i].derivative;
        helicalAxis = unit_vector(helicalAxis);
        NSString *base;
        unsigned int baseIndex = 0;
        if (_sequence) {
            base = [NSString stringWithFormat:@"%c", [_sequence characterAtIndex:baseIndex % [_sequence length]]];
        } else {
            char rand = [[randomNumberGenerator sharedInstance] getRandomByte];
            switch (rand & 0x3) {
                case 0: {
                    base = @"a";
                    break;
                }
                case 1: {
                    if (type == kNucleicAcidTypeDNA) {
                        base = @"t";
                    } else if (type == kNucleicAcidTypeRNA) {
                        base = @"u";
                    }
                    break;
                }
                case 2: {
                    base = @"c";
                    break;
                }
                case 3: {
                    base = @"g";
                    break;
                }
                    
                default:
                    break;
            }
        }
        
        //First rotate the base so that the axis of the initial model matches the helical axis at the current point
        NABaseModelObject *baseModel = [[NABaseModelObject alloc] initWithBase:base naType:type];
        Vector axisOrientation = [baseModel defaultAxisOrientation];
        
        if (vector_dot_product(helicalAxis, axisOrientation) < 1) {
            Vector rAxis = vector_cross(helicalAxis, axisOrientation);
            float rAngle = acosf(vector_dot_product(helicalAxis, axisOrientation));
            [baseModel rotateAroundVector:rAxis byAngle:rAngle];
        }
        
        //Now rotate the base around the helical axis
        [baseModel rotateAroundVector:helicalAxis byAngle:twist];
        
        //And translate to the correct position
        Vector point = points[i].point;
        [baseModel translateToX:point.x Y:point.y Z:point.z];
        
        //Now the same with the complementary base
        NSString *cBase = [self complementaryBaseForBase:base];
        NABaseModelObject *cBaseModel = [[NABaseModelObject alloc] initWithBase:cBase naType:type];
        [cBaseModel rotateAroundX:0 Y:0 Z:180 * radiansPerDegree];
        
        if (vector_dot_product(helicalAxis, axisOrientation) < 1) {
            Vector rAxis = vector_cross(helicalAxis, axisOrientation);
            float rAngle = acosf(vector_dot_product(helicalAxis, axisOrientation));
            [cBaseModel rotateAroundVector:rAxis byAngle:rAngle];
        }
        
        //Now rotate the base around the helical axis
        [cBaseModel rotateAroundVector:helicalAxis byAngle:twist];
        
        //And translate to the correct position
        [cBaseModel translateToX:point.x Y:point.y Z:point.z];
        
        [self addChildModel:baseModel];
        [self addChildModel:cBaseModel];
        
        twist += ht;
    }
    
}

- (NSString *)complementaryBaseForBase:(NSString *)base {
    if ([base isEqualToString:@"a"] || [base isEqualToString:@"A"]) {
        if (_NAType == kNucleicAcidTypeDNA) {
            return @"t";
        } else if (_NAType == kNucleicAcidTypeRNA) {
            return @"u";
        }
    } else if ([base isEqualToString:@"t"] || [base isEqualToString:@"T"]) {
        return @"a";
    } else if ([base isEqualToString:@"u"] || [base isEqualToString:@"U"]) {
        return @"a";
    } else if ([base isEqualToString:@"c"] || [base isEqualToString:@"C"]) {
        return @"g";
    } else if ([base isEqualToString:@"g"] || [base isEqualToString:@"G"]) {
        return @"c";
    }
    return nil;
}

@end
