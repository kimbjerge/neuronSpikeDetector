///////////////////////////////////////////////////////////
//  KernelFilter.h
//  Header:          Kernel filtering functions.
//  Created on:      25-10-2017
//  Original author: MB
///////////////////////////////////////////////////////////
#ifndef KERNEL_FILTER_H
#define KERNEL_FILTER_H

#include "stdint.h"
#include "math.h"
#include <chrono>

#include "ProjectDefinitions.h"

#ifdef USE_OPENCV
	#include <opencv2\opencv.hpp>
using namespace cv;
#endif

using namespace std::chrono;

#ifdef USE_CUDA
extern "C" void KernelFilterWithCudaV2(float *result, const float *signal, const float *kernel, uint16_t templateChannels, uint16_t kernelDim, uint32_t signalLength);
//extern "C" cudaError_t KernelFilterWithCudaV2_Old(float *result, const float *signal, const float *kernel, uint16_t templateChannels, uint16_t kernelDim, uint32_t signalLength);
#endif

template <class T>
class KernelFilter
{
public:
	/* Enum */
	enum FilterTypes
	{
		ZERO_PADDING,
		REPLICATE,
		PURE,
#ifdef USE_OPENCV
		OPENCV,
#endif
	};
	/* Constructor */
	KernelFilter(uint32_t templateChannels, uint32_t signalLength);
	/* Kernel functions calls*/
	void runFilterZeroPadding(T* result, T* signal, uint32_t kernelDim, uint32_t signalLength, uint32_t signalWidth);
	void runFilterReplicate(T* result, T* signal, uint32_t kernelDim, uint32_t signalLength, uint32_t signalWidth);
#ifdef USE_CUDA
	void runFilterReplicateCUDA(T* result, T* signal, T* kernel, uint32_t kernelDim, uint32_t signalLength, uint32_t signalWidth);
#endif
	void runFilterPure(T* result, T* signal, uint32_t kernelDim, uint32_t signalLength, uint32_t signalWidth);
#ifdef USE_OPENCV
	void runFilterOpenCV(T* result, T* signal, uint32_t kernelDim, uint32_t signalLength, uint32_t signalWidth);
#endif
	/* Helper Functions */
	void padArray(T* result, T* signal, uint32_t kernelDim, uint32_t signalLength, uint32_t signalWidth, bool Replicates);
	void generateLaplacianKernel(T* Kernel);
	T* getKernelFilterCoeff(void);
#ifdef USE_OPENCV
	void convertArrayToCVMat(cv::Mat returnObject, T* array_, uint32_t signalLength, uint32_t signalWidth);
	void convertCVMatToArray(cv::Mat inputObject, T* Outputarray, uint32_t signalLength, uint32_t signalWidth);
#endif
	/* Testing and debug */
	float getLatestExecutionTime(void);
	uint32_t compareEquality(T* signal, T* truth, uint32_t signalLength, uint32_t signalWidth);
	float performXTestReturnExecutionTime(T* result, T* signal, T* template_, uint32_t templateLength, uint32_t templateChannels, uint32_t signalLength, uint32_t numberOfTest, FilterTypes testtype);
private:
	high_resolution_clock::time_point t1;
	high_resolution_clock::time_point t2;
	high_resolution_clock::time_point t3;
	high_resolution_clock::time_point t4;
	float f_latestExecutionTime = 0;
	const float kernelAlphaValue = 0.2f;
	T filterKernel[DEFAULT_KERNEL_DIM*DEFAULT_KERNEL_DIM];
#ifdef USE_OPENCV
	cv::Mat imageMat;
	cv::Mat kernelMat;
	cv::Mat resultMat;
#endif
};

/*----------------------------------------------------------------------------*/
/**
* @brief Constructor
* @note Generates the laplacian kernel besides
*/
template <class T>
KernelFilter<T>::KernelFilter(uint32_t templateChannels, uint32_t signalLength) 
#ifdef USE_OPENCV
	:
	imageMat(templateChannels, signalLength, CV_32FC1),
	kernelMat(DEFAULT_KERNEL_DIM, DEFAULT_KERNEL_DIM, CV_32FC1),
	resultMat(templateChannels, signalLength, CV_32FC1)
#endif
{
	generateLaplacianKernel(filterKernel);
}

/*----------------------------------------------------------------------------*/
/**
* @brief Run a kernel filtering on the supplied signal, using the given kernel
* @note		This implementation handles making zero padding along the boundaries automatically.
*
* @param T* result :			Pointer to the array in which result should be stored
* @param T* paddedSignal :		Pointer to the array which holds the padded signal
* @param uint32_t kernelDim:	Indicates the dimensionality of the kernel fx 3 for 3x3 kernel
* @param uint32_t signalLength: Indicates the length of the padded signal
* @param uint32_t signalWidth:	Indicates the width of the padded signal
*
* @retval void : none
*/
template <class T>
void KernelFilter<T>::runFilterZeroPadding(T* result, T* signal, uint32_t kernelDim, uint32_t signalLength, uint32_t signalWidth)
{
	t1 = high_resolution_clock::now();
	// Perform filtering

	// setup variables
	uint32_t kernelHalfSize = floor(kernelDim / 2);

	// Running over the entire image
	for (uint32_t x = 0; x < signalLength; x++)
	{
		for (uint32_t y = 0; y < signalWidth; y++)
		{
			T tmpFilterValue = 0;

			// If away from border
			if (x >= kernelHalfSize && y >= kernelHalfSize && ((signalLength - 1) - x) >= kernelHalfSize && ((signalWidth - 1) - y) >= kernelHalfSize)
			{
				// for each location apply the filter kernel
				for (uint32_t i = 0; i < kernelDim; i++) // assumes kernel af uneven squared size
				{
					for (uint32_t j = 0; j < kernelDim; j++)
					{
						tmpFilterValue += signal[((((x - 1) + i)*signalWidth) + (y - 1)) + j] * filterKernel[j + (i*kernelDim)];
					}
				}
			}
			else // Close to border
			{
				uint32_t imageStarti = 0;
				uint32_t imageStartj = 0;
				uint32_t imageStartx = x;
				uint32_t imageStarty = y;
				uint32_t kernelIMax = kernelDim;
				uint32_t kernelJMax = kernelDim;
				uint32_t extraSubtractI = 0;
				uint32_t extraSubtractY = 0;

				// find startlocations
				if (x < kernelHalfSize)
				{
					extraSubtractI = kernelHalfSize;
					imageStarti = kernelHalfSize;
					imageStartx = kernelHalfSize;
				}

				if (y < kernelHalfSize)
				{
					extraSubtractY = kernelHalfSize;
					imageStartj = kernelHalfSize;
					imageStarty = kernelHalfSize;
				}

				if (((signalLength - 1) - x) < kernelHalfSize)
				{
					kernelIMax = kernelDim - kernelHalfSize;
				}

				if (((signalWidth - 1) - y) < kernelHalfSize)
				{
					kernelJMax = kernelDim - kernelHalfSize;
				}

				// for each location apply the filter kernel
				for (uint32_t i = imageStarti; i < kernelIMax; i++) // assumes kernel af uneven squared size
				{
					for (uint32_t j = imageStartj; j < kernelJMax; j++)
					{
						float signalValue = signal[((((imageStartx - 1) + (i - extraSubtractI))*signalWidth) + (imageStarty - 1)) + (j - extraSubtractY)];
						float kernelValue = filterKernel[j + (i*kernelDim)];

						tmpFilterValue += signal[((((imageStartx - 1) + (i - extraSubtractI))*signalWidth) + (imageStarty - 1)) + (j - extraSubtractY)] * filterKernel[j + (i*kernelDim)];
					}
				}
			}

			result[(x*signalWidth) + y] = tmpFilterValue;
		}
	}



	t2 = high_resolution_clock::now();

	auto duration = duration_cast<microseconds>(t2 - t1).count();
	f_latestExecutionTime = (float)duration;
}

/*----------------------------------------------------------------------------*/
/**
* @brief Run a kernel filtering on the supplied signal, using the given kernel
* @note		This implementation handles making raplicas of the boundaries automatically.
*			This version is currently only working for a 3x3 kernel!!
*
* @param T* result :			Pointer to the array in which result should be stored
* @param T* paddedSignal :		Pointer to the array which holds the padded signal
* @param T* filterKernel :		pointer to the Filter kernel to apply to the signal
* @param uint32_t kernelDim:	Indicates the dimensionality of the kernel fx 3 for 3x3 kernel
* @param uint32_t signalLength: Indicates the length of the padded signal
* @param uint32_t signalWidth:	Indicates the width of the padded signal
*
* @retval void : none
*/
template <class T>
void KernelFilter<T>::runFilterReplicate(T* result, T* signal, uint32_t kernelDim, uint32_t signalLength, uint32_t signalWidth)
{
	t1 = high_resolution_clock::now();
	// Perform filtering

	// setup variables
	uint32_t kernelHalfSize = (uint32_t)floor(kernelDim / 2);

	// Running over the entire image
	for (uint32_t x = 0; x < signalLength; x++)
	{
		for (uint32_t y = 0; y < signalWidth; y++)
		{
			T tmpFilterValue = 0;

			// If away from border
			if (x >= kernelHalfSize && y >= kernelHalfSize && ((signalLength - 1) - x) >= kernelHalfSize && ((signalWidth - 1) - y) >= kernelHalfSize)
			{
				// for each location apply the filter kernel
				for (uint32_t i = 0; i < kernelDim; i++) // assumes kernel af uneven squared size
				{
					for (uint32_t j = 0; j < kernelDim; j++)
					{
						tmpFilterValue += signal[((((x - 1) + i)*signalWidth) + (y - 1)) + j] * filterKernel[j + (i*kernelDim)];
					}
				}
			}
			else // Close to border
			{
				uint32_t imageStarti = 0;
				uint32_t imageStartj = 0;
				uint32_t imageStartx = x;
				uint32_t imageStarty = y;
				uint32_t kernelIMax = kernelDim;
				uint32_t kernelJMax = kernelDim;
				uint32_t extraSubtractI = 0;
				uint32_t extraSubtractY = 0;

				// find startlocations
				bool corner = false;

				if (x < kernelHalfSize && y < kernelHalfSize) // corner ⌈
				{
					tmpFilterValue += signal[(x*signalWidth) + y] * filterKernel[0];
					tmpFilterValue += signal[(x*signalWidth) + y] * filterKernel[1];
					tmpFilterValue += signal[(x*signalWidth) + y + 1] * filterKernel[2];
					tmpFilterValue += signal[(x*signalWidth) + y] * filterKernel[3];
					tmpFilterValue += signal[((x + 1)*signalWidth) + y] * filterKernel[6];
					corner = true;
				}

				if (y < kernelHalfSize && ((signalLength - 1) - x) < kernelHalfSize) // corner ⌉
				{
					tmpFilterValue += signal[(x*signalWidth) + y] * filterKernel[1];
					tmpFilterValue += signal[(x*signalWidth) + y] * filterKernel[2];
					tmpFilterValue += signal[(x*signalWidth) + y] * filterKernel[5];
					tmpFilterValue += signal[(x*signalWidth) + (y + 1)] * filterKernel[8];
					tmpFilterValue += signal[((x - 1)*signalWidth) + y] * filterKernel[0];
					corner = true;
				}

				if (x < kernelHalfSize && ((signalWidth - 1) - y) < kernelHalfSize) // corner ⌊
				{
					tmpFilterValue += signal[(x*signalWidth) + y] * filterKernel[3];
					tmpFilterValue += signal[(x*signalWidth) + y] * filterKernel[6];
					tmpFilterValue += signal[(x*signalWidth) + y] * filterKernel[7];
					tmpFilterValue += signal[(x*signalWidth) + (y - 1)] * filterKernel[0];
					tmpFilterValue += signal[((x + 1)*signalWidth) + y] * filterKernel[8];
					corner = true;
				}

				if (((signalLength - 1) - x) < kernelHalfSize && ((signalWidth - 1) - y) < kernelHalfSize) // corner ⌋
				{
					tmpFilterValue += signal[(x*signalWidth) + y] * filterKernel[5];
					tmpFilterValue += signal[(x*signalWidth) + y] * filterKernel[7];
					tmpFilterValue += signal[(x*signalWidth) + y] * filterKernel[8];
					tmpFilterValue += signal[(x*signalWidth) + (y - 1)] * filterKernel[2];
					tmpFilterValue += signal[((x - 1)*signalWidth) + y] * filterKernel[6];
					corner = true;
				}

				if (x < kernelHalfSize)
				{
					extraSubtractI = kernelHalfSize;
					imageStarti = kernelHalfSize;
					imageStartx = kernelHalfSize;

					if (!corner)
					{
						tmpFilterValue += signal[(x*signalWidth) + (y - 1)] * filterKernel[0];
						tmpFilterValue += signal[(x*signalWidth) + y] * filterKernel[3];
						tmpFilterValue += signal[(x*signalWidth) + (y + 1)] * filterKernel[6];
					}

				}

				if (y < kernelHalfSize)
				{
					extraSubtractY = kernelHalfSize;
					imageStartj = kernelHalfSize;
					imageStarty = kernelHalfSize;

					if (!corner)
					{
						tmpFilterValue += signal[((x - 1)* signalWidth) + y] * filterKernel[0];
						tmpFilterValue += signal[(x*signalWidth) + y] * filterKernel[1];
						tmpFilterValue += signal[((x + 1)* signalWidth) + y] * filterKernel[2];
					}
				}

				if (((signalLength - 1) - x) < kernelHalfSize)
				{
					kernelIMax = kernelDim - kernelHalfSize;

					if (!corner)
					{
						tmpFilterValue += signal[(x* signalWidth) + (y - 1)] * filterKernel[2];
						tmpFilterValue += signal[(x* signalWidth) + y] * filterKernel[5];
						tmpFilterValue += signal[(x* signalWidth) + (y + 1)] * filterKernel[8];
					}
				}

				if (((signalWidth - 1) - y) < kernelHalfSize)
				{
					kernelJMax = kernelDim - kernelHalfSize;

					if (!corner)
					{
						tmpFilterValue += signal[((x - 1)* signalWidth) + y] * filterKernel[6];
						tmpFilterValue += signal[(x*signalWidth) + y] * filterKernel[7];
						tmpFilterValue += signal[((x + 1)* signalWidth) + y] * filterKernel[8];
					}
				}

				// for each location apply the filter kernel
				for (uint32_t i = imageStarti; i < kernelIMax; i++) // assumes kernel af uneven squared size
				{
					for (uint32_t j = imageStartj; j < kernelJMax; j++)
					{
						float signalValue = signal[((((imageStartx - 1) + (i - extraSubtractI))*signalWidth) + (imageStarty - 1)) + (j - extraSubtractY)];
						float kernelValue = filterKernel[j + (i*kernelDim)];

						tmpFilterValue += signal[((((imageStartx - 1) + (i - extraSubtractI))*signalWidth) + (imageStarty - 1)) + (j - extraSubtractY)] * filterKernel[j + (i*kernelDim)];
					}
				}
			}

			result[(x*signalWidth) + y] = tmpFilterValue;
		}
	}



	t2 = high_resolution_clock::now();

	auto duration = duration_cast<microseconds>(t2 - t1).count();
	f_latestExecutionTime = (float)duration;
}

#ifdef USE_CUDA
/*----------------------------------------------------------------------------*/
/**
* @brief Run a kernel filtering on the supplied signal, using the given kernel
* @note		This implementation handles making raplicas of the boundaries automatically.
*			This version is currently only working for a 3x3 kernel!!
*						CUDA VERSION!!!
*
* @param T* result :			Pointer to the array in which result should be stored
* @param T* paddedSignal :		Pointer to the array which holds the padded signal
* @param T* filterKernel :		pointer to the Filter kernel to apply to the signal
* @param uint32_t kernelDim:	Indicates the dimensionality of the kernel fx 3 for 3x3 kernel
* @param uint32_t signalLength: Indicates the length of the padded signal
* @param uint32_t signalWidth:	Indicates the width of the padded signal
*
* @retval void : none
*/
template <class T>
void KernelFilter<T>::runFilterReplicateCUDA(T* result, T* signal, T* kernelPtr, uint32_t kernelDim, uint32_t signalLength, uint32_t signalWidth)
{
	t1 = high_resolution_clock::now();
	// Perform filtering

	KernelFilterWithCudaV2(kernelPtr, signal, result, (uint16_t)signalWidth, (uint16_t)DEFAULT_KERNEL_DIM, signalLength);

	t2 = high_resolution_clock::now();

	auto duration = duration_cast<microseconds>(t2 - t1).count();
	f_latestExecutionTime = (float)duration;
}
#endif
/*----------------------------------------------------------------------------*/
/**
* @brief Run af pure kernel filtering without worrying about boundaries!
*
* @param T* result :			Pointer to the array in which result should be stored
* @param T* paddedSignal :		Pointer to the array which holds the padded signal
* @param T* filterKernel :		pointer to the Filter kernel to apply to the signal
* @param uint32_t kernelDim:	Indicates the dimensionality of the kernel fx 3 for 3x3 kernel
* @param uint32_t signalLength: Indicates the length of the padded signal
* @param uint32_t signalWidth:	Indicates the width of the padded signal
*
* @retval void : none
*/
template <class T>
void KernelFilter<T>::runFilterPure(T* result, T* paddedSignal, uint32_t kernelDim, uint32_t signalLength, uint32_t signalWidth)
{
	t1 = high_resolution_clock::now();
	// Perform filtering

	// setup variables
	uint32_t kernelHalfSize = floor(kernelDim / 2);

	// Running over the entire image
	for (uint32_t x = 0; x < (signalLength - (2 * kernelHalfSize)); x++)
	{
		for (uint32_t y = 0; y < signalWidth - (2 * kernelHalfSize); y++)
		{
			T tmpFilterValue = 0;
			// for each location apply the filter kernel
			for (uint32_t i = 0; i < kernelDim; i++) // assumes kernel of uneven squared size
			{
				for (uint32_t j = 0; j < kernelDim; j++)
				{
					tmpFilterValue += paddedSignal[((x + i)*signalWidth) + (y + j)] * filterKernel[j + (i*kernelDim)];
				}
			}
			result[(x*(signalWidth - (2 * kernelHalfSize))) + y] = tmpFilterValue;
		}
	}

	t2 = high_resolution_clock::now();

	auto duration = duration_cast<microseconds>(t2 - t1).count();
	f_latestExecutionTime = (float)duration;
}

/*----------------------------------------------------------------------------*/
/**
* @brief Pads the array with either zeros or replicas of the boundary values
* @note Its important that the given result array is capable of holding all the values
*			Such that signal that is 4x4 with a 3 dim kernel, is padded to a size of 6x6!
*
* @param T* result :			Pointer to the array in which result should be stored
* @param T* signal :			Pointer to the array which holds the original data
* @param uint32_t kernelDim :	Indicates the dimensionality of the kernel fx 3 for 3x3 kernel
* @param uint32_t signalLength: Indicates the signal length of the data to be padded
* @param uint32_t signalWidth : Indicates the signal width of the data to be padded
* @param bool Replicates :		If true the the arrays is padded with replicas, otherwise zeros
*
* @retval void : none
*/
template <class T>
void KernelFilter<T>::padArray(T* result, T* signal, uint32_t kernelDim, uint32_t signalLength, uint32_t signalWidth, bool Replicates)
{
	t3 = high_resolution_clock::now();

	uint32_t kernelHalfSize = floor(kernelDim / 2);
	uint32_t newArrayWidth = signalWidth + (2 * kernelHalfSize);
	uint32_t newArrayLength = signalLength + (2 * kernelHalfSize);

	/* Pad corners */
	T LeftTop = signal[0];															// corner ⌈
	for (uint32_t x = 0; x < kernelHalfSize; x++)
	{
		for (uint32_t y = 0; y < kernelHalfSize; y++)
		{
			if (Replicates)
				result[(x*newArrayWidth) + y] = LeftTop;
			else
				result[(x*newArrayWidth) + y] = 0;
		}
	}

	T RightTop = signal[(signalLength - 1)*signalWidth];							// corner ⌉
	for (uint32_t x = 0; x < kernelHalfSize; x++)
	{
		for (uint32_t y = 0; y < kernelHalfSize; y++)
		{
			if (Replicates)
				result[((x + (newArrayLength - kernelHalfSize))*newArrayWidth) + y] = RightTop;
			else
				result[((x + (newArrayLength - kernelHalfSize))*newArrayWidth) + y] = 0;
		}
	}

	T LeftBottom = signal[signalWidth - 1];											// corner ⌊
	for (uint32_t x = 0; x < kernelHalfSize; x++)
	{
		for (uint32_t y = 0; y < kernelHalfSize; y++)
		{
			if (Replicates)
				result[(x*newArrayWidth) + (y + (newArrayWidth - kernelHalfSize))] = LeftBottom;
			else
				result[(x*newArrayWidth) + (y + (newArrayWidth - kernelHalfSize))] = 0;
		}
	}

	T RightBottom = signal[((signalLength - 1)*signalWidth) + (signalWidth - 1)];	// corner ⌋
	for (uint32_t x = 0; x < kernelHalfSize; x++)
	{
		for (uint32_t y = 0; y < kernelHalfSize; y++)
		{
			if (Replicates)
				result[((x + (newArrayLength - kernelHalfSize))*newArrayWidth) + (y + (newArrayWidth - kernelHalfSize))] = RightBottom;
			else
				result[((x + (newArrayLength - kernelHalfSize))*newArrayWidth) + (y + (newArrayWidth - kernelHalfSize))] = 0;
		}
	}

	/* Pad Sides */
	for (uint32_t counts = 0; counts < signalWidth; counts++) // Left side
	{
		for (uint32_t x = 0; x < kernelHalfSize; x++)
		{
			if (Replicates)
				result[(x*newArrayWidth) + (counts + kernelHalfSize)] = signal[counts];
			else
				result[(x*newArrayWidth) + (counts + kernelHalfSize)] = 0;
		}
	}

	for (uint32_t counts = 0; counts < signalWidth; counts++) // right side
	{
		for (uint32_t x = (newArrayLength - kernelHalfSize); x < newArrayLength; x++)
		{
			if (Replicates)
				result[(x*newArrayWidth) + (counts + kernelHalfSize)] = signal[((signalLength - 1)*signalWidth) + counts];
			else
				result[(x*newArrayWidth) + (counts + kernelHalfSize)] = 0;
		}
	}

	for (uint32_t counts = 0; counts < signalLength; counts++) // Top side
	{
		for (uint32_t y = 0; y < kernelHalfSize; y++)
		{
			if (Replicates)
				result[((counts + kernelHalfSize)*newArrayWidth) + (y)] = signal[(counts*signalWidth)];
			else
				result[((counts + kernelHalfSize)*newArrayWidth) + (y)] = 0;
		}
	}

	for (uint32_t counts = 0; counts < signalLength; counts++) // Bottom side
	{
		for (uint32_t y = 0; y < kernelHalfSize; y++)
		{
			if (Replicates)
				result[((counts + kernelHalfSize)*newArrayWidth) + (y + (newArrayWidth - kernelHalfSize))] = signal[(counts*signalWidth) + (signalWidth - 1)];
			else
				result[((counts + kernelHalfSize)*newArrayWidth) + (y + (newArrayWidth - kernelHalfSize))] = 0;
		}
	}

	/* Fill internal */
	for (uint32_t x = 0; x < signalLength; x++) // Bottom side
	{
		for (uint32_t y = 0; y < signalWidth; y++)
		{
			result[((x + kernelHalfSize)*newArrayWidth) + (y + kernelHalfSize)] = signal[(x*signalWidth) + y];
		}
	}

	t4 = high_resolution_clock::now();

	auto duration = duration_cast<microseconds>(t4 - t3).count();
	f_latestExecutionTime = (float)duration;

}

/*----------------------------------------------------------------------------*/
/**
* @brief Return the latest execution for either of the algorithms
*
* @retval float : The execution time in microseconds (us)
*/
template <class T>
float KernelFilter<T>::getLatestExecutionTime(void)
{
	return f_latestExecutionTime;
}


/*----------------------------------------------------------------------------*/
/**
* @brief Returns the average execution time, when performing multiple tests.
*
* @retval float : The execution time in microseconds (us)
*/
template <class T>
float KernelFilter<T>::performXTestReturnExecutionTime(T* result, T* signal, T* filterKernel, uint32_t kernelDim, uint32_t signalLength, uint32_t signalWidth, uint32_t numberOfTest, FilterTypes testtype)
{
	float returnValue = 0;
	float* timeArray = new float[numberOfTest];

	for (uint32_t i = 0; i < numberOfTest; i++)
	{
		if (testtype == ZERO_PADDING)
			runFilterZeroPadding(result, signal, kernelDim, signalLength, signalWidth);
		else if (testtype == REPLICATE)
			runFilterReplicate(result, signal, kernelDim, signalLength, signalWidth);
		else if (testtype == PURE)
		{
			T * arrayKernelResult = new T[((signalLength + 2)*(signalWidth + 2))];
			padArray(arrayKernelResult, signal, kernelDim, signalLength, signalWidth, true);
			runFilterPure(result, arrayKernelResult, kernelDim, (signalLength + 2), (signalWidth + 2));
			delete arrayKernelResult;
		}
#ifdef USE_OPENCV
		else if (testtype == OPENCV)
		{
			runFilterOpenCV(result, signal, filterKernel, kernelDim, signalLength, signalWidth);
		}
#endif

		timeArray[i] = getLatestExecutionTime();
	}

	float sum = 0;
	for (uint32_t j = 0; j < numberOfTest; j++)
	{
		sum += timeArray[j];
	}

	returnValue = sum / numberOfTest;

	delete timeArray;
	return returnValue;
}

/*----------------------------------------------------------------------------*/
/**
* @brief Return the latest execution for either of the algorithms
*
* @param T* Kernel : Pointer to the array in which the Laplacian should be stored
*
* @retval void : none
*/
template <class T>
void KernelFilter<T>::generateLaplacianKernel(T* Kernel)
{

	Kernel[0] = (4 / (kernelAlphaValue + 1))*(kernelAlphaValue / 4);
	Kernel[1] = (4 / (kernelAlphaValue + 1))*((1 - kernelAlphaValue) / 4);
	Kernel[2] = (4 / (kernelAlphaValue + 1))*(kernelAlphaValue / 4);
	Kernel[3] = (4 / (kernelAlphaValue + 1))*((1 - kernelAlphaValue) / 4);
	Kernel[4] = (4 / (kernelAlphaValue + 1))*(-1);
	Kernel[5] = (4 / (kernelAlphaValue + 1))*((1 - kernelAlphaValue) / 4);
	Kernel[6] = (4 / (kernelAlphaValue + 1))*(kernelAlphaValue / 4);
	Kernel[7] = (4 / (kernelAlphaValue + 1))*((1 - kernelAlphaValue) / 4);
	Kernel[8] = (4 / (kernelAlphaValue + 1))*(kernelAlphaValue / 4);

}

#ifdef USE_OPENCV
/*----------------------------------------------------------------------------*/
/**
* @brief Run a kernel filtering on the supplied signal, using the given kernel
* @note		This implementation uses the OpenCV Library !
*
* @param T* result :			Pointer to the array in which result should be stored
* @param T* paddedSignal :		Pointer to the array which holds the padded signal
* @param T* filterKernel :		pointer to the Filter kernel to apply to the signal
* @param uint32_t kernelDim:	Indicates the dimensionality of the kernel fx 3 for 3x3 kernel
* @param uint32_t signalLength: Indicates the length of the padded signal
* @param uint32_t signalWidth:	Indicates the width of the padded signal
*
* @retval void : none
*/
template <class T>
void KernelFilter<T>::runFilterOpenCV(T* result, T* signal, uint32_t kernelDim, uint32_t signalLength, uint32_t signalWidth)
{
	t1 = high_resolution_clock::now();
	// Perform 2D filtering using kernel
	//https://docs.opencv.org/2.4/doc/tutorials/imgproc/imgtrans/filter_2d/filter_2d.html

	convertArrayToCVMat(imageMat, signal, signalLength, signalWidth);
	convertArrayToCVMat(kernelMat, filterKernel, kernelDim, kernelDim);
	Point anchor = Point(-1, -1);
	double delta = 0;
	int ddepth = -1;

	filter2D(imageMat, resultMat, ddepth, kernelMat, anchor, delta, BORDER_REPLICATE);

	convertCVMatToArray(resultMat, result, signalLength, signalWidth);

	t2 = high_resolution_clock::now();

	auto duration = duration_cast<microseconds>(t2 - t1).count();
	f_latestExecutionTime = (float)duration;
}


/*----------------------------------------------------------------------------*/
/**
* @brief Converts a 1D array into a CV::Mat object.
*
* @param cv::Mat returnObject :  OpenCV Mat to store the data in (2D)
* @param T* array_ :             Pointer to the array holding the data - 1D
* @param uint32_t signalLength : Indicates the signal length
* @param uint32_t signalWidth :  Indicates the signal width
*
* @retval void : none
*/
template <class T>
void KernelFilter<T>::convertArrayToCVMat(cv::Mat returnObject, T* array_, uint32_t signalLength, uint32_t signalWidth)
{
	uint32_t x = 0;
	uint32_t y = 0;

	for (uint32_t i = 0; i < (signalWidth * signalLength); i++)
	{
		returnObject.at<T>(x, y) = array_[i];
		x++;
		if (x >= signalWidth)
		{
			x = 0;
			y++;
		}
	}
}

/*----------------------------------------------------------------------------*/
/**
* @brief Converts a CV::Mat object to a 1D array.
*
* @param cv::Mat inputObject :     OpenCV Mat object to extract data from
* @param T* Outputarray :          Pointer to the array to store the data - 1D
* @param uint32_t signalLength :   Indicates the signal length
* @param uint32_t templateLength : Indicates the template length
*
* @retval void : none
*/
template <class T>
void KernelFilter<T>::convertCVMatToArray(cv::Mat inputObject, T* Outputarray, uint32_t signalLength, uint32_t templatewidth)
{
	uint32_t x = 0;
	uint32_t y = 0;

	for (uint32_t i = 0; i < (templatewidth * signalLength); i++)
	{
		Outputarray[i] = inputObject.at<T>(x, y);
		x++;
		if (x >= templatewidth)
		{
			x = 0;
			y++;
		}
	}
}
#endif

/*----------------------------------------------------------------------------*/
/**
* @brief Compares to array for equality dowb to one decimal, with some slack
*
* @param T* signal :             Pointer to the signal to be investigated
* @param T* truth :              Pointer to the comparasion signal to be investigated
* @param uint32_t signalLength : Indicates the signal length
* @param uint32_t signalWidth :  Indicates the signal width
*
* @retval uint32_t :             The number of un-equal elements, return 0 if all is equal!
*/
template <class T>
uint32_t KernelFilter<T>::compareEquality(T* signal, T* truth, uint32_t signalLength, uint32_t signalWidth)
{

	uint32_t areNotEqual = 0;
	for (int i = 0; i < signalLength*signalWidth; i++)
	{
		if (((int32_t)signal[i]) * 10 != ((int32_t)truth[i]) * 10)
		{
			if (((signal[i] * 10) >((truth[i] * 10) + 2)) ||
				((signal[i] * 10) < ((truth[i] * 10) - 2)) ||
				((truth[i] * 10) > ((signal[i] * 10) + 2)) ||
				((truth[i] * 10) < ((signal[i] * 10) - 2)))

			{
				areNotEqual++;
			}
		}
	}

	return areNotEqual;

}

/*----------------------------------------------------------------------------*/
/**
* @brief return the kernel filter coefficients
*
* @retval T* :   Pointer to the Kernel filter coeff.
*/
template <class T>
T* KernelFilter<T>::getKernelFilterCoeff(void)
{
	return filterKernel;
}

#endif
