///////////////////////////////////////////////////////////
//  NXCORController.h
//  Header:			 The class controlling the multiple instances of NXCOR.
//  Created on:      30-10-2017
//  Original author: MB
///////////////////////////////////////////////////////////
#ifndef NXCOR_CONTROLLER_H
#define NXCOR_CONTROLLER_H

#include "stdint.h"
#include "math.h"
#include <chrono>
#include "ProjectInfo.h"
#include "TemplateController.h"
#include "NXCOR.h"
#include "ProjectDefinitions.h"

using namespace std::chrono;
#ifdef USE_CUDA
extern "C" void NXCOR_CUDA_3D(float *dev_result, const float *dev_templates, const float *dev_signal, uint16_t templateLength, uint16_t templateChannels, 
								uint32_t signalLength, uint16_t signalChannels, uint16_t numberOfTemplates, uint16_t* dev_signalLowerIndex );
extern "C" void NXCOR_CUDA_3D_Drift(float *dev_result, const float *dev_templates, const float *dev_signal, uint16_t templateLength, uint16_t templateChannels, 
								uint32_t signalLength, uint16_t signalChannels, uint16_t numberOfTemplates, uint16_t* dev_signalLowerIndex );
#endif 

template <class T>
class NXCORController
{
public:
	/* Constructor */
	NXCORController(ProjectInfo *projectRef, TemplateController<T> *templateRef);
	~NXCORController(void);
	/* Handling functions */
	void performNXCORWithTemplates(T* signalPointer, uint32_t dataLenght);
#ifdef USE_CUDA
	void performNXCORWithTemplatesCUDA(T *dev_result, const T *dev_templates, const T *dev_signal, uint16_t templateLength, uint16_t templateChannels, uint32_t signalLength, uint16_t signalChannels, uint16_t numberOfTemplates, uint16_t* dev_signalLowerIndex);
#endif
	T* getFeatureForTemplate(uint32_t templateNumber);
	float getLatestExecutionTime(void);
private:
	/* Helper functions */
	high_resolution_clock::time_point t1;
	high_resolution_clock::time_point t2;
	float f_latestExecutionTime = 0;
	TemplateController<T>* templateControllerRefPtr;
	ProjectInfo * projectRefPtr;
	NXCOR<T> nxcor;
	T* arrayOfFeatures[MAXIMUM_NUMBER_OF_TEMPLATES];
};

/*----------------------------------------------------------------------------*/
/**
* @brief Constructor
*
* @param ProjectInfo *projectRef :            Pointer to the ProjectInfo class holding the project information.
* @param TemplateController<T>* templateRef : Pointer to the TemplateController class holding the templates.
*/
template <class T>
NXCORController<T>::NXCORController(ProjectInfo *projectRef, TemplateController<T> *templateRef)
	: nxcor(TEMPLATE_CROPPED_LENGTH, TEMPLATE_CROPPED_WIDTH, TRAINING_DATA_LENGTH)
{
	t1 = high_resolution_clock::now();
	/* Constructor */
	for (uint32_t i = 0; i < MAXIMUM_NUMBER_OF_TEMPLATES; i++)
	{
		if (projectRef->isTemplateUsedTraining(i + 1) > 0)
		{
			arrayOfFeatures[i] = new T[TRAINING_DATA_LENGTH -TEMPLATE_CROPPED_LENGTH];
		}
	}

	projectRefPtr = projectRef;
	templateControllerRefPtr = templateRef;

	t2 = high_resolution_clock::now();

	auto duration = duration_cast<microseconds>(t2 - t1).count();
	f_latestExecutionTime = (float)duration;
}

/*----------------------------------------------------------------------------*/
/**
* @brief Destructor
* @note Empty!
*/
template <class T>
NXCORController<T>::~NXCORController(void)
{
	
}

/*----------------------------------------------------------------------------*/
/**
* @brief Performs normalized cross correlation on the signal and the templates provided.
*
* @param T* signalPointer : Pointer to the array holding the signal.
*
* @retval void : none
*/
template <class T>
void NXCORController<T>::performNXCORWithTemplates(T* signalPointer, uint32_t dataLenght)
{
	t1 = high_resolution_clock::now();
	for (uint32_t i = 0; i < MAXIMUM_NUMBER_OF_TEMPLATES; i++)
	{
		if (projectRefPtr->isTemplateUsedTraining(i + 1) > 0)
		{
#ifdef USE_OPENCV
			nxcor.runNXCOROpenCV(arrayOfFeatures[i], signalPointer, templateControllerRefPtr->getCroppedTemplate(i + 1), TEMPLATE_CROPPED_LENGTH, TEMPLATE_CROPPED_WIDTH, dataLenght, templateControllerRefPtr->getTemplateLowerIndex(i+1));
#else
	#if NUMBER_OF_DRIFT_CHANNELS_HANDLED > 0
			nxcor.runNXCOR_STD(arrayOfFeatures[i], signalPointer, templateControllerRefPtr->getCroppedTemplate(i + 1), TEMPLATE_CROPPED_LENGTH, TEMPLATE_CROPPED_WIDTH, dataLenght, templateControllerRefPtr->getTemplateLowerIndex(i + 1), NUMBER_OF_DRIFT_CHANNELS_HANDLED);
	#else
			nxcor.runNXCOR(arrayOfFeatures[i], signalPointer, templateControllerRefPtr->getCroppedTemplate(i + 1), TEMPLATE_CROPPED_LENGTH, TEMPLATE_CROPPED_WIDTH, dataLenght, templateControllerRefPtr->getTemplateLowerIndex(i + 1));
	#endif
#endif
		}
	}

	t2 = high_resolution_clock::now();

	auto duration = duration_cast<microseconds>(t2 - t1).count();
	f_latestExecutionTime = (float)duration;
}

#ifdef USE_CUDA
/*----------------------------------------------------------------------------*/
/**
* @brief Performs normalized cross correlation on the signal and the templates provided.
*						CUDA VERSION
* @param T* signalPointer : Pointer to the array holding the signal.
*
* @retval void : none
*/
template <class T>
void NXCORController<T>::performNXCORWithTemplatesCUDA(T *dev_result, const T *dev_templates, const T *dev_signal, uint16_t templateLength, uint16_t templateChannels, uint32_t signalLength, uint16_t signalChannels, uint16_t numberOfTemplates, uint16_t* dev_signalLowerIndex)
{
	t1 = high_resolution_clock::now();
	
#if NUMBER_OF_DRIFT_CHANNELS_HANDLED > 0
	NXCOR_CUDA_3D_Drift(dev_result, dev_templates, dev_signal, templateLength, templateChannels, signalLength, signalChannels, numberOfTemplates, dev_signalLowerIndex);
#else
	NXCOR_CUDA_3D(dev_result, dev_templates, dev_signal, templateLength, templateChannels, signalLength, signalChannels, numberOfTemplates, dev_signalLowerIndex);

#endif
	
	t2 = high_resolution_clock::now();

	auto duration = duration_cast<microseconds>(t2 - t1).count();
	f_latestExecutionTime = (float)duration;
}
#endif

/*----------------------------------------------------------------------------*/
/**
* @brief Returns the features for a specific template.
*
* @param uint32_t templateNumber : Indicates the template of interest.
*
* @retval T* : The pointer holding the features from each template.
*/
template <class T>
T* NXCORController<T>::getFeatureForTemplate(uint32_t templateNumber)
{
	return arrayOfFeatures[templateNumber - 1];
}

/*----------------------------------------------------------------------------*/
/**
* @brief Return the latest execution for either of the algorithms
*
* @retval float : The execution time in microseconds (us)
*/
template <class T>
float NXCORController<T>::getLatestExecutionTime(void)
{
	return f_latestExecutionTime;
}

#endif