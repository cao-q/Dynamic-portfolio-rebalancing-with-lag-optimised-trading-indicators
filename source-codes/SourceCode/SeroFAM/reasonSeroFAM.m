function [approximation, risk] = reasonSeroFAM(input, network)
oInput = reasonInput(input);
oInputFuzzy = reasonInputFuzzy(oInput, network.linkIdxIn2F, network.inputFuzzyParam);
oRule = reasonRule(oInputFuzzy, network.linkF2R);
oOutputFuzzy = reasonOutputFuzzy(oRule, network.linkR2F, network.linkWeightR2F, network.outputFuzzyParam);
[approximation, risk] = reasonOutput(oOutputFuzzy, network.linkIdxF2Out, network.outputFuzzyParam, network.numOutput);
end

function out = reasonInput(in)
out = in;
end

function out = reasonInputFuzzy(in, linkIdxIn2F, inputFuzzyParam)
out = zeros(length(linkIdxIn2F), 1);
validLink = (linkIdxIn2F > 0);
out(validLink) = asymmetricGaussian( ...
    in(linkIdxIn2F(validLink)), ...
    inputFuzzyParam.centroid(validLink), ...
    inputFuzzyParam.lSigma(validLink), ...
    inputFuzzyParam.rSigma(validLink), ...
    inputFuzzyParam.lShoulder(validLink), ...
    inputFuzzyParam.rShoulder(validLink));
end

function out = reasonRule(in, linkF2R)
out = zeros(size(linkF2R, 2), 1);
idxValid = find(any(linkF2R));
for i = 1 : length(idxValid)
    idx = idxValid(i);
    out(idx) = min(in(linkF2R(:, idx)));
end
end

function out = reasonOutputFuzzy(in, linkR2F, linkWeight, outputFuzzyParam)
out = zeros(size(linkR2F, 2), 2);
idxValid = find(any(linkR2F));
for i = 1 : length(idxValid)
    idx = idxValid(i);
    out(idx, 2) = max(in(linkR2F(:, idx)) .* linkWeight(linkR2F(:, idx), idx));
    out(idx, 1) = outputFuzzyParam.centroid(idx) .* out(idx, 2);
end
end

function [out, risk] = reasonOutput(in, linkIdxF2Out, outputFuzzyParam, numOutput)
out = nan(numOutput, 1);
risk = nan(numOutput, 3);
for i = 1 : numOutput
    idxFuzzyParam = (linkIdxF2Out == i);
    if any(idxFuzzyParam)
        input = in(idxFuzzyParam, :);
        sumIn = sum(input, 1);
        out(i) = sumIn(1) / sumIn(2);
    
    % Compute risk
        centroid = outputFuzzyParam.centroid(idxFuzzyParam);
        d = centroid - out(i);
        leftIdx = (centroid < out(i));
        leftRisk = sum(d(leftIdx).^2 .* input(leftIdx, 2));
        leftRiskDivisor = sum(input(leftIdx, 2));
        rightIdx = ~leftIdx;
        rightRisk = sum(d(rightIdx).^2 .* input(rightIdx, 2));
        rightRiskDivisor = sum(input(rightIdx, 2));
        totalRiskDivisor = leftRiskDivisor + rightRiskDivisor;
        if totalRiskDivisor > 0
            totalRisk = ((leftRisk + rightRisk) / totalRiskDivisor)^0.5;
        else
            totalRisk = 0;
        end
        if leftRiskDivisor > 0
            leftRisk = (leftRisk / leftRiskDivisor)^0.5;
        else
            totalRisk = 0;
        end
        if rightRiskDivisor > 0
            rightRisk = (rightRisk / rightRiskDivisor)^0.5;
        else
            totalRisk = 0;
        end
        risk(i, :) = [totalRisk leftRisk, rightRisk];
    end
end
end

