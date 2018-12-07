%IMREAD_RGB Read image to uint8 RGB array, regardless of input format
%
%   im = imread_rgb(name, [background])
%
%IN:
%   name - Relative or absolute path to an image file to read in.
%   background - 1x3 RGB color specification (in the range [0, 1] for the
%                background, if an image has transparency. Default:
%                checkerboard pattern.
%
%OUT:
%    im - MxNx3 RGB image.

function A = imread_rgb(name, background)
[A, map, alpha] = imread(name);
A = A(:,:,:,1); % Keep only first frame of multi-frame files
if ~isempty(map)
    map = uint8(map * 256 - 0.5); % Convert to uint8 for storage
    A = reshape(map(uint32(A)+1,:), [size(A) size(map, 2)]); % Assume indexed from 0
elseif size(A, 3) == 4
    if lower(name(end)) == 'f'
        % TIFF in CMYK colourspace - convert to RGB
        if isfloat(A)
            A = A * 255;
        else
            A = single(A);
        end
        A = 255 - A;
        A(:,:,4) = A(:,:,4) / 255;
        A = uint8(A(:,:,1:3) .* A(:,:,[4 4 4]));
    else
        % Assume 4th channel is an alpha matte
        alpha = A(:,:,4);
        A = A(:,:,1:3);
    end
end
if ~isempty(alpha)
    if nargin < 2
        % Create a checkerboard background
        sqSz = max(size(alpha));
        sqSz = floor(max(log(sqSz / 100), 0) * 10 + 1 + min(sqSz, 100) / 20);
        background = repmat(85, ceil(size(alpha) / sqSz));
        background(2:2:end,1:2:end) = 171;
        background(1:2:end,2:2:end) = 171;
        background = kron(background, ones(sqSz));
        background = repmat(background(1:size(A, 1),1:size(A, 2)), 1, 1, 3);
    else
        background = reshape(background, 1, 1, 3) * 256;
    end
    % Apply transprency over a grey checkerboard pattern
    if isa(alpha, 'uint8')
        alpha = double(alpha) / 255;
    end
    alpha = repmat(alpha, 1, 1, 3);
    A = uint8(double(A) .* alpha + background .* (1 - alpha));
end
end