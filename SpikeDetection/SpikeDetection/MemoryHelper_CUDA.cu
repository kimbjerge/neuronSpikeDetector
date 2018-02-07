
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

extern "C" cudaError_t CheckForError(char * str)
{
	cudaError_t cudaStatus;
	// Check for any errors launching the kernel
	cudaStatus = cudaGetLastError();
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "%s launch failed: %s\n", str, cudaGetErrorString(cudaStatus));
	}
	cudaStatus = cudaDeviceSynchronize();
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaDeviceSynchronize returned error code %d after launching %s!\n", cudaStatus, str);
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
