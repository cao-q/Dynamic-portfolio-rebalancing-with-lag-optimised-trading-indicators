function [predOutTrain, outputTrain, trainErr, ...
    predOutTest, outputTest, testErr] = ...
    anfisPredict(data, testPercent, nHistory)

[inputTrain, outputTrain, inputTest, outputTest] = ...
    prepData(data, nHistory, testPercent);

% % Prep k-Fold cross validation for ANFIS
% k = 3;
% foldSize = size(inputTrain, 1)/k;
% stepidx = round(0 : foldSize : size(inputTrain, 1));
% % Set default random number generator.    
% rng('default');
% randIdx = randperm(size(inputTrain, 1));
% 
% cvInputTrain = cell(k, 1);
% cvOutputTrain = cell(k, 1);
% cvInputVet = cell(k, 1);
% cvOutputVet = cell(k, 1);
% for i = 1 : k
%     inTrain = inputTrain;
%     inTrain(randIdx(stepidx(i)+1:stepidx(i+1)), :) = [];
%     outTrain = outputTrain;
%     outTrain(randIdx(stepidx(i)+1:stepidx(i+1)), :) = [];
% 
%     cvInputTrain{i} = inTrain;
%     cvOutputTrain{i} = outTrain;    
%     cvInputVet{i} = inputTrain(randIdx(stepidx(i)+1:stepidx(i+1)), :);
%     cvOutputVet{i} = outputTrain(randIdx(stepidx(i)+1:stepidx(i+1)), :);
% end

% Create FIS network
genOpt = genfisOptions('FCMClustering');
fis = genfis(inputTrain,outputTrain, genOpt);

%% Tune rule parameters.
tuningOpt = tunefisOptions;
tuningOpt.Method = "anfis";

% Get rule parameter settings.
[in, out] = getTunableSettings(fis);
% Set default random number generator.    
rng('default');

outputFIS = tunefis(fis,[in; out],inputTrain,outputTrain,tuningOpt);

%% Evaluate training & test data
[predOutTrain, trainErr] = evaluateFis(outputFIS, inputTrain, outputTrain);

[predOutTest, testErr] = evaluateFis(outputFIS, inputTest, outputTest);
% figure; hold on;
% plot(outputTest);
% plot(predOut1);
% plot(predOut2);
% title(sprintf('Test Set (FIS1 Test Error: %.3f, FIS2 Test Error: %.3f)', testErr1, testErr2));


