/*
 * File: vector_ops.h
 *
 * Description: Header file for vector operations.
 */

#ifndef _VECTOR_OPS
#define _VECTOR_OPS

#include "typedefs.h"
#include <OpenCL/OpenCL.h>

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

/* ----- FUNCTION HEADERS -------------------------------------------------- */

Vector   vector_subtract(Vector a, Vector b);
cl_float4 clVector_subtract(cl_float4 a, cl_float4 b);
Vector   vector_add(Vector a, Vector b);
double vector_dot_product (Vector a, Vector b);
double vector_size (Vector a);
cl_float clVector_length(cl_float4 a);
double vector_angle (Vector a, Vector b);
Vector vector_scale (Vector a, double scale);
Vector vector_cross (Vector a, Vector b);
Vector vector_lerp (Vector a, Vector b, float fraction);
Vector unit_vector (Vector a);
void print_vector (Vector a);

#endif /* _VECTOR_OPS */


