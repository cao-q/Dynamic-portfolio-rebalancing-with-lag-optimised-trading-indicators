function [rsi, fRSI] = getfRSI(data, forecast, windowSize, predDepth)
%% Calculate RSI
rsi = rsindex(data, 'WindowSize', windowSize);

%% Calculate gains and losses
priceChange = diff(data);
gains = priceChange;
losses = priceChange;
gains(gains < 0) = 0;
losses(losses > 0) = 0;
losses = -losses;

%% Calculate predicted gains and losses
predPriceChange = forecast(:,1:predDepth) - [data,forecast(:,1:predDepth-1)];
predGains = predPriceChange;
predLosses = predPriceChange;
predGains(predGains < 0) = 0;
predLosses(predLosses > 0) = 0;
predLosses = -predLosses;
predGains = sum(predGains, 2);
predLosses = sum(predLosses, 2);

%% Sum up gains and losses for period - predicted depth, add predicted gains and losses
totalGains = movsum(gains, windowSize-predDepth, 'Endpoints', 'discard');
totalGains = totalGains + predGains(windowSize-predDepth+1:end);
totalLosses = movsum(losses, windowSize-predDepth, 'Endpoints', 'discard');
totalLosses = totalLosses + predLosses(windowSize-predDepth+1:end);

%% Calculate fRSI
fRSI = 100 - (100 ./ (1 + (totalGains ./ totalLosses)));

%% Format for output
fRSI = [nan(windowSize-1,1);fRSI];
end