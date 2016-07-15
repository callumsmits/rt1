__constant sampler_t sampler = CLK_FILTER_NEAREST;
__constant sampler_t blurSampler = CLK_ADDRESS_CLAMP_TO_EDGE | CLK_FILTER_NEAREST;

typedef enum _atomData
    {
        X,
        Y,
        Z,
        VDW,
        DIFFUSE_R,
        DIFFUSE_G,
        DIFFUSE_B,
        SPEC_R,
        SPEC_G,
        SPEC_B,
        INTRINSIC_R,
        INTRINSIC_G,
        INTRINSIC_B,
        MIRROR_FRAC,
        SHININESS,
        a1,
        NUM_ATOMDATA
    } atomData;

typedef struct _octree {
    float4 position;
    float radius;
    unsigned int hit;
    unsigned int miss;
    int leafNode;
    unsigned int leafStart;
    unsigned int leafMembers;
    int a1;
    int a2;
} octree;

typedef enum _intrinsicLightData
    {
        XI,
        YI,
        ZI,
        VDWI,
        RED,
        GREEN,
        BLUE,
        CUTOFF,
        MODE,
        NUM_INTRINSIC_LIGHT_DATA
    } intrinsicLightData;

typedef enum _intrinsicLightModes {
    CRUDE_ONE_FACE,
    CRUDE_TWO_FACE,
    REAL_POINT_SOURCE,
    REAL_BROAD_SOURCE,
    NUM_INTRINSIC_LIGHT_MODES
} intrinsicLightModes;

#define NO_INTERSECTION MAXFLOAT
#define IMAGE_DATA_WIDTH 8192
#define NO_FURTHER_NODES UINT_MAX
#define FLOAT_ERROR 0.0001
#define SOFT_SHADOW_SAMPLES 16
#define INTRINSIC_LIGHT_SCALE_EXP (float)3.0
#define HDR_SCALE_MIN 0.05f
#define HDR_SCALE_MAX 0.95f

float randomFloat(float max, uint *rseed, size_t gid) {
    ulong seed = *rseed + gid;
    seed = (seed * 0x5DEECE66DL + 0xBL) & ((1L << 48) - 1);
    uint uresult = seed >> 16;
    *rseed = uresult;
    return (float)uresult / (float)0xFFFFFFFF * max;
}

float4 mirrorRay(float4 direction, float4 normal, float4 point)
{
    float4 proj_vector, temp_point;
    float4 result;
    
    //Normal vector passed should already be a unit vector
    proj_vector = normal * dot(direction, normal);
    
    temp_point = point + direction * -1.0f + proj_vector * 2.0f;
    
    result = temp_point - point;
//    result.w = 0;
    
    return result;
    
}

float raySphereInteractionTest(float4 pos, float radius, float4 rayStart, float4 rayDirection) {
    
    float4 raySphereDifference;
    float b, c, bSqr, c4, t1, t2, tClosest, tPossible;
    
    //    tClosest = NO_INTERSECTION;
    
    raySphereDifference = rayStart - pos;
    
    b = 2 * dot(rayDirection, raySphereDifference);
    c = dot(raySphereDifference, raySphereDifference) - radius * radius;
    
    bSqr = b * b;
    //        ac4 = 4 * c;
    c4 = 4 * c;
    
    tClosest = NO_INTERSECTION;
    if (bSqr > c4) {
        t1 = (b > 0) ? (-b - sqrt(bSqr - c4))*0.5 : (-b + sqrt(bSqr - c4))*0.5;
        t2 = c / t1;
        
        t1 = (t1 > 0) ? t1 : NO_INTERSECTION;
        t2 = (t2 > 0) ? t2 : NO_INTERSECTION;
        tClosest = (t1 < t2) ? t1 : t2;
    }
    return tClosest;
    
}

void dataIntersectionClip(float* tClosestOut, uint* closestAtomOut, float4 rayOrigin, float4 rayDir, __read_only image2d_t nodes, __read_only image2d_t data) {
    
    float4 pos;
    float vdw, t1, tClosest, nodeRadius;
    unsigned int closestAtom;
    uint currentNode;
    
    tClosest = NO_INTERSECTION;
    currentNode = 0;
    closestAtom = 0;
    float clipT = rayOrigin.w;
    rayOrigin.w = 1.0;
    float4 clipRayOrigin = rayOrigin + rayDir * clipT;
    
    while (currentNode != NO_FURTHER_NODES) {
        
        int2 nodeCoord = (int2)((currentNode << 1) % IMAGE_DATA_WIDTH, (currentNode << 1) / IMAGE_DATA_WIDTH);
        
        pos = as_float4(read_imageui(nodes, sampler, nodeCoord));
        
        nodeRadius = pos.w;
        pos.w = 1.0f;
        t1 = raySphereInteractionTest(pos, nodeRadius, rayOrigin, rayDir);
        
        int closerIntersection;
        closerIntersection = t1 != NO_INTERSECTION ? 1 : 0;
        closerIntersection &= (t1 - 2 * nodeRadius) <= tClosest ? 1 : 0;
        
        if (closerIntersection) {
            
            uint4 nodeData;
            nodeData = read_imageui(nodes, sampler, nodeCoord + (int2)(1, 0));
            
            if (nodeData.w != 0) {
                unsigned int leafBaseIndex = nodeData.z;
                
                for (int j = 0; j < nodeData.w; j++) {
                    unsigned int atomIndex = leafBaseIndex + j;
                    
                    int2 atomDataCoord = (int2)((atomIndex << 1) % IMAGE_DATA_WIDTH, (atomIndex << 1) / IMAGE_DATA_WIDTH);
                    
                    pos = as_float4(read_imageui(data, sampler, atomDataCoord));
                    pos.w = 1.0f;
                    uint4 atomData;
                    atomData = read_imageui(data, sampler, atomDataCoord + (int2)(1, 0));
                    vdw = as_float(atomData.x);
                    uint clip = atomData.z;
                    
                    t1 = clip ? raySphereInteractionTest(pos, vdw, clipRayOrigin, rayDir) + clipT : raySphereInteractionTest(pos, vdw, rayOrigin, rayDir);
//                    if (clip)
//                        t1 = raySphereInteractionTest(pos, vdw, clipRayOrigin, rayDir) + clipT;
//                    else
//                        t1 = raySphereInteractionTest(pos, vdw, rayOrigin, rayDir);
//                    if ((get_global_id(0) == 53) && (t1 != NO_INTERSECTION))
//                    printf("i: %u, j: %u, clipT: %.2f, clip: %u, t1: %.2f\n", get_global_id(0) , j, clipT, clip, t1);
                    
                    closestAtom = t1 < tClosest ? atomIndex : closestAtom;
                    tClosest = t1 < tClosest ? t1 : tClosest;
//                    if (t1 != NO_INTERSECTION) {
//                        if (tClosest == NO_INTERSECTION) {
//                            tClosest = t1;
//                            closestAtom = atomIndex;
//                        } else if (t1 < tClosest) {
//                            tClosest = t1;
//                            closestAtom = atomIndex;
//                        }
//                    }
                }
            }
            
            currentNode = nodeData.x;
            
        } else {
            uint4 nodeData;
            nodeCoord = nodeCoord + (int2)(1, 0);
            nodeData = read_imageui(nodes, sampler, nodeCoord);
            
            currentNode = nodeData.y;
            
        }
    }
    *tClosestOut = tClosest;
    *closestAtomOut = closestAtom;
}


void dataIntersection(float* tClosestOut, uint* closestAtomOut, float4 rayOrigin, float4 rayDir, __read_only image2d_t nodes, __read_only image2d_t data) {
    
    float4 pos;
    float vdw, t1, tClosest, nodeRadius;
    unsigned int closestAtom;
    uint currentNode;
    
    tClosest = NO_INTERSECTION;
    currentNode = 0;
    closestAtom = 0;
    
    while (currentNode != NO_FURTHER_NODES) {
        
        int2 nodeCoord = (int2)((currentNode << 1) % IMAGE_DATA_WIDTH, (currentNode << 1) / IMAGE_DATA_WIDTH);
        
        pos = as_float4(read_imageui(nodes, sampler, nodeCoord));
        
        nodeRadius = pos.w;
        pos.w = 1.0f;
        t1 = raySphereInteractionTest(pos, nodeRadius, rayOrigin, rayDir);
        
        int closerIntersection;
        closerIntersection = t1 != NO_INTERSECTION ? 1 : 0;
        closerIntersection &= (t1 - 2 * nodeRadius) <= tClosest ? 1 : 0;
        
        if (closerIntersection) {
            
            uint4 nodeData;
            nodeData = read_imageui(nodes, sampler, nodeCoord + (int2)(1, 0));
            
            if (nodeData.w != 0) {
                unsigned int leafBaseIndex = nodeData.z;
                
                for (int j = 0; j < nodeData.w; j++) {
                    unsigned int atomIndex = leafBaseIndex + j;
                    
                    int2 atomDataCoord = (int2)((atomIndex << 1) % IMAGE_DATA_WIDTH, (atomIndex << 1) / IMAGE_DATA_WIDTH);
                    
                    pos = as_float4(read_imageui(data, sampler, atomDataCoord));
                    vdw = pos.w;
                    pos.w = 1.0f;
//                    float4 atomData;
//                    atomData = as_float4(read_imageui(data, sampler, atomDataCoord + (int2)(1, 0)));
//                    vdw = atomData.x;
                    
                    t1 = raySphereInteractionTest(pos, vdw, rayOrigin, rayDir);
                    
                    closestAtom = t1 < tClosest ? atomIndex : closestAtom;
                    tClosest = t1 < tClosest ? t1 : tClosest;

//                    if (t1 != NO_INTERSECTION) {
//                        if (tClosest == NO_INTERSECTION) {
//                            tClosest = t1;
//                            closestAtom = atomIndex;
//                        } else if (t1 < tClosest) {
//                            tClosest = t1;
//                            closestAtom = atomIndex;
//                        }
//                    }
                }
            }
            
            currentNode = nodeData.x;
            
        } else {
            uint4 nodeData;
            nodeCoord = nodeCoord + (int2)(1, 0);
            nodeData = read_imageui(nodes, sampler, nodeCoord);
            
            currentNode = nodeData.y;
            
        }
    }
    *tClosestOut = tClosest;
    *closestAtomOut = closestAtom;
}

void dataIntersectionIntrinsicLight(float* tClosestOut, uint* closestAtomOut, float4 rayOrigin, float4 rayDir, float lightDistance, __read_only image2d_t nodes, __read_only image2d_t data) {
    
    float4 pos;
    float vdw, t1, tClosest, nodeRadius;
    unsigned int closestAtom;
    uint currentNode;
    
    tClosest = NO_INTERSECTION;
    currentNode = 0;
    closestAtom = 0;
    
    while (currentNode != NO_FURTHER_NODES) {
        
        int2 nodeCoord = (int2)((currentNode << 1) % IMAGE_DATA_WIDTH, (currentNode << 1) / IMAGE_DATA_WIDTH);
        
        pos = as_float4(read_imageui(nodes, sampler, nodeCoord));
        
        nodeRadius = pos.w;
        pos.w = 1.0f;
        t1 = raySphereInteractionTest(pos, nodeRadius, rayOrigin, rayDir);
        
        int closerIntersection;
        closerIntersection = t1 != NO_INTERSECTION ? 1 : 0;
        closerIntersection = (t1 - 2 * nodeRadius) <= tClosest ? closerIntersection : 0;
        closerIntersection = length(pos - rayOrigin) <= nodeRadius + lightDistance ? closerIntersection : 0;
        
        if (closerIntersection) {
            
            uint4 nodeData;
            nodeData = read_imageui(nodes, sampler, nodeCoord + (int2)(1, 0));
            
            if (nodeData.w != 0) {
                unsigned int leafBaseIndex = nodeData.z;
                
                for (int j = 0; j < nodeData.w; j++) {
                    unsigned int atomIndex = leafBaseIndex + j;
                    
                    int2 atomDataCoord = (int2)((atomIndex << 1) % IMAGE_DATA_WIDTH, (atomIndex << 1) / IMAGE_DATA_WIDTH);
                    
                    pos = as_float4(read_imageui(data, sampler, atomDataCoord));
                    vdw = pos.w;
                    pos.w = 1.0f;
                    //                    float4 atomData;
                    //                    atomData = as_float4(read_imageui(data, sampler, atomDataCoord + (int2)(1, 0)));
                    //                    vdw = atomData.x;
                    
                    t1 = raySphereInteractionTest(pos, vdw, rayOrigin, rayDir);
                    
                    closestAtom = t1 < tClosest ? atomIndex : closestAtom;
                    tClosest = t1 < tClosest ? t1 : tClosest;

//                    if (t1 != NO_INTERSECTION) {
//                        if (tClosest == NO_INTERSECTION) {
//                            tClosest = t1;
//                            closestAtom = atomIndex;
//                        } else if (t1 < tClosest) {
//                            tClosest = t1;
//                            closestAtom = atomIndex;
//                        }
//                    }
                }
            }
            
            currentNode = nodeData.x;
            
        } else {
            uint4 nodeData;
            nodeCoord = nodeCoord + (int2)(1, 0);
            nodeData = read_imageui(nodes, sampler, nodeCoord);
            
            currentNode = nodeData.y;
            
        }
    }
    *tClosestOut = tClosest;
    *closestAtomOut = closestAtom;
}

float transferLinearToNonLinearRec709(float l) {
    
    float v;
    v = l < 0.018 ? 4.5f * l : 1.099 * pow(l, 0.45f) - 0.099;
    
    return v;
}

float transferLinearToMacGamma(float l) {
    
    return pow(l, 1.0f/1.8f);
}

kernel void convertToARGB_32Bit(global uchar4* output, __read_only image2d_t input, const unsigned int imageWidth, int limit) {
    
    size_t i = get_global_id(0);
    
    if (i < limit) {
        uchar4 outColour;
        float4 inColour;
        
        int2 coord = (int2)(i % imageWidth, i / imageWidth);
        inColour = read_imagef(input, sampler, coord);
        if (inColour.x < 0.)
            inColour.x = 0;
        else if (inColour.x > 1.0)
            inColour.x = 1.0;
        
        if (inColour.y < 0.)
            inColour.y = 0;
        else if (inColour.y > 1.0)
            inColour.y = 1.0;
        
        if (inColour.z < 0.)
            inColour.z = 0;
        else if (inColour.z > 1.0)
            inColour.z = 1.0;

        if (inColour.w < 0.)
            inColour.w = 0;
        else if (inColour.w > 1.0)
            inColour.w = 1.0;
        
//        inColour.x = transferLinearToNonLinearRec709(inColour.x);
//        inColour.y = transferLinearToNonLinearRec709(inColour.y);
//        inColour.z = transferLinearToNonLinearRec709(inColour.z);
//        inColour.w = transferLinearToNonLinearRec709(inColour.w);

        inColour.x = transferLinearToMacGamma(inColour.x);
        inColour.y = transferLinearToMacGamma(inColour.y);
        inColour.z = transferLinearToMacGamma(inColour.z);
        inColour.w = transferLinearToMacGamma(inColour.w);
        
        
        outColour.x = (uchar)(inColour.w * 255.0);
        outColour.y = (uchar)(inColour.x * 255.0);
        outColour.z = (uchar)(inColour.y * 255.0);
        outColour.w = (uchar)(inColour.z * 255.0);
        output[i] = outColour;
//        if (length(inColour) > 0)
//        printf("i: %d, coord: %d %d, inColour: %.2f %.2f %.2f, outColour: %d %d %d\n", i, coord.x, coord.y, inColour.x, inColour.y, inColour.z, outColour.x, outColour.y, outColour.z);
    }
}

kernel void hdrScaleRGBA(__write_only image2d_t output, global float4 *input, const int imageWidth, const float4 minScale, const float4 min, const float4 maxScale, const float4 max, int aaSamples, int limit) {
    
    size_t i = get_global_id(0);
    
    if (i >= limit) return;
    
    float scaleMin = HDR_SCALE_MIN * aaSamples;
    float scaleMax = HDR_SCALE_MAX * aaSamples;
    
    float4 colour = input[i];
//    float4 scale = (float4)(1.0f, 1.0f, 1.0f, 1.0f);
//    scale.x = colour.x < scaleMin ? scaleMin - ((scaleMin - colour.x) * minScale.x) : scale.x;
//    scale.x = colour.x > scaleMax ? scaleMax + ((colour.x - scaleMax) * maxScale.x) : scale.x;
//    scale.y = colour.y < scaleMin ? scaleMin - ((scaleMin - colour.y) * minScale.y) : scale.y;
//    scale.y = colour.y > scaleMax ? scaleMax + ((colour.y - scaleMax) * maxScale.y) : scale.y;
//    scale.z = colour.z < scaleMin ? scaleMin - ((scaleMin - colour.z) * minScale.z) : scale.z;
//    scale.z = colour.z > scaleMax ? scaleMax + ((colour.z - scaleMax) * maxScale.z) : scale.z;
    
//    float averageScale = (scale.x + scale.y + scale.z) / 3.0f;
    
//    colour.xyz = colour.xyz * averageScale;
//    colour.x = colour.x < scaleMin ? scaleMin - ((scaleMin - colour.x) * minScale.x) : colour.x;
//    colour.x = colour.x > scaleMax ? scaleMax + ((colour.x - scaleMax) * maxScale.x) : colour.x;
//    colour.y = colour.y < scaleMin ? scaleMin - ((scaleMin - colour.y) * minScale.y) : colour.y;
//    colour.y = colour.y > scaleMax ? scaleMax + ((colour.y - scaleMax) * maxScale.y) : colour.y;
//    colour.z = colour.z < scaleMin ? scaleMin - ((scaleMin - colour.z) * minScale.z) : colour.z;
//    colour.z = colour.z > scaleMax ? scaleMax + ((colour.z - scaleMax) * maxScale.z) : colour.z;
    
    colour.x = colour.w > 0.0 ? colour.x / (float)aaSamples : 0;
    colour.y = colour.w > 0.0 ? colour.y / (float)aaSamples : 0;
    colour.z = colour.w > 0.0 ? colour.z / (float)aaSamples : 0;
    colour.w = colour.w > 0.0 ? colour.w / (float)aaSamples : 0;
    
    int2 coord = (int2)(i % imageWidth, i / imageWidth);
    write_imagef(output, coord, colour);
    
//    if ((688000 < i) && (689000 > i))
//        printf("i: %d, scale: %.2f %.2f %.2f av: %.2g input: %.2f %.2f %.2f %.2f colour: %.2f %.2f %.2f %.2f\n", i, scale.x, scale.y, scale.z, averageScale, input[i].x, input[i].y, input[i].z, input[i].w, colour.x, colour.y, colour.z, colour.w);

}

kernel void generateImageHaze(__write_only image2d_t imageOut, __read_only image2d_t image, __read_only image2d_t intrinsicObjectImage, __read_only image2d_t intrinsicLightImage, __read_only image2d_t blurredIntrinsicObjectImage, const int imageWidth, __read_only image2d_t tValue, float hazeStart, float hazeDepth, float4 hazeColour, float desaturationAmount, const int limit) {
    
    size_t i = get_global_id(0);
    
    if (i >= limit) return;
    
    int2 coord = (int2)(i % imageWidth, i / imageWidth);
    
    int2 tVcoord = (int2)(i % IMAGE_DATA_WIDTH, i / IMAGE_DATA_WIDTH);
    float4 tV = read_imagef(tValue, sampler, tVcoord);
    
    float adjustedDepth = (tV.x - hazeStart) > hazeDepth ? hazeDepth : tV.x - hazeStart;
    adjustedDepth = adjustedDepth < 0 ? 0 : adjustedDepth;
    float hazeRatio = adjustedDepth / hazeDepth;
//    float4 hazeToAdd = hazeColour * hazeRatio;
    float4 blurColour = read_imagef(blurredIntrinsicObjectImage, sampler, coord);
//    blurColour.w = blurColour.w * 4.0;

    float4 colour, finalColour;
    colour = read_imagef(image, sampler, coord);
//    if (i==596435) printf("i: %d, colour: %.2f %.2f %.2f %.2f\n", i, colour.x, colour.y, colour.z, colour.w);
    colour += read_imagef(intrinsicObjectImage, sampler, coord);
//    if (i==596435) printf("i: %d, colour: %.2f %.2f %.2f %.2f\n", i, colour.x, colour.y, colour.z, colour.w);
    colour += read_imagef(intrinsicLightImage, sampler, coord);
//    if (i==596435) printf("i: %d, colour: %.2f %.2f %.2f %.2f\n", i, colour.x, colour.y, colour.z, colour.w);
    colour.w = colour.w > 1.0 ? 1.0 : colour.w;
    colour.xyz = colour.xyz * colour.w;
//    if (i==596435) printf("i: %d, colour: %.2f %.2f %.2f %.2f\n", i, colour.x, colour.y, colour.z, colour.w);

    
    float4 tintColour = blurColour + 1.0f;
    hazeColour.xyz = tintColour.xyz * hazeColour.xyz;
    hazeColour.xyz = hazeColour.xyz * hazeColour.w;
    
//    blurColour = blurColour * 2.0f;
//    blurColour.xyz = blurColour.xyz * blurColour.w;
//    colour = blurColour + (1.0f - blurColour.w) * colour;
//    colour = blurColour + colour;
    
    //Haze - fog
    finalColour = hazeRatio * hazeColour + (1.0f - hazeRatio) * colour + blurColour;
    finalColour.w = finalColour.w > 1.0 ? 1.0 : finalColour.w;
    
    //Fade out alpha in the distance...
//    blurColour.w = blurColour.w * 4.0f;
//    finalColour = colour + blurColour;
//    finalColour.w = finalColour.w * (1.0f - hazeRatio);
//    finalColour.w = finalColour.w > 1.0 ? 1.0 : finalColour.w;
    
//    if (i> 500000 && i < 501000)
//    printf("i: %d, adjustedDepth: %.2f, blurColour: %.2f %.2f %.2f %.2f hazeRatio: %.2f, hazeColour: %.2f %.2f %.2f %.2f colour: %.2f %.2f %.2f %.2f finalColour: %.2f %.2f %.2f %.2f\n", i, adjustedDepth, blurColour.x, blurColour.y, blurColour.z, blurColour.w, hazeRatio, hazeColour.x, hazeColour.y, hazeColour.z, hazeColour.w, colour.x, colour.y, colour.z, colour.w, finalColour.x, finalColour.y, finalColour.z, finalColour.w);
    
    write_imagef(imageOut, coord, finalColour);
}

kernel void gaussianRGBAPassHoriz(__read_only image2d_t imageIn, __write_only image2d_t imageOut,
                                           int iWidth, int iHeight,
                                           global const float* mask, int maskSize) {
    
    // compute X pixel location and check in-bounds
    size_t Y = get_global_id(0);
	if (Y >= iHeight) return;
    
    for (int X = 0; X < iWidth; X++)
    {
        int2 coord = (int2)(X, Y);
        float4 sum = (float4)(0, 0, 0, 0);
        for(int a = -maskSize; a < maskSize+1; a++) {
            float m = mask[a+maskSize];
            float4 pixel = read_imagef(imageIn, blurSampler, coord + (int2)(a,0));
            sum += m * pixel;
            //            if (X == 5)
            //            printf("X: %d, Y: %d, a: %d, m: %.2f pixel: %.2f %.2f %.2f %.2f, sum: %.2f %.2f %.2f %.2f\n", X, Y, a, m, pixel.x, pixel.y, pixel.z, pixel.w, sum.x, sum.y, sum.z, sum.w);
        }
        
        //        if (X == 5) {
        //            printf("X: %d, Y: %d, sum: %.2f\n", X, Y, sum);
        //        }
        
        write_imagef(imageOut, coord, sum);
    }
}

kernel void gaussianRGBAPassVert(__read_only image2d_t imageIn, __write_only image2d_t imageOut,
                                          int iWidth, int iHeight,
                                          global const float* mask, int maskSize) {
    
    // compute X pixel location and check in-bounds
    size_t X = get_global_id(0);
	if (X >= iWidth) return;

    for (int Y = 0; Y < iHeight; Y++)
    {
        int2 coord = (int2)(X, Y);
        float4 sum = (float4)(0, 0, 0, 0);
        for(int a = -maskSize; a < maskSize+1; a++) {
            float m = mask[a+maskSize];
            float4 pixel = read_imagef(imageIn, blurSampler, coord + (int2)(0,a));
            sum += m * pixel;
//            if (X == 5)
//            printf("X: %d, Y: %d, a: %d, m: %.2f pixel: %.2f %.2f %.2f %.2f, sum: %.2f %.2f %.2f %.2f\n", X, Y, a, m, pixel.x, pixel.y, pixel.z, pixel.w, sum.x, sum.y, sum.z, sum.w);
        }
        
//        if (X == 5) {
//            printf("X: %d, Y: %d, sum: %.2f\n", X, Y, sum);
//        }
        
        write_imagef(imageOut, coord, sum);
    }
}


kernel void sumImages(__write_only image2d_t imageOut, __read_only image2d_t image1, __read_only image2d_t image2, int imageWidth, int limit) {
    
    size_t i = get_global_id(0);
    
    if (i < limit) {
        float4 c1, c2;
        int2 coord = (int2)(i % imageWidth, i / imageWidth);
        c1 = read_imagef(image1, sampler, coord);
        c2 = read_imagef(image2, sampler, coord);
        write_imagef(imageOut, coord, c1 + c2);
    }
    
}


kernel void generateImageIntrinsicObjects(__write_only image2d_t image, const unsigned int imageWidth, global float* tValue, global float8* sceneRays, global unsigned int* object_ids, global float4* normal, global unsigned int* index, global float* atomData, const int limit) {
    
    size_t i = get_global_id(0);
    
    if (i >= limit) return;
//    uint generatePixel;
//    generatePixel = i < limit ? 1 : 0;
//    generatePixel &= tValue[i] != NO_INTERSECTION ? 1 : 0;
    
//    if (generatePixel) {
        float4 colour;
        colour.w = 1.0;
        
        float4 intrinsicColour;
    uint object = object_ids[i];
        intrinsicColour.x = atomData[object * NUM_ATOMDATA + INTRINSIC_R];
        intrinsicColour.y = atomData[object * NUM_ATOMDATA + INTRINSIC_G];
        intrinsicColour.z = atomData[object * NUM_ATOMDATA + INTRINSIC_B];
        intrinsicColour.w = 0.0;
        float glow;
        glow = 0.5;
        
        float4 invRayDirection = sceneRays[i].s4567 * -1.0f;
        
        //Simple intrinsic lighting
    float4 intersectionNormal = normal[i];
        colour.w = (length(intrinsicColour) > 0) ? 1.0 : 0.0;
        colour.x = intrinsicColour.x * (glow + (1.0f - glow) * dot(intersectionNormal, invRayDirection));
        colour.y = intrinsicColour.y * (glow + (1.0f - glow) * dot(intersectionNormal, invRayDirection));
        colour.z = intrinsicColour.z * (glow + (1.0f - glow) * dot(intersectionNormal, invRayDirection));
        
        int2 coord = (int2)(index[i] % imageWidth, index[i] / imageWidth);
        write_imagef(image, coord, colour);
        //        printf("i: %d, coord: %d %d, rgb: %.2f %.2f %.2f\n", i, coord.x, coord.y, colour.x, colour.y, colour.z);
//    }
}

kernel void generateImage(__write_only image2d_t image, const unsigned int imageWidth, global float* tValue, global float8* sceneRays, global unsigned int* object_ids, global float4* normal, global unsigned int* index, global float* atomData, const int numLights, global float8* lights, global float8* lightRays, global float* sceneLightTValues, const float4 ambientLight, const int limit) {
    
    size_t i = get_global_id(0);
    
    uint generatePixel;
    generatePixel = i < limit ? 1 : 0;
    generatePixel &= tValue[i] != NO_INTERSECTION ? 1 : 0;
    
    if (generatePixel) {
        float4 colour;
        colour.w = 1.0;
        
        float4 diffuseColour, specularColour, intrinsicColour;
        float phong, mirrorFrac, atomRadius;

//        printf("i: %d, oid: %d\n", i, object_ids[i]);
        diffuseColour.x = atomData[object_ids[i] * NUM_ATOMDATA + DIFFUSE_R];
        diffuseColour.y = atomData[object_ids[i] * NUM_ATOMDATA + DIFFUSE_G];
        diffuseColour.z = atomData[object_ids[i] * NUM_ATOMDATA + DIFFUSE_B];
        specularColour.x = atomData[object_ids[i] * NUM_ATOMDATA + SPEC_R];
        specularColour.y = atomData[object_ids[i] * NUM_ATOMDATA + SPEC_G];
        specularColour.z = atomData[object_ids[i] * NUM_ATOMDATA + SPEC_B];
        phong = atomData[object_ids[i] * NUM_ATOMDATA + SHININESS];
        mirrorFrac = atomData[object_ids[i] * NUM_ATOMDATA + MIRROR_FRAC];
        
        float4 invRayDirection = sceneRays[i].s4567 * -1.0f;
        
        //Ambient lighting and simple intrinsic lighting
        colour.x = diffuseColour.x * ambientLight.x;
        colour.y = diffuseColour.y * ambientLight.y;
        colour.z = diffuseColour.z * ambientLight.z;

        //Scene lights
        for (int l = 0; l < numLights; l++) {
            uint lightIndex = i * numLights + l;
            if (sceneLightTValues[lightIndex] > 1.0) {
//                printf("i: %d, l: %d\n", i, l);
                float4 lightRayStart = lightRays[lightIndex].xyzw;
                float4 lightRayDirection = normalize(lightRays[lightIndex].s4567);
                
                float4 mirrorUnit = normalize(mirrorRay(lightRayDirection, normal[i], lightRayStart));
                
                float lDotN = dot(lightRayDirection, normal[i]);
                float rDotV = dot(mirrorUnit, invRayDirection);
                float specScale = pow(rDotV, phong);
                
                lDotN = lDotN < 0 ? 0 : lDotN;
                specScale = specScale < 0 ? 0 : specScale;
                specScale = rDotV > 0 ? specScale : 0;
                
                colour.x += diffuseColour.x * lDotN * lights[l].s4 + specularColour.x * specScale * lights[l].s4;
                colour.y += diffuseColour.y * lDotN * lights[l].s5 + specularColour.y * specScale * lights[l].s5;
                colour.z += diffuseColour.z * lDotN * lights[l].s6 + specularColour.z * specScale * lights[l].s6;

//                if (index[i]==643374)
//                    printf("i: %d, rDotV: %.2f, ss: %.2f colour: %.2f %.2f %.2f %.2f\n", i, rDotV, specScale, colour.x, colour.y, colour.z, colour.w);

            }
        }
        
        int2 coord = (int2)(index[i] % imageWidth, index[i] / imageWidth);
        write_imagef(image, coord, colour);
//        printf("i: %d, coord: %d %d, rgb: %.2f %.2f %.2f\n", i, coord.x, coord.y, colour.x, colour.y, colour.z);
    }
}

kernel void generateImageIntrinsicRayLightCombinedkernel(global float4* outImage, global float8* sceneRays, global float4* point, global float4* normals, global unsigned int* object_ids, global float4* inImage, global float* atomData, float4 ilPosition, float4 ilColour, float intrinsicLightVDW, float distanceCutoff, uint mode, __read_only image2d_t nodes, __read_only image2d_t data, const int limit)  {
    
    size_t i = get_global_id(0);
    
    if (i >= limit) return;
    
    float4 colour;
    
    colour.x = colour.y = colour.z = 0.0;
    
    float4 pos = point[i];
    float4 normal = normals[i];
    float4 viewOrigin = sceneRays[i].xyzw;
    float4 viewDirection = normalize(sceneRays[i].s4567 * (float)-1.0);
    float small_step = (float)FLOAT_ERROR * length(viewOrigin - pos);
    float4 lightRayStart = pos + normal * small_step;
    
    float4 diffuseColour, specularColour, intrinsicColour;
    float phong, mirrorFrac, atomRadius;
    
    //        printf("i: %d, oid: %d\n", i, object_ids[i]);
    diffuseColour.x = atomData[object_ids[i] * NUM_ATOMDATA + DIFFUSE_R];
    diffuseColour.y = atomData[object_ids[i] * NUM_ATOMDATA + DIFFUSE_G];
    diffuseColour.z = atomData[object_ids[i] * NUM_ATOMDATA + DIFFUSE_B];
    specularColour.x = atomData[object_ids[i] * NUM_ATOMDATA + SPEC_R];
    specularColour.y = atomData[object_ids[i] * NUM_ATOMDATA + SPEC_G];
    specularColour.z = atomData[object_ids[i] * NUM_ATOMDATA + SPEC_B];
    intrinsicColour.x = atomData[object_ids[i] * NUM_ATOMDATA + INTRINSIC_R];
    intrinsicColour.y = atomData[object_ids[i] * NUM_ATOMDATA + INTRINSIC_G];
    intrinsicColour.z = atomData[object_ids[i] * NUM_ATOMDATA + INTRINSIC_B];
    phong = atomData[object_ids[i] * NUM_ATOMDATA + SHININESS];
    mirrorFrac = atomData[object_ids[i] * NUM_ATOMDATA + MIRROR_FRAC];
    
    float4 intrinsicLightDirection;
    float ilDistance;
    
    uint seed = as_uint(pos.x);
    
    intrinsicLightDirection = ilPosition - pos;
    ilDistance = length(intrinsicLightDirection) - intrinsicLightVDW;
    
    //Start of rewrite Lighting code
    float4 ilDirectionUnit;
    
    intrinsicLightDirection = ilPosition - lightRayStart;
    
    ilDirectionUnit = normalize(intrinsicLightDirection);
    //Scale light linearly by distance until cutoff
    float ilDistanceScale;
    ilDistanceScale = -1.0/pow(distanceCutoff, INTRINSIC_LIGHT_SCALE_EXP);
    
    uint contributionsForLight = mode == REAL_BROAD_SOURCE ? SOFT_SHADOW_SAMPLES : 1;
    contributionsForLight = ilDistance > FLOAT_ERROR * 2 ? contributionsForLight : 0;
    contributionsForLight = ilDistance < distanceCutoff ? contributionsForLight : 0;
    
    //            printf("i: %d, j: %d, cfl: %d\n", i, j, contributionsForLight);
    for (int l = 0; l < contributionsForLight; l++) {
        int checkForPointIntersection;
        checkForPointIntersection = ilDistance > FLOAT_ERROR * 2 ? 1 : 0;
        
        intrinsicLightDirection = ilPosition - lightRayStart;
        float4 ilOutsideSpherePos = ilPosition + normalize(intrinsicLightDirection * -1.0f) * (intrinsicLightVDW + small_step);
        intrinsicLightDirection = ilOutsideSpherePos - lightRayStart;
        
        float4 s;
        s.x = randomFloat(2.0, &seed, i) - (float)1.0;
        s.y = randomFloat(2.0, &seed, i) - (float)1.0;
        s.z = randomFloat(2.0, &seed, i) - (float)1.0;
        s.w = 0;
        s = s * (float)(intrinsicLightVDW / length(s) + small_step);
        if (dot(s, normalize(intrinsicLightDirection)) > 0) {
            s = s * (float)-1.0;
        }
        s = s + ilPosition;
        float4 sDirection, sDirectionUnit;
        
        sDirection = mode == REAL_POINT_SOURCE ? intrinsicLightDirection : s - lightRayStart;
        sDirectionUnit = normalize(sDirection);

        float scale = length(sDirection);
        float tClosest;
        uint closestAtom;
        
        dataIntersection(&tClosest, &closestAtom, s, sDirectionUnit, nodes, data);
        
        float intersectionT = tClosest == NO_INTERSECTION ? NO_INTERSECTION : tClosest / scale;
        
        float4 scaledLight;
        float sDistance;
        sDistance = scale;
        
        scaledLight = ilColour * (float)(pow(sDistance, INTRINSIC_LIGHT_SCALE_EXP) * ilDistanceScale + 1.0) / (float)contributionsForLight;
        
        float4 phongMirror = mirrorRay(sDirection, normal, s);
        
        float4 Lunit, mirrorUnit;
        
        //                Lunit = normalize(lightRayDirection);
        mirrorUnit = normalize(phongMirror);
        
        float lDotN = dot(sDirectionUnit, normal);
        float rDotV = dot(mirrorUnit, viewDirection);
        float specScale = pow(rDotV, phong);
        
        lDotN = lDotN < 0 ? 0 : lDotN;
        specScale = specScale < 0 ? 0 : specScale;
        
        
        colour.x = intersectionT > 1.0f ? colour.x + diffuseColour.x * lDotN * scaledLight.x + specularColour.x * specScale * scaledLight.x : colour.x;
        colour.y = intersectionT > 1.0f ? colour.y + diffuseColour.y * lDotN * scaledLight.y + specularColour.y * specScale * scaledLight.y : colour.y;
        colour.z = intersectionT > 1.0f ? colour.z + diffuseColour.z * lDotN * scaledLight.z + specularColour.z * specScale * scaledLight.z : colour.z;
    }
    
    colour.w = contributionsForLight > 0 ? 1.0f : 0.0f;
    colour.x = colour.x > 0 ? colour.x : 0;
    colour.y = colour.y > 0 ? colour.y : 0;
    colour.z = colour.z > 0 ? colour.z : 0;
    
    outImage[i] = inImage[i] + colour;
    //    int2 coord = (int2)(index[i] % imageWidth, index[i] / imageWidth);
    //    write_imagef(image, coord, colour);
    //    }
}

kernel void generateImageIntrinsicRayLight(global float4* outImage, const unsigned int imageWidth, global float8* sceneRays, global float* tValue, global float4* point, global float4* normals, global unsigned int* object_ids, global float* atomData, float4 ilPosition, float4 ilColour, float intrinsicLightVDW, float distanceCutoff, uint mode, __read_only image2d_t intrinsicLightTValues, global uint* intrinsicRayStartIndex, __read_only image2d_t intrinsicLightRays, const int limit) {
    
    size_t i = get_global_id(0);
    
    if (i >= limit) return;

    float4 colour;
    
    colour.x = colour.y = colour.z = 0.0;
    
    float4 pos = point[i];
    float4 normal = normals[i];
    float4 viewOrigin = sceneRays[i].xyzw;
    float4 viewDirection = normalize(sceneRays[i].s4567 * (float)-1.0);
    float small_step = (float)FLOAT_ERROR * length(viewOrigin - pos);
    float4 lightRayStart = pos + normal * small_step;
    
    float4 diffuseColour, specularColour, intrinsicColour;
    float phong, mirrorFrac, atomRadius;
    
    //        printf("i: %d, oid: %d\n", i, object_ids[i]);
    diffuseColour.x = atomData[object_ids[i] * NUM_ATOMDATA + DIFFUSE_R];
    diffuseColour.y = atomData[object_ids[i] * NUM_ATOMDATA + DIFFUSE_G];
    diffuseColour.z = atomData[object_ids[i] * NUM_ATOMDATA + DIFFUSE_B];
    specularColour.x = atomData[object_ids[i] * NUM_ATOMDATA + SPEC_R];
    specularColour.y = atomData[object_ids[i] * NUM_ATOMDATA + SPEC_G];
    specularColour.z = atomData[object_ids[i] * NUM_ATOMDATA + SPEC_B];
    intrinsicColour.x = atomData[object_ids[i] * NUM_ATOMDATA + INTRINSIC_R];
    intrinsicColour.y = atomData[object_ids[i] * NUM_ATOMDATA + INTRINSIC_G];
    intrinsicColour.z = atomData[object_ids[i] * NUM_ATOMDATA + INTRINSIC_B];
    phong = atomData[object_ids[i] * NUM_ATOMDATA + SHININESS];
    mirrorFrac = atomData[object_ids[i] * NUM_ATOMDATA + MIRROR_FRAC];
    
    uint startIndex = intrinsicRayStartIndex[i];
    
    float4 intrinsicLightDirection;
    float ilDistance;
    
    intrinsicLightDirection = ilPosition - pos;
    ilDistance = length(intrinsicLightDirection) - intrinsicLightVDW;
    
    //Start of rewrite Lighting code
    float4 ilDirectionUnit;
    
    intrinsicLightDirection = ilPosition - lightRayStart;
    
    ilDirectionUnit = normalize(intrinsicLightDirection);
    //Scale light linearly by distance until cutoff
    float ilDistanceScale;
    ilDistanceScale = -1.0/pow(distanceCutoff, INTRINSIC_LIGHT_SCALE_EXP);
    
    uint contributionsForLight = mode == REAL_BROAD_SOURCE ? SOFT_SHADOW_SAMPLES : 1;
//    contributionsForLight = ilDistance > FLOAT_ERROR * 2 ? contributionsForLight : 0;
//    contributionsForLight = ilDistance < distanceCutoff ? contributionsForLight : 0;
    
    uint validLightDistance = ilDistance > FLOAT_ERROR * 2 ? 1 : 0;
    validLightDistance = ilDistance < distanceCutoff ? validLightDistance : 0;

    //            printf("i: %d, j: %d, cfl: %d\n", i, j, contributionsForLight);
    for (int l = 0; l < contributionsForLight; l++) {
//        int checkForPointIntersection;
//        checkForPointIntersection = ilDistance > FLOAT_ERROR * 2 ? 1 : 0;
        
        float4 sDirection, sDirectionUnit,s;
        uint rayIndex = startIndex + l;
        int2 rCoord = (int2)((rayIndex << 1) % IMAGE_DATA_WIDTH, (rayIndex << 1) / IMAGE_DATA_WIDTH);
        s = read_imagef(intrinsicLightRays, sampler, rCoord);
        sDirection = read_imagef(intrinsicLightRays, sampler, rCoord + (int2)(1,0));
        
        //        s = checkForPointIntersection ? intrinsicLightRays[startIndex + l].xyzw : lightRayStart;
        //         s = lightRayStart;
        //        sDirection = checkForPointIntersection ? intrinsicLightRays[startIndex + l].s4567 : intrinsicLightDirection;
        //         sDirection = intrinsicLightDirection;
        sDirectionUnit = normalize(sDirection);
        
        uint tValueIndex = (startIndex + l);
        int2 coord = (int2)(tValueIndex % IMAGE_DATA_WIDTH, tValueIndex / IMAGE_DATA_WIDTH);
        float intersectionT = read_imagef(intrinsicLightTValues, sampler, coord).x;
        
        float4 scaledLight;
        float sDistance;
        sDistance = length(sDirection);
        
        scaledLight = ilColour * (float)(pow(sDistance, INTRINSIC_LIGHT_SCALE_EXP) * ilDistanceScale + 1.0) / (float)contributionsForLight;
        scaledLight = validLightDistance ? scaledLight : (float4)(0,0,0,0);

        float4 phongMirror = mirrorRay(sDirection, normal, s);
        
        float4 Lunit, mirrorUnit;
        
        //                Lunit = normalize(lightRayDirection);
        mirrorUnit = normalize(phongMirror);
        
        float lDotN = dot(sDirectionUnit, normal);
        float rDotV = dot(mirrorUnit, viewDirection);
        float specScale = pow(rDotV, phong);
        
        lDotN = lDotN < 0 ? 0 : lDotN;
        specScale = specScale < 0 ? 0 : specScale;
        
        
        colour.x = intersectionT > 1.0f ? colour.x + diffuseColour.x * lDotN * scaledLight.x + specularColour.x * specScale * scaledLight.x : colour.x;
        colour.y = intersectionT > 1.0f ? colour.y + diffuseColour.y * lDotN * scaledLight.y + specularColour.y * specScale * scaledLight.y : colour.y;
        colour.z = intersectionT > 1.0f ? colour.z + diffuseColour.z * lDotN * scaledLight.z + specularColour.z * specScale * scaledLight.z : colour.z;
    }
    
    colour.w = validLightDistance > 0 ? 1.0f : 0.0f;
    colour.x = colour.x > 0 ? colour.x : 0;
    colour.y = colour.y > 0 ? colour.y : 0;
    colour.z = colour.z > 0 ? colour.z : 0;
    
    outImage[i] = outImage[i] + colour;
//    int2 coord = (int2)(index[i] % imageWidth, index[i] / imageWidth);
//    write_imagef(image, coord, colour);
    //    }
}

kernel void convertLinearColoursToImage(__write_only image2d_t image, const uint imageWidth, global float4* colour, global uint* index, const uint limit) {
    
    size_t i = get_global_id(0);
    
    if (i >= limit) return;
    
    int2 coord = (int2)(index[i] % imageWidth, index[i] / imageWidth);
    write_imagef(image, coord, colour[i]);

}

kernel void copyBuffer(global float4* outImage, global float4* inImage, const uint limit) {
    size_t i = get_global_id(0);
    
    if (i >= limit) return;
    
    outImage[i] = inImage[i];
}

kernel void zeroBuffer(global float4* buffer, const uint limit) {
    
    size_t i = get_global_id(0);
    
    if (i >= limit) return;
    
    buffer[i] = (float4)(0.0f, 0.0f, 0.0f, 0.0f);
    
}

kernel void generateImageIntrinsicCrudeLight(global float4* outImage, const unsigned int imageWidth, global float8* sceneRays, global float4* point, global float4* normals, global unsigned int* object_ids, global float* atomData, float4 ilPosition, float4 ilColour, float intrinsicLightVDW, float distanceCutoff, uint mode, const int limit) {
    
    size_t i = get_global_id(0);
    
    if (i >= limit) return;

    float4 colour;
    
    colour.x = colour.y = colour.z = 0.0;
    
    float4 pos = point[i];
    float4 normal = normals[i];
    float4 viewOrigin = sceneRays[i].xyzw;
    float4 viewDirection = normalize(sceneRays[i].s4567 * (float)-1.0);
    float small_step = (float)FLOAT_ERROR * length(viewOrigin - pos);
    float4 lightRayStart = pos + normal * small_step;
    
    float4 diffuseColour, specularColour, intrinsicColour;
    float phong, mirrorFrac, atomRadius;
    
    //        printf("i: %d, oid: %d\n", i, object_ids[i]);
    diffuseColour.x = atomData[object_ids[i] * NUM_ATOMDATA + DIFFUSE_R];
    diffuseColour.y = atomData[object_ids[i] * NUM_ATOMDATA + DIFFUSE_G];
    diffuseColour.z = atomData[object_ids[i] * NUM_ATOMDATA + DIFFUSE_B];
    specularColour.x = atomData[object_ids[i] * NUM_ATOMDATA + SPEC_R];
    specularColour.y = atomData[object_ids[i] * NUM_ATOMDATA + SPEC_G];
    specularColour.z = atomData[object_ids[i] * NUM_ATOMDATA + SPEC_B];
    intrinsicColour.x = atomData[object_ids[i] * NUM_ATOMDATA + INTRINSIC_R];
    intrinsicColour.y = atomData[object_ids[i] * NUM_ATOMDATA + INTRINSIC_G];
    intrinsicColour.z = atomData[object_ids[i] * NUM_ATOMDATA + INTRINSIC_B];
    phong = atomData[object_ids[i] * NUM_ATOMDATA + SHININESS];
    mirrorFrac = atomData[object_ids[i] * NUM_ATOMDATA + MIRROR_FRAC];
    
    float4 intrinsicLightDirection;
    float ilDistance;
    
    intrinsicLightDirection = ilPosition - pos;
    ilDistance = length(intrinsicLightDirection) - intrinsicLightVDW;
    
    //Start of rewrite Lighting code
    float4 ilDirectionUnit;
    
    intrinsicLightDirection = ilPosition - lightRayStart;
    
    ilDirectionUnit = normalize(intrinsicLightDirection);
    //Scale light linearly by distance until cutoff
    float ilDistanceScale;
    ilDistanceScale = -1.0/pow(distanceCutoff, INTRINSIC_LIGHT_SCALE_EXP);
    
    float4 sDirection = intrinsicLightDirection;
    float4 sDirectionUnit = normalize(sDirection);
    
    uint addIntrinsicLight = ilDistance < distanceCutoff ? 1 : 0;
    
    float4 scaledLight;
    float sDistance;
    sDistance = length(sDirection);
    
    scaledLight = ilColour * (float)(pow(sDistance, INTRINSIC_LIGHT_SCALE_EXP) * ilDistanceScale + 1.0);
    
    float4 phongMirror = mirrorRay(sDirection, normal, lightRayStart);
    
    float4 Lunit, mirrorUnit;
    
    //                Lunit = normalize(lightRayDirection);
    mirrorUnit = normalize(phongMirror);
    
    float lDotN = dot(sDirectionUnit, normal);
    float rDotV = dot(mirrorUnit, viewDirection);
    float specScale = pow(rDotV, phong);
    
    lDotN = mode == CRUDE_TWO_FACE ? fabs(lDotN) : lDotN;
    lDotN = lDotN < 0 ? 0 : lDotN;
    specScale = specScale < 0 ? 0 : specScale;
    
    colour.x = addIntrinsicLight ? colour.x + diffuseColour.x * lDotN * scaledLight.x + specularColour.x * specScale * scaledLight.x : colour.x;
    colour.y = addIntrinsicLight ? colour.y + diffuseColour.y * lDotN * scaledLight.y + specularColour.y * specScale * scaledLight.y : colour.y;
    colour.z = addIntrinsicLight ? colour.z + diffuseColour.z * lDotN * scaledLight.z + specularColour.z * specScale * scaledLight.z : colour.z;
    
    colour.w = addIntrinsicLight ? 1.0f : 0.0f;
    colour.x = colour.x > 0 ? colour.x : 0;
    colour.y = colour.y > 0 ? colour.y : 0;
    colour.z = colour.z > 0 ? colour.z : 0;
    
    outImage[i] = outImage[i] + colour;

//   int2 coord = (int2)(index[i] % imageWidth, index[i] / imageWidth);
//   write_imagef(image, coord, colour);
    //    }
}


kernel void generateIntrinsicLightingRays(__write_only image2d_t intrinsicLightRays, global uint* intrinsicRayStartIndex, global float8* sceneRays, global float4* point, global float4* normal, float4 ilPosition, float intrinsicLightVDW, float distanceCutoff, uint mode, int limit) {
    
    size_t i = get_global_id(0);
    
    if (i >= limit) return;
    
    float4 pos = point[i];
    float4 viewOrigin = sceneRays[i].xyzw;
    float small_step = (float)FLOAT_ERROR * length(viewOrigin - pos);
    float4 lightRayStart = pos + normal[i] * small_step;
    
    uint seed;
//    seed = rayEntropy[i];
    seed = as_uint(pos.x);
    
    uint startIndex = intrinsicRayStartIndex[i];
    
    float4 intrinsicLightDirection;
    float ilDistance;
    
    intrinsicLightDirection = ilPosition - pos;
    ilDistance = length(intrinsicLightDirection) - intrinsicLightVDW;
    
    uint rays = mode == REAL_BROAD_SOURCE ? SOFT_SHADOW_SAMPLES : 1;
    rays = ilDistance > FLOAT_ERROR * 2 ? rays : 0;
    rays = ilDistance < distanceCutoff ? rays : 0;

    for (uint k = 0; k < rays; k++) {
        
        intrinsicLightDirection = ilPosition - lightRayStart;
        float4 ilOutsideSpherePos = ilPosition + normalize(intrinsicLightDirection * -1.0f) * (intrinsicLightVDW + small_step);
        intrinsicLightDirection = ilOutsideSpherePos - lightRayStart;
        
        float4 s;
        s.x = randomFloat(2.0, &seed, i) - (float)1.0;
        s.y = randomFloat(2.0, &seed, i) - (float)1.0;
        s.z = randomFloat(2.0, &seed, i) - (float)1.0;
        s.w = 0;
        s = s * (float)(intrinsicLightVDW / length(s) + small_step);
        if (dot(s, normalize(intrinsicLightDirection)) > 0) {
            s = s * (float)-1.0;
        }
        s = s + ilPosition;
        float4 sDirection, sDirectionUnit;
        sDirection = s - lightRayStart;
        
//        float8 newRay;
        //                    newRay.xyzw = mode == REAL_POINT_SOURCE ? lightRayStart : s;
//        newRay.xyzw = lightRayStart;
//        newRay.s4567 = mode == REAL_POINT_SOURCE ? intrinsicLightDirection : sDirection;
//        intrinsicLightRays[startIndex + k] = newRay;
        
        uint rayIndex = startIndex + k;
        int2 coord = (int2)((rayIndex << 1) % IMAGE_DATA_WIDTH, (rayIndex << 1) / IMAGE_DATA_WIDTH);
        float4 rayD = mode == REAL_POINT_SOURCE ? intrinsicLightDirection : sDirection;
        
        write_imagef(intrinsicLightRays, coord, lightRayStart);
        write_imagef(intrinsicLightRays, coord + (int2)(1,0), rayD);

//        intrinsicRayIntersectionId[startIndex + k] = i;
        //                    printf("i: %d, j: %d, k: %d, startIndex: %d, numRays: %d\n", i, j, k, startIndex, numRays);
    }

}

kernel void countIntrinsicLightingRaysAtomic(global float4* point, float4 ilPosition, float intrinsicLightVDW, float distanceCutoff, uint mode, global uint* raysNeeded, global uint* sum, uint limitIntersections) {
    
    size_t i = get_global_id(0);
    
    if (i >= limitIntersections) return;
    
    float4 pos = point[i];
    uint numRays = 0;
    
    float4 intrinsicLightDirection;
    float ilDistance;
    
    intrinsicLightDirection = ilPosition - pos;
    ilDistance = length(intrinsicLightDirection) - intrinsicLightVDW;
    
    int rayNeeded;
//    rayNeeded = mode == REAL_POINT_SOURCE ? 1 : 0;
//    rayNeeded = mode == REAL_BROAD_SOURCE ? 1 : rayNeeded;
    rayNeeded = ilDistance > FLOAT_ERROR * 2 ? 1 : 0;
    rayNeeded = ilDistance < distanceCutoff ? rayNeeded : 0;
    if (rayNeeded) {
        numRays += mode == REAL_BROAD_SOURCE ? SOFT_SHADOW_SAMPLES : 1;
    }
    
    uint cumulativeNumRays = atomic_add(sum, numRays);
    raysNeeded[i] = cumulativeNumRays;
//    printf("i: %d, numRays: %d\n", i, numRays);
    
}

kernel void countIntrinsicLightingRays(global float4* point, float4 ilPosition, float intrinsicLightVDW, float distanceCutoff, uint mode, global uint* raysNeeded, uint limitIntersections) {
    
    size_t i = get_global_id(0);
    
    if (i >= limitIntersections) return;
    
    float4 pos = point[i];
    uint numRays = 0;
    
    float4 intrinsicLightDirection;
    float ilDistance;
    
    intrinsicLightDirection = ilPosition - pos;
    ilDistance = length(intrinsicLightDirection) - intrinsicLightVDW;
    
    int rayNeeded;
//    rayNeeded = mode == REAL_POINT_SOURCE ? 1 : 0;
//    rayNeeded = mode == REAL_BROAD_SOURCE ? 1 : rayNeeded;
    rayNeeded = ilDistance > FLOAT_ERROR * 2 ? 1 : 0;
    rayNeeded = ilDistance < distanceCutoff ? rayNeeded : 0;
    uint raysForMode = mode == REAL_BROAD_SOURCE ? SOFT_SHADOW_SAMPLES : 1;
    numRays = rayNeeded ? raysForMode : 0;    
    
    raysNeeded[i] = numRays;
//        printf("i: %d, numRays: %d\n", i, numRays);

}

kernel void screenIntrinsicLights(global uint* screenLight, global float* ilData, global float4* point, global float4* normal, global float* tValue, const float tMax, uint numLights, uint numIntersections) {
    
    size_t i = get_global_id(0);
    
    if (i >= numLights) return;

    float4 ilPosition;
    float intrinsicLightVDW, distanceCutoff;
    uint mode;
    
    ilPosition.x = ilData[i * NUM_INTRINSIC_LIGHT_DATA + XI];
    ilPosition.y = ilData[i * NUM_INTRINSIC_LIGHT_DATA + YI];
    ilPosition.z = ilData[i * NUM_INTRINSIC_LIGHT_DATA + ZI];
    ilPosition.w = 1.0;
    intrinsicLightVDW = ilData[i * NUM_INTRINSIC_LIGHT_DATA + VDWI];
    distanceCutoff = ilData[i * NUM_INTRINSIC_LIGHT_DATA + CUTOFF];
    mode = ilData[i * NUM_INTRINSIC_LIGHT_DATA + MODE];
    
    uint anyPointClose = 0;
    
    for (int j = 0; j < numIntersections; j++) {
        float4 pos = point[j];
        
        float4 intrinsicLightDirection;
        float ilDistance;
        
        intrinsicLightDirection = ilPosition - pos;
        ilDistance = length(intrinsicLightDirection) - intrinsicLightVDW;
        
        uint visible;
        visible = mode == CRUDE_TWO_FACE ? 1 : 0;
        visible = dot(normalize(intrinsicLightDirection), normal[j]) > 0 ? 1 : visible;
        
        int lightNeeded;
        lightNeeded = ilDistance > FLOAT_ERROR * 2 ? visible : 0;
        lightNeeded = ilDistance < distanceCutoff ? lightNeeded : 0;
        lightNeeded = tValue[j] < tMax ? lightNeeded : 0;
        anyPointClose = lightNeeded ? 1 : anyPointClose;
    }
    
    screenLight[i] = anyPointClose;
    
}

kernel void rayDataLightingIntersectImage(__read_only image2d_t rays, __write_only image2d_t tValue, __read_only image2d_t nodes, __read_only image2d_t data, float lightDistance, int limit) {
    
    size_t i = get_global_id(0);
    
    if (i < limit) {
        
//        float4 rayOrigin, rayDir;
//        rayOrigin = rays[i].xyzw;
//        rayDir = rays[i].s4567;
        float4 rayOrigin, rayDir;
        int2 coord = (int2)((i << 1) % IMAGE_DATA_WIDTH, (i << 1) / IMAGE_DATA_WIDTH);
        rayOrigin = read_imagef(rays, sampler, coord);
        rayDir = read_imagef(rays, sampler, coord + (int2)(1,0));
        
        float scale = length(rayDir);
        rayDir = normalize(rayDir);
        
        float tClosest;
        uint closestAtom;
        
        dataIntersectionIntrinsicLight(&tClosest, &closestAtom, rayOrigin, rayDir, lightDistance, nodes, data);
        
        float tValueOut = tClosest == NO_INTERSECTION ? NO_INTERSECTION : tClosest / scale;
        
//        float4 tVImage;
//        tVImage.x = tValueOut;
        coord = (int2)(i % IMAGE_DATA_WIDTH, i / IMAGE_DATA_WIDTH);
        write_imagef(tValue, coord, tValueOut);
//        printf("i: %d, x: %d y: %d, t: %.2f", i, coord.x, coord.y, tVImage.x);
    }
}

kernel void rayDataLightingIntersect(global float8* rays, global float* tValue, __read_only image2d_t nodes, __read_only image2d_t data, int limit) {
    
    size_t i = get_global_id(0);
    
    if (i < limit) {
        
        float4 rayOrigin, rayDir;
        rayOrigin = rays[i].xyzw;
        rayDir = rays[i].s4567;
        float scale = length(rayDir);
        rayDir = normalize(rayDir);
        
        float tClosest;
        uint closestAtom;
        
        dataIntersectionIntrinsicLight(&tClosest, &closestAtom, rayOrigin, rayDir, scale, nodes, data);
//        dataIntersection(&tClosest, &closestAtom, rayOrigin, rayDir, nodes, data);
        
        tValue[i] = tClosest == NO_INTERSECTION ? NO_INTERSECTION : tClosest / scale;
        
//        printf("i: %d, t: %.2f", tValue[i]);
    }
}


kernel void generateLightingRays(global float8* lightingRaysOut, global float8* sceneRays, int numLights, global float8* lights, global float4* point, global float4* normal, int limit) {
    
    size_t i = get_global_id(0);

    if (i < limit) {
        float4 viewOrigin = sceneRays[i].xyzw;
        float small_step = (float)FLOAT_ERROR * length(viewOrigin - point[i]);
        float4 lightRayStart = point[i] + normal[i] * small_step;
        
        for (int j = 0; j < numLights; j++) {
            
            float4 lightPosition = lights[j].s0123;
            float4 lightRayDirection = lightPosition - lightRayStart;
            
            float8 ray;
            ray.xyzw = lightRayStart;
            ray.s4567 = lightRayDirection;
            
            lightingRaysOut[i * numLights + j] = ray;
//            printf("i: %d, j: %d lp: %.2f %.2f %.2f %.2f ld: %.2f %.2f %.2f %.2f\n", i, j, ray.x, ray.y, ray.z, ray.w, ray.s4, ray.s5, ray.s6, ray.s7);
        }
    }
}

kernel void selectIntersectionsFromRays(__read_only image2d_t tValue, global uint* indexIn, __read_only image2d_t raysIn, __read_only image2d_t pointIn, __read_only image2d_t normalIn, __read_only image2d_t object_idIn, global float* tValueOut, global float8* raysOut, global float4* pointOut, global float4* normalOut, global unsigned int* object_idOut, global unsigned int* indexOut, int limit) {
    size_t i = get_global_id(0);
    
    if (i >= limit) return;

    int2 coord = (int2)(i % IMAGE_DATA_WIDTH, i / IMAGE_DATA_WIDTH);

    float4 tV = read_imagef(tValue, sampler, coord);
    
    if (tV.x == NO_INTERSECTION) return;

    unsigned int index = indexIn[i];
    indexOut[index] = i;
    pointOut[index] = read_imagef(pointIn, sampler, coord);
    normalOut[index] = read_imagef(normalIn, sampler, coord);
    tValueOut[index] = tV.x;
    object_idOut[index] = read_imageui(object_idIn, sampler, coord).x;
    float8 ray;
    int2 rayCoord = (int2)((i << 1) % IMAGE_DATA_WIDTH, (i << 1) / IMAGE_DATA_WIDTH);
    ray.xyzw = read_imagef(raysIn, sampler, rayCoord);
    ray.s4567 = read_imagef(raysIn, sampler, rayCoord + (int2)(1,0));
    //Reset the clipT
    ray.w = 1.0;
    raysOut[index] = ray;
//    printf("i: %d, index: %u, tv: %.2f pos: %.2f %.2f %.2f %.2f normal: %.2f %.2f %.2f %.2f\n", i, index, tValueOut[index], pointOut[index].x, pointOut[index].y, pointOut[index].z, pointOut[index].w, normalOut[index].x, normalOut[index].y, normalOut[index].z, normalOut[index].w);
    
}

kernel void detectIntersectingRaysAtomic(__read_only image2d_t tValue, global unsigned int* intersection, global unsigned int* sum, int limit) {
    size_t i = get_global_id(0);
    
    if (i >= limit) return;
    
    int2 coord = (int2)(i % IMAGE_DATA_WIDTH, i / IMAGE_DATA_WIDTH);
    
    float4 tV = read_imagef(tValue, sampler, coord);
//    intersection[i] = tV.x != NO_INTERSECTION ? 1 : 0;
    if (tV.x != NO_INTERSECTION) {
        unsigned int index = atomic_inc(sum);
        intersection[i] = index;
//        printf("i: %d, index: %d, saved: %d\n", i, index, intersection[i]);
    }
    
}


kernel void detectIntersectingRays(__read_only image2d_t tValue, global unsigned int* intersection, int limit) {
    size_t i = get_global_id(0);
    
    if (i >= limit) return;
    
    int2 coord = (int2)(i % IMAGE_DATA_WIDTH, i / IMAGE_DATA_WIDTH);

    float tV = read_imagef(tValue, sampler, coord).x;
    intersection[i] = tV != NO_INTERSECTION ? 1 : 0;
    
}

kernel void rayDataIntersect(__read_only image2d_t rays, __write_only image2d_t tValue, __write_only image2d_t point, __write_only image2d_t normal, __write_only image2d_t object_id, int startPixel, __read_only image2d_t nodes, __read_only image2d_t data, int limit) {
    
    size_t i = get_global_id(0);
        
    if (i < limit) {
     
        float4 rayOrigin, rayDir;
        int2 coord = (int2)((i << 1) % IMAGE_DATA_WIDTH, (i << 1) / IMAGE_DATA_WIDTH);
        rayOrigin = read_imagef(rays, sampler, coord);
        rayDir = read_imagef(rays, sampler, coord + (int2)(1,0));
//        rayOrigin = rays[i].xyzw;
//        rayDir = rays[i].s4567;
        
        float4 pos;
        float vdw, t1, tClosest, nodeRadius;
        unsigned int closestAtom;
        uint currentNode;
        
        dataIntersectionClip(&tClosest, &closestAtom, rayOrigin, rayDir, nodes, data);
        
        coord = (int2)(i % IMAGE_DATA_WIDTH, i / IMAGE_DATA_WIDTH);
        write_imagef(tValue, coord, tClosest);
//        tValue[i] = tClosest;
        
        //Reset the clip
        rayOrigin.w = 1.0;
        float4 theIntersection = rayOrigin + rayDir * tClosest;
//        point[i] = theIntersection;
        write_imagef(point, coord, theIntersection);
        
        
        int2 atomDataCoord = (int2)((closestAtom << 1) % IMAGE_DATA_WIDTH, (closestAtom << 1) / IMAGE_DATA_WIDTH);
        pos = as_float4(read_imageui(data, sampler, atomDataCoord));

        pos.w = 1.0f;
        float4 radius = theIntersection - pos;
        uint4 atomData;
        atomData = read_imageui(data, sampler, atomDataCoord + (int2)(1, 0));
        vdw = as_float(atomData.x);
//        normal[i] = radius / vdw;
        write_imagef(normal, coord, radius / vdw);
//        object_id[i] = atomData.y;
        write_imageui(object_id, coord, atomData.y);
    }
}


kernel void rayGenerate(__write_only image2d_t rays, global uint* entropyPool, int startPixel, float4 viewOrigin, float4 lookAt, float4 upOrientation, int width, int height, float viewWidth, float aperture, float focalDistance, float lensLength, uint clipEnabled, float clipDistance, int limit) {
    
    
    size_t i = get_global_id(0);
    int aaSteps = 1;
    int2 coord = (int2)((i << 1) % IMAGE_DATA_WIDTH, (i << 1) / IMAGE_DATA_WIDTH);
    
    float aspectRatio = (float)width / (float)height;
    
    float4 rayStart, rayDirection, viewDirection;
    float4 centralRayStart, centralRayDirection;
    float circScale, angle;
    
    int actualI = i + startPixel;
    //        printf("Pixel: %d. ", actualI);
    float fi = (float)actualI;
    float fw = (float)width;
    int row = floor(fi/fw);
    int column = actualI - width * row;

//    rayStart = viewOrigin;
    circScale = length(lookAt - viewOrigin);
    angle = column / (float)width * 2 * M_PI_F - M_PI_F;
    rayStart.x = sin(angle) * circScale;
    rayStart.y = viewOrigin.y;
    rayStart.z = -cos(angle) * circScale;
    rayStart.w = 1;
    
//    if ((i > 500000) && (i < 501000)) {
//        printf("i: %d, angle: %.2f raystart: %.2f %.2f %.2f %.2f\n", i, angle, rayStart.x, rayStart.y, rayStart.z, rayStart.w);
//    }
    
    rayDirection = lookAt - rayStart;
    viewDirection = normalize(rayDirection);
    float4 viewPlaneOrigin = rayStart + viewDirection * lensLength;
    float4 viewLeftDirection, viewUpDirection;
    
    viewLeftDirection = cross(upOrientation, viewDirection);
    viewLeftDirection.w = 0;
    viewLeftDirection = normalize(viewLeftDirection);
    
    viewUpDirection = normalize(cross(viewDirection, viewLeftDirection));
    viewUpDirection.w = 0;
    
    float viewHeight = viewWidth / aspectRatio;
    
    float step_size_left = 2 * viewWidth / width;
    float step_size_up = 2 * viewHeight / height;
    
    uint randomSeed = entropyPool[i];
    
    float pixelOffset = (float)1.0 / (float)(aaSteps + 1);
    float leftPixelFraction, upPixelFraction;
    
    leftPixelFraction = randomFloat((float)1.0, &randomSeed,i);
    upPixelFraction = randomFloat((float)1.0, &randomSeed,i);
//    float leftScale = -viewWidth + (column + leftPixelFraction) * step_size_left;
    float leftScale = 0;
    float upScale = -viewHeight + (row + upPixelFraction) * step_size_up;
    
    float4 viewPlanePoint = viewPlaneOrigin + viewUpDirection * upScale + viewLeftDirection * leftScale;
    viewPlanePoint.w = 1;
    
    rayDirection = viewPlanePoint - rayStart;
    
    //plane at focal point with central ray direction as normal
    float4 centralRayDirectionUnit = viewDirection;
    float4 focalPointCenter = rayStart + centralRayDirectionUnit * focalDistance;
    
    float d = dot(centralRayDirectionUnit, focalPointCenter);
    float4 focalPoint;
    focalPoint = rayStart + rayDirection * (d - dot(centralRayDirectionUnit, rayStart))/dot(centralRayDirectionUnit, rayDirection);
    focalPoint.w = (float)1.0;
    
    //plane at clip Distance from view origin with central ray direction as normal
    clipDistance = clipEnabled ? clipDistance : 0.0f;
    float4 clipPlaneCenter = rayStart + centralRayDirectionUnit * clipDistance;
    
    if (centralRayDirectionUnit.z != 0) {
        float zx = -1 * centralRayDirectionUnit.x /centralRayDirectionUnit.z;
        float4 xUnit = (float4)(1,0,zx,0);
        float4 yUnit;
        xUnit = normalize(xUnit);
        yUnit = cross(xUnit, centralRayDirectionUnit);
        yUnit = normalize(yUnit);
        
        float4 p1, d1;
        float rx, ry;
        rx = randomFloat((float)1.0, &randomSeed,i);
        ry = randomFloat((float)1.0, &randomSeed,i);
        p1 = rayStart + xUnit * (float)(rx - 0.5) * aperture + yUnit * (float)(ry - 0.5) * aperture;
        d1 = focalPoint - p1;
        p1.w = 1.0;
        
        float cp = clipEnabled ? length(d1) * (dot(centralRayDirectionUnit, clipPlaneCenter) - dot(centralRayDirectionUnit, p1))/dot(centralRayDirectionUnit, d1) : 0.0f;
//        p1 = clipEnabled ? p1 + d1 * (dot(centralRayDirectionUnit, clipPlaneCenter) - dot(centralRayDirectionUnit, p1))/dot(centralRayDirectionUnit, d1) : p1;
        p1.w = cp;
        
//        float8 ray;
//        ray.xyzw = p1;
//        ray.s4567 = normalize(d1);
//        rays[i] = ray;
        write_imagef(rays, coord, p1);
        write_imagef(rays, coord + (int2)(1,0), normalize(d1));
        
    } else if (centralRayDirectionUnit.y != 0) {
        float yx = -1 * centralRayDirectionUnit.x /centralRayDirectionUnit.y;
        float4 xUnit = (float4)(1,yx,0,0);
        float4 zUnit;
        xUnit = normalize(xUnit);
        zUnit = cross(xUnit, centralRayDirectionUnit);
        zUnit = normalize(zUnit);
        
        float4 p1, d1;
        float rx, rz;
        rx = randomFloat((float)1.0, &randomSeed,i);
        rz = randomFloat((float)1.0, &randomSeed,i);
        p1 = rayStart + xUnit * (float)(rx - 0.5) * aperture + zUnit * (float)(rz - 0.5) * aperture;
        d1 = focalPoint - p1;
        p1.w = 1.0;
        
        float cp = clipEnabled ? length(d1) * (dot(centralRayDirectionUnit, clipPlaneCenter) - dot(centralRayDirectionUnit, p1))/dot(centralRayDirectionUnit, d1) : 0.0f;
        //        p1 = clipEnabled ? p1 + d1 * (dot(centralRayDirectionUnit, clipPlaneCenter) - dot(centralRayDirectionUnit, p1))/dot(centralRayDirectionUnit, d1) : p1;
        p1.w = cp;
        
        
//        float8 ray;
//        ray.xyzw = p1;
//        ray.s4567 = normalize(d1);
//        rays[i] = ray;
        write_imagef(rays, coord, p1);
        write_imagef(rays, coord + (int2)(1,0), normalize(d1));

        
    } else if (centralRayDirectionUnit.x != 0) {
        float xz = -1 * centralRayDirectionUnit.z /centralRayDirectionUnit.x;
        float4 zUnit = (float4)(xz,0,1,0);
        float4 yUnit;
        zUnit = normalize(zUnit);
        yUnit = cross(zUnit, centralRayDirectionUnit);
        yUnit = normalize(yUnit);
        
        float4 p1, d1;
        float ry, rz;
        ry = randomFloat(1.0, &randomSeed,i);
        rz = randomFloat(1.0, &randomSeed,i);
        p1 = rayStart + zUnit * (float)(rz - 0.5) * aperture + yUnit * (float)(ry - 0.5) * aperture;
        d1 = focalPoint - p1;
        p1.w = 1.0;
        
        float cp = clipEnabled ? length(d1) * (dot(centralRayDirectionUnit, clipPlaneCenter) - dot(centralRayDirectionUnit, p1))/dot(centralRayDirectionUnit, d1) : 0.0f;
        //        p1 = clipEnabled ? p1 + d1 * (dot(centralRayDirectionUnit, clipPlaneCenter) - dot(centralRayDirectionUnit, p1))/dot(centralRayDirectionUnit, d1) : p1;
        p1.w = cp;
        
//        float8 ray;
//        ray.xyzw = p1;
//        ray.s4567 = normalize(d1);
//        rays[i] = ray;
        write_imagef(rays, coord, p1);
        write_imagef(rays, coord + (int2)(1,0), normalize(d1));

    }
}