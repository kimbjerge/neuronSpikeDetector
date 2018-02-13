/****************************************************
** Spike Detection project
** Created: 28/8 2017 by MB and ATY, AU
** Modified:
******************************************************/

//#include "SpikeDetection.h"

#include "ProjectDefinitions.h"

#ifdef USE_CUDA
//#include "SpikeDetectCUDA.h"
#include "SpikeDetectCUDA_RTP.h"
#else
#include "SpikeDetect.h"
#endif
//----------------------------------------------------------------------------------------------

#ifdef _DEBUG
#ifdef USE_CUDA
//#error ChannelFilter CUDA kernel does not work correctly in debug mode!
#endif
#endif

int main(void)
{
	int returnValue = 0;

#ifdef USE_CUDA
	//SpikeDetectCUDA<USED_DATATYPE> *spikeDetector;
	//spikeDetector = new SpikeDetectCUDA<USED_DATATYPE>();
	SpikeDetectCUDA_RTP<USED_DATATYPE> *spikeDetector;
	spikeDetector = new SpikeDetectCUDA_RTP<USED_DATATYPE>();

	spikeDetector->runTraining(); // Training not using CUDA
	//spikeDetector->runTrainingCUDA();
#else
	SpikeDetect<USED_DATATYPE> *spikeDetector;
	spikeDetector = new SpikeDetect<USED_DATATYPE>();

	spikeDetector->runTraining();
#endif

	spikeDetector->runPrediction();

	delete spikeDetector;
	
	return returnValue;
}
