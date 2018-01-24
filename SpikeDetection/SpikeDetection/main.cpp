/****************************************************
** Spike Detection project
** Created: 28/8 2017 by MB and ATY, AU
** Modified:
******************************************************/

#include "SpikeDetection.h"
#include "ProjectDefinitions.h"

//----------------------------------------------------------------------------------------------

#ifdef _DEBUG
#ifdef USE_CUDA
//#error ChannelFilter CUDA kernel does not work correctly in debug mode!
#endif
#endif

int main(void)
{
	int returnValue = 0;
	
	SpikeDetection<USED_DATATYPE> spikeDetecter;
	
	//spikeDetecter.runTrainingCUDA();
	spikeDetecter.runTraining();

	spikeDetecter.runPrediction();
	
	return returnValue;
}
