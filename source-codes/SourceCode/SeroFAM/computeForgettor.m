function forgettor = computeForgettor(halfLife, isPureHebbian)
if isPureHebbian
    forgettor = 1;
else
    if halfLife > 0
        forgettor = 0.5^(1/halfLife);
    else
        forgettor = 1;
    end
end
end