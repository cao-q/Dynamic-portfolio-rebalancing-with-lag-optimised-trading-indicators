function [inputTest, predOutTest, opt] = getRangeOpt(filename, startIdx, endIdx)
out = getOptim(filename);
outSorted = sortrows(out, 7, 'descend');
opt = outSorted(1, 1:5);
d = fetchData(filename);
[~, ~, ~, ~, inputTest,  predOutTest,  ~,  ~] = serofamPredictRange(d, 0, false, startIdx, endIdx);
end