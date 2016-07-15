//
//  NABasePDBData.h
//  rt1
//
//  Created by Callum Smits on 15/08/2014.
//  Copyright (c) 2014 a. All rights reserved.
//

#import "pdbData.h"

#define kNucleicAcidTypeDNA 0
#define kNucleicAcidTypeRNA 1

@interface NABasePDBData : pdbData

- (id)initWithBase:(NSString *)base naType:(uint)type;

@end
