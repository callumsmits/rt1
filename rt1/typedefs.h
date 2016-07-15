/*
 * File: typedefs.h
 * Author: Brendan McCane
 *
 * Description: Contains the required typedefs.
 */

#ifndef _TYPEDEFS
#define _TYPEDEFS

#include <stdio.h>
#include <math.h>

/* ----- CONSTANTS --------------------------------------------------------- */

#define  Pi                3.141592653589793239
#define  radiansPerDegree  0.017453292519943
#define  MATRIX_SIZE       4


#define MAX_NUM_OBJS 50

#define SMALL_STEP 0.0001
#define MIRROR_AMOUNT 2



/* ----- TYPE DECLARATIONS ------------------------------------------------- */

/*
** this a record structure for storing colour info.
*/
typedef struct
{
  float red, green, blue;
} RGBColour;


/*
** this a record structure that contains a 3D vector (x, y, z).
**
** Note - if w == 1 then it represents a point.
**        if w == 0 then it represents a vector.
*/
typedef struct _Vector {
  float x, y, z, w;
} Vector;

/* ray is defined by a point and a direction */
typedef struct _Ray {
  Vector start;
  Vector direction;
} RayDef;
	

typedef struct _Matrix
{
  float element[MATRIX_SIZE][MATRIX_SIZE];
} Matrix;


typedef struct _LightSource {
  Vector position;
  RGBColour colour;
} LightSourceDef;


typedef struct
{
  float t_value;
  float *object;
  Vector intersection;
  Vector normal;
} intersection_data;


/* See Fileio.c  to see how to access the values in the array of objects */
typedef struct _ObjectsDef
{
  RGBColour diffuse_colour;
  RGBColour specular_colour;
  float phong;              /* the phong coefficient */
  Matrix transform;
  Matrix inverse_t;
  Matrix inverse_transpose;
} ObjectsDef;



#endif  /* _TYPEDEFS */
