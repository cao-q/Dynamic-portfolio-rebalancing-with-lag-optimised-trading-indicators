addpath('DJIA_Prediction', 'SeroFAM', 'Indicators', 'Portfolio');
% filename = {'_GLD', 'AGG', '_SPY', '_VGK', '_VWO'};
filename = {'^GSPC'};

testPercent = 0.2;

opt = {
    [7,	46,	16, 0.00210215,	-0.003002981];
    [2, 4, 2, 0.001068735, -0.000722583];
    [13, 46, 30, 0.001110505, -0.002115682];
    [5	45	36	0.005499194	-0.003570893];
    [2	3	43	2.06E-03	-0.002580471];
};

for i = 1:length(filename)
    d = fetchData(filename{i});
    [~, ~, ~, ~, inputTest,  predOutTest,  ~,  ~] = serofamPredict(d, testPercent, false, 1, 1);
%     [~, fMACDH, ~] = getfMACDH(inputTest, predOutTest, opt{i}(1), opt{i}(2), opt{i}(3), 1);
%     
%     figure; hold on;
%     plot(normalize(diff(inputTest)));
%     plot(normalize(fMACDH(2:end)));
%     legend({filename{i}, 'fMACDH'});
%     grid on;
%     title('Actual prices and fMACDH normalized');
end

figure;hold on;
% subplot(2,1,1);hold on;
set(gca,'DefaultTextFontSize',12);
set(gca,'FontSize',12);
plot(inputTest,'LineWidth',3);
ylabel('Closing Prices', 'FontSize', 12); xlabel('Datapoints', 'FontSize', 12);
% legend({'Actual'});
grid on;
title('GSPC Market Index Prices', 'FontSize', 12);

f = gcf;
exportgraphics(f,'GSPC Market Index Prices.png','Resolution',1600)

rma = movmean(movmean(inputTest,25),9);
figure;hold on;
% subplot(2,1,2);hold on;
set(gca,'DefaultTextFontSize',12);
plot(rma,'LineWidth',3);
ylabel('Closing Prices', 'FontSize', 12); xlabel('Datapoints', 'FontSize', 12);
% legend({'Actual'});
grid on;
title('GSPC Market Index Prices (After RMA)', 'FontSize', 12);
f = gcf;
exportgraphics(f,'GSPC Market Index Prices (After RMA).png','Resolution',1600)


% figure;
% subplot(2,2,1);hold on;
% plot(inputTest);
% ylabel('Closing'); xlabel('Datapoint#');
% legend({'Actual'});
% grid on;
% title('Actual prices');
% 
% subplot(2,2,2);hold on;
% plot(movmean(inputTest, [12,12], 'Endpoints', 'fill'));
% ylabel('Closing'); xlabel('Datapoint#');
% grid on;
% title('Moving Average across 26 days');
% for i = 1:size(peakTrough)
%     if peakTrough(i) == 1 && peakTrough(i-1) == -1
%         xline(i);
%     elseif peakTrough(i) == -1 && peakTrough(i-1) == 1
%         xline(i);
%     end
% end
% 
% subplot(2,2,3);hold on;
% plot(macdhSignal);
% plot(fMACDHSignal);
% ylabel('Signal'); xlabel('Datapoint#');
% legend({'MACDH', 'fMACDH'});
% grid on;
% title('MACDH vs fMACDH Buy/Sell signals');
% 
% subplot(2,2,4);hold on;
% plot(rsiSignal);
% plot(fRSISignal);
% ylabel('Signal'); xlabel('Datapoint#');
% legend({'RSI', 'fRSI'});
% grid on;
% title('RSI vs fRSI Buy/Sell signals');