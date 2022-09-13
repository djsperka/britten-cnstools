function p = set(p, varargin)
% SET Set stefile properties and return the updated object
propertyArgIn = varargin;
while length(propertyArgIn) >= 2,
   prop = propertyArgIn{1};
   val = propertyArgIn{2};
   propertyArgIn = propertyArgIn(3:end);
   switch prop
       case 'Data'
           p.data = val;
       case 'Events'
           p.events = val;
       case 'EventTypes'
           p.eventtypes = val;
       case 'EventInd'
           p.eventind = val;
       case 'EventTimes'
           p.eventtimes = val;
       case 'FPS'
           p.fps = val;
       case 'Speed'
           p.speed = val;
       case 'MSBefore'
           p.msbefore = val;
       case 'MSAfter'
           p.msafter = val;
       case 'NTrials'
           p.ntrials = val;
       case 'JumpsPerTrial'
           p.jumpspertrial = val;
       case 'SteerMax'
           p.steermaxdeg = val;
       case 'TargOff'
           p.targoffset0deg = val(1);
           p.targoffset1deg = val(2);
       case 'BlinkProb'
           p.blinkprobperjump = val;
       case 'BlinkDurationMS'
           p.blinkdurationms = val;
       case 'BlinkGuardMS'
           p.blinkdurationms = val;
       case 'BlipProb'
           p.blipprobperjump = val;
       case 'BlipDurationMS'
           p.blipdurationms = val;
       case 'BlipGuardMS'
           p.blipdurationms = val;
       case 'BlipMaxAngularVelocity'
           p.blipmaxangvelocity = val;
       case 'Adata'
           p.adata = val;
       case 'Afile'
           p.afile = val;
       case 'Efile'
           p.efile = val;
       otherwise
           error('No property with that name.');
   end
   return;
end
