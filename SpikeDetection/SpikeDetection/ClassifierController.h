///////////////////////////////////////////////////////////
//  ClassifierController.h
//  Header:          The class is used to control the multiple instances of TTClassifiers.
//  Created on:      30-10-2017
//  Original author: MB
///////////////////////////////////////////////////////////
#ifndef CLASSIFIER_CONTROLLER_H
#define CLASSIFIER_CONTROLLER_H
#include "stdint.h"
#include "math.h"
#include <chrono>
#include "ProjectInfo.h"
#include "TTClassifier.h"
#include "NXCORController.h"
#include "TemplateController.h"
#include "ProjectDefinitions.h"

using namespace std::chrono;

#ifdef USE_CUDA
extern "C" void TrainPart1CUDA(const float *dev_signal, char *dev_aboveThreshold, uint32_t *dev_foundTimes, uint32_t *dev_foundTimesCounter,
	uint32_t *dev_TPCounter, uint16_t *dev_peaksOffsets, uint32_t *devTruthTable, uint32_t *devTruthTableSize,
	uint32_t *devTruthTableStartInd, uint16_t templateLength, uint32_t signalLength, uint16_t numberOfTemplates, float threshold);

extern "C" void PredictCUDA(const float *dev_signal, char *dev_aboveThreshold, uint32_t *dev_foundTimes, uint32_t *dev_foundTimesCounter,
							uint16_t templateLength, uint32_t signalLength, uint16_t numberOfTemplates, float *dev_threshold);
#endif


template <class T>
class ClassifierController
{
public:
	/* Constructor */
	ClassifierController(ProjectInfo *projectRef);
	~ClassifierController(void);
	/* Handling functions */
	void performTrainingBasedOnTemplates(NXCORController<T>* nxcorRef, TemplateController<T> * templateController);
#ifdef USE_CUDA
	void performTrainingBasedOnTemplatesPart1_CUDA(const T *dev_signal, char *dev_aboveThreshold, uint32_t *dev_foundTimes, uint32_t *dev_foundTimesCounter,
												   uint32_t *dev_TPCounter, uint16_t *dev_peaksOffsets, uint32_t *devTruthTable, uint32_t *devTruthTableSize, uint32_t *devTruthTableStartInd);
	void performTrainingBasedOnTemplatesPart2(uint32_t *host_TPCounter, uint32_t *host_predictionSize);

	void performPredictionBasedOnTemplatesCUDA(const float *dev_signal, char *dev_aboveThreshold, uint32_t *dev_foundTimes, uint32_t *dev_foundTimesCounter, float *dev_threshold, uint32_t dataLength);
	void verifyPredictionBasedOnTemplatesCUDA(uint32_t* foundTimesCounter, uint32_t* foundTimesP, TemplateController<T> * templateController);
#endif	
	void performPredictionBasedOnTemplates(NXCORController<T>* nxcorRef, TemplateController<T> * templateController);
	float getTemplateThreshold(uint32_t number);
	float getLatestExecutionTime(void);

private:
	/* Helper functions */
	high_resolution_clock::time_point t1;
	high_resolution_clock::time_point t2;
	float f_latestExecutionTime = 0;
	ProjectInfo * projectInfoRefPtr;
	TTClassifier<T>* arrayOfClassifier[MAXIMUM_NUMBER_OF_TEMPLATES];

};

/*----------------------------------------------------------------------------*/
/**
* @brief Constructor
*
* @param ProjectInfo *projectRef : Pointer to the ProjectInfo class holding the project information.
*/
template <class T>
ClassifierController<T>::ClassifierController(ProjectInfo *projectRef)
{
	t1 = high_resolution_clock::now();
	/* Constructor */
	for (uint32_t i = 0; i < MAXIMUM_NUMBER_OF_TEMPLATES; i++)
	{
		if (projectRef->isTemplateUsedTraining(i + 1) > 0)
		{
			arrayOfClassifier[i] = new TTClassifier<T>(RECALL_WEIGHT, PRECISION_WEIGHT);
		}
	}

	projectInfoRefPtr = projectRef;

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
ClassifierController<T>::~ClassifierController(void)
{

}

/*----------------------------------------------------------------------------*/
/**
* @brief Performs training based on the amount of templates used.
* @note
*
* @param NXCORController<T>* nxcorControllerRef    :			Pointer to the NXCORController class holding the correspondence output.
* @param TemplateController<T>* templateController :		    Pointer to the TemplateController class holding the templates.
*
* @retval void : none
*/
template <class T>
void ClassifierController<T>::performTrainingBasedOnTemplates(NXCORController<T>* nxcorControllerRef, TemplateController<T>* templateController)
{
	t1 = high_resolution_clock::now();

	for (uint32_t i = 0; i < MAXIMUM_NUMBER_OF_TEMPLATES; i++)
	{
		uint32_t templatesInTrainData = projectInfoRefPtr->isTemplateUsedTraining(i + 1);
		if (templatesInTrainData > 0)
		{

			TTClassifier<T>* pointer = arrayOfClassifier[i];

#if 0 // KBE for debugging
			T* featuresForTemplate = nxcorControllerRef->getFeatureForTemplate(i + 1);
			std::cout << "T" << i + 1 << " features : ";
			for (int j = 0; j < 20; j++) printf("%0.4f, ", featuresForTemplate[j]);
			std::cout << std::endl;
#endif

			pointer->Train(nxcorControllerRef->getFeatureForTemplate(i + 1), projectInfoRefPtr->getTemplateTruthTableTraining(i+1), projectInfoRefPtr->isTemplateUsedTraining(i + 1), (TRAINING_DATA_LENGTH - TEMPLATE_CROPPED_LENGTH), templateController->getTemplatePeakOffset(i+1));

#ifdef PRINT_OUTPUT_INFO
			float wF1Score = pointer->calculateWF1Score(pointer->getLatestTrainingPrecision(), pointer->getLatestTrainingRecall());
			std::cout << "Train template: " << setw(2) << i + 1 << " thredshold: " << setw(4) << pointer->getThreshold() << " counts: " << setw(5) << templatesInTrainData << " W-F1 score: " << wF1Score << std::endl;
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
* @brief Performs training based on the amount of templates used.
* @note
*
* @param const T *dev_signal				: Device pointer to The NXCOR outputs
* @param char *dev_aboveThreshold			: Device pointer used to indicate which values is above threshold
* @param uint32_t *dev_foundTimes			: Device pointer to where the found times are located
* @param uint32_t *dev_foundTimesCounter	: Device pointer to the arays at which the found times counter values are stored
* @param uint32_t *dev_TPCounter			: Device pointer to where the TP scores are located
* @param uint16_t *dev_peaksOffsets			: Device pointer to the array at which the peakoffset score are located
* @param uint32_t *devTruthTable			: Device pointer to where the truth table is located
* @param uint32_t *devTruthTableSize		: Device pointer to an array indicating the size of the truth tables for each template
* @param uint32_t *devTruthTableStartInd    : Device pointer to array at which stores the start indecis for where in the truth table the template specific truth table starts.
*
* @retval void : none
*/
template <class T>
void ClassifierController<T>::performTrainingBasedOnTemplatesPart1_CUDA(const T *dev_signal, char *dev_aboveThreshold, uint32_t *dev_foundTimes, uint32_t *dev_foundTimesCounter, 
																		uint32_t *dev_TPCounter, uint16_t *dev_peaksOffsets, uint32_t *devTruthTable, uint32_t *devTruthTableSize, 
																		uint32_t *devTruthTableStartInd )
{
	t1 = high_resolution_clock::now();

	const uint32_t NumberOfThresohldToTest = NUMBER_OF_THRESHOLDS_TO_TEST;
	const float startThreshold = MINIMUM_THRESHOLD_TO_TEST;
	float thresholds[NumberOfThresohldToTest];

	for (uint32_t i = 0; i < NumberOfThresohldToTest; i++)
	{
		thresholds[i] = startThreshold + ((MAXIMUM_THRESHOLD_TO_TEST - startThreshold) / ((float)(NumberOfThresohldToTest)))*(i);

		TrainPart1CUDA(dev_signal, dev_aboveThreshold, dev_foundTimes, dev_foundTimesCounter+(i*MAXIMUM_NUMBER_OF_TEMPLATES), dev_TPCounter + (i*MAXIMUM_NUMBER_OF_TEMPLATES), dev_peaksOffsets,
			devTruthTable, devTruthTableSize, devTruthTableStartInd, (uint16_t)TEMPLATE_CROPPED_LENGTH, (uint32_t)TRAINING_DATA_LENGTH, (uint16_t)MAXIMUM_NUMBER_OF_TEMPLATES, thresholds[i]);
	}	
	

	t2 = high_resolution_clock::now();

	auto duration = duration_cast<microseconds>(t2 - t1).count();
	f_latestExecutionTime = (float)duration;
}


/*----------------------------------------------------------------------------*/
/**
* @brief Performs training based on the amount of templates used, from CUDA
* @note
*
* @param uint32_t *host_TPCounter		: Pointer to array holding all TP scores for all templates for all thresholds
* @param  uint32_t *host_predictionSize : Pointer to array holding all prediction spikes counts for all templates for all thresholds
*
* @retval void : none
*/
template <class T>
void ClassifierController<T>::performTrainingBasedOnTemplatesPart2(uint32_t *host_TPCounter, uint32_t *host_predictionSize)
{
	t1 = high_resolution_clock::now();

	uint32_t TPScoresForTemplate[NUMBER_OF_THRESHOLDS_TO_TEST];
	uint32_t PredictionCountsForTemplate[NUMBER_OF_THRESHOLDS_TO_TEST];

#ifdef PRINT_OUTPUT_INFO
	std::cout << "----------- CUDA training results ------------" << std::endl;
#endif

	for (uint32_t i = 0; i < MAXIMUM_NUMBER_OF_TEMPLATES; i++)
	{
		for (uint32_t y = 0; y < NUMBER_OF_THRESHOLDS_TO_TEST; y++)
		{
			TPScoresForTemplate[y] = host_TPCounter[i + (y*MAXIMUM_NUMBER_OF_TEMPLATES)];
			PredictionCountsForTemplate[y] = host_predictionSize[i + (y*MAXIMUM_NUMBER_OF_TEMPLATES)];
		}

		TTClassifier<T>* pointer = arrayOfClassifier[i];
		uint32_t templatesInTrainData = projectInfoRefPtr->isTemplateUsedTraining(i + 1);
		if (templatesInTrainData > 0)
		{
			pointer->TrainFromCUDAResults(projectInfoRefPtr->isTemplateUsedTraining(i + 1), PredictionCountsForTemplate, TPScoresForTemplate);
#ifdef PRINT_OUTPUT_INFO
			float wF1Score = pointer->calculateWF1Score(pointer->getLatestTrainingPrecision(), pointer->getLatestTrainingRecall());
			std::cout << "Train template: " << setw(2) << i + 1 << " threshold: " << setw(4) << pointer->getThreshold() << " counts: " << setw(5) << templatesInTrainData << " W-F1 score: " << wF1Score << std::endl;
#endif
		}
	}

	t2 = high_resolution_clock::now();

	auto duration = duration_cast<microseconds>(t2 - t1).count();
	f_latestExecutionTime = (float)duration;
}

/*----------------------------------------------------------------------------*/
/**
* @brief Performs prediction based on the amount of templates used, using CUDA
* @note
*
* @param const float *dev_signal			: Pointer to array holding to features / signal
* @param char *dev_aboveThreshold			: Pointer to array indicating which values are above threshold, only used by CUDA
* @param uint32_t *dev_foundTimes			: Pointer to array where the foundTimes are placed
* @param uint32_t *dev_foundTimesCounter	: Pointer to array where the number of spikes/foundtimes are located
* @param float dev_threshold				: pointer to array holding the trained thresholds
*
* @retval void : none
*/
template <class T>
void ClassifierController<T>::performPredictionBasedOnTemplatesCUDA(const float *dev_signal, char *dev_aboveThreshold, uint32_t *dev_foundTimes, uint32_t *dev_foundTimesCounter, float *dev_threshold, uint32_t dataLength)
{
	t1 = high_resolution_clock::now();

	PredictCUDA(dev_signal, dev_aboveThreshold, dev_foundTimes, dev_foundTimesCounter, (uint16_t)TEMPLATE_CROPPED_LENGTH, dataLength, (uint16_t)MAXIMUM_NUMBER_OF_TEMPLATES, dev_threshold);

	t2 = high_resolution_clock::now();

	auto duration = duration_cast<microseconds>(t2 - t1).count();
	f_latestExecutionTime = (float)duration;
}

/*----------------------------------------------------------------------------*/
/**
* @brief verifies prediction based on the amount of templates used, using CUDA
* @note
*
* @param T* foundTimesCounter			           : Pointer to array that holds number of times template found
* @param T* foundTimesP     			           : Pointer to array that holds number of times template found
* @param TemplateController<T>* templateController : Pointer to the TemplateController class holding the templates.
*
* @retval void : none
*/
template <class T>
void ClassifierController<T>::verifyPredictionBasedOnTemplatesCUDA(uint32_t* foundTimesCounter, uint32_t* foundTimesP, TemplateController<T> * templateController)
{
	float precision, recall, wF1Score;

	for (int i = 0; i < MAXIMUM_NUMBER_OF_TEMPLATES; i++) {
		printf("T%02d times: %3d", i + 1, foundTimesCounter[i]);
		if (projectInfoRefPtr->isTemplateUsedPrediction(i + 1) > 0)
		{
			TTClassifier<T>* pointer = arrayOfClassifier[i];
			printf("(%3d) threshold %0.2f", projectInfoRefPtr->isTemplateUsedPrediction(i + 1), pointer->getThreshold());
			pointer->compareWithTruthTable(&precision, 
				                           &recall, 
				                           projectInfoRefPtr->getTemplateTruthTablePrediction(i + 1), 
				                           projectInfoRefPtr->isTemplateUsedPrediction(i + 1),
										   &foundTimesP[i*(int)MAXIMUM_PREDICTION_SAMPLES], 
										   foundTimesCounter[i],
				                           3, 
				                           templateController->getTemplatePeakOffset(i + 1));

			wF1Score = pointer->calculateWF1Score(precision, recall);
			std::cout <<" W-F1 score: " << wF1Score;
		}
		std::cout << std::endl;
	}
}

#endif

/*----------------------------------------------------------------------------*/
/**
* @brief Performs prediction based on the amount of templates used.
* @note
*
* @param NXCORController<T>* nxcorControllerRef    :			Pointer to the NXCORController class holding the correspondence output.
* @param TemplateController<T>* templateController :		    Pointer to the TemplateController class holding the templates.
*
* @retval void : none
*/
template <class T>
void ClassifierController<T>::performPredictionBasedOnTemplates(NXCORController<T>* nxcorControllerRef, TemplateController<T> * templateController)
{
	t1 = high_resolution_clock::now();
	float wF1Score;

	for (uint32_t i = 0; i < MAXIMUM_NUMBER_OF_TEMPLATES; i++)
	{
		if (projectInfoRefPtr->isTemplateUsedPrediction(i + 1) > 0)
		{

			TTClassifier<T>* pointer = arrayOfClassifier[i];
			wF1Score = pointer->PredictAndCompare(nxcorControllerRef->getFeatureForTemplate(i + 1), projectInfoRefPtr->getTemplateTruthTablePrediction(i + 1), projectInfoRefPtr->isTemplateUsedPrediction(i + 1), (TRAINING_DATA_LENGTH - TEMPLATE_CROPPED_LENGTH), templateController->getTemplatePeakOffset(i + 1));
#ifdef PRINT_OUTPUT_INFO
			std::cout << "Predict template: " << setw(2) << i+1 << " W-F1 score: " << wF1Score << std::endl;
#endif	
		}
	}

	t2 = high_resolution_clock::now();

	auto duration = duration_cast<microseconds>(t2 - t1).count();
	f_latestExecutionTime = (float)duration;
}

/*----------------------------------------------------------------------------*/
/**
* @brief Returns the threshold for a specific template, determined by the number.
* @note
*
* @param uint32_t number : The template number
*
* @retval float : The template's threshold
*/
template <class T>
float ClassifierController<T>::getTemplateThreshold(uint32_t number)
{
	if (projectInfoRefPtr->isTemplateUsedTraining(number) > 0)
	{
		TTClassifier<T>* pointer = arrayOfClassifier[number-1];
		return pointer->getThreshold();
	} 
	else
	{
		return 1;
	}
}

/*----------------------------------------------------------------------------*/
/**
* @brief Return the latest execution for either of the algorithms
*
* @retval float : The execution time in microseconds (us)
*/
template <class T>
float ClassifierController<T>::getLatestExecutionTime(void)
{
	return f_latestExecutionTime;
}

#endif