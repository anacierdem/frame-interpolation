L = 5; %pyramid levels
LAMBDA = 1.2;
TAU = 0.2;

v = VideoReader('xylophone.mp4');
v.CurrentTime = 0;

% set(gcf,'un','n','pos',[0,0,1,1]);figure(gcf)

frameCount = 0;

clear currentPhase prevPhase

while hasFrame(v) && frameCount < 2
    
    frame = im2double(readFrame(v));

    %RGB channels
    for i=1:3
        [pyr,pind] = buildSCFpyr(frame(:,:,i),L,1);

        if ~exist('currentPhase', 'var')
            currentPhase = zeros([size(pyr,1), 3]);
        end
        
%         showSpyr(pyr, pind);
        
        currentPhase(:,i) = angle(pyr);

    end
    
    if exist('prevPhase', 'var')
        phaseDiff = prevPhase - currentPhase;
        diff = atan2(sin(phaseDiff),cos(phaseDiff));
        
        clear prevPhaseBand1
        
        numLevels = spyrHt(pind);
        for currentLevel = numLevels:-1:2 %1 is high freq. residuals
            %TODO: for all bands
            spyrNumBands(pind);
            
            phaseBand1 = spyrBand(currentPhase, pind, currentLevel, 1);

            if exist('prevPhaseBand1', 'var')
                %Band 1
                resizedPrevBand1 = imresize(prevPhaseBand1, size(phaseBand1));
                phaseDiff = resizedPrevBand1 - LAMBDA * phaseBand1;
                phi = atan2(sin(phaseDiff),cos(phaseDiff));
                
                %TODO
%                 phiLimit = TAU * pi * LAMBDA ^ (numLevels - currentLevel);
%                 resizedPrevBand1 > phiLimit
                
                indices = abs(phi) > pi/2;
                resizedPrevBand1(indices) = phaseBand1(indices);
                
                %Adjust phase
                currentLevelDiff = spyrBand(diff, pind, currentLevel, 1);
                maxValue = ceil(size(phaseBand1, 1) / 2);
                allValues = zeros([size(currentLevelDiff),maxValue+1]);
                for gamma = 0:1:maxValue; 
                    allValues(:,:,gamma+1) = (resizedPrevBand1 - (currentLevelDiff + gamma * 2 *pi)) .* (resizedPrevBand1 - (currentLevelDiff + gamma * 2 *pi));
                end
                
                [~, gammaStar] = min(allValues, [], 3);
                phiHat = currentLevelDiff + (2*(gammaStar-1)*pi);
                
                %Interpolate phase
%                 phiAlpha = 

            end
            
            prevPhaseBand1 = phaseBand1;

%             subplot(2, numLevels, (currentLevel-1)*2 + 1);
%             imshow(currentVal, []);
%             subplot(2, numLevels, (currentLevel-1)*2 + 2);
%             imshow(currentPhase, [-pi, pi]);
        end
        drawnow
    end
    
    prevPhase = currentPhase;
    frameCount = frameCount + 1;
end

res = reconSFpyr(pyr,pind);
