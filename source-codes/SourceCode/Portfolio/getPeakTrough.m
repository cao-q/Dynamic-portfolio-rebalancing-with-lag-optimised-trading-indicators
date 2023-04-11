%% Get peaks and trough of market
function peakTrough = getPeakTrough(data)
    mavg = movmean(data, [12,12], 'Endpoints', 'fill');
    mavg = movmean(mavg, [4,4], 'Endpoints', 'fill');
    mmax = movmax(mavg, [16,16]);
    mmin = movmin(mavg, [16,16]);
    peakTrough = [];
    for i = 1:size(mavg)
        if mavg(i) == mmax(i)
            peakTrough = [peakTrough; -i];
        elseif mavg(i) == mmin(i)
            peakTrough = [peakTrough; i];
        end
    end
end    