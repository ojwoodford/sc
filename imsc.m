%IMSC Wrapper function to SC which replicates display behaviour of IMAGESC
%
% Examples:
%   imsc(I, varargin)
%   imsc(x, y, I, varargin)
%   h = imsc(...)
%
% IN:
%    x - 1xJ vector of x-axis bounds. If x(1) > x(2) the image is flipped
%        left-right. If J > 2 then only the first and last values are used.
%        Default: [1 size(I, 2)].
%    y - 1xK vector of y-axis bounds. If y(1) > y(2) the image is flipped
%        up-down. If K > 2 then only the first and last values are used.
%        Default: [1 size(I, 1)].
%    I - MxNxC input image.
%    varargin - Extra input parameters passed to SC. See SC's help for more
%               information.
%
% OUT:
%    h - Handle of the image graphics object generated.
%
% See also IMAGESC, SC.

% Copyright: Oliver Woodford, 2010

function h = imsc(varargin)

% Check for x, y as first two inputs
if nargin > 2 && isvector(varargin{1}) && numel(varargin{1}) > 1 && isvector(varargin{2}) && numel(varargin{2}) > 1
    % Render
    [I, clim, map] = sc(varargin{3:end});
    % Display
    h = image(varargin{1}([1 end]), varargin{2}([1 end]), I);
else
    % Render
    [I, clim, map] = sc(varargin{:});
    % Display
    h = image(I);
end
% Fix up colormap, if there is one
if ~isempty(clim)
    set(h, 'CDataMapping', 'scaled');
    ha = get(h, 'Parent');
    set(ha, 'CLim', clim);
    set(get(ha, 'Parent'), 'Colormap', map);
end
% Don't display the handle if not requested
if nargout < 1
    clear h
end