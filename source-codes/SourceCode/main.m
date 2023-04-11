addpath('DJIA_Prediction', 'SeroFAM', 'Indicators', 'Portfolio');

data = {'^DJI', '^FTSE', '^GSPC', '^HSI', '^IXIC', '^N225', '^STI'};
% data = {'AGG', 'GLD', 'SPY', 'VAW', 'VCR', 'VDC', 'VDE', 'VFH', 'VGT', 'VHT', 'VIS', 'VNQ', 'VOX', 'VPU'};
output = cell(length(data), 1);
outputRSI = cell(length(data), 1);

for i = 1:length(data)
    output{i} = optimMACDH(data{i});
    % output{i} = BAH(data{i});
    % output{i} = cv5(data{i});
    % output{i} = futures(data{i});
%     output{i} = getOptim(data{i});
%     outputRSI{i} = optimMACDHRSI(data{i});
end


function output = BAH(filename)
    testPercent = 0.2;
    data = fetchData(filename);

    [~, ~, ~, ~, ...
    inputTest,  ~,  ~,  ~] = ...
        serofamPredict(data, testPercent, false, 1, 1);

    output = investBuyAndHold(inputTest, 300000);
end