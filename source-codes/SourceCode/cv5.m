function output = cv5(filename)
testPercent = 0.8;

data = fetchData(filename);

[inputTrain, predOutTrain, outputTrain, trainErr, ...
 inputTest,  predOutTest,  outputTest,  testErr] = ...
    serofamPredict(data, testPercent, false, 1, 1);

dataIn = cell(5, 1);
dataOut = cell(5, 1);
dataIn{1} = inputTrain;
dataOut{1} = predOutTrain;
foldSize = floor(size(predOutTest,1) / 4);
dataIn{2} = inputTest(1:foldSize);
dataIn{3} = inputTest(foldSize+1:2*foldSize);
dataIn{4} = inputTest(2*foldSize+1:3*foldSize);
dataIn{5} = inputTest(3*foldSize+1:end);
dataOut{2} = predOutTest(1:foldSize);
dataOut{3} = predOutTest(foldSize+1:2*foldSize);
dataOut{4} = predOutTest(2*foldSize+1:3*foldSize);
dataOut{5} = predOutTest(3*foldSize+1:end);

output = cell(2,1);

peakTrough = getPeakTrough(inputTest);
r = [];
for i = 1:5
    res = zeros(1,5);

    % GA using cash
    funcFitness = @(x) getFitnessCash(x, dataIn{i}, dataOut{i});
    lb = [1, 1, 1, 0, -0.01];
    ub = [50, 50, 50, 0.01, 0];
    A = [1, -1, 0, 0, 0];
    B = [0];
    gaOpt = optimoptions('ga');
    gaOpt.UseParallel = true;
    gaOpt.Display = 'iter';
    gaOpt.FunctionTolerance = 1e-10;
    gaOpt.MaxStallGenerations = 20;

    out = nan(50,6);
    for j = 1:50
        x = ga(funcFitness, 5, A, B, [], [], lb, ub, [], [1,2,3], gaOpt);
        [~, fMACDH, ~] = getfMACDH(dataIn{i}, dataOut{i}, x(1), x(2), x(3), 1);
        fMACDHSignal = getBuySell(fMACDH, x(4), x(5));

        investfMACDH = investSignal(fMACDHSignal, dataIn{i}, 300000);
        out(j, :) = [investfMACDH, x(1), x(2), x(3), x(4), x(5)];
    end
    outSorted = sortrows(out, 'descend');
    x = outSorted(1, 2:6);
    res(i) = outSorted(1,1);

    for j = i+1:5
        [~, fMACDH, ~] = getfMACDH(dataIn{j}, dataOut{j}, x(1), x(2), x(3), 1);
        fMACDHSignal = getBuySell(fMACDH, x(4), x(5));

        investfMACDH = investSignal(fMACDHSignal, dataIn{j}, 300000);
        res(j) = investfMACDH;
    end
    r = [r;x,nan(1,1),res];
end
output{1} = r;
r = [];
for i = 1:5
    res = zeros(1,5);
    % GA with lag
    funcFitness = @(x) getFitnessMACDH(x, dataIn{i}, dataOut{i}, peakTrough);
    lb = [1, 1, 1, 0, -0.01];
    ub = [50, 50, 50, 0.01, 0];
    A = [1, -1, 0, 0, 0];
    B = [0];
    gaOpt = optimoptions('ga');
    gaOpt.UseParallel = true;
    gaOpt.Display = 'iter';
    gaOpt.FunctionTolerance = 1e-10;
    gaOpt.MaxStallGenerations = 20;

    out = nan(50,6);
    for j = 1:50
        x = ga(funcFitness, 5, A, B, [], [], lb, ub, [], [1,2,3], gaOpt);
        [~, fMACDH, ~] = getfMACDH(dataIn{i}, dataOut{i}, x(1), x(2), x(3), 1);
        fMACDHSignal = getBuySell(fMACDH, x(4), x(5));

        investfMACDH = investSignal(fMACDHSignal, dataIn{i}, 300000);
        out(j, :) = [investfMACDH, x(1), x(2), x(3), x(4), x(5)];
    end
    outSorted = sortrows(out, 'descend');
    x = outSorted(1, 2:6);
    res(i) = outSorted(1,1);

    for j = i+1:5
        [~, fMACDH, ~] = getfMACDH(dataIn{j}, dataOut{j}, x(1), x(2), x(3), 1);
        fMACDHSignal = getBuySell(fMACDH, x(4), x(5));

        investfMACDH = investSignal(fMACDHSignal, dataIn{j}, 300000);
        res(j) = investfMACDH;
    end
    r = [r;x,nan(1,1),res];
end
output{2} = r;
end