%STR2COLOR Convert a color character to an RGB vector
%
%    color = str2color(char)
%
% This function takes in a color character, e.g. 'k', 'r', 'g', 'b', etc.
% and returns the RGB vector for that color.
%
%IN:
%   char - One of 'k', 'b', 'c', 'r', 'm', 'y', 'w'.
%
%OUT:
%   color - 1x3 truecolor (double in range [0,1]) RGB vector for the input.

function x = str2color(x)
x = rem(floor((strfind('kbgcrmyw', x) - 1) * [0.25 0.5 1]), 2);
end