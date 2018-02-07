
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
					//float signalValue = d_Signal[((((imageStartx - 1) + (i - extraSubtractI))*signalWidth) + (imageStarty - 1)) + (j - extraSubtractY)];
					//float kernelValue = d_filterKernel[j + (i*kernelDim)];

					tmpFilterValue += d_Signal[((((imageStartx - 1) + (i - extraSubtractI))*signalWidth) + (imageStarty - 1)) + (j - extraSubtractY)] * d_filterKernel[j + (i*kernelDim)];
				}
			}
		}

		d_result[(x*signalWidth) + y] = tmpFilterValue;
	}

}


extern "C" void KernelFilterWithCudaV2(const float *dev_kernel, const float *dev_signal, float *dev_result, uint16_t templateChannels, uint16_t kernelDim, uint32_t signalLength)
{
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
	CheckForError((char *)"runFilterReplicateGPU");

}

#endif
