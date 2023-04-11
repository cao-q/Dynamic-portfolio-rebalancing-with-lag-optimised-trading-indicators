function out = strategy1n(data, initialInvest, cash, days)
    commission = 1.001;

    stock = zeros(length(data), 1);
    for i = 1:length(data)
        cash = cash + mod(initialInvest(i), (data{i, 1}(1) * commission));
        stock(i) = floor(initialInvest(i) / (data{i,1}(1) * commission));
    end
    value = nan(length(data{1,1}) + 1, 1);
    for i = 1:length(data{1,1})
        value(i) = cash;
        for j = 1:length(data)
            value(i) = value(i) + stock(j) * data{j,1}(i);
        end

        if i ~= 1 && mod(i, days) == 0
            curVal = value(i);
            avgVal = curVal / length(data);
            for j = 1:length(data)
                stockVal = stock(j) * data{j,1}(i);
                if stockVal > avgVal
                    numSell = floor((stockVal - avgVal) / data{j,1}(i));
                    cash = cash + numSell * data{j,1}(i);
                    stock(j) = stock(j) - numSell;
                elseif stockVal < avgVal
                    numBuy = floor((avgVal - stockVal) / (data{j,1}(i) * commission));
                    cash = cash - numBuy * data{j,1}(i);
                    stock(j) = stock(j) + numBuy;
                end
            end
        end
    end
    
    value(end) = cash;
    for i = 1:length(data)
        value(end) = value(end) + stock(i) * data{i, 1}(end);
    end
    out = value;
end

