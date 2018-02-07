///////////////////////////////////////////////////////////
//  ChannelFilter.h
//  Header:          This class holds the channel filtering functions.
//  Created on:      25-10-2017
//  Original author: MB
///////////////////////////////////////////////////////////
#ifndef CHANNEL_FILTER_H
#define CHANNEL_FILTER_H

#include "stdint.h"
#include "math.h"
#include <chrono>
#include <algorithm>
#include <iterator>

#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <device_functions.h>
#include <cuda.h>
#include "ProjectDefinitions.h"

using namespace std::chrono;

#ifdef USE_CUDA
extern "C" void ChannelFilterWithCuda(float *dev_result, float *dev_signal, float *dev_resultInt, float* dev_coeffsA, float* dev_coeffsB, uint16_t signalWidth, uint32_t signalLength);
#endif

template <class T>
class ChannelFilter
{
public:
	/* Constructor */
	ChannelFilter();
	~ChannelFilter(void);
	/* Channel functions calls*/
	void runFilter(T* result, T* signal, uint32_t signalWidth, uint32_t signalLength);
#ifdef USE_CUDA
	void runFilterCUDA(float *dev_result, float *dev_signal, float *dev_resultInt, float* dev_coeffsA, float* dev_coeffsB, uint32_t dataLength);
#endif
	float* getFilterCoeffsA(void);
	float* getFilterCoeffsB(void);
	/* Testing and debug */
	float getLatestExecutionTime(void);
	float performXTestReturnExecutionTime(T* out, T* in, uint32_t signalWidth, uint32_t signalLength, uint32_t numberOfTest);
private:
	void ReverseArray(T* signal, uint32_t signalWidth, uint32_t signalLength);
	void Filter(T* out, const float* b, const float* a, T* in, uint32_t signalWidth, uint32_t signalLength);
	void ReverseFilter(T* out, const float* b, const float* a, T* in, uint32_t signalWidth, uint32_t signalLength);
	std::chrono::high_resolution_clock::time_point t1;
	std::chrono::high_resolution_clock::time_point t2;
	float f_latestExecutionTime = 0;

	/* Filter coefficients are found with MATLAB:
	order  = 3;
	fpass  = [300 9000];
	Fs     = 30000;

	[b, a] = butter(order, fpass / (Fs /2), 'bandpass');
	*/

	// Filter Coeffs
	// 3rd Order Butterworth
	float _a[NUMBER_OF_A_COEFF] = { static_cast<float>(-2.328070365815921), static_cast<float>(1.613337586955990), static_cast<float>(-0.550760947854446), static_cast<float>(0.546587606197827), static_cast<float>(-0.236697172943531), static_cast<float>(-0.043892402907767) };
	float _b[NUMBER_OF_B_COEFF] = { static_cast<float>(0.236886761822704), static_cast<float>(-0.710660285468112), static_cast<float>(0.710660285468112), static_cast<float>(-0.236886761822704) };
	
	// 4th Order Butterworth
	//const float _a[8] = { static_cast<float>(-3.09480182556695), static_cast<float>(3.35590466129395), static_cast<float>(-1.86857682025173), static_cast<float>(1.34381136102870), static_cast<float>(-0.943260898767952), static_cast<float>(0.145954174911043), static_cast<float>(0.0355321080101539), static_cast<float>(0.0254783428151354) };
	//const float _b[5] = { static_cast<float>(0.150087125072278), static_cast<float>(-0.600348500289113), static_cast<float>(0.900522750433669), static_cast<float>(-0.600348500289113), static_cast<float>(0.150087125072278) };
	
	uint32_t aCoeffSize = NUMBER_OF_A_COEFF; 
	uint32_t bCoeffSize = NUMBER_OF_B_COEFF; 

};

/*----------------------------------------------------------------------------*/
/**
* @brief Constructor
*
* @retval void : none
*/
template <class T>
ChannelFilter<T>::ChannelFilter()
{

}

/*----------------------------------------------------------------------------*/
/**
* @brief Destructor
* @note Empty!
*/
template <class T>
ChannelFilter<T>::~ChannelFilter(void)
{

}

/*----------------------------------------------------------------------------*/
/**
* @brief Performs Zero-Phase filtering by running the filter coefficients defined within the class,
*		 both in the forward direction and the reverse direction.
* @note
*
* @param T* result :			Pointer to the array in which result should be stored
* @param T* signal :		    Pointer to the array which holds the signal to be filtered
* @param uint32_t signalWidth:	Indicates the amount of channels used
* @param uint32_t signalLength: Indicates the length of the signal
*
* @retval void : none
*/
template <class T>
void ChannelFilter<T>::runFilter(T* result, T* signal, uint32_t signalWidth, uint32_t signalLength)
{
	t1 = high_resolution_clock::now();

	// Perform filtering
	T* intermediateResult = new T[(unsigned int)(signalWidth*signalLength)];

	Filter(intermediateResult, _b, _a, signal, signalWidth, signalLength);
	ReverseFilter(result, _b, _a, intermediateResult, signalWidth, signalLength);

	// Capture execution time
	t2 = high_resolution_clock::now();
	auto duration = duration_cast<microseconds>(t2 - t1).count();
	f_latestExecutionTime = (float)duration;

	delete intermediateResult;
}

#ifdef USE_CUDA
/*----------------------------------------------------------------------------*/
/**
* @brief Performs Zero-Phase filtering with CUDA by running the filter coefficients defined within the class,
*		 both in the forward direction and the reverse direction.
* @note
*
* @param float *dev_result :			Pointer to the array in which result should be stored
* @param float *dev_signal :		    Pointer to the array which holds the signal to be filtered
* @param float *dev_resultInt:	Indicates the amount of channels used
* @param uint32_t signalLength: Indicates the length of the signal
*
* @retval void : none
*/
template <class T>
void ChannelFilter<T>::runFilterCUDA(float *dev_result, float *dev_signal, float *dev_resultInt, float* dev_coeffsA, float* dev_coeffsB, uint32_t dataLength)
{
	t1 = high_resolution_clock::now();
	// Perform filtering
	ChannelFilterWithCuda(dev_result, dev_signal, dev_resultInt, dev_coeffsA, dev_coeffsB, DATA_CHANNELS, dataLength);

	// Capture execution time
	t2 = high_resolution_clock::now();
	auto duration = duration_cast<microseconds>(t2 - t1).count();
	f_latestExecutionTime = (float)duration;
}
#endif
/*----------------------------------------------------------------------------*/
/**
* @brief Return the latest execution for either of the algorithms
*
* @retval float : The execution time in microseconds (us)
*/
template <class T>
float ChannelFilter<T>::getLatestExecutionTime(void)
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
float ChannelFilter<T>::performXTestReturnExecutionTime(T* out, T* in, uint32_t signalWidth, uint32_t signalLength, uint32_t numberOfTest)
{
	float returnValue = 0;
	float* timeArray = new float[numberOfTest];

	for (uint32_t i = 0; i < numberOfTest; i++)
	{
		runFilter(out, in, signalWidth, signalLength);

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
* @brief Reverses the data of the supplied array.
*
* @param T* signal :		    Pointer to the array which holds the signal to be reversed
* @param uint32_t signalWidth:	Indicates the amount of channels used
* @param uint32_t signalLength: Indicates the length of the array
*
* @retval void : none
*/
template <class T>
void ChannelFilter<T>::ReverseArray(T* signal, uint32_t signalWidth, uint32_t signalLength)
{
	for (int x = 0; x < signalWidth; x++)
	{
		for (int i = 1; i <= signalLength / 2; i++)
		{
			float temporary = signal[(i - 1)*signalWidth + x];
			signal[(i - 1)*signalWidth + x] = signal[(signalWidth*signalLength) - (i*signalWidth) + x];
			signal[(signalWidth*signalLength) - (i*signalWidth) + x] = temporary;
		}
	}
}

/*----------------------------------------------------------------------------*/
/**
* @brief Run the channel filtering in the forward direction.
* @note	 Is a regular filter application, and functions as the first step used for zero-phase filtering.
*
* @param T* out :			    Pointer to the array in which result should be stored
* @param const float* b :		Pointer to the array holding the feedforward coefficients of the filter
* @param const float* a :		Pointer to the array holding the feedback coefficients of the filter
* @param T* in :		        Pointer to the array which holds the signal to be filtered
* @param uint32_t signalWidth:	Indicates the amount of channels used
* @param uint32_t signalLength: Indicates the length of the signal
*
* @retval void : none
*/
template <class T>
void ChannelFilter<T>::Filter(T* out, const float* b, const float* a, T* in, uint32_t signalWidth, uint32_t signalLength)
{
	for (int x = 0; x < (int)signalWidth; x++)
	{
		for (int i = 0; i < (int)signalLength; i++)
		{
			uint32_t index = ((i*signalWidth) + x);
			float tmp = 0.;
			int j = 0;
			out[index] = 0.f;
			for (j = 0; j < (int)bCoeffSize; j++)
			{
				// Every second b coefficient is 0, thus skipped in the calculation 
				// and not included in the array holding the coefficients.
				if (i - (j * 2) < 0) continue;
				tmp += b[j] * in[index - (j * 2)*signalWidth];
			}


			for (j = 0; j < (int)aCoeffSize; j++)
			{
				// The first a coefficient is 1, thus skipped and 
				// omitted in the array holding the coefficients.
				if (i - (j + 1) < 0) continue;
				tmp -= a[j] * out[index - (j + 1)*signalWidth];
			}

			out[index] = tmp;
		}
	}
}

/*----------------------------------------------------------------------------*/
/**
* @brief Run the channel filtering in the reverse direction.
* @note	 Is the second step used for zero-phase filtering.
*
* @param T* out :		     	Pointer to the array in which result should be stored
* @param const float* b :		Pointer to the array holding the feedforward coefficients of the filter
* @param const float* a :		Pointer to the array holding the feedback coefficients of the filter
* @param T* in :		        Pointer to the array which holds the signal to be filtered
* @param uint32_t signalWidth:	Indicates the amount of channels used
* @param uint32_t signalLength: Indicates the length of the signal
*
* @retval void : none
*/
template <class T>
void ChannelFilter<T>::ReverseFilter(T* out, const float* b, const float* a, T* in, uint32_t signalWidth, uint32_t signalLength)
{

	for (int x = (int)signalWidth - 1; x >= 0; x--)
	{
		for (int i = (int)signalLength - 1; i >= 0; i--)
		{
			uint32_t index = ((i*signalWidth) + x);
			float tmp = 0.;
			int j = 0;
			out[index] = 0.f;
			for (j = 0; j < (int)bCoeffSize; j++)
			{
				// Every second b coefficient is 0, thus skipped in the calculation 
				// and not included in the array holding the coefficients.
				if (i + (j * 2) > (int)signalLength - 1) continue;
				tmp += b[j] * in[(index)+(j * 2)*signalWidth];
			}

			for (j = 0; j < (int)aCoeffSize; j++)
			{
				// The first a coefficient is 1, thus skipped and 
				// omitted in the array holding the coefficients.
				if (i + (j + 1) > (int)signalLength - 1) continue;
				tmp -= a[j] * out[(index)+(j + 1)*signalWidth];
			}

			out[index] = tmp;
		}
	}

}

/*----------------------------------------------------------------------------*/
/**
* @brief Retrieves the feedback coefficients.
*
* @param float* Coeffs : Pointer to the array holding the feedback coefficients of the filter
* @param int size :      Indicates the size of the Coeffs array.
*
* @retval void : none
*/
template <class T>
float* ChannelFilter<T>::getFilterCoeffsA(void)
{
	return _a;
}

/*----------------------------------------------------------------------------*/
/**
* @brief Retrieves the feedforward coefficients.
*
* @param float* Coeffs : Pointer to the array holding the feedforward coefficients of the filter
* @param int size :      Indicates the size of the Coeffs array.
*
* @retval void : none
*/
template <class T>
float* ChannelFilter<T>::getFilterCoeffsB(void)
{
	return _b;
}

#endif
