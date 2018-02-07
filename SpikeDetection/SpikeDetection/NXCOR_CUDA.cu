
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <device_functions.h>
#include <cuda.h>
#include <stdio.h>
#include <iostream>
#include <chrono>
#include "ProjectDefinitions.h"
using namespace std::chrono;

#ifdef USE_CUDA

extern "C" cudaError_t CheckForError(char * str);

__global__ void naive_custom_normalized_cross_correlation3D(
	float*				d_response,
	const float* 		d_original,
	const float* 		d_template,
	uint16_t			templateLength,
	uint16_t			templateChannels,
	uint32_t			signalLength,
	uint16_t			signalChannels,
	uint16_t*			d_signalLowerIndex
)
{
	// These values are stored in thread register
	// Make sure not to make more than 64 bytes of variables, as this is the max on the GPU GTX 1060!
	// Other GPU have other limits! - otherwise the data will be stored in a slow to read/write location
	// Which makes the computation time increase dramatically!
	//uint16_t numberOfIterations = (signalLength - templateLength) / (blockDim.x*gridDim.x);			// Number of iterations each thread has to go through
	uint16_t signalIndex = d_signalLowerIndex[blockIdx.y];
	float xcorr = 0;																		// Cross correlation between template and pixel area
	float varSignal = 0;																	// Variance Signal area
	float varTemp = 0;																		// Variance template
	float avgSignal = 0;																	// Average Signal area
	float avgTemp = 0;																		// Average template
	uint32_t signalIndexOffset = threadIdx.x + (blockDim.x*blockIdx.x); //+ (counter*blockDim.x*gridDim.x);
																							// blockDim.y represents which of the template that the thread is working on, e.g. blockDim.y = 0 equals the first template, 1 equals the seconds ...
	if (signalIndexOffset < (signalLength - templateLength))
	{
																							/* TEMPLATE RELATED */
																							// Inlined mean calculation of template
		for (uint16_t i = 0; i<templateLength; i++)
			for (uint16_t j = 0; j<templateChannels; j++) {
				avgTemp += d_template[(i * templateChannels) + j + (blockIdx.y*templateLength*templateChannels)]; // Computes average
																												  //avgTemp += d_template[(i * templateChannels) + j]; // Computes average
			}
		avgTemp = avgTemp / (templateChannels*templateLength);

		// Compute variance of template
		for (uint16_t i = 0; i < templateLength; i++) // Cross correlation with template
			for (uint16_t j = 0; j < templateChannels; j++) {

				float tr = d_template[i * templateChannels + j + (blockIdx.y*templateLength*templateChannels)] - avgTemp;
				//float tr = d_template[i * templateChannels + j] - avgTemp;
				varTemp += (tr*tr);
			}

	
		// Computes mean of image area
			// avgSignal = mean(signal, j, 0, w, wt, ht);

			// Inlined mean calculation
		avgSignal = 0;
		for (uint32_t i = signalIndexOffset; i < templateLength + signalIndexOffset; i++)
			for (uint32_t j = signalIndex; j < templateChannels + signalIndex; j++) {
				avgSignal += d_original[(i * signalChannels) + j]; // Computes average
			}
		avgSignal = avgSignal / (templateChannels*templateLength);

		// Clear variance and cross correlation
		xcorr = 0;
		varSignal = 0;

		// Computes cross correlation and variance
		for (uint32_t i = 0; i < templateLength; i++) // Cross correlation with template
			for (uint32_t j = 0; j < templateChannels; j++) {
				//float signalValue = d_original[(((x + signalIndexOffset)*templateChannels) + y + d_signalLowerIndex[blockDim.y])];
				//float temp = d_template[(x*templateChannels) + y + (blockDim.y*templateLength*templateChannels)];

				float pr = d_original[(((i + signalIndexOffset)*signalChannels) + j + signalIndex)] - avgSignal;
				//float tr = temp - avgTemp;
				xcorr += ((pr) * (d_template[(i*templateChannels) + j + (blockIdx.y*templateLength*templateChannels)] - avgTemp));
				//xcorr += ((pr) * (d_template[(i*templateChannels) + j] - avgTemp));
				varSignal += ((pr) * (pr));
			}

		// Computes normalized cross correlation
		//T normxcorr = xcorr / sqrt(varSignal * varTemp);
		if (varTemp != 0)
		{
			d_response[signalIndexOffset + (signalLength*blockIdx.y)] = xcorr / sqrtf(varSignal * varTemp);
		}
		else
		{
			d_response[signalIndexOffset + (signalLength*blockIdx.y)] = 0;
		}
		//d_response[signalIndexOffset] = xcorr / sqrtf(varSignal * varTemp);
	}
}

__global__ void naive_custom_normalized_cross_correlation3D_STD(
	float*				d_response,
	const float* 		d_original,
	const float* 		d_template,
	uint16_t			templateLength,
	uint16_t			templateChannels,
	uint32_t			signalLength,
	uint16_t			signalChannels,
	uint16_t*			d_signalLowerIndex
)
{
	// These values are stored in thread register
	// Make sure not to make more than 64 bytes of variables, as this is the max on the GPU GTX 1060!
	// Other GPU have other limits! - otherwise the data will be stored in a slow to read/write location
	// Which makes the computation time increase dramatically!
	//unsigned short numberOfIterations = (signalLength - templateLength) / (blockDim.x*gridDim.x);			// Number of iterations each thread has to go through
	uint16_t signalIndex = d_signalLowerIndex[blockIdx.y];
	float xcorr = 0;																		// Cross correlation between template and pixel area
	float varSignal = 0;																	// Variance Signal area
	float varTemp = 0;																		// Variance template
	float avgSignal = 0;																	// Average Signal area
	float avgTemp = 0;																		// Average template
	uint32_t signalIndexOffset = threadIdx.x + (blockDim.x*blockIdx.x);
	//const signed short signalLowerIndexOld = signalLowerIndex;
	// blockDim.y represents which of the template that the thread is working on, e.g. blockDim.y = 0 equals the first template, 1 equals the seconds ..

	if (signalIndexOffset < (signalLength - templateLength))
	{
		for (unsigned short d = 0; d < ((NUMBER_OF_DRIFT_CHANNELS_HANDLED * 2) + 1); d++)
		{
			int16_t dataOffset = d - NUMBER_OF_DRIFT_CHANNELS_HANDLED;
			int16_t templateStartChannel = 0;
			int16_t templateEndChannel = templateChannels;
			int16_t dataEndChannel = templateChannels;
			int16_t signalLowerIndex = signed short(signalIndex);

			if ((signalIndex + templateChannels + dataOffset) <= DATA_CHANNELS && /* the data and template must be cropped ! */
				(int16_t(signalIndex) + dataOffset) >= 0)
			{
				signalLowerIndex = signalIndex + dataOffset;
			}
			else
			{
				if ((int16_t(signalIndex) + dataOffset) < 0)
				{
					templateStartChannel -= dataOffset; // Increment
					dataEndChannel -= 1;
					signalLowerIndex = 0;
					//templateEndChannel += dataOffset; // This will decrement!!
				}
				else if ((int16_t(signalIndex) + templateChannels + dataOffset) > DATA_CHANNELS)
				{
					//templateStartChannel -= dataOffset; // this will increment, as d will always be negative here!!
					signalLowerIndex = signalIndex + dataOffset;
					dataEndChannel -= 1;
					templateEndChannel -= dataOffset; // This will decrement!!
				}
			}


			/* TEMPLATE RELATED */
			// Inlined mean calculation of template
			avgTemp = 0;

			for (uint16_t i = 0; i < templateLength; i++)
				for (uint16_t j = templateStartChannel; j < templateStartChannel + (templateEndChannel - templateStartChannel); j++) {
					avgTemp += d_template[(i * templateChannels) + j + (blockIdx.y*templateLength*templateChannels)]; // Computes average
				}
			avgTemp = avgTemp / ((templateEndChannel - templateStartChannel)*templateLength);

			// Compute variance of template
			varTemp = 0;
			for (uint16_t i = 0; i < templateLength; i++) // Cross correlation with template
				for (uint16_t j = templateStartChannel; j < templateEndChannel; j++) {
					float tr = d_template[i * templateChannels + j + (blockIdx.y*templateLength*templateChannels)] - avgTemp;
					//float tr = d_template[i * templateChannels + j] - avgTemp;
					varTemp += (tr*tr);
				}

			/* SIGNAL AND TEMPLATE RELATED */
			// Computes mean of image area
			// avgSignal = mean(signal, j, 0, w, wt, ht);

			// Inlined mean calculation
			avgSignal = 0;
			for (uint32_t i = signalIndexOffset; i < templateLength + signalIndexOffset; i++)
				for (uint32_t j = signalLowerIndex; j < (templateEndChannel - templateStartChannel) + signalLowerIndex; j++) {
					avgSignal += d_original[(i * signalChannels) + j]; // Computes average
				}
			avgSignal = avgSignal / ((templateEndChannel - templateStartChannel)*templateLength);

			// Clear variance and cross correlation

			xcorr = 0;
			varSignal = 0;

			// Computes cross correlation and variance
			for (uint32_t i = 0; i < templateLength; i++) // Cross correlation with template
				for (uint32_t j = 0; j < dataEndChannel; j++) {
					//float signalValue = d_original[(((x + signalIndexOffset)*templateChannels) + y + d_signalLowerIndex[blockDim.y])];
					//float temp = d_template[(x*templateChannels) + y + (blockDim.y*templateLength*templateChannels)];

					float pr = d_original[(((i + signalIndexOffset)*signalChannels) + j + signalLowerIndex)] - avgSignal;
					//float tr = temp - avgTemp;
					xcorr += ((pr) * (d_template[(i*templateChannels) + j + (blockIdx.y*templateLength*templateChannels) + templateStartChannel] - avgTemp));
					//xcorr += ((pr) * (d_template[(i*templateChannels) + j] - avgTemp));
					varSignal += ((pr) * (pr));
				}

			// Computes normalized cross correlation
			//T normxcorr = xcorr / sqrt(varSignal * varTemp);
			if (d > 0)
			{
				float currentValue = xcorr / sqrtf(varSignal * varTemp);
				if (currentValue > d_response[signalIndexOffset + (((signalLength - templateLength) + 1)*blockIdx.y)])
				{
					d_response[signalIndexOffset + (((signalLength - templateLength) + 1)*blockIdx.y)] = currentValue;
				}
			}
			else
			{
				d_response[signalIndexOffset + (((signalLength - templateLength) + 1)*blockIdx.y)] = xcorr / sqrtf(varSignal * varTemp);
				//d_response[signalIndexOffset] = xcorr / sqrtf(varSignal * varTemp);
			}

		}
	}
}

extern "C" void NXCOR_CUDA_3D(float *dev_result, const float *dev_templates, const float *dev_signal, uint16_t templateLength, uint16_t templateChannels, uint32_t signalLength, uint16_t signalChannels, uint16_t numberOfTemplates, uint16_t* dev_signalLowerIndex)
{
	uint32_t GridXSize = signalLength / MAXIMUM_NUMBER_OF_THREADS;

	if (signalLength % MAXIMUM_NUMBER_OF_THREADS != 0)
	{
		GridXSize++;
	}

	const dim3 blockSize(MAXIMUM_NUMBER_OF_THREADS, 1, 1);
	const dim3 gridsize(GridXSize, numberOfTemplates, 1);

	naive_custom_normalized_cross_correlation3D << <gridsize, blockSize >> >(dev_result, dev_signal, dev_templates, templateLength, templateChannels, signalLength, signalChannels, dev_signalLowerIndex);
	CheckForError((char*)"naive_custom_normalized_cross_correlation3D");

}

extern "C" void NXCOR_CUDA_3D_Drift(float *dev_result, const float *dev_templates, const float *dev_signal, uint16_t templateLength, uint16_t templateChannels, uint32_t signalLength,
	uint16_t signalChannels, uint16_t numberOfTemplates, uint16_t* dev_signalLowerIndex)
{
	uint32_t GridXSize = signalLength / MAXIMUM_NUMBER_OF_THREADS_DRIFT_HANDLING;

	if (signalLength % MAXIMUM_NUMBER_OF_THREADS_DRIFT_HANDLING != 0)
	{
		GridXSize++;
	}

	const dim3 blockSize(MAXIMUM_NUMBER_OF_THREADS_DRIFT_HANDLING, 1, 1);
	const dim3 gridsize(GridXSize, numberOfTemplates, 1);

	naive_custom_normalized_cross_correlation3D_STD << <gridsize, blockSize >> >(dev_result, dev_signal, dev_templates, templateLength, templateChannels, signalLength, signalChannels, dev_signalLowerIndex);
	CheckForError((char*)"naive_custom_normalized_cross_correlation3D_STD");

}

#endif
