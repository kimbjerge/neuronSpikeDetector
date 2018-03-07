///////////////////////////////////////////////////////////
//  ProjectInfo.h
//  Header:          Class holding Project information.
//  Created on:      30-10-2017
//  Original author: MB
///////////////////////////////////////////////////////////
#ifndef PROJECT_INFO_H
#define PROJECT_INFO_H

#include "stdint.h"
#include "math.h"
#include <chrono>
#include "DataLoader.h"
#include "ProjectDefinitions.h"

using namespace std::chrono;

class ProjectInfo
{
public:
	/* Constructor */
	ProjectInfo(std::string pathToConfigFile, uint32_t fileSize);
	~ProjectInfo(void);
	/* Handling functions */
	uint32_t* getTemplateTruthTableTraining(uint32_t templateNumber);
	uint32_t* getTemplateTruthTablePrediction(uint32_t templateNumber);
	USED_DATATYPE* getTraningData(void);
	USED_DATATYPE* getPredictionData(void);
	uint32_t isTemplateUsedTraining(uint32_t templateNumber);
	uint32_t isTemplateUsedPrediction(uint32_t templateNumber);
	uint32_t getNumberOfSpikesTraining(void);
	float getLatestExecutionTime(void);

#ifdef USE_CUDA
	uint32_t* getTruthTableCombined(void);
	uint32_t* getTruthTableSizes(void);
	uint32_t* getTruthTableStartIndencis(void);
	uint32_t  getNumberTotalTruthTableSize(void);
#endif

private:
	/* Helper functions */
#ifdef USE_CUDA
	void generateSortedGTForCUDA(void);
	uint32_t *combinedTruthTable;
	uint32_t *combinedTruthTableSize;
	uint32_t *combinedTruthTableStartIndencis;
#endif
	void readKilosortGTinfoTraining(void);
	void generateTemplateTruthTablesTraining(void);
	void readKilosortGTinfoPrediction(void);
	void generateTemplateTruthTablesPrediction(void);
	DataLoader<USED_DATATYPE> configLoader;
	DataLoader<USED_DATATYPE> *kiloSortTrainingInfoLoader;
	DataLoader<USED_DATATYPE> *trainingDataLoader;
	DataLoader<USED_DATATYPE> *predictionDataLoader;
	uint32_t isTemplateUsedArrayTraining[MAXIMUM_NUMBER_OF_TEMPLATES] = { 0 };
	uint32_t isTemplateUsedArrayPrediction[MAXIMUM_NUMBER_OF_TEMPLATES] = { 0 };
	high_resolution_clock::time_point t1;
	high_resolution_clock::time_point t2;
	float f_latestExecutionTime = 0;
	uint32_t* templateGTArrayTraining[MAXIMUM_NUMBER_OF_TEMPLATES] = { NULL };
	uint32_t* templateGTArrayPrediction[MAXIMUM_NUMBER_OF_TEMPLATES] = { NULL };
};

#endif