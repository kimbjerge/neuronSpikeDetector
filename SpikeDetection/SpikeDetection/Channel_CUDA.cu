
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
			//if ((index + (j * 2)*signalWidth) >= (signalLength*signalWidth)) continue;
			tmp += d_coeffsB[j] * d_intermediateResult[(index)+(j * 2)*signalWidth];
		}

		for (int16_t j = 0; j < (int16_t)NUMBER_OF_A_COEFF; j++)
		{
			// The first a coefficient is 1.
			if ((i + (j + 1)) > (signalLength - 1)) continue;
			//if ((index + (j + 1)*signalWidth) >= (signalLength*signalWidth)) continue;
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
	uint16_t x = threadIdx.x; // counts the channels (width)
	//int32_t signalSize = signalWidth * signalLength;
	
	for (int i = 0; i < signalLength; i++)
	{
		int32_t index = ((i*signalWidth) + x);
		float tmp = 0.f;
		//d_intermediateResult[index] = 0.f;

		for (int16_t j = 0; j < (int16_t)NUMBER_OF_B_COEFF; j++)
		{
			int32_t currIdx = (index - (j * 2)*signalWidth);
			// Every second b coefficient is 0.
			if (currIdx >= 0) 
				tmp += d_coeffsB[j] * d_signal[currIdx];
		}

		for (int16_t j = 0; j < (int16_t)NUMBER_OF_A_COEFF; j++)
		{
			int32_t currIdx = (index - (j + 1)*signalWidth);
			// The first a coefficient is 1.
			if (currIdx >= 0) 
 				tmp -= d_coeffsA[j] * d_intermediateResult[currIdx];
		}

		d_intermediateResult[index] = tmp;
		//__syncthreads();
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
	// Reverse filtering
	uint16_t x = threadIdx.x; // counts the channels (width)
	int32_t signalSize = signalWidth * signalLength;

	for (int i = signalLength - 1; i >= 0; i--)
	{
		int32_t index = ((i*signalWidth) + x);
		float tmp = 0.;
		//d_result[index] = 0.f;

		for (int16_t j = 0; j < (int16_t)NUMBER_OF_B_COEFF; j++)
		{
			int32_t currIdx = index + (j * 2)*signalWidth;
			// Every second b coefficient is 0.
			if (currIdx < signalSize)
  				tmp += d_coeffsB[j] * d_intermediateResult[currIdx];
		}

		for (int16_t j = 0; j < (int16_t)NUMBER_OF_A_COEFF; j++)
		{
			int32_t currIdx = index + (j + 1)*signalWidth;
			// The first a coefficient is 1.
			if (currIdx < signalSize)
  				tmp -= d_coeffsA[j] * d_result[currIdx];
		}

		d_result[index] = tmp;
		//__syncthreads();
	}
}

extern "C" void ChannelFilterWithCuda(float *dev_result, float *dev_signal, float *dev_resultInt, float* dev_coeffsA, float* dev_coeffsB, uint16_t signalWidth, uint32_t signalLength)
{
	const dim3 blockSize(signalWidth, 1, 1);
	//const dim3 blockSize(1, 1, 1);
	const dim3 gridsize(1, 1, 1);

	//CheckForError((char*)"ChannelFilterWithCuda");
	//runChannelFilterGPU << <gridsize, blockSize >> >(dev_result, dev_resultInt, dev_signal, dev_coeffsA, dev_coeffsB, signalWidth, signalLength);
	//CheckForError("runChannelFilterGPU");

	runChannelFilterForwardGPU << <gridsize, blockSize >> >(dev_resultInt, dev_signal, dev_coeffsA, dev_coeffsB, signalWidth, signalLength);
	CheckForError((char*)"runChannelFilterForwardGPU");
	
	runChannelFilterReverseGPU << <gridsize, blockSize >> >(dev_result, dev_resultInt, dev_coeffsA, dev_coeffsB, signalWidth, signalLength);
	CheckForError((char*)"runChannelFilterReverseGPU");
	
}

#endif
