function [predOutput, predErr] = evaluateFis(fis, input, output)
% Calculate the test error.
evalOptions = evalfisOptions("EmptyOutputFuzzySetMessage","none", ...
    "NoRuleFiredMessage","none","OutOfRangeInputValueMessage","none");
predOutput = evalfis(fis,input,evalOptions);
err = predOutput - output;
predErr(1) = sum((predOutput >= 0) ~= (output >= 0)); % Sum of Sign Diff
predErr(2) = mean(abs(err)); % MAE
predErr(3) = mean((err).^2).^0.5; %RMSE
predErr(4) = 1-(1 - sum(err.^2)/sum((output-mean(output)).^2)); % 1-R2
end