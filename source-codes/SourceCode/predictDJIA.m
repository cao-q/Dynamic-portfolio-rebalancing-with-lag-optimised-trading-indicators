testPercent = 0.2;

addpath('DJIA_Prediction', 'SeroFAM');
data = fetchData('^STI');

%% SeroFAM prediction
[~, predOutTrain, outputTrain, trainErr, ...
 ~, predOutTest,  outputTest,  testErr] = ...
    serofamPredict(data, testPercent, false, 1,1);
figure;
subplot(2, 2, 1); hold on;
plot(outputTrain);
plot(predOutTrain);
ylabel('Closing'); xlabel('Datapoint#');
legend({'Actual', 'Prediction'});
grid on;
title('DJIA Prediction (SeroFAM-Training)');
subplot(2, 2, 3); hold on;
plot(outputTrain - predOutTrain);
ylabel('Error'); xlabel('Datapoint#');
grid on;
title(sprintf('Prediction Error (SeroFAM-Training) (RMSE: %.3f, R^2: %.3f)', trainErr(3), 1-trainErr(4)));
subplot(2, 2, 2); hold on;
plot(outputTest);
plot(predOutTest);
ylabel('Closing'); xlabel('Datapoint#');
legend({'Actual', 'Prediction'});
grid on;
title('DJIA Prediction (SeroFAM-Test)');
subplot(2, 2, 4); hold on;
plot(outputTest - predOutTest);
ylabel('Error'); xlabel('Datapoint#');
grid on;
title(sprintf('Prediction Error (SeroFAM-Test) (RMSE: %.3f, R^2: %.3f)', testErr(3), 1-testErr(4)));

%% ANFIS prediction
[predOutTrain, outputTrain, trainErr, ...
    predOutTest, outputTest, testErr] = anfisPredict( ...
    data, testPercent, 3);
figure;
subplot(2, 2, 1); hold on;
plot(outputTrain);
plot(predOutTrain);
ylabel('Closing'); xlabel('Datapoint#');
legend({'Actual', 'Prediction'});
grid on;
title('DJIA Prediction (ANFIS-Training)');
subplot(2, 2, 3); hold on;
plot(outputTrain - predOutTrain);
ylabel('Error'); xlabel('Datapoint#');
grid on;
title(sprintf('Prediction Error (ANFIS-Training) (RMSE: %.3f, R^2: %.3f)', trainErr(3), 1-trainErr(4)));
subplot(2, 2, 2); hold on;
plot(outputTest);
plot(predOutTest);
ylabel('Closing'); xlabel('Datapoint#');
legend({'Actual', 'Prediction'});
grid on;
title('DJIA Prediction (ANFIS-Test)');
subplot(2, 2, 4); hold on;
plot(outputTest - predOutTest);
ylabel('Error'); xlabel('Datapoint#');
grid on;
title(sprintf('Prediction Error (ANFIS-Test) (RMSE: %.3f, R^2: %.3f)', testErr(3), 1-testErr(4)));

