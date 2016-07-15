//
//  rayTrace.cl
//  present
//
//  Created by Callum Smits on 7/07/13.
//  Copyright (c) 2013 Callum Smits. All rights reserved.
//

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

typedef struct _bvhStruct_cl {
    float x, y, z, radius;
    bool leafNode;
    int rangeStart, rangeEnd;
} bvhStruct_cl;

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

typedef struct _rayAtomData {
    float4 rayStart;
    float4 rayDirectionUnit;
    float4 a1;
    float tClosest;
    float a2;
    float a3;
    float a4;
    float16 atomData;
} rayAtomData;

/*typedef enum _interactionData {
    TVALUE,
    NUM,
    INTERSECTION_X,
    INTERSECTION_Y,
    INTERSECTION_Z,
    INTERSECTION_W,
    NORMAL_X,
    NORMAL_Y,
    NORMAL_Z,
    NORMAL_W,
    NUM_INTERACTIONDATA
} interactionData;*/

typedef struct tag_interaction
    {
        float16 data;
        float16 atomData;
    } interactionData;

typedef struct tag_bvhItem {
    int nodeIndex;
    float t_value;
} bvhItem;


#define NO_INTERSECTION MAXFLOAT
#define FLOAT_ERROR 0.004
#define LOCAL_MEM_SIZE 32768
#define MAX_LOCAL_FLOATS LOCAL_MEM_SIZE/sizeof(float)
#define MAX_LOCAL_BVHITEMS LOCAL_MEM_SIZE/sizeof(bvhItem)
#define MAX_LOCAL_ATOMS MAX_LOCAL_FLOATS/4
#define INTRINSIC_LIGHT_SCALE_EXP (float)3.0
#define SOFT_SHADOW_SAMPLES 32
#define GPU_WGS 256

float randomFloat(float max, uint *rseed, size_t gid) {
    ulong seed = *rseed + gid;
    seed = (seed * 0x5DEECE66DL + 0xBL) & ((1L << 48) - 1);
    uint uresult = seed >> 16;
    *rseed = uresult;
    return (float)uresult / (float)0xFFFFFFFF * max;
}

float4 vectorSubtract(float4 a, float4 b, float w) {
    float4 result;
    
    result = (float4)(a.x - b.x, a.y - b.y, a.z - b.z, w);
    
    return result;
}

float4 vectorAdd(float4 a, float4 b, float w) {
    float4 result;
    
    result = (float4)(a.x + b.x, a.y + b.y, a.z + b.z, w);
    
    return result;
}

float4 vectorScale(float4 a, float s) {
    float4 result;
    
    result = (float4)(a.x * s, a.y * s, a.z * s, a.w);
    
    return result;
}

float4 mirrorRay(float4 direction, float4 normal, float4 point)
{
    float4 proj_vector, temp_point;
    float4 result;
    
    //Normal vector passed should already be a unit vector
    proj_vector = normal * dot(direction, normal);
    
    temp_point = point + vectorScale(direction, -1) + vectorScale(proj_vector, 2);
    
    //    result = vectorSubtract(temp_point, point, 0);
    result = temp_point - point;
    
//    if ((get_global_id(0) == 143611) || (get_global_id(0) == 144123)) {
//        printf("i: %d, Proj: %f %f %f %f, length: %f TP: %f %f %f %f, Res: %f %f %f %f\n", get_global_id(0), proj_vector.x, proj_vector.y, proj_vector.z, proj_vector.w, length(proj_vector), temp_point.x, temp_point.y, temp_point.z, temp_point.w, result.x, result.y, result.z, result.w);
//    }
    
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
    
    /*if there is, then compare the t value to the closest intersection, and
     if it is closer, then make this value the closest. Treat tangent as not intersection.
     Use the three step method, page 4 of raytracing handout.*/
    
    t1 = (b > 0) ? (-b - sqrt(bSqr - c4))*0.5 : (-b + sqrt(bSqr - c4))*0.5;
    t2 = c / t1;
    
    t1 = (t1 > 0) ? t1 : NO_INTERSECTION;
    t2 = (t2 > 0) ? t2 : NO_INTERSECTION;
    tClosest = (t1 < t2) ? t1 : t2;

    return tClosest;
    
}

interactionData minimalRayIntersection(global float* input, const unsigned long numAtoms, float4 rayStart, float4 rayDirection)
{
    unsigned long i;
    
    float4 pos;
    float vdw, t1, tClosest;
    unsigned long closestAtom;
    
    tClosest = NO_INTERSECTION;
    
    
    for (i = 0; i < numAtoms; i++) {
        pos.xyzw = (float4)(input[i * NUM_ATOMDATA + X], input[i * NUM_ATOMDATA + Y], input[i * NUM_ATOMDATA + Z], 1.0);
        vdw = input[i * NUM_ATOMDATA + VDW];
        
        t1 = raySphereInteractionTest(pos, vdw, rayStart, rayDirection);
        
        if (t1 >= 0) {
            if (tClosest == NO_INTERSECTION) {
                tClosest = t1;
                closestAtom = i;
            } else if (t1 < tClosest) {
                tClosest = t1;
                closestAtom = i;
            }
        }
    }
    interactionData intersection;
    //    float16 intersection;
    
    intersection.data.s0 = tClosest;
        
    return intersection;
    
}

float16 rayIntersection(global const float16* input, const unsigned long numAtoms, float4 rayStart, float4 rayDirection, float *intersectionT, local rayAtomData *rayArray)
{
    unsigned long i, a;
    
    float4 pos;
    float vdw, t1, tClosest;
    unsigned long closestAtom;
    size_t gid, lid;
    float16 atom, closestAtomData;
    
    gid = get_global_id(0);
    lid = get_local_id(0);
    tClosest = NO_INTERSECTION;
//    closestAtom = 0;
    
    rayArray[lid].rayStart = rayStart;
    rayArray[lid].rayDirectionUnit = rayDirection;
    rayArray[lid].tClosest = NO_INTERSECTION;
//    barrier(CLK_LOCAL_MEM_FENCE);
    
    for (i = 0; i < numAtoms / GPU_WGS; i++) {
        a = i * GPU_WGS + lid;
        a = a < numAtoms ? a : 0;
        atom = input[a];
        pos.xyz = atom.s012;
        pos.w = 1.0;
        vdw = atom.s3;
        for (int j = 0; j < GPU_WGS; j++) {
            char ray;
            ray = j + (char)lid;
            t1 = raySphereInteractionTest(pos, vdw, rayArray[ray].rayStart, rayArray[ray].rayDirectionUnit);
            
            rayArray[ray].atomData = (t1 < rayArray[ray].tClosest) ? atom : rayArray[ray].atomData;
            rayArray[ray].tClosest = (t1 < rayArray[ray].tClosest) ? t1 : rayArray[ray].tClosest;

//            barrier(CLK_LOCAL_MEM_FENCE);
        }
    }
    
/*    for (i = 0; i < numAtoms; i++) {
//        a = (i + gid) % numAtoms;
        atom = input[i];
//        pos.xyzw = (float4)(input[i * NUM_ATOMDATA + X], input[i * NUM_ATOMDATA + Y], input[i * NUM_ATOMDATA + Z], 1.0);
        pos.xyz = atom.s012;
        pos.w = 1.0;
        vdw = atom.s3;
//        vdw = input[i * NUM_ATOMDATA + VDW];

        t1 = raySphereInteractionTest(pos, vdw, rayStart, rayDirection);

        closestAtomData = (t1 < tClosest) ? atom : closestAtomData;
//        closestAtom = (t1 < tClosest) ? i : closestAtom;
        tClosest = (t1 < tClosest) ? t1 : tClosest;
    }*/

//    interactionData intersection;
//    float16 intersection;
    
//    intersection.data.s0 = tClosest;
    
//    intersection.object = closestAtom;
//    intersection.atomData = closestAtomData;
    
    //        float4 theIntersection = vectorAdd(rayStart, vectorScale(rayDirection, tClosest), 1);
//    float4 theIntersection = rayStart + rayDirection * tClosest;
//    intersection.data.s2345 = theIntersection;
    
//    pos.xyzw = (float4)(input[closestAtom * NUM_ATOMDATA + X], input[closestAtom * NUM_ATOMDATA + Y], input[closestAtom * NUM_ATOMDATA + Z], 1.0);
//    pos.xyz = closestAtomData.s012;
//    pos.w = 1.0;
//    vdw = closestAtomData.s3;

//    float4 radius = theIntersection - pos;
//    vdw = input[closestAtom * NUM_ATOMDATA + VDW];
    //        intersection.data.s6789 = vectorScale(radius, 1.0 / vdw);
//    intersection.data.s6789 = radius / vdw;
    
    *intersectionT = rayArray[lid].tClosest;
    
    return rayArray[lid].atomData;
    
}


float4 singleRayTrace(float4 rayStart, float4 rayDirection, global const float* data, const unsigned long numAtoms, global const octree* tree, global const uint* treeLookupData, const float4 ambientLight, int numLights, global float8* lights, int numIntrinsicLights, global float* intrinsicLights, local rayAtomData *rayArray) {
    
    float4 colour;
    
    float4 rayDirectionUnit = normalize(rayDirection);
    float intersectionT;
    float16 atom;
    atom = rayIntersection((global const float16*)data, numAtoms, rayStart, rayDirectionUnit, &intersectionT, rayArray);
    
//    interactionData intersection = rayIntersectionTree(data, numAtoms, tree, treeLookupData, rayStart, rayDirectionUnit);
    
    colour.x = colour.y = colour.z = 0.0;
    
    colour.w = (intersectionT == NO_INTERSECTION) ? 0.0 : 1.0;
    
    float4 diffuseColour, specularColour, intrinsicColour, atomPos;
//    float phong, mirrorFrac, atomRadius;
//    unsigned long object;
    
//    object = intersection.object;
//    float16 atomData;
//    atomData = (float16)data[object * NUM_ATOMDATA];
//    atomPos.x = data[object * NUM_ATOMDATA + X];
//    atomPos.y = data[object * NUM_ATOMDATA + Y];
//    atomPos.z = data[object * NUM_ATOMDATA + Z];
//    atomPos.w = 1.0;
//    atomRadius = data[object * NUM_ATOMDATA + VDW];
    diffuseColour.xyz = atom.s456;
//    specularColour.x = data[object * NUM_ATOMDATA + SPEC_R];
//    specularColour.y = data[object * NUM_ATOMDATA + SPEC_G];
//    specularColour.z = data[object * NUM_ATOMDATA + SPEC_B];
//    intrinsicColour.xyz = intersection.atomData.sABC;
//    phong = data[object * NUM_ATOMDATA + SHININESS];
//    mirrorFrac = data[object * NUM_ATOMDATA + MIRROR_FRAC];
    
//    float4 intersectPos, normal;
//    intersectPos = intersection.data.s2345;
//    normal = intersection.data.s6789;
    
//    float4 small_intersection_step;
//    float small_step = (float)FLOAT_ERROR * length(rayStart - intersectPos);
//    small_intersection_step = intersectPos + normal * small_step;
    
    colour.x = diffuseColour.x * ambientLight.x;// + intrinsicColour.x * dot(normal, rayDirectionUnit * (float)-1.0);
    colour.y = diffuseColour.y * ambientLight.y;// + intrinsicColour.y * dot(normal, rayDirectionUnit * (float)-1.0);
    colour.z = diffuseColour.z * ambientLight.z;// + intrinsicColour.z * dot(normal, rayDirectionUnit * (float)-1.0);
    

    return colour;
}

kernel void raytraceGPU(global uchar4* output, int startPixel, float4 viewOrigin, float4 lookAt, float4 upOrientation, int aaSteps, int width, int height, float viewWidth, float aperture, float focalDistance, float lensLength, global const float* data, const unsigned long numAtoms, global const octree* tree, global const uint* treeLookupData, const float4 ambientLight, int numLights, global float8* lights, int numIntrinsicLights, global float* intrinsicLights, int limit) {
    
    
    size_t i = get_global_id(0);
    __local rayAtomData rayArray[GPU_WGS];
    
//    for (int j = 0; j < 5; j++) {
//        printf("i: %d, node: %u, pos: %.2f %.2f %.2f %.2f r: %.2f hit: %u miss %u leafnode: %d leafstart: %d leafMembers: %d\n", i, j, tree[j].position.x, tree[j].position.y, tree[j].position.z, tree[j].position.w, tree[j].radius, tree[j].hit, tree[j].miss, tree[j].leafNode, tree[j].leafStart, tree[j].leafMembers);
//    }

    
    float4 colour;
    int rayModelHits;
    rayModelHits = 0;
    colour.x = colour.y = colour.z = colour.w = 0;
    if (i + startPixel < limit ) {
        
        float aspectRatio = (float)width / (float)height;
        
        float4 rayStart, rayDirection, viewDirection;
        float4 centralRayStart, centralRayDirection;
        
        rayStart = viewOrigin;
        rayStart.w = 1;
        
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

        int actualI = i + startPixel;
//        printf("Pixel: %d. ", actualI);
        float fi = (float)actualI;
        float fw = (float)width;
        int row = floor(fi/fw);
        int column = actualI - width * row;
        uint randomSeed = numAtoms;
        
        float pixelOffset = 1.0 / (float)(aaSteps + 1);
        for (int j = 0; j < aaSteps; j++) {
            float leftPixelFraction, upPixelFraction;
            
            leftPixelFraction = randomFloat(1.0, &randomSeed,i);
            upPixelFraction = randomFloat(1.0, &randomSeed,i);
            float leftScale = -viewWidth + (column + leftPixelFraction) * step_size_left;
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
            focalPoint.w = 1.0;
            
            if (centralRayDirectionUnit.z != 0) {
                float zx = -1 * centralRayDirectionUnit.x /centralRayDirectionUnit.z;
                float4 xUnit = (float4)(1,0,zx,0);
                float4 yUnit;
                xUnit = normalize(xUnit);
                yUnit = cross(xUnit, centralRayDirectionUnit);
                yUnit = normalize(yUnit);
                
                float4 p1, d1;
                float rx, ry;
                rx = randomFloat(1.0, &randomSeed,i);
                ry = randomFloat(1.0, &randomSeed,i);
                p1 = rayStart + xUnit * (float)(rx - 0.5) * aperture + yUnit * (float)(ry - 0.5) * aperture;
                d1 = focalPoint - p1;
                p1.w = 1.0;
                
                float4 c1;
                c1 = singleRayTrace(p1, d1, data, numAtoms, tree, treeLookupData, ambientLight, numLights, lights, numIntrinsicLights, intrinsicLights, rayArray);
            
                //                    int lid = get_local_id(0);
                //                    if (lid == 0) {
                //                        printf("ZX: %f, xUnit: %f %f %f %f, yUnit: %f %f %f %f, p1: %f %f %f %f", zx, xUnit.x, xUnit.y, xUnit.z, xUnit.w, yUnit.x, yUnit.y, yUnit.z, yUnit.w, p1.x, p1.y, p1.z, p1.w);
                //                    }
                
                if (c1.w > 0) {
                    colour = colour + c1;
                    rayModelHits++;
                }
            } else if (centralRayDirectionUnit.y != 0) {
                float yx = -1 * centralRayDirectionUnit.x /centralRayDirectionUnit.y;
                float4 xUnit = (float4)(1,yx,0,0);
                float4 zUnit;
                xUnit = normalize(xUnit);
                zUnit = cross(xUnit, centralRayDirectionUnit);
                zUnit = normalize(zUnit);
                
                float4 p1, d1;
                float rx, rz;
                rx = randomFloat(1.0, &randomSeed,i);
                rz = randomFloat(1.0, &randomSeed,i);
                p1 = rayStart + xUnit * (float)(rx - 0.5) * aperture + zUnit * (float)(rz - 0.5) * aperture;
                d1 = focalPoint - p1;
                
                float4 c1;
                c1 = singleRayTrace(p1, d1, data, numAtoms, tree, treeLookupData, ambientLight, numLights, lights, numIntrinsicLights, intrinsicLights, rayArray);
                
                if (c1.w > 0) {
                    colour = colour + c1;
                    rayModelHits++;
                }
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
                
                float4 c1;
                c1 = singleRayTrace(p1, d1, data, numAtoms, tree, treeLookupData, ambientLight, numLights, lights, numIntrinsicLights, intrinsicLights, rayArray);
                
                if (c1.w > 0) {
                    colour = colour + c1;
                    rayModelHits++;
                }
            }
            
        }
        
        float numPoints = (float)aaSteps;
        float alpha = colour.w / numPoints;
        colour = colour / (float)rayModelHits;
        colour.w = alpha;
        
        
       /* if (aperture > 0) {
            //plane at focal point with central ray direction as normal
            float4 centralRayDirectionUnit = normalize(centralRayDirection);
            float4 focalPointCenter = centralRayStart + centralRayDirectionUnit * focalDistance;
            
            
            //calculate intersection of this plane with the ray coming in
            float d = dot(centralRayDirectionUnit, focalPointCenter);
            float4 focalPoint;
            focalPoint = rayStart + rayDirection[i] * (d - dot(centralRayDirectionUnit, rayStart))/dot(centralRayDirectionUnit, rayDirection[i]);
            
            if (centralRayDirectionUnit.z != 0) {
                float zx = -1 * centralRayDirectionUnit.x /centralRayDirectionUnit.z;
                float4 xUnit = (float4)(1,0,zx,0);
                float4 yUnit;
                xUnit = normalize(xUnit);
                yUnit = cross(xUnit, centralRayDirectionUnit);
                yUnit = normalize(yUnit);
                
                float4 p1, p2, p3, p4, d1, d2, d3, d4;
                p1 = centralRayStart - xUnit * aperture;
                p2 = centralRayStart + xUnit * aperture;
                p3 = centralRayStart - yUnit * aperture;
                p4 = centralRayStart + yUnit * aperture;
                d1 = focalPoint - p1;
                d2 = focalPoint - p2;
                d3 = focalPoint - p3;
                d4 = focalPoint - p4;
                
                float4 c1, c2, c3, c4;
                c1 = singleRayTrace(p1, d1, data, numAtoms, bvh, bvhMembers, ambientLight, numLights, lights);
                c2 = singleRayTrace(p2, d2, data, numAtoms, bvh, bvhMembers, ambientLight, numLights, lights);
                c3 = singleRayTrace(p3, d3, data, numAtoms, bvh, bvhMembers, ambientLight, numLights, lights);
                c4 = singleRayTrace(p4, d4, data, numAtoms, bvh, bvhMembers, ambientLight, numLights, lights);
                
                colour = (c1 + c2 + c3 + c4) / (float)4.0;
            }
        } else {
            colour = singleRayTrace(rayStart, rayDirection[i], data, numAtoms, bvh, bvhMembers, ambientLight, numLights, lights);
        }*/
    }
    
//    if (colour.w < 1.0)
//        output[i].x = 0;
//    else
//        output[i].x = 255;
    output[i].x = (uchar)(colour.w * 255.0);
    output[i].y = (uchar)(colour.x * 255.0);
    output[i].z = (uchar)(colour.y * 255.0);
    output[i].w = (uchar)(colour.z * 255.0);
    
}