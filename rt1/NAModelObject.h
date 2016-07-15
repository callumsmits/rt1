//
//  NAModelObject.h
//  rt1
//
//  Created by Callum Smits on 15/08/2014.
//  Copyright (c) 2014 a. All rights reserved.
//

#import "modelObject.h"
#import "NABasePDBData.h"

@interface NAModelObject : modelObject

- (id)initWithCurve:(beizerCurve *)c initialOffset:(float)offset initialTwist:(float)it helicalTwist:(float)ht helicalRise:(float)hr nucleicAcidType:(unsigned int)type sequence:(NSString *)s;
- (void)constructNAWithInitialOffset:(float)offset initialTwist:(float)it helicalTwist:(float)ht helicalRise:(float)hr nucleicAcidType:(unsigned int)type;

@end
