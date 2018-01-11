%% Setup
% --------------- Debug/Figures ---------------

TemplatesToTest = 1:MaximumNumberOfTemplates;
TemplatesToTestElements = numel(TemplatesToTest);
SelectSpecificTemplatesToAvoidUsing = []; %[1:10, 12:64]; % OBS - ONLY FOCUSING ON TEMPLATE 11 (10 IN PHY)
TimeBaseSlack = 0;
templateSize = 61;
NumberOfChannelsToInvestigate = 9;
templateSizeTestingThisRound = 17;
counter = 1;
firstRun = 1;

for I = TemplatesToTest(1) : TemplatesToTest( TemplatesToTestElements )
    fprintf('Analysing spikes for template: %.0f\n', I);
    tic
    templateCurrentlyTesting = I;

    %% Investigate if template is matched to signal by Kilosort
    [ templatesPresent, numberOfTemplatesPresent ] = ExtractTemplatePresentInSignalMerged(rez, MaximumNumberOfTemplates, isKiloSortTemplateMerged, signalLength_s, signalOffset, fs);

    %% Find relevant channels to investigate based on the template signal                                                             
    if templatesPresent(templateCurrentlyTesting) > 0 && numel(find(SelectSpecificTemplatesToAvoidUsing == templateCurrentlyTesting)) == 0

        %% Get template for the test
        template = PrepareTemplate( TemplatesFile, templateCurrentlyTesting, [1:32], ...
                                                                     templateGain, pathToNPYMaster, 'NO', 'NO');
        
        %% Possibly crop template
        if strcmp(findTemplateOffsetAndChannelAutomatic, 'YES')
           [ mainChannel, templateSpikeOffset, ~ ] = GetTemplateInfo( template ); 
        end

        if NumberOfChannelsToInvestigate < MaximumChannelsToUse

            ChannelsToInvestigate = ChooseChannels(mainChannel,NumberOfChannelsToInvestigate);

            template = template(:,ChannelsToInvestigate);
        end

        if templateSizeTestingThisRound < MaximumNumberOfTemplateSamples
           template = template(ChooseTemplateSamples(templateSpikeOffset, templateSizeTestingThisRound),:);   
        end


        %% Get Data for the test
        if firstRun == 1
            signal = PrepareDataInVivo( RecordFile, ...
                                        1:32, rez, signalOffset, ...
                                        signalLength_s, 1, fs, 'NO', 'NO');
            
            signal1D = reshape(signal,[1 MaximumChannelsToUse*signalLength_s*fs]);
        
            signal1D_rms = rms(signal1D);

            firstRun = 0;
        end     
   
        %% Get 'ground truth' from kilosort estimation list !
        
        [rez_st3_templateRelevant] = ExtractKilosortInfoUnaffected( signalOffset, signalLength_s , templateCurrentlyTesting, rez, fs, isKiloSortTemplateMerged );
        
        SpikeValue = zeros(1, numel(rez_st3_templateRelevant(:,1)));
        
        for X = 1 : numel(rez_st3_templateRelevant(:,1))
%             figure;
%             surf(signal(grundTruth.gtRes(X)-templateSpikeOffset:grundTruth.gtRes(X)-templateSpikeOffset+templateSize,:));
%             title('Unfiltered Raw Data')
%             xlabel('Channel [#]'),ylabel('sampling points'), zlabel('Amplitude') 
            SpikeValue(X) = signal(rez_st3_templateRelevant(X,1)-1, mainChannel); 
        end
        
        %signal1D = reshape(signal,[1 MaximumChannelsToUse*signalLength_s*fs]);
        
        %signal1D_rms = rms(signal1D);
        
        snr(counter) = abs(mean(SpikeValue)) / signal1D_rms;
        counter = counter + 1;        
        %fprintf('SNR of spikes related to template(%.0f) is: %.2f dB \n',templateCurrentlyTesting, 20*log10(snr(counter-1)));
        
    else
         %fprintf('WARNING: The requested template(%.0f) is not present in the kilosort estimation list!\n', templateCurrentlyTesting);
    end

    ElapsedTime = toc;
    %fprintf('Processing the spikes of template(%.0f) took %.2f seconds.\n\n',templateCurrentlyTesting, ElapsedTime);
end

fprintf('Combined SNR of All spikes is: %.2f dB \n', 20*log10(mean(snr)));
