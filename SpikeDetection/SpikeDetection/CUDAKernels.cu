
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

#define MAXIMUM_NUMBER_OF_THREADS						1024
#define MAXIMUM_NUMBER_OF_THREADS_COMPARING				500
#define MAXIMUM_NUMBER_OF_THREADS_DRIFT_HANDLING		1024

__global__ void runChannelFilterGPU(
	float* d_result,
	float* d_intermediateResult,
	float* d_signal,
	float* d_coeffsA,
	float* d_coeffsB,
	uint16_t signalWidth,
	uint32_t signalLength)
{
	// Forward filtering
	//int x = blockIdx.x; // counts the channels (width)
	uint16_t x = threadIdx.x; // counts the channels (width)

	for (int i = 0; i < signalLength; i++)
	{
		uint32_t index = ((i*signalWidth) + x);
		float tmp = 0.f;
		d_intermediateResult[index] = 0.f;
		for (int16_t j = 0; j < (int16_t)NUMBER_OF_B_COEFF; j++)
		{
			// Every second b coefficient is 0.
			if ((i - (j * 2)) < 0) continue;
			tmp += d_coeffsB[j] * d_signal[index - (j * 2)*signalWidth];
		}


		for (int16_t j = 0; j < (int16_t)NUMBER_OF_A_COEFF; j++)
		{
			// The first a coefficient is 1.
			if ((i - (j + 1)) < 0) continue;
			tmp -= d_coeffsA[j] * d_intermediateResult[index - (j + 1)*signalWidth];
		}

		d_intermediateResult[index] = tmp;
	}

	//x = (gridDim.x - 1) - blockIdx.x;
	//x = (blockDim.x - 1) - threadIdx.x;

	// Reverse filtering

	for (int i = signalLength - 1; i >= 0; i--)
	{
		uint32_t index = ((i*signalWidth) + x);
		float tmp = 0.;
		d_result[index] = 0.f;
		for (int16_t j = 0; j < (int16_t)NUMBER_OF_B_COEFF; j++)
		{
			// Every second b coefficient is 0.
			if ((i + (j * 2)) > (signalLength - 1)) continue;
			tmp += d_coeffsB[j] * d_intermediateResult[(index)+(j * 2)*signalWidth];
		}

		for (int16_t j = 0; j < (int16_t)NUMBER_OF_A_COEFF; j++)
		{
			// The first a coefficient is 1.
			if ((i + (j + 1)) > (signalLength - 1)) continue;
			tmp -= d_coeffsA[j] * d_result[(index)+(j + 1)*signalWidth];
		}

		d_result[index] = tmp;
	}
}

__global__ void runChannelFilterForwardGPU(
	float* d_intermediateResult,
	float* d_signal,
	float* d_coeffsA,
	float* d_coeffsB,
	uint16_t signalWidth,
	uint32_t signalLength)
{
	// Forward filtering
	//int x = blockIdx.x; // counts the channels (width)
	uint16_t x = threadIdx.x; // counts the channels (width)

	/*
	for (int i = 0; i < signalLength; i++)
	{
		uint32_t index = ((i*signalWidth) + x);
		d_intermediateResult[index] = 0.f;
	}
	__syncthreads();
	*/

	for (int i = 0; i < signalLength; i++)
	{
		uint32_t index = ((i*signalWidth) + x);
		float tmp = 0.f;
		d_intermediateResult[index] = 0.f;
		for (int16_t j = 0; j < (int16_t)NUMBER_OF_B_COEFF; j++)
		{
			// Every second b coefficient is 0.
			if ((i - (j * 2)) < 0) continue;
			tmp += d_coeffsB[j] * d_signal[index - (j * 2)*signalWidth];
		}


		for (int16_t j = 0; j < (int16_t)NUMBER_OF_A_COEFF; j++)
		{
			// The first a coefficient is 1.
			if ((i - (j + 1)) < 0) continue;
			tmp -= d_coeffsA[j] * d_intermediateResult[index - (j + 1)*signalWidth];
		}

		d_intermediateResult[index] = tmp;
	}
}

__global__ void runChannelFilterReverseGPU(
	float* d_result,
	float* d_intermediateResult,
	float* d_coeffsA,
	float* d_coeffsB,
	uint16_t signalWidth,
	uint32_t signalLength)
{
	// Forward filtering
	//int x = blockIdx.x; // counts the channels (width)
	uint16_t x = threadIdx.x; // counts the channels (width)

	//x = (gridDim.x - 1) - blockIdx.x;
	//x = (blockDim.x - 1) - threadIdx.x;
	// Reverse filtering
	/*
	for (int i = 0; i < signalLength; i++)
	{
		uint32_t index = ((i*signalWidth) + x);
		d_result[index] = 0.f;
	}
	__syncthreads();
	*/

	for (int i = signalLength - 1; i >= 0; i--)
	{
		uint32_t index = ((i*signalWidth) + x);
		float tmp = 0.;
		d_result[index] = 0.f;
		for (int16_t j = 0; j < (int16_t)NUMBER_OF_B_COEFF; j++)
		{
			// Every second b coefficient is 0.
			//if ((i + (j * 2)) > (signalLength - 1)) continue;
			if ((index + (j * 2)*signalWidth) >= (signalLength*signalWidth)) continue;
			tmp += d_coeffsB[j] * d_intermediateResult[index + (j * 2)*signalWidth];
		}

		for (int16_t j = 0; j < (int16_t)NUMBER_OF_A_COEFF; j++)
		{
			// The first a coefficient is 1.
			//if ((i + (j + 1)) > (signalLength - 1)) continue;
			if ((index + (j + 1)*signalWidth) >= (signalLength*signalWidth)) continue;
			tmp -= d_coeffsA[j] * d_result[index + (j + 1)*signalWidth];
		}

		d_result[index] = tmp;
	}
}

__global__ void runFilterReplicateGPU(
	float* d_result,
	const float* d_Signal,
	const float* d_filterKernel,
	uint16_t kernelDim,
	uint32_t signalLength,
	uint16_t signalWidth)
{
	// Perform filtering

	// setup variables
	uint16_t kernelHalfSize = kernelDim / 2;
	uint32_t y = threadIdx.y; // counts the channels (width)
	uint32_t x = threadIdx.x + blockDim.x*blockIdx.x; // counts the number of samples
	float tmpFilterValue = 0;

	if (x < signalLength)
	{
		// If away from border
		if (x >= kernelHalfSize && y >= kernelHalfSize && ((signalLength - 1) - x) >= kernelHalfSize && ((signalWidth - 1) - y) >= kernelHalfSize)
		{
			// for each location apply the filter kernel
			for (uint32_t i = 0; i < kernelDim; i++) // assumes kernel af uneven squared size
			{
				for (uint32_t j = 0; j < kernelDim; j++)
				{
					tmpFilterValue += d_Signal[((((x - 1) + i)*signalWidth) + (y - 1)) + j] * d_filterKernel[j + (i*kernelDim)];
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
				tmpFilterValue += d_Signal[(x*signalWidth) + y] * d_filterKernel[0];
				tmpFilterValue += d_Signal[(x*signalWidth) + y] * d_filterKernel[1];
				tmpFilterValue += d_Signal[(x*signalWidth) + y + 1] * d_filterKernel[2];
				tmpFilterValue += d_Signal[(x*signalWidth) + y] * d_filterKernel[3];
				tmpFilterValue += d_Signal[((x + 1)*signalWidth) + y] * d_filterKernel[6];
				corner = true;
			}

			if (y < kernelHalfSize && ((signalLength - 1) - x) < kernelHalfSize) // corner ⌉
			{
				tmpFilterValue += d_Signal[(x*signalWidth) + y] * d_filterKernel[1];
				tmpFilterValue += d_Signal[(x*signalWidth) + y] * d_filterKernel[2];
				tmpFilterValue += d_Signal[(x*signalWidth) + y] * d_filterKernel[5];
				tmpFilterValue += d_Signal[(x*signalWidth) + (y + 1)] * d_filterKernel[8];
				tmpFilterValue += d_Signal[((x - 1)*signalWidth) + y] * d_filterKernel[0];
				corner = true;
			}

			if (x < kernelHalfSize && ((signalWidth - 1) - y) < kernelHalfSize) // corner ⌊
			{
				tmpFilterValue += d_Signal[(x*signalWidth) + y] * d_filterKernel[3];
				tmpFilterValue += d_Signal[(x*signalWidth) + y] * d_filterKernel[6];
				tmpFilterValue += d_Signal[(x*signalWidth) + y] * d_filterKernel[7];
				tmpFilterValue += d_Signal[(x*signalWidth) + (y - 1)] * d_filterKernel[0];
				tmpFilterValue += d_Signal[((x + 1)*signalWidth) + y] * d_filterKernel[8];
				corner = true;
			}

			if (((signalLength - 1) - x) < kernelHalfSize && ((signalWidth - 1) - y) < kernelHalfSize) // corner ⌋
			{
				tmpFilterValue += d_Signal[(x*signalWidth) + y] * d_filterKernel[5];
				tmpFilterValue += d_Signal[(x*signalWidth) + y] * d_filterKernel[7];
				tmpFilterValue += d_Signal[(x*signalWidth) + y] * d_filterKernel[8];
				tmpFilterValue += d_Signal[(x*signalWidth) + (y - 1)] * d_filterKernel[2];
				tmpFilterValue += d_Signal[((x - 1)*signalWidth) + y] * d_filterKernel[6];
				corner = true;
			}

			if (x < kernelHalfSize)
			{
				extraSubtractI = kernelHalfSize;
				imageStarti = kernelHalfSize;
				imageStartx = kernelHalfSize;

				if (!corner)
				{
					tmpFilterValue += d_Signal[(x*signalWidth) + (y - 1)] * d_filterKernel[0];
					tmpFilterValue += d_Signal[(x*signalWidth) + y] * d_filterKernel[3];
					tmpFilterValue += d_Signal[(x*signalWidth) + (y + 1)] * d_filterKernel[6];
				}

			}

			if (y < kernelHalfSize)
			{
				extraSubtractY = kernelHalfSize;
				imageStartj = kernelHalfSize;
				imageStarty = kernelHalfSize;

				if (!corner)
				{
					tmpFilterValue += d_Signal[((x - 1)* signalWidth) + y] * d_filterKernel[0];
					tmpFilterValue += d_Signal[(x*signalWidth) + y] * d_filterKernel[1];
					tmpFilterValue += d_Signal[((x + 1)* signalWidth) + y] * d_filterKernel[2];
				}
			}

			if (((signalLength - 1) - x) < kernelHalfSize)
			{
				kernelIMax = kernelDim - kernelHalfSize;

				if (!corner)
				{
					tmpFilterValue += d_Signal[(x* signalWidth) + (y - 1)] * d_filterKernel[2];
					tmpFilterValue += d_Signal[(x* signalWidth) + y] * d_filterKernel[5];
					tmpFilterValue += d_Signal[(x* signalWidth) + (y + 1)] * d_filterKernel[8];
				}
			}

			if (((signalWidth - 1) - y) < kernelHalfSize)
			{
				kernelJMax = kernelDim - kernelHalfSize;

				if (!corner)
				{
					tmpFilterValue += d_Signal[((x - 1)* signalWidth) + y] * d_filterKernel[6];
					tmpFilterValue += d_Signal[(x*signalWidth) + y] * d_filterKernel[7];
					tmpFilterValue += d_Signal[((x + 1)* signalWidth) + y] * d_filterKernel[8];
				}
			}

			// for each location apply the filter kernel
			for (uint32_t i = imageStarti; i < kernelIMax; i++) // assumes kernel af uneven squared size
			{
				for (uint32_t j = imageStartj; j < kernelJMax; j++)
				{
					float signalValue = d_Signal[((((imageStartx - 1) + (i - extraSubtractI))*signalWidth) + (imageStarty - 1)) + (j - extraSubtractY)];
					float kernelValue = d_filterKernel[j + (i*kernelDim)];

					tmpFilterValue += d_Signal[((((imageStartx - 1) + (i - extraSubtractI))*signalWidth) + (imageStarty - 1)) + (j - extraSubtractY)] * d_filterKernel[j + (i*kernelDim)];
				}
			}
		}

		d_result[(x*signalWidth) + y] = tmpFilterValue;
	}

}

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


__global__ void naive_GPU_FindValuesAboveThreshold3DPredict(
	char*				d_response,
	const float* 		d_signal,
	const float* 		d_threshold,
	uint32_t            signalLength,
	uint16_t			templateLength
)
{
	uint32_t index = threadIdx.x + (blockDim.x*blockIdx.x);
	uint16_t templateId = blockIdx.y;

	if (index < (signalLength - templateLength))
	{
		if (d_signal[index + (templateId*signalLength)] >= d_threshold[templateId])
		{
			d_response[index + (templateId*signalLength)] = 1;
		}
		else
		{
			d_response[index + (templateId*signalLength)] = 0;
		}
	}

}

__global__ void naive_GPU_FindValuesAboveThreshold3D(
	char*				d_response,
	const float* 				d_signal,
	float 				threshold,
	uint32_t            signalLength,
	uint16_t			templateLength
)
{
	uint32_t index = threadIdx.x + (blockDim.x*blockIdx.x);
	uint16_t templateId = blockIdx.y;

	if (index < (signalLength-templateLength))
	{
		if (d_signal[index + (templateId*signalLength)] >= threshold)
		{
			d_response[index + (templateId*signalLength)] = 1;
		}
		else
		{
			d_response[index + (templateId*signalLength)] = 0;
		}
	}

}

__global__ void naive_GPU_FindPeaks3D(
	const float* 				d_signal,
	char* 				aboveThresholdindicator,
	uint32_t			signalLength,
	uint16_t			templateLength
)
{
	uint32_t index = threadIdx.x + (blockDim.x*blockIdx.x);
	uint16_t templateId = blockIdx.y;

	if (index < (signalLength - templateLength))
	{

		// Assign first and last element first
		if (index > 1 || index < ((signalLength - templateLength) - 1))
		{
			if (aboveThresholdindicator[index + (templateId*signalLength)] > 0)
			{

				if (d_signal[index + (templateId*signalLength)] > d_signal[index + (templateId*signalLength) - 1] && d_signal[index + (templateId*signalLength)] >= d_signal[index + (templateId*signalLength) + 1])
				{
					//numberOfPeaks++;
				}
				else
				{
					aboveThresholdindicator[index + (templateId*signalLength)] = 0;
				}
			}
		}
		else
		{
			if (index < 1)
			{
				if (d_signal[index + (templateId*signalLength)] > d_signal[index + (templateId*signalLength) + 1] && aboveThresholdindicator[index + (templateId*signalLength)] > 0)
				{
					//numberOfPeaks++;
				}
				else
				{
					aboveThresholdindicator[index + (templateId*signalLength)] = 0;
				}
			}

			if (index > ((signalLength - templateLength) - 2))
			{
				if (d_signal[index + (templateId*signalLength)] > d_signal[index + (templateId*signalLength) - 1] && aboveThresholdindicator[index + (templateId*signalLength)] > 0)
				{
					//numberOfPeaks++;
				}
				else
				{
					aboveThresholdindicator[index + (templateId*signalLength)] = 0;
				}
			}
		}
	}
}

__global__ void naive_GPU_MakesFoundTimes3D(
	uint32_t* 			dev_result,
	char* 				aboveThresholdindicator,
	uint32_t			signalLength,
	uint32_t			maxDimOfResult,
	uint32_t*			dev_counter,
	uint16_t			templateLength
)
{

	uint32_t index = threadIdx.x + (blockDim.x*blockIdx.x);
	uint16_t templateId = blockIdx.y;

	if (index < (signalLength - templateLength))
	{
		// Assign first and last element first
		if (aboveThresholdindicator[index + (templateId*signalLength)] > 0)
		{
			register uint32_t i = atomicAdd(&dev_counter[templateId], 1);
			if (i < maxDimOfResult)
			{
				dev_result[i + (templateId*maxDimOfResult)] = index;
			}
		}
	}
}

__global__ void naive_compare_with_truth_table3D(
	uint32_t*		  d_TPCounter,
	uint32_t*         d_truthTable,
	uint32_t* 		  d_estimationTable,
	uint32_t* 		  d_truthTableStartInd,
	uint32_t* 		  d_truthTableStartSize,
	uint32_t*         d_estimationTableSize,
	uint16_t*         d_peakOffset,
	uint32_t		  maxDimOfResult
)
{
	bool TP = false;
	uint32_t offsetSpike = 0;
	uint32_t I = threadIdx.x + (blockIdx.x*blockDim.x); // e.g threadIdx.x = 2, blockIdx.x = 4, blockDim.c = 1024 --> (4*1024)+2 = 4098
	uint16_t templateId = blockIdx.y;

	if (TEMPLATE_CROPPED_LENGTH > ((d_peakOffset[templateId] * 2) + 1))
	{
		offsetSpike = d_peakOffset[templateId];
	}
	else
	{
		offsetSpike = (d_peakOffset[templateId] / 2);
	}


	if (I < d_estimationTableSize[templateId])
	{
		bool timeStampLocated = false;

		for (uint32_t i = d_truthTableStartInd[templateId]; i < (d_truthTableStartInd[templateId] + d_truthTableStartSize[templateId]); i++)
		{		
			if ((d_estimationTable[I + (templateId*maxDimOfResult)] + offsetSpike) == (d_truthTable[i] - 1))
			{
				TP = true;
				timeStampLocated = true;
				break;
			}
		}

		if (!timeStampLocated && ACCEPTED_TIMELINE_SLACK > 0)
		{
			for (uint32_t Y = 1; Y <= ACCEPTED_TIMELINE_SLACK; Y++)
			{
				for (uint32_t i = d_truthTableStartInd[templateId]; i < (d_truthTableStartInd[templateId] + d_truthTableStartSize[templateId]); i++)
				{
					if ((d_estimationTable[I + (templateId*maxDimOfResult)] + offsetSpike) == ((d_truthTable[i] - 1) - Y))
					{
						TP = true;
						timeStampLocated = true;
						break;
					}
				}

				if (timeStampLocated)
				{
					break;
				}

				if (!timeStampLocated)
				{
					for (uint32_t i = d_truthTableStartInd[templateId]; i < (d_truthTableStartInd[templateId] + d_truthTableStartSize[templateId]); i++)
					{
						if ((d_estimationTable[I + (templateId*maxDimOfResult)] + offsetSpike) == ((d_truthTable[i] - 1) + Y))
						{
							TP = true;
							timeStampLocated = true;
							break;
						}
					}
				}

				if (timeStampLocated)
				{
					break;
				}
			}
		}
	}


	if (TP)
	{
		atomicAdd(&d_TPCounter[templateId], 1);
	}
}



extern "C" void PredictCUDA(const float *dev_signal, char *dev_aboveThreshold, uint32_t *dev_foundTimes, uint32_t *dev_foundTimesCounter,
	uint16_t templateLength, uint32_t signalLength, uint16_t numberOfTemplates, float *dev_threshold)
{
	uint32_t GridXSize = signalLength / MAXIMUM_NUMBER_OF_THREADS;

	if (signalLength % MAXIMUM_NUMBER_OF_THREADS != 0)
	{
		GridXSize++;
	}

	const dim3 blockSize(MAXIMUM_NUMBER_OF_THREADS, 1, 1);
	const dim3 gridsize(GridXSize, numberOfTemplates, 1);

	naive_GPU_FindValuesAboveThreshold3DPredict << <gridsize, blockSize >> > (dev_aboveThreshold, dev_signal, dev_threshold, signalLength, templateLength);
	naive_GPU_FindPeaks3D << <gridsize, blockSize >> > (dev_signal, dev_aboveThreshold, signalLength, templateLength);
	naive_GPU_MakesFoundTimes3D << <gridsize, blockSize >> > (dev_foundTimes, dev_aboveThreshold, signalLength, (uint32_t)MAXIMUM_PREDICTION_SAMPLES, dev_foundTimesCounter, templateLength);
}

extern "C" void TrainPart1CUDA(const float *dev_signal, char *dev_aboveThreshold, uint32_t *dev_foundTimes, uint32_t *dev_foundTimesCounter, 
							   uint32_t *dev_TPCounter, uint16_t *dev_peaksOffsets, uint32_t *devTruthTable, uint32_t *devTruthTableSize,
							   uint32_t *devTruthTableStartInd, uint16_t templateLength, uint32_t signalLength, uint16_t numberOfTemplates, float threshold)
{

	uint32_t GridXSize = signalLength / MAXIMUM_NUMBER_OF_THREADS;

	if (signalLength % MAXIMUM_NUMBER_OF_THREADS != 0)
	{
		GridXSize++;
	}

	const dim3 blockSize(MAXIMUM_NUMBER_OF_THREADS, 1, 1);
	const dim3 gridsize(GridXSize, numberOfTemplates, 1);

	naive_GPU_FindValuesAboveThreshold3D << <gridsize, blockSize >> > (dev_aboveThreshold, dev_signal, threshold, signalLength, templateLength);
	naive_GPU_FindPeaks3D << <gridsize, blockSize >> > (dev_signal, dev_aboveThreshold, signalLength, templateLength);
	naive_GPU_MakesFoundTimes3D << <gridsize, blockSize >> > (dev_foundTimes, dev_aboveThreshold, signalLength, (uint32_t)MAXIMUM_PREDICTION_SAMPLES, dev_foundTimesCounter, templateLength);
	
	const dim3 blockSizeCompare(MAXIMUM_NUMBER_OF_THREADS_COMPARING, 1, 1);

	GridXSize = MAXIMUM_PREDICTION_SAMPLES / MAXIMUM_NUMBER_OF_THREADS_COMPARING;
	if (MAXIMUM_PREDICTION_SAMPLES % MAXIMUM_NUMBER_OF_THREADS_COMPARING != 0)
	{
		GridXSize++;
	}
	const dim3 gridsizeCompare(GridXSize, numberOfTemplates, 1);

	naive_compare_with_truth_table3D << <gridsizeCompare, blockSizeCompare >> > (dev_TPCounter, devTruthTable, dev_foundTimes, devTruthTableStartInd, devTruthTableSize, dev_foundTimesCounter, dev_peaksOffsets, (uint32_t)MAXIMUM_PREDICTION_SAMPLES);
	

}

extern "C" void NXCOR_CUDA_3D(float *dev_result, const float *dev_templates, const float *dev_signal, uint16_t templateLength, uint16_t templateChannels, uint32_t signalLength, uint16_t signalChannels, uint16_t numberOfTemplates, uint16_t* dev_signalLowerIndex)
{
	cudaError_t cudaStatus;
	uint32_t GridXSize = signalLength / MAXIMUM_NUMBER_OF_THREADS;

	if (signalLength % MAXIMUM_NUMBER_OF_THREADS != 0)
	{
		GridXSize++;
	}

	const dim3 blockSize(MAXIMUM_NUMBER_OF_THREADS, 1, 1);
	const dim3 gridsize(GridXSize, numberOfTemplates, 1);

	naive_custom_normalized_cross_correlation3D << <gridsize, blockSize >> >(dev_result, dev_signal, dev_templates, templateLength, templateChannels, signalLength, signalChannels, dev_signalLowerIndex);
	cudaDeviceSynchronize();
	cudaStatus = cudaGetLastError();
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "naive_custom_normalized_cross_correlation3D launch failed: %s\n", cudaGetErrorString(cudaStatus));
	}

}

extern "C" void NXCOR_CUDA_3D_Drift(float *dev_result, const float *dev_templates, const float *dev_signal, uint16_t templateLength, uint16_t templateChannels, uint32_t signalLength,
	uint16_t signalChannels, uint16_t numberOfTemplates, uint16_t* dev_signalLowerIndex)
{
	cudaError_t cudaStatus;
	uint32_t GridXSize = signalLength / MAXIMUM_NUMBER_OF_THREADS_DRIFT_HANDLING;

	if (signalLength % MAXIMUM_NUMBER_OF_THREADS_DRIFT_HANDLING != 0)
	{
		GridXSize++;
	}

	const dim3 blockSize(MAXIMUM_NUMBER_OF_THREADS_DRIFT_HANDLING, 1, 1);
	const dim3 gridsize(GridXSize, numberOfTemplates, 1);

	naive_custom_normalized_cross_correlation3D_STD << <gridsize, blockSize >> >(dev_result, dev_signal, dev_templates, templateLength, templateChannels, signalLength, signalChannels, dev_signalLowerIndex);
	cudaDeviceSynchronize();
	cudaStatus = cudaGetLastError();
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "naive_custom_normalized_cross_correlation3D_STD launch failed: %s\n", cudaGetErrorString(cudaStatus));
	}

}


extern "C" void KernelFilterWithCudaV2(const float *dev_kernel, const float *dev_signal, float *dev_result, uint16_t templateChannels, uint16_t kernelDim, uint32_t signalLength)
{
	cudaError_t cudaStatus;
	// Launch a kernel on the GPU with one thread for each element.
	int xBlocks = MAXIMUM_NUMBER_OF_THREADS / templateChannels;
	int xGrids = signalLength / xBlocks;
	const dim3 blockSize(xBlocks, templateChannels, 1);
	
	if (signalLength % xBlocks != 0)
	{
		xGrids++;
	}

	const dim3 gridsize(xGrids, 1, 1);

	runFilterReplicateGPU << <gridsize, blockSize >> >(dev_result, dev_signal, dev_kernel, kernelDim, signalLength, templateChannels);
	cudaDeviceSynchronize();
	cudaStatus = cudaGetLastError();
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "runFilterReplicateGPU launch failed: %s\n", cudaGetErrorString(cudaStatus));
	}
}

extern "C" void ChannelFilterWithCuda(float *dev_result, float *dev_signal, float *dev_resultInt, float* dev_coeffsA, float* dev_coeffsB, uint16_t signalWidth, uint32_t signalLength)
{
	cudaError_t cudaStatus;
	const dim3 blockSize(signalWidth, 1, 1);
	//const dim3 blockSize(1, 1, 1);
	const dim3 gridsize(1, 1, 1);
	//runChannelFilterGPU << <gridsize, blockSize >> >(dev_result, dev_resultInt, dev_signal, dev_coeffsA, dev_coeffsB, signalWidth, signalLength);

	runChannelFilterForwardGPU << <gridsize, blockSize >> >(dev_resultInt, dev_signal, dev_coeffsA, dev_coeffsB, signalWidth, signalLength);
	cudaDeviceSynchronize();
	cudaStatus = cudaGetLastError();
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "runChannelFilterForwardGPU launch failed: %s\n", cudaGetErrorString(cudaStatus));
		return;
	}

	runChannelFilterReverseGPU << <gridsize, blockSize >> >(dev_result, dev_resultInt, dev_coeffsA, dev_coeffsB, signalWidth, signalLength);
	cudaDeviceSynchronize();
	cudaStatus = cudaGetLastError();
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "runChannelFilterReverseGPU launch failed: %s\n", cudaGetErrorString(cudaStatus));
	}
}

extern "C" cudaError_t SelectCUDA_GPU_Unit(void)
{
	cudaError_t cudaStatus;

	// Choose which GPU to run on, change this on a multi-GPU system.
	cudaStatus = cudaSetDevice(0);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaSetDevice failed!  Do you have a CUDA-capable GPU installed?");
	}

	return cudaStatus;
}

extern "C" cudaError_t AllocateCUDAData(float **dev_pointer, uint32_t length, uint32_t width, uint16_t bytesInValue)
{
	cudaError_t cudaStatus;

	cudaStatus = cudaMalloc((void**)dev_pointer, (length*width) * bytesInValue);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMalloc failed!");
	}

	return cudaStatus;
}

extern "C" cudaError_t AllocateCUDADataChar(char **dev_pointer, uint32_t length, uint32_t width, uint16_t bytesInValue)
{
	cudaError_t cudaStatus;

	cudaStatus = cudaMalloc((void**)dev_pointer, (length*width) * bytesInValue);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMalloc failed!");
	}

	return cudaStatus;
}

extern "C" cudaError_t AllocateCUDADataU16(uint16_t **dev_pointer, uint32_t length, uint32_t width, uint16_t bytesInValue)
{
	cudaError_t cudaStatus;

	cudaStatus = cudaMalloc((void**)dev_pointer, (length*width) * bytesInValue);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMalloc failed!");
	}

	return cudaStatus;
}

extern "C" cudaError_t AllocateCUDADataU32(uint32_t **dev_pointer, uint32_t length, uint32_t width, uint16_t bytesInValue)
{
	cudaError_t cudaStatus;

	cudaStatus = cudaMalloc((void**)dev_pointer, (length*width) * bytesInValue);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMalloc failed!");
	}

	return cudaStatus;
}

extern "C" cudaError_t MemCpyCUDAData(float *dev_pointer, float *host_pointer, uint32_t length, uint32_t width, uint16_t bytesInValue)
{
	cudaError_t cudaStatus;

	// Copy input vectors from host memory to GPU buffers.
	cudaStatus = cudaMemcpy(dev_pointer, host_pointer, ((length*width) * bytesInValue), cudaMemcpyHostToDevice);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMemcpy to device failed!");
	}

	return cudaStatus;
}

extern "C" cudaError_t MemCpyCUDADataU16(uint16_t *dev_pointer, uint16_t *host_pointer, uint32_t length, uint32_t width, uint16_t bytesInValue)
{
	cudaError_t cudaStatus;

	// Copy input vectors from host memory to GPU buffers.
	cudaStatus = cudaMemcpy(dev_pointer, host_pointer, ((length*width) * bytesInValue), cudaMemcpyHostToDevice);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMemcpy to device failed!");
	}

	return cudaStatus;
}

extern "C" cudaError_t MemCpyCUDADataU32(uint32_t *dev_pointer, uint32_t *host_pointer, uint32_t length, uint32_t width, uint16_t bytesInValue)
{
	cudaError_t cudaStatus;

	// Copy input vectors from host memory to GPU buffers.
	cudaStatus = cudaMemcpy(dev_pointer, host_pointer, ((length*width) * bytesInValue), cudaMemcpyHostToDevice);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMemcpy to device failed!");
	}

	return cudaStatus;
}

extern "C" cudaError_t RetreiveResults(float *dev_result, float *result, uint32_t length, uint32_t width, uint16_t bytesInValue)
{
	cudaError_t cudaStatus;
	// Copy output vector from GPU buffer to host memory.
	cudaStatus = cudaMemcpy(result, dev_result, (width*length) * bytesInValue, cudaMemcpyDeviceToHost);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMemcpy to host failed!");
	}

	return cudaStatus;
}

extern "C" cudaError_t RetreiveResultsU32(uint32_t *dev_result, uint32_t *result, uint32_t length, uint32_t width, uint16_t bytesInValue)
{
	cudaError_t cudaStatus;
	// Copy output vector from GPU buffer to host memory.
	cudaStatus = cudaMemcpy(result, dev_result, (width*length) * bytesInValue, cudaMemcpyDeviceToHost);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMemcpy to host failed!");
	}

	return cudaStatus;
}

extern "C" cudaError_t CheckForCudaError(void)
{
	cudaError_t cudaStatus;
	// Check for any errors launching the kernel
	cudaStatus = cudaGetLastError();
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "addKernel launch failed: %s\n", cudaGetErrorString(cudaStatus));
		return cudaStatus;
	}

	// cudaDeviceSynchronize waits for the kernel to finish, and returns
	// any errors encountered during the launch.
	cudaStatus = cudaDeviceSynchronize();
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaDeviceSynchronize returned error code %d after launching kernel!\n", cudaStatus);
		return cudaStatus;
	}

	return cudaStatus;
}

extern "C" void CleanUpCudaForSpikeDet(float *dev_kernel)
{
	cudaFree(dev_kernel);
}

extern "C" void CleanUpCudaForSpikeDetU16(uint16_t *dev_kernel)
{
	cudaFree(dev_kernel);
}

extern "C" void CleanUpCudaForSpikeDetU32(uint32_t *dev_kernel)
{
	cudaFree(dev_kernel);
}

extern "C" void CleanUpCudaForSpikeDetChar(char *dev_kernel)
{
	cudaFree(dev_kernel);
}

#endif