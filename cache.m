%CACHE Wrapper class for caching slow-to-load data
%
%    h = cache(load_func, [cache_len])
%    im = get(h, frame_num)
%
% This class implements a cache, which can improve efficiency when loading
% slow-to-load objects several times.
%
% IN:
%   load_func - Handle to a function which takes a scalar key as input and
%               returns an object.
%   cache_len - scalar indicating how many objects can be stored in the
%               cache. Default: 1 (cache only the most recent object).
%   key - scalar key which is passed to read_fun to load an object.
%
% OUT:
%   h - handle to the cache.

% Copyright (C) Oliver Woodford 2015

classdef cache < handle
    properties (Hidden = true, SetAccess = private)
        load_func; % Function to read in an object
        % Image cache stuff
        buffer;
        cache_indices;
        cache_count;
        load_count;
    end
    
    methods
        % Constructor
        function this = cache(load_fun, buf_size)
            this.load_func = load_fun;
            if nargin < 2
                buf_size = 1; % Default number of images to keep cached
            end
            buf_size = max(buf_size, 1);
            this.buffer = cell(buf_size, 1);
            this.cache_indices = zeros(buf_size, 1);
            this.cache_count = zeros(buf_size, 1);
            this.load_count = 0;
        end
        % The main function - get
        function A = get(this, ind)
            if nargin < 2 || ~isscalar(ind)
                error('Only one object can be got at a time');
            end
            % Check if buffered
            ind = find(this.cache_indices == ind, 1);
            if isempty(ind)
                % Cache the frame
                % Find the least recently used slot
                [ind, ind] = min(this.cache_count);
                % Read in the frame
                this.cache_indices(ind) = ind;
                this.buffer{ind} = this.load_func(ind);
            end
            % Retrieve the cached frame
            A = this.buffer{ind};
            % Update the count and frame number
            this.load_count = this.load_count + 1;
            this.cache_count(ind) = this.load_count;
        end
    end
end
