L = 5; %pyramid levels
LAMBDA = 1.2;
TAU = 0.2;
STEP = 0.1;

v = VideoReader('xylophone.mp4');
v.CurrentTime = 0;

% set(gcf,'un','n','pos',[0,0,1,1]);figure(gcf)

frameCount = 0;

clear currentPhase prevPhase

while hasFrame(v) && frameCount < 2
    
    frame = readFrame(v);

    %TODO: use Lab rgb2lab();
    [pyr,pind] = buildSCFpyr(im2double(rgb2gray(frame)),L,1);
    currentAmplitude = abs(pyr);
    currentPhase = angle(pyr);
    
    if exist('prevPhase', 'var')
        phaseDiff = prevPhase - currentPhase;
        diff = atan2(sin(phaseDiff),cos(phaseDiff));
        
        phiHat = zeros(size(currentPhase));
        clear prevPhaseBand1
        
        numLevels = spyrHt(pind);
        for currentLevel = numLevels:-1:1
            %TODO: for all bands
            numBands = spyrNumBands(pind);
            
            for currentBand = 1:numBands
                
            end
            
            phaseBand1 = spyrBand(currentPhase, pind, currentLevel, 1);

            if exist('prevLevelPhaseBand1', 'var')
                %Band 1
                resizedPrevLevelBand1 = imresize(prevLevelPhaseBand1, size(phaseBand1));
                phaseDiff = resizedPrevLevelBand1 - LAMBDA * phaseBand1;
                phi = atan2(sin(phaseDiff),cos(phaseDiff));
                
                %TODO
%                 phiLimit = TAU * pi * LAMBDA ^ (numLevels - currentLevel);
%                 resizedPrevBand1 > phiLimit
                
                indices = abs(phi) > pi/2;
                resizedPrevLevelBand1(indices) = phaseBand1(indices);
                
                %Adjust phase
                currentLevelDiff = spyrBand(diff, pind, currentLevel, 1);
                maxValue = ceil(size(phaseBand1, 1) / 2);
                allValues = zeros([size(currentLevelDiff),maxValue+1]);
                for gamma = 0:1:maxValue; 
                    allValues(:,:,gamma+1) = (resizedPrevLevelBand1 - (currentLevelDiff + gamma * 2 *pi)) .* (resizedPrevLevelBand1 - (currentLevelDiff + gamma * 2 *pi));
                end
                %second 1 is current band
                currentIndices = pyrBandIndices(pind,1 + 1 + numBands*(currentLevel-1));
                [~, gammaStar] = min(allValues, [], 3);
                phiHat(currentIndices) = currentLevelDiff + (2*(gammaStar-1)*pi);
            end
            

            prevLevelPhaseBand1 = phaseBand1;

%             subplot(2, numLevels, (currentLevel-1)*2 + 1);
%             imshow(currentVal, []);
%             subplot(2, numLevels, (currentLevel-1)*2 + 2);
%             imshow(currentPhase, [-pi, pi]);
        end
        
        %Interpolate phase and reconstruct
        imageIndex = 1;
        for alpha = 0:STEP:1
            phiAlpha = prevPhase + alpha.*phiHat;
            resultingAmplitude = prevAmplitude * (1-alpha) + currentAmplitude * alpha;
            
            %Chose closer high frequency residual
            hfIndices = pyrBandIndices(pind,band);
            if(alpha < 0.5)
                resultingAmplitude(hfIndices) = prevAmplitude(hfIndices);
            else
                resultingAmplitude(hfIndices) = currentAmplitude(hfIndices);
            end
            
            resultingPyr = resultingAmplitude + 1i*phiAlpha;
            res = reconSFpyr(resultingPyr,pind);
            
            subplot(2, size(0:STEP:1), imageIndex);
            imshow(res);
            imageIndex = imageIndex + 1;
        end
            
        drawnow
    end
    
    prevPhase = currentPhase;
    prevAmplitude = currentAmplitude;
    frameCount = frameCount + 1;
end


