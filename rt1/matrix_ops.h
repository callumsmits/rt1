

/*
**  These preprocessor commands mean the header file will
**  be loaded one time only, and not once for every file
**  that includes it.
**
**  They are terminated at the end of the file.
*/
#ifndef _MATRIX_OPS_H
#define _MATRIX_OPS_H


#include "typedefs.h"


Matrix identityMatrix(void);
void loadIdentityMatrix(Matrix *ident);

void makeMatrix(Matrix *mat,
		double a00, double a01, double a02, double a03,
		double a10, double a11, double a12, double a13,
		double a20, double a21, double a22, double a23,
		double a30, double a31, double a32, double a33);

void copyMatrix(Matrix *new, Matrix original);

void addMatrix(Matrix *sum, Matrix adding);

void displayMatrix(Matrix m);

void transverseMatrix (Matrix * mat);

void multiplyMatrix (Matrix multiplier, Matrix *multiplucand);

void multiplyTransverseMatrix (Matrix multiplier, Matrix *multiplucand);

void rightMultiplyMatrix (Matrix *multiplier, Matrix multiplucand);

Vector vectorMatrixMultiply (Matrix transform, Vector point);

Matrix matrixToRotateAroundAxisByAngle(Vector axis, float angle);

void vectorMatrixMultiplyArg (Matrix transform, Vector point, Vector *transformedPoint);

Vector rotationMatrixToAxisAndAngle(Matrix in, float *angle);

int calculate_rotation_matrix(Matrix R, Matrix* U, float E0, float* residual);

#endif /*  _MATRIX_OPS_H  */





