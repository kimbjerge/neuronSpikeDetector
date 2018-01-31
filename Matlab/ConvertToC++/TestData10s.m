PathToDataFiles = 'C:\neuronSpikeDetector\SpikeDetection\SpikeDetection\TestData\'
PathToRefFiles = 'C:\neuronSpikeDetector\SpikeDetection\SpikeDetection\TestData10s\';

%% Verify train data
TrainFile = 'rawData300000x32.bin';

TrainFileName = strcat(PathToDataFiles, TrainFile);
Data2D = Load2DBinFile(TrainFileName, 'Train data');

TrainFileName = strcat(PathToRefFiles, TrainFile);
TrainData2D = Load2DBinFile(TrainFileName, 'Train reference data');

figure
surf(Data2D-TrainData2D);
title('Difference Train Data');

%-------------------------------------------------------------
%% Verify test data
TestFile = 'rawDataForPrediction300000x32.bin';
TestFileName = strcat(PathToDataFiles, TestFile);
Data2D = Load2DBinFile(TestFileName, 'Test data');

TestFileName = strcat(PathToRefFiles, TestFile);
TestData2D = Load2DBinFile(TestFileName, 'Test reference data');

figure
surf(Data2D-TestData2D);
title('Difference Test Data');


