%IMBUF Wrapper class for caching a set of images from a loader class/function
%
%    h = imbuf(read_fun, [cache_len])
%    im = read(h, frame_num)
%
% This class implements a frame cache, which can improve efficiency when
% frames get read several times.
%
% IN:
%   read_fun - Handle to a function which takes a frame index as input and
%              returns an image.
%   cache_len - scalar indicating how many frames can be stored in the
%               frame cache. Default: 1 (cache only the current frame).
%   frame_num - scalar frame index which is passed to read_fun to load a
%               frame.
%
% OUT:
%   h - handle to the buffered stream.

% Copyright (C) Oliver Woodford 2015

classdef imbuf < handle
    properties (Hidden = true, SetAccess = private)
        read_func; % Function to read in an image
        % Image cache stuff
        image_buffer;
        buffer_indices;
        buffer_count;
        read_count;
    end
    
    methods
        % Constructor
        function this = imbuf(read_fun, buf_size)
            this.read_func = read_fun;
            if nargin < 2
                buf_size = 1; % Default number of images to keep cached
            end
            buf_size = max(buf_size, 1);
            this.image_buffer = cell(buf_size, 1);
            this.buffer_indices = zeros(buf_size, 1);
            this.buffer_count = zeros(buf_size, 1);
            this.read_count = 0;
        end
        % The main function - read
        function A = read(this, frame)
            if nargin < 2 || ~isscalar(frame)
                error('Only one frame can be read at a time');
            end
            % Check if buffered
            ind = find(this.buffer_indices == frame, 1);
            if isempty(ind)
                % Cache the frame
                % Find the least recently used slot
                [ind, ind] = min(this.buffer_count);
                % Read in the frame
                this.buffer_indices(ind) = frame;
                this.image_buffer{ind} = this.read_func(frame);
            end
            % Retrieve the cached frame
            A = this.image_buffer{ind};
            % Update the count and frame number
            this.read_count = this.read_count + 1;
            this.buffer_count(ind) = this.read_count;
        end
    end
end
