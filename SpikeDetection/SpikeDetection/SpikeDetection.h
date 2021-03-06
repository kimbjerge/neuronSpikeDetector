///////////////////////////////////////////////////////////
//  SpikeDetection.h
//  Header:          Spike Detection Class
//  Created on:      15-11-2017
//  Original author: MB
///////////////////////////////////////////////////////////
#ifndef SPIKE_DETECTION_H
#define SPIKE_DETECTION_H

#include <cstdio>
#include <iostream>
#include <conio.h>

#include "DataLoader.h"
#include "NXCOR.h"
#include "KernelFilter.h"
#include "TemplateController.h"
#include "TemplateHandler.h"
#include "TTClassifier.h"
#include "ProjectInfo.h"
#include "ChannelFilter.h"
#include "NXCORController.h"
#include "ClassifierController.h"
#include "ProjectDefinitions.h"		

using namespace std::chrono;

#ifdef USE_CUDA
	extern "C" cudaError_t SelectCUDA_GPU_Unit(void);
	extern "C" cudaError_t AllocateCUDAData(float **dev_pointer, uint32_t length, uint32_t width, uint16_t bytesInValue);
	extern "C" cudaError_t AllocateCUDADataChar(char **dev_pointer, uint32_t length, uint32_t width, uint16_t bytesInValue);
	extern "C" cudaError_t AllocateCUDADataU16(uint16_t **dev_pointer, uint32_t length, uint32_t width, uint16_t bytesInValue);
	extern "C" cudaError_t AllocateCUDADataU32(uint32_t **dev_pointer, uint32_t length, uint32_t width, uint16_t bytesInValue);
	extern "C" cudaError_t MemCpyCUDAData(float *dev_pointer, float *host_pointer, uint32_t length, uint32_t width, uint16_t bytesInValue);
	extern "C" cudaError_t MemCpyCUDADataU16(uint16_t *dev_pointer, uint16_t *host_pointer, uint32_t length, uint32_t width, uint16_t bytesInValue);
	extern "C" cudaError_t MemCpyCUDADataU32(uint32_t *dev_pointer, uint32_t *host_pointer, uint32_t length, uint32_t width, uint16_t bytesInValue);
	extern "C" cudaError_t CheckForCudaError(void);
	extern "C" cudaError_t RetreiveResults(float *dev_result, float *result, uint32_t length, uint32_t width, uint16_t bytesInValue);
	extern "C" cudaError_t RetreiveResultsU32(uint32_t *dev_result, uint32_t *result, uint32_t length, uint32_t width, uint16_t bytesInValue);
	extern "C" void CleanUpCudaForSpikeDet(float *dev_Pointer);
	extern "C" void CleanUpCudaForSpikeDetU16(uint16_t *dev_kernel);
	extern "C" void CleanUpCudaForSpikeDetU32(uint32_t *dev_kernel);
	extern "C" void CleanUpCudaForSpikeDetChar(char *dev_kernel);
#endif

template <class T>
class SpikeDetection
{
public:
	/* Constructor */
	SpikeDetection();
	/* Methods */
	//cudaError_t runTrainingCUDA(void);
	void runTraining(void);
	void runPrediction(void);
	/* Helper functions */
	float getLatestExecutionTime(void);
private:
#ifdef USE_CUDA
	cudaError_t prepareCUDATraining(void);
	cudaError_t prepareCUDAPrediction(void);
	void CUDACleanUpTraining(void);
	void CUDACleanUpPrediction(void);
#endif

	KernelFilter<T> kernelFilter;
	ProjectInfo projectInfo; 
	TemplateController<T> templateController; 
	ChannelFilter<T> channelFilter;
	NXCORController<T> nxcorController;
	ClassifierController<T> classifierController;

	/* Helper variables */
	high_resolution_clock::time_point t1;
	high_resolution_clock::time_point t2;
	float f_latestExecutionTime = 0;
#ifdef USE_CUDA
	float *dev_DataPointer;
	float *dev_interMfilteredDataPointer;
	float *dev_kernelFilterCoeff;
	float *dev_ChannelFilterCoeffA;
	float *dev_ChannelFilterCoeffB;
	float *dev_templates;
	float *dev_NXCOROutput;
	uint16_t *dev_lowerChannelIndex;
	char *dev_aboveThresholdIndicator;
	uint32_t *dev_TPCounter;
	uint32_t *dev_FoundTimesCounter;
	uint32_t *dev_FoundTimes;
	uint16_t *dev_spikesPeakOffset;
	uint32_t *dev_grundTruth;
	uint32_t *dev_grundTruthSizes;
	uint32_t *dev_grundTruthStartInd;


	float *dev_DataPointerP;
	float *dev_interMfilteredDataPointerP;
	float *dev_kernelFilterCoeffP;
	float *dev_ChannelFilterCoeffAP;
	float *dev_ChannelFilterCoeffBP;
	float *dev_templatesP;
	float *dev_NXCOROutputP;
	uint16_t *dev_lowerChannelIndexP;
	char *dev_aboveThresholdIndicatorP;
	uint32_t *dev_FoundTimesCounterP;
	uint32_t *dev_FoundTimesP;
	uint16_t *dev_spikesPeakOffsetP;
	float *dev_thresholdsP;
	

#endif
};

/*----------------------------------------------------------------------------*/
/**
* @brief Constructor
* @note Empty!
*/
template <class T>
SpikeDetection<T>::SpikeDetection() :
	kernelFilter(DATA_CHANNELS, TRAINING_DATA_LENGTH),
	projectInfo(PATH_TO_CONFIG_FILE, CONFIG_FILE_LENGTH),
	templateController(&projectInfo, &kernelFilter),
	nxcorController(&projectInfo, &templateController),
	classifierController(&projectInfo)
{
	f_latestExecutionTime = projectInfo.getLatestExecutionTime();
}

/*----------------------------------------------------------------------------*/
/**
* @brief Return the latest execution for either of the algorithms
*
* @retval float : The execution time in microseconds (us)
*/
template <class T>
float SpikeDetection<T>::getLatestExecutionTime(void)
{
	return f_latestExecutionTime;
}

/*----------------------------------------------------------------------------*/
/**
* @brief The training of the model, reduced memory usage version
*
* @retval void : none
*/
/* KBE??? - not used yet!! */
#if 0
template <class T>
cudaError_t SpikeDetection<T>::runTrainingCUDA(void)
{
	cudaError_t cudaStatus;

#ifdef USE_CUDA
	
	t1 = high_resolution_clock::now();

	//************************************************ Channel filtering **************************************************************************************************

	// Allocate Buffer for data 
	cudaStatus = AllocateCUDAData(&dev_DataPointer, (uint32_t)TRAINING_DATA_LENGTH, (uint32_t)DATA_CHANNELS, (uint16_t)sizeof(USED_DATATYPE));
	if (cudaStatus != cudaSuccess) return cudaStatus;

	// Allocate Temporary filtered Result Buffer for raw data 
	cudaStatus = AllocateCUDAData(&dev_interMfilteredDataPointer, (uint32_t)TRAINING_DATA_LENGTH, (uint32_t)DATA_CHANNELS, (uint16_t)sizeof(USED_DATATYPE));
	if (cudaStatus != cudaSuccess) return cudaStatus;

	// Allocate Space for channel filter A coeff. 
	cudaStatus = AllocateCUDAData(&dev_ChannelFilterCoeffA, (uint32_t)NUMBER_OF_A_COEFF, (uint32_t)1, (uint16_t)sizeof(USED_DATATYPE));
	if (cudaStatus != cudaSuccess) return cudaStatus;

	// Allocate Space for channel filter B coeff. 
	cudaStatus = AllocateCUDAData(&dev_ChannelFilterCoeffB, (uint32_t)NUMBER_OF_B_COEFF, (uint32_t)1, (uint16_t)sizeof(USED_DATATYPE));
	if (cudaStatus != cudaSuccess) return cudaStatus;

	// Memory copy raw data to GPU
	cudaStatus = MemCpyCUDAData(dev_DataPointer, projectInfo.getTraningData(), (uint32_t)TRAINING_DATA_LENGTH, (uint32_t)DATA_CHANNELS, (uint16_t)sizeof(USED_DATATYPE));
	if (cudaStatus != cudaSuccess) return cudaStatus;

	// Memory copy Kernel filter coeff to data 
	cudaStatus = MemCpyCUDAData(dev_ChannelFilterCoeffA, channelFilter.getFilterCoeffsA(), (uint32_t)NUMBER_OF_A_COEFF, (uint32_t)1, (uint16_t)sizeof(USED_DATATYPE));
	if (cudaStatus != cudaSuccess) return cudaStatus;

	// Memory copy Kernel filter coeff to data 
	cudaStatus = MemCpyCUDAData(dev_ChannelFilterCoeffB, channelFilter.getFilterCoeffsB(), (uint32_t)NUMBER_OF_B_COEFF, (uint32_t)1, (uint16_t)sizeof(USED_DATATYPE));
	if (cudaStatus != cudaSuccess) return cudaStatus;

	channelFilter.runFilterCUDA(dev_DataPointer, dev_DataPointer, dev_interMfilteredDataPointer, dev_ChannelFilterCoeffA, dev_ChannelFilterCoeffB);
	
	CleanUpCudaForSpikeDet(dev_ChannelFilterCoeffA);
	CleanUpCudaForSpikeDet(dev_ChannelFilterCoeffB);

#ifdef PRINT_OUTPUT_INFO
	std::cout << "CUDA Channel Filter Completed" << std::endl;
#endif

	//************************************************ Kernel filtering ***************************************************************************************************

	// Allocate Space for kernel filter coeff. 
	cudaStatus = AllocateCUDAData(&dev_kernelFilterCoeff, (uint32_t)DEFAULT_KERNEL_DIM, (uint32_t)DEFAULT_KERNEL_DIM, (uint16_t)sizeof(USED_DATATYPE));
	if (cudaStatus != cudaSuccess) return cudaStatus;

	// Memory copy Kernel filter coeff to data 
	cudaStatus = MemCpyCUDAData(dev_kernelFilterCoeff, kernelFilter.getKernelFilterCoeff(), (uint32_t)DEFAULT_KERNEL_DIM, (uint32_t)DEFAULT_KERNEL_DIM, (uint16_t)sizeof(USED_DATATYPE));
	if (cudaStatus != cudaSuccess) return cudaStatus;

	kernelFilter.runFilterReplicateCUDA(dev_interMfilteredDataPointer, dev_DataPointer, dev_kernelFilterCoeff, DEFAULT_KERNEL_DIM, TRAINING_DATA_LENGTH, DATA_CHANNELS);

	//CleanUpCudaForSpikeDet(dev_kernelFilterCoeff);
	//CleanUpCudaForSpikeDet(dev_DataPointer);

#ifdef PRINT_OUTPUT_INFO
	std::cout << "CUDA Kernel Filter Completed" << std::endl;
#endif

	//************************************************ NXCOR Template Matching **********************************************************************************************

	// Allocate Space for NXCOR Output 
	cudaStatus = AllocateCUDAData(&dev_NXCOROutput, (uint32_t)TRAINING_DATA_LENGTH, (uint32_t)MAXIMUM_NUMBER_OF_TEMPLATES, (uint16_t)sizeof(USED_DATATYPE));
	if (cudaStatus != cudaSuccess) return cudaStatus;

	// Allocate Space for Templates 
	cudaStatus = AllocateCUDAData(&dev_templates, (uint32_t)TEMPLATE_CROPPED_LENGTH*TEMPLATE_CROPPED_WIDTH, (uint32_t)MAXIMUM_NUMBER_OF_TEMPLATES, (uint16_t)sizeof(USED_DATATYPE));
	if (cudaStatus != cudaSuccess) return cudaStatus;

	// Memory copy filterTemplates to GPU 
	cudaStatus = MemCpyCUDAData(dev_templates, templateController.getAllCroppedTemplates(), (uint32_t)TEMPLATE_CROPPED_LENGTH*TEMPLATE_CROPPED_WIDTH, (uint32_t)MAXIMUM_NUMBER_OF_TEMPLATES, (uint16_t)sizeof(USED_DATATYPE));
	if (cudaStatus != cudaSuccess) return cudaStatus;

	nxcorController.performNXCORWithTemplatesCUDA(dev_NXCOROutput, dev_templates, dev_interMfilteredDataPointer, (uint16_t)TEMPLATE_CROPPED_LENGTH, (uint16_t)TEMPLATE_CROPPED_WIDTH, TRAINING_DATA_LENGTH, DATA_CHANNELS, MAXIMUM_NUMBER_OF_TEMPLATES, dev_lowerChannelIndex);

	CleanUpCudaForSpikeDet(dev_kernelFilterCoeff);
	CleanUpCudaForSpikeDet(dev_DataPointer);
	CleanUpCudaForSpikeDet(dev_templates);
	CleanUpCudaForSpikeDet(dev_interMfilteredDataPointer);

#ifdef PRINT_OUTPUT_INFO
	std::cout << "CUDA Template Matching Completed" << std::endl;
#endif

	//************************************************ Training Threshold ***********************************************************************************************

	// Allocate Space lower channel index 
	cudaStatus = AllocateCUDADataU16(&dev_lowerChannelIndex, (uint32_t)MAXIMUM_NUMBER_OF_TEMPLATES, (uint32_t)1, (uint16_t)sizeof(uint16_t));
	if (cudaStatus != cudaSuccess) return cudaStatus;

	// Allocate Space For TP counts 
	cudaStatus = AllocateCUDADataU32(&dev_TPCounter, (uint32_t)MAXIMUM_NUMBER_OF_TEMPLATES, (uint32_t)NUMBER_OF_THRESHOLDS_TO_TEST, (uint16_t)sizeof(uint32_t));
	if (cudaStatus != cudaSuccess) return cudaStatus;

	// Allocate Space For spike detection counts 
	cudaStatus = AllocateCUDADataU32(&dev_FoundTimesCounter, (uint32_t)MAXIMUM_NUMBER_OF_TEMPLATES, (uint32_t)NUMBER_OF_THRESHOLDS_TO_TEST, (uint16_t)sizeof(uint32_t));
	if (cudaStatus != cudaSuccess) return cudaStatus;

	// Allocate Space for threshold indication 
	cudaStatus = AllocateCUDADataChar(&dev_aboveThresholdIndicator, (uint32_t)TRAINING_DATA_LENGTH, (uint32_t)MAXIMUM_NUMBER_OF_TEMPLATES, (uint16_t)sizeof(char));
	if (cudaStatus != cudaSuccess) return cudaStatus;

	// Allocate Space For spike detection counts 
	cudaStatus = AllocateCUDADataU32(&dev_FoundTimes, (uint32_t)MAXIMUM_NUMBER_OF_TEMPLATES, (uint32_t)MAXIMUM_PREDICTION_SAMPLES, (uint16_t)sizeof(uint32_t));
	if (cudaStatus != cudaSuccess) return cudaStatus;

	// Allocate Space for peak offsets 
	cudaStatus = AllocateCUDADataU16(&dev_spikesPeakOffset, (uint32_t)MAXIMUM_NUMBER_OF_TEMPLATES, (uint32_t)1, (uint16_t)sizeof(uint16_t));
	if (cudaStatus != cudaSuccess) return cudaStatus;

	// Allocate Space For grund truth to compare against 
	cudaStatus = AllocateCUDADataU32(&dev_grundTruth, (uint32_t)projectInfo.getNumberTotalTruthTableSize(), (uint32_t)1, (uint16_t)sizeof(uint32_t));
	if (cudaStatus != cudaSuccess) return cudaStatus;

	// Allocate Space For grund truth sizes 
	cudaStatus = AllocateCUDADataU32(&dev_grundTruthSizes, (uint32_t)MAXIMUM_NUMBER_OF_TEMPLATES, (uint32_t)1, (uint16_t)sizeof(uint32_t));
	if (cudaStatus != cudaSuccess) return cudaStatus;

	// Allocate Space For grund truth start indencis 
	cudaStatus = AllocateCUDADataU32(&dev_grundTruthStartInd, (uint32_t)MAXIMUM_NUMBER_OF_TEMPLATES, (uint32_t)1, (uint16_t)sizeof(uint32_t));
	if (cudaStatus != cudaSuccess) return cudaStatus;

	// Memory copy lower index channel number to GPU 
	cudaStatus = MemCpyCUDADataU16(dev_lowerChannelIndex, templateController.getAllTemplatesLowerIndex(), (uint32_t)MAXIMUM_NUMBER_OF_TEMPLATES, (uint32_t)1, (uint16_t)sizeof(uint16_t));
	if (cudaStatus != cudaSuccess) return cudaStatus;

	// Memory copy TP counter to GPU - zero init. 
	uint32_t myArray[(uint32_t)MAXIMUM_NUMBER_OF_TEMPLATES*(uint32_t)NUMBER_OF_THRESHOLDS_TO_TEST] = { 0 };
	cudaStatus = MemCpyCUDADataU32(dev_TPCounter, myArray, (uint32_t)MAXIMUM_NUMBER_OF_TEMPLATES, (uint32_t)NUMBER_OF_THRESHOLDS_TO_TEST, (uint16_t)sizeof(uint32_t));
	if (cudaStatus != cudaSuccess) return cudaStatus;

	// Memory copy Found times counter to GPU - zero init. 
	cudaStatus = MemCpyCUDADataU32(dev_FoundTimesCounter, myArray, (uint32_t)MAXIMUM_NUMBER_OF_TEMPLATES, (uint32_t)NUMBER_OF_THRESHOLDS_TO_TEST, (uint16_t)sizeof(uint32_t));
	if (cudaStatus != cudaSuccess) return cudaStatus;

	// Memory copy templates peaks offsets to GPU 
	cudaStatus = MemCpyCUDADataU16(dev_spikesPeakOffset, templateController.getAllTemplatesPeaksOffset(), (uint32_t)MAXIMUM_NUMBER_OF_TEMPLATES, (uint32_t)1, (uint16_t)sizeof(uint16_t));
	if (cudaStatus != cudaSuccess) return cudaStatus;

	// Memory copy truth table to GPU 
	cudaStatus = MemCpyCUDADataU32(dev_grundTruth, projectInfo.getTruthTableCombined(), (uint32_t)projectInfo.getNumberTotalTruthTableSize(), (uint32_t)1, (uint16_t)sizeof(uint32_t));
	if (cudaStatus != cudaSuccess) return cudaStatus;

	// Memory copy truth table sizes to the GPU 
	cudaStatus = MemCpyCUDADataU32(dev_grundTruthSizes, projectInfo.getTruthTableSizes(), (uint32_t)MAXIMUM_NUMBER_OF_TEMPLATES, (uint32_t)1, (uint16_t)sizeof(uint32_t));
	if (cudaStatus != cudaSuccess) return cudaStatus;

	// Memory copy truth table start indecis to the GPU 
	cudaStatus = MemCpyCUDADataU32(dev_grundTruthStartInd, projectInfo.getTruthTableStartIndencis(), (uint32_t)MAXIMUM_NUMBER_OF_TEMPLATES, (uint32_t)1, (uint16_t)sizeof(uint32_t));
	if (cudaStatus != cudaSuccess) return cudaStatus;

	// Perform classification part 1 on GPU
	classifierController.performTrainingBasedOnTemplatesPart1_CUDA(dev_NXCOROutput, dev_aboveThresholdIndicator, dev_FoundTimes, dev_FoundTimesCounter, dev_TPCounter, dev_spikesPeakOffset,
		dev_grundTruth, dev_grundTruthSizes, dev_grundTruthStartInd);
	
	if (CheckForCudaError() != cudaError_t::cudaSuccess)
	{
		std::cout << "CUDA Error launching or synchronizing, processing stopped" << std::endl;
		return CheckForCudaError();
    }

	uint32_t host_FoundTimesCounters[(uint32_t)MAXIMUM_NUMBER_OF_TEMPLATES*NUMBER_OF_THRESHOLDS_TO_TEST];
	if (RetreiveResultsU32(dev_FoundTimesCounter, host_FoundTimesCounters, (uint32_t)MAXIMUM_NUMBER_OF_TEMPLATES, (uint32_t)NUMBER_OF_THRESHOLDS_TO_TEST, (uint16_t)sizeof(uint32_t)) != cudaError_t::cudaSuccess)
	{
		std::cout << "CUDA Error fetching found times" << std::endl;
		return CheckForCudaError();
	}

	uint32_t host_TPCounters[(uint32_t)MAXIMUM_NUMBER_OF_TEMPLATES*NUMBER_OF_THRESHOLDS_TO_TEST];
	if (RetreiveResultsU32(dev_TPCounter, host_TPCounters, (uint32_t)MAXIMUM_NUMBER_OF_TEMPLATES, (uint32_t)NUMBER_OF_THRESHOLDS_TO_TEST, (uint16_t)sizeof(uint32_t)) != cudaError_t::cudaSuccess)
	{
		std::cout << "CUDA Error fetching TP counters" << std::endl;
		return CheckForCudaError();
	}

	CleanUpCudaForSpikeDet(dev_NXCOROutput);
	CleanUpCudaForSpikeDetU16(dev_lowerChannelIndex);
	CleanUpCudaForSpikeDetChar(dev_aboveThresholdIndicator);
	CleanUpCudaForSpikeDetU32(dev_FoundTimes);
	CleanUpCudaForSpikeDetU16(dev_spikesPeakOffset);
	CleanUpCudaForSpikeDetU32(dev_grundTruth);
	CleanUpCudaForSpikeDetU32(dev_grundTruthSizes);
	CleanUpCudaForSpikeDetU32(dev_grundTruthStartInd);

#ifdef PRINT_OUTPUT_INFO
	std::cout << "CUDA Training Part 1 Completed" << std::endl;
#endif

	// Perform classification part 2 on CPU
	classifierController.performTrainingBasedOnTemplatesPart2(host_TPCounters, host_FoundTimesCounters);

	CleanUpCudaForSpikeDetU32(dev_TPCounter);
	CleanUpCudaForSpikeDetU32(dev_FoundTimesCounter);

	t2 = high_resolution_clock::now();
	auto duration = duration_cast<microseconds>(t2 - t1).count();
	f_latestExecutionTime = (float)duration;

#ifdef PRINT_OUTPUT_INFO
	std::cout << "Total CUDA Training time: " << f_latestExecutionTime / 1000 << " ms. processing " << TRAINING_DATA_TIME << " seconds of data" << std::endl;
#endif

#endif
	return cudaStatus;
}

#endif

/*----------------------------------------------------------------------------*/
/**
* @brief The training of the model.
*
* @retval void : none
*/
template <class T>
void SpikeDetection<T>::runTraining(void)
{
	std::cout << "************* TRAINING **************" << std::endl;
#ifdef USE_CUDA
	if (prepareCUDATraining() != cudaError_t::cudaSuccess)
	{
		CUDACleanUpTraining();
		std::cout << "CUDA Error, processing stopped" << std::endl;
		return;
	}
#endif

	t1 = high_resolution_clock::now();

	/**** 1D Filter ****/
#ifdef USE_CUDA 
	channelFilter.runFilterCUDA(dev_DataPointer, dev_DataPointer, dev_interMfilteredDataPointer, dev_ChannelFilterCoeffA, dev_ChannelFilterCoeffB);

#ifdef CUDA_VERIFY
	USED_DATATYPE* filteredResults = new USED_DATATYPE[(uint32_t)(TRAINING_DATA_LENGTH*DATA_CHANNELS)];
	channelFilter.runFilter(filteredResults, projectInfo.getTraningData(), DATA_CHANNELS, TRAINING_DATA_LENGTH);

	USED_DATATYPE* filteredResultsCUDA = new USED_DATATYPE[(uint32_t)(TRAINING_DATA_LENGTH*DATA_CHANNELS)];
	RetreiveResults(dev_DataPointer, filteredResultsCUDA, TRAINING_DATA_LENGTH, DATA_CHANNELS, sizeof(USED_DATATYPE));

	int error = 0;
	for (int i = 0; i < TRAINING_DATA_LENGTH*DATA_CHANNELS; i++) {
		if (round(filteredResultsCUDA[i]) < floor(filteredResults[i]) || round(filteredResultsCUDA[i]) > ceil(filteredResults[i])) {
			error++;
			if (i < 32 * 10) {
				printf("%0.4f %0.4f, ", filteredResults[i], filteredResultsCUDA[i]);
				if (i+1 % 32 == 0) std::cout << endl;
			}
		}
	}
	std::cout << "Channel filter errors : " << error << std::endl;
	free(filteredResultsCUDA);
#endif

#else
	USED_DATATYPE* filteredResults = new USED_DATATYPE[(uint32_t)(TRAINING_DATA_LENGTH*DATA_CHANNELS)];
	channelFilter.runFilter(filteredResults, projectInfo.getTraningData(), DATA_CHANNELS, TRAINING_DATA_LENGTH);
#ifdef PRINT_OUTPUT_INFO
	std::cout << "1D filtering time: " << channelFilter.getLatestExecutionTime() / 1000 << " ms. processing " << TRAINING_DATA_TIME << " seconds of data" << std::endl;
#endif
#endif


	/**** 2D Filter ****/
#ifdef USE_CUDA
	kernelFilter.runFilterReplicateCUDA(dev_interMfilteredDataPointer, dev_DataPointer, dev_kernelFilterCoeff, DEFAULT_KERNEL_DIM, TRAINING_DATA_LENGTH, DATA_CHANNELS);

#ifdef CUDA_VERIFY
	USED_DATATYPE* kernelResults = new USED_DATATYPE[(uint32_t)(TRAINING_DATA_LENGTH*DATA_CHANNELS)];
	kernelFilter.runFilterReplicate(kernelResults, filteredResults, DEFAULT_KERNEL_DIM, TRAINING_DATA_LENGTH, DATA_CHANNELS);

	USED_DATATYPE* kernelResultsCUDA = new USED_DATATYPE[(uint32_t)(TRAINING_DATA_LENGTH*DATA_CHANNELS)];
	RetreiveResults(dev_interMfilteredDataPointer, kernelResultsCUDA, TRAINING_DATA_LENGTH, DATA_CHANNELS, sizeof(USED_DATATYPE));

	error = 0;
	for (int i = 0; i < TRAINING_DATA_LENGTH*DATA_CHANNELS; i++) {
		if (round(kernelResultsCUDA[i]) < floor(kernelResults[i]) || round(kernelResultsCUDA[i]) > ceil(kernelResults[i])) {
			error++;
			if (i < 32 * 10) {
				printf("%0.4f %0.4f, ", kernelResults[i], kernelResultsCUDA[i]);
				if (i + 1 % 32 == 0) std::cout << endl;
			}
		}
	}
	std::cout << "Kernel filter errors : " << error << std::endl;
	free(filteredResults);
	free(kernelResultsCUDA);
#endif

#else 
#ifdef USE_OPENCV
	USED_DATATYPE* kernelResults = new USED_DATATYPE[(uint32_t)(TRAINING_DATA_LENGTH*DATA_CHANNELS)];
	kernelFilter.runFilterOpenCV(kernelResults, filteredResults, DEFAULT_KERNEL_DIM, TRAINING_DATA_LENGTH, DATA_CHANNELS);
#ifdef PRINT_OUTPUT_INFO
	std::cout << "2D filtering time: " << kernelFilter.getLatestExecutionTime() / 1000 << " ms. processing " << TRAINING_DATA_TIME << " seconds of data" << std::endl;
#endif	
#else
	USED_DATATYPE* kernelResults = new USED_DATATYPE[(uint32_t)(TRAINING_DATA_LENGTH*DATA_CHANNELS)];
	kernelFilter.runFilterReplicate(kernelResults, filteredResults, DEFAULT_KERNEL_DIM, TRAINING_DATA_LENGTH, DATA_CHANNELS);
#ifdef PRINT_OUTPUT_INFO
	std::cout << "2D filtering time: " << kernelFilter.getLatestExecutionTime() / 1000 << " ms. processing " << TRAINING_DATA_TIME << " seconds of data" << std::endl;
#endif	
#endif
#endif


	/**** NXCOR Filter ****/
#ifdef USE_CUDA
	nxcorController.performNXCORWithTemplatesCUDA(dev_NXCOROutput, dev_templates, dev_interMfilteredDataPointer, (uint16_t)TEMPLATE_CROPPED_LENGTH, (uint16_t)TEMPLATE_CROPPED_WIDTH, TRAINING_DATA_LENGTH, DATA_CHANNELS, MAXIMUM_NUMBER_OF_TEMPLATES, dev_lowerChannelIndex);

#ifdef CUDA_VERIFY
	nxcorController.performNXCORWithTemplates(kernelResults);

	USED_DATATYPE* NXCOROutputCUDA = new USED_DATATYPE[(uint32_t)(TRAINING_DATA_LENGTH*MAXIMUM_NUMBER_OF_TEMPLATES)];
	RetreiveResults(dev_NXCOROutput, NXCOROutputCUDA, TRAINING_DATA_LENGTH, MAXIMUM_NUMBER_OF_TEMPLATES, sizeof(USED_DATATYPE));

	error = 0;
	float precision = 1000;
	for (int t = 0; t < MAXIMUM_NUMBER_OF_TEMPLATES; t++) {
		if (projectInfo.isTemplateUsedTraining(t + 1) > 0)
		{
			USED_DATATYPE* featureArray = nxcorController.getFeatureForTemplate(t + 1);
			for (int i = 0; i < (TRAINING_DATA_LENGTH - TEMPLATE_CROPPED_LENGTH - 10); i++) {
				float feature = featureArray[i];
				float featureCUDA = NXCOROutputCUDA[t*TRAINING_DATA_LENGTH + i];
				if (round(featureCUDA*precision) < floor(feature*precision) || round(featureCUDA*precision) > ceil(feature*precision)) {
					error++;
					printf("T%i %0.4f %0.4f, ", t+1, feature, featureCUDA);
					if ((error+1)%10 == 0) std::cout << endl;
				}
			}
		}
	}
	std::cout << "NXCOR filter errors : " << error << std::endl;
	free(kernelResults);
	free(NXCOROutputCUDA);
#endif

#else
	//KBE??? changed when not using kernel filter
	//nxcorController.performNXCORWithTemplates(filteredResults);
	nxcorController.performNXCORWithTemplates(kernelResults);
#ifdef PRINT_OUTPUT_INFO
	std::cout << "NXCOR all templates time: " << nxcorController.getLatestExecutionTime() / 1000 << " ms. processing " << TRAINING_DATA_TIME << " seconds of data" << std::endl;
#endif
#endif


	/**** TRAIN ****/
#ifdef USE_CUDA

#ifdef CUDA_VERIFY
	classifierController.performTrainingBasedOnTemplates(&nxcorController, &templateController);
#endif

	// Perform classification part 1 on GPU
	classifierController.performTrainingBasedOnTemplatesPart1_CUDA(dev_NXCOROutput, dev_aboveThresholdIndicator, dev_FoundTimes, dev_FoundTimesCounter, dev_TPCounter, dev_spikesPeakOffset,
																	dev_grundTruth, dev_grundTruthSizes, dev_grundTruthStartInd);

	if (CheckForCudaError() != cudaError_t::cudaSuccess)
	{
		CUDACleanUpTraining();
		std::cout << "CUDA Error launching or synchronizing, processing stopped" << std::endl;
		return;
	}

	uint32_t* host_FoundTimesCounters = new uint32_t[MAXIMUM_NUMBER_OF_TEMPLATES*NUMBER_OF_THRESHOLDS_TO_TEST];
	if (RetreiveResultsU32(dev_FoundTimesCounter, host_FoundTimesCounters, (uint32_t)MAXIMUM_NUMBER_OF_TEMPLATES, (uint32_t)NUMBER_OF_THRESHOLDS_TO_TEST, (uint16_t)sizeof(uint32_t)) != cudaError_t::cudaSuccess)
	{
		CUDACleanUpTraining();
		std::cout << "CUDA Error fetching found times" << std::endl;
		return;
	}

	uint32_t* host_TPCounters = new uint32_t[MAXIMUM_NUMBER_OF_TEMPLATES*NUMBER_OF_THRESHOLDS_TO_TEST];
	if (RetreiveResultsU32(dev_TPCounter, host_TPCounters, (uint32_t)MAXIMUM_NUMBER_OF_TEMPLATES, (uint32_t)NUMBER_OF_THRESHOLDS_TO_TEST, (uint16_t)sizeof(uint32_t)) != cudaError_t::cudaSuccess)
	{
		CUDACleanUpTraining();
		std::cout << "CUDA Error fetching TP counters" << std::endl;
		return;
	}

	// Perform classification part 2 on CPU
	classifierController.performTrainingBasedOnTemplatesPart2(host_TPCounters, host_FoundTimesCounters);

	// Clean up GPU
	CUDACleanUpTraining();

	delete host_FoundTimesCounters;
	delete host_TPCounters;

#else
	classifierController.performTrainingBasedOnTemplates(&nxcorController, &templateController);
#ifdef PRINT_OUTPUT_INFO
	std::cout << "Train all template models time: " << classifierController.getLatestExecutionTime() / 1000 << " ms. processing " << TRAINING_DATA_TIME << " seconds of data" << std::endl;
#endif
#endif



#ifndef USE_CUDA
	delete kernelResults;
	delete filteredResults;
#endif

	t2 = high_resolution_clock::now();
	auto duration = duration_cast<microseconds>(t2 - t1).count();
	f_latestExecutionTime = (float)duration;
#ifdef USE_CUDA
#ifdef PRINT_OUTPUT_INFO
	std::cout << "Total CUDA Training time: " << f_latestExecutionTime / 1000 << " ms. processing " << TRAINING_DATA_TIME << " seconds of data" << std::endl;
#endif
#else
#ifdef PRINT_OUTPUT_INFO
	std::cout << "Total CPU Training time: " << f_latestExecutionTime / 1000 << " ms. processing " << TRAINING_DATA_TIME << " seconds of data" << std::endl;
#endif
#endif
}

/*----------------------------------------------------------------------------*/
/**
* @brief The testing/prediction loop using the trained model upon new data.
*
* @retval void : none
*/
template <class T>
void SpikeDetection<T>::runPrediction(void)
{
	std::cout << "************* PREDICTION **************" << std::endl;

#ifdef USE_CUDA
	if (prepareCUDAPrediction() != cudaError_t::cudaSuccess)
	{
		CUDACleanUpPrediction();
		std::cout << "CUDA Error, processing stopped" << std::endl;
		return;
	}
#endif
	t1 = high_resolution_clock::now();

	// 1D Filter 
#ifdef USE_CUDA 
	channelFilter.runFilterCUDA(dev_DataPointerP, dev_DataPointerP, dev_interMfilteredDataPointerP, dev_ChannelFilterCoeffAP, dev_ChannelFilterCoeffBP);
#else
	USED_DATATYPE* filteredResults = new USED_DATATYPE[(uint32_t)(TRAINING_DATA_LENGTH*DATA_CHANNELS)];
	channelFilter.runFilter(filteredResults, projectInfo.getPredictionData(), DATA_CHANNELS, TRAINING_DATA_LENGTH);
#ifdef PRINT_OUTPUT_INFO
	std::cout << "1D filtering time: " << channelFilter.getLatestExecutionTime() / 1000 << " ms. processing " << TRAINING_DATA_TIME << " seconds of data" << std::endl;
#endif
#endif


	// 2D Filter 
#ifdef USE_CUDA
	kernelFilter.runFilterReplicateCUDA(dev_interMfilteredDataPointerP, dev_DataPointerP, dev_kernelFilterCoeffP, DEFAULT_KERNEL_DIM, TRAINING_DATA_LENGTH, DATA_CHANNELS);
#else
#ifdef USE_OPENCV
	USED_DATATYPE* kernelResults = new USED_DATATYPE[(uint32_t)(TRAINING_DATA_LENGTH*DATA_CHANNELS)];
	kernelFilter.runFilterOpenCV(kernelResults, filteredResults, DEFAULT_KERNEL_DIM, TRAINING_DATA_LENGTH, DATA_CHANNELS);
#ifdef PRINT_OUTPUT_INFO
	std::cout << "2D filtering time: " << kernelFilter.getLatestExecutionTime() / 1000 << " ms. processing " << TRAINING_DATA_TIME << " seconds of data" << std::endl;
#endif
#else
	USED_DATATYPE* kernelResults = new USED_DATATYPE[(uint32_t)(TRAINING_DATA_LENGTH*DATA_CHANNELS)];
	kernelFilter.runFilterReplicate(kernelResults, filteredResults, DEFAULT_KERNEL_DIM, TRAINING_DATA_LENGTH, DATA_CHANNELS);
#ifdef PRINT_OUTPUT_INFO
	std::cout << "2D filtering time: " << kernelFilter.getLatestExecutionTime() / 1000 << " ms. processing " << TRAINING_DATA_TIME << " seconds of data" << std::endl;
#endif
#endif
#endif


	/**** NXCOR Filter ****/
#ifdef USE_CUDA
	nxcorController.performNXCORWithTemplatesCUDA(dev_NXCOROutputP, dev_templatesP, dev_interMfilteredDataPointerP, (uint16_t)TEMPLATE_CROPPED_LENGTH, (uint16_t)TEMPLATE_CROPPED_WIDTH, TRAINING_DATA_LENGTH, DATA_CHANNELS, MAXIMUM_NUMBER_OF_TEMPLATES, dev_lowerChannelIndexP);
#else
	// KBE??? changed when not using kernel filter
	//nxcorController.performNXCORWithTemplates(filteredResults);
	nxcorController.performNXCORWithTemplates(kernelResults);
#ifdef PRINT_OUTPUT_INFO
	std::cout << "NXCOR all templates time: " << nxcorController.getLatestExecutionTime() / 1000 << " ms. processing " << TRAINING_DATA_TIME << " seconds of data" << std::endl;
#endif
#endif


	// Predict
#ifdef USE_CUDA
	// Perform prediction on GPU
	classifierController.performPredictionBasedOnTemplatesCUDA(dev_NXCOROutputP, dev_aboveThresholdIndicatorP, dev_FoundTimesP, dev_FoundTimesCounterP, dev_thresholdsP);

	if (CheckForCudaError() != cudaError_t::cudaSuccess)
	{
		CUDACleanUpPrediction();
		std::cout << "CUDA Error launching or synchronizing, processing stopped" << std::endl;
		return;
	}

	uint32_t* host_FoundTimesCounters = new uint32_t[MAXIMUM_NUMBER_OF_TEMPLATES];
	if (RetreiveResultsU32(dev_FoundTimesCounterP, host_FoundTimesCounters, (uint32_t)MAXIMUM_NUMBER_OF_TEMPLATES, (uint32_t)1, (uint16_t)sizeof(uint32_t)) != cudaError_t::cudaSuccess)
	{
		CUDACleanUpPrediction();
		std::cout << "CUDA Error fetching found times" << std::endl;
		return;
	}

	uint32_t* host_FoundTimesP = new uint32_t[MAXIMUM_NUMBER_OF_TEMPLATES*MAXIMUM_PREDICTION_SAMPLES];
	if (RetreiveResultsU32(dev_FoundTimesP, host_FoundTimesP, (uint32_t)MAXIMUM_NUMBER_OF_TEMPLATES, (uint32_t)MAXIMUM_PREDICTION_SAMPLES, (uint16_t)sizeof(uint32_t)) != cudaError_t::cudaSuccess)
	{
		CUDACleanUpPrediction();
		std::cout << "CUDA Error fetching times array" << std::endl;
		return;
	}

#ifdef PRINT_OUTPUT_INFO
	classifierController.verifyPredictionBasedOnTemplatesCUDA(host_FoundTimesCounters, host_FoundTimesP, &templateController);
#endif

	// Clean up GPU
	CUDACleanUpPrediction();

	delete host_FoundTimesCounters;
	delete host_FoundTimesP;

#else
	classifierController.performPredictionBasedOnTemplates(&nxcorController, &templateController);
#ifdef PRINT_OUTPUT_INFO
	std::cout << "Prediction, all models time: " << classifierController.getLatestExecutionTime() / 1000 << " ms. processing " << RUNTIME_DATA_TIME << " seconds of data" << std::endl;
#endif
#endif


	// TODO:
	// Make the arrays static instead an save time by avoiding Allocation and deallocation runtime!!
#ifndef USE_CUDA
	delete kernelResults;
	delete filteredResults;
#endif

	t2 = high_resolution_clock::now();
	auto duration = duration_cast<microseconds>(t2 - t1).count();
	f_latestExecutionTime = (float)duration;
#ifdef USE_CUDA
#ifdef PRINT_OUTPUT_INFO
	std::cout << "Total CUDA Prediction time: " << f_latestExecutionTime / 1000 << " ms. processing " << TRAINING_DATA_TIME << " seconds of data" << std::endl;
#endif
#else
#ifdef PRINT_OUTPUT_INFO
	std::cout << "Total CPU Prediction time: " << f_latestExecutionTime / 1000 << " ms. processing " << TRAINING_DATA_TIME << " seconds of data" << std::endl;
#endif
#endif

}

#ifdef USE_CUDA
/*----------------------------------------------------------------------------*/
/**
* @brief Initilize CUDA, selects the GPU unit, allocates and transfers data
* 
* @param T* dataPointer				: Pointer to the data which is the offset
* @param uint32_t dataLength		: The length of the datasnippet to process
* @retval cudaError_t				: The status of the CUDA operation
*/
template <class T>
cudaError_t SpikeDetection<T>::prepareCUDATraining(void)
{
	cudaError_t cudaStatus;

	cudaStatus =  SelectCUDA_GPU_Unit();
	if (cudaStatus != cudaSuccess) return cudaStatus;

	/********** Allocate the needed data **************/
	/* Allocate Buffer for data */
	cudaStatus = AllocateCUDAData(&dev_DataPointer, (uint32_t)TRAINING_DATA_LENGTH, (uint32_t)DATA_CHANNELS, (uint16_t)sizeof(USED_DATATYPE));
	if (cudaStatus != cudaSuccess) return cudaStatus;

	/* Allocate Temporary filtered Result Buffer for raw data */
	cudaStatus = AllocateCUDAData(&dev_interMfilteredDataPointer, (uint32_t)TRAINING_DATA_LENGTH, (uint32_t)DATA_CHANNELS, (uint16_t)sizeof(USED_DATATYPE));
	if (cudaStatus != cudaSuccess) return cudaStatus;

	/* Allocate Space for channel filter A coeff. */
	cudaStatus = AllocateCUDAData(&dev_ChannelFilterCoeffA, (uint32_t)NUMBER_OF_A_COEFF, (uint32_t)1, (uint16_t)sizeof(USED_DATATYPE));
	if (cudaStatus != cudaSuccess) return cudaStatus;
	
	/* Allocate Space for channel filter B coeff. */
	cudaStatus = AllocateCUDAData(&dev_ChannelFilterCoeffB, (uint32_t)NUMBER_OF_B_COEFF, (uint32_t)1, (uint16_t)sizeof(USED_DATATYPE));
	if (cudaStatus != cudaSuccess) return cudaStatus;

	/* Allocate Space for kernel filter coeff. */
	cudaStatus = AllocateCUDAData(&dev_kernelFilterCoeff, (uint32_t)DEFAULT_KERNEL_DIM, (uint32_t)DEFAULT_KERNEL_DIM, (uint16_t)sizeof(USED_DATATYPE));
	if (cudaStatus != cudaSuccess) return cudaStatus;

	/* Allocate Space for NXCOR Output */
	cudaStatus = AllocateCUDAData(&dev_NXCOROutput, (uint32_t)TRAINING_DATA_LENGTH, (uint32_t)MAXIMUM_NUMBER_OF_TEMPLATES, (uint16_t)sizeof(USED_DATATYPE));
	if (cudaStatus != cudaSuccess) return cudaStatus;

	/* Allocate Space for Templates */
	cudaStatus = AllocateCUDAData(&dev_templates, (uint32_t)TEMPLATE_CROPPED_LENGTH*TEMPLATE_CROPPED_WIDTH, (uint32_t)MAXIMUM_NUMBER_OF_TEMPLATES, (uint16_t)sizeof(USED_DATATYPE));
	if (cudaStatus != cudaSuccess) return cudaStatus;

	/* Allocate Space lower channel index */
	cudaStatus = AllocateCUDADataU16(&dev_lowerChannelIndex, (uint32_t)MAXIMUM_NUMBER_OF_TEMPLATES, (uint32_t)1, (uint16_t)sizeof(uint16_t));
	if (cudaStatus != cudaSuccess) return cudaStatus;
	
	/* Allocate Space For TP counts */
	cudaStatus = AllocateCUDADataU32(&dev_TPCounter, (uint32_t)MAXIMUM_NUMBER_OF_TEMPLATES, (uint32_t)NUMBER_OF_THRESHOLDS_TO_TEST, (uint16_t)sizeof(uint32_t));
	if (cudaStatus != cudaSuccess) return cudaStatus;

	/* Allocate Space For spike detection counts */
	cudaStatus = AllocateCUDADataU32(&dev_FoundTimesCounter, (uint32_t)MAXIMUM_NUMBER_OF_TEMPLATES, (uint32_t)NUMBER_OF_THRESHOLDS_TO_TEST, (uint16_t)sizeof(uint32_t));
	if (cudaStatus != cudaSuccess) return cudaStatus;

	/* Allocate Space for threshold indication */
	cudaStatus = AllocateCUDADataChar(&dev_aboveThresholdIndicator, (uint32_t)TRAINING_DATA_LENGTH, (uint32_t)MAXIMUM_NUMBER_OF_TEMPLATES, (uint16_t)sizeof(char));
	if (cudaStatus != cudaSuccess) return cudaStatus;
	
	/* Allocate Space For spike detection counts */
	cudaStatus = AllocateCUDADataU32(&dev_FoundTimes, (uint32_t)MAXIMUM_NUMBER_OF_TEMPLATES, (uint32_t)MAXIMUM_PREDICTION_SAMPLES, (uint16_t)sizeof(uint32_t));
	if (cudaStatus != cudaSuccess) return cudaStatus;

	/* Allocate Space for peak offsets */
	cudaStatus = AllocateCUDADataU16(&dev_spikesPeakOffset, (uint32_t)MAXIMUM_NUMBER_OF_TEMPLATES, (uint32_t)1, (uint16_t)sizeof(uint16_t));
	if (cudaStatus != cudaSuccess) return cudaStatus;

	/* Allocate Space For grund truth to compare against */
	cudaStatus = AllocateCUDADataU32(&dev_grundTruth, (uint32_t)projectInfo.getNumberTotalTruthTableSize(), (uint32_t)1, (uint16_t)sizeof(uint32_t));
	if (cudaStatus != cudaSuccess) return cudaStatus;

	/* Allocate Space For grund truth sizes */
	cudaStatus = AllocateCUDADataU32(&dev_grundTruthSizes, (uint32_t)MAXIMUM_NUMBER_OF_TEMPLATES, (uint32_t)1, (uint16_t)sizeof(uint32_t));
	if (cudaStatus != cudaSuccess) return cudaStatus;

	/* Allocate Space For grund truth start indencis */
	cudaStatus = AllocateCUDADataU32(&dev_grundTruthStartInd, (uint32_t)MAXIMUM_NUMBER_OF_TEMPLATES, (uint32_t)1, (uint16_t)sizeof(uint32_t));
	if (cudaStatus != cudaSuccess) return cudaStatus;
	

	/****************************** MemCpy the needed data to the GPU ****************************/
	/* Memory copy raw data to GPU*/
	cudaStatus = MemCpyCUDAData(dev_DataPointer, projectInfo.getTraningData(), (uint32_t)TRAINING_DATA_LENGTH, (uint32_t)DATA_CHANNELS, (uint16_t)sizeof(USED_DATATYPE));
	if (cudaStatus != cudaSuccess) return cudaStatus;

	/* Memory copy Kernel filter coeff to data */
	cudaStatus = MemCpyCUDAData(dev_ChannelFilterCoeffA, channelFilter.getFilterCoeffsA(), (uint32_t)NUMBER_OF_A_COEFF, (uint32_t)1, (uint16_t)sizeof(USED_DATATYPE));
	if (cudaStatus != cudaSuccess) return cudaStatus;

	/* Memory copy Kernel filter coeff to data */
	cudaStatus = MemCpyCUDAData(dev_ChannelFilterCoeffB, channelFilter.getFilterCoeffsB(), (uint32_t)NUMBER_OF_B_COEFF, (uint32_t)1, (uint16_t)sizeof(USED_DATATYPE));
	if (cudaStatus != cudaSuccess) return cudaStatus;

	/* Memory copy Kernel filter coeff to data */
	cudaStatus = MemCpyCUDAData(dev_kernelFilterCoeff, kernelFilter.getKernelFilterCoeff(), (uint32_t)DEFAULT_KERNEL_DIM, (uint32_t)DEFAULT_KERNEL_DIM, (uint16_t)sizeof(USED_DATATYPE));
	if (cudaStatus != cudaSuccess) return cudaStatus;

	/* Memory copy filterTemplates to GPU */
	cudaStatus = MemCpyCUDAData(dev_templates, templateController.getAllCroppedTemplates(), (uint32_t)TEMPLATE_CROPPED_LENGTH*TEMPLATE_CROPPED_WIDTH, (uint32_t)MAXIMUM_NUMBER_OF_TEMPLATES, (uint16_t)sizeof(USED_DATATYPE));
	if (cudaStatus != cudaSuccess) return cudaStatus;

	/* Memory copy lower index channel number to GPU */
	cudaStatus = MemCpyCUDADataU16(dev_lowerChannelIndex, templateController.getAllTemplatesLowerIndex(), (uint32_t)MAXIMUM_NUMBER_OF_TEMPLATES, (uint32_t)1, (uint16_t)sizeof(uint16_t));
	if (cudaStatus != cudaSuccess) return cudaStatus;

	/* Memory copy TP counter to GPU - zero init. */
	uint32_t myArray[(uint32_t)MAXIMUM_NUMBER_OF_TEMPLATES*(uint32_t)NUMBER_OF_THRESHOLDS_TO_TEST] = { 0 };
	cudaStatus = MemCpyCUDADataU32(dev_TPCounter, myArray, (uint32_t)MAXIMUM_NUMBER_OF_TEMPLATES, (uint32_t)NUMBER_OF_THRESHOLDS_TO_TEST, (uint16_t)sizeof(uint32_t));
	if (cudaStatus != cudaSuccess) return cudaStatus;

	/* Memory copy Found times counter to GPU - zero init. */
	cudaStatus = MemCpyCUDADataU32(dev_FoundTimesCounter, myArray, (uint32_t)MAXIMUM_NUMBER_OF_TEMPLATES, (uint32_t)NUMBER_OF_THRESHOLDS_TO_TEST, (uint16_t)sizeof(uint32_t));
	if (cudaStatus != cudaSuccess) return cudaStatus;

	/* Memory copy templates peaks offsets to GPU */
	cudaStatus = MemCpyCUDADataU16(dev_spikesPeakOffset, templateController.getAllTemplatesPeaksOffset(), (uint32_t)MAXIMUM_NUMBER_OF_TEMPLATES, (uint32_t)1, (uint16_t)sizeof(uint16_t));
	if (cudaStatus != cudaSuccess) return cudaStatus;

	/* Memory copy truth table to GPU */
	cudaStatus = MemCpyCUDADataU32(dev_grundTruth, projectInfo.getTruthTableCombined(), (uint32_t)projectInfo.getNumberTotalTruthTableSize(), (uint32_t)1, (uint16_t)sizeof(uint32_t));
	if (cudaStatus != cudaSuccess) return cudaStatus;

	/* Memory copy truth table sizes to the GPU */
	cudaStatus = MemCpyCUDADataU32(dev_grundTruthSizes, projectInfo.getTruthTableSizes(), (uint32_t)MAXIMUM_NUMBER_OF_TEMPLATES, (uint32_t)1, (uint16_t)sizeof(uint32_t));
	if (cudaStatus != cudaSuccess) return cudaStatus;

	/* Memory copy truth table start indecis to the GPU */
	cudaStatus = MemCpyCUDADataU32(dev_grundTruthStartInd, projectInfo.getTruthTableStartIndencis(), (uint32_t)MAXIMUM_NUMBER_OF_TEMPLATES, (uint32_t)1, (uint16_t)sizeof(uint32_t));
	
	return cudaStatus;
}


/*----------------------------------------------------------------------------*/
/**
* @brief Initilize CUDA, selects the GPU unit, allocates and transfers data
*
* @param T* dataPointer				: Pointer to the data which is the offset
* @param uint32_t dataLength		: The length of the datasnippet to process
* @retval cudaError_t				: The status of the CUDA operation
*/
template <class T>
cudaError_t SpikeDetection<T>::prepareCUDAPrediction(void)
{
	cudaError_t cudaStatus;

	cudaStatus = SelectCUDA_GPU_Unit();
	if (cudaStatus != cudaSuccess) return cudaStatus;

	/********** Allocate the needed data **************/
	/* Allocate Buffer for data */
	cudaStatus = AllocateCUDAData(&dev_DataPointerP, (uint32_t)RUNTIME_DATA_LENGTH, (uint32_t)DATA_CHANNELS, (uint16_t)sizeof(USED_DATATYPE));
	if (cudaStatus != cudaSuccess) return cudaStatus;

	/* Allocate Temporary filtered Result Buffer for raw data */
	cudaStatus = AllocateCUDAData(&dev_interMfilteredDataPointerP, (uint32_t)RUNTIME_DATA_LENGTH, (uint32_t)DATA_CHANNELS, (uint16_t)sizeof(USED_DATATYPE));
	if (cudaStatus != cudaSuccess) return cudaStatus;

	/* Allocate Space for channel filter A coeff. */
	cudaStatus = AllocateCUDAData(&dev_ChannelFilterCoeffAP, (uint32_t)NUMBER_OF_A_COEFF, (uint32_t)1, (uint16_t)sizeof(USED_DATATYPE));
	if (cudaStatus != cudaSuccess) return cudaStatus;

	/* Allocate Space for channel filter B coeff. */
	cudaStatus = AllocateCUDAData(&dev_ChannelFilterCoeffBP, (uint32_t)NUMBER_OF_B_COEFF, (uint32_t)1, (uint16_t)sizeof(USED_DATATYPE));
	if (cudaStatus != cudaSuccess) return cudaStatus;

	/* Allocate Space for kernel filter coeff. */
	cudaStatus = AllocateCUDAData(&dev_kernelFilterCoeffP, (uint32_t)DEFAULT_KERNEL_DIM, (uint32_t)DEFAULT_KERNEL_DIM, (uint16_t)sizeof(USED_DATATYPE));
	if (cudaStatus != cudaSuccess) return cudaStatus;

	/* Allocate Space for NXCOR Output */
	cudaStatus = AllocateCUDAData(&dev_NXCOROutputP, (uint32_t)RUNTIME_DATA_LENGTH, (uint32_t)MAXIMUM_NUMBER_OF_TEMPLATES, (uint16_t)sizeof(USED_DATATYPE));
	if (cudaStatus != cudaSuccess) return cudaStatus;

	/* Allocate Space for Templates */
	cudaStatus = AllocateCUDAData(&dev_templatesP, (uint32_t)TEMPLATE_CROPPED_LENGTH*TEMPLATE_CROPPED_WIDTH, (uint32_t)MAXIMUM_NUMBER_OF_TEMPLATES, (uint16_t)sizeof(USED_DATATYPE));
	if (cudaStatus != cudaSuccess) return cudaStatus;

	/* Allocate Space lower channel index */
	cudaStatus = AllocateCUDADataU16(&dev_lowerChannelIndexP, (uint32_t)MAXIMUM_NUMBER_OF_TEMPLATES, (uint32_t)1, (uint16_t)sizeof(uint16_t));
	if (cudaStatus != cudaSuccess) return cudaStatus;

	/* Allocate Space For spike detection counts */
	cudaStatus = AllocateCUDADataU32(&dev_FoundTimesCounterP, (uint32_t)MAXIMUM_NUMBER_OF_TEMPLATES, (uint32_t)1, (uint16_t)sizeof(uint32_t));
	if (cudaStatus != cudaSuccess) return cudaStatus;

	/* Allocate Space for threshold indication */
	cudaStatus = AllocateCUDADataChar(&dev_aboveThresholdIndicatorP, (uint32_t)RUNTIME_DATA_LENGTH, (uint32_t)MAXIMUM_NUMBER_OF_TEMPLATES, (uint16_t)sizeof(char));
	if (cudaStatus != cudaSuccess) return cudaStatus;

	/* Allocate Space For spike detection counts */
	cudaStatus = AllocateCUDADataU32(&dev_FoundTimesP, (uint32_t)MAXIMUM_NUMBER_OF_TEMPLATES, (uint32_t)MAXIMUM_PREDICTION_SAMPLES, (uint16_t)sizeof(uint32_t));
	if (cudaStatus != cudaSuccess) return cudaStatus;

	/* Allocate Space for peak offsets */
	cudaStatus = AllocateCUDADataU16(&dev_spikesPeakOffsetP, (uint32_t)MAXIMUM_NUMBER_OF_TEMPLATES, (uint32_t)1, (uint16_t)sizeof(uint16_t));
	if (cudaStatus != cudaSuccess) return cudaStatus;

	/* Allocate Space for the trained thresholds */
	cudaStatus = AllocateCUDAData(&dev_thresholdsP, (uint32_t)MAXIMUM_NUMBER_OF_TEMPLATES, (uint32_t)1, (uint16_t)sizeof(USED_DATATYPE));
	if (cudaStatus != cudaSuccess) return cudaStatus;	


	/****************************** MemCpy the needed data to the GPU ****************************/
	/* Memory copy raw data to GPU*/
	cudaStatus = MemCpyCUDAData(dev_DataPointerP, projectInfo.getPredictionData(), (uint32_t)RUNTIME_DATA_LENGTH, (uint32_t)DATA_CHANNELS, (uint16_t)sizeof(USED_DATATYPE));
	if (cudaStatus != cudaSuccess) return cudaStatus;

	/* Memory copy Kernel filter coeff to data */
	cudaStatus = MemCpyCUDAData(dev_ChannelFilterCoeffAP, channelFilter.getFilterCoeffsA(), (uint32_t)NUMBER_OF_A_COEFF, (uint32_t)1, (uint16_t)sizeof(USED_DATATYPE));
	if (cudaStatus != cudaSuccess) return cudaStatus;

	/* Memory copy Kernel filter coeff to data */
	cudaStatus = MemCpyCUDAData(dev_ChannelFilterCoeffBP, channelFilter.getFilterCoeffsB(), (uint32_t)NUMBER_OF_B_COEFF, (uint32_t)1, (uint16_t)sizeof(USED_DATATYPE));
	if (cudaStatus != cudaSuccess) return cudaStatus;

	/* Memory copy Kernel filter coeff to data */
	cudaStatus = MemCpyCUDAData(dev_kernelFilterCoeffP, kernelFilter.getKernelFilterCoeff(), (uint32_t)DEFAULT_KERNEL_DIM, (uint32_t)DEFAULT_KERNEL_DIM, (uint16_t)sizeof(USED_DATATYPE));
	if (cudaStatus != cudaSuccess) return cudaStatus;

	/* Memory copy filterTemplates to GPU */
	cudaStatus = MemCpyCUDAData(dev_templatesP, templateController.getAllCroppedTemplates(), (uint32_t)TEMPLATE_CROPPED_LENGTH*TEMPLATE_CROPPED_WIDTH, (uint32_t)MAXIMUM_NUMBER_OF_TEMPLATES, (uint16_t)sizeof(USED_DATATYPE));
	if (cudaStatus != cudaSuccess) return cudaStatus;

	/* Memory copy lower index channel number to GPU */
	cudaStatus = MemCpyCUDADataU16(dev_lowerChannelIndexP, templateController.getAllTemplatesLowerIndex(), (uint32_t)MAXIMUM_NUMBER_OF_TEMPLATES, (uint32_t)1, (uint16_t)sizeof(uint16_t));
	if (cudaStatus != cudaSuccess) return cudaStatus;

	/* Memory copy Found times counter to GPU - zero init. */
	uint32_t myArray[(uint32_t)MAXIMUM_NUMBER_OF_TEMPLATES] = { 0 };
	cudaStatus = MemCpyCUDADataU32(dev_FoundTimesCounterP, myArray, (uint32_t)MAXIMUM_NUMBER_OF_TEMPLATES, (uint32_t)1, (uint16_t)sizeof(uint32_t));
	if (cudaStatus != cudaSuccess) return cudaStatus;

	/* Memory copy templates peaks offsets to GPU */
	cudaStatus = MemCpyCUDADataU16(dev_spikesPeakOffsetP, templateController.getAllTemplatesPeaksOffset(), (uint32_t)MAXIMUM_NUMBER_OF_TEMPLATES, (uint32_t)1, (uint16_t)sizeof(uint16_t));
	if (cudaStatus != cudaSuccess) return cudaStatus;
	
	/* Memory copy trained thresholds to GPU */
	float thresholdsArray[MAXIMUM_NUMBER_OF_TEMPLATES];
	for (uint32_t i = 0; i < MAXIMUM_NUMBER_OF_TEMPLATES; i++) { thresholdsArray[i] = classifierController.getTemplateThreshold(i + 1); }
	cudaStatus = MemCpyCUDAData(dev_thresholdsP, thresholdsArray, (uint32_t)MAXIMUM_NUMBER_OF_TEMPLATES, (uint32_t)1, (uint16_t)sizeof(USED_DATATYPE));
	
	return cudaStatus;
}

/*----------------------------------------------------------------------------*/
/**
* @brief Cleans up the CUDA execution
*
* @param none
* @retval none				
*/
template <class T>
void SpikeDetection<T>::CUDACleanUpTraining(void)
{
	CleanUpCudaForSpikeDet(dev_DataPointer);
	CleanUpCudaForSpikeDet(dev_interMfilteredDataPointer);
	CleanUpCudaForSpikeDet(dev_kernelFilterCoeff);
	CleanUpCudaForSpikeDet(dev_ChannelFilterCoeffA);
	CleanUpCudaForSpikeDet(dev_ChannelFilterCoeffB);
	CleanUpCudaForSpikeDet(dev_NXCOROutput);
	CleanUpCudaForSpikeDet(dev_templates);
	CleanUpCudaForSpikeDetU16(dev_lowerChannelIndex);
	CleanUpCudaForSpikeDetU32(dev_TPCounter);
	CleanUpCudaForSpikeDetChar(dev_aboveThresholdIndicator);
	CleanUpCudaForSpikeDetU32(dev_FoundTimes);
	CleanUpCudaForSpikeDetU32(dev_FoundTimesCounter);
	CleanUpCudaForSpikeDetU16(dev_spikesPeakOffset);
	CleanUpCudaForSpikeDetU32(dev_grundTruth);
	CleanUpCudaForSpikeDetU32(dev_grundTruthSizes);
	CleanUpCudaForSpikeDetU32(dev_grundTruthStartInd);
}

/*----------------------------------------------------------------------------*/
/**
* @brief Cleans up the CUDA execution
*
* @param none
* @retval none
*/
template <class T>
void SpikeDetection<T>::CUDACleanUpPrediction(void)
{
	CleanUpCudaForSpikeDet(dev_DataPointerP);
	CleanUpCudaForSpikeDet(dev_interMfilteredDataPointerP);
	CleanUpCudaForSpikeDet(dev_kernelFilterCoeffP);
	CleanUpCudaForSpikeDet(dev_ChannelFilterCoeffAP);
	CleanUpCudaForSpikeDet(dev_ChannelFilterCoeffBP);
	CleanUpCudaForSpikeDet(dev_NXCOROutputP);
	CleanUpCudaForSpikeDet(dev_templatesP);
	CleanUpCudaForSpikeDetU16(dev_lowerChannelIndexP);
	CleanUpCudaForSpikeDetChar(dev_aboveThresholdIndicatorP);
	CleanUpCudaForSpikeDetU32(dev_FoundTimesP);
	CleanUpCudaForSpikeDetU32(dev_FoundTimesCounterP);
	CleanUpCudaForSpikeDetU16(dev_spikesPeakOffsetP);
	CleanUpCudaForSpikeDet(dev_thresholdsP);
}

#endif

#endif