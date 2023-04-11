function output = optimMACDHRSI(filename)

testPercent = 0.2;
data = fetchData(filename);

[~, ~, ~, ~, inputTest,  predOutTest,  ~,  ~] = serofamPredict(data, testPercent, false, 1, 1);

peakTrough = getPeakTrough(inputTest);
funcFitness = @(x) getFitnessMACDH(x, inputTest, predOutTest, peakTrough);
lb = [1, 1, 1, 0, -0.01, 1, 0, 0];
ub = [50, 50, 50, 0.01, 50, 100, 100];
A = [1, -1, 0, 0, 0, 0, 0, 0;
    0, 0, 0 ,0, 0, 0, 1, -1];
B = [0; 0];
gaOpt = optimoptions('ga');
gaOpt.UseParallel = true;
gaOpt.Display = 'iter';
gaOpt.FunctionTolerance = 1e-10;
gaOpt.MaxStallGenerations = 20;
% x = ga(funcFitness, 8, A, B, [], [], lb, ub, [], [1,2,3,6,7,8], gaOpt);

out = nan(102,6);

[macdh, fMACDH, hMACDH] = getfMACDH(inputTest, predOutTest, 12, 26, 9, 1);

hMACDHSignal = getBuySell(hMACDH, 0, 0);
[lagBuy, lagSell, miss, total] = getLag(peakTrough, hMACDHSignal);
investhMACDH = investSignal(hMACDHSignal, inputTest, 300000);
out(1,:) = [investhMACDH, lagBuy, lagSell, miss, total, nan(1,1)];

macdhSignal = getBuySell(macdh, 0.002, -0.002);
fMACDHSignal = getBuySell(fMACDH, 0.002, -0.002);
[lagBuy, lagSell, miss, total] = getLag(peakTrough, fMACDHSignal);

investMACDH = investSignal(macdhSignal, inputTest, 300000);
investfMACDH = investSignal(fMACDHSignal, inputTest, 300000);
out(2,:) = [investMACDH, investfMACDH, lagBuy, lagSell, miss, total];

for i = 3:102
    x = ga(funcFitness, 8, A, B, [], [], lb, ub, [], [1,2,3,6,7,8], gaOpt);
    [macdh, fMACDH, ~] = getfMACDH(inputTest, predOutTest, x(1), x(2), x(3), 1);
    macdhSignal = getBuySell(macdh, x(4), x(5));
    fMACDHSignal = getBuySell(fMACDH, x(4), x(5));
    [lagBuy, lagSell, miss, total] = getLag(peakTrough, fMACDHSignal);

    investMACDH = investSignal(macdhSignal, inputTest, 300000);
    investfMACDH = investSignal(fMACDHSignal, inputTest, 300000);
%     out(i, :) = [investMACDH, investfMACDH, x];
    out(i, :) = [investMACDH, investfMACDH, lagBuy, lagSell, miss, total];
end

bestCase = investSignal(peakTrough, inputTest, 300000);
sprintf('Best case: %.3f', bestCase)

output = out;
end