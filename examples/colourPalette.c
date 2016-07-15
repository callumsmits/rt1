//
//  colourPalette.c
//  rt1
//
//  Created by Callum Smits on 28/08/2014.
//  Copyright (c) 2014 a. All rights reserved.
//

#include <stdio.h>
#import "colourPalette.h"

void setupFlagellarColours() {
    
    shaftColour.red = 106/255.0;
    shaftColour.green = 125/255.0;
    shaftColour.blue = 139/255.0;

    fliFColour.red = 71/255.0;
    fliFColour.green = 101/255.0;
    fliFColour.blue = 124/255.0;

    fliGColour.red = 41/255.0;
    fliGColour.green = 80/255.0;
    fliGColour.blue = 109/255.0;

    fliMColour.red = 17/255.0;
    fliMColour.green = 61/255.0;
    fliMColour.blue = 94/255.0;

    fliNColour.red = 4/255.0;
    fliNColour.green = 17/255.0;
    fliNColour.blue = 79/255.0;

    motAColour.red = 193/255.0;
    motAColour.green = 155/255.0;
    motAColour.blue = 104/255.0;

    motBColour.red = 170/255.0;
    motBColour.green = 121/255.0;
    motBColour.blue = 67/255.0;

    outMemColour.red = 0/255.0;
    outMemColour.green = 74/255.0;
    outMemColour.blue = 74/255.0;

    innerMemColour.red = 34/255.0;
    innerMemColour.green = 102/255.0;
    innerMemColour.blue = 102/255.0;

    pgcnColour.red = 97/255.0;
    pgcnColour.green = 130/255.0;
    pgcnColour.blue = 130/255.0;

    blackColour.red = 0.00;
    blackColour.green = 0.00;
    blackColour.blue = 0.00;
    
    specColour.red = 0.25;
    specColour.green = 0.25;
    specColour.blue = 0.25;
    
    protonColour.red = 0.0;
    protonColour.green = 0.0;
    protonColour.blue = 0.0;
    
    protonGlowColour.red = 1.0;
    protonGlowColour.green = 1.0;
    protonGlowColour.blue = 0.5;

    atpFormationFlashColour.red = 0.05;
    atpFormationFlashColour.green = 0.05;
    atpFormationFlashColour.blue = 0.05;
    
    subMColour.red = 124/255.0;
    subMColour.green = 71/255.0;
    subMColour.blue = 0/255.0;
    
    subAColour.red = 216/255.0;
    subAColour.green = 193/255.0;
    subAColour.blue = 161/255.0;
    
    subBColour.red = 193/255.0;
    subBColour.green = 155/255.0;
    subBColour.blue = 104/255.0;
    
    subCColour.red = 147/255.0;
    subCColour.green = 92/255.0;
    subCColour.blue = 19/255.0;
    
    subGColour.red = 170/255.0;
    subGColour.green = 121/255.0;
    subGColour.blue = 67/255.0;
    
    subDColour.red = 193/255.0;
    subDColour.green = 155/255.0;
    subDColour.blue = 104/255.0;
    
    subEColour.red = 170/255.0;
    subEColour.green = 121/255.0;
    subEColour.blue = 67/255.0;
    
    stalkColour.red = 170/255.0;
    stalkColour.green = 108/255.0;
    stalkColour.blue = 67/255.0;

    bARColour.red = 147/255.0;
    bARColour.green = 77/255.0;
    bARColour.blue = 19/255.0;
}

void setupRichardColors() {
    
    blackColour.red = 0.00;
    blackColour.green = 0.00;
    blackColour.blue = 0.00;
    
    specColour.red = 0.25;
    specColour.green = 0.25;
    specColour.blue = 0.25;
    
    protonColour.red = 0.0;
    protonColour.green = 0.0;
    protonColour.blue = 0.0;
    
    protonGlowColour.red = 1.0;
    protonGlowColour.green = 1.0;
    protonGlowColour.blue = 0.5;
    
    com1Colour.red = 149/255.0;
    com1Colour.green = 254/255.0;
    com1Colour.blue = 254/255.0;
    
    com3Colour.red = 35/255.0;
    com3Colour.green = 162/255.0;
    com3Colour.blue = 162/255.0;
    
    com4Colour.red = 255/255.0;
    com4Colour.green = 0/255.0;
    com4Colour.blue = 0/255.0;
    
    cytoCColour.red = 48/255.0;
    cytoCColour.green = 146/255.0;
    cytoCColour.blue = 48/255.0;
    
    subMColour.red = 230/255.0;
    subMColour.green = 230/255.0;
    subMColour.blue = 230/255.0;
    
    subAColour.red = 33/255.0;
    subAColour.green = 62/255.0;
    subAColour.blue = 135/255.0;
    
    subBColour.red = 117/255.0;
    subBColour.green = 56/255.0;
    subBColour.blue = 140/255.0;
    
    subCColour.red = 30/255.0;
    subCColour.green = 30/255.0;
    subCColour.blue = 30/255.0;
    
    subGColour.red = 43/255.0;
    subGColour.green = 60/255.0;
    subGColour.blue = 152/255.0;
    
    subDColour.red = 29/255.0;
    subDColour.green = 133/255.0;
    subDColour.blue = 80/255.0;
    
    subEColour.red = 213/255.0;
    subEColour.green = 82/255.0;
    subEColour.blue = 164/255.0;
    
    stalkColour.red = 116/255.0;
    stalkColour.green = 188/255.0;
    stalkColour.blue = 76/255.0;
    
    popcColour.red = 0.85;
    popcColour.green = 0.85;
    popcColour.blue = 1.0;
    
    adpColour.red = 12/255.0;
    adpColour.green = 162/255.0;
    adpColour.blue = 249/255.0;
    
    po4Colour.red = 52/255.0;
    po4Colour.green = 193/255.0;
    po4Colour.blue = 14/255.0;
    
    atpColour.red = 190/255.0;
    atpColour.green = 13/255.0;
    atpColour.blue = 241/255.0;

    atpGlowDiffuseColour.red = 190/255.0;
    atpGlowDiffuseColour.green = 13/255.0;
    atpGlowDiffuseColour.blue = 241/255.0;

    atpGlowColour.red = 75/255.0;
    atpGlowColour.green = 75/255.0;
    atpGlowColour.blue = 75/255.0;
    
    atpFormationFlashColour.red = 0.05;
    atpFormationFlashColour.green = 0.05;
    atpFormationFlashColour.blue = 0.05;

    backboneColour.red = 220/255.0;
    backboneColour.green = 220/255.0;
    backboneColour.blue = 220/255.0;
    
    turquoiseColour.red = 81/255.0;
    turquoiseColour.green = 222/255.0;
    turquoiseColour.blue = 252/255.0;
    
    yellowColour.red = 253/255.0;
    yellowColour.green = 244/255.0;
    yellowColour.blue = 23/255.0;

}

void setupOurColours() {
    
    specColour.red = 0.25;
    specColour.green = 0.25;
    specColour.blue = 0.25;
    
    protonColour.red = 0.0;
    protonColour.green = 0.0;
    protonColour.blue = 0.0;
    
    protonGlowColour.red = 1.0;
    protonGlowColour.green = 1.0;
    protonGlowColour.blue = 0.5;
    
    subMColour.red = 0.2;
    subMColour.green = 0;
    subMColour.blue = 1.0;
    
    subAColour.red = 0.0;
    subAColour.green = 0.3;
    subAColour.blue = 1.0;
    
    subBColour.red = 0.0;
    subBColour.green = 0.5;
    subBColour.blue = 1.0;
    
    subCColour.red = 0.0;
    subCColour.green = 0.0;
    subCColour.blue = 1.0;
    
    subGColour.red = 0.3;
    subGColour.green = 0.3;
    subGColour.blue = 1.0;
    
    subDColour.red = 0.1;
    subDColour.green = 0.1;
    subDColour.blue = 1.0;
    
    subEColour.red = 0.2;
    subEColour.green = 0.2;
    subEColour.blue = 1.0;
    
    stalkColour.red = 0.2;
    stalkColour.green = 0.0;
    stalkColour.blue = 1.0;
    
    popcColour.red = 0.85;
    popcColour.green = 0.85;
    popcColour.blue = 1.0;
    
    po4GlowColour.red = 1.0;
    po4GlowColour.green = 1.0;
    po4GlowColour.blue = 0.8;

}

void initColours() {
    setupFlagellarColours();
}
