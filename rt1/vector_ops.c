/*
 * File: vector_ops.c
 * Author:  Brendan McCane.
 * Updated: Raymond Scurr. (2001).
 *
 * Description: Vector ops. You'll probably want to add more functions here.
 */

#include "vector_ops.h"

/* ----- TYPE DECLARATIONS ------------------------------------------------- */
/*
** this a record structure that contains a 3D vector (x, y, z).
**
** Note - if w == 1 then it represents a point.
**        if w == 0 then it represents a vector.
**
**   typedef struct _Vector {
**     GLdouble x, y, z, w;
**   } Vector;
*/


/* subtract two vectors: return a-b */
Vector vector_subtract(Vector a, Vector b)
{
  Vector result;
  
  result.x = a.x - b.x;
  result.y = a.y - b.y;
  result.z = a.z - b.z;
    result.w = a.w - b.w;
  return(result);
}

cl_float4 clVector_subtract(cl_float4 a, cl_float4 b) {
    cl_float4 result;
    
    result.x = a.x - b.x;
    result.y = a.y - b.y;
    result.z = a.z - b.z;
    result.w = a.w - b.w;
    return(result);
    
}

/* add two vectors: return a+b */
Vector vector_add(Vector a, Vector b)
{
    Vector result;
    
    result.x = a.x + b.x;
    result.y = a.y + b.y;
    result.z = a.z + b.z;
    result.w = a.w + b.w;
    return(result);
}

//Vector dot product - useful to find angle between two vectors
double vector_dot_product (Vector a, Vector b)
{

  return a.x * b.x + a.y * b.y + a.z * b.z;

}

//Vector size - returns the magnitude of the vector
double vector_size (Vector a)
{

  return sqrt(pow(a.x, 2) + pow(a.y, 2) + pow(a.z, 2));

}

cl_float clVector_length(cl_float4 a) {

    return sqrt(a.x * a.x + a.y * a.y + a.z * a.z + a.w * a.w);
    
}


//Vector angle - returns the angle (in radians) between two vectors
double vector_angle (Vector a, Vector b)
{

  return acos(vector_dot_product(a,b)/(vector_size(a)*vector_size(b)));

}


//Vector scale - function that multiplies a vector by a scalar number
Vector vector_scale (Vector a, double scale)
{

  Vector result;

  result.x = a.x * scale;
  result.y = a.y * scale;
  result.z = a.z * scale;
  result.w = a.w;

  return result;

}

Vector vector_lerp (Vector a, Vector b, float fraction) {
    Vector r;
    
    float bFrac = 1.0 - fraction;
    
    r.x = a.x * fraction + b.x * bFrac;
    r.y = a.y * fraction + b.y * bFrac;
    r.z = a.z * fraction + b.z * bFrac;
    r.w = a.w * fraction + b.w * bFrac;
    
    return r;
}

Vector vector_cross (Vector a, Vector b) {
    Vector result;
    
    result.x = a.y * b.z - a.z * b.y;
    result.y = a.z * b.x - a.x * b.z;
    result.z = a.x * b.y - a.y * b.x;
    result.w = 0;
    
    return result;
}

Vector unit_vector (Vector a) {
    
    return vector_scale(a, 1.0 / vector_size(a));
    
}

void print_vector (Vector a)
{

  printf("%lf %lf %lf %lf \n", a.x, a.y, a.z, a.w);

}

