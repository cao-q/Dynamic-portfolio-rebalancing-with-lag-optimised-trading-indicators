%% Get actual peaks and troughs
function actualPeakTrough = getActualPeakTrough(data)
    mavg = movmean(data, [12,12], 'Endpoints', 'fill');
    mavg = movmean(mavg, [4,4], 'Endpoints', 'fill');
    mmax = movmax(mavg, [16,16]);
    mmin = movmin(mavg, [16,16]);
    actualPeakTrough = nan(size(data));
    k = 1;
    for i = 1:size(mavg)
        if mavg(i) == mmax(i)
            for j = i-16:i+16
                if data(j) == max(data(i-16:i+16))
                    actualPeakTrough(k,1) = j;
                    k = k + 1;
                end
            end
        elseif mavg(i) == mmin(i)
            for j = i-16:i+16
                if data(j) == min(data(i-16:i+16))
                    actualPeakTrough(k,1) = -j;
                    k = k + 1;
                end
            end
        end
    end
    end