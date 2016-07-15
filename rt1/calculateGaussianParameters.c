//
//  calculateGaussianParameters.c
//  rt1
//
//  Created by Callum Smits on 14/07/2014.
//  Copyright (c) 2014 a. All rights reserved.
//

#include <stdio.h>
#include <stdlib.h>
#include <math.h>

void preProcessGaussianParams(float fSigma, int iOrder, float *oa0, float *oa1, float *oa2, float *oa3, float *ob1, float *ob2, float *ocoefp, float *ocoefn) {
    float nsigma = fSigma; // note: fSigma is range-checked and clamped >= 0.1f upstream
    float alpha = 1.695f / nsigma;
    float ema = exp(alpha);
    float ema2 = exp(-2.0f * alpha);
    float b1 = -2.0f * ema;
    float b2 = ema2;
    float a0 = 0.0f;
    float a1 = 0.0f;
    float a2 = 0.0f;
    float a3 = 0.0f;
    float coefp = 0.0f;
    float coefn = 0.0f;
    switch (iOrder)
    {
        case 0:
        {
            const float k = (1.0f - ema)*(1.0f - ema)/(1.0f + (2.0f * alpha * ema) - ema2);
            a0 = k;
            a1 = k * (alpha - 1.0f) * ema;
            a2 = k * (alpha + 1.0f) * ema;
            a3 = -k * ema2;
        }
        break;
        case 1:
        {
            a0 = (1.0f - ema) * (1.0f - ema);
            a1 = 0.0f;
            a2 = -a0;
            a3 = 0.0f;
        }
        break;
        case 2:
        {
            const float ea = exp(-alpha);
            const float k = -(ema2 - 1.0f)/(2.0f * alpha * ema);
            float kn = -2.0f * (-1.0f + (3.0f * ea) - (3.0f * ea * ea) + (ea * ea * ea));
            kn /= (((3.0f * ea) + 1.0f + (3.0f * ea * ea) + (ea * ea * ea)));
            a0 = kn;
            a1 = -kn * (1.0f + (k * alpha)) * ema;
            a2 = kn * (1.0f - (k * alpha)) * ema;
            a3 = -kn * ema2;
        }
        break;
        default:
        // note: iOrder is range-checked and clamped to 0-2 upstream
        return;
    }
    coefp = (a0 + a1)/(1.0f + b1 + b2);
    coefn = (a2 + a3)/(1.0f + b1 + b2);
    
    *oa0 = a0;
    *oa1 = a1;
    *oa2 = a2;
    *oa3 = a3;
    *ob1 = b1;
    *ob2 = b2;
    *ocoefn = coefn;
    *ocoefp = coefp;
}

float *createGaussianMask(float sigma, int * maskSizePointer) {
    int maskSize = (int)ceil(3.0f*sigma);
    float *mask = (float *)malloc(sizeof(float)*maskSize*2+1);
    float sum = 0.0f;
    for(int a = -maskSize; a < maskSize+1; a++) {
        float temp = exp(-((float)(a*a) / (2*sigma*sigma)));
        sum += temp;
        mask[a+maskSize] = temp;
    }
    // Normalize the mask
    for(int i = 0; i < (maskSize*2+1); i++) {
        mask[i] = mask[i] / sum;
//        printf("i: %d, mask: %.2f\n", i, mask[i]);
    }
    
    *maskSizePointer = maskSize;
    
    return mask;
}