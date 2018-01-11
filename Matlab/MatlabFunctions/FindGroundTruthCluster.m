function [ GroundTruthClusterID ] = FindGroundTruthCluster( templateToTest, rez, groundTruthTable )
%FINDGROUNDTRUTHCLUSTER Summary of this function goes here
%   Detailed explanation goes here
    rezSt3Ind = find(rez.st3(:,5) == templateToTest);
    groundTruthTableLocal.gtClu = groundTruthTable.gtClu;
    GroundTruthClusterID = 0;  
    maxLookTrough = 7;
    
    if numel(rezSt3Ind) > 0 
        
        for Y = 1 : maxLookTrough    
            
            if Y == 1
               groundTruthTableLocal.gtRes = groundTruthTable.gtRes;  
            elseif Y <= ceil(maxLookTrough/2);
               groundTruthTableLocal.gtRes = groundTruthTable.gtRes - (Y-1); % offset 
            else
               groundTruthTableLocal.gtRes = groundTruthTable.gtRes + (Y-ceil(maxLookTrough/2)); % offset
            end
            
            
%             diff = numel(groundTruthTableLocal.gtRes) - numel(rezSt3Ind);
%             paddedArray = padarray(rez.st3(rezSt3Ind,1),diff, 'post');
%             %markAllResultK2G1 = setdiff(groundTruthTableLocal.gtRes, paddedArray);
%             markAllResultK2G2 = setdiff(paddedArray, groundTruthTableLocal.gtRes);
% 
%             if numel(find(markAllResultK2G2 == 0)) > 0
%                 indexToThroughAway = find(markAllResultK2G2 == 0);
%                 markAllResultK2G2(indexToThroughAway) = [];
%             end
% 
%             differenceCount = (numel(rezSt3Ind) - numel(markAllResultK2G2));  
%             
%             if differenceCount > 30 && differenceCount < (numel(rezSt3Ind)*0.9)
%                 
%             end
%             %markAllResultK2G3 =  union(markAllResultK2G1, markAllResultK2G2);

            
            
            firstTimeStamp = rez.st3(rezSt3Ind(1),1);      
            indsInGT = find(groundTruthTableLocal.gtRes == firstTimeStamp);
            if numel(indsInGT) > 0
               % find other time stamp and compare with timestamps

               indsForSameCluster = find(groundTruthTableLocal.gtClu == groundTruthTableLocal.gtClu(indsInGT(1)));
               GroundTruthClusterID = groundTruthTableLocal.gtClu(indsInGT(1));

               CorectCounter = 0;
               WrongCounter = 0;
               for I = 1 : numel(rezSt3Ind)
                groundTruthTimestamp = groundTruthTableLocal.gtRes(indsForSameCluster(I));
                rezFileTimeStamp = rez.st3(rezSt3Ind(I-WrongCounter),1);
                if groundTruthTimestamp  == rezFileTimeStamp 
                    CorectCounter = CorectCounter + 1;
                else
                   WrongCounter = WrongCounter + 1;    
                end
               end
               
               if CorectCounter < 1
                   GroundTruthClusterID = 0;
               else
                   return;
               end              
            end
        end
    end
end

