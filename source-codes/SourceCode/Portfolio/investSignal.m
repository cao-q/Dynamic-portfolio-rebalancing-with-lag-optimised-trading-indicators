%% Invest into stock based on signal given
function returns = investSignal(signal, prices, initialAmt)
    cash = initialAmt;
    stocks = 0;
    commission = 1.001;
    for i = 1:size(signal)
        pos = signal(i);
        if pos > 0
            stocks = stocks + floor(cash / (prices(pos) * commission));
            cash = mod(cash, (prices(pos) * commission));
        elseif pos < 0
            cash = cash + stocks * (prices(-pos) / commission);
            stocks = 0;
        end
    end
    returns = cash + stocks * (prices(end) / commission);
end