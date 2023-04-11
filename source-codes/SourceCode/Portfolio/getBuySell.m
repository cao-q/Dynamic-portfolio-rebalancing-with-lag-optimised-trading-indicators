%% Convert indicator into buy/sell signals
function signal = getBuySell(data, buyPoint, sellPoint)
    signal = [];
    for i = 1:size(data, 1)
        if data(i, :) > buyPoint
            if size(signal,1) == 0 || signal(end) < 0
                signal = [signal; i];
            end
        elseif data(i, :) < sellPoint
            if size(signal,1) == 0 || signal(end) > 0
                signal = [signal; -i];
            end
        end
    end
end