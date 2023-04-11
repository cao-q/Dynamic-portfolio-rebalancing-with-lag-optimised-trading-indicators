function [macdh, fMACDH, hMACDH] = getfMACDH(data, forecast, periodShort, periodLong, periodSignal, predDepth)
%% Calculate MACDH
ema = nan(size(data, 1), 2); % EMAshort, EMAlong
ema(:,1) = movavg(data, 'exponential', periodShort);
ema(:,2) = movavg(data, 'exponential', periodLong);
macd = ema(:,1) - ema(:,2);
macdSignal = movavg(macd, 'exponential', periodSignal);
macdh = macd - macdSignal;

%% Calculate hindsight MACDH
hindsightMACD = movmean(data, [6,6], 'Endpoints', 'fill') - movmean(data, [13,13], 'Endpoints', 'fill');
hindsightMACDSignal = movmean(hindsightMACD, [4,4], 'Endpoints', 'fill');
hMACDH = hindsightMACD - hindsightMACDSignal;

%% Calculate fMACDH
weight = [2/(periodShort+1), 2/(periodLong+1)];
weightSignal = 2/(periodSignal+1);
fEMA = ema;
fMACDSignal = macd;
for i = 1:predDepth
    fEMA =  fEMA .* (1 - weight) + (forecast(:,i) * weight);
    fMACD = fEMA(:,1) - fEMA(:,2);
    fMACDSignal = fMACDSignal * (1 - weightSignal) + fMACD * weightSignal;
end
fMACDH = fMACD - fMACDSignal;

%% Express as percentage
macdh = macdh ./ (0.5 * (ema(:,1) + ema(:,2)));
fMACDH = fMACDH ./ (0.5 * (fEMA(:,1) + fEMA(:,2)));

%% Format for output
macdh = [nan(periodLong+periodSignal-1,1);macdh(periodLong+periodSignal:end)];
fMACDH = [nan(periodLong+periodSignal-1,1);fMACDH(periodLong+periodSignal:end)];
end