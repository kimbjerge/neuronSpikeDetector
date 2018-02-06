/****************************************************
** Spike Detection project
** Created: 28/8 2017 by MB and ATY, AU
** Modified:
******************************************************/

//#include "SpikeDetection.h"

#include "ProjectDefinitions.h"

#ifdef USE_CUDA
#include "SpikeDetectCUDA.h"
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
	SpikeDetect<USED_DATATYPE> *spikeDetector;

#ifdef USE_CUDA
	spikeDetector = new SpikeDetectCUDA<USED_DATATYPE>();
#else
	spikeDetector = new SpikeDetect<USED_DATATYPE>();
#endif

	spikeDetector->runTraining();

	spikeDetector->runPrediction();

	delete spikeDetector;
	
	return returnValue;
}
