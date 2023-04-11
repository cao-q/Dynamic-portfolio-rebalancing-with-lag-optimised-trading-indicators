function [network, fcState, ruleParam] = initSeroFAM( ...
    numInput, numOutput, cfg)

network.numInput = numInput;
network.numOutput = numOutput;
MAX_NEURON_INPUTFUZZY = cfg.maxCluster * numInput;
MAX_NEURON_OUTPUTFUZZY = cfg.maxCluster * numOutput;

% network.inputFuzzyParam (Layer 2)
inputFuzzyParam.stability = nan(MAX_NEURON_INPUTFUZZY, 1);
inputFuzzyParam.centroid = nan(MAX_NEURON_INPUTFUZZY, 1);
inputFuzzyParam.lSigma = nan(MAX_NEURON_INPUTFUZZY, 1);
inputFuzzyParam.rSigma = nan(MAX_NEURON_INPUTFUZZY, 1);
inputFuzzyParam.lShoulder = nan(MAX_NEURON_INPUTFUZZY, 1);
inputFuzzyParam.rShoulder = nan(MAX_NEURON_INPUTFUZZY, 1);
inputFuzzyParam.mergedTo = nan(MAX_NEURON_INPUTFUZZY, 1);
inputFuzzyParam.isNew = false(MAX_NEURON_INPUTFUZZY, 1);
inputFuzzyParam.isGarbage = false(MAX_NEURON_INPUTFUZZY, 1);
network.inputFuzzyParam = inputFuzzyParam;

% network.outputFuzzyParam (Layer 4)
outputFuzzyParam.stability = nan(MAX_NEURON_OUTPUTFUZZY, 1);
outputFuzzyParam.centroid = nan(MAX_NEURON_OUTPUTFUZZY, 1);
outputFuzzyParam.lSigma = nan(MAX_NEURON_OUTPUTFUZZY, 1);
outputFuzzyParam.rSigma = nan(MAX_NEURON_OUTPUTFUZZY, 1);
outputFuzzyParam.lShoulder = nan(MAX_NEURON_OUTPUTFUZZY, 1);
outputFuzzyParam.rShoulder = nan(MAX_NEURON_OUTPUTFUZZY, 1);
outputFuzzyParam.mergedTo = nan(MAX_NEURON_OUTPUTFUZZY, 1);
outputFuzzyParam.isNew = false(MAX_NEURON_OUTPUTFUZZY, 1);
outputFuzzyParam.isGarbage = false(MAX_NEURON_OUTPUTFUZZY, 1);
network.outputFuzzyParam = outputFuzzyParam;

% network.link12 (Layer 1-2):
% Value indicates input neuron, index indicates input fuzzy neuron
network.linkIdxIn2F = zeros(MAX_NEURON_INPUTFUZZY, 1);

% network.link23 (Layer 2-3):
network.linkF2R = false(MAX_NEURON_INPUTFUZZY, cfg.MAX_NEURON_PREMISE);

% network.link34 (Layer 3-4):
network.linkR2F = false(cfg.MAX_NEURON_PREMISE, MAX_NEURON_OUTPUTFUZZY);
network.linkWeightR2F = zeros(cfg.MAX_NEURON_PREMISE, MAX_NEURON_OUTPUTFUZZY);

% network.link45 (Layer 4-5):
network.linkIdxF2Out = zeros(MAX_NEURON_OUTPUTFUZZY, 1);

% For Fuzzy Clustering
% Input & Output dataspace
dataSpaceStruct.sumSquareM = 0;
dataSpaceStruct.sumM = 0;
dataSpaceStruct.sumCurrency = 0;
dataSpaceStruct.stSpace = 0;
fcState.inputDataSpace = repmat(dataSpaceStruct, network.numInput, 1);
fcState.outputDataSpace = repmat(dataSpaceStruct, network.numOutput, 1);

% Input & Output binCollector
binCollectorStruct.basePtr = nan(cfg.MAX_DATA_BIN, 1);
binCollectorStruct.twaMean = zeros(cfg.MAX_DATA_BIN, 1);
binCollectorStruct.currency = zeros(cfg.MAX_DATA_BIN, 1);
binCollectorStruct.count = zeros(cfg.MAX_DATA_BIN, 1);
fcState.inputBinCollector = repmat(binCollectorStruct, network.numInput, 1);
fcState.outputBinCollector = repmat(binCollectorStruct, network.numOutput, 1);

% For rule learning
ruleParam.rulePotential = nan(cfg.MAX_NEURON_PREMISE, 1);
ruleParam.efficacy = zeros(cfg.MAX_NEURON_PREMISE, MAX_NEURON_OUTPUTFUZZY);
ruleParam.timeUpdate = zeros(cfg.MAX_NEURON_PREMISE, MAX_NEURON_OUTPUTFUZZY);
ruleParam.topCache = zeros(cfg.MAX_NEURON_PREMISE, MAX_NEURON_OUTPUTFUZZY);
ruleParam.baseCache = zeros(cfg.MAX_NEURON_PREMISE, MAX_NEURON_OUTPUTFUZZY);
