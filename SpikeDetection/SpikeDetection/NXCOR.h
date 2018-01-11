///////////////////////////////////////////////////////////
//  NXCOR.h
//  Header:          Normalized Cross Correlation functions.
//  Created on:      23-10-2017
//  Original author: MB
///////////////////////////////////////////////////////////
#ifndef NXCOR_H
#define NXCOR_H

#include "stdint.h"
#include "math.h"
#include <chrono>

#include "ProjectDefinitions.h"

#ifdef USE_OPENCV
#include <opencv2\opencv.hpp>
#endif

using namespace std::chrono;

template <class T>
class NXCOR
{
public:
	/* Constructor */
	NXCOR(uint32_t templateLength, uint32_t templateChannels, uint32_t signalLength);
	/* NXCOR functions calls*/
	void runNXCOR(T* result, T* signal, T* template_, uint32_t templateLength, uint32_t templateChannels, uint32_t signalLength,  uint32_t signalLowerIndex);
	void runNXCOR_STD(T* result, T* signal, T* template_, uint32_t templateLength, uint32_t templateChannels, uint32_t signalLength, uint32_t signalLowerIndex, uint32_t numberOfChannelDrift);
#ifdef USE_OPENCV
	void runNXCOROpenCV(T* result, T* signal, T* template_, uint32_t templateLength, uint32_t templateChannels, uint32_t signalLength, uint32_t signalLowerIndex);
#endif
	/* Helper Functions */
	float getLatestExecutionTime(void);
	float performXTestReturnExecutionTime(T* result, T* signal, T* template_, uint32_t templateLength, uint32_t templateChannels, uint32_t signalLength, bool useOpenCV, uint32_t numberOfTest);
private:
	T mean(T* inputPatch, uint32_t r, uint32_t c, uint32_t stride, uint32_t wt, uint32_t ht);
#ifdef USE_OPENCV
	void convertArrayToCVMat(cv::Mat returnObject, T* array_, uint32_t signalLength, uint32_t signalWidth, uint32_t templateWidth, uint32_t signalLowerIndex);
	void convertCVMatToArray(cv::Mat inputObject, T* Outputarray, uint32_t signalLength, uint32_t signalWidth);
#endif	
	high_resolution_clock::time_point t1;
	high_resolution_clock::time_point t2;
	float f_latestExecutionTime = 0;
#ifdef USE_OPENCV
	cv::Mat imageMat;
	cv::Mat templateMat;
	cv::Mat resultMat;
#endif
};

/*----------------------------------------------------------------------------*/
/**
* @brief Constructor
*
* @param uint32_t templateLength :   Indicates the length of the template.
* @param uint32_t templateChannels : Indicates the width of the template.
* @param uint32_t signalLength :     Indicates the length of the signal.
* 
* @retval void : none
*/
template <class T>
NXCOR<T>::NXCOR(uint32_t templateLength, uint32_t templateChannels, uint32_t signalLength)
#ifdef USE_OPENCV
	:
	imageMat(templateChannels, signalLength, CV_32FC1),
	templateMat(templateChannels, templateLength, CV_32FC1),
	resultMat(1, (signalLength - templateLength), CV_32FC1)
#endif
{
	
}

/*----------------------------------------------------------------------------*/
/**
* @brief Performs NXCOR computation between the signal and a template
*   @note This Implementation assumes that the signal width and
*         the template width is the same
*
* @param T* result :                 Pointer to the array in which the NXCOR output is stored
*				                     - The resulting array is (signalLength-templateLength + 1) long.
* @param T* signal :                 Pointer to the input signal array - 1D
* @param T* template_ :              Pointer to the input template array - 1D
* @param uint32_t templateLength :   Indicates of the template length
* @param uint32_t templateChannels : Indicates the number og channels in the template and the signal
* @param uint32_t signalLength :     Indicates the length of the signal
* @param uint32_t signalLowerIndex : Indicates the start channel of where the template should be applied from
*
* @retval void : none
*/
template <class T>
void NXCOR<T>::runNXCOR(T* result, T* signal, T* template_, uint32_t templateLength, uint32_t templateChannels, uint32_t signalLength, uint32_t signalLowerIndex)
{
	t1 = high_resolution_clock::now();
	const uint32_t wt = templateChannels;
	const uint32_t ht = templateLength;
	const uint32_t w = 32;
	const uint32_t h = signalLength;

	T xcorr = 0;     // Cross correlation between template and pixel area
	T varSignal = 0; // Variance Signal area
	T varTemp = 0;   // Variance template
	T avgSignal = 0; // Average Signal area
	T avgTemp = 0;   // Average template

	// Clear result
	//for (int n = 0; n < (h- ht); n++) result[n] = 0;

	// Computes average of template for red and blue color
	avgTemp = mean(template_, 0, 0, wt, wt, ht);

	// Compute variance of template
	for (uint32_t k = 0; k < ht; k++) // Cross correlation with template
		for (uint32_t l = 0; l < wt; l++) {
			T temp = template_[k * wt + l];

			// Red color, cross correlation, variance pixel, variance template
			T tr = temp - avgTemp;
			varTemp = varTemp + (tr*tr);
		}

	for (uint32_t j = 0; j <= (h - ht); j++) { // For all coloums - assuming all rows every time

		// Computes mean of image area
		avgSignal = mean(signal, j, signalLowerIndex, 32, wt, ht);

		// Clear varance and cross correlation
		xcorr = 0;
		varSignal = 0;

		// Computes cross correlation and variance
		for (uint32_t x = 0; x < ht; x++) // Cross correlation with template
			for (uint32_t y = 0; y < wt; y++) {
				T signalValue = signal[(((x+j)*w) + y + signalLowerIndex)];
				T temp = template_[(x*wt) + y];

				T pr = signalValue - avgSignal;
				T tr = temp - avgTemp;
				xcorr += (pr * tr);
				varSignal = varSignal + (pr * pr);
			}

		// Computes normalized cross correlation
		//T normxcorr = xcorr / sqrt(varSignal * varTemp);
		result[j] = (T)(xcorr / sqrt(varSignal * varTemp));
	}
	

	t2 = high_resolution_clock::now();

	auto duration = duration_cast<microseconds>(t2 - t1).count();
	f_latestExecutionTime = (float)duration;
}


/*----------------------------------------------------------------------------*/
/**
* @brief Performs NXCOR computation between the signal and a template with drift handling.
*   @note This Implementation assumes that the signal width and
*         the template width is the same. STD stands for Single Threaded Drift Handling		  
*
* @param T* result :                     Pointer to the array in which the NXCOR output is stored
*				                         - The resulting array is (signalLength-templateLength + 1) long.
* @param T* signal :                     Pointer to the input signal array - 1D
* @param T* template_ :                  Pointer to the input template array - 1D
* @param uint32_t templateLength :       Indicates of the template length
* @param uint32_t templateChannels :     Indicates the number og channels in the template and the signal
* @param uint32_t signalLength :         Indicates the length of the signal
* @param uint32_t signalLowerIndex :     Indicates the start channel of where the template should be applied from
* @param uint32_t numberOfChannelDrift : Indicates the amount of channels drift can be handled for.
*
* @retval void : none
*/
template <class T>
void NXCOR<T>::runNXCOR_STD(T* result, T* signal, T* template_, uint32_t templateLength, uint32_t templateChannels, uint32_t signalLength, uint32_t signalLowerIndex, uint32_t numberOfChannelDrift)
{
	t1 = high_resolution_clock::now();
	const uint32_t wt = templateChannels;
	const uint32_t ht = templateLength;
	const uint32_t w = 32;
	const uint32_t h = signalLength;
	uint32_t driftIterations = (numberOfChannelDrift * 2) + 1;

	T xcorr = 0; // Cross correlation between template and pixel area
	T varSignal = 0; // Variance Signal area
	T varTemp = 0; // Variance template
	T avgSignal = 0; // Average Signal area
	T avgTemp = 0; // Average template
	T bestXCorr = 0;
	int32_t signalLowerIndexOld = signalLowerIndex;
	// Clear result
	//for (int n = 0; n < (h- ht); n++) result[n] = 0;

	for (uint32_t d = 0; d < driftIterations; d++)
	{
		int32_t dataOffset = d - numberOfChannelDrift;
		int32_t templateStartChannel = 0;
		int32_t templateEndChannel = templateChannels;
		int32_t dataEndChannel = templateChannels;

		if ( (signalLowerIndexOld + templateChannels + dataOffset) <= DATA_CHANNELS && /* the data and template must be cropped ! */
			 (int32_t(signalLowerIndexOld) + dataOffset) >= 0 )
		{
			signalLowerIndex = signalLowerIndexOld + dataOffset;
		}
		else
		{
			if ((int32_t(signalLowerIndexOld) + dataOffset) < 0)
			{
				templateStartChannel -= dataOffset; // Increment
				dataEndChannel -= 1;
				signalLowerIndex = 0;
				//templateEndChannel += dataOffset; // This will decrement!!
			}
			else if ((int32_t(signalLowerIndexOld) + templateChannels + dataOffset) > DATA_CHANNELS)
			{
				//templateStartChannel -= dataOffset; // this will increment, as d will always be negative here!!
				signalLowerIndex = signalLowerIndexOld + dataOffset;
				dataEndChannel -= 1;
				templateEndChannel -= dataOffset; // This will decrement!!
			}
		}

		// Computes average of template for red and blue color
		avgTemp = mean(template_, 0, templateStartChannel, wt, (templateEndChannel- templateStartChannel), ht);

		// Compute variance of template
		varTemp = 0; // Variance template
		for (uint32_t k = 0; k < ht; k++) // Cross correlation with template
			for (uint32_t l = templateStartChannel; l < templateEndChannel; l++) {
				T temp = template_[k * wt + l];

				// Red color, cross correlation, variance pixel, variance template
				T tr = temp - avgTemp;
				varTemp = varTemp + (tr*tr);
			}

		for (uint32_t j = 0; j <= (h - ht); j++) { // For all coloums - assuming all rows every time

			// Computes mean of image area
			avgSignal = mean(signal, j, signalLowerIndex, DATA_CHANNELS, (templateEndChannel - templateStartChannel), ht);

			// Clear varance and cross correlation
			xcorr = 0;
			varSignal = 0;

			// Computes cross correlation and variance
			for (uint32_t x = 0; x < ht; x++) // Cross correlation with template
				for (uint32_t y = 0; y < dataEndChannel; y++) {
					T signalValue = signal[(((x + j)*w) + y + signalLowerIndex)];
					T temp = template_[(x*wt) + y + templateStartChannel];

					T pr = signalValue - avgSignal;
					T tr = temp - avgTemp;
					xcorr += (pr * tr);
					varSignal = varSignal + (pr * pr);
				}

			// Computes normalized cross correlation
			//T normxcorr = xcorr / sqrt(varSignal * varTemp);
			if (d > 0)
			{
				T currentData = (T)(xcorr / sqrt(varSignal * varTemp));
				if (currentData > result[j])
				{
					result[j] = currentData;
				}
			}
			else
			{
				result[j] = (T)(xcorr / sqrt(varSignal * varTemp));
			}
		}

	}

	t2 = high_resolution_clock::now();

	auto duration = duration_cast<microseconds>(t2 - t1).count();
	f_latestExecutionTime = (float)duration;
}

/*----------------------------------------------------------------------------*/
/**
* @brief Calculates the mean for a given window
*
* @param T* inputPatch:    Pointer to the supplied data
* @param uint32_t r:       Start index couloum to start from
* @param uint32_t c:       Start index row to start from
* @param uint32_t stride : The size of the row (channel width)
* @param uint32_t wt :     Indicates the width of the template
* @param uint32_t ht :     Indicates the length or height of the template
*
* @retval T : The mean value
*/
template <class T>
T NXCOR<T>::mean(T* inputPatch, uint32_t r, uint32_t c, uint32_t stride, uint32_t wt, uint32_t ht)
{
	T average = 0;
	for (uint32_t i = r; i<ht + r; i++)
		for (uint32_t j = c; j<wt + c; j++) {
			average += inputPatch[(i * stride) + j]; // Computes average
		}
	average = average / (wt*ht);
	return average;
}


#ifdef USE_OPENCV
/*----------------------------------------------------------------------------*/
/**
* @brief Performs NXCOR computation between the signal and a template using OpenCV impl.
*   @note This Implementation assumes that the width signal width and
*         the template width is the same
*
* @param T* result :                 Pointer to the array in which the NXCOR output is stored
*				                     - The resulting array is (signalLength-templateLength + 1) long.
* @param T* signal :                 Pointer to the input signal array - 1D
* @param T* template_ :              Pointer to the input template array - 1D
* @param uint32_t templateLength :   Indicates the template length
* @param uint32_t templateChannels : Indicates the number of channels in the template and the signal
* @param uint32_t signalLength :     Indicates the length of the signal
* @param uint32_t signalLowerIndex : Indicates the start channel of where the template should be applied from
*
* @retval void : none
*/
template <class T>
void NXCOR<T>::runNXCOROpenCV(T* result, T* signal, T* template_, uint32_t templateLength, uint32_t templateChannels, uint32_t signalLength, uint32_t signalLowerIndex)
{
	t1 = high_resolution_clock::now();
	
	convertArrayToCVMat(imageMat, signal, signalLength, DATA_CHANNELS, templateChannels, signalLowerIndex);
	convertArrayToCVMat(templateMat, template_, templateLength, templateChannels, templateChannels, 0);
	
	cv::matchTemplate(imageMat, templateMat, resultMat, CV_TM_CCORR_NORMED);
	
	convertCVMatToArray(resultMat, result, signalLength, templateLength);
	
	t2 = high_resolution_clock::now();

	auto duration = duration_cast<microseconds>(t2 - t1).count();
	f_latestExecutionTime = (float)duration;
}


/*----------------------------------------------------------------------------*/
/**
* @brief Converts a 1D array into a CV::Mat object.
*
* @param cv::Mat returnObject :      OpenCV Mat to store the data in (2D)
* @param T* array_ :                 Pointer to the array holding the data - 1D
* @param uint32_t signalLength :     Indicates the signal length
* @param uint32_t signalWidth :      Indicates the signal width
* @param uint32_t templateWidth :    Indicates the template width
* @param uint32_t signalLowerIndex : Indicates the start channel of where the template should be applied from
*
* @retval void : none
*/
template <class T>
void NXCOR<T>::convertArrayToCVMat(cv::Mat returnObject, T* array_, uint32_t signalLength, uint32_t signalWidth, uint32_t templateWidth, uint32_t signalLowerIndex)
{

	for (uint32_t i = 0; i < (signalLength); i++)
	{
		for (uint32_t y = signalLowerIndex; y < signalLowerIndex+templateWidth; y++)
		{
			returnObject.at<T>((y-signalLowerIndex), i) = array_[(i*signalWidth)+y];
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
void NXCOR<T>::convertCVMatToArray(cv::Mat inputObject, T* Outputarray, uint32_t signalLength, uint32_t templateLength)
{
	for (uint32_t i = 0; i < (signalLength-templateLength); i++)
	{
		Outputarray[i] = inputObject.at<T>(0, i);
	}
}
#endif

/*----------------------------------------------------------------------------*/
/**
* @brief Return the latest execution for either of the algorithms
*
* @retval float : The execution time in microseconds (us)
*/
template <class T>
float NXCOR<T>::getLatestExecutionTime(void)
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
float NXCOR<T>::performXTestReturnExecutionTime(T* result, T* signal, T* template_, uint32_t templateLength, uint32_t templateChannels, uint32_t signalLength, bool useOpenCV, uint32_t numberOfTest)
{
	float returnValue = 0;
	float* timeArray = new float[numberOfTest];

	for (uint32_t i = 0; i < numberOfTest; i++)
	{
#ifdef USE_OPENCV
		if (useOpenCV)
		{
			runNXCOROpenCV(result, signal, template_, templateLength, templateChannels, signalLength);
			timeArray[i] = getLatestExecutionTime();
		}
		else
		{
#endif
			runNXCOR(result, signal, template_, templateLength, templateChannels, signalLength);
			timeArray[i] = getLatestExecutionTime();
#ifdef USE_OPENCV
		}
#endif
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

#endif