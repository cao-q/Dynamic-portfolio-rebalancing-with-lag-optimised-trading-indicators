function out = getOptim(filename)
    testPercent = 0.2;

    data = fetchData(filename);
    [~, ~, ~, ~, inputTest,  predOutTest,  ~,  ~] = serofamPredict(data, testPercent, false, 1, 1);

    out = nan(100,12);

    peakTrough = getPeakTrough(inputTest);
    funcFitness = @(x) getFitnessMACDH(x, inputTest, predOutTest, peakTrough);
    lb = [1, 1, 1, 0, -0.01];
    ub = [50, 50, 50, 0.01, 0];
    A = [1, -1, 0, 0, 0];
    B = [0];
    gaOpt = optimoptions('ga');
    gaOpt.UseParallel = true;
    gaOpt.Display = 'iter';
    gaOpt.FunctionTolerance = 1e-10;
    gaOpt.MaxStallGenerations = 20;

    for i = 1:100
        x = ga(funcFitness, 5, A, B, [], [], lb, ub, [], [1,2,3], gaOpt);
        [macdh, fMACDH, ~] = getfMACDH(inputTest, predOutTest, x(1), x(2), x(3), 1);
        macdhSignal = getBuySell(macdh, x(4), x(5));
        fMACDHSignal = getBuySell(fMACDH, x(4), x(5));
        [lagBuy, lagSell, miss, total] = getLag(peakTrough, fMACDHSignal);

        investMACDH = investSignal(macdhSignal, inputTest, 300000);
        investfMACDH = investSignal(fMACDHSignal, inputTest, 300000);
        out(i, :) = [x, nan(1,1), investMACDH, investfMACDH, lagBuy, lagSell, miss, total];
    end
end