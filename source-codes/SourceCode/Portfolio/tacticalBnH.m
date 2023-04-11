function out = tacticalBnH(data, opt, initialInvest, cash, axe, leg)
    commission = 1.001;
    lightC = {'#E8F8F5' '#EAF2F8' '#F4ECF7' '#FDEDEC'};
    darkC = {'#76D7C4' '#7FB3D5' '#BB8FCE' '#F1948A'};

    signal = cell(length(data), 1);
    stock = zeros(length(data), 1);
    for i = 1:length(data)
        [~, fMACDH, ~] = getfMACDH(data{i,1}, data{i,2}, opt{i}(1), opt{i}(2), opt{i}(3), 1);
        signal{i} = getBuySell(fMACDH, opt{i}(4), opt{i}(5));

        cash = cash + mod(initialInvest(i), (data{i, 1}(1) * commission));
        stock(i) = floor(initialInvest(i) / (data{i,1}(1) * commission));
    end

    figure();
    subplot(2, 1 ,1); hold on;
    set(gca,'DefaultTextFontSize',12);
    axis(axe);
    p = zeros(length(data), 1);
    for i = 1:length(data)
        plot(data{i,1}, 'Color', lightC{i},'MarkerSize',10);
        p(i) = plot(0, data{i,1}(1), '.', 'Color', darkC{i},'MarkerSize',10);
    end
    
    value = nan(length(data{1,1}) + 1, 1);
    for i = 1:length(data{1,1})
        %% Plot
        value(i) = cash;
        for j = 1:length(data)
            value(i) = value(i) + stock(j) * data{j,1}(i);
            if stock(j) > 0
                plot(i, data{j,1}(i), '.', 'Color', darkC{j},'MarkerSize',10);
            else
                plot(i, data{j,1}(i), '.', 'Color', lightC{j},'MarkerSize',10);
            end
        end
        pause(.01);

        for j = length(data):-1:2
            if ~isempty(signal{j}) && i == -signal{j}(1)
                cash = cash + stock(j) * data{j,1}(i);
                stock(j) = 0;
                stock(j-1) = stock(j-1) + floor(cash / (data{j-1,1}(i) * commission));
                cash = mod(cash, (data{j-1,1}(i) * commission));
                signal{j} = signal{j}(2:end);
            end
        end

        for j = 2:length(data)
            if ~isempty(signal{j}) && i == signal{j}(1)
                cash = cash + stock(j-1) * data{j-1,1}(i);
                stock(j-1) = 0;
                stock(j) = stock(j) + floor(cash / (data{j,1}(i) * commission));
                cash = mod(cash, (data{j,1}(i) * commission));
                signal{j} = signal{j}(2:end);
            end
        end
    end
    
    value(end) = cash;
    for i = 1:length(data)
        value(end) = value(end) + stock(i) * data{i, 1}(end);
    end
    out = value;
    
    legend(p, leg);
    subplot(2, 1 ,2); hold on;
    plot(value);
    legend('Portfolio Value');
end