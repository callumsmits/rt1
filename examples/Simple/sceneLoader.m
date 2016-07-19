//
//  sceneLoader.m
//  rt1
//
//  Created by Stock Lab on 8/05/2014.
//  Copyright (c) 2014 a. All rights reserved.
//

#import "sceneLoader.h"
#import "beizerCurve.h"
#import "NAModelObject.h"
#import "colourPalette.h"
#import "vector_ops.h"

@interface sceneLoader () {
    dispatch_group_t _dispatch_group;
}

@end

@implementation sceneLoader

- (id)init {
    
    if (self = [super init]) {
        _dispatch_group = dispatch_group_create();
    }
    
    return self;
}


- (modelObject *)loadScene {
    NSLog(@"Loading data");
    
    NSString *modelDirectory = [NSString stringWithFormat:@"%@/%@", NSHomeDirectory(), @"Documents/Development/rt1/examples/structureData/"];
    
    RGBColour diffuse;
    diffuse.red = 37/255.0; diffuse.green = 169/255.0; diffuse.blue = 33/255.0;
    
    RGBColour specular;
    specular.red = 0.6; specular.green = 0.6; specular.blue = 0.6;
    
    
    pdbData *proteinPDB = [[pdbData alloc] init];
    [proteinPDB setDiffuseColour:diffuse specularColour:specular shininess:50 mirrorFrac:0];
    proteinPDB.CPK = NO;
    NSString *proteinPath = [modelDirectory stringByAppendingString:@"2WC9.pdb"];
    [proteinPDB initWithPDBFile:proteinPath];

    modelObject *protein = [[modelObject alloc] initWithPDBData:proteinPDB];
    [protein centerModelOnOrigin];
    
    modelObject *newWorld = [[modelObject alloc] init];
    [newWorld addChildModel:protein];
    [newWorld setName:@"protein" forChild:protein];
    
    [newWorld enableWobbleWithMaxRadius:1.0 changeVectorSize:0.5];
    
    NSLog(@"Finished");
    
    return newWorld;

}

@end
