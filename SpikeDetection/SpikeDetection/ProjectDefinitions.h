///////////////////////////////////////////////////////////
//  ProjectDefinitions.h
//  Header:          This file defines the setup for this project.
//  Created on:      27-10-2017
//  Original author: MB
///////////////////////////////////////////////////////////
#ifndef PROJECT_DEFINITIONS_H
#define PROJECT_DEFINITIONS_H

/*********************************** GENERAL SETUP ****************************************************/
//#define					USE_OPENCV
#define					USE_CUDA // Working with 2 seconds train and predict

#define					PRINT_OUTPUT_INFO

#ifdef USE_OPENCV
#ifdef USE_CUDA
#error Selecting both USE_OPENCV and USE_CUDA is not allowed
#endif
#endif

/*********************************** PATHS ************************************************************/
#define					PATH_TO_CONFIG_FILE					"TestData/projectInfo.bin"
#define					PATH_TO_KILSORT_GT_TRAINING			"TestData/RezInfo.bin"
#define					PATH_TO_TEMPLATES					"TestData/Templates/template_"
#define					PATH_TO_TRAINING_DATA				"TestData/rawData300000x32.bin"
#define					PATH_TO_PREDICTION_DATA				"TestData/rawDataForPrediction300000x32.bin"

/*********************************** SAMPLING *********************************************************/
#define					USED_DATATYPE						float
#define					SAMPLING_FREQUENCY					30000
#define					TRAINING_DATA_TIME					1 // 10 s, must be same size
#define					RUNTIME_DATA_TIME					1 // 4 ms // The runtime/prediction data is assumed to be consecutive to the training data
#define					TRAINING_DATA_LENGTH				SAMPLING_FREQUENCY*TRAINING_DATA_TIME
#define					RUNTIME_DATA_LENGTH					SAMPLING_FREQUENCY*RUNTIME_DATA_TIME
#define					DATA_CHANNELS						32		

/*********************************** MATLAB OUTPUT ****************************************************/
#define					KILOSORT_ST3_WIDTH_USED				2
#define					CONFIG_FILE_LENGTH					1

/*********************************** TEMPLATES ********************************************************/
#define					MAXIMUM_NUMBER_OF_TEMPLATES			64
#define					TEMPLATE_ORIGINAL_LENGTH			61
#define					TEMPLATE_ORIGINAL_WIDTH				DATA_CHANNELS
#define					TEMPLATE_CROPPED_LENGTH				17
#define					TEMPLATE_CROPPED_WIDTH				9

/*********************************** DRIFT HANDLING ***************************************************/
#define					NUMBER_OF_DRIFT_CHANNELS_HANDLED	0 // only 1 has been tested! OpenCV does not support drift currently
#ifdef USE_OPENCV 
#if NUMBER_OF_DRIFT_CHANNELS_HANDLED > 0
#error THIS IS NOT ALLOWED!
#endif
#endif

/*********************************** CHANNEL FILTERING ************************************************/
#define					NUMBER_OF_A_COEFF					6
#define					NUMBER_OF_B_COEFF					4

/*********************************** KERNEL FILTERING *************************************************/
#define					DEFAULT_KERNEL_DIM					3 // Equals 3x3 - Currently only supported!

/*********************************** TRAINED THRESHOLD ************************************************/
#define					PRECISION_WEIGHT					0.7
#define					RECALL_WEIGHT						0.3
#define					ACCEPTED_TIMELINE_SLACK				3
#define					NUMBER_OF_THRESHOLDS_TO_TEST		40
#define				    MINIMUM_THRESHOLD_TO_TEST			0.2
#define				    MAXIMUM_THRESHOLD_TO_TEST			1
#define					MAXIMUM_PREDICTION_SAMPLES			TRAINING_DATA_TIME*1000 // inidcats a Maximum 1000 spikes per template per second


#endif