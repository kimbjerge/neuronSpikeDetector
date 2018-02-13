///////////////////////////////////////////////////////////
//  SpikeDetection.h
//  Header:          Spike Detect Class (CUDA optimized)
//                   Realtime Predition specialization
//  Created on:      12-02-2018
//  Original author: KBE
///////////////////////////////////////////////////////////
#ifndef SPIKE_DETECTCUDA_RTP_H
#define SPIKE_DETECTCUDA_RTP_H

#include "SpikeDetectCUDA.h"		

using namespace std::chrono;

template <class T>
class SpikeDetectCUDA_RTP : public SpikeDetectCUDA<T>
{
public:
	/* Constructor */
	SpikeDetectCUDA_RTP();
	/* Methods */
	virtual void runPrediction(void);
	uint32_t* getFoundTimesCounters(void);
	virtual cudaError_t prepareCUDAPrediction(void);
	virtual void CUDACleanUpPrediction(void);
protected:
	cudaError_t runPredictionRTP(T *dataPointerP);
	uint32_t* host_FoundTimesCounters;
	uint32_t* host_FoundTimesP;
	uint32_t myArray[(uint32_t)MAXIMUM_NUMBER_OF_TEMPLATES] = { 0 };
};

/*----------------------------------------------------------------------------*/
/**
* @brief Constructor
* @note Empty!
*/
template <class T>
SpikeDetectCUDA_RTP<T>::SpikeDetectCUDA_RTP() :
	SpikeDetectCUDA()
{
	host_FoundTimesCounters = NULL;
	host_FoundTimesP = NULL;
}

/*----------------------------------------------------------------------------*/
/**
* @brief Returns a pointer to the array of number of times template found in data
*
* @retval void : Pointer to array of size MAXIMUM_NUMBER_OF_TEMPLATES
*/
template <class T>
uint32_t* SpikeDetectCUDA_RTP<T>::getFoundTimesCounters(void)
{
	return host_FoundTimesCounters;
}

/*----------------------------------------------------------------------------*/
/**
* @brief The testing/prediction loop using the trained model upon new data.
*
* @retval void : none
*/
template <class T>
void SpikeDetectCUDA_RTP<T>::runPrediction(void)
{
	int spikesFound = 0;
	cudaError_t cudaStatus;
	T *currentDataPointer;
	int numIterations = (int)((float)RUNTIME_DATA_TIME / RTP_DATA_TIME);

	std::cout << "************* CUDA REALTIME PREDICTION **************" << std::endl;

	cudaStatus = prepareCUDAPrediction();
	if (cudaStatus == cudaError_t::cudaSuccess)
	{
		currentDataPointer = projectInfo.getPredictionData();
		for (int i = 0; i < numIterations; i++) {
			cudaStatus = runPredictionRTP(currentDataPointer);
			if (cudaStatus != cudaError_t::cudaSuccess) break;
			currentDataPointer += (int)(RTP_DATA_LENGTH*DATA_CHANNELS);
			//std::cout << i << std::endl;
			for (int j = 0; j < MAXIMUM_NUMBER_OF_TEMPLATES; j++)
				if (host_FoundTimesCounters[j] > 0) {
					std::cout << "                T" << (j + 1) << " num: " << host_FoundTimesCounters[j] << std::endl;
					spikesFound += host_FoundTimesCounters[j];
				}
		}
	} else {
		std::cout << "CUDA Error allocating memory, processing stopped" << std::endl;
	}

	std::cout << "Number of neuron spikes : " << spikesFound << std::endl;
	// Clean up GPU and Memory
	CUDACleanUpPrediction();
}

template <class T>
cudaError_t SpikeDetectCUDA_RTP<T>::runPredictionRTP(T *dataPointerP)
{
	cudaError_t cudaStatus = cudaError_t::cudaSuccess;

	t1 = high_resolution_clock::now();

	/* Memory copy raw data to GPU*/
	cudaStatus = MemCpyCUDAData(dev_DataPointerP, dataPointerP, (uint32_t)RTP_DATA_LENGTH, (uint32_t)DATA_CHANNELS, (uint16_t)sizeof(USED_DATATYPE));
	if (cudaStatus != cudaError_t::cudaSuccess) {
		std::cout << "MemCpyCUDAData error , processing stopped" << std::endl;
		return cudaStatus;
	}

	/* Memory copy Found times counter to GPU - zero init. */
	cudaStatus = MemCpyCUDADataU32(dev_FoundTimesCounterP, myArray, (uint32_t)MAXIMUM_NUMBER_OF_TEMPLATES, (uint32_t)1, (uint16_t)sizeof(uint32_t));
	if (cudaStatus != cudaSuccess) {
		std::cout << "MemCpyCUDADataU32 error , processing stopped" << std::endl;
		return cudaStatus;
	}

	// 1D Filter 
	channelFilter.runFilterCUDA(dev_DataPointerP, dev_DataPointerP, dev_interMfilteredDataPointerP, dev_ChannelFilterCoeffAP, dev_ChannelFilterCoeffBP, RTP_DATA_LENGTH);

	// 2D Filter 
#ifdef USE_KERNEL_FILTER
	kernelFilter.runFilterReplicateCUDA(dev_interMfilteredDataPointerP, dev_DataPointerP, dev_kernelFilterCoeffP, DEFAULT_KERNEL_DIM, RTP_DATA_LENGTH, DATA_CHANNELS);

	/**** NXCOR Filter ****/
	nxcorController.performNXCORWithTemplatesCUDA(dev_NXCOROutputP, dev_templatesP, dev_interMfilteredDataPointerP, (uint16_t)TEMPLATE_CROPPED_LENGTH, (uint16_t)TEMPLATE_CROPPED_WIDTH, RTP_DATA_LENGTH, DATA_CHANNELS, MAXIMUM_NUMBER_OF_TEMPLATES, dev_lowerChannelIndexP);
#else
	/**** NXCOR Filter without kernel filter  ****/
	nxcorController.performNXCORWithTemplatesCUDA(dev_NXCOROutputP, dev_templatesP, dev_DataPointerP, (uint16_t)TEMPLATE_CROPPED_LENGTH, (uint16_t)TEMPLATE_CROPPED_WIDTH, RTP_DATA_LENGTH, DATA_CHANNELS, MAXIMUM_NUMBER_OF_TEMPLATES, dev_lowerChannelIndexP);
#endif

	// Perform prediction on GPU
	classifierController.performPredictionBasedOnTemplatesCUDA(dev_NXCOROutputP, dev_aboveThresholdIndicatorP, dev_FoundTimesP, dev_FoundTimesCounterP, dev_thresholdsP, RTP_DATA_LENGTH);

	cudaStatus = CheckForCudaError();
	if (cudaStatus != cudaError_t::cudaSuccess)
	{
		std::cout << "CUDA Error launching or synchronizing, processing stopped" << std::endl;
		return cudaStatus;
	}

	cudaStatus = RetreiveResultsU32(dev_FoundTimesCounterP, host_FoundTimesCounters, (uint32_t)MAXIMUM_NUMBER_OF_TEMPLATES, (uint32_t)1, (uint16_t)sizeof(uint32_t));
	if (cudaStatus != cudaError_t::cudaSuccess)
	{
		std::cout << "CUDA Error fetching found times" << std::endl;
		return cudaStatus;
	}

	cudaStatus = RetreiveResultsU32(dev_FoundTimesP, host_FoundTimesP, (uint32_t)MAXIMUM_NUMBER_OF_TEMPLATES, (uint32_t)MAXIMUM_PREDICTION_SAMPLES, (uint16_t)sizeof(uint32_t));
	if (cudaStatus != cudaError_t::cudaSuccess)
	{
		std::cout << "CUDA Error fetching times array" << std::endl;
		return cudaStatus;
	}

#ifdef PRINT_OUTPUT_INFO
	classifierController.verifyPredictionBasedOnTemplatesCUDA(host_FoundTimesCounters, host_FoundTimesP, &templateController);
#endif

	t2 = high_resolution_clock::now();
	auto duration = duration_cast<microseconds>(t2 - t1).count();
	f_latestExecutionTime = (float)duration;

//#ifdef PRINT_OUTPUT_INFO
	//std::cout << "RTP time: " << f_latestExecutionTime / 1000 << " ms. processing " << RTP_DATA_TIME << " sec. data" << std::endl;
	std::cout << "RTP: " << f_latestExecutionTime / 1000 << " ms" << std::endl;
//#endif

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
cudaError_t SpikeDetectCUDA_RTP<T>::prepareCUDAPrediction(void)
{
	cudaError_t cudaStatus;

	cudaStatus = SelectCUDA_GPU_Unit();
	if (cudaStatus != cudaSuccess) return cudaStatus;

	/********** Allocate the needed data **************/
	/* Allocate Buffer for data */
	cudaStatus = AllocateCUDAData(&dev_DataPointerP, (uint32_t)RTP_DATA_LENGTH, (uint32_t)DATA_CHANNELS, (uint16_t)sizeof(USED_DATATYPE));
	if (cudaStatus != cudaSuccess) return cudaStatus;

	/* Allocate Temporary filtered Result Buffer for raw data */
	cudaStatus = AllocateCUDAData(&dev_interMfilteredDataPointerP, (uint32_t)RTP_DATA_LENGTH, (uint32_t)DATA_CHANNELS, (uint16_t)sizeof(USED_DATATYPE));
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
	cudaStatus = AllocateCUDAData(&dev_NXCOROutputP, (uint32_t)RTP_DATA_LENGTH, (uint32_t)MAXIMUM_NUMBER_OF_TEMPLATES, (uint16_t)sizeof(USED_DATATYPE));
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
	cudaStatus = AllocateCUDADataChar(&dev_aboveThresholdIndicatorP, (uint32_t)RTP_DATA_LENGTH, (uint32_t)MAXIMUM_NUMBER_OF_TEMPLATES, (uint16_t)sizeof(char));
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
	//cudaStatus = MemCpyCUDAData(dev_DataPointerP, projectInfo.getPredictionData(), (uint32_t)RUNTIME_DATA_LENGTH, (uint32_t)DATA_CHANNELS, (uint16_t)sizeof(USED_DATATYPE));
	//if (cudaStatus != cudaSuccess) return cudaStatus;

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
	//uint32_t myArray[(uint32_t)MAXIMUM_NUMBER_OF_TEMPLATES] = { 0 };
	cudaStatus = MemCpyCUDADataU32(dev_FoundTimesCounterP, myArray, (uint32_t)MAXIMUM_NUMBER_OF_TEMPLATES, (uint32_t)1, (uint16_t)sizeof(uint32_t));
	if (cudaStatus != cudaSuccess) return cudaStatus;

	/* Memory copy templates peaks offsets to GPU */
	cudaStatus = MemCpyCUDADataU16(dev_spikesPeakOffsetP, templateController.getAllTemplatesPeaksOffset(), (uint32_t)MAXIMUM_NUMBER_OF_TEMPLATES, (uint32_t)1, (uint16_t)sizeof(uint16_t));
	if (cudaStatus != cudaSuccess) return cudaStatus;
	
	/* Memory copy trained thresholds to GPU */
	float thresholdsArray[MAXIMUM_NUMBER_OF_TEMPLATES];
	for (uint32_t i = 0; i < MAXIMUM_NUMBER_OF_TEMPLATES; i++) { thresholdsArray[i] = classifierController.getTemplateThreshold(i + 1); }
	cudaStatus = MemCpyCUDAData(dev_thresholdsP, thresholdsArray, (uint32_t)MAXIMUM_NUMBER_OF_TEMPLATES, (uint32_t)1, (uint16_t)sizeof(USED_DATATYPE));
	
	host_FoundTimesCounters = new uint32_t[MAXIMUM_NUMBER_OF_TEMPLATES];
	host_FoundTimesP = new uint32_t[MAXIMUM_NUMBER_OF_TEMPLATES*MAXIMUM_PREDICTION_SAMPLES];

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
void SpikeDetectCUDA_RTP<T>::CUDACleanUpPrediction(void)
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

	delete host_FoundTimesCounters;
	delete host_FoundTimesP;
}

#endif
