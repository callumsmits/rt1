//
//  pdbData.h
//  present
//
//  Created by Callum Smits on 4/07/13.
//  Copyright (c) 2013 Callum Smits. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "bvhObject.h"
#import "pdbStateRawData.h"

#define kGRID 5

typedef struct _bvhStruct {
    float x, y, z, radius;
    bool leafNode;
    int rangeStart, rangeEnd;
} bvhStruct;

@interface pdbData : NSObject {
    float *modelData;
    NSUInteger numAtoms;
    float *grid[kGRID][kGRID][kGRID];
    NSUInteger gridNumAtoms[kGRID][kGRID][kGRID];
    float xMin, xMax, yMin, yMax, zMin, zMax;
    bvhObject *bvhMain;
    bvhStruct *bvh;
    int bvhSize;
    int *bvhMembers;
    int numBVHMembers;
    bool CPK;
    bool hydrophobic;
    float diffuse_R;
    float diffuse_G;
    float diffuse_B;
    float specular_R;
    float specular_G;
    float specular_B;
    float intrinsic_R;
    float intrinsic_G;
    float intrinsic_B;
    float shininess;
    float mirrorFraction;
    unsigned int clipApplied;
    int numStates;
}

@property (nonatomic) float *modelData;
@property (nonatomic) NSUInteger numAtoms;
@property (nonatomic) float xMin;
@property (nonatomic) float xMax;
@property (nonatomic) float yMin;
@property (nonatomic) float yMax;
@property (nonatomic) float zMin;
@property (nonatomic) float zMax;
@property (nonatomic) bvhStruct *bvh;
@property (nonatomic) int bvhSize;
@property (nonatomic) int numBVHMembers;
@property (nonatomic) int *bvhMembers;
@property (nonatomic) float diffuse_R;
@property (nonatomic) float diffuse_G;
@property (nonatomic) float diffuse_B;
@property (nonatomic) float specular_R;
@property (nonatomic) float specular_G;
@property (nonatomic) float specular_B;
@property (nonatomic) float intrinsic_R;
@property (nonatomic) float intrinsic_G;
@property (nonatomic) float intrinsic_B;
@property (nonatomic) float shininess;
@property (nonatomic) float mirrorFraction;
@property (nonatomic) unsigned int clipApplied;
@property (nonatomic) bool CPK;
@property (nonatomic) bool hydrophobic;
@property (nonatomic, strong) bvhObject *bvhMain;
@property (nonatomic) int numStates;

- (void)initWithPDBFile:(NSString *)fileName;
- (void)initWithPDBString:(NSString *)pdbString;
- (NSUInteger)numAtomsForGridX:(int)x Y:(int)y Z:(int)z;
- (float *)dataForGridX:(int)x Y:(int)y Z:(int)z;
- (void)logGridX:(int)x Y:(int)y Z:(int)z;
- (void)transformToX:(float)x Y:(float)y Z:(float)z;
- (void)rotateToA:(float)a B:(float)b C:(float)c;
- (void)applyTransformation;
- (pdbStateRawData *)addPDBForNextStateWithPDBFile:(NSString *)fileName;
- (NSMutableArray *)addStatesFromMultiStatePDBFile:(NSString *)fileName;
- (void)selectState:(int)state;
- (void)selectFractionalState:(float)state;
- (void)initWithMultiStatePDBFile:(NSString *)fileName;
- (void)setDiffuseR:(float)dr diffuseG:(float)dg diffuseB:(float)db specR:(float)sr specG:(float)sg specB:(float)sb shininess:(float)s mirrorFrac:(float)mf;
- (void)setDiffuseColour:(RGBColour)diffuse specularColour:(RGBColour)specular shininess:(float)s mirrorFrac:(float)mf;
- (int)numStates;

@end
