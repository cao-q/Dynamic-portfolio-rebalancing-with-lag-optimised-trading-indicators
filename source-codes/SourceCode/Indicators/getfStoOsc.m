function [stoOsc, fStoOsc] = getfStoOsc(data, forecast, kWindow, dWindow)
stoOsc = stochosc(data, 'NumPeriodsK', kWindow, 'NumPeriodsD', dWindow);

%% Moving min and max of input data
kMin = movmin(data, [kWindow-2,0], 2);
dMin = movmin(data, [dWindow-2,0], 2);
kMax = movmax(data, [kWindow-2,0], 2);
dMax = movmax(data, [dWindow-2,0], 2);

%% Find min and max including forecasted data
kMin = min([kMin, forecast], 2);
dMin = min([dMin, forecast], 2);
kMax = max([kMax, forecast], 2);
dMax = max([dMax, forecast], 2);

%% Calculate stochastic oscillator
percentK = ((forecast - kMin) / (kMax - kMin)) * 100;
percentD = ((forecast - dMin) / (dMax - dMin)) * 100;
fStoOsc = [percentK, percentD];
end
