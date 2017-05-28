FRAME_LIMIT = 2;

v = VideoReader('xylophone.mp4');
v.CurrentTime = 0;

frameCount = 0;
clear prevFrameAmplitude prevFramePhase outFrames;

while hasFrame(v) && frameCount < FRAME_LIMIT
    frame = readFrame(v);
    labFrame = im2double(rgb2lab(frame));
    
    if exist('prevFramePhase', 'var')
        for i=1:3 
            [ outFrames(:,:,i,:), prevFrameAmplitude(:,i), prevFramePhase(:,i) ] = interpolateFrames( labFrame(:,:,i), prevFrameAmplitude(:,i), prevFramePhase(:,i));
        end
        
        p = implay(lab2rgb(outFrames));
        waitfor(p);
    else %First frame
        %Pre-allocate arrays
        [ ~, prevFrameAmplitude, prevFramePhase, numFrames ] = interpolateFrames( labFrame(:,:,1) );
        prevFrameAmplitude = [prevFrameAmplitude, prevFrameAmplitude, prevFrameAmplitude];
        prevFramePhase = [prevFramePhase, prevFramePhase, prevFramePhase];
        outFrames = zeros([size(labFrame), numFrames]);
        
        for i=2:3 
            [ ~, prevFrameAmplitude(:,i), prevFramePhase(:,i) ] = interpolateFrames( labFrame(:,:,i) );
        end
    end
    
    frameCount = frameCount + 1;
end


