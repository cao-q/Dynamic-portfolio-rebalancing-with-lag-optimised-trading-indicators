function predErr = tuneSeroFam(x, input, output)

% Setup SeroFAM
cfg = cfgSeroFAM();
cfg.halfLife = x(1);
cfg.forgettor = computeForgettor(cfg.halfLife, cfg.isPureHebbian);
cfg.representationGain = x(2);
cfg.ruleFireThreshold = x(3); 
cfg.binWidth = x(4);
cfg.maxCluster = x(5);
cfg.gapModifier = x(6);

err = nan(size(input));
for i = 1 : numel(input)
    [~, e] = runSeroFam(input{i}, output{i}, cfg, [], [], []);
    err(i) = e(3);
end
predErr = sum(err);


