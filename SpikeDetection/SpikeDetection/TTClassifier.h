///////////////////////////////////////////////////////////
//  TTClassifier.h
//  Header:          Function to train and do prediction
//  Created on:      26-10-2017
//  Original author: MB
///////////////////////////////////////////////////////////
#ifndef TT_CLASSIFIER_H
#define TT_CLASSIFIER_H

#include "stdint.h"
#include "math.h"
#include <chrono>

using namespace std::chrono;

template <class T>
class TTClassifier
{
public:
	/* Enums */
	enum PredictTypes
	{
		PREDICT,
	};
	/* Constructor */
	TTClassifier(float recallWeight, float precisionWeight);
	/* Template handling functions */
	uint32_t Predict(T* Features, uint32_t** foundTimes, uint32_t FeaturesLength);
	float PredictAndCompare(T* Features, uint32_t* Truthtable, uint32_t numberOfSpikes, uint32_t numberOfFeatures, uint32_t peakOffset);
	void Train(T* Features, uint32_t* Truthtable, uint32_t numberOfSpikes, uint32_t numberOfFeatures, uint32_t peakOffset);
	float getLatestTrainingPrecision(void);
	float getLatestTrainingRecall(void);
	float getThreshold(void);
	/* Helper functions - Consider protected or private*/
	uint32_t findPeaks(T* signal, uint32_t** foundTimes, uint32_t signalLength, bool* AboveThresholdIndicator);
	void findValuesAboveThreshold(T* signal, bool* indexIndication, uint32_t signalLength, T nonMaximumValue);
	void compareWithTruthTable(float* precision, float* recall, uint32_t* Truthtable, uint32_t sizeOfTruthTable, uint32_t* Estimation, uint32_t sizeOfEstimation, uint32_t slack, uint32_t peakOffset);
	bool findTimeStampInArray(uint32_t valueToFind, uint32_t* ArrayToSearch, uint32_t arraySize, uint32_t* startIndex, int32_t OffsetToTruthTable, bool arrayIsTruthTable);
	float calculateWF1Score(float precision, float recall);
#ifdef USE_CUDA
	void TrainFromCUDAResults(uint32_t TruthtabletableSize, uint32_t* PredictionNumberOfSpikes, uint32_t* TPScores);
#endif

	/* Test and debug */
	float getLatestExecutionTime(void);
	float performXTestReturnExecutionTime(T* Features, uint32_t** foundTimes, uint32_t FeaturesLength, uint32_t numberOfTest, PredictTypes testtype);
private:
	float trainedThreshold = 0;
	float lastTrainedPrecision = 0;
	float lastTrainedRecall = 0;
	float precisionWeight = 0;
	float recallWeight = 0;
	high_resolution_clock::time_point t1;
	high_resolution_clock::time_point t2;
	high_resolution_clock::time_point t3;
	high_resolution_clock::time_point t4;
	float f_latestExecutionTime = 0;
};

/*----------------------------------------------------------------------------*/
/**
* @brief Constructor
*
* @param float recallWeight_ :    Indicates the weight of the recall score.
* @param float precisionWeight_ : Indicates the weight of the precision score.
*/
template <class T>
TTClassifier<T>::TTClassifier(float recallWeight_, float precisionWeight_)
{
	precisionWeight = precisionWeight_;
	recallWeight = recallWeight_;
}


/*----------------------------------------------------------------------------*/
/**
* @brief Makes a prediciton upon the given features based on the current threshold
*
* @param T* Features :             The features which is to be predicted upon
* @param uint32_t** foundTimes :   Pointer to a pointer used to store the found spikes timestamps
* @param uint32_t FeaturesLength : Indicates the length of the feature array
*
* @retval uint32_t : Returns the number of spikes detected using the stored threshold
*/
template <class T>
uint32_t TTClassifier<T>::Predict(T* Features, uint32_t** foundTimes, uint32_t FeaturesLength)
{
	t3 = high_resolution_clock::now();

	bool* ThresholdOUt = new bool[FeaturesLength];
	uint32_t foundSpikesHit = 0;
	
	findValuesAboveThreshold(Features, ThresholdOUt, FeaturesLength, 0);

	foundSpikesHit = findPeaks(Features, foundTimes, FeaturesLength, ThresholdOUt);

	delete ThresholdOUt;

	t4 = high_resolution_clock::now();

	auto duration = duration_cast<microseconds>(t4 - t3).count();
	f_latestExecutionTime = (float)duration;

	return foundSpikesHit;
}

/*----------------------------------------------------------------------------*/
/**
* @brief Train a threshold classifier using the supplied features and truthtable.
*
* @param T* Features :               Array of features to be trained upon
* @param uint32_t* Truthtable :		 Truthtable holding the timestamp which should be declared spikes
* @param uint32_t numberOfSpikes :   The number of spike in the truthtable
* @param uint32_t numberOfFeatures : The number of features in the feature array
* @param uint32_t peakOffset :       The peak offset within the window.
*
* @retval void : none
*/
template <class T>
void TTClassifier<T>::Train(T* Features, uint32_t* Truthtable, uint32_t numberOfSpikes, uint32_t numberOfFeatures, uint32_t peakOffset)
{
	t1 = high_resolution_clock::now();
	
	//ThresholdToTest = 0.2:0.02 : 1; % NXCOR
	
	// Generate Thresholds to test
	const uint32_t NumberOfThresohldToTest = NUMBER_OF_THRESHOLDS_TO_TEST;
	const float startThreshold = MINIMUM_THRESHOLD_TO_TEST;
	float thresholds[NumberOfThresohldToTest];
	float precisionArray[NumberOfThresohldToTest];
	float recallArray[NumberOfThresohldToTest];

	for (uint32_t i = 0; i < NumberOfThresohldToTest; i++)
	{
		thresholds[i] = startThreshold + ((MAXIMUM_THRESHOLD_TO_TEST - startThreshold) / ((float)(NumberOfThresohldToTest)))*(i);
	}

	// Apply Thresholds
	for (uint32_t i = 0; i < NumberOfThresohldToTest; i++)
	{
		uint32_t* timesArrayPtr = NULL;
		trainedThreshold = thresholds[i];

		uint32_t numberOfSpikesEst = Predict(Features, &timesArrayPtr, numberOfFeatures);

		compareWithTruthTable(&precisionArray[i], &recallArray[i], Truthtable, numberOfSpikes, timesArrayPtr, numberOfSpikesEst, 3, peakOffset);

		delete timesArrayPtr;
	}

	// Find weighted F1-scores
	float WF1Scores[NumberOfThresohldToTest];

	for (uint32_t i = 0; i < NumberOfThresohldToTest; i++)
	{
		WF1Scores[i] = calculateWF1Score(precisionArray[i], recallArray[i]);
	}

	// Find best F1 Score
	uint32_t bestScoreIndex = 0;
	float bestScore = WF1Scores[bestScoreIndex];

	for (uint32_t i = 1; i < NumberOfThresohldToTest; i++)
	{
		if (WF1Scores[i] > bestScore)
		{
			bestScore = WF1Scores[i];
			bestScoreIndex = i;
		}
	}

	// selecting the optimum
	trainedThreshold = thresholds[bestScoreIndex];

	// for debugging
	lastTrainedPrecision = precisionArray[bestScoreIndex];
	lastTrainedRecall = recallArray[bestScoreIndex];

	t2 = high_resolution_clock::now();

	auto duration = duration_cast<microseconds>(t2 - t1).count();
	f_latestExecutionTime = (float)duration;

}

/*----------------------------------------------------------------------------*/
/**
* @brief Predict and compare the results
*
* @param T* Features :               Array of features to be predicted
* @param uint32_t* Truthtable :		 Truthtable holding the timestamp for comparesion
* @param uint32_t numberOfSpikes :   The number of spike in the truthtable
* @param uint32_t numberOfFeatures : The number of features in the feature array
* @param uint32_t peakOffset :       The peak offset within the window.
*
* @retval void : uint32_t: Weighted F1 score
*/
template <class T>
float TTClassifier<T>:: PredictAndCompare(T* Features, uint32_t* Truthtable, uint32_t numberOfSpikes, uint32_t numberOfFeatures, uint32_t peakOffset)
{
	t1 = high_resolution_clock::now();

	float precision;
	float recall;
	uint32_t* timesArrayPtr = NULL;

	uint32_t numberOfSpikesEst = Predict(Features, &timesArrayPtr, numberOfFeatures);

	compareWithTruthTable(&precision, &recall, Truthtable, numberOfSpikes, timesArrayPtr, numberOfSpikesEst, 3, peakOffset);

	delete timesArrayPtr;
	
	// Find weighted F1-scores
	float WF1Scores = calculateWF1Score(precision, recall);

	t2 = high_resolution_clock::now();

	auto duration = duration_cast<microseconds>(t2 - t1).count();
	f_latestExecutionTime = (float)duration;

	return WF1Scores;
}

/*----------------------------------------------------------------------------*/
/**
* @brief Performs non-maximum suppresion upon the features which is above the threshold
*
* @param T* signal :					 Pointer to the feature array
* @param uint32_t** foundTimes :		 The prediction array of times(indices) which represent a spike
* @param uint32_t signalLength :         The length of the feature(signal) array
* @param bool* AboveThresholdIndicator : Array of bool inidicating which features are above the threshold
*
* @retval uint32_t : Return the number of spikes present after suppresion
*/
template <class T>
uint32_t TTClassifier<T>::findPeaks(T* signal, uint32_t** foundTimes, uint32_t signalLength, bool* AboveThresholdIndicator)
{
	uint32_t numberOfPeaks = 0;
	T StoredPre = 0;
	T StoredPost = 0;
	T currentSignal = 0;
	bool saveNextTime = false;


	// Assign first and last element first
	if (signal[0] > signal[1] && AboveThresholdIndicator[0])
	{		
		numberOfPeaks++;
	}
	else
	{
		AboveThresholdIndicator[0] = false;
	}

	if (signal[signalLength-1] > signal[signalLength-2] && AboveThresholdIndicator[signalLength - 1])
	{
		numberOfPeaks++;
	}
	else
	{
		AboveThresholdIndicator[signalLength - 1] = false;
	}

	for (uint32_t i = 1; i < signalLength - 1; i++)
	{
		if (AboveThresholdIndicator[i])
		{
			currentSignal = signal[i];
			StoredPre = signal[i - 1];
			StoredPost = signal[i + 1];
			
			if (currentSignal > StoredPre && currentSignal >= StoredPost)
			{
				numberOfPeaks++;
			}
			else
			{
				AboveThresholdIndicator[i] = false;
			} 
		}
	}

	/* Generate spikes times array */
	*foundTimes = new uint32_t[numberOfPeaks];
	

	uint32_t counter = 0;
	uint32_t* arrayPointer = *foundTimes;
	for (uint32_t i = 0; i < signalLength; i++)
	{
		if (AboveThresholdIndicator[i])
		{
			arrayPointer[counter] = i;
			counter++;
		}
	}

	return numberOfPeaks;
}

/*----------------------------------------------------------------------------*/
/**
* @brief Finds the features above the stored threshold, and indicates it within a boolean array
*
* @param T* signal :			 The array of features
* @param bool* indexIndication : Array to flag where the features are above the threshold
* @param uint32_t signalLength : Indicates the length of the feature array
* @param T nonMaximumValue :     Not used, but is designed as a value to set upon the values which are below threshold
*
* @retval void : none
*/
template <class T>
void TTClassifier<T>::findValuesAboveThreshold(T* signal, bool* indexIndication, uint32_t signalLength, T nonMaximumValue)
{
	for (uint32_t i = 0; i < signalLength; i++)
	{
		if (signal[i] >= trainedThreshold)
		{
			indexIndication[i] = true;
		}
		else
		{
			indexIndication[i] = false;
			//signal[i] = nonMaximumValue;
		}
	}
}

/*----------------------------------------------------------------------------*/
/**
* @brief Returns the average execution time, when performing multiple tests.
*
* @retval float : The execution time in microseconds (us)
*/
template <class T>
float TTClassifier<T>::performXTestReturnExecutionTime(T* Features, uint32_t** foundTimes, uint32_t FeaturesLength, uint32_t numberOfTest, PredictTypes testtype)
{
	float returnValue = 0;
	float* timeArray = new float[numberOfTest];

	for (uint32_t i = 0; i < numberOfTest; i++)
	{
		if (testtype == PREDICT)
			Predict(Features, foundTimes, FeaturesLength);

		timeArray[i] = getLatestExecutionTime();
	}

	float sum = 0;
	for (uint32_t j = 0; j < numberOfTest; j++)
	{
		sum += timeArray[j];
	}

	returnValue = sum / numberOfTest;

	delete timeArray;
	return returnValue;
}

/*----------------------------------------------------------------------------*/
/**
* @brief Return the latest execution for either of the algorithms
*
* @retval float : The execution time in microseconds (us)
*/
template <class T>
float TTClassifier<T>::getLatestExecutionTime(void)
{
	return f_latestExecutionTime;
}

/*----------------------------------------------------------------------------*/
/**
* @brief Returns the precision from the lastest training.
*
* @retval float : The precision. 
*/
template <class T>
float TTClassifier<T>::getLatestTrainingPrecision(void)
{
	return lastTrainedPrecision;
}

/*----------------------------------------------------------------------------*/
/**
* @brief Returns the recall from the lastest training.
*
* @retval float : The recall.
*/
template <class T>
float TTClassifier<T>::getLatestTrainingRecall(void)
{
	return lastTrainedRecall;
}

/*----------------------------------------------------------------------------*/
/**
* @brief Compares a given prediction vector against a features vector to estimate the performance
*
* @param float* precision :			 Pointer to precision score (used as output)
* @param float* recall :			 Pointer to recall score (used as output)
* @param uint32_t* Truthtable :		 Pointer to the truth table to compare against
* @param uint32_t sizeOfTruthTable : Size of the truthtable
* @param uint32_t* Estimation :		 Pointer to the prediciton vector
* @param uint32_t sizeOfEstimation : Size of the prediction vector
* @param uint32_t slack :			 Allowed slack between prediction and truth
* @param uint32_t peakOffset :       Inidicates the peakoffset within the template (used as offset in comparision)
*
* @retval void : none
*/
template <class T>
void TTClassifier<T>::compareWithTruthTable(float* precision, float* recall, uint32_t* Truthtable, uint32_t sizeOfTruthTable, uint32_t* Estimation, uint32_t sizeOfEstimation, uint32_t slack, uint32_t peakOffset)
{
	t3 = high_resolution_clock::now();

	uint32_t TP = 0;
	uint32_t TN = 0;
	uint32_t FP = 0;
	uint32_t FN = 0;
	uint32_t startIndex = 0;
	uint32_t offsetSpike = 0;

	if (TEMPLATE_CROPPED_LENGTH > ((peakOffset * 2) + 1))
	{
		offsetSpike = peakOffset;
	}
	else
	{
		offsetSpike = (uint32_t)ceil(peakOffset / 2) ;
	}

	for (uint32_t I = 0; I < sizeOfEstimation; I++)
	{
		if (findTimeStampInArray(Estimation[I]+offsetSpike, Truthtable, sizeOfTruthTable, &startIndex, 0, true))
		{
			TP = TP + 1;
		}
		else if (slack > 0)
		{
			for (int32_t Y = 1; Y <= (int)slack; Y++)
			{
				if (findTimeStampInArray((Estimation[I])+ offsetSpike, Truthtable, sizeOfTruthTable, &startIndex, -Y, true))
				{
					TP = TP + 1;
					break;

				}
				else if (findTimeStampInArray((Estimation[I])+ offsetSpike, Truthtable, sizeOfTruthTable, &startIndex, Y, true))
				{
					TP = TP + 1;
					break;
				}

				/*if (Y == (slack))
				{
					FP = FP + 1;
					break;
				}*/
			}
		}
		/*
		else
		{
			FP = FP + 1;
		} */
	}

	startIndex = 0;
	/*
	for (uint32_t I = 0; I < sizeOfTruthTable; I++)
	{
		if (findTimeStampInArray(Truthtable[I]- (offsetSpike), Estimation, sizeOfEstimation, &startIndex, 0, false))
		{
			// TP = TP + 1;
		}
		else if (slack > 0)
		{
			for (uint32_t Y = 1; Y <= slack; Y++)
			{
				if (findTimeStampInArray(Truthtable[I]- (offsetSpike), Estimation, sizeOfEstimation, &startIndex, -Y, false))
				{
					// TP = TP + 1;
					break;
				}
				if (findTimeStampInArray(Truthtable[I]- (offsetSpike), Estimation, sizeOfEstimation, &startIndex, Y, false))
				{
					// TP = TP + 1;
					break;
				}

				if (Y == (slack))
				{
					FN = FN + 1;
					break;
				}
			}
		}
		else
		{
			FN = FN + 1;
		}	
	}
	*/

	FN = sizeOfTruthTable - TP;
	FP = sizeOfEstimation - TP;
	//TN = numberOfSamples - (TP + FP + FN);

	t4 = high_resolution_clock::now();

	auto duration = duration_cast<microseconds>(t4 - t3).count();
	f_latestExecutionTime = (float)duration;

	*precision = (float)TP / ((float)TP + (float)FP);
	*recall = (float)TP / ((float)TP + (float)FN);
	//fallout = FP / (FP + TN);


}

/*----------------------------------------------------------------------------*/
/**
* @brief Searches for a given timestamp within an array
*
* @param uint32_t valueToFind :		  The value (timestamp) to fin
* @param uint32_t* ArrayToSearch :	  Pointer to the array to search within
* @param uint32_t arraySize :		  Size of the array to search within
* @param uint32_t *startIndex :       Startindex to start looking from within the array
* @param int32_t OffsetToTruthTable : Possible offset to the array to search within
* @param bool arrayIsTruthTable :     Indicates is the search array is the truthtable
*
* @retval bool : Indicate if the value was found; true is found
*/
template <class T>
bool TTClassifier<T>::findTimeStampInArray(uint32_t valueToFind, uint32_t* ArrayToSearch, uint32_t arraySize, uint32_t *startIndex, int32_t OffsetToTruthTable, bool arrayIsTruthTable)
{
	bool returnValue = false;

	for (uint32_t i = *startIndex; i < arraySize; i++)
	{
		uint32_t currentArrayValue = ArrayToSearch[i];

		if (arrayIsTruthTable)
		{
			currentArrayValue -= 1;
		}

		if (valueToFind == (currentArrayValue + OffsetToTruthTable))
		{
			*startIndex = 0;
			returnValue = true;
			break;
		}
	}

	return returnValue;
}

/*----------------------------------------------------------------------------*/
/**
* @brief Returns the weighted F1 score, based on the precision and recall provided.
*
* @param float precision : Indicates the precision.
* @param float recall :    Indicates the recall.
*
* @retval float : The weighted F1 score.
*/
template <class T>
float TTClassifier<T>::calculateWF1Score(float precision, float recall)
{
	//return (precisionWeight + recallWeight) / ((precisionWeight / precision) + (recallWeight / recall));
	return ((precisionWeight * precision) + (recallWeight * recall));
}

/*----------------------------------------------------------------------------*/
/**
* @brief Returns the threshold.
*
* @retval float : The trained threshold.
*/
template <class T>
float TTClassifier<T>::getThreshold(void)
{
	return trainedThreshold;
}

#ifdef USE_CUDA
/*----------------------------------------------------------------------------*/
/**
* @brief Trains From the threshold from the partial results made by CUDA
*
* @retval uint32_t TruthtabletableSize:				The size of the truthtable for this template
* @retval uint32_t* PredictionNumberOfSpikes:		The size of the prediction vectors from CUDA
* @retval uint32_t* TPScores:						Array of TP scores obtained from CUDA
* @retval none : -
*/
template <class T>
void TTClassifier<T>::TrainFromCUDAResults(uint32_t TruthtabletableSize, uint32_t *PredictionNumberOfSpikes, uint32_t* TPScores)
{
	t1 = high_resolution_clock::now();
	float precisionArray[NUMBER_OF_THRESHOLDS_TO_TEST];
	float recallArray[NUMBER_OF_THRESHOLDS_TO_TEST];
	float TP;
	float FN;
	float FP;
	float thresholds[NUMBER_OF_THRESHOLDS_TO_TEST];
	

	// Calculate precision and recall scores
	for (uint32_t i = 0; i < NUMBER_OF_THRESHOLDS_TO_TEST; i++)
	{
		thresholds[i] = MINIMUM_THRESHOLD_TO_TEST + ((MAXIMUM_THRESHOLD_TO_TEST - MINIMUM_THRESHOLD_TO_TEST) / ((float)(NUMBER_OF_THRESHOLDS_TO_TEST)))*(i);
		TP = (float)TPScores[i];
		FN = TruthtabletableSize - TP;
		FP = PredictionNumberOfSpikes[i] - TP;

		precisionArray[i] = (float)TP / ((float)TP + (float)FP);
		recallArray[i] = (float)TP / ((float)TP + (float)FN);
	}

	// Find weighted F1-scores
	float WF1Scores[NUMBER_OF_THRESHOLDS_TO_TEST];

	for (uint32_t i = 0; i < NUMBER_OF_THRESHOLDS_TO_TEST; i++)
	{
		WF1Scores[i] = calculateWF1Score(precisionArray[i], recallArray[i]);
	}

	// Find best F1 Score
	uint32_t bestScoreIndex = 0;
	float bestScore = WF1Scores[bestScoreIndex];

	for (uint32_t i = 1; i < NUMBER_OF_THRESHOLDS_TO_TEST; i++)
	{
		if (WF1Scores[i] > bestScore)
		{
			bestScore = WF1Scores[i];
			bestScoreIndex = i;
		}
	}

	// selecting the optimum
	trainedThreshold = thresholds[bestScoreIndex];

	// for debugging
	lastTrainedPrecision = precisionArray[bestScoreIndex];
	lastTrainedRecall = recallArray[bestScoreIndex];

	t2 = high_resolution_clock::now();

	auto duration = duration_cast<microseconds>(t2 - t1).count();
	f_latestExecutionTime = (float)duration;
}
#endif

#endif