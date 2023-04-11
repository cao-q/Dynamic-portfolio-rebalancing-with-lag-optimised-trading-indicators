function [bolBands, fBolBands] = getfBollinger(data, forecast, windowSize)
%% Calculate Bollinger Bands
[middle, upper, lower] = bollinger(data, 'WindowSize', windowSize);
bolBands = [middle, upper, lower];

%% Calculate fBollinger Bands
middle = movsum(data,[windowSize-2,0],'Endpoints', 'fill');
middle = (middle + forecast) / windowSize;
window = nan(size(data,1)-windowSize+2, windowSize);
for i = 1:windowSize-1
    window(:,i) = data(i:end-windowSize+i+1);
end
window(:,windowSize) = forecast(windowSize-1:end);
window = [nan(windowSize-2,windowSize);window];
SSE = sum((window - middle) .^ 2, 2);
mstd = sqrt(SSE / (windowSize-1));
upper = middle + 2 * mstd;
lower = middle - 2 * mstd;
fBolBands = [middle, upper, lower];
end