//
//  calculateGaussianParameters.h
//  rt1
//
//  Created by Callum Smits on 14/07/2014.
//  Copyright (c) 2014 a. All rights reserved.
//

#ifndef rt1_calculateGaussianParameters_h
#define rt1_calculateGaussianParameters_h

void preProcessGaussianParams(float fSigma, int iOrder, float *oa0, float *oa1, float *oa2, float *oa3, float *ob1, float *ob2, float *ocoefp, float *ocoefn);
float *createGaussianMask(float sigma, int * maskSizePointer);

#endif
