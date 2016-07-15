//
//  NABaseModelObject.h
//  rt1
//
//  Created by Callum Smits on 15/08/2014.
//  Copyright (c) 2014 a. All rights reserved.
//

#import "modelObject.h"
#import "NABasePDBData.h"

@interface NABaseModelObject : modelObject

- (id)initWithBase:(NSString *)base naType:(uint)type;
- (Vector)defaultModelOrientation;
- (Vector)defaultAxisOrientation;

@end
