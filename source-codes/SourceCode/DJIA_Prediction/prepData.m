function [inputTrain, outputTrain, inputTest, outputTest] = ...
    prepData(data, nHistory, testPercent)

inputIdx = (nHistory:(length(data)-1))' - (0:(nHistory-1));
input = data(inputIdx);
output = data(inputIdx(:, 1)+1);

idxTest = floor((1-testPercent) * size(input, 1));
inputTrain = input(1:idxTest-1, :);
outputTrain = output(1:idxTest-1, :);
inputTest = input(idxTest:end, :);
outputTest = output(idxTest:end, :);

