///////////////////////////////////////////////////////////
//  ProjectInfo.cpp
//  Header:          Class holding Project information.
//  Created on:      30-10-2017
//  Original author: MB, KBE
///////////////////////////////////////////////////////////
#include "ProjectInfo.h"

/*----------------------------------------------------------------------------*/
/**
* @brief Constructor
*
* @param std::string pathToConfigFile :   The path to the config file.
* @param uint32_t fileSize :              Indicates the file size.
* @param std::string pathToKilosortInfo : The path to the Kilosort info file.
*
* @retval void : none
*/
ProjectInfo::ProjectInfo(std::string pathToConfigFile, uint32_t fileSize) :
	configLoader(pathToConfigFile, 1, fileSize, DataLoader<USED_DATATYPE>::FLOAT)
{
	/* Constructor */
	t1 = high_resolution_clock::now();
	
	kiloSortTrainingInfoLoader = new DataLoader<USED_DATATYPE>(PATH_TO_KILSORT_GT_TRAINING, KILOSORT_ST3_WIDTH_USED, getNumberOfSpikesTraining(), DataLoader<USED_DATATYPE>::FLOAT);
	trainingDataLoader = new DataLoader<USED_DATATYPE>(PATH_TO_TRAINING_DATA, DATA_CHANNELS, TRAINING_DATA_LENGTH, DataLoader<USED_DATATYPE>::FLOAT);
	predictionDataLoader = new DataLoader<USED_DATATYPE>(PATH_TO_PREDICTION_DATA, DATA_CHANNELS, RUNTIME_DATA_LENGTH, DataLoader<USED_DATATYPE>::FLOAT);

	readKilosortGTinfoTraining();
	generateTemplateTruthTablesTraining();
	readKilosortGTinfoPrediction();
	generateTemplateTruthTablesPrediction();

#ifdef USE_CUDA
	generateSortedGTForCUDA();
#endif
	t2 = high_resolution_clock::now();

	auto duration = duration_cast<microseconds>(t2 - t1).count();
	f_latestExecutionTime = (float)duration;
}

/*----------------------------------------------------------------------------*/
/**
* @brief Destructor
* @note Empty!
*/
ProjectInfo::~ProjectInfo(void)
{
	if (kiloSortTrainingInfoLoader != NULL)
	{
		delete kiloSortTrainingInfoLoader;
	}

	if (trainingDataLoader != NULL)
	{
		delete trainingDataLoader;
	}

	if (predictionDataLoader != NULL)
	{
		delete predictionDataLoader;
	}

	for (uint32_t i = 0; i < MAXIMUM_NUMBER_OF_TEMPLATES; i++)
	{
		uint32_t *currentArrayPointer = templateGTArrayTraining[i];
		if (currentArrayPointer != NULL)
		{
			delete currentArrayPointer;
		}
	}

	for (uint32_t i = 0; i < MAXIMUM_NUMBER_OF_TEMPLATES; i++)
	{
		uint32_t *currentArrayPointer = templateGTArrayPrediction[i];
		if (currentArrayPointer != NULL)
		{
			delete currentArrayPointer;
		}
	}
}

/*----------------------------------------------------------------------------*/
/**
* @brief Returns the amount of spikes.
*
* @retval uint32_t : The amount of spikes.
*/
uint32_t ProjectInfo::getNumberOfSpikesTraining(void)
{
	return (uint32_t)configLoader.getDataPointer()[0];
}


/*----------------------------------------------------------------------------*/
/**
* @brief Reads the ground truth info from Kilosort.
*
* @retval void : none
*/
void ProjectInfo::readKilosortGTinfoTraining(void)
{
	uint32_t maximumValues = getNumberOfSpikesTraining();

	for (uint32_t templateCounter = 0; templateCounter < MAXIMUM_NUMBER_OF_TEMPLATES; templateCounter++)
	{
		uint32_t TemplateFoundCount = 0;
		
		for (uint32_t i = 0; i < (maximumValues*KILOSORT_ST3_WIDTH_USED); i++)
		{
			if (((uint32_t)kiloSortTrainingInfoLoader->getDataPointer()[i + 1]) == (templateCounter+1))
			{
				if (((uint32_t)kiloSortTrainingInfoLoader->getDataPointer()[i]) > TRAINING_DATA_LENGTH)
				{
					break;
				}
				TemplateFoundCount++;
			}
			i+= KILOSORT_ST3_WIDTH_USED-1;
		}

		isTemplateUsedArrayTraining[templateCounter] = TemplateFoundCount;
	}
}

/*----------------------------------------------------------------------------*/
/**
* @brief Generates truth tables for the templates.
*
* @retval void : none
*/
void ProjectInfo::generateTemplateTruthTablesTraining(void)
{	
	uint32_t maximumValues = getNumberOfSpikesTraining();

	for (uint32_t templateCounter = 0; templateCounter < MAXIMUM_NUMBER_OF_TEMPLATES; templateCounter++)
	{
		if (isTemplateUsedTraining(templateCounter + 1) > 0)
		{
			uint32_t TemplateFoundCount = 0;
			uint32_t arraySize = isTemplateUsedTraining(templateCounter + 1);
			templateGTArrayTraining[templateCounter] = new uint32_t[arraySize];
			uint32_t *currentArrayPointer = templateGTArrayTraining[templateCounter];

			for (uint32_t i = 0; i < (maximumValues*KILOSORT_ST3_WIDTH_USED); i++)
			{
				if (((uint32_t)kiloSortTrainingInfoLoader->getDataPointer()[i + 1]) == (templateCounter + 1))
				{
					if (((uint32_t)kiloSortTrainingInfoLoader->getDataPointer()[i]) > TRAINING_DATA_LENGTH)
					{
						break;
					}
					currentArrayPointer[TemplateFoundCount] = (uint32_t)kiloSortTrainingInfoLoader->getDataPointer()[i];
					TemplateFoundCount++;
				}
				i += KILOSORT_ST3_WIDTH_USED - 1;
			}
		}
	}
}

/*----------------------------------------------------------------------------*/
/**
* @brief Reads the ground truth info from Kilosort.
*
* @retval void : none
*/
void ProjectInfo::readKilosortGTinfoPrediction(void)
{
	uint32_t maximumValues = getNumberOfSpikesTraining();

	for (uint32_t templateCounter = 0; templateCounter < MAXIMUM_NUMBER_OF_TEMPLATES; templateCounter++)
	{
		uint32_t TemplateFoundCount = 0;

		for (uint32_t i = 0; i < (maximumValues*KILOSORT_ST3_WIDTH_USED); i++)
		{
			if (((uint32_t)kiloSortTrainingInfoLoader->getDataPointer()[i + 1]) == (templateCounter + 1))
			{
				if (((uint32_t)kiloSortTrainingInfoLoader->getDataPointer()[i]) > (RUNTIME_DATA_LENGTH + TRAINING_DATA_LENGTH))
				{
					break;
				}
				else if (((uint32_t)kiloSortTrainingInfoLoader->getDataPointer()[i]) >= (TRAINING_DATA_LENGTH))
				{
					TemplateFoundCount++;
				}
			}
			i += KILOSORT_ST3_WIDTH_USED - 1;
		}

		isTemplateUsedArrayPrediction[templateCounter] = TemplateFoundCount;
	}
}

/*----------------------------------------------------------------------------*/
/**
* @brief Generates truth tables for the templates.
*
* @retval void : none
*/
void ProjectInfo::generateTemplateTruthTablesPrediction(void)
{
	uint32_t maximumValues = getNumberOfSpikesTraining();

	for (uint32_t templateCounter = 0; templateCounter < MAXIMUM_NUMBER_OF_TEMPLATES; templateCounter++)
	{
		if (isTemplateUsedPrediction(templateCounter + 1) > 0)
		{
			uint32_t TemplateFoundCount = 0;
			uint32_t arraySize = isTemplateUsedPrediction(templateCounter + 1);
			templateGTArrayPrediction[templateCounter] = new uint32_t[arraySize];
			uint32_t *currentArrayPointer = templateGTArrayPrediction[templateCounter];

			for (uint32_t i = 0; i < (maximumValues*KILOSORT_ST3_WIDTH_USED); i++)
			{
				if (((uint32_t)kiloSortTrainingInfoLoader->getDataPointer()[i + 1]) == (templateCounter + 1))
				{
					if (((uint32_t)kiloSortTrainingInfoLoader->getDataPointer()[i]) > (RUNTIME_DATA_LENGTH + TRAINING_DATA_LENGTH))
					{
						break;
					}
					else if (((uint32_t)kiloSortTrainingInfoLoader->getDataPointer()[i]) >= (TRAINING_DATA_LENGTH))
					{
						currentArrayPointer[TemplateFoundCount] = ((uint32_t)kiloSortTrainingInfoLoader->getDataPointer()[i]) - TRAINING_DATA_LENGTH;
						TemplateFoundCount++;
					}	
				}
				i += KILOSORT_ST3_WIDTH_USED - 1;
			}
		}
	}
}

/*----------------------------------------------------------------------------*/
/**
* @brief Checks if a template is used, returns 0 if not, otherwise returns the template number.
*
* @retval uint32_t : The template used.
*/
uint32_t ProjectInfo::isTemplateUsedTraining(uint32_t templateNumber)
{
	if (templateNumber > 0 && templateNumber <= MAXIMUM_NUMBER_OF_TEMPLATES)
		return isTemplateUsedArrayTraining[templateNumber - 1];
	else
		return 0;
}

/*----------------------------------------------------------------------------*/
/**
* @brief Checks if a template is used, returns 0 if not, otherwise returns the template number.
*
* @retval uint32_t : The template used.
*/
uint32_t ProjectInfo::isTemplateUsedPrediction(uint32_t templateNumber)
{
	if (templateNumber > 0 && templateNumber <= MAXIMUM_NUMBER_OF_TEMPLATES)
		return isTemplateUsedArrayPrediction[templateNumber - 1];
	else
		return 0;
}


/*----------------------------------------------------------------------------*/
/**
* @brief returns the latest execution time
*
* @retval uint32_t : The latest execution time in us.
*/
float ProjectInfo::getLatestExecutionTime(void)
{
	return f_latestExecutionTime;
}

/*----------------------------------------------------------------------------*/
/**
* @brief Returns the template truth table.
*
* @retval uint32_t* : The pointer for the ground truth array.
*/
uint32_t* ProjectInfo::getTemplateTruthTableTraining(uint32_t templateNumber)
{
	if (isTemplateUsedTraining(templateNumber) > 0)
	{
		return templateGTArrayTraining[templateNumber - 1];
	}

	return NULL;
}

/*----------------------------------------------------------------------------*/
/**
* @brief Returns the template truth table.
*
* @retval uint32_t* : The pointer for the ground truth array.
*/
uint32_t* ProjectInfo::getTemplateTruthTablePrediction(uint32_t templateNumber)
{
	if (isTemplateUsedPrediction(templateNumber) > 0)
	{
		return templateGTArrayPrediction[templateNumber - 1];
	}

	return NULL;
}

/*----------------------------------------------------------------------------*/
/**
* @brief Returns the training data.
*
* @retval USED_DATATYPE* : The pointer for the array holding the training data.
*/
USED_DATATYPE* ProjectInfo::getTraningData(void)
{
	return trainingDataLoader->getDataPointer();
}


/*----------------------------------------------------------------------------*/
/**
* @brief Returns the prediction data.
*
* @retval USED_DATATYPE* : The pointer for the array holding the prediction data.
*/
USED_DATATYPE* ProjectInfo::getPredictionData(void)
{
	return predictionDataLoader->getDataPointer();
}

#ifdef USE_CUDA
/*----------------------------------------------------------------------------*/
/**
* @brief Generates truth tables for the templates sorted for CUDA.
*
* @retval void : none
*/
void ProjectInfo::generateSortedGTForCUDA(void)
{
	combinedTruthTableSize = new uint32_t[MAXIMUM_NUMBER_OF_TEMPLATES];
	combinedTruthTableStartIndencis = new uint32_t[MAXIMUM_NUMBER_OF_TEMPLATES];

	uint32_t totalSizeOfTruthTable = 0;
	for (uint32_t i = 0; i < MAXIMUM_NUMBER_OF_TEMPLATES; i++)
	{
		uint32_t ttForTemplate = isTemplateUsedTraining(i + 1);

		combinedTruthTableSize[i] = ttForTemplate;
		
		if (i == 0)
		{
			combinedTruthTableStartIndencis[i] = 0;
		}
		else
		{
			combinedTruthTableStartIndencis[i] = totalSizeOfTruthTable;
		}
	
		totalSizeOfTruthTable += ttForTemplate;
	}

	combinedTruthTable = new uint32_t[totalSizeOfTruthTable];
	
	for (uint32_t i = 0; i < MAXIMUM_NUMBER_OF_TEMPLATES; i++)
	{
		for (uint32_t y = 0; y < combinedTruthTableSize[i]; y++)
		{
			if (getTemplateTruthTableTraining(i + 1) != NULL)
			{
				combinedTruthTable[y + combinedTruthTableStartIndencis[i]] = getTemplateTruthTableTraining(i + 1)[y];
			}
		}
	}

}

/*----------------------------------------------------------------------------*/
/**
* @brief Returns the combined truthtable
*
* @retval uint32_t* : 1D representation of the sorted grund truth
*/
uint32_t* ProjectInfo::getTruthTableCombined(void)
{
	return combinedTruthTable;
}

/*----------------------------------------------------------------------------*/
/**
* @brief Returns an array of sizes indicating for each template the number of grund truths
*
* @retval uint32_t* : returns the array
*/
uint32_t* ProjectInfo::getTruthTableSizes(void)
{
	return combinedTruthTableSize;
}

/*----------------------------------------------------------------------------*/
/**
* @brief Returns an array of indencis indicating for each template the starting location within the grund truth
*
* @retval uint32_t* : returns the array
*/
uint32_t* ProjectInfo::getTruthTableStartIndencis(void)
{
	return combinedTruthTableStartIndencis;
}

/*----------------------------------------------------------------------------*/
/**
* @brief Returns the total amount of samples in the truthTable
*
* @retval uint32_t : returns the number
*/
uint32_t ProjectInfo::getNumberTotalTruthTableSize(void)
{
	return getTruthTableStartIndencis()[MAXIMUM_NUMBER_OF_TEMPLATES - 1] + getTruthTableSizes()[MAXIMUM_NUMBER_OF_TEMPLATES - 1];
}
#endif
