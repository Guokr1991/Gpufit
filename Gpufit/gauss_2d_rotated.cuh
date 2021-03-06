#ifndef GPUFIT_GAUSS2DROTATED_CUH_INCLUDED
#define GPUFIT_GAUSS2DROTATED_CUH_INCLUDED

/* Description of the calculate_gauss2drotated function
* =====================================================
*
* This function calculates the values of two-dimensional elliptic gauss model
* functions including a rotation parameter and their partial derivatives with
* respect to the model parameters. 
*
* No independent variables are passed to this model function.  Hence, the 
* (X, Y) coordinate of the first data value is assumed to be (0.0, 0.0).  For
* a fit size of M x N data points, the (X, Y) coordinates of the data are
* simply the corresponding array index values of the data array, starting from
* zero.
*
* Parameters:
*
* parameters: An input vector of model parameters.
*             p[0]: amplitude
*             p[1]: center coordinate x
*             p[2]: center coordinate y
*             p[3]: width x (standard deviation)
*             p[4]: width y (standard deviation)
*             p[5]: offset
*             p[6]: rotation angle [radians]
*
* n_fits: The number of fits. (not used)
*
* n_points: The number of data points per fit.
*
* value: An output vector of model function values.
*
* derivative: An output vector of model function partial derivatives.
*
* point_index: The data point index.
*
* fit_index: The fit index. (not used)
*
* chunk_index: The chunk index. (not used)
*
* user_info: An input vector containing user information. (not used)
*
* user_info_size: The size of user_info in bytes. (not used)
*
* Calling the calculate_gauss2drotated function
* =============================================
*
* This __device__ function can be only called from a __global__ function or an other
* __device__ function.
*
*/

__device__ void calculate_gauss2drotated(
    float const * parameters,
    int const n_fits,
    int const n_points,
    float * value,
    float * derivative,
    int const point_index,
    int const fit_index,
    int const chunk_index,
    char * user_info,
    std::size_t const user_info_size)
{
    // indices

    int const n_points_x = sqrt((float)n_points);

    int const point_index_y = point_index / n_points_x;
    int const point_index_x = point_index - point_index_y * n_points_x;

    // parameters

    float const * p = parameters;

    // value

    float const cosp6 = cosf(p[6]);
    float const sinp6 = sinf(p[6]);

    float const arga = (point_index_x - p[1]) * cosp6 - (point_index_y - p[2]) * sinp6;
    float const argb = (point_index_x - p[1]) * sinp6 + (point_index_y - p[2]) * cosp6;
    float const ex = exp(-0.5 * (((arga / p[3]) * (arga / p[3])) + ((argb / p[4]) * (argb / p[4]))));
    value[point_index] = p[0] * ex + p[5];

    // derivative

    float * current_derivative = derivative + point_index;

    current_derivative[0 * n_points] = ex;
    current_derivative[1 * n_points] = (((p[0] * cosp6 * arga) / (p[3] * p[3])) + ((p[0] * sinp6 * argb) / (p[4] * p[4]))) * ex;
    current_derivative[2 * n_points] = (((-p[0] * sinp6 * arga) / (p[3] * p[3])) + ((p[0] * cosp6 * argb) / (p[4] * p[4]))) * ex;
    current_derivative[3 * n_points] = p[0] * arga * arga / (p[3] * p[3] * p[3]) * ex;
    current_derivative[4 * n_points] = p[0] * argb * argb / (p[4] * p[4] * p[4]) * ex;
    current_derivative[5 * n_points] = 1;
    current_derivative[6 * n_points] = p[0] * arga * argb * (1.0 / (p[3] * p[3]) - 1.0 / (p[4] * p[4])) * ex;
}

#endif
