function [ Extraoffset ] = VerifyOffset( RezRelevant, GroundTruthRelevant)
%VERIFYOFFSET Summary of this function goes here
%   Detailed explanation goes here
    MaximumOffsetAdjust = 5;
               
    Positivematches = 0;
    NegativeMatches = 0;
    smallestSize = numel(RezRelevant(:,1));
    if numel(GroundTruthRelevant) < smallestSize;
        smallestSize = numel(GroundTruthRelevant);
    end
    
    Found = 0;
    Extraoffset = 0;
    
    for Y = 0 : 3
        if Found == 1
            break;
        end
        
        Positivematches = 0;
        NegativeMatches = 0;
        
        for I = 1 : smallestSize
            test1 = find(RezRelevant(I) == (GroundTruthRelevant+Y));
            test2 = find(RezRelevant(I) == (GroundTruthRelevant-Y));
            if numel(test1) > 0
                Positivematches = Positivematches + 1;
            elseif numel(test2) > 0
                NegativeMatches = NegativeMatches + 1;
            end
            
            if Positivematches > (smallestSize*0.5)
                Found = 1;
                Extraoffset = Y;
                break;
            elseif NegativeMatches > (smallestSize*0.5)
                Found = 1;
                Extraoffset = -Y;
                break;
            end
        end
    end
    
    
    

end

