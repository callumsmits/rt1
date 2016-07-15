//
//  pdbData.m
//  present
//
//  Created by Callum Smits on 4/07/13.
//  Copyright (c) 2013 Callum Smits. All rights reserved.
//

#import "pdbData.h"
#import "modelObject.h"
#import "typedefs.h"
#import "matrix_ops.h"
#import "vector_ops.h"
#import "colourPalette.h"

#define kBVHSafetyMargin 0.0;


@interface pdbData () {
    Matrix transform;
    NSMutableArray *stateDataArray;
//    float * originalData;
//    bvhObject *originalBVH;
    float *stateOriginalData;
    bvhObject *stateOriginalBVH;
    RGBColour pdbDataBackboneColour, pdbDataTurquoiseColour, pdbDataYellowColour;
}

@property (nonatomic) float* stateOriginalData;
@property (nonatomic, strong) bvhObject *stateOriginalBVH;

- (void)updateBVHcoordinates;
- (pdbStateRawData *)loadModelFromEnumerator:(NSEnumerator *)pdbEnumerator;
- (pdbStateRawData *)addPDBForNextStateWithPDBString:(NSString *)pdbString;
- (unsigned int)hashForAtomNameString:(NSString *)atomName;
- (unsigned int)hashForResidueNameString:(NSString *)residueName;

@end

@implementation pdbData

@synthesize numAtoms, modelData;
@synthesize xMax,xMin,yMin,yMax,zMin,zMax;
@synthesize bvh, bvhMembers, bvhSize, numBVHMembers;
@synthesize diffuse_R, diffuse_G, diffuse_B, specular_R, specular_G, specular_B, intrinsic_R, intrinsic_G, intrinsic_B, shininess, mirrorFraction;
@synthesize CPK, bvhMain, stateOriginalData, stateOriginalBVH, hydrophobic;
@synthesize numStates;
@synthesize clipApplied;

- (id)init {
    if (self = [super init]) {
        self.CPK = NO;
        self.hydrophobic = NO;
        numAtoms = 0;
        self.intrinsic_R = 0;
        self.intrinsic_G = 0;
        self.intrinsic_B = 0;
        self.clipApplied = NO;
        
        pdbDataBackboneColour.red = 220/255.0;
        pdbDataBackboneColour.green = 220/255.0;
        pdbDataBackboneColour.blue = 220/255.0;
        
        pdbDataTurquoiseColour.red = 81/255.0;
        pdbDataTurquoiseColour.green = 222/255.0;
        pdbDataTurquoiseColour.blue = 252/255.0;
        
        pdbDataYellowColour.red = 253/255.0;
        pdbDataYellowColour.green = 244/255.0;
        pdbDataYellowColour.blue = 23/255.0;
    }
    return self;
}

- (void)initWithPDBFile:(NSString *)fileName {
    numAtoms = 0;
    loadIdentityMatrix(&transform);
    stateDataArray = [NSMutableArray arrayWithCapacity:1];
    pdbStateRawData *newState = [self addPDBForNextStateWithPDBFile:fileName];
    [stateDataArray addObject:newState];
    self.numStates = 1;
    [self selectState:0];
}

- (void)initWithPDBString:(NSString *)pdbString {
    numAtoms = 0;
    loadIdentityMatrix(&transform);
    stateDataArray = [NSMutableArray arrayWithCapacity:1];
    pdbStateRawData *newState = [self addPDBForNextStateWithPDBString:pdbString];
    [stateDataArray addObject:newState];
    self.numStates = 1;
    [self selectState:0];
}

- (void)initWithMultiStatePDBFile:(NSString *)fileName {
    numAtoms = 0;
    loadIdentityMatrix(&transform);
    stateDataArray = [self addStatesFromMultiStatePDBFile:fileName];
    [self selectState:0];
}

- (unsigned int)hashForAtomNameString:(NSString *)atomName {
    const char *atomNameCString;
    atomNameCString = [atomName cStringUsingEncoding:NSUTF8StringEncoding];
    return (atomNameCString[0] << 24) + (atomNameCString[1] << 16) + (atomNameCString[2] << 8) + atomNameCString[3];
}

- (unsigned int)hashForResidueNameString:(NSString *)residueName {
    const char *residueNameCString;
    residueNameCString = [residueName cStringUsingEncoding:NSUTF8StringEncoding];
    return (residueNameCString[0] << 16) + (residueNameCString[1] << 8) + (residueNameCString[2]);
}

- (void)selectState:(int)state {
    if (state < numStates) {
        pdbStateRawData *selectedState = [stateDataArray objectAtIndex:state];
        stateOriginalData = selectedState.stateModelData;
        stateOriginalBVH = selectedState.stateBVH;
        self.bvhMain = stateOriginalBVH;
        if (modelData) {
            free(modelData);
        }
        modelData = (float *)malloc(sizeof(float) * NUM_ATOMDATA * numAtoms);
        memcpy(modelData, stateOriginalData, sizeof(float) * NUM_ATOMDATA * numAtoms);

    }
}

- (void)selectFractionalState:(float)state {
    if (numStates == 1) {
        return;
    }
    if (state < 0) {
        state += numStates;
    }
    if (state > numStates) {
        state = fmodf(state, numStates);
    }
    if (state <= numStates) {
        int prevState = (int)floor(state);
        pdbStateRawData *firstState = [stateDataArray objectAtIndex:prevState];
        float *firstStateOriginalData = firstState.stateModelData;
        
        int nextState = (int)ceil(state);
        if (nextState > numStates - 1) {
            nextState = 0;
        }
        pdbStateRawData *selectedState = [stateDataArray objectAtIndex:nextState];
        stateOriginalData = selectedState.stateModelData;
        stateOriginalBVH = selectedState.stateBVH;
        self.bvhMain = stateOriginalBVH;
        if (modelData) {
            free(modelData);
        }
        modelData = (float *)malloc(sizeof(float) * NUM_ATOMDATA * numAtoms);
        memcpy(modelData, stateOriginalData, sizeof(float) * NUM_ATOMDATA * numAtoms);
        //Adjust the coordinates
        float fraction = 1.0 - (state - floor(state));
        for (int i = 0; i < numAtoms; i++) {
            Vector a, b;
            float *atom = firstStateOriginalData + NUM_ATOMDATA * i;
            a.x = *(atom + X);
            a.y = *(atom + Y);
            a.z = *(atom + Z);
            a.w = 1;

            atom = stateOriginalData + NUM_ATOMDATA * i;
            b.x = *(atom + X);
            b.y = *(atom + Y);
            b.z = *(atom + Z);
            b.w = 1;

            Vector r = vector_lerp(a, b, fraction);
            
            float *dst = modelData + NUM_ATOMDATA * i;
            *(dst + X) = r.x;
            *(dst + Y) = r.y;
            *(dst + Z) = r.z;
        }
    }
}

- (void)setDiffuseColour:(RGBColour)diffuse specularColour:(RGBColour)specular shininess:(float)s mirrorFrac:(float)mf {
    [self setDiffuseR:diffuse.red diffuseG:diffuse.green diffuseB:diffuse.blue specR:specular.red specG:specular.green specB:specular.blue shininess:s mirrorFrac:mf];
}

- (void)setDiffuseR:(float)dr diffuseG:(float)dg diffuseB:(float)db specR:(float)sr specG:(float)sg specB:(float)sb shininess:(float)s mirrorFrac:(float)mf {
    self.diffuse_R = dr;
    self.diffuse_G = dg;
    self.diffuse_B = db;
    self.specular_R = sr;
    self.specular_G = sg;
    self.specular_B = sb;
    self.shininess = s;
    self.mirrorFraction = mf;
}

- (NSMutableArray *)addStatesFromMultiStatePDBFile:(NSString *)fileName {
    
    NSMutableArray *stateArray = [NSMutableArray arrayWithCapacity:0];
    
    NSError *error = nil;
    
    NSString *pdbAsString = [NSString stringWithContentsOfFile:fileName
                                                      encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        NSLog(@"Error opening PDB file: %@", error);
        return nil;
    }
    NSArray *pdbLines = [pdbAsString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    NSEnumerator *pdbEnumerator = [pdbLines objectEnumerator];
    
    NSString *pdbLine;
    
    //Find the first model
    while ((pdbLine = [pdbEnumerator nextObject]) && ([pdbLine hasPrefix:@"MODEL"] == false)) {
    }
    
    pdbStateRawData *newState;
    while ((newState = [self loadModelFromEnumerator:pdbEnumerator])) {
        [stateArray addObject:newState];
    }
    
    self.numStates = (int)[stateArray count];
    return stateArray;
}

- (pdbStateRawData *)loadModelFromEnumerator:(NSEnumerator *)pdbEnumerator {

    float *newModelData = nil;
    NSString *pdbLine;
    NSMutableArray *atomsArray = [NSMutableArray arrayWithCapacity:0];
    while ((pdbLine = [pdbEnumerator nextObject]) && ([pdbLine hasPrefix:@"MODEL"] == false)) {
        if (([pdbLine length] > 4) &&
            ([pdbLine characterAtIndex:0] == 'A') &&
            ([pdbLine characterAtIndex:1] == 'T') &&
            ([pdbLine characterAtIndex:2] == 'O') &&
            ([pdbLine characterAtIndex:3] == 'M')) {
            [atomsArray addObject:pdbLine];
        }
    }
    
    if ([atomsArray count] == 0) {
        return nil;
    }
    
    if (numAtoms > 0) {
        if (numAtoms != [atomsArray count]) {
            NSLog(@"Error - loading PDB state with different number of atoms!");
        }
    } else {
        numAtoms = [atomsArray count];
    }
    newModelData = (float *)malloc(sizeof(float) * NUM_ATOMDATA * numAtoms);
    
    if (!newModelData) {
        NSLog(@"Error allocating memory for PDB file");
        return nil;
    }
    
    NSRange xRange, yRange, zRange, atomTypeRange, sequenceNumber;
    xRange.location = 30;
    xRange.length = 8;
    yRange.location = 38;
    yRange.length = 8;
    zRange.location = 46;
    zRange.length = 8;
    atomTypeRange.location = 76;
    atomTypeRange.length = 2;
    sequenceNumber.location = 22;
    sequenceNumber.length = 4;
    int currentResidue = -1000000000;
    NSMutableArray *bvhObjects = [NSMutableArray arrayWithCapacity:0];
    for (int i = 0; i < [atomsArray count]; i++) {
        float x, y, z, vdw;
        int residueNumber;
        RGBColour atomColour;
        NSString *currentLine = [atomsArray objectAtIndex:i];
        x = [[currentLine substringWithRange:xRange] floatValue];
        y = [[currentLine substringWithRange:yRange] floatValue];
        z = [[currentLine substringWithRange:zRange] floatValue];
        NSString *atomTypeString = [currentLine substringWithRange:atomTypeRange];
        residueNumber = [[currentLine substringWithRange:sequenceNumber] intValue];
        if ((residueNumber == currentResidue) || (residueNumber == currentResidue + 1) || (residueNumber == currentResidue + 2) || (residueNumber == currentResidue + 3)
            || (residueNumber == currentResidue + 4) || (residueNumber == currentResidue + 5)) {
            //            || (residueNumber == currentResidue + 6) || (residueNumber == currentResidue + 7)) {
            bvhObject *currentBV = [bvhObjects lastObject];
            [[currentBV children] addObject:[NSNumber numberWithInt:i]];
        } else {
            bvhObject *newBV = [[bvhObject alloc] initWithX:0 Y:0 Z:0 radius:0 isLeafNode:YES];
            [bvhObjects addObject:newBV];
            [[newBV children] addObject:[NSNumber numberWithInt:i]];
            currentResidue = residueNumber;
        }
        
        if ([atomTypeString characterAtIndex:1] == 'H') {
            vdw = 2.2;
            atomColour.red = 0.8;
            atomColour.green = 0.8;
            atomColour.blue = 0.8;
        } else if ([atomTypeString characterAtIndex:1] == 'C') {
            vdw = 1.7;
            atomColour.red = 0.8;
            atomColour.green = 0.8;
            atomColour.blue = 0.8;
        } else if ([atomTypeString characterAtIndex:1] == 'N') {
            vdw = 1.55;
            atomColour.red = 0.0;
            atomColour.green = 0.0;
            atomColour.blue = 0.8;
        } else if ([atomTypeString characterAtIndex:1] == 'O') {
            vdw = 1.52;
            atomColour.red = 0.8;
            atomColour.green = 0.0;
            atomColour.blue = 0.0;
        } else if ([atomTypeString characterAtIndex:1] == 'P') {
            vdw = 1.8;
//            vdw = 1.5;
            atomColour.red = 0.8;
            atomColour.green = 0.8;
            atomColour.blue = 0.0;
        } else if ([atomTypeString characterAtIndex:1] == 'S') {
            vdw = 1.8;
            atomColour.red = 0.0;
            atomColour.green = 0.8;
            atomColour.blue = 0.0;
        } else {
            vdw = 1.5;
            atomColour.red = 1.0;
            atomColour.green = 1.0;
            atomColour.blue = 1.0;
        }
        float *atom = newModelData + i * NUM_ATOMDATA;
        *(atom + X) = x;
        *(atom + Y) = y;
        *(atom + Z) = z;
        *(atom + VDW) = vdw;
        if (CPK) {
            *(atom + DIFFUSE_R) = atomColour.red;
            *(atom + DIFFUSE_G) = atomColour.green;
            *(atom + DIFFUSE_B) = atomColour.blue;
//            *(atom + SPEC_R) = 0.5 * atomColour.red;
//            *(atom + SPEC_G) = 0.5 * atomColour.green;
//            *(atom + SPEC_B) = 0.5 * atomColour.blue;
            *(atom + SPEC_R) = 0.6;
            *(atom + SPEC_G) = 0.6;
            *(atom + SPEC_B) = 0.6;
            *(atom + INTRINSIC_R) = 0;
            *(atom + INTRINSIC_G) = 0;
            *(atom + INTRINSIC_B) = 0;
        } else {
            *(atom + DIFFUSE_R) = diffuse_R;
            *(atom + DIFFUSE_G) = diffuse_G;
            *(atom + DIFFUSE_B) = diffuse_B;
            *(atom + SPEC_R) = specular_R;
            *(atom + SPEC_G) = specular_G;
            *(atom + SPEC_B) = specular_B;
            *(atom + INTRINSIC_R) = intrinsic_R;
            *(atom + INTRINSIC_G) = intrinsic_G;
            *(atom + INTRINSIC_B) = intrinsic_B;
        }
        *(atom + MIRROR_FRAC) = mirrorFraction;
        *(atom + SHININESS) = shininess;
        *(atom + CLIP_APPLIED) = clipApplied;
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
    
    //Put a copy of this in the originalData
    //    originalData = (float *)malloc(sizeof(float) * NUM_ATOMDATA * numAtoms);
    //    memcpy(originalData, modelData, sizeof(float) * NUM_ATOMDATA * numAtoms);
    
    //Adjust the dimensions for the VDW radii
    xMin = xMin - 1.8;
    xMax = xMax + 1.8;
    yMin = yMin - 1.8;
    yMax = yMax + 1.8;
    zMin = zMin - 1.8;
    zMax = zMax + 1.8;
    
    //Now setup boundary volumes for children
    NSEnumerator *boundaryGroup  = [bvhObjects objectEnumerator];
    
    bvhObject *current;
    while (current = [boundaryGroup nextObject]) {
        float xAverage = 0, yAverage = 0, zAverage = 0;
        for (int i = 0; i < [current.children count]; i++) {
            float *atom = newModelData + [[current.children objectAtIndex:i] integerValue] * NUM_ATOMDATA;
            xAverage = xAverage + *(atom + X);
            yAverage = yAverage + *(atom + Y);
            zAverage = zAverage + *(atom + Z);
        }
        xAverage = xAverage / [current.children count];
        yAverage = yAverage / [current.children count];
        zAverage = zAverage / [current.children count];
        
        float maxDist = 0, x, y, z, vdw;
        int maxAtom = 0;
        for (int i = 0; i < [current.children count]; i++) {
            float *atom = newModelData + [[current.children objectAtIndex:i] integerValue] * NUM_ATOMDATA;
            x = *(atom + X);
            y = *(atom + Y);
            z = *(atom + Z);
            vdw = *(atom + VDW);
            float dist = sqrtf(powf(x - xAverage, 2) + powf(y - yAverage, 2) + powf(z - zAverage, 2)) + vdw + kBVHSafetyMargin;
            if (dist > maxDist) {
                maxDist = dist;
                maxAtom = i;
            }
        }
        current.x = xAverage;
        current.y = yAverage;
        current.z = zAverage;
        //        float *atom = modelData + maxAtom * NUM_ATOMDATA;
        //        x = *(atom + X);
        //        y = *(atom + Y);
        //        z = *(atom + Z);
        //        vdw = *(atom + VDW);
        //        current.radius = sqrtf(powf(x - xAverage, 2) + powf(y - yAverage, 2) + powf(z - zAverage, 2)) + vdw;
        current.radius = maxDist;
    }
    
    //Find any other atoms that should be included in this volume
    /*for (int i = 0; i < [atomsArray count]; i++) {
     float *atom = modelData + i * NUM_ATOMDATA;
     float x, y, z, vdw;
     x = *(atom + X);
     y = *(atom + Y);
     z = *(atom + Z);
     vdw = *(atom + VDW);
     for (int j = 0; j < [bvhObjects count]; j++) {
     bvhObject *current = [bvhObjects objectAtIndex:j];
     float distance = sqrtf(powf(x - current.x, 2) + powf(y - current.y, 2) + powf(z - current.z, 2));
     if (distance < vdw + current.radius) {
     NSNumber *currentI = [NSNumber numberWithInt:i];
     BOOL alreadyPresent = CFArrayContainsValue((__bridge CFArrayRef)(current.children), CFRangeMake(0, [current.children count]), (CFNumberRef)currentI);
     if (!alreadyPresent) {
     [current.children addObject:currentI];
     }
     }
     }
     }*/
    
    //Now cluster volumes
    float xAverage = 0, yAverage = 0, zAverage = 0;
    for (int i = 0; i < [bvhObjects count]; i++) {
        bvhObject *current = [bvhObjects objectAtIndex:i];
        xAverage = xAverage + current.x;
        yAverage = yAverage + current.y;
        zAverage = zAverage + current.z;
    }
    xAverage = xAverage / [bvhObjects count];
    yAverage = yAverage / [bvhObjects count];
    zAverage = zAverage / [bvhObjects count];
    
    float maxDist = 0;
    for (int i = 0; i < [bvhObjects count]; i++) {
        bvhObject *current = [bvhObjects objectAtIndex:i];
        float dist = sqrtf(powf(current.x - xAverage, 2) + powf(current.y - yAverage, 2) + powf(current.z - zAverage, 2)) + current.radius + kBVHSafetyMargin;
        if (dist > maxDist) {
            maxDist = dist;
        }
    }
    
    bvhObject *masterObject = [[bvhObject alloc] initWithX:xAverage Y:yAverage Z:zAverage radius:maxDist isLeafNode:NO];
    for (int i = 0; i < [bvhObjects count]; i++) {
        [masterObject.children addObject:[bvhObjects objectAtIndex:i]];
    }
    masterObject.atoms = numAtoms;
    //    self.bvhMain = masterObject;
    //    self.originalBVH = masterObject;
    //    [self updateBVHcoordinates];
    
    pdbStateRawData *newState = [[pdbStateRawData alloc] init];
    newState.stateModelData = newModelData;
    newState.stateBVH = masterObject;
    
    return newState;
}

- (pdbStateRawData *)addPDBForNextStateWithPDBFile:(NSString *)fileName {
    NSError *error = nil;
    
    NSString *pdbAsString = [NSString stringWithContentsOfFile:fileName
                                                      encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        NSLog(@"Error opening PDB file: %@", error);
        return nil;
    }
    
    return [self addPDBForNextStateWithPDBString:pdbAsString];
}

- (pdbStateRawData *)addPDBForNextStateWithPDBString:(NSString *)pdbString {
    
    float *newModelData = nil;

    NSArray *pdbLines = [pdbString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    NSMutableArray *atomsArray = [NSMutableArray arrayWithCapacity:0];
    
    NSEnumerator *pdbEnumerator = [pdbLines objectEnumerator];
    
    NSString *pdbLine;
    
    while (pdbLine = [pdbEnumerator nextObject]) {
        if (([pdbLine length] > 4) &&
            ([pdbLine characterAtIndex:0] == 'A') &&
            ([pdbLine characterAtIndex:1] == 'T') &&
            ([pdbLine characterAtIndex:2] == 'O') &&
            ([pdbLine characterAtIndex:3] == 'M')) {
            [atomsArray addObject:pdbLine];
        }
    }
    
    if (numAtoms > 0) {
        if (numAtoms != [atomsArray count]) {
            NSLog(@"Error - loading PDB state with different number of atoms!");
        }
    } else {
        numAtoms = [atomsArray count];
    }
    newModelData = (float *)malloc(sizeof(float) * NUM_ATOMDATA * numAtoms);
    
    if (!newModelData) {
        NSLog(@"Error allocating memory for PDB file");
        return nil;
    }
    
    unsigned int AHash, CHash, DHash, EHash, FHash, GHash, HHash, IHash, KHash, LHash, MHash, NHash, PHash, QHash, SHash, THash, VHash, WHash, YHash;
    AHash = [self hashForResidueNameString:@"ALA"];
    CHash = [self hashForResidueNameString:@"CYS"];
    DHash = [self hashForResidueNameString:@"ASP"];
    EHash = [self hashForResidueNameString:@"GLU"];
    FHash = [self hashForResidueNameString:@"PHE"];
    GHash = [self hashForResidueNameString:@"GLY"];
    HHash = [self hashForResidueNameString:@"HIS"];
    IHash = [self hashForResidueNameString:@"ILE"];
    KHash = [self hashForResidueNameString:@"LYS"];
    LHash = [self hashForResidueNameString:@"LEU"];
    MHash = [self hashForResidueNameString:@"MET"];
    NHash = [self hashForResidueNameString:@"ASN"];
    PHash = [self hashForResidueNameString:@"PRO"];
    QHash = [self hashForResidueNameString:@"GLN"];
    SHash = [self hashForResidueNameString:@"SER"];
    THash = [self hashForResidueNameString:@"THR"];
    VHash = [self hashForResidueNameString:@"VAL"];
    WHash = [self hashForResidueNameString:@"TRP"];
    YHash = [self hashForResidueNameString:@"TYR"];
    
    unsigned int bbNHash, bbCAHash, bbCHash, bbOHash, bbHAHash, bbHHash, bbHA2Hash, bbHA3Hash;
    bbNHash = [self hashForAtomNameString:@" N  "];
    bbCAHash = [self hashForAtomNameString:@" CA "];
    bbCHash = [self hashForAtomNameString:@" C  "];
    bbOHash = [self hashForAtomNameString:@" O  "];
    bbHAHash = [self hashForAtomNameString:@" HA "];
    bbHHash = [self hashForAtomNameString:@" H  "];
    bbHA2Hash = [self hashForAtomNameString:@" HA2"];
    bbHA3Hash = [self hashForAtomNameString:@" HA3"];
    
    NSRange xRange, yRange, zRange, atomTypeRange, sequenceNumber, atomNameRange, residueNameRange;
    xRange.location = 30;
    xRange.length = 8;
    yRange.location = 38;
    yRange.length = 8;
    zRange.location = 46;
    zRange.length = 8;
    atomTypeRange.location = 76;
    atomTypeRange.length = 2;
    sequenceNumber.location = 22;
    sequenceNumber.length = 4;
    atomNameRange.location = 12;
    atomNameRange.length = 4;
    residueNameRange.location = 17;
    residueNameRange.length = 3;
    int currentResidue = -1000000000;
    NSMutableArray *bvhObjects = [NSMutableArray arrayWithCapacity:0];
    for (int i = 0; i < [atomsArray count]; i++) {
        float x, y, z, vdw;
        int residueNumber;
        RGBColour atomColour;
        NSString *currentLine = [atomsArray objectAtIndex:i];
        x = [[currentLine substringWithRange:xRange] floatValue];
        y = [[currentLine substringWithRange:yRange] floatValue];
        z = [[currentLine substringWithRange:zRange] floatValue];
        NSString *atomTypeString = [currentLine substringWithRange:atomTypeRange];
        NSString *atomNameString = [currentLine substringWithRange:atomNameRange];
        NSString *residueNameString = [currentLine substringWithRange:residueNameRange];
        unsigned int atomHash = [self hashForAtomNameString:atomNameString];
        unsigned int residueHash = [self hashForResidueNameString:residueNameString];
        residueNumber = [[currentLine substringWithRange:sequenceNumber] intValue];
        if ((residueNumber == currentResidue) || (residueNumber == currentResidue + 1) || (residueNumber == currentResidue + 2) || (residueNumber == currentResidue + 3)
            || (residueNumber == currentResidue + 4) || (residueNumber == currentResidue + 5)) {
            //            || (residueNumber == currentResidue + 6) || (residueNumber == currentResidue + 7)) {
            bvhObject *currentBV = [bvhObjects lastObject];
            [[currentBV children] addObject:[NSNumber numberWithInt:i]];
        } else {
            bvhObject *newBV = [[bvhObject alloc] initWithX:0 Y:0 Z:0 radius:0 isLeafNode:YES];
            [bvhObjects addObject:newBV];
            [[newBV children] addObject:[NSNumber numberWithInt:i]];
            currentResidue = residueNumber;
        }
        
        if ([atomTypeString characterAtIndex:1] == 'H') {
            vdw = 1.5;
            atomColour.red = 0.8;
            atomColour.green = 0.8;
            atomColour.blue = 0.8;
        } else if ([atomTypeString characterAtIndex:1] == 'C') {
            vdw = 1.7;
            atomColour.red = 0.8;
            atomColour.green = 0.8;
            atomColour.blue = 0.8;
        } else if ([atomTypeString characterAtIndex:1] == 'N') {
            vdw = 1.55;
            atomColour.red = 0.0;
            atomColour.green = 0.0;
            atomColour.blue = 0.8;
        } else if ([atomTypeString characterAtIndex:1] == 'O') {
            vdw = 1.52;
            atomColour.red = 0.8;
            atomColour.green = 0.0;
            atomColour.blue = 0.0;
        } else if ([atomTypeString characterAtIndex:1] == 'P') {
            vdw = 1.8;
            atomColour.red = 0.85;
            atomColour.green = 0.73;
            atomColour.blue = 0.29;
        } else if ([atomTypeString characterAtIndex:1] == 'S') {
            vdw = 1.8;
            atomColour.red = 0.0;
            atomColour.green = 0.8;
            atomColour.blue = 0.0;
        } else {
            vdw = 1.5;
            atomColour.red = 1.0;
            atomColour.green = 1.0;
            atomColour.blue = 1.0;
        }
        float *atom = newModelData + i * NUM_ATOMDATA;
        *(atom + X) = x;
        *(atom + Y) = y;
        *(atom + Z) = z;
        *(atom + VDW) = vdw;
        if (CPK) {
            *(atom + DIFFUSE_R) = atomColour.red;
            *(atom + DIFFUSE_G) = atomColour.green;
            *(atom + DIFFUSE_B) = atomColour.blue;
            *(atom + SPEC_R) = 0.6;
            *(atom + SPEC_G) = 0.6;
            *(atom + SPEC_B) = 0.6;
            //            *(atom + SPEC_R) = 0.5 * atomColour.red;
            //            *(atom + SPEC_G) = 0.5 * atomColour.green;
            //            *(atom + SPEC_B) = 0.5 * atomColour.blue;
            *(atom + INTRINSIC_R) = 0;
            *(atom + INTRINSIC_G) = 0;
            *(atom + INTRINSIC_B) = 0;
        } else if (hydrophobic) {
            if ((atomHash == bbNHash) || (atomHash == bbCAHash) || (atomHash == bbCHash) || (atomHash == bbOHash) || (atomHash == bbHHash) ||
                (atomHash == bbHAHash) || (atomHash == bbHA2Hash) || (atomHash == bbHA3Hash)) {
                    atomColour = pdbDataBackboneColour;
            } else if ((residueHash == FHash) || (residueHash == IHash) || (residueHash == LHash) || (residueHash == WHash) || (residueHash == VHash) || (residueHash == CHash) || (residueHash == MHash) || (residueHash == AHash)) {
                atomColour = pdbDataYellowColour;
            } else {
                atomColour = pdbDataTurquoiseColour;
            }
            *(atom + DIFFUSE_R) = atomColour.red;
            *(atom + DIFFUSE_G) = atomColour.green;
            *(atom + DIFFUSE_B) = atomColour.blue;
            *(atom + SPEC_R) = 0.6;
            *(atom + SPEC_G) = 0.6;
            *(atom + SPEC_B) = 0.6;
            *(atom + INTRINSIC_R) = 0;
            *(atom + INTRINSIC_G) = 0;
            *(atom + INTRINSIC_B) = 0;
        }else {
            *(atom + DIFFUSE_R) = diffuse_R;
            *(atom + DIFFUSE_G) = diffuse_G;
            *(atom + DIFFUSE_B) = diffuse_B;
            *(atom + SPEC_R) = specular_R;
            *(atom + SPEC_G) = specular_G;
            *(atom + SPEC_B) = specular_B;
            *(atom + INTRINSIC_R) = intrinsic_R;
            *(atom + INTRINSIC_G) = intrinsic_G;
            *(atom + INTRINSIC_B) = intrinsic_B;
        }
        *(atom + MIRROR_FRAC) = mirrorFraction;
        *(atom + SHININESS) = shininess;
        *(atom + CLIP_APPLIED) = clipApplied;
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
    
    //Put a copy of this in the originalData
    //    originalData = (float *)malloc(sizeof(float) * NUM_ATOMDATA * numAtoms);
    //    memcpy(originalData, modelData, sizeof(float) * NUM_ATOMDATA * numAtoms);
    
    //Adjust the dimensions for the VDW radii
    xMin = xMin - 1.8;
    xMax = xMax + 1.8;
    yMin = yMin - 1.8;
    yMax = yMax + 1.8;
    zMin = zMin - 1.8;
    zMax = zMax + 1.8;
    
    //Now setup boundary volumes for children
    NSEnumerator *boundaryGroup  = [bvhObjects objectEnumerator];
    
    bvhObject *current;
    while (current = [boundaryGroup nextObject]) {
        float xAverage = 0, yAverage = 0, zAverage = 0;
        for (int i = 0; i < [current.children count]; i++) {
            float *atom = newModelData + [[current.children objectAtIndex:i] integerValue] * NUM_ATOMDATA;
            xAverage = xAverage + *(atom + X);
            yAverage = yAverage + *(atom + Y);
            zAverage = zAverage + *(atom + Z);
        }
        xAverage = xAverage / [current.children count];
        yAverage = yAverage / [current.children count];
        zAverage = zAverage / [current.children count];
        
        float maxDist = 0, x, y, z, vdw;
        int maxAtom = 0;
        for (int i = 0; i < [current.children count]; i++) {
            float *atom = newModelData + [[current.children objectAtIndex:i] integerValue] * NUM_ATOMDATA;
            x = *(atom + X);
            y = *(atom + Y);
            z = *(atom + Z);
            vdw = *(atom + VDW);
            float dist = sqrtf(powf(x - xAverage, 2) + powf(y - yAverage, 2) + powf(z - zAverage, 2)) + vdw + kBVHSafetyMargin;
            if (dist > maxDist) {
                maxDist = dist;
                maxAtom = i;
            }
        }
        current.x = xAverage;
        current.y = yAverage;
        current.z = zAverage;
        //        float *atom = modelData + maxAtom * NUM_ATOMDATA;
        //        x = *(atom + X);
        //        y = *(atom + Y);
        //        z = *(atom + Z);
        //        vdw = *(atom + VDW);
        //        current.radius = sqrtf(powf(x - xAverage, 2) + powf(y - yAverage, 2) + powf(z - zAverage, 2)) + vdw;
        current.radius = maxDist;
    }
    
    //Find any other atoms that should be included in this volume
    /*for (int i = 0; i < [atomsArray count]; i++) {
     float *atom = modelData + i * NUM_ATOMDATA;
     float x, y, z, vdw;
     x = *(atom + X);
     y = *(atom + Y);
     z = *(atom + Z);
     vdw = *(atom + VDW);
     for (int j = 0; j < [bvhObjects count]; j++) {
     bvhObject *current = [bvhObjects objectAtIndex:j];
     float distance = sqrtf(powf(x - current.x, 2) + powf(y - current.y, 2) + powf(z - current.z, 2));
     if (distance < vdw + current.radius) {
     NSNumber *currentI = [NSNumber numberWithInt:i];
     BOOL alreadyPresent = CFArrayContainsValue((__bridge CFArrayRef)(current.children), CFRangeMake(0, [current.children count]), (CFNumberRef)currentI);
     if (!alreadyPresent) {
     [current.children addObject:currentI];
     }
     }
     }
     }*/
    
    //Now cluster volumes
    float xAverage = 0, yAverage = 0, zAverage = 0;
    for (int i = 0; i < [bvhObjects count]; i++) {
        bvhObject *current = [bvhObjects objectAtIndex:i];
        xAverage = xAverage + current.x;
        yAverage = yAverage + current.y;
        zAverage = zAverage + current.z;
    }
    xAverage = xAverage / [bvhObjects count];
    yAverage = yAverage / [bvhObjects count];
    zAverage = zAverage / [bvhObjects count];
    
    float maxDist = 0;
    for (int i = 0; i < [bvhObjects count]; i++) {
        bvhObject *current = [bvhObjects objectAtIndex:i];
        float dist = sqrtf(powf(current.x - xAverage, 2) + powf(current.y - yAverage, 2) + powf(current.z - zAverage, 2)) + current.radius + kBVHSafetyMargin;
        if (dist > maxDist) {
            maxDist = dist;
        }
    }
    
    bvhObject *masterObject = [[bvhObject alloc] initWithX:xAverage Y:yAverage Z:zAverage radius:maxDist isLeafNode:NO];
    for (int i = 0; i < [bvhObjects count]; i++) {
        [masterObject.children addObject:[bvhObjects objectAtIndex:i]];
    }
    masterObject.atoms = numAtoms;
    //    self.bvhMain = masterObject;
    //    self.originalBVH = masterObject;
    //    [self updateBVHcoordinates];
    
    pdbStateRawData *newState = [[pdbStateRawData alloc] init];
    newState.stateModelData = newModelData;
    newState.stateBVH = masterObject;
    
    return newState;
    
}

- (void)transformToX:(float)x Y:(float)y Z:(float)z {
    Matrix tempMatrix;
    
    makeMatrix(&tempMatrix,
               1, 0, 0, x,
               0, 1, 0, y,
               0, 0, 1, z,
               0, 0, 0, 1);
    
    multiplyMatrix(tempMatrix, &transform);
}

- (void)rotateToA:(float)a B:(float)b C:(float)c {
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

}

- (void)applyTransformation {
    
    for (int i = 0; i < numAtoms; i++) {
        Vector a;
        float *atom = stateOriginalData + NUM_ATOMDATA * i;
        a.x = *(atom + X);
        a.y = *(atom + Y);
        a.z = *(atom + Z);
        a.w = 1;
        
        Vector r = vectorMatrixMultiply(transform, a);
        float *dst = modelData + NUM_ATOMDATA * i;
        *(dst + X) = r.x;
        *(dst + Y) = r.y;
        *(dst + Z) = r.z;
    }
    
    [self updateBVHcoordinates];
}

- (void)updateBVHcoordinates {
    self.bvhMain = [stateOriginalBVH copyWithTransform:transform];
//    self.bvhMain = originalBVH;
    
    //Setup the bvh arrays
    NSUInteger numMembers = [bvhMain.children count];
    for (int i = 0; i < [bvhMain.children count]; i++) {
        bvhObject *current = [bvhMain.children objectAtIndex:i];
        numMembers = numMembers + [current.children count];
    }
    int numBVHObjects = (int)[bvhMain.children count] + 1;
    self.bvh = (bvhStruct *)malloc(sizeof(bvhStruct) * numBVHObjects);
    self.bvhMembers = (int *)malloc(sizeof(int) * numMembers);
    
    int memberIndex = 0;
    int startRange, endRange;
    startRange = memberIndex;
    for (int i = 0; i < [bvhMain.children count]; i++) {
        bvhMembers[memberIndex] = i + 1;
        memberIndex++;
    }
    endRange = memberIndex;
    int currentBVH = 0;
    bvh[currentBVH].x = bvhMain.x;
    bvh[currentBVH].y = bvhMain.y;
    bvh[currentBVH].z = bvhMain.z;
    bvh[currentBVH].radius = bvhMain.radius;
    bvh[currentBVH].leafNode = NO;
    bvh[currentBVH].rangeStart = startRange;
    bvh[currentBVH].rangeEnd = endRange;
    currentBVH++;
    
    for (int i = 0; i < [bvhMain.children count]; i++) {
        startRange = memberIndex;
        bvhObject *current = [bvhMain.children objectAtIndex:i];
        for (int j = 0; j < [current.children count]; j++) {
            int object = (int)[[current.children objectAtIndex:j] integerValue];
            bvhMembers[memberIndex] = object;
            memberIndex++;
        }
        endRange = memberIndex;
        bvh[currentBVH].x = current.x;
        bvh[currentBVH].y = current.y;
        bvh[currentBVH].z = current.z;
        bvh[currentBVH].radius = current.radius;
        bvh[currentBVH].leafNode = YES;
        bvh[currentBVH].rangeStart = startRange;
        bvh[currentBVH].rangeEnd = endRange;
        currentBVH++;
    }
    
    self.numBVHMembers = numMembers;
    self.bvhSize = [bvhMain.children count] + 1;
    
//    for (int i = 0; i < bvhSize; i++) {
//        NSLog(@"%d: %f %f %f r:%f s:%d e:%d", i, bvh[i].x, bvh[i].y, bvh[i].z, bvh[i].radius, bvh[i].rangeStart, bvh[i].rangeEnd);
//    }
    
//    for (int i = 0; i < numMembers; i++) {
//        NSLog(@"%d: %d", i, bvhMembers[i]);
//    }

}

- (void)logGridX:(int)x Y:(int)y Z:(int)z {
    NSLog(@"Grid %d %d %d", x, y, z);
    NSLog(@"Num atoms: %d", (int)[self numAtomsForGridX:x Y:y Z:z]);
    for (int i = 0; i < [self numAtomsForGridX:x Y:y Z:z]; i++) {
        float *a;
        a = [self dataForGridX:x Y:y Z:z] + i * NUM_ATOMDATA;
        NSLog(@"Atom %d: %f %f %f VDW: %f", i, *(a + X), *(a + Y), *(a + Z), *(a + VDW));
    }
}

- (NSUInteger)numAtomsForGridX:(int)x Y:(int)y Z:(int)z {
    return gridNumAtoms[x][y][z];
}

- (float *)dataForGridX:(int)x Y:(int)y Z:(int)z {
    return grid[x][y][z];
}


@end
