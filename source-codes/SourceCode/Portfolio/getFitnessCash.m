%% Fitness function for final cash
function fitness = getFitnessCash(x, data, forecast)
    [~, fMACDH, ~] = getfMACDH(data, forecast, x(1), x(2), x(3), 1);
    fMACDHSignal = getBuySell(fMACDH, x(4), x(5));
    investfMACDH = investSignal(fMACDHSignal, data, 300000);
    fitness = -investfMACDH;
end