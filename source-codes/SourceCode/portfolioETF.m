addpath('DJIA_Prediction', 'SeroFAM', 'Indicators', 'Portfolio');
filename = {'AGG', 'GLD', 'VAW', 'VCR', 'VDC', 'VDE', 'VFH', 'VGT', 'VHT', 'VIS', 'VNQ', 'VOX', 'VPU'};
lightC = {'#F9EBEA', '#FDEDEC', '#F5EEF8', '#F4ECF7', '#EAF2F8', '#EBF5FB', '#E8F8F5', '#E8F6F3', '#E9F7EF', '#EAFAF1', '#FEF9E7', '#FEF5E7', '#FDF2E9', '#FBEEE6'};
darkC = {'#D98880', '#F1948A', '#C39BD3', '#BB8FCE', '#7FB3D5', '#85C1E9', '#76D7C4', '#73C6B6', '#7DCEA0', '#82E0AA', '#F7DC6F', '#F8C471', '#F0B27A', '#E59866'};

testPercent = 0.2;

opt = {
    [1	35	47	0.002877357	-0.001810002];
    [1	10	9	0.008566634	-0.007571127];
    [19	40	35	0.000732225	-0.000931759];
    [16	48	34	0.001024174	-0.001867539];
    [1	38	49	0.007226696	-0.00735962];
    [16	45	20	0.000797459	-0.000671206];
    [10	33	38	0.001534005	-0.001928799];
    [13	39	40	0.00258925	-0.003643088];
    [20	44	46	0.000712891	-0.00118471];
    [8	24	41	0.00282611	-0.002165171];
    [7	38	17	0.002724131	-0.000237593];
    [13	47	48	0.001974847	-0.001535438];
    [3	14	46	0.001601159	-0.00378873];
};
data = cell(13,2);
output = cell(2,1);
out = zeros(13,1);
for i = 1:13
    d = fetchData(filename{i});
    [~, ~, ~, ~, inputTest,  predOutTest,  ~,  ~] = serofamPredict(d, testPercent, false, 1, 1);
    
%     [inputTest, predOutTest, opt{i}] = getRangeOpt(filename{i}, 2770, 3270);
    
    data{i,1} = inputTest;
    [~, fMACDH, ~] = getfMACDH(inputTest, predOutTest, opt{i}(1), opt{i}(2), opt{i}(3), 1);
    % Buy, sell and hold signals per day
    fMACDH(fMACDH <= opt{i}(4) & fMACDH >= opt{i}(5)) = 0;
    fMACDH(fMACDH > 0) = 1;
    fMACDH(fMACDH < 0) = -1;
    data{i, 2} = fMACDH;

    bnh = investBuyAndHold(inputTest, 1e6);
    out(i) = bnh;
end
output{1} = out;

% Plot graph
figure();
subplot(2, 1 ,1); hold on;
set(gca,'DefaultTextFontSize',12);
x = ceil(length(data{1, 1}) / 100) * 100;
axis([0 x 0 600]);
p = zeros(length(data), 1);
for i = 1:length(data)
    plot(data{i,1}, 'Color', lightC{i},'MarkerSize',10);
    p(i) = plot(0, data{i,1}(1), '.', 'Color', darkC{i},'MarkerSize',10);
end
value = nan(length(data{1,1}) + 1);

% out1n = strategy1n(data, [76923 76923 76923 76923 76923 76923 76923 76923 76923 76923 76923 76923 76923], 1);
% sprintf("1/n strategy result: %.3f", out1n(end))

commission = 1.001;
% ini = floor(1e6 / length(filename));
% cash = mod(1e6, length(filename));
ini = 0;
cash = 1e6;
stock = zeros(length(filename), 1);
for i = 1:length(filename)
    stock(i) = floor(ini/ (data{i, 1}(1) * commission));
    cash = cash + mod(ini, (data{i, 1}(1) * commission));
end

for i = 1:length(data{1,1})
    % Animated graph
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

    % Sell off sell stocks, check hold stocks
    newBuy = 0;
    for j = 1:length(filename)
        holdValue = 0;
        holdNum = 0;
        if data{j,2}(i) == -1
            cash = cash + stock(j) * data{j,1}(i);
            stock(j) = 0;
        elseif data{j,2}(i) == 0
            holdValue = holdValue + stock(j) * data{j,1}(i);
            holdNum = holdNum + 1;
        elseif stock(j) == 0 && data{j,2}(i) == 1
            newBuy = newBuy + 1;
        end
    end
    % Buy into any new buy stocks, spread money amongst otherwise
    holdValue = holdValue + cash;
    for j = 1:length(filename)
        if stock(j) == 0 && data{j,2}(i) == 1
            buyAmt = floor(holdValue / (holdNum + newBuy));
            while cash < buyAmt
                for k = 1:length(filename)
                    if data{k,2}(i) == 0 && stock(k) > 0
                        cash = cash + data{k,1}(i);
                        stock(k) = stock(k) - 1;
                    end
                end
            end
            stock(j) = floor(buyAmt / (data{j, 1}(i) * commission));
            cash = cash - buyAmt + mod(buyAmt, (data{j, 1}(i) * commission));
        end
    end
    % Spread remaining money among buy stocks
    canBuy = true;
    while canBuy
        canBuy = false;
        for j = 1:length(filename)
            if data{j,2}(i) == 1
                if cash > (data{j,1}(i) * commission)
                    cash = cash - (data{j,1}(i) * commission);
                    stock(j) = stock(j) + 1;
                    canBuy = true;
                end
            end
        end
    end
end

for i = 1:length(filename)
    cash = cash + stock(i) * data{i,1}(end);
end

value(end) = cash;
legend(p, filename);
subplot(2, 1 ,2); hold on;
plot(value);
legend('Portfolio Value');

output{2} = cash;