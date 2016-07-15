
#include "matrix_ops.h"

/*
** FUNCTIONS
*/

Matrix identityMatrix(void)
{
  Matrix result = { {1, 0, 0, 0,
                     0, 1, 0, 0,
  		     0, 0, 1, 0,
         	     0, 0, 0, 1 } };
  return result;
}

void loadIdentityMatrix(Matrix *ident)
{
  (*ident) = identityMatrix();
}

void makeMatrix(Matrix *mat,
		double a00, double a01, double a02, double a03,
		double a10, double a11, double a12, double a13,
		double a20, double a21, double a22, double a23,
		double a30, double a31, double a32, double a33)
{
  (*mat).element[0][0] = a00;
  (*mat).element[0][1] = a01;
  (*mat).element[0][2] = a02;
  (*mat).element[0][3] = a03;

  (*mat).element[1][0] = a10;
  (*mat).element[1][1] = a11;
  (*mat).element[1][2] = a12;
  (*mat).element[1][3] = a13;

  (*mat).element[2][0] = a20;
  (*mat).element[2][1] = a21;
  (*mat).element[2][2] = a22;
  (*mat).element[2][3] = a23;

  (*mat).element[3][0] = a30;
  (*mat).element[3][1] = a31;
  (*mat).element[3][2] = a32;
  (*mat).element[3][3] = a33;
}

void copyMatrix(Matrix *new, Matrix original) {
    (*new).element[0][0] = original.element[0][0];
    (*new).element[0][1] = original.element[0][1];
    (*new).element[0][2] = original.element[0][2];
    (*new).element[0][3] = original.element[0][3];
    
    (*new).element[1][0] = original.element[1][0];
    (*new).element[1][1] = original.element[1][1];
    (*new).element[1][2] = original.element[1][2];
    (*new).element[1][3] = original.element[1][3];
    
    (*new).element[2][0] = original.element[2][0];
    (*new).element[2][1] = original.element[2][1];
    (*new).element[2][2] = original.element[2][2];
    (*new).element[2][3] = original.element[2][3];
    
    (*new).element[3][0] = original.element[3][0];
    (*new).element[3][1] = original.element[3][1];
    (*new).element[3][2] = original.element[3][2];
    (*new).element[3][3] = original.element[3][3];
}

void addMatrix(Matrix *sum, Matrix adding)
{
   int row, col;

  for (row = 0; row < MATRIX_SIZE; row++)
    for (col = 0; col < MATRIX_SIZE; col++)
      (*sum).element[row][col] += adding.element[row][col];
}


/*
**  Output Matrix - for testing and diagnostics
*/
void displayMatrix(Matrix m)
{
  int row, col;

  printf("\n");
  for (row = 0; row < MATRIX_SIZE; row++)
  {
    for (col = 0; col < MATRIX_SIZE; col++)
      printf("%2.4f ", m.element[row][col]);
    printf("\n");
  }
  printf("\n");
}


void transverseMatrix (Matrix * mat)
{
  int row, col;
  Matrix temp_matrix;

  //transverse into the temp matrix
  for (row = 0; row < MATRIX_SIZE; row++)
    for (col = 0; col < MATRIX_SIZE; col++)
      temp_matrix.element[col][row] = mat->element[row][col];
  
  //copy into original matrix
  for (row = 0; row < MATRIX_SIZE; row++)
    for (col = 0; col < MATRIX_SIZE; col++)
      mat->element[row][col] = temp_matrix.element[row][col];
  
}


void multiplyMatrix (Matrix multiplier, Matrix *multiplucand)
{
  int row, col, position;
  double sum;
  Matrix temp_matrix;
  
  /*multiply into the temp matrix*/
  for (row = 0; row < MATRIX_SIZE; row++)
    for (col = 0; col < MATRIX_SIZE; col++)
      {
	for (sum = position = 0; position < MATRIX_SIZE; position++)
	  sum = sum + multiplier.element[row][position] * 
	    multiplucand->element[position][col];
	
	temp_matrix.element[row][col] = sum;
      }
  
  //and now copy into the original matrix
  for (row = 0; row < MATRIX_SIZE; row++)
    for (col = 0; col < MATRIX_SIZE; col++)
      multiplucand->element[row][col] = temp_matrix.element[row][col];
}


void multiplyTransverseMatrix (Matrix multiplier, Matrix *multiplucand)
{
  int row, col, position;
  double sum;
  Matrix temp_matrix;
  
  /*multiply into the temp matrix*/
  for (row = 0; row < MATRIX_SIZE; row++)
    for (col = 0; col < MATRIX_SIZE; col++)
      {
	for (sum = position = 0; position < MATRIX_SIZE; position++)
	  sum = sum + multiplier.element[row][position] * 
	    multiplucand->element[position][col];
	
	temp_matrix.element[row][col] = sum;
      }
  
  //and now copy into the original matrix
  for (row = 0; row < MATRIX_SIZE; row++)
    for (col = 0; col < MATRIX_SIZE; col++)
      multiplucand->element[row][col] = temp_matrix.element[col][row];
}          


void rightMultiplyMatrix (Matrix *multiplier, Matrix multiplucand)
{
  int row, col, position;
  double sum;
  Matrix temp_matrix;
  
  /*multiply into the temp matrix*/
  for (row = 0; row < MATRIX_SIZE; row++)
    for (col = 0; col < MATRIX_SIZE; col++)
      {
	for (sum = position = 0; position < MATRIX_SIZE; position++)
	  sum = sum + multiplier->element[row][position] * 
	    multiplucand.element[position][col];
	
	temp_matrix.element[row][col] = sum;
      }
  
  //and now copy into the original matrix
  for (row = 0; row < MATRIX_SIZE; row++)
    for (col = 0; col < MATRIX_SIZE; col++)
      multiplier->element[row][col] = temp_matrix.element[row][col];
}

Matrix matrixToRotateAroundAxisByAngle(Vector axis, float angle) {
    Matrix tempMatrix;
    
    float t = 1 - cosf(angle);
    float c = cosf(angle);
    float s = sinf(angle);
    makeMatrix(&tempMatrix,
               t * axis.x * axis.x + c, t * axis.x * axis.y - s * axis.z, t * axis.x * axis.z + s * axis.y, 0,
               t * axis.x * axis.y + s * axis.z, t * axis.y * axis.y + c, t * axis.y * axis.z - s * axis.x, 0,
               t * axis.x * axis.z - s * axis.y, t * axis.y * axis.z + s * axis.x, t * axis.z * axis.z + c, 0,
               0, 0, 0, 1);
    return tempMatrix;
}

Vector vectorMatrixMultiply (Matrix transform, Vector point)
{
    
    Vector result;
    
    result.x = transform.element[0][0] * point.x +
    transform.element[0][1] * point.y +
    transform.element[0][2] * point.z +
    transform.element[0][3] * point.w;
    
    result.y = transform.element[1][0] * point.x +
    transform.element[1][1] * point.y +
    transform.element[1][2] * point.z +
    transform.element[1][3] * point.w;
    
    result.z = transform.element[2][0] * point.x +
    transform.element[2][1] * point.y +
    transform.element[2][2] * point.z +
    transform.element[2][3] * point.w;
    
    result.w = transform.element[3][0] * point.x +
    transform.element[3][1] * point.y +
    transform.element[3][2] * point.z +
    transform.element[3][3] * point.w;
    
//    if (result.w > 0) {
//        result.x = result.x / result.w;
//        result.y = result.y / result.w;
//        result.z = result.z / result.w;
//        result.w = result.w / result.w;
//    }
    
    return result;
}

Vector rotationMatrixToAxisAndAngle(Matrix in, float *angle) {
    
    //First convert rotation matrix to quaternion
    float t = 1 + in.element[0][0] + in.element[1][1] + in.element[2][2];
    
    Vector q;
    if (t > 0.00001) {
        float S = sqrt(t) * 2;
        q.x = ( in.element[2][1] - in.element[1][2] ) / S;
        q.y = ( in.element[0][2] - in.element[2][0] ) / S;
        q.z = ( in.element[1][0] - in.element[0][1] ) / S;
        q.w = 0.25 * S;
    } else {
        if ( in.element[0][0] > in.element[1][1] && in.element[0][0] > in.element[2][2] )  {	// Column 0:
            float S  = sqrt( 1.0 + in.element[0][0] - in.element[1][1] - in.element[2][2] ) * 2;
            q.x = 0.25 * S;
            q.y = (in.element[1][0] + in.element[0][1] ) / S;
            q.z = (in.element[0][2] + in.element[2][0] ) / S;
            q.w = (in.element[2][1] - in.element[1][2] ) / S;
        } else if (in.element[1][1] > in.element[2][2] ) {			// Column 1:
            float S  = sqrt( 1.0 + in.element[1][1] - in.element[0][0] - in.element[2][2] ) * 2;
            q.x = (in.element[1][0] + in.element[0][1] ) / S;
            q.y = 0.25 * S;
            q.z = (in.element[2][1] + in.element[1][2] ) / S;
            q.w = (in.element[0][2] - in.element[2][0] ) / S;
        } else {						// Column 2:
            float S  = sqrt( 1.0 + in.element[2][2] - in.element[0][0] - in.element[1][1] ) * 2;
            q.x = (in.element[0][2] + in.element[2][0] ) / S;
            q.y = (in.element[2][1] + in.element[1][2] ) / S;
            q.z = 0.25 * S;
            q.w = (in.element[1][0] - in.element[0][1] ) / S;
        }
    }
    
    //Normalise the quaternion
    float mag = sqrtf(q.x * q.x + q.y * q.y + q.z * q.z + q.w * q.w);
    q.x = q.x / mag;
    q.y = q.y / mag;
    q.z = q.z / mag;
    q.w = q.w / mag;
    
    float cos_a = q.w;
    *angle = acos( cos_a ) * 2;
    float sin_a = sqrt( 1.0 - cos_a * cos_a );
    if ( fabs( sin_a ) < 0.0005 ) sin_a = 1;
    Vector axis;
    axis.x = q.x / sin_a;
    axis.y = q.y / sin_a;
    axis.z = q.z / sin_a;
    axis.w = 0.0;
    
    return axis;
}

//Following code adapted from http://boscoh.com/code/rmsd.c
#define ROTATE(a,i,j,k,l) { g = a.element[i][j]; \
                            h = a.element[k][l]; \
                            a.element[i][j] = g-s*(h+g*tau); \
                            a.element[k][l] = h+s*(g-h*tau); }

#define ROTATEM(a,i,j,k,l) { g = (*a).element[i][j]; \
                             h = (*a).element[k][l]; \
                             (*a).element[i][j] = g-s*(h+g*tau); \
                             (*a).element[k][l] = h+s*(g-h*tau); }

/*
 * jacobi3
 *
 *    computes eigenval and eigen_vec of a real 3x3
 * symmetric matrix. On output, elements of a that are above
 * the diagonal are destroyed. d[1..3] returns the
 * eigenval of a. v[1..3][1..3] is a matrix whose
 * columns contain, on output, the normalized eigen_vec of
 * a. n_rot returns the number of Jacobi rotations that were required.
 */
int jacobi3(Matrix a, float d[3], Matrix *v, int* n_rot)
{
    int count, k, i, j;
    float tresh, theta, tau, t, sum, s, h, g, c, b[3], z[3];
    
    /*Initialize v to the identity matrix.*/
//    for (i=0; i<3; i++)
//    {
//        for (j=0; j<3; j++)
//            v.element[i][j] = 0.0;
//        v.element[i][i] = 1.0;
//    }
    loadIdentityMatrix(v);
    
    /* Initialize b and d to the diagonal of a */
    for (i=0; i<3; i++)
        b[i] = d[i] = a.element[i][i];
    
    /* z will accumulate terms */
    for (i=0; i<3; i++)
        z[i] = 0.0;
    
    *n_rot = 0;
    
    /* 50 tries */
    for (count=0; count<50; count++)
    {
        
        /* sum off-diagonal elements */
        sum = 0.0;
        for (i=0; i<2; i++)
        {
            for (j=i+1; j<3; j++)
                sum += fabs(a.element[i][j]);
        }
        
        /* if converged to machine underflow */
        if (sum == 0.0)
            return(1);
        
        /* on 1st three sweeps... */
        if (count < 3)
            tresh = sum * 0.2 / 9.0;
        else
            tresh = 0.0;
        
        for (i=0; i<2; i++)
        {
            for (j=i+1; j<3; j++)
            {
                g = 100.0 * fabs(a.element[i][j]);
                
                /*  after four sweeps, skip the rotation if
                 *   the off-diagonal element is small
                 */
                if ( count > 3  &&  fabs(d[i])+g == fabs(d[i])
                    &&  fabs(d[j])+g == fabs(d[j]) )
                {
                    a.element[i][j] = 0.0;
                }
                else if (fabs(a.element[i][j]) > tresh)
                {
                    h = d[j] - d[i];
                    
                    if (fabs(h)+g == fabs(h))
                    {
                        t = a.element[i][j] / h;
                    }
                    else
                    {
                        theta = 0.5 * h / (a.element[i][j]);
                        t = 1.0 / ( fabs(theta) +
                                   (double)sqrt(1.0 + theta*theta) );
                        if (theta < 0.0)
                            t = -t;
                    }
                    
                    c = 1.0 / (double) sqrt(1 + t*t);
                    s = t * c;
                    tau = s / (1.0 + c);
                    h = t * a.element[i][j];
                    
                    z[i] -= h;
                    z[j] += h;
                    d[i] -= h;
                    d[j] += h;
                    
                    a.element[i][j] = 0.0;
                    
                    for (k=0; k<=i-1; k++)
                        ROTATE(a, k, i, k, j)
                        
                        for (k=i+1; k<=j-1; k++) 
                            ROTATE(a, i, k, k, j)
                            
                            for (k=j+1; k<3; k++) 
                                ROTATE(a, i, k, j, k)
                                
                                for (k=0; k<3; k++) 
                                    ROTATEM(v, k, i, k, j)
                                    
                                    ++(*n_rot);
                }
            }
        }
        
        for (i=0; i<3; i++) 
        {
            b[i] += z[i];
            d[i] = b[i];
            z[i] = 0.0;
        }
    }
    
    printf("Too many iterations in jacobi3\n");
    return (0);
}

/*
 * diagonalize_symmetric
 *
 *    Diagonalize a 3x3 matrix & sort eigenval by size
 */
int diagonalize_symmetric(Matrix matrix,
                          Matrix *eigen_vec,
                          float eigenval[3])
{
    int n_rot, i, j, k;
    Matrix vec;
    float val;
    
    if (!jacobi3(matrix, eigenval, &vec, &n_rot))
    {
        printf("convergence failed\n");
        return (0);
    }
    
    /* sort solutions by eigenval */
    for (i=0; i<3; i++)
    {
        k = i;
        val = eigenval[i];
        
        for (j=i+1; j<3; j++)
            if (eigenval[j] >= val)
            {
                k = j;
                val = eigenval[k];
            }
        
        if (k != i)
        {
            eigenval[k] = eigenval[i];
            eigenval[i] = val;
            for (j=0; j<3; j++)
            {
                val = vec.element[j][i];
                vec.element[j][i] = vec.element[j][k];
                vec.element[j][k] = val;
            }
        }
    }
    
    /* transpose such that first index refers to solution index */
    for (i=0; i<3; i++)
        for (j=0; j<3; j++)
            (*eigen_vec).element[i][j] = vec.element[j][i];
    
    return (1);
}

void normalize(float a[3])
{
    float  b;
    
    b = sqrt((a[0]*a[0] + a[1]*a[1] + a[2]*a[2]));
    a[0] /= b;
    a[1] /= b;
    a[2] /= b;
}



float dot(float a[3], float b[3])
{
    return (a[0] * b[0] + a[1] * b[1] + a[2] * b[2]);
}



static void cross(float a[3], float b[3], float c[3])
{
    a[0] = b[1]*c[2] - b[2]*c[1];
    a[1] = b[2]*c[0] - b[0]*c[2];
    a[2] = b[0]*c[1] - b[1]*c[0];
}

/*
 * calculate_rotation_matrix()
 *
 *   calculates the rotation matrix U and the
 * rmsd from the R matrix and E0:
 */
int calculate_rotation_matrix(Matrix R,
                              Matrix *Uret,
                              float E0,
                              float* residual)
{
    int i, j, k;
    Matrix Rt, RtR, U;
    Matrix left_eigenvec, right_eigenvec;
    float v[3], eigenval[3];
    float sigma;
    
    makeMatrix(&left_eigenvec, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
    makeMatrix(&U, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
    
    /* build Rt, transpose of R  */
    for (i=0; i<3; i++)
        for (j=0; j<3; j++)
            Rt.element[i][j] = R.element[j][i];
    
    /* make symmetric RtR = Rt X R */
    for (i=0; i<3; i++)
        for (j=0; j<3; j++)
        {
            RtR.element[i][j] = 0.0;
            for (k = 0; k<3; k++)
                RtR.element[i][j] += Rt.element[k][i] * R.element[j][k];
        }
    
    if (!diagonalize_symmetric(RtR, &right_eigenvec, eigenval))
        return(0);
    
    /* right_eigenvec's should be an orthogonal system but could be left
     * or right-handed. Let's force into right-handed system.
     */
    cross(&right_eigenvec.element[2][0], &right_eigenvec.element[0][0], &right_eigenvec.element[1][0]);
    
    /* From the Kabsch algorithm, the eigenvec's of RtR
     * are identical to the right_eigenvec's of R.
     * This means that left_eigenvec = R x right_eigenvec
     */
    for (i=0; i<3; i++)
        for (j=0; j<3; j++)
            left_eigenvec.element[i][j] = dot(&right_eigenvec.element[i][0], &Rt.element[j][0]);
    
    for (i=0; i<3; i++)
        normalize(&left_eigenvec.element[i][0]);
    
    /*
     * Force left_eigenvec[2] to be orthogonal to the other vectors.
     * First check if the rotational matrices generated from the
     * orthogonal eigenvectors are in a right-handed or left-handed
     * co-ordinate system - given by sigma. Sigma is needed to
     * resolve this ambiguity in calculating the RMSD.
     */
    cross(v, &left_eigenvec.element[0][0], &left_eigenvec.element[1][0]);
    if (dot(v, &left_eigenvec.element[2][0]) < 0.0)
        sigma = -1.0;
    else
        sigma = 1.0;
    for (i=0; i<3; i++)
        left_eigenvec.element[2][i] = v[i];
    
    /* calc optimal rotation matrix U that minimises residual */
    for (i=0;i<3; i++)
        for (j=0; j<3; j++)
        {
            U.element[i][j] = 0.0;
            for (k=0; k<3; k++)
                U.element[i][j] += left_eigenvec.element[k][i] * right_eigenvec.element[k][j];
        }
    
    *residual = E0 - (double) sqrt(fabs(eigenval[0])) 
    - (double) sqrt(fabs(eigenval[1]))
    - sigma * (double) sqrt(fabs(eigenval[2]));
    
    *Uret = U;
    return (1);
}
