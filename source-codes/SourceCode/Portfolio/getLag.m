%% Get lag of indicators to real data
function [avgLagBuy, avgLagSell, miss, total]  = getLag(crossovers, signal)
    i = 2; % First datapoint is always either min or max, but not a crossover
    j = 1;
    buy = [];
    sell = [];
    % Merge actual and signal, split by buy and sell
    % Then go over merged list, and find the delay
    while i <= size(crossovers,1) && j <= size(signal,1)
        if abs(crossovers(i)) <= abs(signal(j))
            if crossovers(i) > 0
                buy = [buy; crossovers(i), 0]; % 0 means actual, 1 means signal
            else
                sell = [sell; -crossovers(i), 0];
            end
            i = i + 1;
        else
            if signal(j) > 0
                buy = [buy; signal(j), 1];
            else
                sell = [sell; -signal(j), 1];
            end
            j = j+1;
        end
    end
    for i = i:size(crossovers,1)
        if crossovers(i) > 0
            buy = [buy; crossovers(i), 0]; % 0 means actual, 1 means signal
        else
            sell = [sell; -crossovers(i), 0];
        end
    end
    for j = j:size(signal,1)
        if signal(j) > 0
            buy = [buy; signal(j), 1];
        else
            sell = [sell; -signal(j), 1];
        end
    end
    
    hitBuy = 0;
    totalLagBuy = 0;
    for i = 2:size(buy,1)
        if buy(i-1,2) == 0
            if buy(i,2) == 1
                totalLagBuy = totalLagBuy + buy(i,1) - buy(i-1, 1);
                hitBuy = hitBuy + 1;
            end
        end
    end
    
    hitSell = 0;
    totalLagSell = 0;
    for i = 2:size(sell,1)
        if sell(i-1,2) == 0
            if sell(i,2) == 1
                totalLagSell = totalLagSell + sell(i,1) - sell(i-1, 1);
                hitSell = hitSell + 1;
            end
        end
    end
    avgLagBuy = totalLagBuy / hitBuy;
    avgLagSell = totalLagSell / hitSell;
    miss = size(sell(sell(:,2)==0), 1) - hitSell;
    total = size(signal,1);
end