///////////////////////////////////////////////////////////
//  SpikeDetection.h
//  Header:          Spike Detect Class (C++ and OpenCV)
//  Created on:      06-02-2018
//  Original author: MB/KBE
///////////////////////////////////////////////////////////
#ifndef SPIKE_DETECT_H
#define SPIKE_DETECT_H

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

template <class T>
class SpikeDetect
{
public:
	/* Constructor */
	SpikeDetect();
	/* Methods */
	virtual void runTraining(void);
	virtual void runPrediction(void);
	/* Helper functions */
	float getLatestExecutionTime(void);
	ProjectInfo *getProjectInfo(void) { return &projectInfo; };
protected:
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
};

/*----------------------------------------------------------------------------*/
/**
* @brief Constructor
* @note Empty!
*/
template <class T>
SpikeDetect<T>::SpikeDetect() :
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
float SpikeDetect<T>::getLatestExecutionTime(void)
{
	return f_latestExecutionTime;
}

/*----------------------------------------------------------------------------*/
/**
* @brief The training of the model.
*
* @retval void : none
*/
template <class T>
void SpikeDetect<T>::runTraining(void)
{
	std::cout << "************* TRAINING **************" << std::endl;

	t1 = high_resolution_clock::now();

	/**** 1D Filter ****/
	USED_DATATYPE* filteredResults = new USED_DATATYPE[(uint32_t)(TRAINING_DATA_LENGTH*DATA_CHANNELS)];
	channelFilter.runFilter(filteredResults, projectInfo.getTraningData(), DATA_CHANNELS, TRAINING_DATA_LENGTH);
#ifdef PRINT_OUTPUT_INFO
	std::cout << "1D filtering time: " << channelFilter.getLatestExecutionTime() / 1000 << " ms. processing " << TRAINING_DATA_TIME << " seconds of data" << std::endl;
#endif


	/**** 2D Filter ****/
#ifdef USE_KERNEL_FILTER

#ifdef USE_OPENCV
	USED_DATATYPE* kernelResults = new USED_DATATYPE[(uint32_t)(TRAINING_DATA_LENGTH*DATA_CHANNELS)];
	kernelFilter.runFilterOpenCV(kernelResults, filteredResults, DEFAULT_KERNEL_DIM, TRAINING_DATA_LENGTH, DATA_CHANNELS);
#ifdef PRINT_OUTPUT_INFO
	std::cout << "2D OpenCV filtering time: " << kernelFilter.getLatestExecutionTime() / 1000 << " ms. processing " << TRAINING_DATA_TIME << " seconds of data" << std::endl;
#endif	
#else
	USED_DATATYPE* kernelResults = new USED_DATATYPE[(uint32_t)(TRAINING_DATA_LENGTH*DATA_CHANNELS)];
	kernelFilter.runFilterReplicate(kernelResults, filteredResults, DEFAULT_KERNEL_DIM, TRAINING_DATA_LENGTH, DATA_CHANNELS);
#ifdef PRINT_OUTPUT_INFO
	std::cout << "2D filtering time: " << kernelFilter.getLatestExecutionTime() / 1000 << " ms. processing " << TRAINING_DATA_TIME << " seconds of data" << std::endl;
#endif	
#endif
	/**** NXCOR Filter ****/
	nxcorController.performNXCORWithTemplates(kernelResults, TRAINING_DATA_LENGTH);
	delete kernelResults;
#else

	/**** NXCOR Filter without kernel filter ****/
	nxcorController.performNXCORWithTemplates(filteredResults, TRAINING_DATA_LENGTH);
#endif

#ifdef PRINT_OUTPUT_INFO
	std::cout << "NXCOR all templates time: " << nxcorController.getLatestExecutionTime() / 1000 << " ms. processing " << TRAINING_DATA_TIME << " seconds of data" << std::endl;
#endif


	/**** TRAIN ****/
	classifierController.performTrainingBasedOnTemplates(&nxcorController, &templateController);
#ifdef PRINT_OUTPUT_INFO
	std::cout << "Train all template models time: " << classifierController.getLatestExecutionTime() / 1000 << " ms. processing " << TRAINING_DATA_TIME << " seconds of data" << std::endl;
#endif

	delete filteredResults;

	t2 = high_resolution_clock::now();
	auto duration = duration_cast<microseconds>(t2 - t1).count();
	f_latestExecutionTime = (float)duration;
#ifdef PRINT_OUTPUT_INFO
	std::cout << "Total CPU Training time: " << f_latestExecutionTime / 1000 << " ms. processing " << TRAINING_DATA_TIME << " seconds of data" << std::endl;
#endif

}

/*----------------------------------------------------------------------------*/
/**
* @brief The testing/prediction loop using the trained model upon new data.
*
* @retval void : none
*/
template <class T>
void SpikeDetect<T>::runPrediction(void)
{
	std::cout << "************* PREDICTION **************" << std::endl;

	t1 = high_resolution_clock::now();

	// 1D Filter 
	USED_DATATYPE* filteredResults = new USED_DATATYPE[(uint32_t)(RUNTIME_DATA_LENGTH*DATA_CHANNELS)];
	channelFilter.runFilter(filteredResults, projectInfo.getPredictionData(), DATA_CHANNELS, RUNTIME_DATA_LENGTH);
#ifdef PRINT_OUTPUT_INFO
	std::cout << "1D filtering time: " << channelFilter.getLatestExecutionTime() / 1000 << " ms. processing " << RUNTIME_DATA_TIME << " seconds of data" << std::endl;
#endif

	// 2D Filter 
#ifdef USE_KERNEL_FILTER

#ifdef USE_OPENCV
	USED_DATATYPE* kernelResults = new USED_DATATYPE[(uint32_t)(RUNTIME_DATA_LENGTH*DATA_CHANNELS)];
	kernelFilter.runFilterOpenCV(kernelResults, filteredResults, DEFAULT_KERNEL_DIM, RUNTIME_DATA_LENGTH, DATA_CHANNELS);
#ifdef PRINT_OUTPUT_INFO
	std::cout << "2D OpenCV filtering time: " << kernelFilter.getLatestExecutionTime() / 1000 << " ms. processing " << RUNTIME_DATA_TIME << " seconds of data" << std::endl;
#endif
#else
	USED_DATATYPE* kernelResults = new USED_DATATYPE[(uint32_t)(RUNTIME_DATA_LENGTH*DATA_CHANNELS)];
	kernelFilter.runFilterReplicate(kernelResults, filteredResults, DEFAULT_KERNEL_DIM, RUNTIME_DATA_LENGTH, DATA_CHANNELS);
#ifdef PRINT_OUTPUT_INFO
	std::cout << "2D filtering time: " << kernelFilter.getLatestExecutionTime() / 1000 << " ms. processing " << RUNTIME_DATA_TIME << " seconds of data" << std::endl;
#endif
#endif

	/**** NXCOR Filter ****/
	nxcorController.performNXCORWithTemplates(kernelResults, RUNTIME_DATA_LENGTH);
	delete kernelResults;
#else
	/**** NXCOR Filter without kernel filter****/
	nxcorController.performNXCORWithTemplates(filteredResults, RUNTIME_DATA_LENGTH);
#endif

#ifdef PRINT_OUTPUT_INFO
	std::cout << "NXCOR all templates time: " << nxcorController.getLatestExecutionTime() / 1000 << " ms. processing " << RUNTIME_DATA_TIME << " seconds of data" << std::endl;
#endif

	// Predict
	classifierController.performPredictionBasedOnTemplates(&nxcorController, &templateController);
#ifdef PRINT_OUTPUT_INFO
	std::cout << "Prediction, all models time: " << classifierController.getLatestExecutionTime() / 1000 << " ms. processing " << RUNTIME_DATA_TIME << " seconds of data" << std::endl;
#endif

	// TODO:
	// Make the arrays static instead an save time by avoiding Allocation and deallocation runtime!!
	delete filteredResults;

	t2 = high_resolution_clock::now();
	auto duration = duration_cast<microseconds>(t2 - t1).count();
	f_latestExecutionTime = (float)duration;
#ifdef PRINT_OUTPUT_INFO
	std::cout << "Total CPU Prediction time: " << f_latestExecutionTime / 1000 << " ms. processing " << RUNTIME_DATA_TIME << " seconds of data" << std::endl;
#endif

}


#endif