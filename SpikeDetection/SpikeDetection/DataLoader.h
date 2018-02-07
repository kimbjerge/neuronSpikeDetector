///////////////////////////////////////////////////////////
//  TM_COR.h
//  Header:			 Class used to load the data.
//  Created on:      24-08-2017
//  Original author: MB
///////////////////////////////////////////////////////////
#ifndef DATA_LOADER_H
#define DATA_LOADER_H

#include <string>
#include <iostream>
#include <fstream>
#include "stdint.h"
#include <math.h>

template <class T>
class DataLoader
{
public:
	/* Enums */
	enum DataSizeType { UINT8, UINT16, UINT32, FLOAT };
	/* Constructor */
	DataLoader(std::string stringPath, uint16_t numberOfChannels, uint32_t size, DataSizeType dataType);
	~DataLoader(void);
	/* Get functions */
	T* getDataPointer(void);
	T* getDataPointer(uint32_t channelOffset);
	uint32_t getSizeBytes(void);
	uint32_t getNumberOfChannels(void);
	uint32_t getNumberOfSamples(void);
private:
	uint32_t u32_fileSize = 0;
	uint32_t u32_numberOfChannels = 0;
	uint32_t u32_numberOfSamples = 0;
	T* DataArrayPtr_ = NULL;
};

using namespace std;

/*----------------------------------------------------------------------------*/
/**
* @brief Constructor
* @note  Loads the data depending on which datatype is used.
*
* @param std::string stringPath :	 The path to where the data is located.
* @param uint16_t numberOfChannels : Indicates the amount of channels used.
* @param uint32_t size :			 Indicates the size of the data.
* @param DataSizeType dataType :	 Indicates through an enum what datatype is used.
*
* @retval void : none
*/
template <class T>
DataLoader<T>::DataLoader(std::string stringPath, uint16_t numberOfChannels, uint32_t size, DataSizeType dataType)
{
	
	u32_numberOfSamples = size;
	u32_numberOfChannels = numberOfChannels;

	DataArrayPtr_ = new T[numberOfChannels*size];

	uint32_t maxLoop = size*numberOfChannels;
	ifstream ifs(stringPath, ios::binary);
	uint32_t u32_iterator = 0;

	while (maxLoop > 0)
	{
		if (ifs)
		{
			switch (dataType)
			{
				case UINT8: {	int8_t dummy;		ifs.read(reinterpret_cast<char*>(&dummy), sizeof(dummy));	DataArrayPtr_[u32_iterator] = isnan((T)dummy) ? 0 : (float)dummy; }	break;
				case UINT16: {	int16_t dummy;		ifs.read(reinterpret_cast<char*>(&dummy), sizeof(dummy));	DataArrayPtr_[u32_iterator] = isnan((T)dummy) ? 0 : (float)dummy; }	break;
				case UINT32: {	int32_t dummy;		ifs.read(reinterpret_cast<char*>(&dummy), sizeof(dummy));	DataArrayPtr_[u32_iterator] = isnan((T)dummy) ? 0 : (float)dummy; }	break;
				case FLOAT: {	float dummy;		ifs.read(reinterpret_cast<char*>(&dummy), sizeof(dummy));	DataArrayPtr_[u32_iterator] = isnan((T)dummy) ? 0 : dummy; }	break;
				
				default: {	int16_t dummy;		ifs.read(reinterpret_cast<char*>(&dummy), sizeof(dummy));	DataArrayPtr_[u32_iterator] = (T)dummy; }	break;
			}
			
			
			u32_fileSize++;
		}
		u32_iterator++;
		maxLoop--;
	}

	ifs.close();
}

/*----------------------------------------------------------------------------*/
/**
* @brief Destructor
* @note Empty!
*/
template <class T>
DataLoader<T>::~DataLoader(void)
{
	// free the allocated memory 
	delete DataArrayPtr_;
}

/*----------------------------------------------------------------------------*/
/**
* @brief Returns the datapointer for the data.
*
* @retval T* : The pointer to the array holding the data.
*/
template <class T>
T* DataLoader<T>::getDataPointer(void)
{
	return DataArrayPtr_;
}

/*----------------------------------------------------------------------------*/
/**
* @brief Returns the datapointer with a offset for the data.
*
* @param uint32_t channelOffset : The offset for the datapointer to the data.
*
* @retval T* : The pointer to the array holding the data.
*/
template <class T>
T* DataLoader<T>::getDataPointer(uint32_t channelOffset)
{
	return DataArrayPtr_[channelOffset];
}

/*----------------------------------------------------------------------------*/
/**
* @brief Returns the filesize in bytes.
*
* @retval uint32_t : The amount of bytes.
*/
template <class T>
uint32_t DataLoader<T>::getSizeBytes(void)
{
	return u32_fileSize;
}

/*----------------------------------------------------------------------------*/
/**
* @brief Returns the amount of channels used.
*
* @retval uint32_t : The amount of channels.
*/
template <class T>
uint32_t DataLoader<T>::getNumberOfChannels(void)
{
	return u32_numberOfChannels;
}

/*----------------------------------------------------------------------------*/
/**
* @brief Returns the amount of samples in the data.
*
* @retval uint32_t : The amount of samples.
*/
template <class T>
uint32_t DataLoader<T>::getNumberOfSamples(void)
{
	return u32_numberOfSamples;
}

#endif /* DATA_LOADER_H */
