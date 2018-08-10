
PrePath = 'C:\neuronSpikeDetector\Matlab\'; % Path to the root of this project
%DiectoryToEvaluate = strcat(PrePath,'Simulation_10min_30kHz_DefVals'); % Path to the data, rez file and more
%DiectoryToEvaluate = strcat(PrePath,'Simulation_CVLAB'); % Path to the data, rez file and more
load(strcat(DiectoryToEvaluate, '\rez.mat')); % Loads the rez file from KiloSort
%isKiloSortTemplateMerged = 'YES'; % Has KiloSort merged the templates?
%isKiloSortTemplateMerged = 'NO'; % Has KiloSort merged the templates?


%PathToOutputFiles = strcat(PrePath,'ConvertToC++');
%PathToOutputFiles = 'C:\neuronSpikeDetector\SpikeDetection\SpikeDetection\TestData\'
%PathToOutputFiles = 'C:\neuronSpikeDetector\Matlab\ConvertToC++\'
PathToOutputFiles = 'C:\AxiocamSDK\cameraZeiss\stimulateSpikeDetector\stimulateSpikeDetector\TestData'

if strcmp(UsingSimulatedData, 'YES')
    ChannelsInDataToUse = 3:34;
else
    ChannelsInDataToUse = 1:32;
end

%% Generate Rez-info file
fullFileName = fullfile(PathToOutputFiles, 'RezInfo.bin');

if exist(PathToOutputFiles) == 0
    mkdir(PathToOutputFiles);
end

if strcmp(filterType, 'Dsort')
    RezToSave = rez.st(:, [1 8]);
else
    if strcmp(isKiloSortTemplateMerged, 'YES')
        RezToSave = rez.st3(:, [1 5]);
    else
        RezToSave = rez.st3(:, [1 2]);
    end
end

[fileID meassage] = fopen(fullFileName, 'w');
if length(meassage) == 0
    fwrite(fileID, RezToSave', 'float');
end
fclose('all');

%% Project info file

fullFileName = fullfile(PathToOutputFiles, 'projectInfo.bin');

if exist(PathToOutputFiles) == 0
    mkdir(PathToOutputFiles);
end

if strcmp(filterType, 'Dsort')
    rezFileSize = size(rez.st);
else
    rezFileSize = size(rez.st3);
end
projectInfo = rezFileSize(1);

[fileID meassage] = fopen(fullFileName, 'w');
if length(meassage) == 0
    fwrite(fileID, projectInfo, 'float');
end
fclose('all');

%% Make training data
%RecordFile = strcat(DiectoryToEvaluate, '\sim_binary.dat');
signalOffset = 0;
signalLength_s = 30;
signalGain = 1; 
%signalGain = 6; % 15.6 db
ViewFiguresRunning = 'NO';
ShowFunctionExcTime = 'NO';

if strcmp(filterType, 'Dsort')
    %map = load(rez.ops.chanMap);
    chanMap = 1:32;
    dataType = 'uint16';
else
    chanMap = rez.ops.chanMap;
    dataType = 'int16';
end

Oldsignal = PrepareData( RecordFile, dataType, ChannelsInDataToUse, chanMap, signalOffset, ...
                         signalLength_s, signalGain, fs, ViewFiguresRunning, ShowFunctionExcTime);

fullFileName = fullfile(PathToOutputFiles, 'rawData300000x32.bin');

if exist(PathToOutputFiles) == 0
    mkdir(PathToOutputFiles);
end


[fileID meassage] = fopen(fullFileName, 'w');
if length(meassage) == 0
    fwrite(fileID, Oldsignal', 'float');
end
fclose('all');

%% Make Prediction data
%RecordFile = strcat(DiectoryToEvaluate, '\sim_binary.dat');
signalOffset = 30;
signalLength_s = 30;
signalGain = 1;
%signalGain = 6; % 15.6 db
ViewFiguresRunning = 'NO';
ShowFunctionExcTime = 'NO';

Newsignal = PrepareData( RecordFile, dataType, ChannelsInDataToUse, chanMap, signalOffset, ...
                         signalLength_s, signalGain, fs, ViewFiguresRunning, ShowFunctionExcTime);

fullFileName = fullfile(PathToOutputFiles, 'rawDataForPrediction300000x32.bin');

if exist(PathToOutputFiles) == 0
    mkdir(PathToOutputFiles);
end


[fileID meassage] = fopen(fullFileName, 'w');
if length(meassage) == 0
    fwrite(fileID, Newsignal', 'float');
end
fclose('all');

%% Templates
%TemplatesFile = strcat(DiectoryToEvaluate,'\templates.npy');
MaximumChannelsToUse = 32;
templateGain = 1;
%templateGain = 6; % 15.6 db
pathToNPYMaster = strcat(PrePath, 'MatlabLibs\npy-matlab-master'); % Path to NPY matlab reader project
ViewFiguresRunning = 'NO';
ShowFunctionExcTime = 'NO';


for Y = 1: MaximumNumberOfTemplates

if strcmp(filterType, 'Dsort')
    template = rez.M_template(:,:,Y);
    if( strcmp(ViewFiguresRunning, 'YES') == 1)
        figure
        surf(template)
        title(['Template: ' num2str(Y)])
        xlabel('Channel [#]'),ylabel('sampling points'), zlabel('Amplitude')
    end    
else
    templateCurrentlyTesting = Y;
    template = PrepareTemplate( TemplatesFile, templateCurrentlyTesting, [1:MaximumChannelsToUse], ...
                            templateGain, pathToNPYMaster, ViewFiguresRunning, ShowFunctionExcTime);
end                        
    fullFileName = fullfile(strcat(PathToOutputFiles, '\Templates'), strcat('template_', num2str(Y), '.bin'));

    if exist(strcat(PathToOutputFiles, '\Templates')) == 0
        mkdir(strcat(PathToOutputFiles, '\Templates'));
    end


    [fileID meassage] = fopen(fullFileName, 'w');
    if length(meassage) == 0
        fwrite(fileID, template', 'float');
    else
        fprintf('Error writing!\n');
    end
    fclose('all');
                        
end
