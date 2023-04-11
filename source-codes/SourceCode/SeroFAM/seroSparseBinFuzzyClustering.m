function [network, fcState] = seroSparseBinFuzzyClustering( ...
    network, fcState, input, output)
cfg = cfgSeroFAM();

% Train input neuron
[network.inputFuzzyParam, network.linkIdxIn2F, ...
    fcState.inputDataSpace, fcState.inputBinCollector] = ...
    trainNeuron( ...
    network.inputFuzzyParam, network.linkIdxIn2F, ...
    fcState.inputDataSpace, fcState.inputBinCollector, input, cfg);

% Train output neuron
[network.outputFuzzyParam, network.linkIdxF2Out, ...
    fcState.outputDataSpace, fcState.outputBinCollector] = ...
    trainNeuron( ...
    network.outputFuzzyParam, network.linkIdxF2Out, ...
    fcState.outputDataSpace, fcState.outputBinCollector, output, cfg);
end

function [fuzzyParam, fuzzyCrispLinkIdx, dataSpace, binCollector] = ...
    trainNeuron(fuzzyParam, fuzzyCrispLinkIdx, dataSpace, binCollector, ...
    dataVal, cfg)
for i = 1 : numel(dataVal)
    % Update the spatio-temporal space
    dataSpace(i) = spaceTemporalUpdate( ...
        dataSpace(i), dataVal(i), cfg.forgettor);

    % Update the particular bin & its parameters.
    binCollector(i) = binTemporalUpdate( ...
        binCollector(i), dataVal(i), cfg.forgettor, cfg.binWidth);
    
    % Check expandable condition
    idxFuzzyParam = find(fuzzyCrispLinkIdx == i);
    newCentroid = isExpandable(dataVal(i), ...
        fuzzyParam.centroid(idxFuzzyParam), ...
        dataSpace(i).stSpace, cfg.maxCluster);
    if newCentroid
        % However, the membership nodes 
        % are initialized with centroid == dataVal
        % (i) Add to crispLayer.FuzzyBabyCollector
        idxNewNeuron = find(isnan(fuzzyParam.centroid), 1);
        fuzzyParam.centroid(idxNewNeuron) = dataVal(i);
        fuzzyParam.isNew(idxNewNeuron) = true;
        fuzzyCrispLinkIdx(idxNewNeuron) = i;
        idxFuzzyParam = find(fuzzyCrispLinkIdx == i);
        centroid = fuzzyParam.centroid(idxFuzzyParam);
        stability = [];
    else % Update centroids
        % you need to set the centroids and stabilities 
        % in the UpdateCentroidStabilities() function
        % otherwise, if you extract the centroids again
        % from the neuron.MergeFuzzyNeurons() function
        % below, you will not get the set of updated neurons.
        centroid = fuzzyParam.centroid(idxFuzzyParam);
        stability = fuzzyParam.stability(idxFuzzyParam);
        pid = constrainedPowerInverseDistance(dataVal(i), centroid);
        stability = stability * cfg.forgettor;
        centroid = (stability .* centroid + pid .* dataVal(i)) ./ ...
            (stability + pid);
        stability = stability + pid;
        fuzzyParam.centroid(idxFuzzyParam) = centroid;
        fuzzyParam.stability(idxFuzzyParam) = stability;
    end
    
    % Merge clusters if necessary
    [idxMerger, idxMergee] = IsReducible(centroid, ...
        dataSpace(i).stSpace, cfg.maxCluster);
    % if new mergee, then no need to add to garbage
    if idxMergee > 0 && ~fuzzyParam.isNew(idxFuzzyParam(idxMergee))
        % (i) Add mergee to crispLayer.FuzzyGarbageCollector (99%)
        % (ii) or remove from crispLayer.FuzzyBabyCollector (rare - infact shouldnt happen)
        
        % Merge centroid based on stability
        stability = fuzzyParam.stability(idxFuzzyParam);
        centroid(idxMerger) = ...
            sum(centroid([idxMerger idxMergee]) .* stability([idxMerger idxMergee])) / ...
            sum(stability([idxMerger idxMergee]));        
        fuzzyParam.centroid(idxFuzzyParam) = centroid;
        
        % Set isGarbage flag & remove links for Mergee
        fuzzyParam.isGarbage(idxFuzzyParam(idxMergee)) = true;        
        fuzzyParam.mergedTo(idxFuzzyParam(idxMergee)) = ...
            idxFuzzyParam(idxMerger);
        fuzzyCrispLinkIdx(idxFuzzyParam(idxMergee)) = ...
            -fuzzyCrispLinkIdx(idxFuzzyParam(idxMergee)); % Marked as removed
        
        idxFuzzyParam = find(fuzzyCrispLinkIdx == i);
        centroid = fuzzyParam.centroid(idxFuzzyParam);
        stability = [];
    end

    % (i)   Centroids are complete
    % (ii)  Stabilities are complete ONLY if there was NO adding or merging.
    % (iii) if isempty(stability), then need to recompute stability values.

    % Compute approximation for variances 
    [lSigma, rSigma, newStability] = computeVariances( ...
        binCollector(i), centroid, stability, cfg.gapModifier);
    fuzzyParam.lSigma(idxFuzzyParam) = lSigma;
    fuzzyParam.rSigma(idxFuzzyParam) = rSigma;
    if isempty(stability)
        fuzzyParam.stability(idxFuzzyParam) = newStability;
    end  
    % Finalize is called at the end of every cluster training epoch.
    % Set shoulders for both ends of centroids
    shoulder = fuzzyParam.lShoulder(idxFuzzyParam);
    shoulder(:) = false;
    [~, idx] = min(centroid);
    shoulder(idx) = true;
    fuzzyParam.lShoulder(idxFuzzyParam) = shoulder;
    shoulder(:) = false;
    [~, idx] = max(centroid);
    shoulder(idx) = true;
    fuzzyParam.rShoulder(idxFuzzyParam) = shoulder;
end
end

function [leftSigma, rightSigma, stability] = computeVariances( ...
    binCollector, centroid, stability, gapModifier)

[sortedCentroid, centroidIdx] = sort(centroid);

if isempty(stability)
    stability = zeros(size(sortedCentroid));
    idx = find(~isnan(binCollector.basePtr));
    currUtil = binCollector.currency(idx) .* binCollector.count(idx);
    for i = 1 : length(idx)
        pid = constrainedPowerInverseDistance(binCollector.twaMean(idx(i)), sortedCentroid);
        stability = stability + currUtil(i) .* pid;
    end
end

leftSigma = ones(size(sortedCentroid));
rightSigma = ones(size(sortedCentroid));
if length(sortedCentroid) > 1
    gapStability = (diff(sortedCentroid) * gapModifier) ./ ...
        (stability(1:end-1) + stability(2:end));
    % if j-stability < jNext-stability, then j-RIGHT > jNext-LEFT variance
    leftSigma(2:end) = stability(1:end-1) .* gapStability;
    rightSigma(1:end-1) = stability(2:end) .* gapStability;
end
% Validate variance
leftSigma(leftSigma == 0 | isnan(leftSigma) | isinf(leftSigma)) = 1;
rightSigma(rightSigma == 0 | isnan(rightSigma) | isinf(rightSigma)) = 1;

% Rearrange order
leftSigma(centroidIdx) = leftSigma;
rightSigma(centroidIdx) = rightSigma;
stability(centroidIdx) = stability;
end

function newCentroid = isExpandable(input, centroid, stSpace, maxCluster)
newCentroid = false;
clusterCount = length(centroid);
if clusterCount < maxCluster
    if clusterCount > 0
        nearestCentroidDist = min(abs(input - centroid));
        expansionResistance = stSpace /  ...
            (maxCluster - clusterCount);
        if (expansionResistance > 0) && ...
                (nearestCentroidDist > expansionResistance)
            newCentroid = true;
        end
    else
        newCentroid = true;
    end
end
end

function [mergeId, mergeeId] = IsReducible(centroid, stSpace, maxCluster)
mergeId = 0;
mergeeId = 0;
if length(centroid) > 1
    [sortedCentroid, centroidIdx] = sort(centroid);
    dist = diff(sortedCentroid);
    [neardist, idx] = min(dist);
    ReductionResistance = stSpace / maxCluster;
    if neardist < ReductionResistance
        mergeId = centroidIdx(idx);
        mergeeId = centroidIdx(idx+1);
    end
end
end

function pid = constrainedPowerInverseDistance(dataVal, centroid)
d = dataVal - centroid;
pid = 1 ./ (d.^2);
pidSum = sum(pid);
idxInf = (d == 0);
if any(idxInf)
    pid(:) = 0;
    pid(idxInf) = 1;
else
    pid = pid / pidSum;
end
end

function ds = spaceTemporalUpdate(ds, dataVal, forgettor)
% Recurse equation for the sumSqMeans
ds.sumSquareM = (ds.sumSquareM * forgettor) + dataVal^2;
% Recurse equation for the sumMean
ds.sumM = (ds.sumM * forgettor) + dataVal;
ds.sumCurrency = (ds.sumCurrency * forgettor) + 1;

%                        { SUM(x^2)  -   SUM(x)^2  }
% stSpace = 2 * expMod * { ---------   ----------- } ^ 0.5
%                        { SUM(beta)   SUM(beta)^2 }
persistent expMod
if isempty(expMod)
    expMod = 2 * (2 * pi)^0.5;
end
d = (ds.sumSquareM / ds.sumCurrency) - (ds.sumM / ds.sumCurrency)^2;
% Ensure difference is +ve, so that there is no complex stSpace value
ds.stSpace = expMod * max(d, 0)^0.5;
end

function binCollector = binTemporalUpdate(binCollector, dataVal, forgettor, binWidth)
% Forget all bins
binCollector.currency = binCollector.currency * forgettor;

% Search for bin for update
binHash = round(dataVal / binWidth);
idx = find(binHash >= binCollector.basePtr & binHash < binCollector.basePtr+binWidth, 1);
% Create new bin if do not exist
if isempty(idx)
    idx = find(isnan(binCollector.basePtr), 1);
    if isempty(idx)
        error('MAX_DATA_BIN exceeded!');
    end
    binCollector.basePtr(idx) = binHash;
end
% Update bin
ffUtil = binCollector.currency(idx) * binCollector.count(idx);
% if only one data per time-step then ff = 1.0
ff = 1;
binCollector.twaMean(idx) = (binCollector.twaMean(idx) * ffUtil + dataVal * ff) / (ffUtil + ff);
binCollector.count(idx) = binCollector.count(idx) + 1;
binCollector.currency(idx) = (ffUtil + ff) / binCollector.count(idx);
end
