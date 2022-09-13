% $Id: get.m,v 1.2 2015/05/12 18:17:53 devel Exp $
%
function val = get(p, propName)
% GET Get stefile properties from the specified object
% and return the value
switch propName
    case 'Data'
        val = p.data;
    case 'Events'
        val = p.events;
    case 'EventTypes'
        val = char(p.events(:, 1));
    case 'EventTimes'
        val = p.events(:, 2);
    case 'FPS'
        val = p.fps;
    case 'Speed'
        val = p.speed;
    case 'MSBefore'
        val = p.msbefore;
    case 'MSAfter'
        val = p.msafter;
    case 'NTrials'
        val = p.ntrials;
    case 'JumpsPerTrial'
        val = p.jumpspertrial;
    case 'SteerMax'
        val = p.steermaxdeg;
    case 'TargOff'
        val = [p.targoffset0deg p.targoffset1deg];
    case 'BlinkProb'
        val = p.blinkprobperjump;
    case 'BlinkDurationMS'
        val = p.blinkdurationms;
    case 'BlinkGuardMS'
        val = p.blinkdurationms;
    case 'BlipProb'
        val = p.blipprobperjump;
    case 'BlipDurationMS'
        val = p.blipdurationms;
    case 'BlipGuardMS'
        val = p.blipdurationms;
    case 'BlipMaxAngularVelocity'
        val = p.blipmaxangvelocity;
    case 'Adata'
        val = p.adata;
    case 'Afile'
        val = p.afile;
    case 'Efile'
        val = p.efile;
    case 'FixedLooking'
        val = p.fixedlooking;
    otherwise
        error('No property with that name.');
end
return;
