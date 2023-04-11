function cfg = cfgSeroFAM()
global dbgPrint dbgPrintFileId
dbgPrint = 0;
dbgPrintFileId = 1; % 1 for standard output (the screen)

cfg.MAX_NEURON_PREMISE = 500;
cfg.MAX_DATA_BIN = 8000; %5000
%NOTES: halfLife = -1 % PUREHEBBIAN
%NOTES: halfLife =  0 % BCM WITH SIMPLE AVERAGE THRESHOLD
%NOTES: halfLife = +X % BCM WITH EXPONENTIAL MOVING THRESHOLD
cfg.isPureHebbian = false;
cfg.halfLife = 15; %15
cfg.forgettor = computeForgettor(cfg.halfLife, cfg.isPureHebbian);
cfg.representationGain = 0.5;
% cfg.ruleFireThreshold: Proportion of rules with highest potential fired.
% cfg.ruleFireThreshold = 1: all rules fired.
% Used to be call minimumPotential. Rename as it does not convey meaning.
cfg.ruleFireThreshold = 0.8; %0.8
cfg.binWidth = 1; %1
cfg.maxCluster = 50; %50
cfg.gapModifier = 1;
end