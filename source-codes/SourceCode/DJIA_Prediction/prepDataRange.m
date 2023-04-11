function [inputTrain, outputTrain, inputTest, outputTest] = ...
    prepDataRange(data, nHistory, ~, startIdx, endIdx)

inputIdx = (nHistory:(length(data)-1))' - (0:(nHistory-1));
input = data(inputIdx);
output = data(inputIdx(:, 1)+1);

inputTrain = input(1:startIdx-1, :);
outputTrain = output(1:startIdx-1, :);
inputTest = input(startIdx:endIdx, :);
outputTest = output(startIdx:endIdx, :);

