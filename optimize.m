function [ out ] = optimize( gamma , resizedPrevBand, currentLevelDiff)
%OPTIMIZE Summary of this function goes here
%   Detailed explanation goes here

    out = (resizedPrevBand - (currentLevelDiff + gamma * 2 *pi)) .* (resizedPrevBand - (currentLevelDiff + gamma * 2 *pi));
end

