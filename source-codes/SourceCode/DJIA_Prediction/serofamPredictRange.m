function [inputTrain, predOutTrain, outputTrain, trainErr, ...
    inputTest, predOutTest, outputTest, testErr] = ...
    serofamPredict(data, testPercent, tuneNetwork, startIdx, endIdx)

[inputTrain, outputTrain, inputTest, outputTest] = ...
    prepDataRange(data, 1, testPercent, startIdx, endIdx);

x = [];
if ~tuneNetwork
    SeroFAMParam = load('SeroFAMParam.mat');
    x = SeroFAMParam.x;
end

%% Setup SeroFAM with tuned hyperparameters
cfg = cfgSeroFAM();
cfg.halfLife = x(1);
cfg.forgettor = computeForgettor(cfg.halfLife, cfg.isPureHebbian);
cfg.representationGain = x(2);
cfg.ruleFireThreshold = x(3); 
cfg.binWidth = x(4);
cfg.maxCluster = x(5);
cfg.gapModifier = x(6);

[predOutTrain, trainErr, network, fcState, ruleParam] = ...
    runSeroFam(inputTrain, outputTrain, cfg, [], [], [], 1);

[predOutTest, testErr, network, fcState, ruleParam] = ...
    runSeroFam(inputTest, outputTest, cfg, network, fcState, ruleParam, 1);