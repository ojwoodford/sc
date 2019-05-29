%DIRIM  Get the names of all images in a directory
%
%   names = dirim([dirname])
%
%IN:
%   dirname - Absolute or relative path to the directory to search. Can
%             include wildcards supported by the DIR command. Default:
%             current directory.
%
%OUT:
%   names - Cell array of names of images in the directory.
%
%   See also DIR.

function D = dirim(varargin)
% Go through the directory list
D = dir(varargin{:});
% Check if file is a supported image type
isim = @(f) numel(f.name) > 4 && ~f.isdir && (any(strcmpi(f.name(end-3:end), {'.png', '.tif', '.jpg', '.bmp', '.ppm', '.pgm', '.pbm', '.gif', '.ras'})) || any(strcmpi(f.name(end-4:end), {'.tiff', '.jpeg'})));
D = D(arrayfun(isim, D));
% Return the names
D = {D(:).name};
end