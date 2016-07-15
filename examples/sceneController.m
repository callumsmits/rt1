//
//  sceneController.m
//  rt1
//
//  Created by Stock Lab on 8/05/2014.
//  Copyright (c) 2014 a. All rights reserved.
//

#import "sceneController.h"
#import "vector_ops.h"
#import "cameraObject.h"
#import "sceneLoader.h"
#import "renderManager.h"
#import "randomNumberGenerator.h"
#import "colourPalette.h"

@interface sceneController () {
    renderManager *r;
    NSMutableArray *holdObjects;
}

@property (nonatomic, strong) renderManager *r;
@property (nonatomic, strong) NSMutableArray *holdObjects;

@end

@implementation sceneController

@synthesize camera, world;
@synthesize r;
@synthesize ambient_light, num_lights;
@synthesize imageSize;
@synthesize holdObjects;

- (LightSourceDef *) light_sources {
    return light_sources;
}

- (void)initScene {
    
    self.holdObjects = [NSMutableArray arrayWithCapacity:0];
    
    imageSize.width = kImageWidth;
    imageSize.height = kImageHeight;
    
    //Camera setup
    Vector viewOrigin, lookAtPoint, upOrientation;
    viewOrigin.x = 0;
    viewOrigin.y = 300;
    viewOrigin.z = -750;
//    viewOrigin.z = -1;
//    viewOrigin.z = -500;
//    viewOrigin.x = 190;
//    viewOrigin.y = 75;
//    viewOrigin.z = -600;
    //C-ring closeup?
//    viewOrigin.x = 10;
//    viewOrigin.y = 7;
//    viewOrigin.z = -110;
    //ATPase from above view
//    viewOrigin.x = 0;
//    viewOrigin.y = -300;
//    viewOrigin.z = 0;
    //Cristae view
//    viewOrigin.x = 0;
//    viewOrigin.y = -100;
//    viewOrigin.z = -1250;
    lookAtPoint.x = lookAtPoint.y = lookAtPoint.z = 0.0;
    lookAtPoint.w = 1.0;
    lookAtPoint.y = 0;
    //Stator closeup
//    lookAtPoint.x = 190;
//    lookAtPoint.y = 5;
//    lookAtPoint.y = -100;
    //C-ring closeup
//    lookAtPoint.x = 10;
//    lookAtPoint.y = 7;
    //ATPase from above
//    lookAtPoint.y = 0;
//    lookAtPoint.w = 1.0;
    //Cristae view
//    lookAtPoint.y = 100;
    
    upOrientation.x = upOrientation.z = upOrientation.w = 0.0;
    upOrientation.y = 1.0;
    //ATPase from above
//    upOrientation.y = 0;
//    upOrientation.z = -1.0;
    

    //ATP
/*    viewOrigin.x = 0;
    viewOrigin.y = -60;
    viewOrigin.z = -300;
    viewOrigin.x = 0;
    viewOrigin.y = -2;
    viewOrigin.z = -250;
    viewOrigin.w = 1.0;
    lookAtPoint.x = lookAtPoint.y = lookAtPoint.z = 0.0;
    lookAtPoint.y = -2;
    lookAtPoint.w = 1.0;
    upOrientation.x = upOrientation.z = upOrientation.w = 0.0;
    upOrientation.y = 1.0;*/
    
    
    self.camera = [[cameraObject alloc] initWithCameraOrigin:viewOrigin lookAt:lookAtPoint upOrientation:upOrientation windowSize:imageSize viewWidth:30 lensLength:40 aperture:0 focalLength:600];
    //C-ring
//    self.camera = [[cameraObject alloc] initWithCameraOrigin:viewOrigin lookAt:lookAtPoint upOrientation:upOrientation windowSize:imageSize viewWidth:30 lensLength:40 aperture:0 focalLength:85];
    //ATPase from above
//    self.camera = [[cameraObject alloc] initWithCameraOrigin:viewOrigin lookAt:lookAtPoint upOrientation:upOrientation windowSize:imageSize viewWidth:30 lensLength:40 aperture:6 focalLength:200];
//ATP
//    self.camera = [[cameraObject alloc] initWithCameraOrigin:viewOrigin lookAt:lookAtPoint upOrientation:upOrientation windowSize:imageSize viewWidth:15 lensLength:40 aperture:0 focalLength:50];
//    self.camera = [[cameraObject alloc] initWithCameraOrigin:viewOrigin lookAt:lookAtPoint upOrientation:upOrientation windowSize:imageSize viewWidth:10 lensLength:40 aperture:0 focalLength:50];
    //Mito View
//    self.camera = [[cameraObject alloc] initWithCameraOrigin:viewOrigin lookAt:lookAtPoint upOrientation:upOrientation windowSize:imageSize viewWidth:30 lensLength:40 aperture:6 focalLength:470];
    //Cristae view
//    self.camera = [[cameraObject alloc] initWithCameraOrigin:viewOrigin lookAt:lookAtPoint upOrientation:upOrientation windowSize:imageSize viewWidth:30 lensLength:40 aperture:2 focalLength:320];

    camera.hazeStartDistanceFromCamera = 1300;
    camera.hazeLength = 300;
    cl_float4 hazeC;
    hazeC.x = hazeC.y = hazeC.z = 0.5; hazeC.w = 0.01;
    camera.hazeColour = hazeC;
    camera.clipPlaneDistanceFromCamera = 210;
    camera.clipPlaneEnabled = NO;
    
    //Lights setup
    num_lights = 8;
    //ATPase light
    /*light_sources[0].position.x = 0;
    light_sources[0].position.y = 0;
    light_sources[0].position.z = -40;
    light_sources[0].position.w = 1;
    light_sources[0].colour.red = 0.2;
    light_sources[0].colour.green = 0.2;
    light_sources[0].colour.blue = 0.2;
    
    light_sources[1].position.x = 0;
    light_sources[1].position.y = 0;
    light_sources[1].position.z = -20;
    light_sources[1].position.w = 1;
    light_sources[1].colour.red = 0.2;
    light_sources[1].colour.green = 0.2;
    light_sources[1].colour.blue = 0.2;
    
    light_sources[2].position.x = 0;
    light_sources[2].position.y = 0;
    light_sources[2].position.z = 0;
    light_sources[2].position.w = 1;
    light_sources[2].colour.red = 0.2;
    light_sources[2].colour.green = 0.2;
    light_sources[2].colour.blue = 0.2;
    
    light_sources[3].position.x = 0;
    light_sources[3].position.y = 0;
    light_sources[3].position.z = 20;
    light_sources[3].position.w = 1;
    light_sources[3].colour.red = 0.2;
    light_sources[3].colour.green = 0.2;
    light_sources[3].colour.blue = 0.2;
    
    light_sources[4].position.x = 0;
    light_sources[4].position.y = 0;
    light_sources[4].position.z = 40;
    light_sources[4].position.w = 1;
    light_sources[4].colour.red = 0.2;
    light_sources[4].colour.green = 0.2;
    light_sources[4].colour.blue = 0.2;*/
    
    light_sources[0].position.x = 500;
    light_sources[0].position.y = -500;
    light_sources[0].position.z = -700;
    light_sources[0].position.w = 1;
    light_sources[0].colour.red = 0.20;
    light_sources[0].colour.green = 0.20;
    light_sources[0].colour.blue = 0.20;

    light_sources[1].position.x = -500;
    light_sources[1].position.y = -500;
    light_sources[1].position.z = -700;
    light_sources[1].position.w = 1;
    light_sources[1].colour.red = 0.20;
    light_sources[1].colour.green = 0.20;
    light_sources[1].colour.blue = 0.20;

    light_sources[2].position.x = 500;
    light_sources[2].position.y = 500;
    light_sources[2].position.z = -700;
    light_sources[2].position.w = 1;
    light_sources[2].colour.red = 0.2;
    light_sources[2].colour.green = 0.2;
    light_sources[2].colour.blue = 0.2;

    light_sources[3].position.x = -500;
    light_sources[3].position.y = 500;
    light_sources[3].position.z = -700;
    light_sources[3].position.w = 1;
    light_sources[3].colour.red = 0.2;
    light_sources[3].colour.green = 0.2;
    light_sources[3].colour.blue = 0.2;

    light_sources[4].position.x = 500;
    light_sources[4].position.y = -500;
    light_sources[4].position.z = 700;
    light_sources[4].position.w = 1;
    light_sources[4].colour.red = 0.20;
    light_sources[4].colour.green = 0.20;
    light_sources[4].colour.blue = 0.20;
    
    light_sources[5].position.x = -500;
    light_sources[5].position.y = -500;
    light_sources[5].position.z = 700;
    light_sources[5].position.w = 1;
    light_sources[5].colour.red = 0.20;
    light_sources[5].colour.green = 0.20;
    light_sources[5].colour.blue = 0.20;
    
    light_sources[6].position.x = 500;
    light_sources[6].position.y = 500;
    light_sources[6].position.z = 700;
    light_sources[6].position.w = 1;
    light_sources[6].colour.red = 0.2;
    light_sources[6].colour.green = 0.2;
    light_sources[6].colour.blue = 0.2;
    
    light_sources[7].position.x = -500;
    light_sources[7].position.y = 500;
    light_sources[7].position.z = 700;
    light_sources[7].position.w = 1;
    light_sources[7].colour.red = 0.2;
    light_sources[7].colour.green = 0.2;
    light_sources[7].colour.blue = 0.2;

    
//    light_sources[4].position.x = 300;
//    light_sources[4].position.y = 300;
//    light_sources[4].position.z = 300;
//    light_sources[4].position.w = 1;
//    light_sources[4].colour.red = 0.4;
//    light_sources[4].colour.green = 0.4;
//    light_sources[4].colour.blue = 0.4;
    
//    light_sources[5].position.x = -300;
//    light_sources[5].position.y = 300;
//    light_sources[5].position.z = 300;
//    light_sources[5].position.w = 1;
//    light_sources[5].colour.red = 0.4;
//    light_sources[5].colour.green = 0.4;
//    light_sources[5].colour.blue = 0.4;
    
//    light_sources[6].position.x = 300;
//    light_sources[6].position.y = -300;
//    light_sources[6].position.z = 300;
//    light_sources[6].position.w = 1;
//    light_sources[6].colour.red = 0.4;
//    light_sources[6].colour.green = 0.4;
//    light_sources[6].colour.blue = 0.4;
    
//    light_sources[7].position.x = -300;
//    light_sources[7].position.y = -300;
//    light_sources[7].position.z = 300;
//    light_sources[7].position.w = 1;
//    light_sources[7].colour.red = 0.4;
//    light_sources[7].colour.green = 0.4;
//    light_sources[7].colour.blue = 0.4;

    ambient_light.red = 0.1;
    ambient_light.green = 0.1;
    ambient_light.blue = 0.1;
//    ambient_light.red = 0;
//    ambient_light.green = 0;
//    ambient_light.blue = 0;

    //Scene setup
    initColours();

    NSLog(@"Loading data...");
    self.world = [[[sceneLoader alloc] init] loadScene];
    NSLog(@"Finished - %d atoms, %d scene lights", world.numModelData, world.numIntrinsicLights);
    
    //Renderer setup
//    self.r = [[renderManager alloc] initWithCamera:camera imageSize:imageSize];
//    [r loadLightDataFromArray:light_sources withAmbient:ambient_light numLights:num_lights];
    
//    [world applyTransformation];
//    [world loadData];
//    [world logModelData];
//    [r loadModelDataFromWorld:world];
//    [camera calculateCameraAnimationWithFrame:0];
//    [r renderImage];
//    [r saveImage];
}

- (void)scheduleProtonTranslocationForModel:(modelObject *)model translocationDuration:(int)protonTranslocationDuration currentFrame:(int) f {
    
    modelObject *protonPool = [world getChildWithName:@"protonPool"];
    modelObject *motB = [world getChildWithName:@"motB"];
    modelObject *targetATPase = [model getChildWithName:@"childATPase"];
    Vector ep, B, C, D, AB, BC, CD;
    //Entry point for the first half channel - atpaseLeft coordinates
    //        ep.x = 27; ep.y = -11; ep.z = 10; ep.w = 1;
/*    ep.x = -24.002; ep.y = -14.204; ep.z = 0.058; ep.w = 1;
    Vector epw = [model transformCoordinate:ep inSystemOfChild:atpase];
    ep = [targetATPase transformCoordinate:ep inSystemOfChild:atpase];
    B.x = -24.733; B.y = -13.493; B.z = 35.581; B.w = 1;
    B = [targetATPase transformCoordinate:B inSystemOfChild:atpase];
    C.x = -17.9; C.y = -24.541; C.z = 35.45; C.w = 1;
    C = [targetATPase transformCoordinate:C inSystemOfChild:atpase];
    D.x = -16.633; D.y = -25.747; D.z = 67.089; D.w = 1;
    D = [targetATPase transformCoordinate:D inSystemOfChild:atpase];
*/
 
    ep.x = -0; ep.y = -40; ep.z = 0.0; ep.w = 1;
    Vector epw = [model transformCoordinate:ep inSystemOfChild:motB];
    
    B.x = 0; B.y = 30; B.z = 0; B.w = 1;
//    C.x = 0; C.y = 20; C.z = 0; C.w = 1;
    
    AB = vector_subtract(B, ep);
//    BC = vector_subtract(C, B);
    
    //Get proton
    modelObject *proton = [protonPool releaseFromPoolModelClosestToPoint:epw];
    [proton changeIntrinsicColourTo:protonGlowColour withMaxDistance:40.0 mode:REAL_BROAD_SOURCE];
    
    Vector translationMomentum, rotationMomentum;
    translationMomentum = [proton getDiffusionTranslationVectorAndEndDiffusionWithRotationChangeVector:&rotationMomentum];
    
    //Shift into coordinate system of model
    modelObject *protonParent = [model addAndTransformIntoCoordSystemChildModel:proton];
    
    [camera animateFollowModelObject:protonParent parent:model world:world distanceFromCentreOfMass:-20.0];
    
    //Now calculate curves based on this new position
    beizerCurve *transitPath = [[beizerCurve alloc] init];
    Vector start, i2, i1, end;
    start.x = start.y = start.z = 0; start.w = 1.0;
    end = vector_subtract(ep, [proton currentTranslation]);
    i2 = vector_lerp(start, end, 0.6);
    
    [transitPath addCurveWithStartPoint:start momentumVector:translationMomentum i2:i2 end:end];
    i1 = i2 = start = end;
    end = vector_add(end, AB);
    i1 = vector_lerp(start, end, 0.3);
    i2 = vector_lerp(start, end, 0.6);
    [transitPath addCurveWithI1:i1 i2:i2 end:end];
    //Have the proton jump to the second channel
//    end = vector_add(end, BC);
//    i1 = i2 = start = end;
//    end = vector_add(end, CD);
//    i1 = vector_lerp(start, end, 0.3);
//    i2 = vector_lerp(start, end, 0.6);
//    [transitPath addCurveWithStartPoint:start i1:i1 i2:i2 end:end];
    i2 = end;
    end.y += ([[randomNumberGenerator sharedInstance] getRandomUShort] / (float)UINT16_MAX) * 30 + 10;
    end.x += ([[randomNumberGenerator sharedInstance] getRandomShort] / (float)INT16_MAX) * 30;
    end.z += ([[randomNumberGenerator sharedInstance] getRandomUShort] / (float)UINT16_MAX) * 30 + 20;
    i2 = vector_lerp(i2, end, 0.5);
    [transitPath addCurveWithSymmetricalJoinWithI2:i2 end:end];
    [proton animateTranslationAlongCurve:transitPath duration:protonTranslocationDuration];
    
//    RGBColour g; g.red = 0; g.blue = 0; g.green = 1.0;
//    [proton changeIntrinsicColourTo:g withMaxDistance:10 mode:REAL_POINT_SOURCE];
    //Store info for later
    
    NSDictionary *protonInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"proton", @"type",
                                proton, @"object",
                                transitPath, @"curve",
                                model, @"parent",
                                [NSNumber numberWithInt:f + protonTranslocationDuration], @"destFrame", nil];
    [holdObjects addObject:protonInfo];
    
}

#define PHASE_1 0
#define PHASE_2 1
#define PHASE_3 2

- (void)scheduleADPandPO4TranslocationForModel:(modelObject *)model currentCatalysisPhase:(int)currentCatalysisPhase currentFrame:(int) f {
    Vector ep, ex, ei2;
    modelObject *subC = [world getChildWithName:@"subC"];

    int ADPEntryPointState = 0, PO4EntryPointState = 0;
    int ADPRandomOffset = 0, PO4RandomOffset = 0;
    switch (currentCatalysisPhase) {
        case PHASE_1:
            //Site 1
            //Entry point for this PHASE - atpase coordinates
            ep.x = -23.6; ep.y = 62.9; ep.z = 132.1; ep.w = 1;
            //Exchange point - atpase coordinates
            ex.x = -27.8; ex.y = 25.7; ex.z = 132.1; ex.w = 1;
            //i2 point for entry - atpase coordinates
            ei2.x = -50; ei2.y = 70; ei2.z = 40; ei2.w = 1;
            ADPEntryPointState = 60;//60 + (([[randomNumberGenerator sharedInstance] getRandomUShort] / (float)UINT16_MAX) * 10.0);
            PO4EntryPointState = 60;//75 + (([[randomNumberGenerator sharedInstance] getRandomUShort] / (float)UINT16_MAX) * 20.0);
            break;
        case PHASE_2:
            //Site 2
            ep.x = -37.1; ep.y = -52.7; ep.z = 132.1; ep.w = 1;
            ex.x = -8.4; ex.y = -37.0; ex.z = 132.1; ex.w = 1;
            ei2.x = -65; ei2.y = -40; ei2.z = 40; ei2.w = 1;
            ADPEntryPointState = 120;// + (([[randomNumberGenerator sharedInstance] getRandomUShort] / (float)UINT16_MAX) * 10.0);
            PO4EntryPointState = 120;//135 + (([[randomNumberGenerator sharedInstance] getRandomUShort] / (float)UINT16_MAX) * 20.0);
            
            break;
        case PHASE_3:
            //Site 3
            ep.x = 58.2; ep.y = 0.0; ep.z = 132.1; ep.w = 1;
            ex.x = 36.2; ex.y = 11.3; ex.z = 132.1; ex.w = 1;
            ei2.x = 70; ei2.y = 12; ei2.z = 40; ei2.w = 1;
            ADPEntryPointState = 0;// + (([[randomNumberGenerator sharedInstance] getRandomUShort] / (float)UINT16_MAX) * 10.0);
            PO4EntryPointState = 0;//15 + (([[randomNumberGenerator sharedInstance] getRandomUShort] / (float)UINT16_MAX) * 20.0);
            
            break;
        default:
            break;
    }
    ADPRandomOffset = 10 + (([[randomNumberGenerator sharedInstance] getRandomUShort] / (float)UINT16_MAX) * 10.0);
    PO4RandomOffset = 10 + (([[randomNumberGenerator sharedInstance] getRandomUShort] / (float)UINT16_MAX) * 10.0);

    int ADPToEntryPointDuration = [subC calculateFramesToArriveAtState:ADPEntryPointState + ADPRandomOffset];
    int PO4ToEntryPointDuration = [subC calculateFramesToArriveAtState:PO4EntryPointState + PO4RandomOffset];
    
    modelObject *ADPPool = [world getChildWithName:@"matrixADPPool"];
    modelObject *PO4Pool = [world getChildWithName:@"matrixPO4Pool"];
    modelObject *atpase = [world getChildWithName:@"atpase"];
    modelObject *targetATPase = [model getChildWithName:@"childATPase"];
//    modelObject *targetATPase = model;
    
    //Transform necessary coordinates into appropriate system
    Vector epw = [model transformCoordinate:ep inSystemOfChild:atpase];
    ep = [targetATPase transformCoordinate:ep inSystemOfChild:atpase];
    ex = [targetATPase transformCoordinate:ex inSystemOfChild:atpase];
    ei2 = [targetATPase transformCoordinate:ei2 inSystemOfChild:atpase];
    Vector po4Extra; po4Extra.x = 0; po4Extra.y = 0; po4Extra.z = 20; po4Extra.w = 0;
    po4Extra = [targetATPase transformCoordinate:po4Extra inSystemOfChild:atpase];
    
    //ADP
    modelObject *adp = [ADPPool releaseFromPoolModelClosestToPoint:epw];
//    RGBColour g;
//    g.red = 0.0; g.blue = 0.0; g.green = 1.0;
//    [adp changeDiffuseColourTo:g];
    Vector translationMomentum, rotationMomentum;
    Vector translation = [adp currentTranslation];
    //    end = vector_subtract(ep, translation);
    Vector rotation = [adp getDiffusionRotationVector];
    translationMomentum = [adp getDiffusionTranslationVectorAndEndDiffusionWithRotationChangeVector:&rotationMomentum];
    [adp resetTransformation];
    [adp rotateAroundX:rotation.x Y:rotation.y Z:rotation.z];
    //No mode random diffusion - directed rotation to correct alignment for superposition
//    [adp enableDiffusionRotationWithMaxSpeed:0.1 rotChangeSize:0.01 initialVector:rotationMomentum];
    modelObject *adpRotating = [[modelObject alloc] init];
    [adpRotating addChildModel:adp];
    [adpRotating setName:@"rotationADP" forChild:adp];
    [adpRotating translateToX:translation.x Y:translation.y Z:translation.z];
    [adpRotating setClipForModelTo:NO];
    [model addAndTransformIntoCoordSystemChildModel:adpRotating];
    translationMomentum = [model transformWithInverseTransform:translationMomentum];
    
    //Now use target molecules for alignment...
    //First the hold state of ADP
    NSString *ADPHoldTargetString = [NSString stringWithFormat:@"%d_ADPh", currentCatalysisPhase];
    modelObject *targetHoldADP = [world getChildWithName:ADPHoldTargetString];
    
    modelObject *transformedTargetHoldADP = [[modelObject alloc] init];
    [transformedTargetHoldADP addChildModel:targetHoldADP];
    [targetATPase transformIntoCurrentSystemModel:transformedTargetHoldADP inSystemOfChild:atpase];
    
    Vector axis;
    float angle;
    Vector holdTrans;
    [adpRotating targetMolecule:transformedTargetHoldADP requiredRotationAxis:&axis requiredRotationAngle:&angle requiredTranslationVector:&holdTrans];

    //Then the entry state if the ADP arrives exactly at the start of the cycle
    NSString *ADPTargetString = [NSString stringWithFormat:@"%d_ADPe", currentCatalysisPhase];
    modelObject *targetADP = [world getChildWithName:ADPTargetString];

    modelObject *transformedTargetADP = [[modelObject alloc] init];
    [transformedTargetADP addChildModel:targetADP];
    [targetATPase transformIntoCurrentSystemModel:transformedTargetADP inSystemOfChild:atpase];
    
    Vector trans;
    [adpRotating targetMolecule:transformedTargetADP requiredRotationAxis:&axis requiredRotationAngle:&angle requiredTranslationVector:&trans];
    
//    [adp animateRotationAroundAxis:axis byAngle:angle duration:ADPToEntryPointDuration];
    [adp animateRotationAroundAxis:axis byAngle:angle durationModel:subC durationTargetState:ADPEntryPointState + ADPRandomOffset];
    
    //But it will probably arrive later --> get the translation to the next state and interpolate
    int nextCatalysisPhase = (currentCatalysisPhase + 1) % 3;
    NSString *ADPBTargetString = [NSString stringWithFormat:@"%d_ADPb", nextCatalysisPhase];
    modelObject *targetADPb = [world getChildWithName:ADPBTargetString];
    
    modelObject *transformedTargetADPb = [[modelObject alloc] init];
    [transformedTargetADPb addChildModel:targetADPb];
    [targetATPase transformIntoCurrentSystemModel:transformedTargetADPb inSystemOfChild:atpase];
    
    Vector transb;
    [adpRotating targetMolecule:transformedTargetADPb requiredRotationAxis:&axis requiredRotationAngle:&angle requiredTranslationVector:&transb];
    
    float fraction = 1.0 - (float)ADPRandomOffset / 60.0;
    Vector finalTrans = vector_lerp(trans, transb, fraction);
    
    Vector atpaseSphere = [targetATPase positionAndRadiusOfEncompassingSphere];
    float atpaseSphereRad = atpaseSphere.w;
    atpaseSphere.w = 1.0;
    
    Vector epOnSphere = vector_scale(unit_vector(vector_subtract(ep, atpaseSphere)), atpaseSphereRad);
    Vector startPosOnSphere = vector_scale(unit_vector(vector_subtract([adpRotating currentTranslation], atpaseSphere)), atpaseSphereRad);
    Vector sphereTransitDirection = vector_lerp(startPosOnSphere, epOnSphere, 0.5);
    if (vector_size(sphereTransitDirection) == 0) {
        Vector one; one.x = 1.0; one.y = 1.0; one.z = 1.0; one.w = 0.0;
        epOnSphere = vector_add(epOnSphere, one);
        sphereTransitDirection = vector_lerp(startPosOnSphere, epOnSphere, 0.5);
    }
    sphereTransitDirection = vector_scale(unit_vector(sphereTransitDirection), atpaseSphereRad);
    Vector sphereTransitPoint = vector_add(atpaseSphere, sphereTransitDirection);
    epOnSphere = vector_add(atpaseSphere, epOnSphere);
    
    beizerCurve *transitPathADP = [[beizerCurve alloc] init];
    Vector start, i2, i1, end;
    
    //Construct curve backwards - first from exchange to entry point
    start = holdTrans;
    end = finalTrans;
    i2 = vector_lerp(start, end, 0.6);
    i1 = vector_lerp(start, end, 0.3);
    [transitPathADP addCurveWithStartPoint:start i1:i1 i2:i2 end:end];
    
    
    start = vector_subtract(ep, [adpRotating currentTranslation]);
//    end = vector_subtract(ex, [adpRotating currentTranslation]);
    end = holdTrans;
//    i2 = vector_lerp(start, end, 0.6);
    i1 = vector_lerp(start, end, 0.3);
//    [transitPathADP addCurveWithStartPoint:start i1:i1 i2:i2 end:end];
    [transitPathADP addCurveWithSymmetricalJoinToBeginningWithStartPoint:start i1:i1];
    
    //From entry point to point on sphere
    start = vector_subtract(sphereTransitPoint, [adpRotating currentTranslation]);
    i1 = vector_subtract(epOnSphere, [adpRotating currentTranslation]);
    [transitPathADP addCurveWithSymmetricalJoinToBeginningWithStartPoint:start i1:i1];

    //From start to point on sphere
    start.x = start.y = start.z = 0; start.w = 1.0;
    translationMomentum = vector_scale(translationMomentum, 2);
    [transitPathADP addCurveWithSymmetricalJoinToBeginningWithStartPoint:start momentumVector:translationMomentum];
    
//    [transitPathADP addCurveWithStartPoint:start i1:i1 i2:i2 end:end];
//    start = vector_subtract(ep, [adpRotating currentTranslation]);
    //New model objects need the previous frame set
    if (f > 0) {
        [adpRotating setPreviousFrame:f - 1];
    }
//    [adpRotating animateTranslationAlongCurve:transitPathADP duration:ADPToEntryPointDuration];
    [adpRotating animateTranslationAlongCurve:transitPathADP durationModel:subC durationTargetState:ADPEntryPointState + ADPRandomOffset];
    
//    end = vector_subtract(ex, [adpRotating currentTranslation]);
//    [adpRotating animateLinearTranslationTo:end duration:ADPToEntryPointDuration];
    NSDictionary *adpInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"adpe", @"type",
                             adpRotating, @"object",
                             model, @"parent",
                             subC, @"durationModel",
                             [NSNumber numberWithInt:ADPEntryPointState + ADPRandomOffset], @"durationState",
                             [NSNumber numberWithBool:([subC getCurrentState] > ADPEntryPointState + ADPRandomOffset)], @"durationWrapAroundRequired",
                             [NSNumber numberWithInt:f], @"durationStartFrame",
                             [NSNumber numberWithInt:f + ADPToEntryPointDuration + 1], @"destFrame", nil];
    [holdObjects addObject:adpInfo];
    
    //PO4
    modelObject *po4 = [PO4Pool releaseFromPoolModelClosestToPoint:epw];
//    g.blue = 1.0;
//    [po4 changeDiffuseColourTo:g];

    translation = [po4 currentTranslation];
    rotation = [po4 getDiffusionRotationVector];
    translationMomentum = [po4 getDiffusionTranslationVectorAndEndDiffusionWithRotationChangeVector:&rotationMomentum];
    [po4 resetTransformation];
    [po4 rotateAroundX:rotation.x Y:rotation.y Z:rotation.z];
//    [po4 enableDiffusionRotationWithMaxSpeed:0.1 rotChangeSize:0.01 initialVector:rotationMomentum];
    modelObject *po4Rotating = [[modelObject alloc] init];
    [po4Rotating addChildModel:po4];
    [po4Rotating setName:@"po4" forChild:po4];
    [po4Rotating translateToX:translation.x Y:translation.y Z:translation.z];
    [po4Rotating setClipForModelTo:NO];
    [model addAndTransformIntoCoordSystemChildModel:po4Rotating];
    translationMomentum = [model transformWithInverseTransform:translationMomentum];
    
    //Now use target molecules for alignment...
    NSString *PO4HoldTargetString = [NSString stringWithFormat:@"%d_PO4h", currentCatalysisPhase];
    modelObject *targetHoldPO4 = [world getChildWithName:PO4HoldTargetString];
    
    modelObject *transformedTargetHoldPO4 = [[modelObject alloc] init];
    [transformedTargetHoldPO4 addChildModel:targetHoldPO4];
    [targetATPase transformIntoCurrentSystemModel:transformedTargetHoldPO4 inSystemOfChild:atpase];
    
    [po4Rotating targetMolecule:transformedTargetHoldPO4 requiredRotationAxis:&axis requiredRotationAngle:&angle requiredTranslationVector:&holdTrans];
    
    NSString *PO4TargetString = [NSString stringWithFormat:@"%d_PO4e", currentCatalysisPhase];
    modelObject *targetPO4 = [world getChildWithName:PO4TargetString];
    
    modelObject *transformedTargetPO4 = [[modelObject alloc] init];
    [transformedTargetPO4 addChildModel:targetPO4];
    [targetATPase transformIntoCurrentSystemModel:transformedTargetPO4 inSystemOfChild:atpase];
    
    [po4Rotating targetMolecule:transformedTargetPO4 requiredRotationAxis:&axis requiredRotationAngle:&angle requiredTranslationVector:&trans];
    
//    [po4 animateRotationAroundAxis:axis byAngle:angle duration:PO4ToEntryPointDuration];
    [po4 animateRotationAroundAxis:axis byAngle:angle durationModel:subC durationTargetState:PO4EntryPointState + PO4RandomOffset];

    NSString *PO4BTargetString = [NSString stringWithFormat:@"%d_PO4b", nextCatalysisPhase];
    modelObject *targetPO4b = [world getChildWithName:PO4BTargetString];
    
    modelObject *transformedTargetPO4b = [[modelObject alloc] init];
    [transformedTargetPO4b addChildModel:targetPO4b];
    [targetATPase transformIntoCurrentSystemModel:transformedTargetPO4b inSystemOfChild:atpase];
    
    [po4Rotating targetMolecule:transformedTargetPO4b requiredRotationAxis:&axis requiredRotationAngle:&angle requiredTranslationVector:&transb];
    
    fraction = 1.0 - (float)PO4RandomOffset / 60.0;
    finalTrans = vector_lerp(trans, transb, fraction);

    
    epOnSphere = vector_scale(unit_vector(vector_subtract(ep, atpaseSphere)), atpaseSphereRad);
    startPosOnSphere = vector_scale(unit_vector(vector_subtract([po4Rotating currentTranslation], atpaseSphere)), atpaseSphereRad);
    sphereTransitDirection = vector_lerp(startPosOnSphere, epOnSphere, 0.5);
    if (vector_size(sphereTransitDirection) == 0) {
        Vector one; one.x = 1.0; one.y = 1.0; one.z = 1.0; one.w = 0.0;
        epOnSphere = vector_add(epOnSphere, one);
        sphereTransitDirection = vector_lerp(startPosOnSphere, epOnSphere, 0.5);
    }
    sphereTransitDirection = vector_scale(unit_vector(sphereTransitDirection), atpaseSphereRad);
    sphereTransitPoint = vector_add(atpaseSphere, sphereTransitDirection);
    epOnSphere = vector_add(atpaseSphere, epOnSphere);

    
    beizerCurve *transitPathPO4 = [[beizerCurve alloc] init];
    start = holdTrans;
    //    end = vector_subtract(ex, [po4Rotating currentTranslation]);
    end = finalTrans;
    i2 = vector_lerp(start, end, 0.6);
    i1 = vector_lerp(start, end, 0.3);
    [transitPathPO4 addCurveWithStartPoint:start i1:i1 i2:i2 end:end];
    
    Vector po4ep = vector_add(ep, po4Extra);
    start = vector_subtract(po4ep, [po4Rotating currentTranslation]);
//    end = vector_subtract(ex, [po4Rotating currentTranslation]);
    end = holdTrans;
//    i2 = vector_lerp(start, end, 0.6);
    i1 = vector_lerp(start, end, 0.3);
//    [transitPathPO4 addCurveWithStartPoint:start i1:i1 i2:i2 end:end];
    [transitPathPO4 addCurveWithSymmetricalJoinToBeginningWithStartPoint:start i1:i1];

    start = vector_subtract(sphereTransitPoint, [po4Rotating currentTranslation]);
    i1 = vector_subtract(epOnSphere, [po4Rotating currentTranslation]);
    [transitPathPO4 addCurveWithSymmetricalJoinToBeginningWithStartPoint:start i1:i1];
    
    start.x = start.y = start.z = 0; start.w = 1.0;
    translationMomentum = vector_scale(translationMomentum, 2);
    [transitPathPO4 addCurveWithSymmetricalJoinToBeginningWithStartPoint:start momentumVector:translationMomentum];
    
    //    [transitPathADP addCurveWithStartPoint:start i1:i1 i2:i2 end:end];
    //    start = vector_subtract(ep, [adpRotating currentTranslation]);

    if (f > 0) {
        [po4Rotating setPreviousFrame:f - 1];
    }
//    [po4Rotating animateTranslationAlongCurve:transitPathPO4 duration:PO4ToEntryPointDuration];
    [po4Rotating animateTranslationAlongCurve:transitPathPO4 durationModel:subC durationTargetState:PO4EntryPointState + PO4RandomOffset];
    
    NSDictionary *po4Info = [NSDictionary dictionaryWithObjectsAndKeys:@"po4e", @"type",
                             po4Rotating, @"object",
                             model, @"parent",
                             adpRotating, @"linkedADP",
                             subC, @"durationModel",
                             [NSNumber numberWithInt:PO4EntryPointState + PO4RandomOffset], @"durationState",
                             [NSNumber numberWithBool:([subC getCurrentState] > PO4EntryPointState + PO4RandomOffset)], @"durationWrapAroundRequired",
                             [NSNumber numberWithInt:f], @"durationStartFrame",
                             [NSNumber numberWithInt:f + PO4ToEntryPointDuration + 1], @"destFrame", nil];
    [holdObjects addObject:po4Info];

}

- (void)cRingZoomSceneActionForFrame:(int)f {
    int startFrame = 1560;
    //    int startFrame = 2598;
    
    if (f == 0) {
        modelObject *protonPool = [world getChildWithName:@"protonPool"];
        Vector destination;
        destination.x = 0; destination.y = 200; destination.z = 0; destination.z = 0;
        [protonPool animateLinearTranslationTo:destination duration:0];
    }
    
    if (f == 0) {
    
        Vector destination, i1, i2;
        i1.x = -3; i1.y = -60; i1.z = -350;
        i1.w = 1;
        i2.x = 3; i2.y = -60; i2.z = -350;
        i2.w = 1;
        destination.x = 10; destination.y = -60; destination.z = -350; destination.w = 1;
        [camera animateViewOriginTranslationTo:destination intermediate1:i1 intermediate2:i2 duration:3180-startFrame];
        
    }
    
    //Shift protons into place
    if (f == 2206 - startFrame) {
        modelObject *protonPool = [world getChildWithName:@"protonPool"];
        Vector destination;
        destination.x = 0; destination.y = -200; destination.z = 0; destination.z = 0;
        [protonPool animateLinearTranslationTo:destination duration:100];
    }
    
    //Start the ATPase rotating
    if (f == 2462 - startFrame) {
        Vector s, i1, i2, e;
        s.x = s.y = s.z = s.w = 0;
        i1.x = i1.y = i1.z = i1.w = 0;
        i2.x = i2.y = i2.z = i2.w = 0;
        e.x = e.y = e.z = e.w = 0;
        s.x = 0;
        i1.x = 0;
        i2.x = 0.5;
        e.x = 0.5;
        beizerCurve *rate = [[beizerCurve alloc] init];
        [rate addCurveWithStartPoint:s i1:i1 i2:i2 end:e];
        modelObject *atpase = [world getChildWithName:@"atpase"];
        modelObject *rotor = [world getChildWithName:@"rotor"];
        [atpase animateModelStateRateOfChangeWithCurve:rate duration:100];
        [rotor animateModelStateRateOfChangeWithCurve:rate duration:100];
    }

    //Zoom in on the C-ring
    if (f == 3180 - startFrame) {
        
        Vector destination, i1, i2;
        i1.x = 0; i1.y = 10; i1.z = -300;
        i1.w = 1;
        i2.x = 20; i2.y = 15; i2.z = -150;
        i2.w = 1;
        destination.x = 10; destination.y = 7; destination.z = -110; destination.w = 1;
        [camera animateViewOriginTranslationTo:destination intermediate1:i1 intermediate2:i2 duration:75];
        destination.z = 0; destination.x = 10; destination.y = 7; destination.w = 1;
        [camera animateViewLookAtTranslationTo:destination duration:75];
        [camera animateApertureTo:2.0 duration:75];
        [camera animateFocalLenghTo:95 duration:75];
    }
}

- (void)f1ZoomAndClipActionForFrame:(int)f catalysisCurrentState:(float)catalysisCurrentState catalysisPhase:(int)catalysisCurrentPhase {
    int startFrame = 3900;
    
    //Start the ATPase rotating
    if (f == 3900 - startFrame) {
        Vector s, i1, i2, e;
        s.x = s.y = s.z = s.w = 0;
        i1.x = i1.y = i1.z = i1.w = 0;
        i2.x = i2.y = i2.z = i2.w = 0;
        e.x = e.y = e.z = e.w = 0;
        s.x = 0.5;
        i1.x = 0.5;
        i2.x = 0.5;
        e.x = 0.5;
        beizerCurve *rate = [[beizerCurve alloc] init];
        [rate addCurveWithStartPoint:s i1:i1 i2:i2 end:e];
        
        modelObject *atpase = [world getChildWithName:@"atpase"];
        modelObject *rotor = [world getChildWithName:@"rotor"];
        [atpase animateModelStateRateOfChangeWithCurve:rate duration:10];
        [rotor animateModelStateRateOfChangeWithCurve:rate duration:10];
        
        [atpase setClipForModelTo:YES];
//        modelObject *atpaseLeft = [world getChildWithName:@"atpaseLeft"];
//        [atpaseLeft setClipForModelTo:YES];
}

    if (f == 4100 - startFrame) {
        //        modelObject *atpaseRight = [world getChildWithName:@"atpaseRight"];
        //        [atpaseRight animateCurvePositionTo:0.68 duration:100];
        Vector destination, i1, i2;
        i1.x = 0; i1.y = 0; i1.z = -350;
        i1.w = 1;
        i2.x = 0; i2.y = -300; i2.z = 0;
        i2.w = 1;
        destination.z = 0; destination.x = 0; destination.y = -300; destination.w = 1;
        [camera animateViewOriginTranslationTo:destination intermediate1:i1 intermediate2:i2 duration:100];
        destination.x = 0; destination.y = -150; destination.z = 0; destination.w = 1;
        [camera animateViewLookAtTranslationTo:destination duration:50];
        
        Vector upOrientation;
        upOrientation.x = upOrientation.z = upOrientation.w = 0.0;
        upOrientation.y = 1.0;
        //ATPase from above
        upOrientation.y = 0;
        upOrientation.z = -1.0;
        
        [camera animateUpOrientationTo:upOrientation duration:100];
        [camera animateFocalLenghTo:130 duration:100];
    }
    
    if (f == 4200 - startFrame) {
        camera.clipPlaneEnabled = YES;
        camera.clipPlaneDistanceFromCamera = 120;
        [camera animateClipPlaneTo:210 duration:100];
        [camera animateFocalLenghTo:210 duration:100];
    }
    
    if (f == 4145 - startFrame) {
        //        modelObject *popc = [world getChildWithName:@"popc"];
        modelObject *membrane = [world getChildWithName:@"membrane"];
        modelObject *popCCurve = [world getChildWithName:@"popCCurve"];
        //        modelObject *popCCurveLower = [world getChildWithName:@"popCCurveLower"];
        
        modelObject *membranePlane = [[modelObject alloc] init];
        [membranePlane addGridOfModel:popCCurve xNumMembers:1 xSpacing:0 zNumMembers:50 zSpacing:6];
        //        [membranePlane addGridOfModel:popCCurveLower xNumMembers:1 xSpacing:0 zNumMembers:3 zSpacing:6];
        //    [membranePlane addChildModel:popCHeadGrid];
        [membranePlane translateToX:0 Y:0 Z:-150];
        
        modelObject *membraneNew = [[modelObject alloc] init];
        //    [membrane addChildModel:popCCurveLeft];
        //    [membrane addChildModel:popCCurveLowerLeft];
        //    [membrane addGridOfModel:popCCurveLeft xNumMembers:1 xSpacing:0 zNumMembers:4 zSpacing:6.0];
        //    [membrane addGridOfModel:popCCurveLowerLeft xNumMembers:1 xSpacing:0 zNumMembers:4 zSpacing:6.0];
        //    [membrane addGridOfModel:popCCurveRight xNumMembers:1 xSpacing:0 zNumMembers:4 zSpacing:6.0];
        //    [membrane addGridOfModel:popCCurveLowerRight xNumMembers:1 xSpacing:0 zNumMembers:4 zSpacing:6.0];
        [membraneNew addChildModel:membranePlane];
        [membraneNew enableWobbleWithMaxRadius:0.5 changeVectorSize:0.3];
        [membraneNew setPreviousFrame:f-1];
        
        [world deleteChildModel:membrane];
        [world addChildModel:membraneNew];
//        modelObject *protonPool = [world getChildWithName:@"protonPool"];
//        [world deleteChildModel:protonPool];
    }

    if (f == (5018 - 46) - startFrame) {
        Vector s, i1, i2, e;
        s.x = s.y = s.z = s.w = 0;
        i1.x = i1.y = i1.z = i1.w = 0;
        i2.x = i2.y = i2.z = i2.w = 0;
        e.x = e.y = e.z = e.w = 0;
        s.x = 0.5;
        i1.x = 0.5;
        i2.x = 0.5;
        e.x = 0.5;
        beizerCurve *rate = [[beizerCurve alloc] init];
        [rate addCurveWithStartPoint:s i1:i1 i2:i2 end:e];
        [rate addCurveWithI1:i1 i2:i2 end:e];
        i2.x = 0.001;
        e.x = 0.001;
        [rate addCurveWithI1:i1 i2:i2 end:e];
        float stateDifference = 60.0 - catalysisCurrentState;
        if (stateDifference < 20) {
            stateDifference += 60;
        }
        float duration = [rate durationForXIntegralResult:stateDifference];
        
        modelObject *atpase = [world getChildWithName:@"atpase"];
        modelObject *rotor = [world getChildWithName:@"rotor"];
        [atpase animateModelStateRateOfChangeWithCurve:rate duration:duration];
        [rotor animateModelStateRateOfChangeWithCurve:rate duration:duration];
        
    }
    
    if (f == 5110 - startFrame) {
        Vector s, i1, i2, e;
        s.x = s.y = s.z = s.w = 0;
        i1.x = i1.y = i1.z = i1.w = 0;
        i2.x = i2.y = i2.z = i2.w = 0;
        e.x = e.y = e.z = e.w = 0;
        s.x = 0.001;
        i1.x = 0.001;
        i2.x = 0.5;
        e.x = 0.5;
        beizerCurve *rate = [[beizerCurve alloc] init];
        [rate addCurveWithStartPoint:s i1:i1 i2:i2 end:e];
        i1.x = 0.5;
        [rate addCurveWithI1:i1 i2:i2 end:e];
        i2.x = 0.001;
        e.x = 0.001;
        [rate addCurveWithI1:i1 i2:i2 end:e];
        float stateDifference = 60.0 - catalysisCurrentState;
        if (stateDifference < 20) {
            stateDifference += 60;
        }
        float duration = [rate durationForXIntegralResult:stateDifference];
        
        modelObject *atpase = [world getChildWithName:@"atpase"];
        modelObject *rotor = [world getChildWithName:@"rotor"];
        [atpase animateModelStateRateOfChangeWithCurve:rate duration:duration];
        [rotor animateModelStateRateOfChangeWithCurve:rate duration:duration];
        
    }
    
    if (f == 5295 - startFrame) {
        Vector s, i1, i2, e;
        s.x = s.y = s.z = s.w = 0;
        i1.x = i1.y = i1.z = i1.w = 0;
        i2.x = i2.y = i2.z = i2.w = 0;
        e.x = e.y = e.z = e.w = 0;
        s.x = 0.001;
        i1.x = 0.001;
        i2.x = 0.5;
        e.x = 0.5;
        beizerCurve *rate = [[beizerCurve alloc] init];
        [rate addCurveWithStartPoint:s i1:i1 i2:i2 end:e];
        i1.x = 0.5;
        [rate addCurveWithI1:i1 i2:i2 end:e];
        i2.x = 0.001;
        e.x = 0.001;
        [rate addCurveWithI1:i1 i2:i2 end:e];
        float stateDifference = 60.0 - catalysisCurrentState;
        if (stateDifference < 20) {
            stateDifference += 60;
        }
        float duration = [rate durationForXIntegralResult:stateDifference];
        
        modelObject *atpase = [world getChildWithName:@"atpase"];
        modelObject *rotor = [world getChildWithName:@"rotor"];
        [atpase animateModelStateRateOfChangeWithCurve:rate duration:duration];
        [rotor animateModelStateRateOfChangeWithCurve:rate duration:duration];
    }
    
    if (f == 5528 - startFrame) {
        Vector s, i1, i2, e;
        s.x = s.y = s.z = s.w = 0;
        i1.x = i1.y = i1.z = i1.w = 0;
        i2.x = i2.y = i2.z = i2.w = 0;
        e.x = e.y = e.z = e.w = 0;
        s.x = 0.001;
        i1.x = 0.001;
        i2.x = 0.5;
        e.x = 0.5;
        beizerCurve *rate = [[beizerCurve alloc] init];
        [rate addCurveWithStartPoint:s i1:i1 i2:i2 end:e];
        i1.x = 0.5;
        [rate addCurveWithI1:i1 i2:i2 end:e];
        i2.x = 0.001;
        e.x = 0.001;
        [rate addCurveWithI1:i1 i2:i2 end:e];
        float stateDifference = 60.0 - catalysisCurrentState;
        if (stateDifference < 20) {
            stateDifference += 60;
        }
        float duration = [rate durationForXIntegralResult:stateDifference];
        
        modelObject *atpase = [world getChildWithName:@"atpase"];
        modelObject *rotor = [world getChildWithName:@"rotor"];
        [atpase animateModelStateRateOfChangeWithCurve:rate duration:duration];
        [rotor animateModelStateRateOfChangeWithCurve:rate duration:duration];
    }
    
    if (f == 5830 - startFrame) {
        Vector s, i1, i2, e;
        s.x = s.y = s.z = s.w = 0;
        i1.x = i1.y = i1.z = i1.w = 0;
        i2.x = i2.y = i2.z = i2.w = 0;
        e.x = e.y = e.z = e.w = 0;
        s.x = 0.001;
        i1.x = 0.001;
        i2.x = 0.5;
        e.x = 0.5;
        beizerCurve *rate = [[beizerCurve alloc] init];
        [rate addCurveWithStartPoint:s i1:i1 i2:i2 end:e];
        
        modelObject *atpase = [world getChildWithName:@"atpase"];
        modelObject *rotor = [world getChildWithName:@"rotor"];
        [atpase animateModelStateRateOfChangeWithCurve:rate duration:10];
        [rotor animateModelStateRateOfChangeWithCurve:rate duration:10];
        
    }
}

- (void)dimerConstructionAndZoomOutActionForFrame:(int)f {

    int startFrame = 6050;
    int dimerStartFrame = 6540 - startFrame;
    int zoomStartFrame = 7050 - startFrame;
    
    //Start the ATPase rotating
    if (f == 6050 - startFrame) {
        Vector s, i1, i2, e;
        s.x = s.y = s.z = s.w = 0;
        i1.x = i1.y = i1.z = i1.w = 0;
        i2.x = i2.y = i2.z = i2.w = 0;
        e.x = e.y = e.z = e.w = 0;
        s.x = 0.5;
        i1.x = 0.5;
        i2.x = 0.5;
        e.x = 0.5;
        beizerCurve *rate = [[beizerCurve alloc] init];
        [rate addCurveWithStartPoint:s i1:i1 i2:i2 end:e];
        
        modelObject *atpase = [world getChildWithName:@"atpase"];
        modelObject *rotor = [world getChildWithName:@"rotor"];
        [atpase animateModelStateRateOfChangeWithCurve:rate duration:10];
        [rotor animateModelStateRateOfChangeWithCurve:rate duration:10];
        
        camera.hazeStartDistanceFromCamera = 1000;
        camera.hazeLength = 1000;
    }
    
    if (f == dimerStartFrame) {
        Vector modelOrientation;
        modelOrientation.x = 0;
        modelOrientation.y = -1.0;
        modelOrientation.z = 0;
        modelOrientation.w = 0.0;
        
        Vector attachPoint;
        attachPoint.x = 0;
        attachPoint.y = -47;
        attachPoint.z = 0;
        attachPoint.w = 1.0;
        
        beizerCurve *innerStartCurve = (beizerCurve *)[world getChildWithName:@"innerStartCurve"];
        modelObject *atpase = [world getChildWithName:@"atpase"];
        modelObject *atpaseRight = [[modelObject alloc] init];
        [atpaseRight addChildModel:atpase onToCurve:innerStartCurve curveFraction:0.49 modelOrientation:modelOrientation modelAttachmentPoint:attachPoint];
//        [atpaseRight addChildModel:atpase onToCurve:innerStartCurve curveFraction:0.465 modelOrientation:modelOrientation modelAttachmentPoint:attachPoint];
        [atpaseRight setName:@"childATPase" forChild:atpase];
        [atpaseRight setPreviousFrame:f-1];
        [atpaseRight setClipForModelTo:NO];

        modelObject *atpaseLeft = [world getChildWithName:@"atpaseLeft"];
        [atpaseLeft setClipForModelTo:NO];
        
        [world addChildModel:atpaseRight];
        [world setName:@"atpaseRight" forChild:atpaseRight];
        NSMutableArray *sceneATPases = (NSMutableArray *)[world getChildWithName:@"sceneATPases"];
        [sceneATPases addObject:atpaseRight];
    }
    
    if (f == dimerStartFrame) {
        modelObject *atpaseRight = [world getChildWithName:@"atpaseRight"];
        [atpaseRight animateCurvePositionTo:0.470 duration:200];
    }
    
    if (f == dimerStartFrame + 205) {
        modelObject *atpaseLeft = [world getChildWithName:@"atpaseLeft"];
        [atpaseLeft animateCurvePositionTo:0.42 duration:80];
    }
    
    if (f == dimerStartFrame + 220) {
        modelObject *atpaseRight = [world getChildWithName:@"atpaseRight"];
        [atpaseRight animateCurvePositionTo:0.49 duration:60];
    }
    
    if (f == dimerStartFrame + 170) {
        modelObject *atpaseLeft = [world getChildWithName:@"atpaseLeft"];
        modelObject *atpaseRight = [world getChildWithName:@"atpaseRight"];
        
        Vector modelOrientation;
        
        modelOrientation.x = 0;
        modelOrientation.y = -1.0;
        modelOrientation.z = 0;
        modelOrientation.w = 0.0;
        
        beizerCurve *innerStartCurve = (beizerCurve *)[world getChildWithName:@"innerStartCurve"];
        beizerCurve *innerEndCurve = (beizerCurve *)[world getChildWithName:@"innerEndCurve"];
        beizerCurve *outerStartCurve = (beizerCurve *)[world getChildWithName:@"outerStartCurve"];
        beizerCurve *outerEndCurve = (beizerCurve *)[world getChildWithName:@"outerEndCurve"];
        beizerCurve *innerStartCurveForMembrane = (beizerCurve *)[world getChildWithName:@"innerStartCurveForMembrane"];
        beizerCurve *innerEndCurveForMembrane = (beizerCurve *)[world getChildWithName:@"innerEndCurveForMembrane"];
        beizerCurve *innerInsideCurveForMembrane = (beizerCurve *)[world getChildWithName:@"innerInsideCurveForMembrane"];
        beizerCurve *innerEndInsideCurveForMembrane = (beizerCurve *)[world getChildWithName:@"innerEndInsideCurveForMembrane"];
        beizerCurve *innerStartBoundaryCurve = (beizerCurve *)[world getChildWithName:@"innerStartBoundaryCurve"];
        beizerCurve *innerEndBoundaryCurve = (beizerCurve *)[world getChildWithName:@"innerEndBoundaryCurve"];
        
        [atpaseLeft animateMaintainModelsOnCurveFrom:innerStartCurve to:innerEndCurve originalModel:nil modelOrientation:modelOrientation spacing:0 duration:100];
        [atpaseRight animateMaintainModelsOnCurveFrom:innerStartCurve to:innerEndCurve originalModel:nil modelOrientation:modelOrientation spacing:0 duration:100];
        
        modelObject *IMPopCCurve = [world getChildWithName:@"IMPopCCurve"];
        modelObject *IMPopCCurveInner = [world getChildWithName:@"IMPopCCurveInner"];
        modelObject *popC = [world getChildWithName:@"popC"];
        [IMPopCCurve animateMaintainModelsOnCurveFrom:innerStartCurveForMembrane to:innerEndCurveForMembrane originalModel:popC modelOrientation:modelOrientation spacing:6.0 duration:100];
        [IMPopCCurveInner animateMaintainModelsOnCurveFrom:innerInsideCurveForMembrane to:innerEndInsideCurveForMembrane originalModel:popC modelOrientation:modelOrientation spacing:6.0 duration:100];
        
        modelObject *protonPool = [world getChildWithName:@"protonPool"];
        modelObject *matrixPool = [world getChildWithName:@"matrixPool"];
        modelObject *matrixPO4Pool = [world getChildWithName:@"matrixPO4Pool"];
        modelObject *matrixADPPool = [world getChildWithName:@"matrixADPPool"];
        modelObject *matrixATPPool = [world getChildWithName:@"matrixATPPool"];
        [protonPool animateDiffusionCurvesOuterFrom:innerStartBoundaryCurve to:innerEndBoundaryCurve andInner:nil to:nil duration:100];
        [matrixPool animateDiffusionCurvesOuterFrom:outerStartCurve to:outerEndCurve andInner:nil to:nil duration:100];
        [matrixADPPool animateDiffusionCurvesOuterFrom:outerStartCurve to:outerEndCurve andInner:nil to:nil duration:100];
        [matrixPO4Pool animateDiffusionCurvesOuterFrom:outerStartCurve to:outerEndCurve andInner:nil to:nil duration:100];
        [matrixATPPool animateDiffusionCurvesOuterFrom:outerStartCurve to:outerEndCurve andInner:nil to:nil duration:100];
        
//        [protonPool changePoolDiffusionMaxTransSpeed:25 maxRotSpeed:0.1];
    }

//    if (f == 4370 - startFrame) {
//        modelObject *protonPool = [world getChildWithName:@"protonPool"];
//        [protonPool changePoolDiffusionMaxTransSpeed:5.0 maxRotSpeed:0.1];
//    }
    if (f == dimerStartFrame + 270) {
        Vector s, i1, i2, e;
        s.x = s.y = s.z = s.w = 0;
        i1.x = i1.y = i1.z = i1.w = 0;
        i2.x = i2.y = i2.z = i2.w = 0;
        e.x = e.y = e.z = e.w = 0;
        s.x = 0.5;
        i1.x = 0.5;
        i2.x = 1.0;
        e.x = 1.0;
        beizerCurve *rate = [[beizerCurve alloc] init];
        [rate addCurveWithStartPoint:s i1:i1 i2:i2 end:e];
        
        modelObject *atpase = [world getChildWithName:@"atpase"];
        modelObject *rotor = [world getChildWithName:@"rotor"];
        [atpase animateModelStateRateOfChangeWithCurve:rate duration:50];
        [rotor animateModelStateRateOfChangeWithCurve:rate duration:50];
    }
    
    if (f == zoomStartFrame) {
        
        Vector atpaseF1Center;
        atpaseF1Center.x = 0; atpaseF1Center.y = 0; atpaseF1Center.z = 132; atpaseF1Center.w = 1.0;
        modelObject *atpaseLeft = [world getChildWithName:@"atpaseLeft"];
        modelObject *atpase = [world getChildWithName:@"atpase"];
        atpaseF1Center = [atpaseLeft transformCoordinate:atpaseF1Center inSystemOfChild:atpase];
        [camera animateViewLookAtTranslationTo:atpaseF1Center duration:50];
        
        Vector destination, i1, i2;
        i1.x = -610; i1.y = -80; i1.z = 175;
        i1.w = 1;
        i2.x = 387; i2.y = -80; i2.z = 501;
        i2.w = 1;
        destination.z = -1000; destination.x = 0; destination.y = -60; destination.w = 1;
        [camera animateViewOriginTranslationTo:destination intermediate1:i1 intermediate2:i2 duration:400];

        [camera animateFocalLenghTo:30 duration:160];
        [camera animateApertureTo:2 duration:160];
    }
    
    if (f == zoomStartFrame + 160) {
        modelObject *popC = [world getChildWithName:@"popC"];
        beizerCurve *innerEndCurveForMembrane = (beizerCurve *)[world getChildWithName:@"innerEndCurveForMembrane"];
        
        Vector modelOrientation;
        modelOrientation.x = 0;
        modelOrientation.y = -1.0;
        modelOrientation.z = 0;
        modelOrientation.w = 0.0;

        modelObject *membraneCurve = [[modelObject alloc] init];
        [membraneCurve addParametricLineOfModel:popC modelOrientation:modelOrientation spacing:6.0 offset:0 bezierCurve:innerEndCurveForMembrane];
        modelObject *membranePlane = [[modelObject alloc] init];
        [membranePlane addGridOfModel:membraneCurve xNumMembers:1 xSpacing:0 zNumMembers:70 zSpacing:-6];
        [membranePlane translateToX:0 Y:0 Z:18];
        [membranePlane enableWobbleWithMaxRadius:0.5 changeVectorSize:0.3];
        [membranePlane setClipForModelTo:YES];
        
        [world addChildModel:membranePlane];

        modelOrientation.x = 0;
        modelOrientation.y = -1.0;
        modelOrientation.z = 0;
        modelOrientation.w = 0.0;
        
        Vector attachPoint;
        attachPoint.x = 0;
        attachPoint.y = -47;
        attachPoint.z = 0;
        attachPoint.w = 1.0;
        
        beizerCurve *innerEndCurve = (beizerCurve *)[world getChildWithName:@"innerEndCurve"];
        modelObject *atpase = [world getChildWithName:@"atpase"];
        modelObject *atpaseRotate = [world getChildWithName:@"atpaseRotate"];
        NSMutableArray *sceneATPases = (NSMutableArray *)[world getChildWithName:@"sceneATPases"];

        for (int atpaseDimer = 1; atpaseDimer < 5; atpaseDimer++) {
            modelObject *atpaseLeft = [[modelObject alloc] init];
            [atpaseLeft addChildModel:atpaseRotate onToCurve:innerEndCurve curveFraction:0.42 modelOrientation:modelOrientation modelAttachmentPoint:attachPoint];
            [atpaseLeft setName:@"childATPase" forChild:atpaseRotate];
            [atpaseLeft setClipForModelTo:YES];
            [atpaseLeft translateToX:0 Y:0 Z:-100 * atpaseDimer];
            
            modelObject *atpaseRight = [[modelObject alloc] init];
            [atpaseRight addChildModel:atpase onToCurve:innerEndCurve curveFraction:0.49 modelOrientation:modelOrientation modelAttachmentPoint:attachPoint];
            [atpaseRight setName:@"childATPase" forChild:atpase];
            [atpaseRight setClipForModelTo:YES];
            [atpaseRight translateToX:0 Y:0 Z:-100 * atpaseDimer];
            
            [world addChildModel:atpaseLeft];
            [world addChildModel:atpaseRight];
            [sceneATPases addObject:atpaseLeft];
            [sceneATPases addObject:atpaseRight];
        }

        modelObject *protonPool = [world getChildWithName:@"protonPool"];
        modelObject *matrixPool = [world getChildWithName:@"matrixPool"];
        modelObject *matrixPO4Pool = [world getChildWithName:@"matrixPO4Pool"];
        modelObject *matrixADPPool = [world getChildWithName:@"matrixADPPool"];
        modelObject *matrixATPPool = [world getChildWithName:@"matrixATPPool"];
        [protonPool changePoolDiffusionNearZ:-700 farZ:100];
        [matrixPool changePoolDiffusionNearZ:-700 farZ:100];
        [matrixPO4Pool changePoolDiffusionNearZ:-700 farZ:100];
        [matrixADPPool changePoolDiffusionNearZ:-700 farZ:100];
        [matrixATPPool changePoolDiffusionNearZ:-700 farZ:100];
        
//        camera.clipPlaneEnabled = YES;
//        camera.clipPlaneDistanceFromCamera = 400;
//        [camera animateClipPlaneTo:0 duration:100];

    }
    
    if (f == zoomStartFrame + 200) {
        [camera animateFocalLenghTo:350 duration:100];
        [camera animateApertureTo:6 duration:100];
    }
    
    if (f == zoomStartFrame + 300) {
        Vector lookAtPoint;
        lookAtPoint.x = lookAtPoint.y = lookAtPoint.z = 0.0;
        lookAtPoint.y = -60;

        [camera animateViewLookAtTranslationTo:lookAtPoint duration:60];
    }
}

- (void)cristaeConstructionForFrame:(int)f {
    int startFrame = 6050;
    
    if (f == 6050 - startFrame) {
        //Start the animations
        Vector s, i1, i2, e;
        s.x = s.y = s.z = s.w = 0;
        i1.x = i1.y = i1.z = i1.w = 0;
        i2.x = i2.y = i2.z = i2.w = 0;
        e.x = e.y = e.z = e.w = 0;
        s.x = 1.0;
        i1.x = 1.0;
        i2.x = 1.0;
        e.x = 1.0;
        beizerCurve *rate = [[beizerCurve alloc] init];
        [rate addCurveWithStartPoint:s i1:i1 i2:i2 end:e];
        
        modelObject *atpase = [world getChildWithName:@"atpase"];
        modelObject *rotor = [world getChildWithName:@"rotor"];
        [atpase animateModelStateRateOfChangeWithCurve:rate duration:10];
        [rotor animateModelStateRateOfChangeWithCurve:rate duration:10];
        
        //Construct the cristae
        //First remove the old flat membrane
        modelObject *membrane = [world getChildWithName:@"membrane"];
        [world deleteChildModel:membrane];

        //Now create new
        modelObject *popC = [world getChildWithName:@"popC"];
        beizerCurve *innerEndCurveForMembrane = (beizerCurve *)[world getChildWithName:@"innerEndCurveForMembrane"];
        Vector gridDirection;
        gridDirection.x = 0;
        gridDirection.y = 0;
        gridDirection.z = 1.0;
        gridDirection.w = 0.0;
        beizerCurve *innerEndInsideCurve = [innerEndCurveForMembrane curveBySubtractingNormalWithScale:28.0 segmentations:4 crossVector:gridDirection];
        beizerCurve *innerEndBoundaryCurve = [innerEndCurveForMembrane curveBySubtractingNormalWithScale:35.0 segmentations:4 crossVector:gridDirection];

        Vector modelOrientation;
        modelOrientation.x = 0;
        modelOrientation.y = -1.0;
        modelOrientation.z = 0;
        modelOrientation.w = 0.0;
        
        modelObject *membraneCurve = [[modelObject alloc] init];
        [membraneCurve addParametricLineOfModel:popC modelOrientation:modelOrientation spacing:6.0 offset:0 bezierCurve:innerEndCurveForMembrane];
        modelObject *innerMembraneCurve = [[modelObject alloc] init];
        [innerMembraneCurve addParametricLineOfModel:popC modelOrientation:modelOrientation spacing:6.0 offset:0 bezierCurve:innerEndInsideCurve];
        modelObject *membranePlane = [[modelObject alloc] init];
        [membranePlane addGridOfModel:membraneCurve xNumMembers:1 xSpacing:0 zNumMembers:870/6 zSpacing:-6];
        [membranePlane addGridOfModel:innerMembraneCurve xNumMembers:1 xSpacing:0 zNumMembers:870/6 zSpacing:-6];
//        [membranePlane translateToX:0 Y:0 Z:0];
        [membranePlane enableWobbleWithMaxRadius:0.5 changeVectorSize:0.3];
        [membranePlane setClipForModelTo:YES];
        
        [world addChildModel:membranePlane];
        
        modelOrientation.x = 0;
        modelOrientation.y = -1.0;
        modelOrientation.z = 0;
        modelOrientation.w = 0.0;
        
        Vector attachPoint;
        attachPoint.x = 0;
        attachPoint.y = -47;
        attachPoint.z = 0;
        attachPoint.w = 1.0;
        
        beizerCurve *innerEndCurve = (beizerCurve *)[world getChildWithName:@"innerEndCurve"];
        beizerCurve *outerEndCurve = (beizerCurve *)[world getChildWithName:@"outerEndCurve"];
        modelObject *atpaseRotate = [world getChildWithName:@"atpaseRotate"];
        NSMutableArray *sceneATPases = (NSMutableArray *)[world getChildWithName:@"sceneATPases"];
        
        modelObject *atpaseLeft = [world getChildWithName:@"atpaseLeft"];
        [world deleteChildModel:atpaseLeft];
        [sceneATPases removeObject:atpaseLeft];
        
        modelObject *protonPool = [world getChildWithName:@"protonPool"];
        modelObject *matrixPool = [world getChildWithName:@"matrixPool"];
        modelObject *matrixPO4Pool = [world getChildWithName:@"matrixPO4Pool"];
        modelObject *matrixADPPool = [world getChildWithName:@"matrixADPPool"];
        modelObject *matrixATPPool = [world getChildWithName:@"matrixATPPool"];
        [world deleteChildModel:protonPool];
        [world deleteChildModel:matrixPool];
        [world deleteChildModel:matrixPO4Pool];
        [world deleteChildModel:matrixADPPool];
        [world deleteChildModel:matrixATPPool];
        
        Vector e1;
        e1.x = 0; e1.y = 300; e1.z = 100; e1.w = 0;
        modelObject *proton = [world getChildWithName:@"proton"];
        modelObject *adp = [world getChildWithName:@"ADP"];
        modelObject *po4 = [world getChildWithName:@"PO4"];
        modelObject *atpGlow = [world getChildWithName:@"ATPGlow"];

        protonPool = [[modelObject alloc] init];
        [protonPool setupCurveBasedPoolOfModel:proton numModels:100 boundingCurve:innerEndBoundaryCurve innerCurve:nil nearZLimit:-900 farZLimit:100 newModelEntryPoint:e1];
        [protonPool enablePoolDiffusionWithMaxTransSpeed:5.0 maxRotSpeed:0.0 transChangeSize:1.5 rotChangeSize:0.00];
        [protonPool enableWobbleWithMaxRadius:1.0 changeVectorSize:0.5];
        [protonPool changePoolReplacementTo:YES];
        [world addChildModel:protonPool];
        [world setName:@"protonPool" forChild:protonPool];
        
        matrixPool = [[modelObject alloc] init];
        matrixADPPool = [[modelObject alloc] init];
        matrixPO4Pool = [[modelObject alloc] init];
        matrixATPPool = [[modelObject alloc] init];
        
        for (int atpaseDimer = 0; atpaseDimer < 10; atpaseDimer++) {
            modelObject *atpaseLeft = [[modelObject alloc] init];
            [atpaseLeft addChildModel:atpaseRotate onToCurve:innerEndCurve curveFraction:0.42 modelOrientation:modelOrientation modelAttachmentPoint:attachPoint];
            [atpaseLeft setName:@"childATPase" forChild:atpaseRotate];
            [atpaseLeft setClipForModelTo:YES];
            [atpaseLeft translateToX:0 Y:0 Z:-100 * atpaseDimer];
            
            modelObject *atpaseRight = [[modelObject alloc] init];
            [atpaseRight addChildModel:atpase onToCurve:innerEndCurve curveFraction:0.49 modelOrientation:modelOrientation modelAttachmentPoint:attachPoint];
            [atpaseRight setName:@"childATPase" forChild:atpase];
            [atpaseRight setClipForModelTo:YES];
            [atpaseRight translateToX:0 Y:0 Z:-100 * atpaseDimer];
            
            [world addChildModel:atpaseLeft];
            [world addChildModel:atpaseRight];
            [sceneATPases addObject:atpaseLeft];
            [sceneATPases addObject:atpaseRight];
            
            [matrixADPPool addPoolExclusionZoneBasedOn:atpaseLeft];
            [matrixPO4Pool addPoolExclusionZoneBasedOn:atpaseLeft];
            [matrixATPPool addPoolExclusionZoneBasedOn:atpaseLeft];
            [matrixPool addPoolExclusionZoneBasedOn:atpaseLeft];
            
            [matrixADPPool addPoolExclusionZoneBasedOn:atpaseRight];
            [matrixPO4Pool addPoolExclusionZoneBasedOn:atpaseRight];
            [matrixATPPool addPoolExclusionZoneBasedOn:atpaseRight];
            [matrixPool addPoolExclusionZoneBasedOn:atpaseRight];

        }

        e1.x = 1000; e1.y = -1000; e1.z = 0; e1.w = 0;
        [matrixPool setupCurveBasedPoolOfModel:proton numModels:20 boundingCurve:outerEndCurve innerCurve:nil nearZLimit:-900 farZLimit:100 newModelEntryPoint:e1];
        [matrixPool enablePoolDiffusionWithMaxTransSpeed:5.0 maxRotSpeed:0.1 transChangeSize:1.5 rotChangeSize:0.01];
        [matrixPool enableWobbleWithMaxRadius:1.0 changeVectorSize:0.5];
        
        [matrixADPPool setupCurveBasedPoolOfModel:adp numModels:40 boundingCurve:outerEndCurve innerCurve:nil nearZLimit:-900 farZLimit:100 newModelEntryPoint:e1];
        [matrixADPPool enablePoolDiffusionWithMaxTransSpeed:3.0 maxRotSpeed:0.1 transChangeSize:0.5 rotChangeSize:0.01];
        [matrixADPPool enableWobbleWithMaxRadius:1.0 changeVectorSize:0.5];
        [matrixADPPool changePoolReplacementTo:YES];

        [matrixPO4Pool setupCurveBasedPoolOfModel:po4 numModels:40 boundingCurve:outerEndCurve innerCurve:nil nearZLimit:-900 farZLimit:100 newModelEntryPoint:e1];
        [matrixPO4Pool enablePoolDiffusionWithMaxTransSpeed:3.0 maxRotSpeed:0.1 transChangeSize:0.5 rotChangeSize:0.01];
        [matrixPO4Pool enableWobbleWithMaxRadius:1.0 changeVectorSize:0.5];
        [matrixPO4Pool changePoolReplacementTo:YES];

        [matrixATPPool setupCurveBasedPoolOfModel:atpGlow numModels:2 boundingCurve:outerEndCurve innerCurve:nil nearZLimit:-900 farZLimit:100 newModelEntryPoint:e1];
        [matrixATPPool enablePoolDiffusionWithMaxTransSpeed:3.0 maxRotSpeed:0.1 transChangeSize:0.5 rotChangeSize:0.01];
        [matrixATPPool enableWobbleWithMaxRadius:1.0 changeVectorSize:0.5];
        [matrixATPPool changePoolReplacementTo:NO];
        
        [world addChildModel:matrixPool];
        [world setName:@"matrixPool" forChild:matrixPool];
        [world addChildModel:matrixADPPool];
        [world setName:@"matrixADPPool" forChild:matrixADPPool];
        [world addChildModel:matrixATPPool];
        [world setName:@"matrixATPPool" forChild:matrixATPPool];
        [world addChildModel:matrixPO4Pool];
        [world setName:@"matrixPO4Pool" forChild:matrixPO4Pool];
        
        camera.hazeStartDistanceFromCamera = 800;
        camera.hazeLength = 400;
    }

}

- (void)sceneManagementForFrame:(int)f {

    
    
//    if (f == 240) {
//        modelObject *stator1 = [world getChildWithName:@"stator1"];
//        [bfm animateRotationAroundX:0 Y:0 Z:90 * radiansPerDegree duration:30];
//    }
    
//    if ((f >85) && (f < 115)) {
    
//        modelObject *fliM = [world getChildWithName:@"fliM"];
//        modelObject *rotor = [world getChildWithName:@"rotor"];
    
//        float t = 10 * (1 - cosf((float)(f - 85) / 30.0 * 180 * radiansPerDegree));
    
//        modelObject *fliMOligoNew = [[modelObject alloc] init];
//        [fliMOligoNew addCircleOfModel:fliM numMembers:34 radius:220 + t * 5];
//        [fliMOligoNew translateToX:0 Y:0.5 * t Z:0];
//        [rotor deleteChildWithName:@"fliMOligo"];
//        [rotor addChildModel:fliMOligoNew];
//        [rotor setName:@"fliMOligo" forChild:fliMOligoNew];
    
/*        modelObject *fliF = [world getChildWithName:@"fliF"];
        modelObject *fliFOligoNew = [[modelObject alloc] init];
        [fliFOligoNew addCircleOfModel:fliF numMembers:34 radius:0 + t * 5];
        [fliFOligoNew translateToX:0 Y:-1 * t Z:0];
        [rotor deleteChildWithName:@"fliFOligo"];
        [rotor addChildModel:fliFOligoNew];
        [rotor setName:@"fliFOligo" forChild:fliFOligoNew];

        modelObject *fliG = [world getChildWithName:@"fliG"];
        modelObject *fliGOligoNew = [[modelObject alloc] init];
        [fliGOligoNew addCircleOfModel:fliG numMembers:34 radius:0 + t * 5];
        [fliGOligoNew translateToX:0 Y:70 Z:0];
        [fliGOligoNew translateToX:0 Y:-0.5 * t Z:0];
        [rotor deleteChildWithName:@"fliGOligo"];
        [rotor addChildModel:fliGOligoNew];
        [rotor setName:@"fliGOligo" forChild:fliGOligoNew];

        modelObject *fliN = [world getChildWithName:@"fliN"];
        modelObject *fliNOligoNew = [[modelObject alloc] init];
        [fliNOligoNew addCircleOfModel:fliN numMembers:34 radius:220 + t * 5];
        [fliNOligoNew translateToX:0 Y:210 Z:0];
        [fliNOligoNew translateToX:0 Y:1 * t Z:0];
        [rotor deleteChildWithName:@"fliNOligo"];
        [rotor addChildModel:fliNOligoNew];
        [rotor setName:@"fliNOligo" forChild:fliNOligoNew];

        modelObject *shaft = [rotor getChildWithName:@"shaftOligo"];
        modelObject *hook = [rotor getChildWithName:@"hookFilament"];
        [shaft translateToX:0 Y:-1 * t Z:0];
        [hook translateToX:0 Y:-1 * t Z:0];*/
//    }

//    if (f == 153) {
//        modelObject *model = [world getChildWithName:@"fliF"];
//        [model animateDiffuseColourTo:protonGlowColour duration:5];
//    }
//    if (f == 158) {
//        modelObject *model = [world getChildWithName:@"fliF"];
//        [model animateDiffuseColourTo:fliNColour duration:5];
//    }

//    if (f == 306) {
//        modelObject *model = [world getChildWithName:@"fliG"];
//        [model animateDiffuseColourTo:protonGlowColour duration:5];
//    }
//    if (f == 311) {
//        modelObject *model = [world getChildWithName:@"fliG"];
//        [model animateDiffuseColourTo:fliNColour duration:5];
//    }

//    if (f == 534) {
//        modelObject *model = [world getChildWithName:@"fliM"];
//        [model animateDiffuseColourTo:protonGlowColour duration:5];
//    }
//    if (f == 539) {
//        modelObject *model = [world getChildWithName:@"fliM"];
//        [model animateDiffuseColourTo:fliNColour duration:5];
//    }

//    if (f == 564) {
//        modelObject *model = [world getChildWithName:@"fliN"];
//        [model animateDiffuseColourTo:protonGlowColour duration:5];
//    }
//    if (f == 569) {
//        modelObject *model = [world getChildWithName:@"fliN"];
//        [model animateDiffuseColourTo:fliNColour duration:5];
//    }

    
    modelObject *stator1 = [world getChildWithName:@"stator1"];
    modelObject *stator2 = [world getChildWithName:@"stator2"];
    
    modelObject *motBN = [world getChildWithName:@"motBN"];
    modelObject *motBCDimer = [world getChildWithName:@"motBCDimer"];
    modelObject *motBCMonomer = [world getChildWithName:@"motBCMonomer"];
    modelObject *rotor = [world getChildWithName:@"rotor"];
    
    if (f == 0) {
        [stator1 translateToX:-810 Y:0 Z:0];
        [stator2 translateToX:810 Y:0 Z:0];

        Vector lookAt;
        lookAt.x = 190; lookAt.y = 0; lookAt.z = 0;
        [camera setLookAtPoint:lookAt];
        [motBCMonomer rotateAroundX:0 Y:0 Z:90 * radiansPerDegree];
        [motBN translateToX:0 Y:-50 Z:0];
        [motBCDimer translateToX:0 Y:-50 Z:0];
        Vector rotVector;
        rotVector.x = 0; rotVector.y = 1.0; rotVector.z = 0;
        [rotor animateRotationAroundAxis:rotVector byAnglePerFrame: 360 / (5 * 240) * radiansPerDegree];
        [self scheduleProtonTranslocationForModel:stator1 translocationDuration:480 currentFrame:f];
    }
    
    if (f == 180) {
        Vector lookAt;
        lookAt.x = 0; lookAt.y = 0; lookAt.z = 0;
        [camera animateViewLookAtTranslationTo:lookAt duration:30];
    }
    
    //8 sec - translate in one stator over 2 s
//    if (f == 241) {
//        Vector translation;
//        translation.x = -810; translation.y = 0; translation.z = 0; translation.w = 0;
//        [stator1 animateLinearTranslationTo:translation duration:60];
//        translation.x = 810; translation.y = 0; translation.z = 0; translation.w = 0;
//        [stator2 animateLinearTranslationTo:translation duration:60];
//    }
    
    //10 sec - trigger motB movement
//    if (f == 301) {
//        Vector translation;
//        translation.x = 0; translation.y = -50; translation.z = 0; translation.w = 0;
//        modelObject *motBN = [world getChildWithName:@"motBN"];
//        modelObject *motBCDimer = [world getChildWithName:@"motBCDimer"];
//        modelObject *motBCMonomer = [world getChildWithName:@"motBCMonomer"];
//        [motBCMonomer animateRotationAroundX:0 Y:0 Z:90 * radiansPerDegree duration:60];
//        [motBN animateLinearTranslationTo:translation duration:60];
//        [motBCDimer animateLinearTranslationTo:translation duration:60];
//    }
    //12 sec - trigger proton translocation
//    if ((f > 361) && (f % 60 == 2)) {
//        int duration = ([[randomNumberGenerator sharedInstance] getRandomUShort] / (float)UINT16_MAX) * 30 + 30;
//        [self scheduleProtonTranslocationForModel:stator1 translocationDuration:duration currentFrame:f];
//    }
//    if ((f > 361) && (f % 60 == 26)) {
//        modelObject *rotor = [world getChildWithName:@"rotor"];
//        [rotor animateRotationAroundAxisEnergyEvent];
//    }

//    if ((f > 361) && (f % 60 == 31)) {
//        int duration = ([[randomNumberGenerator sharedInstance] getRandomUShort] / (float)UINT16_MAX) * 30 + 30;
//        [self scheduleProtonTranslocationForModel:stator2 translocationDuration:duration currentFrame:f];
//    }
//    if ((f > 361) && (f % 60 == 55)) {
//        modelObject *rotor = [world getChildWithName:@"rotor"];
//        [rotor animateRotationAroundAxisEnergyEvent];
//    }

    //18 sec - second motB translocation
//    if (f == 121) {
//        Vector translation;
//        translation.x = 810; translation.y = 0; translation.z = 0; translation.w = 0;
//        [stator2 animateLinearTranslationTo:translation duration:60];
//    }

    //20 sec - trigger movement
//    if (f == 181) {
//        Vector translation;
//        translation.x = 0; translation.y = -50; translation.z = 0; translation.w = 0;
//        modelObject *motBN = [world getChildWithName:@"motBN2"];
//        modelObject *motBCDimer = [world getChildWithName:@"motBCDimer2"];
//        modelObject *motBCMonomer = [world getChildWithName:@"motBCMonomer2"];
//        [motBCMonomer animateRotationAroundX:0 Y:0 Z:90 * radiansPerDegree duration:60];
//        [motBN animateLinearTranslationTo:translation duration:60];
//        [motBCDimer animateLinearTranslationTo:translation duration:60];
//    }

    //22 sec - trigger proton translocation
//    if ((f > 241) && (f % 60 == 30)) {
//        int duration = ([[randomNumberGenerator sharedInstance] getRandomUShort] / (float)UINT16_MAX) * 30 + 30;
//        [self scheduleProtonTranslocationForModel:stator2 translocationDuration:duration currentFrame:f];
//    }
//    if ((f > 250) && (f % 60 == 55)) {
//        modelObject *rotor = [world getChildWithName:@"rotor"];
//        [rotor animateRotationAroundAxisEnergyEvent];
//    }
//    if (f % 40 == 1) {
//        int duration = ([[randomNumberGenerator sharedInstance] getRandomUShort] / (float)UINT16_MAX) * 30 + 30;
//        [self scheduleProtonTranslocationForModel:stator1 translocationDuration:duration currentFrame:f];
//        duration = ([[randomNumberGenerator sharedInstance] getRandomUShort] / (float)UINT16_MAX) * 30 + 30;
//        [self scheduleProtonTranslocationForModel:stator2 translocationDuration:duration currentFrame:f];
//    }

//    if (f % 40 == 25) {
//        modelObject *rotor = [world getChildWithName:@"rotor"];
//        [rotor animateRotationAroundAxisEnergyEvent];
//    }

//    if (f % 40 == 20) {
//        int duration = ([[randomNumberGenerator sharedInstance] getRandomUShort] / (float)UINT16_MAX) * 30 + 30;
//        [self scheduleProtonTranslocationForModel:stator1 translocationDuration:duration currentFrame:f];
//        int duration = ([[randomNumberGenerator sharedInstance] getRandomUShort] / (float)UINT16_MAX) * 30 + 30;
//        [self scheduleProtonTranslocationForModel:stator2 translocationDuration:duration currentFrame:f];
//    }
    
//    if ((f % 40 == 5) && (f > 20)) {
//        modelObject *rotor = [world getChildWithName:@"rotor"];
//        [rotor animateRotationAroundAxisEnergyEvent];
//    }

    int averageDuration = 45;
    
    //Check if any protons have finished the transit
    NSArray *holdCopy = [NSArray arrayWithArray:holdObjects];
    NSEnumerator *holdEnum = [holdCopy objectEnumerator];
    NSDictionary *o;
    
    while (o = [holdEnum nextObject]) {
        if ([[o objectForKey:@"type"] isEqualToString:@"proton"]) {
            int destFrame = (int)[[o objectForKey:@"destFrame"] integerValue];
            if (f == destFrame) {
                [holdObjects removeObject:o];
                modelObject *proton = [o objectForKey:@"object"];
                modelObject *matrixPool = [world getChildWithName:@"matrixPool"];
                modelObject *mot = [o objectForKey:@"parent"];
                
                //                Vector offset = [atpase transformWithCurrentTransform:[proton currentTranslation]];
                //                [proton resetTransformation];
                //                [proton translateToX:offset.x Y:offset.y Z:offset.z];
                //                [atpase deleteChildModel:proton];
                [mot deleteAndTransformOutOfCoordSystemChildModel:proton];
                [matrixPool addToPoolModel:proton];
                Vector rot;
                rot.x = rot.y = rot.z = rot.w = 0;
                Vector momentum;
                beizerCurve *transitPath = [o objectForKey:@"curve"];
                momentum = vector_scale([transitPath getDerivativeAtT:1.0], 1.0 / (float)averageDuration);
                momentum = [mot transformWithCurrentTransform:momentum];
                [proton setDiffusionTranslateChangeVector:momentum rotateChangeVector:rot];
                [camera animateFollowModelObject:proton parent:proton world:world distanceFromCentreOfMass:-20.0];
            }
        }
    }


}

- (void)sceneManagementForFrameATPaseCurrent:(int)f {
    
    //Calculate how much ATPase has rotated
    modelObject *subC = [world getChildWithName:@"subC"];
    static float protonCurrentState = 0;
    static float previousProtonState = 0;
    if ([subC getCurrentState] < previousProtonState) {
        protonCurrentState += [subC getNumModelStates] - previousProtonState + [subC getCurrentState];
    } else {
        protonCurrentState += [subC getCurrentState] - previousProtonState;
    }
    previousProtonState = [subC getCurrentState];
    
    static float catalysisCurrentState = 0;
    static float previousCatalysisState = 0;
    static bool catalysisModelsSelected = NO;
    static bool atpAdded = NO;
    static int currentCatalysisPhase = PHASE_1;
    if ([subC getCurrentState] < previousCatalysisState) {
        catalysisCurrentState += [subC getNumModelStates] - previousCatalysisState + [subC getCurrentState];
    } else {
        catalysisCurrentState += [subC getCurrentState] - previousCatalysisState;
    }
    previousCatalysisState = [subC getCurrentState];
    if (catalysisCurrentState > 60) {
        catalysisCurrentState -= 60;
        currentCatalysisPhase++;
        if (currentCatalysisPhase > PHASE_3) {
            currentCatalysisPhase = PHASE_1;
        }
    }
    
//    printf("\nf: %d, Proton state: %.2f, catalysis state: %.2f, phase: %d\n", f, protonCurrentState, catalysisCurrentState, currentCatalysisPhase);
    
    //
    //This bit corresponds to the storyboard
    //
//    [self cRingZoomSceneActionForFrame:f];
//    [self f1ZoomAndClipActionForFrame:f catalysisCurrentState:catalysisCurrentState catalysisPhase:currentCatalysisPhase];
//    [self dimerConstructionAndZoomOutActionForFrame:f];
//    [self cristaeConstructionForFrame:f];

//    if (f < 2403) {
//        [self cRingZoomSceneActionForFrame:f];
//    } else if (f == 2403) {
//        Vector viewOrigin, lookAtPoint;
//        viewOrigin.x = 0;
//        viewOrigin.y = -60;
//        viewOrigin.z = -350;
//        viewOrigin.w = 1.0;
//        camera.viewOrigin = viewOrigin;
//        lookAtPoint.x = lookAtPoint.y = lookAtPoint.z = 0.0;
//        lookAtPoint.y = -60;
//        camera.lookAtPoint = lookAtPoint;
//        camera.aperture = 6.0;
//        camera.focalLength = 320;
//        [self f1ZoomAndClipActionForFrame:f catalysisCurrentState:catalysisCurrentState catalysisPhase:currentCatalysisPhase];
//    } else if ((f > 2403) && (f < 4650)) {
//        [self f1ZoomAndClipActionForFrame:f catalysisCurrentState:catalysisCurrentState catalysisPhase:currentCatalysisPhase];
//    }
    
    //
    //The rest is to automate the ATPase animations...
    //
//    modelObject *atpaseLeft = [world getChildWithName:@"atpaseLeft"];
//    [atpaseLeft logClipData];
//    [atpaseLeft getNumModelStates];
    NSMutableArray *sceneATPases = (NSMutableArray *)[world getChildWithName:@"sceneATPases"];
    //and as approriate determine paths for:
    //protons
    int protonTranslocationDuration = 44;

    if (protonCurrentState > [subC getNumModelStates] / 8.0) {
        protonCurrentState -= [subC getNumModelStates] / 8.0;
//        [self scheduleProtonTranslocationForModel:[world getChildWithName:@"atpaseLeft"] translocationDuration:protonTranslocationDuration currentFrame:f];
//        [self scheduleProtonTranslocationForModel:[world getChildWithName:@"atpaseRight"] translocationDuration:protonTranslocationDuration currentFrame:f];
        NSEnumerator *atpaseEnum = [sceneATPases objectEnumerator];
        modelObject *atpase;
        while (atpase = [atpaseEnum nextObject]) {
            [self scheduleProtonTranslocationForModel:atpase translocationDuration:protonTranslocationDuration currentFrame:f];
        }
    }
    
    
    //Check if any protons have finished the transit
    NSArray *holdCopy = [NSArray arrayWithArray:holdObjects];
    NSEnumerator *holdEnum = [holdCopy objectEnumerator];
    NSDictionary *o;
    
    while (o = [holdEnum nextObject]) {
        if ([[o objectForKey:@"type"] isEqualToString:@"proton"]) {
            int destFrame = (int)[[o objectForKey:@"destFrame"] integerValue];
            if (f == destFrame) {
                [holdObjects removeObject:o];
                modelObject *proton = [o objectForKey:@"object"];
                modelObject *matrixPool = [world getChildWithName:@"matrixPool"];
                modelObject *atpase = [o objectForKey:@"parent"];
                
//                Vector offset = [atpase transformWithCurrentTransform:[proton currentTranslation]];
//                [proton resetTransformation];
//                [proton translateToX:offset.x Y:offset.y Z:offset.z];
//                [atpase deleteChildModel:proton];
                [atpase deleteAndTransformOutOfCoordSystemChildModel:proton];
                [matrixPool addToPoolModel:proton];
                Vector rot;
                rot.x = rot.y = rot.z = rot.w = 0;
                Vector momentum;
                beizerCurve *transitPath = [o objectForKey:@"curve"];
                momentum = vector_scale([transitPath getDerivativeAtT:1.0], 1.0 / (float)protonTranslocationDuration);
                momentum = [atpase transformWithCurrentTransform:momentum];
                [proton setDiffusionTranslateChangeVector:momentum rotateChangeVector:rot];
            }
        }
    }

    
    //Determine paths for ADP/PO4/ATP
    //ADP and PO4 binding for PHASE open at frame 61
    if ((catalysisCurrentState > 0) && (catalysisCurrentState < 1) && (!catalysisModelsSelected)) {
        catalysisModelsSelected = YES;
        
//        [self scheduleADPandPO4TranslocationForModel:[world getChildWithName:@"atpaseLeft"] currentCatalysisPhase:currentCatalysisPhase currentFrame:f];
//        [self scheduleADPandPO4TranslocationForModel:[world getChildWithName:@"atpaseRight"] currentCatalysisPhase:currentCatalysisPhase currentFrame:f];
        NSEnumerator *atpaseEnum = [sceneATPases objectEnumerator];
        modelObject *atpase;
        while (atpase = [atpaseEnum nextObject]) {
            [self scheduleADPandPO4TranslocationForModel:atpase currentCatalysisPhase:currentCatalysisPhase currentFrame:f];
        }

    }
    
    if ((catalysisCurrentState > 1) && (catalysisCurrentState < 2)) {
        catalysisModelsSelected = NO;
    }
    

    
    if ([subC hasModelStateCycled] == YES) {
        NSArray *holdCopy = [NSArray arrayWithArray:holdObjects];
        NSEnumerator *holdEnum = [holdCopy objectEnumerator];
        NSDictionary *d;
        while (d = [holdEnum nextObject]) {
            if (([d objectForKey:@"durationWrapAroundRequired"]) && ([[d objectForKey:@"durationWrapAroundRequired"] boolValue] == YES)) {
                NSMutableDictionary *newD = [d mutableCopy];
                [newD removeObjectForKey:@"durationWrapAroundRequired"];
                [holdObjects removeObject:d];
                [holdObjects addObject:newD];
            }
        }
    }
    
#define kFlashDuration 10
    
    if ([holdObjects count] > 0) {
        NSArray *holdCopy = [NSArray arrayWithArray:holdObjects];
        NSEnumerator *holdEnum = [holdCopy objectEnumerator];
        NSDictionary *d;
        
        while (d = [holdEnum nextObject]) {
            if (([[d objectForKey:@"type"] isEqualToString:@"adpe"]) &&
                ((![d objectForKey:@"durationWrapAroundRequired"]) || ([[d objectForKey:@"durationWrapAroundRequired"] boolValue] == NO)) &&
                ([[d objectForKey:@"durationModel"] getCurrentState] > [[d objectForKey:@"durationState"] floatValue])) {
//                [[d objectForKey:@"parent"] deleteChildModel:[d objectForKey:@"object"]];
//                [world deleteChildModel:[d objectForKey:@"object"]];
                [holdObjects removeObject:d];
                
                //Now use target molecules for alignment...
                NSString *ADPTargetString = [NSString stringWithFormat:@"%d_ADPb", currentCatalysisPhase];
                modelObject *targetADP = [world getChildWithName:ADPTargetString];
                
                modelObject *transformedTargetADP = [[modelObject alloc] init];
                [transformedTargetADP addChildModel:targetADP];
                
                modelObject *model = [d objectForKey:@"parent"];
                modelObject *targetATPase = [model getChildWithName:@"childATPase"];
                modelObject *atpase = [world getChildWithName:@"atpase"];
                modelObject *subC = [world getChildWithName:@"subC"];
                modelObject *adpRotating = [d objectForKey:@"object"];
                modelObject *adp = [adpRotating getChildWithName:@"rotationADP"];

                [targetATPase transformIntoCurrentSystemModel:transformedTargetADP inSystemOfChild:atpase];
                
                Vector axis;
                float angle;
                Vector trans;
                [adpRotating targetMolecule:transformedTargetADP requiredRotationAxis:&axis requiredRotationAngle:&angle requiredTranslationVector:&trans];
                
                int targetState;
                switch (currentCatalysisPhase) {
                    case PHASE_1:
                    {
                        targetState = 60;
                        break;
                    }
                    case PHASE_2:
                    {
                        targetState = 120;
                        break;
                    }
                    case PHASE_3:
                    {
                        targetState = 0;
                        break;
                    }
                    default:
                        break;
                }
//                int transformationDuration = [subC calculateFramesToArriveAtState:targetState];
                
//                [adp animateRotationAroundAxis:axis byAngle:angle duration:transformationDuration];
                [adp animateRotationAroundAxis:axis byAngle:angle durationModel:subC durationTargetState:targetState];
//                [adpRotating animateLinearTranslationTo:trans duration:transformationDuration];
                [adpRotating animateLinearTranslationTo:trans durationModel:subC durationTargetState:targetState];
                
//                NSDictionary *adpInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"adpb", @"type",
//                                         adpRotating, @"object",
//                                         model, @"parent",
//                                         [NSNumber numberWithInt:f + transformationDuration], @"destFrame", nil];
//                [holdObjects addObject:adpInfo];

            }
            if (([[d objectForKey:@"type"] isEqualToString:@"po4e"]) &&
                ((![d objectForKey:@"durationWrapAroundRequired"]) || ([[d objectForKey:@"durationWrapAroundRequired"] boolValue] == NO)) &&
                ([[d objectForKey:@"durationModel"] getCurrentState] > [[d objectForKey:@"durationState"] floatValue])) {
//([[d objectForKey:@"destFrame"] intValue] == f)) {
//                [[d objectForKey:@"parent"] deleteChildModel:[d objectForKey:@"object"]];
//                [world deleteChildModel:[d objectForKey:@"object"]];
                [holdObjects removeObject:d];
                
                //Now use target molecules for alignment...
                NSString *PO4TargetString = [NSString stringWithFormat:@"%d_PO4b", currentCatalysisPhase];
                modelObject *targetPO4 = [world getChildWithName:PO4TargetString];
                
                modelObject *transformedTargetPO4 = [[modelObject alloc] init];
                [transformedTargetPO4 addChildModel:targetPO4];
                
                modelObject *model = [d objectForKey:@"parent"];
                modelObject *targetATPase = [model getChildWithName:@"childATPase"];
                modelObject *atpase = [world getChildWithName:@"atpase"];
                modelObject *subC = [world getChildWithName:@"subC"];
                modelObject *po4Rotating = [d objectForKey:@"object"];
                modelObject *po4 = [po4Rotating getChildWithName:@"po4"];
                modelObject *adpRotating = [d objectForKey:@"linkedADP"];

                
                [targetATPase transformIntoCurrentSystemModel:transformedTargetPO4 inSystemOfChild:atpase];
                
                Vector axis;
                float angle;
                Vector trans;
//                [po4Rotating logModelData];
//                [transformedTargetPO4 logModelData];
                [po4Rotating targetMolecule:transformedTargetPO4 requiredRotationAxis:&axis requiredRotationAngle:&angle requiredTranslationVector:&trans];
                
                int targetState;
                switch (currentCatalysisPhase) {
                    case PHASE_1:
                    {
                        targetState = 60;
                        break;
                    }
                    case PHASE_2:
                    {
                        targetState = 120;
                        break;
                    }
                    case PHASE_3:
                    {
                        targetState = 0;
                        break;
                    }
                    default:
                        break;
                }
                int transformationDuration = [subC calculateFramesToArriveAtState:targetState];
                
//                [po4 animateRotationAroundAxis:axis byAngle:angle duration:transformationDuration];
                [po4 animateRotationAroundAxis:axis byAngle:angle durationModel:subC durationTargetState:targetState];
//                [po4Rotating animateLinearTranslationTo:trans duration:transformationDuration];
                [po4Rotating animateLinearTranslationTo:trans durationModel:subC durationTargetState:targetState];
                
                NSDictionary *po4Info = [NSDictionary dictionaryWithObjectsAndKeys:@"po4b", @"type",
                                         po4Rotating, @"object",
                                         model, @"parent",
                                         adpRotating, @"linkedADP",
                                         subC, @"durationModel",
                                         [NSNumber numberWithInt:targetState], @"durationState",
                                         [NSNumber numberWithBool:([subC getCurrentState] > targetState)], @"durationWrapAroundRequired",
                                         [NSNumber numberWithInt:f], @"durationStartFrame",
                                         [NSNumber numberWithInt:f + transformationDuration + 1], @"destFrame", nil];
                [holdObjects addObject:po4Info];

            }
            if (([[d objectForKey:@"type"] isEqualToString:@"po4b"]) &&
                ((![d objectForKey:@"durationWrapAroundRequired"]) || ([[d objectForKey:@"durationWrapAroundRequired"] boolValue] == NO)) &&
                ([[d objectForKey:@"durationModel"] getCurrentState] > [[d objectForKey:@"durationState"] floatValue])) {
//([[d objectForKey:@"destFrame"] intValue] == f)) {
                [holdObjects removeObject:d];
                modelObject *po4Rotating = [d objectForKey:@"object"];
                modelObject *adpRotating = [d objectForKey:@"linkedADP"];
                modelObject *model = [d objectForKey:@"parent"];
                modelObject *targetATPase = [model getChildWithName:@"childATPase"];
                modelObject *atpase = [world getChildWithName:@"atpase"];
                modelObject *subC = [world getChildWithName:@"subC"];
                modelObject *adp = [adpRotating getChildWithName:@"rotationADP"];

                //Construct ATP from these parts...
                modelObject *po4 = [po4Rotating getChildWithName:@"po4"];
                
                modelObject *po4NoO = [world getChildWithName:@"po4ForATP"];
                modelObject *po4NoORotate = [[modelObject alloc] init];
                [po4NoORotate addChildModel:po4NoO];
                [po4 transformIntoCurrentSystemModel:po4NoORotate inSystemOfChild:po4];
                modelObject *po4NoOTranslate = [[modelObject alloc] init];
                [po4NoOTranslate addChildModel:po4NoORotate];
                [po4Rotating transformIntoCurrentSystemModel:po4NoOTranslate inSystemOfChild:po4Rotating];
//                [po4 deleteChildWithName:@"O4"];
//                [po4Rotating applyTransformation];
                
                modelObject *newATP = [[modelObject alloc] init];
                [newATP addChildModel:adpRotating];
                [newATP setName:@"adp" forChild:adpRotating];
                [newATP addChildModel:po4NoOTranslate];
                [newATP setName:@"po4" forChild:po4NoOTranslate];
//                [newATP addChildModel:po4Rotating];
//                [newATP setName:@"po4" forChild:po4Rotating];
                [newATP setPreviousFrame:f-1];
                [newATP setClipForModelTo:NO];
                
                [model deleteChildModel:po4Rotating];
                [model deleteChildModel:adpRotating];
                [model addChildModel:newATP];
                
                NSString *ATPTargetString = [NSString stringWithFormat:@"%d_ATP", currentCatalysisPhase];
                modelObject *targetATP = [world getChildWithName:ATPTargetString];
                
                modelObject *transformedTargetATP = [[modelObject alloc] init];
                [transformedTargetATP addChildModel:targetATP];
                [targetATPase transformIntoCurrentSystemModel:transformedTargetATP inSystemOfChild:atpase];
                
                Vector axis;
                Vector trans;
                float angle;
                [newATP targetMolecule:transformedTargetATP requiredRotationAxis:&axis requiredRotationAngle:&angle requiredTranslationVector:&trans];
                
                int targetState;
                switch (currentCatalysisPhase) {
                    case PHASE_1:
                    {
                        targetState = 60;
                        break;
                    }
                    case PHASE_2:
                    {
                        targetState = 120;
                        break;
                    }
                    case PHASE_3:
                    {
                        targetState = 0;
                        break;
                    }
                    default:
                        break;
                }
                int transformationDuration = [subC calculateFramesToArriveAtState:targetState];
                
                
//                [po4NoORotate animateRotationAroundAxis:axis byAngle:angle duration:transformationDuration];
                [po4NoORotate animateRotationAroundAxis:axis byAngle:angle durationModel:subC durationTargetState:targetState];
//                [po4 animateRotationAroundAxis:axis byAngle:angle durationModel:subC durationTargetState:targetState];
//                [adp animateRotationAroundAxis:axis byAngle:angle duration:transformationDuration];
                [adp animateRotationAroundAxis:axis byAngle:angle durationModel:subC durationTargetState:targetState];
                
//                [newATP animateLinearTranslationTo:trans duration:transformationDuration];
                [newATP animateLinearTranslationTo:trans durationModel:subC durationTargetState:targetState];
                
                NSDictionary *atpInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"atpb", @"type",
                                         newATP, @"object",
                                         model, @"parent",
                                         subC, @"durationModel",
                                         [NSNumber numberWithInt:targetState], @"durationState",
                                         [NSNumber numberWithBool:([subC getCurrentState] > targetState)], @"durationWrapAroundRequired",
                                         [NSNumber numberWithInt:f], @"durationStartFrame",
                                         [NSNumber numberWithInt:f + transformationDuration + 1], @"destFrame", nil];
                [holdObjects addObject:atpInfo];

                
            }
            if (([[d objectForKey:@"type"] isEqualToString:@"atpb"]) &&
//                ((![d objectForKey:@"durationWrapAroundRequired"]) || ([[d objectForKey:@"durationWrapAroundRequired"] boolValue] == NO)) &&
//                ([[d objectForKey:@"durationModel"] getCurrentState] >= [[d objectForKey:@"durationState"] floatValue]) &&
                ([[d objectForKey:@"durationModel"] calculateFramesToArriveAtState:[[d objectForKey:@"durationState"] floatValue]]  <= kFlashDuration) &&
                (![[d objectForKey:@"object"] hasIntrinsicColour])) {
//([[d objectForKey:@"destFrame"] intValue] - kFlashDuration - 1 == f)) {
                
                modelObject *atp = [d objectForKey:@"object"];
                
                [atp animateIntrinsicColourTo:atpFormationFlashColour withMaxDistance:25.0 mode:CRUDE_TWO_FACE duration:kFlashDuration];
                
                modelObject *po4 = [atp getChildWithName:@"po4"];
                //Pool objects have the object with colour as a child - therefore have no colour themselves. So set the colour for these selected ones now before animating...
                [po4 changeDiffuseColourTo:po4Colour];
                [po4 animateDiffuseColourTo:atpColour duration:kFlashDuration];
                modelObject *adp = [atp getChildWithName:@"adp"];
                [adp changeDiffuseColourTo:adpColour];
                [adp animateDiffuseColourTo:atpColour duration:kFlashDuration];
            }
            if (([[d objectForKey:@"type"] isEqualToString:@"atpb"]) &&
                ((![d objectForKey:@"durationWrapAroundRequired"]) || ([[d objectForKey:@"durationWrapAroundRequired"] boolValue] == NO)) &&
                ([[d objectForKey:@"durationModel"] getCurrentState] > [[d objectForKey:@"durationState"] floatValue])) {
//([[d objectForKey:@"destFrame"] intValue] == f)) {
                [holdObjects removeObject:d];
                
                modelObject *atp = [d objectForKey:@"object"];
                modelObject *model = [d objectForKey:@"parent"];
                modelObject *targetATPase = [model getChildWithName:@"childATPase"];
                modelObject *atpase = [world getChildWithName:@"atpase"];
                modelObject *subC = [world getChildWithName:@"subC"];

                [atp animateIntrinsicColourTo:blackColour withMaxDistance:25.0 mode:CRUDE_TWO_FACE duration:kFlashDuration];
                                
                NSString *ATPTargetString = [NSString stringWithFormat:@"%d_ATPh", currentCatalysisPhase];
                modelObject *targetATP = [world getChildWithName:ATPTargetString];
                
                modelObject *transformedTargetATP = [[modelObject alloc] init];
                [transformedTargetATP addChildModel:targetATP];
                [targetATPase transformIntoCurrentSystemModel:transformedTargetATP inSystemOfChild:atpase];
                
                Vector axis;
                Vector trans;
                float angle;
                [atp targetMolecule:transformedTargetATP requiredRotationAxis:&axis requiredRotationAngle:&angle requiredTranslationVector:&trans];
                
                int targetState;
                switch (currentCatalysisPhase) {
                    case PHASE_1:
                    {
                        targetState = 40;
                        break;
                    }
                    case PHASE_2:
                    {
                        targetState = 100;
                        break;
                    }
                    case PHASE_3:
                    {
                        targetState = 160;
                        break;
                    }
                    default:
                        break;
                }
//                int transformationDurationForRotation = [subC calculateFramesToArriveAtState:targetState - 20];
                int transformationDuration = [subC calculateFramesToArriveAtState:targetState];

                modelObject *po4 = [atp getChildWithName:@"po4"];
                modelObject *adp = [atp getChildWithName:@"adp"];
//                [po4 animateRotationAroundAxis:axis byAngle:angle duration:transformationDurationForRotation];
                [po4 animateRotationAroundAxis:axis byAngle:angle durationModel:subC durationTargetState:targetState - 20];
//                [adp animateRotationAroundAxis:axis byAngle:angle duration:transformationDurationForRotation];
                [adp animateRotationAroundAxis:axis byAngle:angle durationModel:subC durationTargetState:targetState - 20];
                
                Vector ATPHolding;
                switch (currentCatalysisPhase) {
                    case PHASE_1:
                        ATPHolding.x = -40.16; ATPHolding.y = 52.756; ATPHolding.z = 132.114; ATPHolding.w = 1.0;
                        break;
                    case PHASE_2:
                        ATPHolding.x = -25.51; ATPHolding.y = -60.013; ATPHolding.z = 132.114; ATPHolding.w = 1.0;
                        break;
                    case PHASE_3:
                        ATPHolding.x = 57.26; ATPHolding.y = 7.408; ATPHolding.z = 132.114; ATPHolding.w = 1.0;
                        break;
                    default:
                        break;
                }
                
                ATPHolding = [targetATPase transformCoordinate:ATPHolding inSystemOfChild:atpase];
                Vector start, i2, i1, end;
                
                end = trans;
                start.x = start.y = start.z = 0; start.w = 1.0;
                i1 = vector_lerp(start, end, 0.33);
                i2 = vector_lerp(start, end, 0.66);
                beizerCurve *transit = [[beizerCurve alloc] init];
                [transit addCurveWithStartPoint:start i1:i1 i2:i2 end:end];
                
                Vector translation = [atp positionAndRadiusOfEncompassingSphere];
                translation.w = 1.0;
                start = end;
                end = vector_subtract(ATPHolding, translation);
                i1 = vector_lerp(start, end, 0.33);
                i2 = vector_lerp(start, end, 0.66);
                [transit addCurveWithSymmetricalJoinWithI2:i2 end:end];
                
//                [atp animateTranslationAlongCurve:transit duration:transformationDuration];
                [atp animateTranslationAlongCurve:transit durationModel:subC durationTargetState:targetState];
                
                NSDictionary *atpInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"atpForMatrix", @"type",
                                         atp, @"object",
                                         model, @"parent",
                                         transit, @"curve",
                                         subC, @"durationModel",
                                         [NSNumber numberWithInt:targetState], @"durationState",
                                         [NSNumber numberWithBool:([subC getCurrentState] > targetState)], @"durationWrapAroundRequired",
                                         [NSNumber numberWithInt:f + kFlashDuration], @"flashDestination",
                                         [NSNumber numberWithInt:f + transformationDuration + 1], @"destFrame", nil];
                [holdObjects addObject:atpInfo];

            }
            if (([[d objectForKey:@"type"] isEqualToString:@"atpForMatrix"]) && ([[d objectForKey:@"flashDestination"] intValue] == f)) {
                modelObject *atp = [d objectForKey:@"object"];
                
                [atp animateIntrinsicColourTo:atpGlowColour withMaxDistance:10.0 mode:REAL_BROAD_SOURCE duration:kFlashDuration];

            }
            if (([[d objectForKey:@"type"] isEqualToString:@"atpForMatrix"]) &&
                ((![d objectForKey:@"durationWrapAroundRequired"]) || ([[d objectForKey:@"durationWrapAroundRequired"] boolValue] == NO)) &&
                ([[d objectForKey:@"durationModel"] getCurrentState] >= [[d objectForKey:@"durationState"] floatValue])) {
                    [holdObjects removeObject:d];
                    modelObject *fATP = [d objectForKey:@"object"];
                    modelObject *atpPool = [world getChildWithName:@"matrixATPPool"];
                    modelObject *atpase = [d objectForKey:@"parent"];
                    [atpase deleteAndTransformOutOfCoordSystemChildModel:fATP];
                    [atpPool addToPoolModel:fATP];
                    Vector momentum;
                    beizerCurve *transitPath = [d objectForKey:@"curve"];
                    momentum = vector_scale([transitPath getDerivativeAtT:1.0], 1.0 / (float)20);
                    Vector zero; zero.x = 0; zero.y = 0; zero.z = 0; zero.w = 0;

                    [fATP setDiffusionTranslateChangeVector:momentum rotateChangeVector:zero];

//                    [fATP setDiffusionTranslateChangeVector:zero rotateChangeVector:rChange];
            }
            if (([[d objectForKey:@"type"] isEqualToString:@"atpToDelete"]) && ([[d objectForKey:@"destFrame"] intValue] == f)) {
                [[d objectForKey:@"parent"] deleteChildModel:[d objectForKey:@"object"]];
                //                [world deleteChildModel:[d objectForKey:@"object"]];
                [holdObjects removeObject:d];
            }
            //Take a dark atpase and highlight it with the glow colour
            if (([[d objectForKey:@"type"] isEqualToString:@"atpToHighlight"]) && ([[d objectForKey:@"destFrame"] intValue] == f)) {
                int ATPtranslationStartState = 0;
                switch (currentCatalysisPhase) {
                    case PHASE_1:
                        ATPtranslationStartState = 40;
                        break;
                    case PHASE_2:
                        ATPtranslationStartState = 100;
                        break;
                    case PHASE_3:
                        ATPtranslationStartState = 160;
                        break;
                    default:
                        ATPtranslationStartState = 0;
                }
                
                [holdObjects removeObject:d];
                modelObject *fATP = [d objectForKey:@"object"];
                modelObject *targetATPase = [d objectForKey:@"parent"];
                int flashDuration = 5;
                [fATP animateIntrinsicColourTo:atpColour withMaxDistance:10.0 mode:REAL_BROAD_SOURCE duration:flashDuration];
                int requiredFrames = [subC calculateFramesToArriveAtState:ATPtranslationStartState];
                
                NSDictionary *atpInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"atpNoFlash", @"type",
                                         fATP, @"object",
                                         targetATPase, @"parent",
                                         [NSNumber numberWithInt:f + requiredFrames], @"destFrame", nil];
                [holdObjects addObject:atpInfo];
            }

        }
        
    }

}

- (void)sceneManagementForFrameATPFinal:(int)f {
    //Camera slow drift
    if (f == 0) {
        Vector destination, i1, i2;
        i1.x = 0; i1.y = -2; i1.z = -43;
        i1.w = 1;
        i2.x = 0; i2.y = -2; i2.z = -44;
        i2.w = 1;
        destination.z = -45; destination.x = 0; destination.y = -2; destination.w = 1;
        [camera animateViewOriginTranslationTo:destination intermediate1:i1 intermediate2:i2 duration:780];
    }

    
    //Phosphate flashes
    if (f == 435) {
        modelObject *pbo = [world getChildWithName:@"pbo"];
        RGBColour glowColour;
        glowColour.red = 0.6;
        glowColour.green = 0.6;
        glowColour.blue = 0.6;

        [pbo animateIntrinsicColourTo:glowColour withMaxDistance:5 mode:REAL_BROAD_SOURCE duration:7];
    }
    if (f == 442) {
        modelObject *pbo = [world getChildWithName:@"pbo"];
        RGBColour glowColour;
        glowColour.red = 0.0;
        glowColour.green = 0.0;
        glowColour.blue = 0.0;
        
        [pbo animateIntrinsicColourTo:glowColour withMaxDistance:5 mode:REAL_BROAD_SOURCE duration:7];
    }
    if (f == 456) {
        modelObject *pbo = [world getChildWithName:@"pbo"];
        RGBColour glowColour;
        glowColour.red = 0.6;
        glowColour.green = 0.6;
        glowColour.blue = 0.6;
        
        [pbo animateIntrinsicColourTo:glowColour withMaxDistance:5 mode:REAL_BROAD_SOURCE duration:7];
    }
    if (f == 463) {
        modelObject *pbo = [world getChildWithName:@"pbo"];
        RGBColour glowColour;
        glowColour.red = 0.0;
        glowColour.green = 0.0;
        glowColour.blue = 0.0;
        
        [pbo animateIntrinsicColourTo:glowColour withMaxDistance:5 mode:REAL_BROAD_SOURCE duration:7];
    }

    //Adenosine flash
    if (f == 569) {
        modelObject *adenosine = [world getChildWithName:@"adenosine"];
        RGBColour glowColour;
        glowColour.red = 0.6;
        glowColour.green = 0.6;
        glowColour.blue = 0.6;
        [adenosine animateIntrinsicColourTo:glowColour withMaxDistance:5 mode:REAL_BROAD_SOURCE duration:10];
    }
    if (f == 580) {
        modelObject *adenosine = [world getChildWithName:@"adenosine"];
        RGBColour glowColour;
        glowColour.red = 0.0;
        glowColour.green = 0.0;
        glowColour.blue = 0.0;
        [adenosine animateIntrinsicColourTo:glowColour withMaxDistance:5 mode:REAL_BROAD_SOURCE duration:10];
    }
    //Alpha po4
    if (f == 600) {
        modelObject *pa = [world getChildWithName:@"pa"];
        RGBColour glowColour;
        glowColour.red = 0.6;
        glowColour.green = 0.6;
        glowColour.blue = 0.6;
        [pa animateIntrinsicColourTo:glowColour withMaxDistance:5 mode:REAL_BROAD_SOURCE duration:10];
    }
    if (f == 610) {
        modelObject *pa = [world getChildWithName:@"pa"];
        RGBColour glowColour;
        glowColour.red = 0.0;
        glowColour.green = 0.0;
        glowColour.blue = 0.0;
        [pa animateIntrinsicColourTo:glowColour withMaxDistance:5 mode:REAL_BROAD_SOURCE duration:10];
    }
    //Beta po4
    if (f == 620) {
        modelObject *pb = [world getChildWithName:@"pb"];
        RGBColour glowColour;
        glowColour.red = 0.6;
        glowColour.green = 0.6;
        glowColour.blue = 0.6;
        [pb animateIntrinsicColourTo:glowColour withMaxDistance:5 mode:REAL_BROAD_SOURCE duration:10];
    }
    if (f == 630) {
        modelObject *pb = [world getChildWithName:@"pb"];
        RGBColour glowColour;
        glowColour.red = 0.0;
        glowColour.green = 0.0;
        glowColour.blue = 0.0;
        [pb animateIntrinsicColourTo:glowColour withMaxDistance:5 mode:REAL_BROAD_SOURCE duration:10];
    }
    //Gamma po4
    if (f == 640) {
        modelObject *pg = [world getChildWithName:@"pg"];
        RGBColour glowColour;
        glowColour.red = 0.6;
        glowColour.green = 0.6;
        glowColour.blue = 0.6;
        [pg animateIntrinsicColourTo:glowColour withMaxDistance:5 mode:REAL_BROAD_SOURCE duration:10];
    }
    if (f == 650) {
        modelObject *pg = [world getChildWithName:@"pg"];
        RGBColour glowColour;
        glowColour.red = 0.0;
        glowColour.green = 0.0;
        glowColour.blue = 0.0;
        [pg animateIntrinsicColourTo:glowColour withMaxDistance:5 mode:REAL_BROAD_SOURCE duration:10];
    }
    
    //Prepare for split off by adding extra O
    if (f == 750) {
        RGBColour specColour;
        specColour.red = 0.6;
        specColour.green = 0.6;
        specColour.blue = 0.6;
        
        RGBColour ATPColour;
        ATPColour.red = 0.8;
        ATPColour.green = 0.0;
        ATPColour.blue = 0.0;

        pdbData *pgoPDB = [[pdbData alloc] init];
        [pgoPDB setDiffuseColour:ATPColour specularColour:specColour shininess:50.0 mirrorFrac:0.3];
        pgoPDB.CPK = NO;
        [pgoPDB initWithPDBFile:@"/Users/stocklab/Documents/Callum/rt1SSS/rt1/structureData/ADP_O.pdb"];
        modelObject *pgo = [[modelObject alloc] initWithPDBData:pgoPDB];
        [pgo centerModelOnOrigin];
        
        modelObject *pgForRotate = [world getChildWithName:@"pgForRotation"];
        Vector offset; offset.x = 5.293-7.161; offset.y = -4.879+4.998; offset.z = -1.447+2.116;
        Vector transform = [pgForRotate currentTranslation];
        transform = vector_add(vector_scale(transform, -1.0), offset);
        [pgo translateToX:transform.x Y:transform.y Z:transform.z];
        [pgForRotate addChildModel:pgo];
        [world setName:@"pgo" forChild:pgo];
    }
    if (f == 760) {
        modelObject *pbo = [world getChildWithName:@"pbo"];
        RGBColour glowColour;
        glowColour.red = 1.0;
        glowColour.green = 1.0;
        glowColour.blue = 0.5;
        
        [pbo animateIntrinsicColourTo:glowColour withMaxDistance:5 mode:REAL_BROAD_SOURCE duration:10];

        modelObject *pgo = [world getChildWithName:@"pgo"];
        [pgo animateIntrinsicColourTo:glowColour withMaxDistance:5 mode:REAL_BROAD_SOURCE duration:10];
    }
    if (f == 780) {
        modelObject *pbo = [world getChildWithName:@"pbo"];
        RGBColour glowColour;
        glowColour.red = 0.0;
        glowColour.green = 0.0;
        glowColour.blue = 0.0;
        
        [pbo animateIntrinsicColourTo:glowColour withMaxDistance:5 mode:REAL_BROAD_SOURCE duration:5];
        
        modelObject *pgo = [world getChildWithName:@"pgo"];
        [pgo animateIntrinsicColourTo:glowColour withMaxDistance:5 mode:REAL_BROAD_SOURCE duration:5];

        Vector s, i1, i2, e;
        s.x = s.y = s.z = 0; s.w = 1.0;
        i1.x = 8; i1.y = 0; i1.z = 0; i1.w = 1.0;
        i2.x = 8; i2.y = 5; i2.z = 0; i2.w = 1.0;
        e.x = 6; e.y = 0; e.z = 0; e.w = 1.0;
        beizerCurve *split = [[beizerCurve alloc] init];
        [split addCurveWithStartPoint:s i1:i1 i2:i2 end:e];
        modelObject *pg = [world getChildWithName:@"pg"];
        [pg animateTranslationAlongCurve:split duration:20];
//        modelObject *pgForRotate = [world getChildWithName:@"pgForRotation"];
//        [pgForRotate enableDiffusionRotationWithMaxSpeed:0.05 rotChangeSize:0.005 initialVector:s];
        
        Vector destination;
        i1.x = 0; i1.y = -2; i1.z = -48;
        i1.w = 1;
        i2.x = 0; i2.y = -2; i2.z = -49;
        i2.w = 1;
        destination.z = -50; destination.x = 0; destination.y = -2; destination.w = 1;
        [camera animateViewOriginTranslationTo:destination intermediate1:i1 intermediate2:i2 duration:20];
        destination.z = 0; destination.x = 3; destination.y = -2; destination.w = 1;
        [camera animateViewLookAtTranslationTo:destination duration:20];
    }
    if (f == 800) {
        Vector destination, i1, i2;
        i1.x = 0; i1.y = -2; i1.z = -49;
        i1.w = 1;
        i2.x = 0; i2.y = -2; i2.z = -48;
        i2.w = 1;
        destination.z = -46; destination.x = 0; destination.y = -2; destination.w = 1;
        [camera animateViewOriginTranslationTo:destination intermediate1:i1 intermediate2:i2 duration:900];
        destination.z = 0; destination.x = 0; destination.y = -2; destination.w = 1;
        [camera animateViewLookAtTranslationTo:destination duration:900];
    }
    if (f == 1355) {
        Vector s, i1, i2, e;
        s.x = s.y = s.z = 0; s.w = 1.0;
        i1.x = -8; i1.y = 0; i1.z = 0; i1.w = 1.0;
        i2.x = -8; i2.y = -5; i2.z = 0; i2.w = 1.0;
        e.x = -6; e.y = 0; e.z = 0; e.w = 1.0;
        beizerCurve *split = [[beizerCurve alloc] init];
        [split addCurveWithStartPoint:s i1:i1 i2:i2 end:e];
        modelObject *pg = [world getChildWithName:@"pg"];
        [pg animateTranslationAlongCurve:split duration:30];
    }
    if (f == 1365) {
        modelObject *pbo = [world getChildWithName:@"pbo"];
        RGBColour glowColour;
        glowColour.red = 1.0;
        glowColour.green = 1.0;
        glowColour.blue = 0.5;
        
        [pbo animateIntrinsicColourTo:glowColour withMaxDistance:5 mode:REAL_BROAD_SOURCE duration:20];
        
        modelObject *pgo = [world getChildWithName:@"pgo"];
        [pgo animateIntrinsicColourTo:glowColour withMaxDistance:5 mode:REAL_BROAD_SOURCE duration:20];
    }
    if (f == 1385) {
        modelObject *pbo = [world getChildWithName:@"pbo"];
        RGBColour glowColour;
        glowColour.red = 0.0;
        glowColour.green = 0.0;
        glowColour.blue = 0.0;
        
        [pbo animateIntrinsicColourTo:glowColour withMaxDistance:5 mode:REAL_BROAD_SOURCE duration:10];
        
        modelObject *pgo = [world getChildWithName:@"pgo"];
        [pgo animateIntrinsicColourTo:glowColour withMaxDistance:5 mode:REAL_BROAD_SOURCE duration:10];
    }

}

- (void)sceneManagementForFrameATPase:(int)f {
    
//    if (f == 121) {
//        Vector destination, i1, i2;
//        destination.z = 350; destination.x = 0; destination.y = 0; destination.w = 1;
//        i1.x = 350; i1.y = 0; i1.z = -350;
//        i1.w = 1;
//        i2.x = 350; i2.y = 0; i2.z = 350;
//        i2.w = 1;
//        [camera animateViewOriginTranslationTo:destination intermediate1:i1 intermediate2:i2 duration:242];
//    }
    
//    if ((f % 20 == 0) && (f < 310)) {
//        modelObject *cpool = [world getChildWithName:@"cpool"];
//        modelObject *ppool = [world getChildWithName:@"protonPool"];
//        Vector intersection;
//        intersection.x = 0; intersection.y = 220; intersection.z = 50; intersection.w = 0;
//        modelObject *proton = [ppool releaseFromPoolModelClosestToPoint:intersection];
//        [cpool addToPoolModel:proton];
//    }
    
    //Proton translocation code
    /*if (f % 22 == 0) {
        int protonTranslocationDuration = 44;
        modelObject *protonPool = [world getChildWithName:@"protonPool"];
        modelObject *atpaseLeft = [world getChildWithName:@"atpaseLeft"];
        Vector atpasePos = [atpaseLeft currentTranslation];
        Vector ep;
        //Entry point for the first half channel - atpaseLeft coordinates
        ep.x = 27; ep.y = -11; ep.z = 10; ep.w = 1;
        //Transform to world coords
        ep = [atpaseLeft transformWithCurrentTransform:ep];
        modelObject *proton = [protonPool releaseFromPoolModelClosestToPoint:ep];
        beizerCurve *transitPath = [[beizerCurve alloc] init];
        Vector translationMomentum, rotationMomentum, start, i2, i1, end;
        start.x = start.y = start.z = 0; start.w = 1.0;
        end = vector_subtract(ep, [proton currentTranslation]);
        i2 = vector_lerp(start, end, 0.6);
        translationMomentum = [proton getDiffusionTranslationVectorAndEndDiffusionWithRotationChangeVector:&rotationMomentum];
        [transitPath addCurveWithStartPoint:start momentumVector:translationMomentum i2:i2 end:end];
        i1 = i2 = start = end;
        i1.y -= 7;
        i2.y -= 15;
        end.y -= 20;
        [transitPath addCurveWithI1:i1 i2:i2 end:end];
        //Have the proton jump to the second channel
        end.z -= 11;
        end.x += 10;
        i1 = i2 = start = end;
        i1.y -= 7;
        i2.y -= 15;
        i2.x -= 0;
        end.y -= 40;
        end.x -= 0;
        [transitPath addCurveWithStartPoint:start i1:i1 i2:i2 end:end];
//        [transitPath addCurveWithSymmetricalJoinWithI2:i2 end:end];
        i2 = end;
        end.y -= ([[randomNumberGenerator sharedInstance] getRandomUShort] / (float)UINT16_MAX) * 30 + 20;
        end.x += ([[randomNumberGenerator sharedInstance] getRandomShort] / (float)INT16_MAX) * 30;
        end.z += ([[randomNumberGenerator sharedInstance] getRandomUShort] / (float)UINT16_MAX) * 30;
        i2 = vector_lerp(i2, end, 0.5);
        [transitPath addCurveWithSymmetricalJoinWithI2:i2 end:end];
        [proton animateTranslationAlongCurve:transitPath duration:protonTranslocationDuration];
        [world addChildModel:proton];

        //Store info for later
        
        NSDictionary *protonInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"proton", @"type",
                                    proton, @"object",
                                    transitPath, @"curve",
                                    [NSNumber numberWithInt:f + protonTranslocationDuration], @"destFrame", nil];
        [holdObjects addObject:protonInfo];
        
        
        //Check if any protons have finished the transit
        NSArray *holdCopy = [NSArray arrayWithArray:holdObjects];
        NSEnumerator *holdEnum = [holdCopy objectEnumerator];
        NSDictionary *o;
        
        while (o = [holdEnum nextObject]) {
            if ([[o objectForKey:@"type"] isEqualToString:@"proton"]) {
                int destFrame = (int)[[o objectForKey:@"destFrame"] integerValue];
                if (f == destFrame) {
                    [holdObjects removeObject:o];
                    proton = [o objectForKey:@"object"];
                    modelObject *matrixPool = [world getChildWithName:@"matrixPool"];
                    [matrixPool addToPoolModel:proton];
                    Vector rot;
                    rot.x = rot.y = rot.z = rot.w = 0;
                    Vector momentum;
                    transitPath = [o objectForKey:@"curve"];
                    momentum = vector_scale([transitPath getDerivativeAtT:1.0], 1.0 / (float)protonTranslocationDuration);
                    [proton setDiffusionTranslateChangeVector:momentum rotateChangeVector:rot];
                }
            }
        }
        
    }
    
    //ADP and PO4 binding for PHASE open at frame 61
    if (f % 180 == 0) {
        int ADPToEntryPointDuration = 70 + (([[randomNumberGenerator sharedInstance] getRandomUShort] / (float)UINT16_MAX) * 20.0);
        int PO4ToEntryPointDuration = 60 + (([[randomNumberGenerator sharedInstance] getRandomUShort] / (float)UINT16_MAX) * 15.0);
//        ADPToEntryPointDuration = 10;
//        PO4ToEntryPointDuration = 10;
        modelObject *ADPPool = [world getChildWithName:@"matrixADPPool"];
        modelObject *PO4Pool = [world getChildWithName:@"matrixPO4Pool"];
        modelObject *atpase = [world getChildWithName:@"atpase"];
        modelObject *atpaseRotate = [world getChildWithName:@"atpaseRotate"];
        modelObject *atpaseLeft = [world getChildWithName:@"atpaseLeft"];
        Vector ep;
        //Entry point for this PHASE - atpase coordinates
        ep.x = -23.6; ep.y = 62.9; ep.z = 112.1; ep.w = 1;
        ep = [atpase transformWithCurrentTransform:ep];
        ep = [atpaseRotate transformWithCurrentTransform:ep];
        ep = [atpaseLeft transformWithCurrentTransform:ep];
        //Exchange point - atpase coordinates
        Vector ex; ex.x = -27.8; ex.y = 25.7; ex.z = 132.1; ex.w = 1;
        ex = [atpase transformWithCurrentTransform:ex];
        ex = [atpaseRotate transformWithCurrentTransform:ex];
        ex = [atpaseLeft transformWithCurrentTransform:ex];
        Vector he = vector_subtract(ex, ep);
        //i2 point for entry - atpase coordinates
        Vector ei2; ei2.x = -50; ei2.y = 70; ei2.z = 40; ei2.w = 1;
        ei2 = [atpase transformWithCurrentTransform:ei2];
        ei2 = [atpaseRotate transformWithCurrentTransform:ei2];
        ei2 = [atpaseLeft transformWithCurrentTransform:ei2];
        
        //ADP
        modelObject *adp = [ADPPool releaseFromPoolModelClosestToPoint:ep];
        RGBColour g;
        g.red = 0.0; g.blue = 0.0; g.green = 1.0;
        [adp changeDiffuseColourTo:g];
        beizerCurve *transitPathADP = [[beizerCurve alloc] init];
        Vector translationMomentum, rotationMomentum, start, i2, i1, end, rotation;
        start.x = start.y = start.z = 0; start.w = 1.0;
        Vector translation = [adp currentTranslation];
        end = vector_subtract(ep, translation);
        rotation = [adp getDiffusionRotationVector];
        translationMomentum = [adp getDiffusionTranslationVectorAndEndDiffusionWithRotationChangeVector:&rotationMomentum];
        [adp resetTransformation];
        [adp rotateAroundX:rotation.x Y:rotation.y Z:rotation.z];
        [adp enableDiffusionRotationWithMaxSpeed:0.1 rotChangeSize:0.01 initialVector:rotationMomentum];
        modelObject *adpRotating = [[modelObject alloc] init];
        [adpRotating addChildModel:adp];
        [adpRotating translateToX:translation.x Y:translation.y Z:translation.z];
        [transitPathADP addCurveWithStartPoint:start momentumVector:translationMomentum i2:ei2 end:end];
        translationMomentum = vector_scale(vector_subtract(end, ei2), 0.2);
        i1 = i2 = start = end;
        end = vector_add(end, he);
        Vector zero; zero.x = zero.y = zero.z = zero.w = 0;
        i2 = vector_add(i2, vector_lerp(zero, he, 0.5));
        i1 = vector_lerp(vector_add(start, translationMomentum), i2, 0.5);
        [transitPathADP addCurveWithI1:i1 i2:i2 end:end];
        //New model objects need the previous frame set
        if (f > 0) {
            [adpRotating setPreviousFrame:f - 1];
        }
        [adpRotating animateTranslationAlongCurve:transitPathADP duration:ADPToEntryPointDuration];
        [world addChildModel:adpRotating];
        NSDictionary *adpInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"adp61", @"type",
                                    adpRotating, @"object",
                                    [NSNumber numberWithInt:f + ADPToEntryPointDuration], @"destFrame", nil];
        [holdObjects addObject:adpInfo];
        
        //PO4
        modelObject *po4 = [PO4Pool releaseFromPoolModelClosestToPoint:ep];
        g.blue = 1.0;
        [po4 changeDiffuseColourTo:g];
        beizerCurve *transitPathPO4 = [[beizerCurve alloc] init];
        start.x = start.y = start.z = 0; start.w = 1.0;
        translation = [po4 currentTranslation];
        end = vector_subtract(ep, translation);
        rotation = [po4 getDiffusionRotationVector];
        translationMomentum = [po4 getDiffusionTranslationVectorAndEndDiffusionWithRotationChangeVector:&rotationMomentum];
        [po4 resetTransformation];
        [po4 rotateAroundX:rotation.x Y:rotation.y Z:rotation.z];
        [po4 enableDiffusionRotationWithMaxSpeed:0.1 rotChangeSize:0.01 initialVector:rotationMomentum];
        modelObject *po4Rotating = [[modelObject alloc] init];
        [po4Rotating addChildModel:po4];
        [po4Rotating translateToX:translation.x Y:translation.y Z:translation.z];
        [transitPathPO4 addCurveWithStartPoint:start momentumVector:translationMomentum i2:ei2 end:end];
        translationMomentum = vector_scale(vector_subtract(end, ei2), 0.2);
        i1 = i2 = start = end;
        end = vector_add(end, he);
        zero.x = zero.y = zero.z = zero.w = 0;
        i2 = vector_add(i2, vector_lerp(zero, he, 0.5));
        i1 = vector_lerp(vector_add(start, translationMomentum), i2, 0.5);
        [transitPathPO4 addCurveWithI1:i1 i2:i2 end:end];
        if (f > 0) {
            [po4Rotating setPreviousFrame:f - 1];
        }
        [po4Rotating animateTranslationAlongCurve:transitPathPO4 duration:PO4ToEntryPointDuration];
        [world addChildModel:po4Rotating];
        NSDictionary *po4Info = [NSDictionary dictionaryWithObjectsAndKeys:@"po461", @"type",
                                 po4Rotating, @"object",
                                 [NSNumber numberWithInt:f + PO4ToEntryPointDuration], @"destFrame", nil];
        [holdObjects addObject:po4Info];

        //Check there are no ATP molecules to end the flash for...
        NSArray *holdCopy = [NSArray arrayWithArray:holdObjects];
        NSEnumerator *holdEnum = [holdCopy objectEnumerator];
        NSDictionary *o;
        
        while (o = [holdEnum nextObject]) {
            if ([[o objectForKey:@"type"] isEqualToString:@"atp1"]) {
                int destFrame = (int)[[o objectForKey:@"destFrame"] integerValue];
                if (f == destFrame) {
                    [holdObjects removeObject:o];
                    modelObject *fATP = [o objectForKey:@"object"];
                    RGBColour blackColour; blackColour.red = 0.0; blackColour.green = 0.0; blackColour.blue = 0.0;
                    int flashDuration = 5;
                    [fATP animateIntrinsicColourTo:blackColour withMaxDistance:10 mode:CRUDE_TWO_FACE duration:flashDuration];
                    int translationStartFrame = f + flashDuration + 35;
                    NSDictionary *atpInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"atp1", @"type",
                                             fATP, @"object",
                                             [NSNumber numberWithInt:translationStartFrame], @"destFrame", nil];
                    [holdObjects addObject:atpInfo];
                }
            }
        }

    }
    
    //Start the ATP flash
    if (f % 180 == 175) {
        int flashDuration = 5;
        modelObject *atpase = [world getChildWithName:@"atpase"];
        modelObject *atpaseRotate = [world getChildWithName:@"atpaseRotate"];
        modelObject *atpaseLeft = [world getChildWithName:@"atpaseLeft"];

        Vector atpN6; atpN6.x = 7.62; atpN6.y = -3.84; atpN6.z = -1.41; atpN6.w = 1.0;
        Vector atpO; atpO.x = -3.04; atpO.y = 2.76; atpO.z = 5.82; atpO.w = 1.0;
        Vector atpOrient = unit_vector(vector_subtract(atpO, atpN6));
        
        Vector f1; f1.x = -13.26; f1.y = 22.68; f1.z = 148.89; f1.w = 1.0;
        Vector f2; f2.x = -22.08; f2.y = 21.50; f2.z = 138.02; f2.w = 1.0;
        f1 = [atpase transformWithCurrentTransform:f1];
        f1 = [atpaseRotate transformWithCurrentTransform:f1];
        f1 = [atpaseLeft transformWithCurrentTransform:f1];
        f2 = [atpase transformWithCurrentTransform:f2];
        f2 = [atpaseRotate transformWithCurrentTransform:f2];
        f2 = [atpaseLeft transformWithCurrentTransform:f2];

        Vector fOrient = unit_vector(vector_subtract(f1, f2));
        Vector rotationAxis = vector_cross(atpOrient, fOrient);
        float angle = acosf(vector_dot_product(atpOrient, fOrient));
        modelObject *atp = [world getChildWithName:@"ATP"];
        modelObject *orientedATP = [[modelObject alloc] init];
        if (f > 0) {
            [orientedATP setPreviousFrame:f - 1];
        }
        [orientedATP addChildModel:atp];
        [orientedATP rotateAroundVector:rotationAxis byAngle:angle];
        
        //This object for the rotation diffusion on exit
        modelObject *rATP = [[modelObject alloc] init];
        [rATP addChildModel:orientedATP];
        
        modelObject *fATP = [[modelObject alloc] init];
        [fATP addChildModel:rATP];
        Vector flash; flash.x = -18.12; flash.y = 19.82; flash.z = 137.44; flash.w = 1.0;
        flash = [atpase transformWithCurrentTransform:flash];
        flash = [atpaseRotate transformWithCurrentTransform:flash];
        flash = [atpaseLeft transformWithCurrentTransform:flash];
        [fATP translateToX:flash.x Y:flash.y Z:flash.z];
        RGBColour whiteColour;
        whiteColour.red = 0.05; whiteColour.green = 0.05; whiteColour.blue = 0.05;
        [fATP animateIntrinsicColourTo:whiteColour withMaxDistance:20.0 mode:CRUDE_TWO_FACE duration:flashDuration];
        [world addChildModel:fATP];

        [fATP setName:@"rATP" forChild:rATP];

        NSDictionary *atpInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"atp1", @"type",
                                 fATP, @"object",
                                 [NSNumber numberWithInt:f + flashDuration], @"destFrame", nil];
        [holdObjects addObject:atpInfo];
    }
    
    //Start the ATP leaving the PHASE...
    if (f % 180 == 40) {
        NSArray *holdCopy = [NSArray arrayWithArray:holdObjects];
        NSEnumerator *holdEnum = [holdCopy objectEnumerator];
        NSDictionary *o;
        
        while (o = [holdEnum nextObject]) {
            if ([[o objectForKey:@"type"] isEqualToString:@"atp1"]) {
                int destFrame = (int)[[o objectForKey:@"destFrame"] integerValue];
                if (f == destFrame) {
                    [holdObjects removeObject:o];
                    int exitDuration = 30;
                    modelObject *fATP = [o objectForKey:@"object"];
                    modelObject *atpase = [world getChildWithName:@"atpase"];
                    modelObject *atpaseRotate = [world getChildWithName:@"atpaseRotate"];
                    modelObject *atpaseLeft = [world getChildWithName:@"atpaseLeft"];

                    Vector ATPHolding; ATPHolding.x = -40.16; ATPHolding.y = 52.756; ATPHolding.z = 132.114; ATPHolding.w = 1.0;
                    ATPHolding = [atpase transformWithCurrentTransform:ATPHolding];
                    ATPHolding = [atpaseRotate transformWithCurrentTransform:ATPHolding];
                    ATPHolding = [atpaseLeft transformWithCurrentTransform:ATPHolding];
                    Vector end;
                    Vector translation = [fATP currentTranslation];
                    end = vector_subtract(ATPHolding, translation);
                    [fATP animateLinearTranslationTo:end duration:exitDuration];
                    
                    modelObject *rATP = [fATP getChildWithName:@"rATP"];
                    Vector zero; zero.x = 0; zero.y = 0; zero.z = 0; zero.w = 0;
                    [rATP enableDiffusionRotationWithMaxSpeed:0.1 rotChangeSize:0.01 initialVector:zero];

                    NSDictionary *atpInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"atp1", @"type",
                                             fATP, @"object",
                                             [NSNumber numberWithInt:f + exitDuration], @"destFrame", nil];
                    [holdObjects addObject:atpInfo];

                }
            }
        }
    }
    
    if (f % 180 == 70) {
        NSArray *holdCopy = [NSArray arrayWithArray:holdObjects];
        NSEnumerator *holdEnum = [holdCopy objectEnumerator];
        NSDictionary *o;
        
        while (o = [holdEnum nextObject]) {
            if ([[o objectForKey:@"type"] isEqualToString:@"atp1"]) {
                int destFrame = (int)[[o objectForKey:@"destFrame"] integerValue];
                if (f == destFrame) {
                    [holdObjects removeObject:o];
                    modelObject *fATP = [o objectForKey:@"object"];
                    modelObject *atpPool = [world getChildWithName:@"matrixATPPool"];
                    modelObject *rATP = [fATP getChildWithName:@"rATP"];
                    Vector rChange = [rATP getDiffusionRotateChangeAndEndRotationDiffusion];
                    [atpPool addToPoolModel:fATP];
                    [world deleteChildModel:fATP];
                    Vector zero; zero.x = 0; zero.y = 0; zero.z = 0; zero.w = 0;
                    [fATP setDiffusionTranslateChangeVector:zero rotateChangeVector:rChange];
                }
            }
        }
    }
    
    if ([holdObjects count] > 0) {
        NSArray *holdCopy = [NSArray arrayWithArray:holdObjects];
        NSEnumerator *holdEnum = [holdCopy objectEnumerator];
        NSDictionary *d;
        
        while (d = [holdEnum nextObject]) {
            if (([[d objectForKey:@"type"] isEqualToString:@"adp61"]) && ([[d objectForKey:@"destFrame"] intValue] == f)) {
                [world deleteChildModel:[d objectForKey:@"object"]];
                [holdObjects removeObject:d];
            }
            if (([[d objectForKey:@"type"] isEqualToString:@"po461"]) && ([[d objectForKey:@"destFrame"] intValue] == f)) {
                [world deleteChildModel:[d objectForKey:@"object"]];
                [holdObjects removeObject:d];
            }
        }
    }*/
    
    
    
    /*if (f == 20) {
     RGBColour n;
     n.red = 0.1;
     n.green = 0.8;
     n.blue = 0;
     [objRed animateDiffuseColourTo:n duration:30];
     Vector destination;
     destination.x = 0; destination.y = 10; destination.z = 0; destination.w = 1;
     [objRed animateLinearTranslationTo:destination duration:30];
     [objRed animateRotationAroundX:90 * radiansPerDegree Y:0 Z:0 duration:30];
     }*/
    
    /*if (f == 20) {
     Vector destination, i1, i2;
     destination.x = 0; destination.y = 10; destination.z = 0; destination.w = 1;
     i1.x = 10; i1.y = 0; i1.z = 0;
     i1.w = 1;
     i2.x = 10; i2.y = 10; i2.z = 0;
     i2.w = 1;
     //        [world animateTranslationTo:destination intermediate1:i1 intermediate2:i2 duration:30];
     //        [group animateLinearTranslationTo:destination duration:30];
     [group animateRotationAroundX:90 * radiansPerDegree Y:0 * radiansPerDegree Z:0 duration:20];
     }*/
    
    /*if (f == 55) {
     RGBColour n;
     n.red = 0.5;
     n.green = 0.1;
     n.blue = 0;
     [objRed animateDiffuseColourTo:n duration:30];
     [objRed animateRotationAroundX:-90 * radiansPerDegree Y:0 Z:0 duration:30];
     }
     if (f == 55) {
     Vector destination, i1, i2;
     destination.x = 0; destination.y = 10; destination.z = 0; destination.w = 1;
     i1.x = 10; i1.y = 0; i1.z = 0;
     i1.w = 1;
     i2.x = 10; i2.y = 10; i2.z = 0;
     i2.w = 1;
     //        [world animateTranslationTo:destination intermediate1:i1 intermediate2:i2 duration:30];
     //        [group animateLinearTranslationTo:destination duration:30];
     [group animateRotationAroundX:0 Y:0 Z:600 * radiansPerDegree duration:600];
     //        [group animateRotationAroundX:00 * radiansPerDegree Y:90 * radiansPerDegree Z:0 duration:30];
     }
     
     if (f == 90) {
     [objRed animateRotationAroundX:-90 * radiansPerDegree Y:0 Z:0 duration:30];
     }*/
    
    
    /*if (f == 45) {
     Vector destination;
     destination.x = 15; destination.y = 0; destination.z = 0; destination.w = 1;
     [camera animateViewLookAtTranslationTo:destination duration:30];
     }*/
    /*if (f == 75) {
     Vector destination;
     destination.x = -15; destination.y = 0; destination.z = 0; destination.w = 1;
     [camera animateViewLookAtTranslationTo:destination duration:30];
     }
     if (f == 105) {
     Vector destination, i1, i2;
     destination.z = -60; destination.x = -20; destination.y = -20; destination.w = 1;
     i1.x = 0; i1.y = 0; i1.z = -70;
     i1.w = 1;
     i2.x = 0; i2.y = 0; i2.z = -70;
     i2.w = 1;
     [camera animateViewOriginTranslationTo:destination intermediate1:i1 intermediate2:i2 duration:30];
     }
     if (f == 135) {
     camera.focalLength = 55;
     [camera animateApertureTo:2.0 duration:30];
     }
     if (f == 165) {
     [camera animateFocalLenghTo:65 duration:60];
     }
     if (f == 225) {
     Vector destination, i1, i2;
     destination.z = -100; destination.x = 15; destination.y = 0; destination.w = 1;
     i1.x = 30; i1.y = 30; i1.z = -60;
     i1.w = 1;
     i2.x = 30; i2.y = 30; i2.z = -100;
     i2.w = 1;
     [camera animateViewOriginTranslationTo:destination intermediate1:i1 intermediate2:i2 duration:30];
     [camera animateApertureTo:0 duration:30];
     destination.x = 15; destination.y = 0; destination.z = 0; destination.w = 1;
     [camera animateViewLookAtTranslationTo:destination duration:30];
     }
     if (f == 255) {
     [camera animateLensLengthTo:100 duration:30];
     }*/
    
}

@end
