function [predOutput, predErr, network, fcState, ruleParam] = ...
    runSeroFam(input, output, cfg, network, fcState, ruleParam, predDepth)
numInput = size(input, 2);
numOutput = size(output, 2);

if isempty(network)
    [network, fcState, ruleParam] = initSeroFAM(numInput, numOutput, cfg);
end

% Run training set
predOutput = nan(size(output,1), predDepth);
for i = 1 : size(input, 1)
    inputTemp = input(i, :);
    for j = 1:predDepth
        [predOutput(i,j), ~] = reasonSeroFAM(inputTemp', network);
        inputTemp = [inputTemp(2:end), predOutput(i,j)];
    end

    [network, fcState, ruleParam] = learnSeroFAM( ...
        network, fcState, ruleParam, i, input(i, :)', output(i), cfg);
end
idx = ~isnan(predOutput(:,1));
% predOutput(isnan(predOutput)) = 0;
err = predOutput(idx) - output(idx);
predErr(1) = sum((predOutput(idx) >= 0) ~= (output(idx) >= 0)); % Sum of Sign Diff
predErr(2) = mean(abs(err)); % MAE
predErr(3) = (mean((err).^2).^0.5); %RMSE
predErr(4) = 1-(1 - sum(err.^2)/sum((output-mean(output)).^2)); % 1-R2
end