%% Fitness function for MACDH (5 variables)
function fitness = getFitnessMACDH(x, data, forecast, crossovers)
    [~, fMACDH, ~] = getfMACDH(data, forecast, x(1), x(2), x(3), 1);
    % macdhSignal = getBuySell(macdh, x(4), x(5));
    fMACDHSignal = getBuySell(fMACDH, x(4), x(5));
    % [rsi, fRSI] = getfRSI(data, forecast, x(6), 1);
    % signal = getBuySell([fMACDH, fRSI], [x(4),x(7)], [x(5),x(8)]);
    
    
    [lagBuy, lagSell, miss, total] = getLag(crossovers, fMACDHSignal);
    % fitness = -gaussianFunc(total - size(crossovers,1), size(crossovers,1)/2) / (1 + lagSell);
    % fitness = fitness + miss;
    fitness = -gaussianFunc(total - size(crossovers,1), size(crossovers,1)/2) / (1 + (lagSell + lagBuy) * miss);
end

function gaussian = gaussianFunc(x, c)
    gaussian = exp(- (x.^2) / (2 * (c.^2)));
end