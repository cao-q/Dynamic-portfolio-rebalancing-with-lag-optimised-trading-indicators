function [network, fcState, ruleParam] = learnSeroFAM( ...
    network, fcState, ruleParam, currTime, input, output, cfg)
dbgPrint(sprintf('currTime(%f): learnSeroFAM', currTime));

% Learning membership structure 
[network, fcState] = seroSparseBinFuzzyClustering(network, fcState, ...
    input, output);

% learning of rule base
[network, ruleParam] = learnRule(network, ruleParam, ...
    currTime, input, output, cfg);
end

function out = learnFuzzyActivation(in, linkIdx, fuzzyParam)
out = nan(length(linkIdx), 1);
validLink = (linkIdx > 0);
out(validLink) = asymmetricGaussian( ...
    in(linkIdx(validLink)), ...
    fuzzyParam.centroid(validLink), ...
    fuzzyParam.lSigma(validLink), ...
    fuzzyParam.rSigma(validLink), ...
    fuzzyParam.lShoulder(validLink), ...
    fuzzyParam.rShoulder(validLink));
end

function [network, ruleParam] = learnRule(network, ruleParam, ...
    currTime, input, output, cfg)
dbgPrint('learnRule');

inputFuzzyParam = network.inputFuzzyParam;
outputFuzzyParam = network.outputFuzzyParam;
numInput = network.numInput;
linkIdxIn2F = network.linkIdxIn2F;
linkF2R = network.linkF2R;
linkIdxF2Out = network.linkIdxF2Out;

% Get activation values of input & output
activationInputFuzzy = learnFuzzyActivation(input, ...
    linkIdxIn2F, inputFuzzyParam);
activationOutputFuzzy = learnFuzzyActivation(output, ...
    linkIdxF2Out, outputFuzzyParam);

% * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
% Conceptualizing the self-reorganzing ACPOP-BCM 
% * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
% When to create new rules?
% (a) when babyNeurons are added in the input layer.
% (b) or, when additional premise improves localization.
%     CREATE NEW PREMISE SET
% 
% When to extend the no. of rule links?
% (c) when babyNeurons are added in the output layer. 
%     rule-links start with zero potential
%     rule-links start with zero sliding threshold.s
% 
% When to merge premises?
% (d) when garbage neurons are removed in the input layer.
%     premise strength is combined 
% 
% When to merge rule links?
% (e) when garbage neurons are removed in the output layer.
%     rule-link strengths are combined
% * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

% Heterogeneous decay of potential
ruleParam.rulePotential = ruleParam.rulePotential * cfg.forgettor;

[inputFuzzyParam, linkF2R, ruleParam] = reorganizeInputFuzzyNeurons( ...
    inputFuzzyParam, linkF2R, ruleParam, currTime, cfg.forgettor);

[outputFuzzyParam, ruleParam] = reorganizeOutputFuzzySynapses( ...
    outputFuzzyParam, ruleParam, currTime, cfg.forgettor);

[linkF2R, ruleParam] = updateRule(linkF2R, ruleParam, ...
    currTime, activationInputFuzzy, activationOutputFuzzy, ...
    linkIdxIn2F, numInput, linkIdxF2Out, cfg);

% Rule selection
[linkR2F, linkWeightR2F] = onlineRuleSelection( ...
    ruleParam, cfg.ruleFireThreshold);

network.inputFuzzyParam = inputFuzzyParam;
network.linkF2R = linkF2R;
network.linkR2F = linkR2F;
network.linkWeightR2F = linkWeightR2F;
network.outputFuzzyParam = outputFuzzyParam;
end

function [inputFuzzyParam, linkF2R, ruleParam] = ...
    reorganizeInputFuzzyNeurons(inputFuzzyParam, linkF2R, ruleParam, ...
    currTime, forgettor)
dbgPrint('\treorganizeInputFuzzyNeurons');
% fuzzy neurons have been merged
idxMergee = find(inputFuzzyParam.isGarbage);
for i = 1 : length(idxMergee)
    dbgPrint(sprintf('\t\tInputFuzzy deleted(%d)', idxMergee(i)));
    idxMerger = inputFuzzyParam.mergedTo(idxMergee(i));    
    % Merge fuzzy input nodes of premises    
    % Search from the subset of casen attached to merger (goodCase),
    % find if there is a goodCase similar to the badCase
    idxBadRule = find(linkF2R(idxMergee(i), :));
    idxGoodRule = find(linkF2R(idxMerger, :));
    for j = 1 : length(idxBadRule)
        badRuleInput = linkF2R(:, idxBadRule(j));
        badRuleInput(idxMergee(i)) = false; % Ignore Mergee
        foundGoodMatch = false;
        for k = 1 : length(idxGoodRule)
            goodRuleInput = linkF2R(:, idxGoodRule(k));
            goodRuleInput(idxMerger) = false; % Ignore Merger
            if all(badRuleInput == goodRuleInput)
                % Found good match
                foundGoodMatch = true;
                
                % Merge input potential
                ruleParam.rulePotential(idxGoodRule(k)) = ...
                    ruleParam.rulePotential(idxGoodRule(k)) + ...
                    ruleParam.rulePotential(idxBadRule(j));
                
                % Merge synaptic values
                ruleParam = MergeSynapticValue_Rule(currTime, ...
                    idxGoodRule(k), idxBadRule(j), ruleParam, forgettor);
                
                % Delink & delete rule
                [linkF2R, ruleParam] = deleteRule(linkF2R, ruleParam, ...
                    idxBadRule(j));
                
                dbgPrint(sprintf('\t\tRule deleted(%d), replaced by Rule(%d)', idxBadRule(j), idxGoodRule(k)));                
                break;
            end
        end
        if ~foundGoodMatch
            % No match, relink Merger to bad rule 
            linkF2R(idxMerger, idxBadRule(j)) = true;
            linkF2R(idxMergee(i), idxBadRule(j)) = false;
            dbgPrint(sprintf('\t\tinputFuzzy(%d) relinked to rule(%d)', idxMerger, idxBadRule(j)));
        end
    end
end
    
% Delink Mergee
linkF2R(idxMergee, :) = false;
% Clear Mergee
inputFuzzyParam = clearFuzzyParam(inputFuzzyParam, idxMergee);

% Reset isNew flags
inputFuzzyParam.isNew(:) = false;
end

function [outputFuzzyParam, ruleParam] = reorganizeOutputFuzzySynapses( ...
    outputFuzzyParam, ruleParam, currTime, forgettor)
dbgPrint('\treorganizeOutputFuzzySynapses');

% Have not actually updated the sliding threshold for currTime as yet
validRule = (ruleParam.rulePotential > 0);
ruleParam.timeUpdate(validRule, outputFuzzyParam.isNew) = currTime - 1;

% Merge output associations for deleted output fuzzy
idxMergee = find(outputFuzzyParam.isGarbage);
if ~isempty(idxMergee)
    dbgPrint(sprintf('\t\tOutputFuzzy deleted(%d)', idxMergee));
    idxMerger = outputFuzzyParam.mergedTo(idxMergee);    
    ruleParam = MergeSynapticValue_Output(currTime, idxMerger, idxMergee, ...
        ruleParam, forgettor);

    % Delink Mergee & reset r2fParam
    ruleParam.efficacy(:, idxMergee) = 0;
    ruleParam.timeUpdate(:, idxMergee) = 0;
    ruleParam.topCache(:, idxMergee) = 0;
    ruleParam.baseCache(:, idxMergee) = 0;
end

% Clear Mergee
outputFuzzyParam = clearFuzzyParam(outputFuzzyParam, idxMergee);

% Reset isNew flags
outputFuzzyParam.isNew(:) = false;
end

function [linkF2R, ruleParam] = updateRule(linkF2R, ruleParam, ...    
    currTime, activationInputFuzzy, activationOutputFuzzy, ...
    linkIdxIn2F, numInput, linkIdxF2Out, cfg)

dbgPrint('\tupdateRule');

% Step A: get ideal premise nodes from inputLayer
% highestActivation: Highest possible activation; May not be a rule yet
idxBestInputFuzzy = zeros(numInput, 1);
activation = ones(numInput, 1);
for i = 1 : numInput
    idxInputFuzzy = find(linkIdxIn2F == i);
    [activation(i), idx] = max(activationInputFuzzy(idxInputFuzzy));
    idxBestInputFuzzy(i) = idxInputFuzzy(idx);
end
highestActivation = min(activation);
dbgPrint(sprintf('\t\tHighest possible activation (%f)', highestActivation));


% Step B: check current rulebase coverage
% currentActivation: Firing based on existing rulebase
currentActivation = 0;
idxRule = find(any(linkF2R));
if ~isempty(idxRule)
    activation = zeros(length(idxRule), 1);
    for i = 1 : length(idxRule)
        activation(i) = min(activationInputFuzzy(linkF2R(:, idxRule(i))));
    end
    [currentActivation, idx] = max(activation);
    idxBestRule = idxRule(idx);
    dbgPrint(sprintf('\t\tBest rule (#%d) activation (%f)', idxBestRule, currentActivation));
end
% Step C: currentActivation do not meet minActivation
% Create rule link, based on highestActivation
if currentActivation < (highestActivation - cfg.representationGain)
    idxBestRule = find(~any(linkF2R), 1);
    ruleParam.rulePotential(idxBestRule) = 0;
    linkF2R(idxBestInputFuzzy, idxBestRule) = true;
    currentActivation = highestActivation;
    dbgPrint(sprintf('\t\tNew rule (#%d)', idxBestRule));
end

% Update r2fParam
idxOutputFuzzy = find(linkIdxF2Out > 0);

%  Update to t = currTime - 1 
ruleParam = updateSlidingThreshold(ruleParam, currTime - 1, [], ...
    idxBestRule, idxOutputFuzzy, cfg.forgettor);

% Set the spontaneous level to 0.0
theta = zeros(1, length(idxOutputFuzzy));
if ~cfg.isPureHebbian
    % using BCM rate based model equation (Theta ~= 0)
    theta = ruleParam.topCache(idxBestRule, idxOutputFuzzy) ./ ...
        ruleParam.baseCache(idxBestRule, idxOutputFuzzy);
    theta(ruleParam.baseCache(idxBestRule, idxOutputFuzzy) == 0) = 0;
end
preSignal = currentActivation;
postSignal = activationOutputFuzzy(idxOutputFuzzy)';
assoc = (preSignal .* postSignal .* (postSignal - theta));

% Update to t = currTime 
ruleParam = updateSlidingThreshold(ruleParam, currTime, postSignal, ...
    idxBestRule, idxOutputFuzzy, cfg.forgettor);

% Do not let synap weight < 0
ruleParam.efficacy(idxBestRule, idxOutputFuzzy) = max( ...
    ruleParam.efficacy(idxBestRule, idxOutputFuzzy) + assoc, 0);

% Concern: update rule-potential from which synapse?
% (a) updating from all ie. sum(synp_mod) will create bias to 
%     those outputs with synaps for contradiction-correction. 
%     using ambiguity-correction however, this becomes a 
%     plausible choice. see Scenario C 
 
% Scenario A: Take the max positive update. Rule-potential update will 
% be positive or small negative. 

% Scenario B: Take the max absolute update. (CHOSEN)
[~, idx] = max(abs(assoc));
potentialUpdate = assoc(idx);

% Scenario C: Take the sum or average of all the synaps

%Update rule potential
ruleParam.rulePotential(idxBestRule) = ...
    ruleParam.rulePotential(idxBestRule) + potentialUpdate;
end

function [linkR2F, linkWeightR2F] = onlineRuleSelection( ...
    ruleParam, ruleFireThreshold)

dbgPrint('\tonlineRuleSelection');

% Synaptic weight normalization
linkWeightR2F = zeros(size(ruleParam.efficacy));
validRule = (ruleParam.rulePotential > 0);
maxEfficacy =  max(max(ruleParam.efficacy(validRule, :), [], 2), 0);
linkWeightR2F(validRule, :) = ...
    ruleParam.efficacy(validRule, :) ./ maxEfficacy;

% Rule selection
linkR2F = (linkWeightR2F > 0);
potentialThreshold = sum(ruleParam.rulePotential) * (1 - ruleFireThreshold);
[sortedPotential, idxRule] = sort(ruleParam.rulePotential);
idxUnselected = idxRule(cumsum(sortedPotential) <= potentialThreshold);
linkR2F(idxUnselected, :) = false;

dbgPrint(sprintf('\t\tRule selected (%d/%d)', numel(idxRule) - numel(idxUnselected), sum(double(validRule))));
end

function ruleParam = MergeSynapticValue_Rule(currTime, ...
    idxGoodRule, IdxBadRule, ruleParam, forgettor)
idxOutputFuzzy = find(ruleParam.timeUpdate(idxGoodRule, :) ~= ...
    ruleParam.timeUpdate(IdxBadRule, :));
% Synchronize sliding threshold
ruleParam = updateSlidingThreshold(ruleParam, currTime - 1, [], ...
    idxGoodRule, idxOutputFuzzy, forgettor);
ruleParam = updateSlidingThreshold(ruleParam, currTime - 1, [], ...
    IdxBadRule, idxOutputFuzzy, forgettor);

ruleParam.efficacy(idxGoodRule, :) = ruleParam.efficacy(idxGoodRule, :) + ...
    ruleParam.efficacy(IdxBadRule, :);
ruleParam.topCache(idxGoodRule, :) = ruleParam.topCache(idxGoodRule, :) + ...
    ruleParam.topCache(IdxBadRule, :);

% NEVER EVER add the bottom cache, cos it will lead to double counting of bottom!!
end

function ruleParam = MergeSynapticValue_Output(currTime, ...
    idxGoodOutputFuzzy, idxBadOutputFuzzy, ruleParam, forgettor)
for i = 1 : numel(idxGoodOutputFuzzy)
    idxRule = find(ruleParam.timeUpdate(:, idxGoodOutputFuzzy(i)) ~= ...
        ruleParam.timeUpdate(:, idxBadOutputFuzzy(i)));
    % Synchronize sliding threshold
    ruleParam = updateSlidingThreshold(ruleParam, currTime - 1, [], ...
        idxRule, idxGoodOutputFuzzy(i), forgettor);
    ruleParam = updateSlidingThreshold(ruleParam, currTime - 1, [], ...
        idxRule, idxBadOutputFuzzy(i), forgettor);

    ruleParam.efficacy(:, idxGoodOutputFuzzy(i)) = ...
        ruleParam.efficacy(:, idxGoodOutputFuzzy(i)) + ...
        ruleParam.efficacy(:, idxBadOutputFuzzy(i));
    ruleParam.topCache(:, idxGoodOutputFuzzy(i)) = ...
        ruleParam.topCache(:, idxGoodOutputFuzzy(i)) + ...
        ruleParam.topCache(:, idxBadOutputFuzzy(i));
end

% Do not add the bottom cache. It will lead to double counting of bottom!!
end

function ruleParam = updateSlidingThreshold(ruleParam, ...
    updateToTime, postSignal, idxRule, idxOutputFuzzy, forgettor)
if isempty(idxOutputFuzzy) || isempty(idxRule)
    return;
end

timeUpdate = ruleParam.timeUpdate(idxRule, idxOutputFuzzy);
efficacy = ruleParam.efficacy(idxRule, idxOutputFuzzy);
topCache = ruleParam.topCache(idxRule, idxOutputFuzzy);
baseCache = ruleParam.baseCache(idxRule, idxOutputFuzzy);

timeLag = updateToTime - timeUpdate;
idxUpdate = (timeLag > 0);
%Decay Offset
offset = forgettor.^timeLag(idxUpdate);
efficacy(idxUpdate) = efficacy(idxUpdate) .* offset;
if isempty(postSignal)
    topCache(idxUpdate) = (topCache(idxUpdate) .* offset);
else
    topCache(idxUpdate) = (topCache(idxUpdate) .* offset) + ...
        postSignal(idxUpdate).^2;
end

% Remember that the geometric progress is as such
%                                          1 - f^n
% g(n) = 1 + f^1 + f^2 + ... + f^(n-1) = ---------
%                                          1 - f
% since offset = forgettor^timeLag);
% therefore, geometric g(n) = (1 - offset) * _inverseForgettor;
if forgettor < 1
% Original implementation
%     baseCache(idxUpdate) = baseCache(idxUpdate) .* offset + ...
%         ((1 - offset) ./ (1 - forgettor));
% Based on paper
    baseCache(idxUpdate) = baseCache(idxUpdate) .* offset + ...
        forgettor * ((1 - offset) ./ (1 - forgettor));
else
    baseCache(idxUpdate) = baseCache(idxUpdate) .* offset;
end
timeUpdate(idxUpdate) = updateToTime;

ruleParam.timeUpdate(idxRule, idxOutputFuzzy) = timeUpdate;
ruleParam.efficacy(idxRule, idxOutputFuzzy) = efficacy;
ruleParam.topCache(idxRule, idxOutputFuzzy) = topCache;
ruleParam.baseCache(idxRule, idxOutputFuzzy) = baseCache;
end

function [linkF2R, ruleParam] = deleteRule(linkF2R, ruleParam, idxRule)
linkF2R(:, idxRule) = false;
ruleParam.rulePotential(idxRule) = nan;
ruleParam.normalEfficacy(idxRule, :) = 0;
ruleParam.efficacy(idxRule, :) = 0;
ruleParam.timeUpdate(idxRule, :) = 0;
ruleParam.topCache(idxRule, :) = 0;
ruleParam.baseCache(idxRule, :) = 0;
end

function fuzzyParam = clearFuzzyParam(fuzzyParam, idx)
if ~isempty(idx)
    fuzzyParam.stability(idx) = nan;
    fuzzyParam.centroid(idx) = nan;
    fuzzyParam.lSigma(idx) = nan;
    fuzzyParam.rSigma(idx) = nan;
    fuzzyParam.lShoulder(idx) = nan;
    fuzzyParam.rShoulder(idx) = nan;
    fuzzyParam.mergedTo(idx) = nan;
    fuzzyParam.isNew(idx) = false;
    fuzzyParam.isGarbage(idx) = false;
end
end
