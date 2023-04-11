function mGrade = asymmetricGaussian(val, centroid, lSigma, rSigma, lShoulder, rShoulder)
mGrade = ones(size(val));

d = val - centroid;

% Left Non-shoulder
idx = (d < 0) & ~lShoulder;
mGrade(idx) = exp(-(d(idx)./lSigma(idx)).^2);

% Right Non-shoulder
idx = (d > 0) & ~rShoulder;
mGrade(idx) = exp(-(d(idx)./rSigma(idx)).^2);
end