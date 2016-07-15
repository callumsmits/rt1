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

typedef struct _lightTest {
    float3 direction;
    int id;
} lightTest;

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
        unsigned long object;
    } interactionData;

typedef struct tag_bvhItem {
    int nodeIndex;
    float t_value;
} bvhItem;

#define NO_INTERSECTION -1
#define FLOAT_ERROR 0.004
#define LOCAL_MEM_SIZE 32768
#define MAX_LOCAL_FLOATS LOCAL_MEM_SIZE/sizeof(float)
#define MAX_LOCAL_BVHITEMS LOCAL_MEM_SIZE/sizeof(bvhItem)
#define MAX_LOCAL_ATOMS MAX_LOCAL_FLOATS/4
#define INTRINSIC_LIGHT_SCALE_EXP (float)3.0
#define SOFT_SHADOW_SAMPLES 32
#define LIGHTS_TO_COALESCE 16
#define GLOW_LIGHT_SCALE_EXP (float)2.0

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

float4 refractRay(float4 normal, float4 incident, float n1, float n2) {
    float n;
    n = n1 / n2;
    float cosI, sinT2, cosT, r0rth, rPar;
    cosI = (float)-1.0 * dot(normal, incident);
    sinT2 = n * n * ((float)1.0 - cosI * cosI);
    if (sinT2 > 1.0)
        return (float4)(0,0,0,0); //TIR
    cosT = sqrt((float)1.0 - sinT2);
    return n * incident + (n * cosI - cosT) * normal;
}

float reflectance(float4 normal, float4 incident, float n1, float n2) {
    float n;
    n = n1 / n2;
    float cosI, sinT2, cosT, r0rth, rPar;
    cosI = (float)-1.0 * dot(normal, incident);
    sinT2 = n * n * ((float)1.0 - cosI * cosI);
    if (sinT2 > 1.0)
        return (float)1.0; //TIR
    cosT = sqrt((float)1.0 - sinT2);
    r0rth = (n1 * cosI - n2 * cosT) / (n1 * cosI + n2 * cosT);
    rPar = (n2 * cosI - n1 * cosT) / (n2 * cosI + n1 * cosT);
    return (r0rth * r0rth + rPar * rPar) / (float)2.0;
}

float fresnelTransmission(float4 normal, float4 incident, float n1, float n2) {
    return (float)1.0 - reflectance(normal, incident, n1, n2);
}

float fresnelProduct(float n1, float4 incident1, float4 normal1, float n2, float4 incident2, float4 normal2) {
    float f1, f2;
    f1 = fresnelTransmission(normal1, incident1, n1, n2);
    f2 = fresnelTransmission(normal2, incident2, n2, n1);
//    if (get_global_id(0) == 4331) printf("f1: %.2f f2: %.2f\n", f1, f2);
    return f1 * f2;
}

float4 doubleRaySphereInteractionTest(float4 pos, float radius, float4 rayStart, float4 rayDirection) {
    
    float4 raySphereDifference;
    float b, c, bSqr, c4, t1, t2, tClosest;
    
    raySphereDifference = rayStart - pos;
    
    b = 2 * dot(rayDirection, raySphereDifference);
    c = dot(raySphereDifference, raySphereDifference) - radius * radius;
    
    bSqr = b * b;
    //        ac4 = 4 * c;
    c4 = 4 * c;
    
    //assume an intersection already...
    if (b > 0)
        t1 = (-b - sqrt(bSqr - c4))*0.5;
    else
        t1 = (-b + sqrt(bSqr - c4))*0.5;
    
    t2 = c / t1;
    
    return (float4)(t1, t2, 0, 0);
    
}

float raySphereInteractionTest(float4 pos, float radius, float4 rayStart, float4 rayDirection) {
    
    float4 raySphereDifference;
    float b, c, bSqr, c4, t1, t2, tClosest;
    
    tClosest = NO_INTERSECTION;
    
    raySphereDifference = rayStart - pos;
    
    b = 2 * dot(rayDirection, raySphereDifference);
    c = dot(raySphereDifference, raySphereDifference) - radius * radius;
    
    bSqr = b * b;
    //        ac4 = 4 * c;
    c4 = 4 * c;
    
    /*if there is, then compare the t value to the closest intersection, and
     if it is closer, then make this value the closest. Treat tangent as not intersection.
     Use the three step method, page 4 of raytracing handout.*/
    if (bSqr >= c4)
    {
        if (b > 0)
            t1 = (-b - sqrt(bSqr - c4))*0.5;
        else
            t1 = (-b + sqrt(bSqr - c4))*0.5;
        
        t2 = c / t1;
        
        if ((t1 > 0) && ((t1 < t2) || (t2 < 0)))
        {
            tClosest = t1;
        }
        else if (t2 > 0)
        {
            tClosest = t2;
        }
        
    }
        /*t1 = (-b - sqrt(bSqr - c4)) * 0.5;
         
         if (t1 < 0) {
         t1 = (-b + sqrt(bSqr - c4)) * 0.5;
         }
         
         //if this is the first intersection, set the closer object greater than zero closest.
         if ((tClosest == NO_INTERSECTION) && (t1 >=0 ))
         {
         tClosest = t1;
         closestAtom = i;
         }
         //otherwise, if the point is closer than the closest, and greater than zero, than set
         //it as the closest
         else if ((t1 < tClosest) && (t1 >= 0)) {
         tClosest = t1;
         closestAtom = i;
         }*/
    
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

interactionData rayIntersection(global const float* input, const unsigned long numAtoms, float4 rayStart, float4 rayDirection)
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
    
    if (tClosest > 0) {
        intersection.object = closestAtom;
        
//        float4 theIntersection = vectorAdd(rayStart, vectorScale(rayDirection, tClosest), 1);
        float4 theIntersection = rayStart + rayDirection * tClosest;
        intersection.data.s2345 = theIntersection;
        
        pos.xyzw = (float4)(input[closestAtom * NUM_ATOMDATA + X], input[closestAtom * NUM_ATOMDATA + Y], input[closestAtom * NUM_ATOMDATA + Z], 1.0);
        float4 radius = theIntersection - pos;
        vdw = input[closestAtom * NUM_ATOMDATA + VDW];
//        intersection.data.s6789 = vectorScale(radius, 1.0 / vdw);
        intersection.data.s6789 = radius / vdw;

    }
    
    return intersection;
    
}



//The rayStart is assumed to be one of the atom positions, so test for this and exclude from consideration
interactionData rayIntersectionTreeMinimalIntrinsic(global const float* input, int numAtoms, global const octree* tree, global const uint* treeLookupData, float4 rayStart, float4 rayDirection) {
    
    unsigned long i;
    
    float4 pos;
    float vdw, t1, tClosest, nodeRadius;
    unsigned long closestAtom;
    uint currentNode;
    
    tClosest = NO_INTERSECTION;
    currentNode = 0;
    
    while (currentNode != UINT_MAX) {
        //        if (get_global_id(0) == 33) {
        //            printf("i: %d node: %u pos %.2f %.2f %.2f %.2f radius: %.2f hit: %u miss: %u\n",get_global_id(0), currentNode, tree[currentNode].position.x, tree[currentNode].position.y, tree[currentNode].position.z, tree[currentNode].position.w, tree[currentNode].radius, tree[currentNode].hit, tree[currentNode].miss);
        //        }
        pos = tree[currentNode].position;
        nodeRadius = tree[currentNode].radius;
        t1 = raySphereInteractionTest(pos, nodeRadius, rayStart, rayDirection);
        
        if (t1 >=0) {
            
            if (tree[currentNode].leafNode) {
                unsigned int leafBaseIndex = tree[currentNode].leafStart;
                
                for (i = 0; i < tree[currentNode].leafMembers; i++) {
                    unsigned int atom = treeLookupData[leafBaseIndex + i];
                    pos.xyzw = (float4)(input[atom * NUM_ATOMDATA + X], input[atom * NUM_ATOMDATA + Y], input[atom * NUM_ATOMDATA + Z], 1.0);
                    vdw = input[atom * NUM_ATOMDATA + VDW];
                    
                    t1 = raySphereInteractionTest(pos, vdw, rayStart, rayDirection);
                    
                    if ((pos.x == rayStart.x) && (pos.y == rayStart.y) && (pos.z == rayStart.z)) {
                        t1 = NO_INTERSECTION;
                    }
                    
                    if (t1 >= 0) {
                        if (tClosest == NO_INTERSECTION) {
                            tClosest = t1;
                            closestAtom = atom;
                        } else if (t1 < tClosest) {
                            tClosest = t1;
                            closestAtom = atom;
                        }
                    }
                }
            }
            
            currentNode = tree[currentNode].hit;
            
        } else {
            currentNode = tree[currentNode].miss;
            
        }
        
    }
    
    
    interactionData intersection;
    
    intersection.data.s0 = tClosest;
    
    return intersection;
    
}

/*bool allLightsFinished(uint *nodeArray, int numLightDirections) {
    bool retValue;
    retValue = 1;
    for (int i = 0; i < numLightDirections; i++) {
        retValue &= (nodeArray[i] == UINT_MAX);
    }
    
    return retValue;
}

uint nextNodeFromGroup(uint *nodeArray) {
    uint highestNode;
    highestNode = nodeArray[0];
    
    for (int i = 1; i < LIGHTS_TO_COALESCE; i++) {
        uint nextValue = nodeArray[i] == UINT_MAX ? 0 : nodeArray[i];
        highestNode = nextValue > highestNode ? nextValue : highestNode;
    }
    
    return highestNode;
}

interactionData rayIntersectionTreeLighting(global const float* input, int numAtoms, global const octree* tree, global const uint* treeLookupData, float4 rayStart, lightTest *lightDirections, int numLightDirections) {
    
    unsigned long i;
    
    float4 pos;
    float vdw, t1, nodeRadius;
    uint currentNode[LIGHTS_TO_COALESCE];
    float tCloeset[LIGHTS_TO_COALESCE];
    
    for (i = 0; i < LIGHTS_TO_COALESCE; i++) {
        currentNode[i] = 0;
    }
    
    tClosest = NO_INTERSECTION;
    currentNode = 0;
    
    while (!allLightsFinished(currentNode)) {
        //        if (get_global_id(0) == 33) {
        //            printf("i: %d node: %u pos %.2f %.2f %.2f %.2f radius: %.2f hit: %u miss: %u\n",get_global_id(0), currentNode, tree[currentNode].position.x, tree[currentNode].position.y, tree[currentNode].position.z, tree[currentNode].position.w, tree[currentNode].radius, tree[currentNode].hit, tree[currentNode].miss);
        //        }
        pos = tree[currentNode].position;
        nodeRadius = tree[currentNode].radius;
        t1 = raySphereInteractionTest(pos, nodeRadius, rayStart, rayDirection);
        
        if (t1 >=0) {
            
            if (tree[currentNode].leafNode) {
                unsigned int leafBaseIndex = tree[currentNode].leafStart;
                
                for (i = 0; i < tree[currentNode].leafMembers; i++) {
                    unsigned int atom = treeLookupData[leafBaseIndex + i];
                    pos.xyzw = (float4)(input[atom * NUM_ATOMDATA + X], input[atom * NUM_ATOMDATA + Y], input[atom * NUM_ATOMDATA + Z], 1.0);
                    vdw = input[atom * NUM_ATOMDATA + VDW];
                    
                    t1 = raySphereInteractionTest(pos, vdw, rayStart, rayDirection);
                    
                    if (t1 >= 0) {
                        if (tClosest == NO_INTERSECTION) {
                            tClosest = t1;
                        } else if (t1 < tClosest) {
                            tClosest = t1;
                        }
                    }
                }
            }
            
            currentNode = tree[currentNode].hit;
            
        } else {
            currentNode = tree[currentNode].miss;
            
        }
        
    }
    
    
    interactionData intersection;
    
    intersection.data.s0 = tClosest;
    
    return intersection;
    
}*/


interactionData rayIntersectionTreeMinimal(global const float* input, int numAtoms, global const octree* tree, global const uint* treeLookupData, float4 rayStart, float4 rayDirection) {
    
    unsigned long i;
    
    float4 pos;
    float vdw, t1, tClosest, nodeRadius;
    unsigned long closestAtom;
    uint currentNode;
    
    tClosest = NO_INTERSECTION;
    currentNode = 0;
    
    while (currentNode != UINT_MAX) {
        //        if (get_global_id(0) == 33) {
        //            printf("i: %d node: %u pos %.2f %.2f %.2f %.2f radius: %.2f hit: %u miss: %u\n",get_global_id(0), currentNode, tree[currentNode].position.x, tree[currentNode].position.y, tree[currentNode].position.z, tree[currentNode].position.w, tree[currentNode].radius, tree[currentNode].hit, tree[currentNode].miss);
        //        }
        pos = tree[currentNode].position;
        nodeRadius = tree[currentNode].radius;
        t1 = raySphereInteractionTest(pos, nodeRadius, rayStart, rayDirection);
        
        if (t1 >=0) {
            
            if (tree[currentNode].leafNode) {
                unsigned int leafBaseIndex = tree[currentNode].leafStart;
                
                for (i = 0; i < tree[currentNode].leafMembers; i++) {
                    unsigned int atom = treeLookupData[leafBaseIndex + i];
                    pos.xyzw = (float4)(input[atom * NUM_ATOMDATA + X], input[atom * NUM_ATOMDATA + Y], input[atom * NUM_ATOMDATA + Z], 1.0);
                    vdw = input[atom * NUM_ATOMDATA + VDW];
                    
                    t1 = raySphereInteractionTest(pos, vdw, rayStart, rayDirection);
                    
                    if (t1 >= 0) {
                        if (tClosest == NO_INTERSECTION) {
                            tClosest = t1;
                            closestAtom = atom;
                        } else if (t1 < tClosest) {
                            tClosest = t1;
                            closestAtom = atom;
                        }
                    }
                }
            }
            
            currentNode = tree[currentNode].hit;
            
        } else {
            currentNode = tree[currentNode].miss;
            
        }
        
    }
    
    
    interactionData intersection;
    
    intersection.data.s0 = tClosest;
    
    return intersection;
    
}

float4 pointGlowColourTree(global const float* input, int numAtoms, global const octree* tree, global const uint* treeLookupData, float4 point, float glowRadius) {
    
    unsigned long i;
    
    float4 pos;
    float vdw, t1, nodeRadius;
    uint currentNode;
    float4 colour;
    uint numTouches;
    
    colour = (float4)(0,0,0,0);
    
    currentNode = 0;
    numTouches = 0;
    
    float glowScale;
    glowScale = -1.0/pow(glowRadius, GLOW_LIGHT_SCALE_EXP);
    
    while (currentNode != UINT_MAX) {
        //        if (get_global_id(0) == 33) {
        //            printf("i: %d node: %u pos %.2f %.2f %.2f %.2f radius: %.2f hit: %u miss: %u\n",get_global_id(0), currentNode, tree[currentNode].position.x, tree[currentNode].position.y, tree[currentNode].position.z, tree[currentNode].position.w, tree[currentNode].radius, tree[currentNode].hit, tree[currentNode].miss);
        //        }
        pos = tree[currentNode].position;
        nodeRadius = tree[currentNode].radius;
        t1 = length(pos - point) - nodeRadius;
        
        if (t1 < glowRadius) {
            
            if ((tree[currentNode].leafNode) && (tree[currentNode].leafMembers > 0)) {
                unsigned int leafBaseIndex = tree[currentNode].leafStart;
                
                for (i = 0; i < tree[currentNode].leafMembers; i++) {
                    unsigned int atom = treeLookupData[leafBaseIndex + i];
                    pos.xyzw = (float4)(input[atom * NUM_ATOMDATA + X], input[atom * NUM_ATOMDATA + Y], input[atom * NUM_ATOMDATA + Z], 1.0);
                    vdw = input[atom * NUM_ATOMDATA + VDW];
                    
                    t1 = length(pos - point) - vdw;
                    
                    if (t1 < glowRadius) {
                        float4 scaledLight;
                        float4 atomColour;
                        atomColour = (float4)(input[atom * NUM_ATOMDATA + INTRINSIC_R], input[atom * NUM_ATOMDATA + INTRINSIC_G], input[atom * NUM_ATOMDATA + INTRINSIC_B], 1.0);
                        if ((atomColour.x == 0) && (atomColour.y == 0) && (atomColour.z == 0)) {
                            atomColour = (float4)(input[atom * NUM_ATOMDATA + DIFFUSE_R], input[atom * NUM_ATOMDATA + DIFFUSE_G], input[atom * NUM_ATOMDATA + DIFFUSE_B], 1.0);
                        }
                        scaledLight = atomColour * (float)0.8 * (float)(pow(t1, GLOW_LIGHT_SCALE_EXP) * glowScale + 1.0);
                        colour += scaledLight;
                        numTouches++;
                    }
                }
            }
            
            currentNode = tree[currentNode].hit;
            
        } else {
            currentNode = tree[currentNode].miss;
            
        }
        
    }
    
    if (numTouches) {
        colour = colour / numTouches;
    }
    return colour;
}

interactionData rayIntersectionTree(global const float* input, int numAtoms, global const octree* tree, global const uint* treeLookupData, float4 rayStart, float4 rayDirection) {

    unsigned long i;
    
    float4 pos;
    float vdw, t1, tClosest, nodeRadius;
    unsigned long closestAtom;
    uint currentNode;
    
    tClosest = NO_INTERSECTION;
    currentNode = 0;
    
    while (currentNode != UINT_MAX) {
//        if (get_global_id(0) == 33) {
//            printf("i: %d node: %u pos %.2f %.2f %.2f %.2f radius: %.2f hit: %u miss: %u\n",get_global_id(0), currentNode, tree[currentNode].position.x, tree[currentNode].position.y, tree[currentNode].position.z, tree[currentNode].position.w, tree[currentNode].radius, tree[currentNode].hit, tree[currentNode].miss);
//        }
        pos = tree[currentNode].position;
        nodeRadius = tree[currentNode].radius;
        t1 = raySphereInteractionTest(pos, nodeRadius, rayStart, rayDirection);
        
        if (t1 >=0) {

            if (tree[currentNode].leafNode) {
                unsigned int leafBaseIndex = tree[currentNode].leafStart;

                for (i = 0; i < tree[currentNode].leafMembers; i++) {
                    unsigned int atom = treeLookupData[leafBaseIndex + i];
                    pos.xyzw = (float4)(input[atom * NUM_ATOMDATA + X], input[atom * NUM_ATOMDATA + Y], input[atom * NUM_ATOMDATA + Z], 1.0);
                    vdw = input[atom * NUM_ATOMDATA + VDW];
                    
                    t1 = raySphereInteractionTest(pos, vdw, rayStart, rayDirection);
                    
                    if (t1 >= 0) {
                        if (tClosest == NO_INTERSECTION) {
                            tClosest = t1;
                            closestAtom = atom;
                        } else if (t1 < tClosest) {
                            tClosest = t1;
                            closestAtom = atom;
                        }
                    }
                }
            }

            currentNode = tree[currentNode].hit;

        } else {
            currentNode = tree[currentNode].miss;

        }
        
    }
    
    
    interactionData intersection;
    
    intersection.data.s0 = tClosest;
    
//    if (tClosest > 0) {
    intersection.object = closestAtom;
    
    float4 theIntersection = rayStart + rayDirection * tClosest;
    intersection.data.s2345 = theIntersection;
    
    pos.xyzw = (float4)(input[closestAtom * NUM_ATOMDATA + X], input[closestAtom * NUM_ATOMDATA + Y], input[closestAtom * NUM_ATOMDATA + Z], 1.0);
    float4 radius = theIntersection - pos;
    vdw = input[closestAtom * NUM_ATOMDATA + VDW];
    intersection.data.s6789 = radius / vdw;
        
//    }
    
    return intersection;

}

/*float4 singleRayTraceMirror(float4 rayStart, float4 rayDirection, global const float* data, const unsigned long numAtoms, global bvhStruct_cl* bvh, global int* bvhMembers, const float4 ambientLight, int numLights, global float8* lights, int numIntrinsicLights, global float* intrinsicLights) {
    
    float4 colour;
    
    float4 rayDirectionUnit = normalize(rayDirection);
    
    //    interactionData intersection = rayIntersection((global const float*)data, numAtoms, rayStart, rayDirectionUnit);
    
    interactionData intersection = rayIntersectionBVH(data, numAtoms, bvh, bvhMembers, rayStart, rayDirectionUnit);
    
    if (intersection.data.s0 < 0)
    {
        colour.x = colour.y = colour.z = 1.0;
        colour.w = 0;
    }
    else
    {
        
        float4 diffuseColour, specularColour, intrinsicColour;
        float phong;
        unsigned long object;
        
        colour.w = 1.0;
        
        object = intersection.object;
        diffuseColour.x = data[object * NUM_ATOMDATA + DIFFUSE_R];
        diffuseColour.y = data[object * NUM_ATOMDATA + DIFFUSE_G];
        diffuseColour.z = data[object * NUM_ATOMDATA + DIFFUSE_B];
        specularColour.x = data[object * NUM_ATOMDATA + SPEC_R];
        specularColour.y = data[object * NUM_ATOMDATA + SPEC_G];
        specularColour.z = data[object * NUM_ATOMDATA + SPEC_B];
        intrinsicColour.x = data[object * NUM_ATOMDATA + INTRINSIC_R];
        intrinsicColour.y = data[object * NUM_ATOMDATA + INTRINSIC_G];
        intrinsicColour.z = data[object * NUM_ATOMDATA + INTRINSIC_B];
        phong = data[object * NUM_ATOMDATA + SHININESS];
        
        float4 intersectPos, normal;
        intersectPos = intersection.data.s2345;
        normal = intersection.data.s6789;
        
        float4 small_intersection_step;
        float small_step = (float)FLOAT_ERROR * length(rayStart - intersectPos);
        small_intersection_step = intersectPos + normal * small_step;
        //        small_intersection_step = vectorAdd(intersectPos, normal * small_step, 1);
        
        colour.x = diffuseColour.x * ambientLight.x + intrinsicColour.x * dot(normal, rayDirectionUnit * (float)-1.0);
        colour.y = diffuseColour.y * ambientLight.y + intrinsicColour.y * dot(normal, rayDirectionUnit * (float)-1.0);
        colour.z = diffuseColour.z * ambientLight.z + intrinsicColour.z * dot(normal, rayDirectionUnit * (float)-1.0);
        //        colour.x = diffuseColour.x * ambientLight.x * dot(normal, rayDirectionUnit * (float)-1.0);
        //        colour.y = diffuseColour.y * ambientLight.y * dot(normal, rayDirectionUnit * (float)-1.0);
        //        colour.z = diffuseColour.z * ambientLight.z * dot(normal, rayDirectionUnit * (float)-1.0);
        
        //Now add the intrinsic lights
        for (int il = 0; il < numIntrinsicLights; il++) {
            float4 intrinsicLightDirection, ilPosition, ilColour;
            float intrinsicLightVDW, distanceCutoff, ilDistance;
            
            ilPosition.x = intrinsicLights[il * NUM_INTRINSIC_LIGHT_DATA + XI];
            ilPosition.y = intrinsicLights[il * NUM_INTRINSIC_LIGHT_DATA + YI];
            ilPosition.z = intrinsicLights[il * NUM_INTRINSIC_LIGHT_DATA + ZI];
            intrinsicLightVDW = intrinsicLights[il * NUM_INTRINSIC_LIGHT_DATA + VDWI];
            ilColour.x = intrinsicLights[il * NUM_INTRINSIC_LIGHT_DATA + RED];
            ilColour.y = intrinsicLights[il * NUM_INTRINSIC_LIGHT_DATA + GREEN];
            ilColour.z = intrinsicLights[il * NUM_INTRINSIC_LIGHT_DATA + BLUE];
            distanceCutoff = intrinsicLights[il * NUM_INTRINSIC_LIGHT_DATA + CUTOFF];
            ilPosition.w = 0;
            
            intrinsicLightDirection = ilPosition - intersectPos;
            ilDistance = length(intrinsicLightDirection) - intrinsicLightVDW;
            if ((ilDistance < distanceCutoff) && (!(intrinsicColour.x + intrinsicColour.y + intrinsicColour.z > 0))) {
                float4 ilDirectionUnit;
                ilDirectionUnit = normalize(intrinsicLightDirection);
                //Scale light linearly by distance until cutoff
                float ilDistanceScale;
                ilDistanceScale = -1.0/pow(distanceCutoff, INTRINSIC_LIGHT_SCALE_EXP);
                if (dot(normal, ilDirectionUnit) > 0) {
                    float4 scaledLight;
                    
                    scaledLight = ilColour * (float)(pow(ilDistance, INTRINSIC_LIGHT_SCALE_EXP) * ilDistanceScale + 1.0);
                    
                    float4 phongMirror = mirrorRay(intrinsicLightDirection, normal, ilPosition);
                    
                    float4 Lunit, viewDirection, mirrorUnit;
                    
                    //                Lunit = normalize(lightRayDirection);
                    viewDirection = normalize(rayDirection * (float)-1.0);
                    mirrorUnit = normalize(phongMirror);
                    
                    float lDotN = dot(ilDirectionUnit, normal);
                    float rDotV = dot(mirrorUnit, viewDirection);
                    float specScale = pow(rDotV, phong);
                    
                    colour.x = colour.x + diffuseColour.x * lDotN * scaledLight.x + specularColour.x * specScale * scaledLight.x;
                    colour.y = colour.y + diffuseColour.y * lDotN * scaledLight.y + specularColour.y * specScale * scaledLight.y;
                    colour.z = colour.z + diffuseColour.z * lDotN * scaledLight.z + specularColour.z * specScale * scaledLight.z;
                    
                    //                    colour.x = colour.x + ilColour.x * fabs(dot(normal, ilDirectionUnit)) * (ilDistance * ilDistanceScale + 1.0);
                    //                    colour.y = colour.y + ilColour.y * fabs(dot(normal, ilDirectionUnit)) * (ilDistance * ilDistanceScale + 1.0);
                    //                    colour.z = colour.z + ilColour.z * fabs(dot(normal, ilDirectionUnit)) * (ilDistance * ilDistanceScale + 1.0);
                }
            }
        }
        
        float scale = dot(normal, rayDirectionUnit * (float)-1.0);
        float4 lightRayStart = intersectPos + normal * small_step * scale;
        
        for (int counter = 0;counter < numLights;counter++)
        {
            
            float4 lightPosition = lights[counter].s0123;
            //            float4 lightPosition = (float4)(100,-100,-200,1);
            float4 lightRayDirection = lightPosition - lightRayStart;
            float scale = length(lightRayDirection);
            lightRayDirection = normalize(lightRayDirection);
            //            float4 lightRayDirection = vectorSubtract(lightPosition, lightRayStart, 0);
            
            //Find any intersections along this ray
            interactionData lightIntersection = rayIntersectionBVHMinimal(data, numAtoms, bvh, bvhMembers, lightRayStart, lightRayDirection);
            //            interactionData lightIntersection = rayIntersectionBVH(data, numAtoms, bvh, bvhMembers, lightRayStart, lightRayDirection);
            //            interactionData lightIntersection = minimalRayIntersection(data, numAtoms, lightRayStart, lightRayDirection);
            //            interactionData lightIntersection = rayIntersection(data, numAtoms, lightRayStart, lightRayDirection);
            //            interactionData lightIntersection;
            //            lightIntersection.data.s0 = 0.1;
            
            float intersectionT = lightIntersection.data.s0 / scale;
            
            
            if ((intersectionT < 0.0) || (intersectionT > 1.0))
            {
                float4 phongMirror = mirrorRay(lightRayDirection, normal, lightRayStart);
                
                float4 Lunit, viewDirection, mirrorUnit;
                
                //                Lunit = normalize(lightRayDirection);
                viewDirection = normalize(rayDirection * (float)-1.0);
                mirrorUnit = normalize(phongMirror);
                
                float lDotN = dot(lightRayDirection, normal);
                float rDotV = dot(mirrorUnit, viewDirection);
                float specScale = pow(rDotV, phong);
                
                //                if ((get_global_id(0) == 143611) || (get_global_id(0) == 144123)) {
                //                    printf("i: %d, M: %f %f %f %f, MU: %f %f %f %f, VD: %f %f %f %f, rdv: %f, ss: %f\n",get_global_id(0), phongMirror.x, phongMirror.y, phongMirror.z, phongMirror.w, mirrorUnit.x, mirrorUnit.y, mirrorUnit.z, mirrorUnit.w, viewDirection.x, viewDirection.y, viewDirection.z, viewDirection.w, rDotV, specScale);
                //                }
                
                colour.x = colour.x + diffuseColour.x * lDotN * lights[counter].s4 + specularColour.x * specScale * lights[counter].s4;
                colour.y = colour.y + diffuseColour.y * lDotN * lights[counter].s5 + specularColour.y * specScale * lights[counter].s5;
                colour.z = colour.z + diffuseColour.z * lDotN * lights[counter].s6 + specularColour.z * specScale * lights[counter].s6;
                
            }
        }
    }
    
    if (colour.x < 0.)
        colour.x = 0;
    else if (colour.x > 1.0)
        colour.x = 1.0;
    
    if (colour.y < 0.)
        colour.y = 0;
    else if (colour.y > 1.0)
        colour.y = 1.0;
    
    if (colour.z < 0.)
        colour.z = 0;
    else if (colour.z > 1.0)
        colour.z = 1.0;
    
    return colour;
}*/

float4 singleRayTrace(float4 rayStart, float4 rayDirection, global const float* data, const unsigned long numAtoms, global const octree* tree, global const uint* treeLookupData, const float4 ambientLight, int numLights, global float8* lights, int numIntrinsicLights, global float* intrinsicLights) {
    
    float4 colour;
    
    float4 rayDirectionUnit = normalize(rayDirection);
    
//    interactionData intersection = rayIntersection((global const float*)data, numAtoms, rayStart, rayDirectionUnit);
    
    interactionData intersection = rayIntersectionTree(data, numAtoms, tree, treeLookupData, rayStart, rayDirectionUnit);
    
    if (intersection.data.s0 < 0)
    {
        colour.x = colour.y = colour.z = 0.0;
        colour.w = 0;
        
/*        float maxDist, currentDistance, sampleStep;
        sampleStep = 5;
        maxDist = length(tree[0].position - rayStart) + tree[0].radius;
        currentDistance = sampleStep;
        int numTouches;
        numTouches = 0;
        while (currentDistance < maxDist) {
            float4 pos, pointC;
            pos = rayStart + rayDirectionUnit * currentDistance;
            pointC = pointGlowColourTree(data, numAtoms, tree, treeLookupData, pos, 4.0);
            if (pointC.w > 0) {
                numTouches++;
                colour += pointC;
            }
            currentDistance += sampleStep;
        }
        if (numTouches) {
            colour = colour / numTouches;
        }*/
    }
    else
    {
        
        float4 diffuseColour, specularColour, intrinsicColour, atomPos;
        float phong, mirrorFrac, atomRadius;
        unsigned long object;
        
        colour.w = 1.0;
        
        object = intersection.object;
        atomPos.x = data[object * NUM_ATOMDATA + X];
        atomPos.y = data[object * NUM_ATOMDATA + Y];
        atomPos.z = data[object * NUM_ATOMDATA + Z];
        atomPos.w = 1.0;
        atomRadius = data[object * NUM_ATOMDATA + VDW];
        diffuseColour.x = data[object * NUM_ATOMDATA + DIFFUSE_R];
        diffuseColour.y = data[object * NUM_ATOMDATA + DIFFUSE_G];
        diffuseColour.z = data[object * NUM_ATOMDATA + DIFFUSE_B];
        specularColour.x = data[object * NUM_ATOMDATA + SPEC_R];
        specularColour.y = data[object * NUM_ATOMDATA + SPEC_G];
        specularColour.z = data[object * NUM_ATOMDATA + SPEC_B];
        intrinsicColour.x = data[object * NUM_ATOMDATA + INTRINSIC_R];
        intrinsicColour.y = data[object * NUM_ATOMDATA + INTRINSIC_G];
        intrinsicColour.z = data[object * NUM_ATOMDATA + INTRINSIC_B];
        phong = data[object * NUM_ATOMDATA + SHININESS];
        mirrorFrac = data[object * NUM_ATOMDATA + MIRROR_FRAC];
        
        float4 intersectPos, normal;
        intersectPos = intersection.data.s2345;
        normal = intersection.data.s6789;
        
        float4 small_intersection_step;
        float small_step = (float)FLOAT_ERROR * length(rayStart - intersectPos);
        small_intersection_step = intersectPos + normal * small_step;
        //        small_intersection_step = vectorAdd(intersectPos, normal * small_step, 1);
        
        /*if (get_global_id(0) == 131328) {
            float4 pos;
            pos.x = data[object * NUM_ATOMDATA + X];
            pos.y = data[object * NUM_ATOMDATA + Y];
            pos.z = data[object * NUM_ATOMDATA + Z];
            printf("O: %d, pos: %f %f %f, intersect: %f %f %f %f, normal: %f %f %f %f\n", object, pos.x, pos.y, pos.z, intersectPos.x, intersectPos.y, intersectPos.z, intersectPos.w, normal.x, normal.y, normal.z, normal.w);
        }*/
        float4 p;
        p.x = data[object * NUM_ATOMDATA + X];
        p.y = data[object * NUM_ATOMDATA + Y];
        p.z = data[object * NUM_ATOMDATA + Z];
//        printf("i: %d, O: %d, pos: %f %f %f, intersect: %f %f %f %f, normal: %f %f %f %f\n", (int)get_global_id(0), object, p.x, p.y, p.z, intersectPos.x, intersectPos.y, intersectPos.z, intersectPos.w, normal.x, normal.y, normal.z, normal.w);
        float visibleFraction;
        visibleFraction = 0;
        uint seed;
        seed = intersectPos.x;
        size_t gid = get_global_id(0);
        
        for (int i = 0; i < 2 * LIGHTS_TO_COALESCE; i++) {
            float4 s;
            s.x = randomFloat(2.0, &seed, gid) - (float)1.0;
            s.y = randomFloat(2.0, &seed, gid) - (float)1.0;
            s.z = randomFloat(2.0, &seed, gid) - (float)1.0;
            s.w = 0;
            s = normalize(s);
            if (dot(s, normal) < 0) {
                s = s * (float)-1.0;
            }
            interactionData lightIntersection = rayIntersectionTreeMinimalIntrinsic(data, numAtoms, tree, treeLookupData, small_intersection_step, s);
            if (lightIntersection.data.s0 < 0) {
                visibleFraction += 1.0 / (float)(2 * LIGHTS_TO_COALESCE);
            }
        }
        
        colour.x = diffuseColour.x * ambientLight.x * visibleFraction + intrinsicColour.x * dot(normal, rayDirectionUnit * (float)-1.0);
        colour.y = diffuseColour.y * ambientLight.y * visibleFraction + intrinsicColour.y * dot(normal, rayDirectionUnit * (float)-1.0);
        colour.z = diffuseColour.z * ambientLight.z * visibleFraction + intrinsicColour.z * dot(normal, rayDirectionUnit * (float)-1.0);
//        colour.x = diffuseColour.x * ambientLight.x + intrinsicColour.x * dot(normal, rayDirectionUnit * (float)-1.0);
//        colour.y = diffuseColour.y * ambientLight.y + intrinsicColour.y * dot(normal, rayDirectionUnit * (float)-1.0);
//        colour.z = diffuseColour.z * ambientLight.z + intrinsicColour.z * dot(normal, rayDirectionUnit * (float)-1.0);
//        colour.x = diffuseColour.x * ambientLight.x * dot(normal, rayDirectionUnit * (float)-1.0);
//        colour.y = diffuseColour.y * ambientLight.y * dot(normal, rayDirectionUnit * (float)-1.0);
//        colour.z = diffuseColour.z * ambientLight.z * dot(normal, rayDirectionUnit * (float)-1.0);

        //Now add the intrinsic lights
        for (int il = 0; il < numIntrinsicLights; il++) {
            float4 intrinsicLightDirection, ilPosition, ilColour;
            float intrinsicLightVDW, distanceCutoff, ilDistance;
            int mode;
            
            ilPosition.x = intrinsicLights[il * NUM_INTRINSIC_LIGHT_DATA + XI];
            ilPosition.y = intrinsicLights[il * NUM_INTRINSIC_LIGHT_DATA + YI];
            ilPosition.z = intrinsicLights[il * NUM_INTRINSIC_LIGHT_DATA + ZI];
            intrinsicLightVDW = intrinsicLights[il * NUM_INTRINSIC_LIGHT_DATA + VDWI];
            ilColour.x = intrinsicLights[il * NUM_INTRINSIC_LIGHT_DATA + RED];
            ilColour.y = intrinsicLights[il * NUM_INTRINSIC_LIGHT_DATA + GREEN];
            ilColour.z = intrinsicLights[il * NUM_INTRINSIC_LIGHT_DATA + BLUE];
            distanceCutoff = intrinsicLights[il * NUM_INTRINSIC_LIGHT_DATA + CUTOFF];
            mode = intrinsicLights[il * NUM_INTRINSIC_LIGHT_DATA + MODE];
            ilPosition.w = 1;
            
            intrinsicLightDirection = ilPosition - small_intersection_step;
            ilDistance = length(intrinsicLightDirection) - intrinsicLightVDW;
            if ((ilDistance < distanceCutoff) && (!(intrinsicColour.x + intrinsicColour.y + intrinsicColour.z > 0))) {
                float4 ilDirectionUnit;
                ilDirectionUnit = normalize(intrinsicLightDirection);
                //Scale light linearly by distance until cutoff
                float ilDistanceScale;
                ilDistanceScale = -1.0/pow(distanceCutoff, INTRINSIC_LIGHT_SCALE_EXP);
                
                int noObstruction;
                noObstruction = 0;
                if (mode == REAL_POINT_SOURCE) {
                    interactionData lightIntersection = rayIntersectionTreeMinimalIntrinsic(data, numAtoms, tree, treeLookupData, small_intersection_step, ilDirectionUnit);
                    float intersectionT = lightIntersection.data.s0 / (length(intrinsicLightDirection) - intrinsicLightVDW);

                    if ((intersectionT < 0) || (intersectionT > 1.0)) {
                        noObstruction = 1;
                    }
                }
                int crudeOneFace;
                crudeOneFace = 0;
                if ((mode == CRUDE_ONE_FACE) && ((dot(normal, ilDirectionUnit) > 0)))
                    crudeOneFace = 1;
                
                if ((crudeOneFace) || (mode == CRUDE_TWO_FACE) || (noObstruction)) {
                    float4 scaledLight;
                    
                    scaledLight = ilColour * (float)(pow(ilDistance, INTRINSIC_LIGHT_SCALE_EXP) * ilDistanceScale + 1.0);
                    
                    float4 phongMirror = mirrorRay(intrinsicLightDirection, normal, small_intersection_step);
                    
                    float4 Lunit, viewDirection, mirrorUnit;
                    
                    //                Lunit = normalize(lightRayDirection);
                    viewDirection = normalize(rayDirection * (float)-1.0);
                    mirrorUnit = normalize(phongMirror);
                    
                    float lDotN = dot(ilDirectionUnit, normal);
                    if (mode == CRUDE_TWO_FACE) {
                        lDotN = fabs(lDotN);
                    } //else if (lDotN < 0) {
                        //lDotN = 0;
                    //}
                    float rDotV = dot(mirrorUnit, viewDirection);
                    float specScale = pow(rDotV, phong);
//                    if (rDotV < 0)
//                        specScale = 0;
                    
                    colour.x = colour.x + diffuseColour.x * lDotN * scaledLight.x + specularColour.x * specScale * scaledLight.x;
                    colour.y = colour.y + diffuseColour.y * lDotN * scaledLight.y + specularColour.y * specScale * scaledLight.y;
                    colour.z = colour.z + diffuseColour.z * lDotN * scaledLight.z + specularColour.z * specScale * scaledLight.z;
                    
                    //                    colour.x = colour.x + ilColour.x * fabs(dot(normal, ilDirectionUnit)) * (ilDistance * ilDistanceScale + 1.0);
                    //                    colour.y = colour.y + ilColour.y * fabs(dot(normal, ilDirectionUnit)) * (ilDistance * ilDistanceScale + 1.0);
                    //                    colour.z = colour.z + ilColour.z * fabs(dot(normal, ilDirectionUnit)) * (ilDistance * ilDistanceScale + 1.0);
                }
                if (mode == REAL_BROAD_SOURCE) {
                    float4 s;
                    for (int l = 0; l < SOFT_SHADOW_SAMPLES; l++) {
                        s.x = randomFloat(2.0, &seed, gid) - (float)1.0;
                        s.y = randomFloat(2.0, &seed, gid) - (float)1.0;
                        s.z = randomFloat(2.0, &seed, gid) - (float)1.0;
                        s.w = 0;
                        s = s * (float)(intrinsicLightVDW / length(s) + small_step);
                        if (dot(s, ilDirectionUnit) > 0) {
                            s = s * (float)-1.0;
                        }
                        s = s + ilPosition;
                        float4 sDirection, sDirectionUnit;
                        sDirection = s - small_intersection_step;
                        sDirectionUnit = normalize(sDirection);
                        interactionData lightIntersection = rayIntersectionTreeMinimalIntrinsic(data, numAtoms, tree, treeLookupData, small_intersection_step, sDirectionUnit);
                        float intersectionT = lightIntersection.data.s0 / length(sDirection);
                        
                        if ((intersectionT < 0) | (intersectionT > 1.0)) {
                            float4 scaledLight;
                            float sDistance;
                            sDistance = length(sDirection);
                            
                            scaledLight = ilColour * (float)(pow(sDistance, INTRINSIC_LIGHT_SCALE_EXP) * ilDistanceScale + 1.0) / (float)SOFT_SHADOW_SAMPLES;
                            
                            float4 phongMirror = mirrorRay(sDirection, normal, s);
                            
                            float4 Lunit, viewDirection, mirrorUnit;
                            
                            //                Lunit = normalize(lightRayDirection);
                            viewDirection = normalize(rayDirection * (float)-1.0);
                            mirrorUnit = normalize(phongMirror);
                            
                            float lDotN = dot(sDirectionUnit, normal);
                            if (lDotN < 0) {
                                lDotN = 0;
                            }
                            float rDotV = dot(mirrorUnit, viewDirection);
                            float specScale = pow(rDotV, phong);
                            if (rDotV < 0)
                                specScale = 0;
                            
                            colour.x = colour.x + diffuseColour.x * lDotN * scaledLight.x + specularColour.x * specScale * scaledLight.x;
                            colour.y = colour.y + diffuseColour.y * lDotN * scaledLight.y + specularColour.y * specScale * scaledLight.y;
                            colour.z = colour.z + diffuseColour.z * lDotN * scaledLight.z + specularColour.z * specScale * scaledLight.z;
                        }
                    }
                }
            }
        }
        
        /*Now time to cycle through the lights. If the ray reaches the light, then calculate the
         lambertian and phong lighting that results from it.*/
        /*set up the ray - first move a step away from the intersection point in the direction
         of the normal*/
        float scale = dot(normal, rayDirectionUnit * (float)-1.0);
        float4 lightRayStart = intersectPos + normal * small_step * scale;
        
        for (int counter = 0;counter < numLights;counter++)
        {
            
            float4 lightPosition = lights[counter].s0123;
//            float4 lightPosition = (float4)(100,-100,-200,1);
            
            //Sub surface scattering - BSSRDF model, see Jensen et al. A Practical model for Subsurface Light Transport.
            float4 os, oa, ot, albedo;
            float nMedium, nAtoms, otLength, nRatio, fdr;
            nMedium = 1.0;
            nAtoms = 1.3;
            nRatio = nAtoms / nMedium;
            fdr = (float)-1.440 / (nRatio * nRatio) + (float)0.710 / nRatio + (float)0.668 + (float)0.0636 * nRatio;
            //Ketchup
//            os.x = 0.18; os.y = 0.07; os.z = 0.03; os.w = 0;
//            oa.x = 0.061; oa.y = 0.97; oa.z = 1.45; oa.w = 0;
            //Marble
            //            os.x = 2.19; os.y = 2.62; os.z = 3.00; os.w = 0;
            //            oa.x = 0.0021; oa.y = 0.0041; oa.z = 0.0071; oa.w = 0;
            //Skin
            //            os.x = 1.09; os.y = 1.59; os.z = 1.79; os.w = 0;
            //            oa.x = 0.013; oa.y = 0.07; oa.z = 0.145; oa.w = 0;
            //Whole Milk
            //            os.x = 2.55; os.y = 3.21; os.z = 3.77; os.w = 0;
            //            oa.x = 0.0011; oa.y = 0.0024; oa.z = 0.014; oa.w = 0;
            //Play
//            os.x = 0.4; os.y = 0.; os.z = 0.; os.w = 0;
//            oa.x = 0.0004; oa.y = 0.0; oa.z = 0.0; oa.w = 5.0;
            os = 0.8f * diffuseColour;
            oa = 0.0008f * diffuseColour;
            os.w = 0.0f;
            oa.w = 5.0f;
            ot = os + oa;
            otLength = length(ot);
            albedo = os / otLength;
            //            if (gid == 0) printf("%.2f %.2f %.2f %.2f", albedo.x, albedo.y, albedo.z, albedo.w);
            
            //single scattering
            //find the refraction ray inside
            float4 refractedRay, actualRefractedRay, ssLight;
            ssLight = (float4)(0,0,0,0);
            refractedRay = refractRay(normal, rayDirectionUnit, nMedium, nAtoms);
            actualRefractedRay = refractedRay * (float)-1.0;
            //            printf("n: %.2f %.2f %.2f %.2f rdu: %.2f %.2f %.2f %.2f refracted: %.2f %.2f %.2f %.2f\n", normal.x, normal.y, normal.z, normal.w, rayDirectionUnit.x, rayDirectionUnit.y, rayDirectionUnit.z, rayDirectionUnit.w, refractedRay.x, refractedRay.y, refractedRay.z, refractedRay.w);
            for (int i = 0; i < LIGHTS_TO_COALESCE; i++) {
                float random, surfaceTValue;
                random = randomFloat(1.0, &seed, gid);
                float4 internalPoint, pointToLightDirection, surfaceIntersection, surfaceNormal, lightToPointDirection, outsideSurfacePoint;
                //Choose internal point
                internalPoint = intersectPos + refractedRay * random / otLength;
                pointToLightDirection = normalize(lightPosition - internalPoint);
                //find where this intersects with the sphere
                surfaceTValue = raySphereInteractionTest(atomPos, atomRadius, internalPoint, pointToLightDirection);
                surfaceIntersection = internalPoint + pointToLightDirection * surfaceTValue;
                surfaceNormal = (surfaceIntersection - atomPos) / atomRadius;
                
                outsideSurfacePoint = surfaceIntersection + small_step * surfaceNormal;
                interactionData ssIntersection = rayIntersectionTreeMinimal(data, numAtoms, tree, treeLookupData, outsideSurfacePoint, pointToLightDirection);
                float scaledIntersection = ssIntersection.data.s0 / length(outsideSurfacePoint - lightPosition);
                
                if ((scaledIntersection < 0) || (scaledIntersection > 1)) {
                    lightToPointDirection = pointToLightDirection * (float)-1.0;
                    float g, si, fp;
                    g = fabs(dot(normal, rayDirectionUnit * (float)-1.0)) / fabs(dot(surfaceNormal, lightToPointDirection));
                    si = length(surfaceIntersection - internalPoint) * fabs(dot(lightToPointDirection, surfaceNormal)) / sqrt((float)1.0 - (nMedium / nAtoms) * (nMedium / nAtoms) * ((float)1 - pow(dot(lightToPointDirection, surfaceNormal),2)));
                    fp = fresnelProduct(nMedium, lightToPointDirection, surfaceNormal, nAtoms, actualRefractedRay, (float)-1.0 * normal);
                    ssLight.x += (os.x * fp / (g * (float)3.0 * ot.x)) * exp((float)-1.0 * si * ot.x) * exp((float)-1.0 * length(refractedRay)*ot.x) * lights[counter].s4;
                    ssLight.y += (os.y * fp / (g * (float)3.0 * ot.y)) * exp((float)-1.0 * si * ot.y) * exp((float)-1.0 * length(refractedRay)*ot.y) * lights[counter].s5;
                    ssLight.z += (os.z * fp / (g * (float)3.0 * ot.z)) * exp((float)-1.0 * si * ot.z) * exp((float)-1.0 * length(refractedRay)*ot.z) * lights[counter].s6;
                    //                    if (gid == 4331) {
                    //                        printf("i: %d n: %.2f %.2f %.2f %.2f sn: %.2f %.2f %.2f %.2f rdu: %.2f %.2f %.2f %.2f atomP: %.2f %.2f %.2f rad: %.2f random: %.2f g: %.2f si: %.2f fp: %.2f internalP: %.2f %.2f %.2f %.2f red: %.2f\n", i, normal.x, normal.y, normal.z, normal.w, surfaceNormal.x, surfaceNormal.y, surfaceNormal.z, surfaceNormal.w, rayDirectionUnit.x, rayDirectionUnit.y, rayDirectionUnit.z, rayDirectionUnit.w, atomPos.x, atomPos.y, atomPos.z, atomRadius, random, g, si, fp, internalPoint.x, internalPoint.y, internalPoint.z, internalPoint.w, ssLight.x);
                    //                    }
                    
                }
            }
            
            colour.x += ssLight.x / (float)(LIGHTS_TO_COALESCE);
            colour.y += ssLight.y / (float)(LIGHTS_TO_COALESCE);
            colour.z += ssLight.z / (float)(LIGHTS_TO_COALESCE);
//            float4 lightRayDirection = lightPosition - lightRayStart;
//            float scale = length(lightRayDirection);
//            lightRayDirection = normalize(lightRayDirection);
            //            float4 lightRayDirection = vectorSubtract(lightPosition, lightRayStart, 0);
            
            //Find any intersections along this ray
//            interactionData lightIntersection = rayIntersectionTreeMinimal(data, numAtoms, tree, treeLookupData, lightRayStart, lightRayDirection);
//            interactionData lightIntersection = minimalRayIntersection(data, numAtoms, lightRayStart, lightRayDirection);
//            interactionData lightIntersection = rayIntersection(data, numAtoms, lightRayStart, lightRayDirection);
//            interactionData lightIntersection;
//            lightIntersection.data.s0 = 0.1;
            
            /*If there are no intersections, or if the intersections are beyond the light source,
             then do the light processing*/
            
//            float intersectionT = lightIntersection.data.s0 / scale;
            
            /*if (get_global_id(0) == 131328) {
                float4 intersectPosb, normalb;
                intersectPosb = lightIntersection.data.s2345;
                normalb = lightIntersection.data.s6789;
                unsigned long o;
                o = lightIntersection.object;
                
                printf("L: %d, s: %f, tv: %f, tvs: %f, lrs: %f %f %f %f, lrd: %f %f %f %f", counter, scale, lightIntersection.data.s0, intersectionT, lightRayStart.x, lightRayStart.y, lightRayStart.z, lightRayStart.w, lightRayDirection.x, lightRayDirection.y, lightRayDirection.z, lightRayDirection.w);
                printf("O: %d, intersect: %f %f %f %f, normal: %f %f %f %f\n", o, intersectPosb.x, intersectPosb.y, intersectPosb.z, intersectPosb.w, normalb.x, normalb.y, normalb.z, normalb.w);

            }*/
            
/*            if ((intersectionT < 0.0) || (intersectionT > 1.0))
            {
                float4 phongMirror = mirrorRay(lightRayDirection, normal, lightRayStart);
                
                float4 Lunit, viewDirection, mirrorUnit;
                
                //                Lunit = normalize(lightRayDirection);
                viewDirection = normalize(rayDirection * (float)-1.0);
                mirrorUnit = normalize(phongMirror);
                
                float lDotN = dot(lightRayDirection, normal);
                float rDotV = dot(mirrorUnit, viewDirection);
                float specScale = pow(rDotV, phong);
             
//                if ((get_global_id(0) == 143611) || (get_global_id(0) == 144123)) {
//                    printf("i: %d, M: %f %f %f %f, MU: %f %f %f %f, VD: %f %f %f %f, rdv: %f, ss: %f\n",get_global_id(0), phongMirror.x, phongMirror.y, phongMirror.z, phongMirror.w, mirrorUnit.x, mirrorUnit.y, mirrorUnit.z, mirrorUnit.w, viewDirection.x, viewDirection.y, viewDirection.z, viewDirection.w, rDotV, specScale);
//                }
                
//                colour.x = colour.x + diffuseColour.x * lDotN * lights[counter].s4 + specularColour.x * specScale * lights[counter].s4;
//                colour.y = colour.y + diffuseColour.y * lDotN * lights[counter].s5 + specularColour.y * specScale * lights[counter].s5;
//                colour.z = colour.z + diffuseColour.z * lDotN * lights[counter].s6 + specularColour.z * specScale * lights[counter].s6;
               
            }*/
        }
        
        /*Now, if we are below the number of mirror levels, then we recurse, and fire a
         mirror ray.*/
        
        //        if (recurseDepth > 0)
        //        {
        //            if (*(object + MIRROR_FRAC) > 0) {
        
        //Form the mirror ray
        //                mirror = mirror_ray(vector_scale(ray.direction, -1),
        //                                    intersection.normal,
        //                                    small_intersection_step);
        
        //                RGBColour mirrorColour = [self rayTraceWithRay:mirror currentRecursionLevel:recurseDepth - 1];
        //                colour.red = specularColour.red * mirrorColour.red * *(object + MIRROR_FRAC) + colour.red;
        //                colour.green = specularColour.green * mirrorColour.green * *(object + MIRROR_FRAC) + colour.green;
        //                colour.blue = specularColour.blue * mirrorColour.blue * *(object + MIRROR_FRAC) + colour.blue;
        //            }
        //        }
        //        else {
        //            RGBColour black;
        //            black.red = black.green = black.blue = 1.0;
        //            return black;
        //        }
//        float4 mirror = mirrorRay(rayDirection * (float)-1.0, normal, small_intersection_step);
//        float4 mirrorColour;
//        mirrorColour = singleRayTraceMirror(small_intersection_step, mirror, data, numAtoms, bvh, bvhMembers, ambientLight, numLights, lights, numIntrinsicLights, intrinsicLights);
//        if (mirrorColour.w > 0.0) {
//            colour.x = colour.x + specularColour.x * mirrorFrac * mirrorColour.x;
//            colour.y = colour.y + specularColour.y * mirrorFrac * mirrorColour.y;
//            colour.z = colour.z + specularColour.z * mirrorFrac * mirrorColour.z;
//        }
        
    }
    
    if (colour.x < 0.)
        colour.x = 0;
    else if (colour.x > 1.0)
        colour.x = 1.0;
    
    if (colour.y < 0.)
        colour.y = 0;
    else if (colour.y > 1.0)
        colour.y = 1.0;
    
    if (colour.z < 0.)
        colour.z = 0;
    else if (colour.z > 1.0)
        colour.z = 1.0;

    return colour;
}

kernel void raytrace(global uchar4* output, int startPixel, float4 viewOrigin, float4 lookAt, float4 upOrientation, int aaSteps, int width, int height, float viewWidth, float aperture, float focalDistance, float lensLength, global const float* data, const unsigned long numAtoms, global const octree* tree, global const uint* treeLookupData, const float4 ambientLight, int numLights, global float8* lights, int numIntrinsicLights, global float* intrinsicLights, int limit) {
    
    
    size_t i = get_global_id(0);
    
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
                c1 = singleRayTrace(p1, d1, data, numAtoms, tree, treeLookupData, ambientLight, numLights, lights, numIntrinsicLights, intrinsicLights);
                
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
                c1 = singleRayTrace(p1, d1, data, numAtoms, tree, treeLookupData, ambientLight, numLights, lights, numIntrinsicLights, intrinsicLights);
                
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
                c1 = singleRayTrace(p1, d1, data, numAtoms, tree, treeLookupData, ambientLight, numLights, lights, numIntrinsicLights, intrinsicLights);
                
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