function [ecstr, ecind] = ecencode(a, ecletters, eccodes)
% Encode the ecfile struct into a string (ecstr) of letters using the
% string ecletters and the codes eccodes. All other ecodes are ignored. 
%
% The  input 'a' is assumed to be the same as that returned by 'ecf'. The
% inputs ecletters and eccodes should have the same number of elements. The  
% ecode for each element of the struct array 'a' is compared to the values
% in 'eccodes'. If a match is found at eccodes(i), then the character at
% ecletters(i) is added to the string 'ecstr', and the index i is added to
% 'ecind'. The arrays returned have the same number of elements, and the
% values in 'ecind' can be used to recover the actual data values stored in
% 'a'. 
%
% This function is designed to be used in the parsing of a sequence of
% codes, where certain patterns of codes denote "good" trials or trials
% where a particular pattern of behavior was desired. See the function
% 'pstparse' for a more complete usage. 

ecstr='';
ecind=[];
n=0;
for i=1:size(a, 2),
    % for each ecode we loop over all the relevant codes, extracting and
    % encoding them as we find them. For each code we find, save the index
    % of that code in ind[]. 
    for j=1:size(ecletters, 2),
        if a(i).channel==eccodes(j), 
            n=n+1;
            ecstr(n) = ecletters(j);
            ecind(n) = i;
            break;
        end
    end
end

return
