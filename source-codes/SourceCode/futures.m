function output = futures(filename)
    testPercent = 0.2;
    data = fetchData(filename);
    output = cell(2, 1);

    [~, ~, ~, ~, inputTest,  predOutTest,  ~,  ~] = serofamPredict(data, testPercent, false, 1, 1);
    [macdh, ~, ~] = getfMACDH(inputTest, predOutTest, 12, 26, 9, 1);
    macdhSignal = getBuySell(macdh, 0, 0);
    output{1,1} = investSignal(macdhSignal, inputTest, 300000);

    out = zeros(5,5);
    for inputDepth = 1:5
        for predDepth = 1:5
            [~, ~, ~, ~, inputTest,  predOutTest,  ~,  ~] = ...
                serofamPredict(data, testPercent, false, predDepth, inputDepth);
            inputTest = inputTest(:,1);
            [~, fMACDH, ~] = getfMACDH(inputTest, predOutTest, 12, 26, 9, predDepth);
            fMACDHSignal = getBuySell(fMACDH, 0.003, -0.003);
            out(inputDepth, predDepth) = investSignal(fMACDHSignal, inputTest, 300000);
        end
    end

    output{2, 1} = out;
end