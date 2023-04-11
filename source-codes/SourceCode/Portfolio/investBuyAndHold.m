%% Invest using Buy and Hold strategy
function returns = investBuyAndHold(prices, initialAmt)
    cash = initialAmt;
    stocks = 0;
    commission = 1.001;

    % Buy stocks on first day
    stocks = stocks + floor(cash / (prices(1) * commission));
    cash = mod(cash, (prices(1) * commission));

    returns = cash + stocks * (prices(end) / commission);
end