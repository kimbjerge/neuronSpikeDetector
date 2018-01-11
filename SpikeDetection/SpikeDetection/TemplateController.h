///////////////////////////////////////////////////////////
//  Template.h
//  Header:          Class holding template information
//  Created on:      27-10-2017
//  Original author: MB
///////////////////////////////////////////////////////////
#ifndef TEMPLATE_H
#define TEMPLATE_H

#include "stdint.h"
#include "math.h"
#include <chrono>

#include "TTClassifier.h"
#include "KernelFilter.h"
#include "DataLoader.h"
#include "TemplateHandler.h"
#include "ProjectDefinitions.h"
#include "ProjectInfo.h"

using namespace std::chrono;

template <class T>
class TemplateController
{
public:
	/* Constructor */
	TemplateController(ProjectInfo *projectRef, KernelFilter<T> * kernelFilterPointer);
	/* Template handling functions */
	T* getCroppedTemplate(uint32_t number);
	T* getAllCroppedTemplates(void);
	uint16_t* getAllTemplatesLowerIndex(void);
	uint16_t* getAllTemplatesPeaksOffset(void);
	uint32_t getTemplateLowerIndex(uint32_t number);
	uint32_t getTemplateUpperIndex(uint32_t number);
	uint32_t getTemplatePeakOffset(uint32_t number);
private:
	/* Helper functions */
	TemplateHandler<T>* arrayOfTemplates[MAXIMUM_NUMBER_OF_TEMPLATES] = { NULL };
	T* combinedArrayOfTemplates;
	uint16_t* combinedLowerIndexArrayOfTemplates;
	uint16_t* combinedArrayOfTemplatespeaksOffsets;
	high_resolution_clock::time_point t1;
	high_resolution_clock::time_point t2;
	float f_latestExecutionTime = 0;
};

/*----------------------------------------------------------------------------*/
/**
* @brief Constructor
*
* @param ProjectInfo *projectRef :               Pointer to the ProjectInfo class holding the project information.
* @param KernelFilter<T> * kernelFilterPointer : Pointer to the KernelFilter class.
*/
template <class T>
TemplateController<T>::TemplateController(ProjectInfo *projectRef, KernelFilter<T> * kernelFilterPointer)
{
	combinedArrayOfTemplates = new T[TEMPLATE_CROPPED_WIDTH*TEMPLATE_CROPPED_LENGTH*MAXIMUM_NUMBER_OF_TEMPLATES];
	combinedLowerIndexArrayOfTemplates = new uint16_t[MAXIMUM_NUMBER_OF_TEMPLATES];
	combinedArrayOfTemplatespeaksOffsets = new uint16_t[MAXIMUM_NUMBER_OF_TEMPLATES];

	for (uint32_t i = 0; i < MAXIMUM_NUMBER_OF_TEMPLATES; i++)
	{
		std::string templatePath = PATH_TO_TEMPLATES;
		std::string completeString = templatePath + std::to_string(i + 1) + ".bin";
		arrayOfTemplates[i] = new TemplateHandler<T>(i + 1, completeString, kernelFilterPointer);

		combinedLowerIndexArrayOfTemplates[i] = (uint16_t)getTemplateLowerIndex(i + 1);
		combinedArrayOfTemplatespeaksOffsets[i] = (uint16_t)getTemplatePeakOffset(i + 1);

		for (uint32_t x = 0; x < TEMPLATE_CROPPED_LENGTH; x++)
		{
			for (uint32_t y = 0; y < TEMPLATE_CROPPED_WIDTH; y++)
			{
				combinedArrayOfTemplates[(TEMPLATE_CROPPED_WIDTH*TEMPLATE_CROPPED_LENGTH*i) + (x*TEMPLATE_CROPPED_WIDTH) + y] = arrayOfTemplates[i]->getCroppedTemplate()[(x*TEMPLATE_CROPPED_WIDTH) + y];
			}
		}
	}
}

/*----------------------------------------------------------------------------*/
/**
* @brief Returns the pointer for a specific cropped template determined by the parameter.
*
* @param uint32_t number : Indicates the specific template, desired.
*
* @retval T* : The pointer for the cropped template.
*/
template <class T>
T* TemplateController<T>::getCroppedTemplate(uint32_t number)
{
	if (arrayOfTemplates[number - 1] != NULL)
	{
		return arrayOfTemplates[number - 1]->getCroppedTemplate();
	}
	else
	{
		return NULL;
	}
}

/*----------------------------------------------------------------------------*/
/**
* @brief Returns the channel at which the template should be applied from
*
* @param uint32_t number : Indicates the specific template, desired.
*
* @retval uint32_t : Indicates the start channel of where the template should be applied from
*/
template <class T>
uint32_t TemplateController<T>::getTemplateLowerIndex(uint32_t number)
{
	return arrayOfTemplates[number - 1]->getTemplateChannelLowerIndex();
}

/*----------------------------------------------------------------------------*/
/**
* @brief Returns the channel at which the template should be applied from
*
* @param uint32_t number : Indicates the specific template, desired.
*
* @retval uint32_t : Indicates the start channel of where the template should be applied to
*/
template <class T>
uint32_t TemplateController<T>::getTemplateUpperIndex(uint32_t number)
{
	return arrayOfTemplates[number - 1]->getTemplateChannelUpperIndex();
}

/*----------------------------------------------------------------------------*/
/**
* @brief returns the spike peak offset within the full template
* @note Kilosort seems to place the spike at 19 samples along
* @param uint32_t number : Indicates the specific template, desired.
*
* @retval uint32_t : returns the peak offset in samples
*/
template <class T>
uint32_t TemplateController<T>::getTemplatePeakOffset(uint32_t number)
{
	return arrayOfTemplates[number - 1]->getPeakOffset();
}

/*----------------------------------------------------------------------------*/
/**
* @brief returns all templates combined
*
* @param none
*
* @retval T* : The pointer for the all cropped templates combined.
*/
template <class T>
T* TemplateController<T>::getAllCroppedTemplates(void)
{
	return combinedArrayOfTemplates;
}

/*----------------------------------------------------------------------------*/
/**
* @brief returns all templates combined
*
* @param none
*
* @retval T* : The pointer for the all cropped templates combined.
*/
template <class T>
uint16_t* TemplateController<T>::getAllTemplatesLowerIndex(void)
{
	return combinedLowerIndexArrayOfTemplates;
}

/*----------------------------------------------------------------------------*/
/**
* @brief returns all templates peaks combined
*
* @param none
*
* @retval T* : The pointer for the peaks of the templates
*/
template <class T>
uint16_t* TemplateController<T>::getAllTemplatesPeaksOffset(void)
{
	return combinedArrayOfTemplatespeaksOffsets;
}

#endif