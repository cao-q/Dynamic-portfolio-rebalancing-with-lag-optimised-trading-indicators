% AGG - iShares Core US Aggregate Bond ETF
% SPY - SPDR S&P 500 ETF Trust
% VGK - Vanguard European Stock Index Fund ETF
% VWO - Vanguard Emerging Markets Stock Index Fund ETF

addpath('DJIA_Prediction', 'SeroFAM', 'Indicators', 'Portfolio');
filename = {'_AGG', '_SPY', '_VGK', '_VWO'};
legendname = {'AGG', 'SPY', 'VGK', 'VWO'};

testPercent = 0.2;

opt = {
%     [7,	46,	16, 0.00210215,	-0.003002981];
    [2, 4, 2, 0.001068735, -0.000722583];
    [13, 46, 30, 0.001110505, -0.002115682];
    [5	45	36	0.005499194	-0.003570893];
    [2	3	43	2.06E-03	-0.002580471];
};
% opt = cell(length(filename),2);
data = cell(length(filename),2);
output = zeros(length(filename)+1, 1);
for i = 1:length(filename)
    d = fetchData(filename{i});
    [~, ~, ~, ~, inputTest,  predOutTest,  ~,  ~] = serofamPredict(d, testPercent, false, 1, 1);
%     [inputTest, predOutTest, opt{i}] = getRangeOpt(filename{i}, 2770, 3270); %2709, 3213
    data{i,1} = inputTest;
    data{i,2} = predOutTest;

    bnh = investBuyAndHold(inputTest, 1e6);
    sprintf("%s buy and hold result: %.3f", filename{i}, bnh)
    output(i) = bnh;
end

x = ceil(length(data{1, 1}) / 100) * 100;
out = tacticalBnH(data, opt, [250000 250000 250000 250000], 0, [0 x 0 400], legendname);
sprintf("Tactical buy and hold result: %.3f", out(end))
output(end) = out(end);

out1n = strategy1n(data, [250000 250000 250000 250000], 0, 22);
sprintf("1/n strategy result, 22 days: %.3f", out1n(end))

out1n = strategy1n(data, [250000 250000 250000 250000], 0, 66);
sprintf("1/n strategy result, 66 days: %.3f", out1n(end))