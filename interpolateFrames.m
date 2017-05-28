function [ outFrames, amplitude, phase, numFrames ] = interpolateFrames( nextFrame, prevFrameAmplitude, prevFramePhase )
    %Parameters
    L = 5; %pyramid levels
    LAMBDA = 1.2;
    TAU = 0.2;
    BANDS = 8;
    
    STEP = 0.1;

    [pyr,pind] = buildSCFpyr(nextFrame,L,BANDS);
    currentAmplitude = abs(pyr);
    currentPhase = angle(pyr);
    
    if exist('prevFramePhase', 'var')
        phaseDiff = currentPhase - prevFramePhase;
        diff = atan2(sin(phaseDiff),cos(phaseDiff));
        
        phiHat = zeros(size(currentPhase));

        numLevels = spyrHt(pind);
        numBands = spyrNumBands(pind);
        for currentLevel = 1:numLevels
            
            for currentBand = 1:numBands
                currentLevelPhase = spyrBand(currentPhase, pind, currentLevel, currentBand);
                
                if(currentLevel < numLevels-1)
                    coarserLevelPhase = imresize(spyrBand(currentPhase, pind, currentLevel+1, currentBand), size(currentLevelPhase));

                    %Shift correction
                    phaseDiff = currentLevelPhase - LAMBDA * coarserLevelPhase;
                    phi = atan2(sin(phaseDiff),cos(phaseDiff));

                    %Bounded phase shift
                    phiLimit = TAU * pi * LAMBDA ^ (numLevels - currentLevel);

                    indicesToCorrect = abs(phi) > pi/2 | currentLevelPhase > phiLimit;
                    currentLevelPhase(indicesToCorrect) = LAMBDA * coarserLevelPhase(indicesToCorrect);
                else
                    indicesToCorrect = currentLevelPhase > phiLimit;
                    currentLevelPhase(indicesToCorrect) = 0;
                end

                %Adjust phase
                currentLevelDiff = spyrBand(diff, pind, currentLevel, currentBand);
                maxValue = ceil(size(currentLevelPhase, 1) / 2);
                allValues = zeros([size(currentLevelDiff),maxValue+1]);
                for gamma = 0:1:maxValue; 
                    allValues(:,:,gamma+1) = (currentLevelPhase - (currentLevelDiff + gamma * 2 *pi)) .* (currentLevelPhase - (currentLevelDiff + gamma * 2 *pi));
                end
                currentIndices = pyrBandIndices(pind,1 + currentBand + numBands*(currentLevel-1));
                [~, gammaStar] = min(allValues, [], 3);
                phiHat(currentIndices) = currentLevelDiff + (2*(gammaStar-1)*pi);
            end
        end
        
        %Interpolate phase and reconstruct
        numFrames = 1/STEP + 1;
        outFrames = zeros([size(nextFrame), numFrames]);

        imageIndex = 1;
        for alpha = 0:STEP:1
            phiAlpha = prevFramePhase + alpha.*phiHat;
            resultingAmplitude = prevFrameAmplitude * (1-alpha) + currentAmplitude * alpha;

            %Choose closer high frequency residual
            hfIndices = pyrBandIndices(pind,1);
            phiAlpha(hfIndices) = prevFramePhase(hfIndices);
            if(alpha < 0.5)
                resultingAmplitude(hfIndices) = prevFrameAmplitude(hfIndices);
            else
                resultingAmplitude(hfIndices) = currentAmplitude(hfIndices);
            end

            resultingPyr = resultingAmplitude.*exp(phiAlpha*1i);
            outFrames(:,:,imageIndex) = reconSFpyr(resultingPyr,pind);
            imageIndex = imageIndex + 1;
        end
    else
        outFrames = [];
        numFrames = 1/STEP + 1;
    end
    
    phase = currentPhase;
    amplitude = currentAmplitude;
end

