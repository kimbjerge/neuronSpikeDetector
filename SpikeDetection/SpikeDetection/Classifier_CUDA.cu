
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
	CheckForError((char*)"naive_GPU_FindValuesAboveThreshold3DPredict");
	naive_GPU_FindPeaks3D << <gridsize, blockSize >> > (dev_signal, dev_aboveThreshold, signalLength, templateLength);
	CheckForError((char*)"naive_GPU_FindPeaks3D");
	naive_GPU_MakesFoundTimes3D << <gridsize, blockSize >> > (dev_foundTimes, dev_aboveThreshold, signalLength, (uint32_t)MAXIMUM_PREDICTION_SAMPLES, dev_foundTimesCounter, templateLength);
	CheckForError((char*)"naive_GPU_MakesFoundTimes3D");
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
	CheckForError((char*)"naive_GPU_FindValuesAboveThreshold3D");
	naive_GPU_FindPeaks3D << <gridsize, blockSize >> > (dev_signal, dev_aboveThreshold, signalLength, templateLength);
	CheckForError((char*)"naive_GPU_FindPeaks3D");
	naive_GPU_MakesFoundTimes3D << <gridsize, blockSize >> > (dev_foundTimes, dev_aboveThreshold, signalLength, (uint32_t)MAXIMUM_PREDICTION_SAMPLES, dev_foundTimesCounter, templateLength);
	CheckForError((char*)"naive_GPU_MakesFoundTimes3D");

	const dim3 blockSizeCompare(MAXIMUM_NUMBER_OF_THREADS_COMPARING, 1, 1);

	GridXSize = MAXIMUM_PREDICTION_SAMPLES / MAXIMUM_NUMBER_OF_THREADS_COMPARING;
	if (MAXIMUM_PREDICTION_SAMPLES % MAXIMUM_NUMBER_OF_THREADS_COMPARING != 0)
	{
		GridXSize++;
	}
	const dim3 gridsizeCompare(GridXSize, numberOfTemplates, 1);

	naive_compare_with_truth_table3D << <gridsizeCompare, blockSizeCompare >> > (dev_TPCounter, devTruthTable, dev_foundTimes, devTruthTableStartInd, devTruthTableSize, dev_foundTimesCounter, dev_peaksOffsets, (uint32_t)MAXIMUM_PREDICTION_SAMPLES);
	CheckForError((char*)"naive_compare_with_truth_table3D");

}

#endif
