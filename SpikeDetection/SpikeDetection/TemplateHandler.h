///////////////////////////////////////////////////////////
//  TemplateHandler.h
//  Header:          Functions and handles used opun the templates
//  Created on:      25-10-2017
//  Original author: MB
///////////////////////////////////////////////////////////
#ifndef TEMPLATE_HANDLER_H
#define TEMPLATE_HANDLER_H

#include "stdint.h"
#include "math.h"
#include "DataLoader.h"
#include "KernelFilter.h"
#include "ProjectDefinitions.h"
#include <chrono>
#ifdef USE_OPENCV
	#include <opencv2\opencv.hpp>
	using namespace cv;
#endif

using namespace std::chrono;

template <class T>
class TemplateHandler
{
public:	
	/* Constructor */
	TemplateHandler(uint32_t templateID, std::string pathToTemplate, KernelFilter<T> * kernelFilterPointer);
	/* Template handling functions */
	T* getCroppedTemplate(void);
	uint32_t getTemplateChannelLowerIndex(void);
	uint32_t getTemplateChannelUpperIndex(void);
	uint32_t getPeakOffset(void);
	/* Debug */
	void testClass(void);
private:
	/* Helper functions */
#ifdef USE_OPENCV
	void convertArrayToCVMat(cv::Mat returnObject, T* array_, uint32_t signalLength, uint32_t signalWidth);
	void findTemplateInfoOpenCV(uint32_t* mainchannel, uint32_t * peakoffset, T* templatePtr, uint32_t templateLength, uint32_t templateWidth);
#endif
	void findTemplateInfo(uint32_t* mainchannel, uint32_t * peakoffset, T* templatePtr, uint32_t templateLength, uint32_t templateWidth);
	void chooseSamples(uint32_t* lowerChannelIndex, uint32_t* upperChannelIndex, uint32_t centerChannel, uint32_t wantedchannelSize, uint32_t maximumNumberOfChannels);
	void cropTemplate(T* templatePtr, T* templateReturn, uint32_t wantedTemplateLength, uint32_t wantedTemplateWidth, uint32_t currentTemplateLength, uint32_t currentTemplateWidth);
	
	DataLoader<T> templateLoader;
	uint32_t templateID_;
	T* templateDataPointer_;
	T* filteredtemplateDataPointer_;
	uint32_t templateLength;
	uint32_t templateWidth;
	uint32_t channelIndexLower;
	uint32_t channelIndexUpper;
	uint32_t templateMainChannel;
	uint32_t templatePeakOffset;

	high_resolution_clock::time_point t1;
	high_resolution_clock::time_point t2;
	float f_latestExecutionTime = 0;
};

/*----------------------------------------------------------------------------*/
/**
* @brief Constructor
*
* @param uint32_t templateID :                   Indicates the template ID.
* @param std::string pathToTemplate :            The path for the templates.
* @param KernelFilter<T> * kernelFilterPointer : The pointer for the KernelFilter class.
*/
template <class T>
TemplateHandler<T>::TemplateHandler(uint32_t templateID, std::string pathToTemplate, KernelFilter<T> * kernelFilterPointer) :
	templateLoader(pathToTemplate, TEMPLATE_ORIGINAL_WIDTH, TEMPLATE_ORIGINAL_LENGTH, DataLoader<USED_DATATYPE>::FLOAT)
{
	templateID_ = templateID;
	templateLength = TEMPLATE_ORIGINAL_LENGTH;
	templateWidth = TEMPLATE_ORIGINAL_WIDTH;

	filteredtemplateDataPointer_ = new T[TEMPLATE_CROPPED_LENGTH*TEMPLATE_CROPPED_WIDTH];

#ifdef USE_KERNEL_FILTER
	templateDataPointer_ = new T[TEMPLATE_CROPPED_LENGTH*TEMPLATE_CROPPED_WIDTH];
	cropTemplate(templateLoader.getDataPointer(), templateDataPointer_, TEMPLATE_CROPPED_LENGTH, TEMPLATE_CROPPED_WIDTH, templateLength, templateWidth);

	kernelFilterPointer->runFilterReplicate(filteredtemplateDataPointer_, templateDataPointer_, DEFAULT_KERNEL_DIM, TEMPLATE_CROPPED_LENGTH, TEMPLATE_CROPPED_WIDTH);
	
	delete templateDataPointer_;
#else
	// Don't 2D filter template when kernel filter not used
	cropTemplate(templateLoader.getDataPointer(), filteredtemplateDataPointer_, TEMPLATE_CROPPED_LENGTH, TEMPLATE_CROPPED_WIDTH, templateLength, templateWidth);
#endif

}

/*----------------------------------------------------------------------------*/
/**
* @brief Finds the channel and the offset of the main spike in a template
* @notes - Is equavalient to finding the smallest value in the template!
*
* @param uint32_t* mainchannel :   Pointer to location where the channel of the spikes is stored
* @param uint32_t * peakoffset :   Pointer to location where the offset of the spikes is stored
* @param T* templatePtr :          Pointer to the template
* @param uint32_t templateLength : Indicates the length of the supplied template
* @param uint32_t templateWidth :  Indicates the width of the supplied template
*
* @retval void : none
*/
template <class T>
void TemplateHandler<T>::findTemplateInfo(uint32_t* mainchannel, uint32_t * peakoffset, T* templatePtr, uint32_t templateLength, uint32_t templateWidth)
{
	T savedMin = templatePtr[0];
	uint32_t savedX = 0;
	uint32_t savedY = 0;

	for (uint32_t x = 0; x < templateLength; x++)
	{
		for (uint32_t y = 0; y < templateWidth; y++)
		{
			if (templatePtr[(x*templateWidth) + y] < savedMin)
			{
				savedMin = templatePtr[(x*templateWidth) + y];
				savedX = x;
				savedY = y;
			}
		}
	}

	if (savedX >= 1)
		*peakoffset = savedX - 1;
	else
		*peakoffset = savedX;

	*mainchannel = savedY; // this is a error - but should never happen
}



#ifdef USE_OPENCV
/*----------------------------------------------------------------------------*/
/**
* @brief Finds the channel and the offset of the main spike in a template
* @notes - Is equavalient to finding the smallest value in the template!
*				THIS USING OPENCV IMPL.
*
* @param uint32_t* mainchannel :   Pointer to location where the channel of the spikes is stored
* @param uint32_t * peakoffset :   Pointer to location where the offset of the spikes is stored
* @param T* templatePtr :          Pointer to the template
* @param uint32_t templateLength : Indicates the length of the supplied template
* @param uint32_t templateWidth :  Indicates the width of the supplied template
*
* @retval void : none
*/
template <class T>
void TemplateHandler<T>::findTemplateInfoOpenCV(uint32_t* mainchannel, uint32_t * peakoffset, T* templatePtr, uint32_t templateLength, uint32_t templateWidth)
{
	cv::Mat tmpMatObject(templateWidth, templateLength, CV_32FC1);

	convertArrayToCVMat(tmpMatObject, templatePtr, templateLength, templateWidth);

	double minVal; double maxVal; Point minLoc; Point maxLoc; Point matchLoc;

	minMaxLoc(tmpMatObject, &minVal, &maxVal, &minLoc, &maxLoc, Mat());

	
	if(minLoc.x >= 1)
		*peakoffset = minLoc.x - 1; 
	else
		*peakoffset = minLoc.x; // thos is a error - but should never happen

	*mainchannel = minLoc.y; 

}


/*----------------------------------------------------------------------------*/
/**
* @brief Converts a 1D array into a CV::Mat object.
*
* @param cv::Mat returnObject :  OpenCV Mat to store the data in (2D)
* @param T* array_ :             Pointer to the array holding the data - 1D
* @param uint32_t signalLength : Indicates the signal length
* @param uint32_t signalWidth :  Indicates the signal width
*
* @retval void : none
*/
template <class T>
void TemplateHandler<T>::convertArrayToCVMat(cv::Mat returnObject, T* array_, uint32_t signalLength, uint32_t signalWidth)
{
	uint32_t x = 0;
	uint32_t y = 0;

	for (uint32_t i = 0; i < (signalWidth * signalLength); i++)
	{
		returnObject.at<T>(x, y) = array_[i];
		x++;
		if (x >= signalWidth)
		{
			x = 0;
			y++;
		}
	}
}
#endif

/*----------------------------------------------------------------------------*/
/**
* @brief Crops a given template to a smaller dimension, using the templates
*			main spike as the center.
*
* @param T* templatePtr:                 Pointer to the origianl template
* @param T* templateReturn:              Pointer to the cropped template
* @param uint32_t wantedTemplateLength:  The wanted length of the cropped template
* @param uint32_t wantedTemplateWidth:   The wanted width of the cropped template
* @param uint32_t currentTemplateLength: The current template length
* @param uint32_t currentTemplateWidth:  The current template width
*
* @retval void : none
*/
template <class T>
void TemplateHandler<T>::cropTemplate(T* templatePtr, T* templateReturn, uint32_t wantedTemplateLength, uint32_t wantedTemplateWidth, uint32_t currentTemplateLength, uint32_t currentTemplateWidth)
{
	uint32_t mainChannel;
	uint32_t peakoffset;

#ifdef USE_OPENCV
	findTemplateInfoOpenCV(&mainChannel, &peakoffset, templatePtr, currentTemplateLength, currentTemplateWidth);
#else
	findTemplateInfo(&mainChannel, &peakoffset, templatePtr, currentTemplateLength, currentTemplateWidth);
#endif 

	templateMainChannel = mainChannel;
	templatePeakOffset = peakoffset;

	uint32_t channelUpperIndex;
	uint32_t channelLowerIndex;
	chooseSamples(&channelLowerIndex, &channelUpperIndex, mainChannel, wantedTemplateWidth, currentTemplateWidth);

	channelIndexLower = channelLowerIndex;
	channelIndexUpper = channelUpperIndex;

	uint32_t samplesUpperIndex;
	uint32_t samplesLowerIndex;
	chooseSamples(&samplesLowerIndex, &samplesUpperIndex, peakoffset, wantedTemplateLength, currentTemplateLength);

	// select samples from the original 
	for (uint32_t x = samplesLowerIndex; x <= samplesUpperIndex; x++)
	{
		for (uint32_t y = channelLowerIndex; y <= channelUpperIndex; y++)
		{
			templateReturn[((x - samplesLowerIndex)*wantedTemplateWidth) + (y - channelLowerIndex)] = templatePtr[(x*currentTemplateWidth) + y];
		}
	}

	templateLength = wantedTemplateLength;
	templateWidth = wantedTemplateWidth;
}

/*----------------------------------------------------------------------------*/
/**
* @brief Finds the start and end indencies for the specific subset length or width
*
* @param uint32_t* lowerChannelIndex :     Pointer to location where the lower index is stored
* @param uint32_t* upperChannelIndex:      Pointer to location where the upper index is stored
* @param uint32_t uint32_t centerChannel:  The center of the subset
* @param uint32_t wantedchannelSize:       The wanted length/width of the subset
* @param uint32_t maximumNumberOfChannels: The maximum length/width of the original set
*
* @retval void : none
*/
template <class T>
void TemplateHandler<T>::chooseSamples(uint32_t* lowerChannelIndex, uint32_t* upperChannelIndex, uint32_t centerChannel, uint32_t wantedchannelSize, uint32_t maximumNumberOfChannels)
{
	maximumNumberOfChannels--; // nul indexing in C

	if (wantedchannelSize % 2 == 0 || wantedchannelSize>maximumNumberOfChannels || centerChannel>maximumNumberOfChannels)
	{
		*lowerChannelIndex = 0;
		*upperChannelIndex = maximumNumberOfChannels;
		return;
	}

	int32_t minChannelNumber = centerChannel - (int32_t)floor(wantedchannelSize / 2);
	int32_t maxChannelNumber = centerChannel + (int32_t)floor(wantedchannelSize / 2);

	if (minChannelNumber < 0)
	{
		int32_t minChannelRest = (int32_t)abs(floor(minChannelNumber));
		minChannelNumber = 0;
		if ((maxChannelNumber + minChannelRest) < (int32_t)maximumNumberOfChannels)
		{
			maxChannelNumber = maxChannelNumber + minChannelRest;
		}
	}

	if (maxChannelNumber > (int32_t)maximumNumberOfChannels)
	{
		int32_t maxChannelRest = (int32_t)abs(floor(maxChannelNumber) - maximumNumberOfChannels);
		maxChannelNumber = maximumNumberOfChannels;
		if ((minChannelNumber - maxChannelRest) >= 0)
		{
			minChannelNumber = minChannelNumber - maxChannelRest;
		}
	}

	*lowerChannelIndex = minChannelNumber;
	*upperChannelIndex = maxChannelNumber;
}


/*----------------------------------------------------------------------------*/
/**
* @brief Test function used for debugging and testing methods
*
* @retval void : none
*/
template <class T>
void TemplateHandler<T>::testClass()
{
	const uint32_t fullTemplateLength = 61;
	const uint32_t fullTemplateWidth = 32;
	const uint32_t croppedTemplateLength = 17;
	const uint32_t croppedTemplateWitdh = 9;

	bool testSucces = true;
	DataLoader<T> Template1("C:/Users/Morten Buhl/Dropbox/Master Engineer/Master Thesis/Generated_Emouse_Data/Simulation_10min_30kHz_DefVals/FilteredData/croppedTemplate1.bin", croppedTemplateWitdh, croppedTemplateLength, DataLoader<T>::FLOAT);
	DataLoader<T> TemplateFull("C:/Users/Morten Buhl/Dropbox/Master Engineer/Master Thesis/Generated_Emouse_Data/Simulation_10min_30kHz_DefVals/FilteredData/rawTemplateFullSize.bin", fullTemplateWidth, fullTemplateLength, DataLoader<T>::FLOAT);

	uint32_t mainChannel1;
	uint32_t peakOffset1;
	uint32_t mainChannel2;
	uint32_t peakOffset2;

	t1 = high_resolution_clock::now();
	findTemplateInfo(&mainChannel1, &peakOffset1, TemplateFull.getDataPointer(), 61, 32);
	t2 = high_resolution_clock::now();
	auto duration = duration_cast<microseconds>(t2 - t1).count();
	std::cout << "findTemplateInfo exectionTime: " << duration << " us" << std::endl;

#ifdef USE_OPENCV
	t1 = high_resolution_clock::now();
	findTemplateInfoOpenCV(&mainChannel2, &peakOffset2, TemplateFull.getDataPointer(), 61, 32);
	t2 = high_resolution_clock::now();
	duration = duration_cast<microseconds>(t2 - t1).count();
	std::cout << "findTemplateInfoOpenCV exectionTime: " << duration << " us" << std::endl;

	if (mainChannel2 != mainChannel1 || peakOffset1 != peakOffset2)
	testSucces = false;
#endif

	uint32_t channelUpperIndex;
	uint32_t channelLowerIndex;
	t1 = high_resolution_clock::now();
	chooseSamples(&channelLowerIndex, &channelUpperIndex, mainChannel1, croppedTemplateWitdh, fullTemplateWidth);
	t2 = high_resolution_clock::now();
	duration = duration_cast<microseconds>(t2 - t1).count();
	std::cout << "chooseSamples(Width) exectionTime: " << duration << " us" << std::endl;

	uint32_t samplesUpperIndex;
	uint32_t samplesLowerIndex;
	t1 = high_resolution_clock::now();
	chooseSamples(&samplesLowerIndex, &samplesUpperIndex, peakOffset1, croppedTemplateLength, fullTemplateLength);
	t2 = high_resolution_clock::now();
	duration = duration_cast<microseconds>(t2 - t1).count();
	std::cout << "chooseSamples(Length) exectionTime: " << duration << " us" << std::endl;

	if (channelLowerIndex != 0 ||
		channelUpperIndex != 8 ||
		samplesLowerIndex != 10 ||
		samplesUpperIndex != 26)
	{
		testSucces = false;
	}


	T croppedArray[croppedTemplateLength*croppedTemplateWitdh];
	t1 = high_resolution_clock::now();
	cropTemplate(TemplateFull.getDataPointer(), croppedArray, croppedTemplateLength, croppedTemplateWitdh, fullTemplateLength, fullTemplateWidth);
	t2 = high_resolution_clock::now();
	duration = duration_cast<microseconds>(t2 - t1).count();
	std::cout << "cropTemplate exectionTime: " << duration << " us" << std::endl;


	for (int32_t i = 0; i < croppedTemplateLength*croppedTemplateWitdh; i++)
	{
		if (((int32_t)croppedArray[i]) * 10 != ((int32_t)Template1.getDataPointer()[i]) * 10)
		{
			if (((croppedArray[i] * 10) > ((Template1.getDataPointer()[i] * 10) + 2)) ||
				((croppedArray[i] * 10) < ((Template1.getDataPointer()[i] * 10) - 2)) ||
				((Template1.getDataPointer()[i] * 10) > ((croppedArray[i] * 10) + 2)) ||
				((Template1.getDataPointer()[i] * 10) < ((croppedArray[i] * 10) - 2)))

			{
				testSucces = false;
			}
		}
	}


	if (testSucces)
	{
		std::cout << "The test succeded!" << std::endl;
	}
	else
	{
		std::cout << "The test failed!" << std::endl;
	}
}

/*----------------------------------------------------------------------------*/
/**
* @brief Returns the cropped template
*
* @retval T* : The pointer for the cropped template.
*/
template <class T>
T* TemplateHandler<T>::getCroppedTemplate(void)
{
	return filteredtemplateDataPointer_;
}

/*----------------------------------------------------------------------------*/
/**
* @brief Returns the lower index at which the template should be applied
*
* @retval uint32_t : Index indicating the lower channel number the template should be applied to
*/
template <class T>
uint32_t TemplateHandler<T>::getTemplateChannelLowerIndex(void)
{
	return channelIndexLower;
}

/*----------------------------------------------------------------------------*/
/**
* @brief Returns the higher index at which the template should be applied
*
* @retval uint32_t : Index indicating the higher channel number the template should be applied to
*/
template <class T>
uint32_t TemplateHandler<T>::getTemplateChannelUpperIndex(void)
{
	return channelIndexUpper;
}

/*----------------------------------------------------------------------------*/
/**
* @brief Return the peak offset in samples according to the specific template
*
* @retval uint32_t : Return the peakoffset in samples
*/
template <class T>
uint32_t TemplateHandler<T>::getPeakOffset(void)
{
	return templatePeakOffset;
}

#endif