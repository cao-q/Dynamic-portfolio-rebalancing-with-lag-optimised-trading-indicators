function [inputTrain, predOutTrain, outputTrain, trainErr, ...
    inputTest, predOutTest, outputTest, testErr] = ...
    serofamPredict(data, testPercent, tuneNetwork, predDepth, inputDepth)

[inputTrain, outputTrain, inputTest, outputTest] = ...
    prepData(data, inputDepth, testPercent);

% 2-Fold validation
foldSize = floor(size(inputTrain, 1)/2);
cvInputTrain = cell(3, 1);
cvOutputTrain = cell(3, 1);
cvInputTrain{1} = inputTrain(1:foldSize, :);
cvOutputTrain{1} = outputTrain(1:foldSize, :);    
cvInputTrain{2} = inputTrain(foldSize+1:end, :);
cvOutputTrain{2} = outputTrain(foldSize+1:end, :);    
cvInputTrain{3} = inputTrain;
cvOutputTrain{3} = outputTrain;

x = [];
if ~tuneNetwork
    SeroFAMParam = load('SeroFAMParam.mat');
    x = SeroFAMParam.x;
end
if isempty(x)
    %% Tune SeroFAM with GA
    % LB/UB: [halfLife representationGain ruleFireThreshold binWidth ...
    % maxCluster gapModifier]
    lb = [1 0 0 0.1 5 0.1];
    ub = [200 1 1 10 100 10];
    funcTuneSeroFam = @(x) tuneSeroFam(x, cvInputTrain, cvOutputTrain);
    gaOpt = optimoptions('ga');
    gaOpt.UseParallel = true;
    gaOpt.Display = 'iter';
    gaOpt.FunctionTolerance = 1e-3;
    gaOpt.MaxStallGenerations = 20;
    x = ga(funcTuneSeroFam, 6, [], [], [], [], lb, ub, [], 5, gaOpt);
    save('SeroFAMParam.mat', 'x');
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
    runSeroFam(inputTrain, outputTrain, cfg, [], [], [], predDepth);

% figure; hold on;
% plot(outputTrain);
% plot(predOutTrain);
% title(sprintf('Training Set (SeroFAM Train Error: %.3f)', trainErr));

[predOutTest, testErr, network, fcState, ruleParam] = ...
    runSeroFam(inputTest, outputTest, cfg, network, fcState, ruleParam, predDepth);

% figure; hold on;
% plot(outputTest);
% plot(predOutTest);
% title(sprintf('Test Set (SeroFAM Test Error: %.3f)', testErr));
