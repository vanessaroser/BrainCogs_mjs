 
cfg.lCue = 200;
cfg.minCueSep = 12;

cueOffset = 10;
 nCues = [11 0];
 iSide = 1;

 
 lEffective            = cfg.lCue - cueOffset - (nCues(iSide) - 1) * cfg.minCueSep;
stim.cuePos{iSide}    = cueOffset + sort(rand(1, nCues(iSide))) * lEffective    ...
              + (0:nCues(iSide) - 1) * cfg.minCueSep  ;

%Ascending series (diff=constant) + ascending series (diff random) => intervals constant + random.