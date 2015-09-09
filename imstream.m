%IMSTREAM Open an image or video stream for reading a frame at a time
%
%    h = imstream(filename, [cache_len])
% 
% This class creates a single interface to both streams from both videos
% and sequences of images. The interface is similar to that of MATLAB's
% VideoReader class. However, the read method can only read an image at a
% time, and access to frames is also achieved by subscripted reference,
% i.e. h(3) returns the third frame.
%
% The class also implements a frame cache, which can improve efficiency
% when frames get read several times.
%
% IN:
%   filename - string containing the full or partial path to a video file
%              or first frame in an image sequence.
%   cache_len - scalar indicating how many frames can be stored in the
%               frame cache. Default: 1 (cache only the current frame).
%
% OUT:
%   h - handle to the stream.
%    
%Example:
%   % Process all frame triplets
%   ims = imstream('input.000.png', 3); % Cache last 3 frames used
%   n = ims.num_frames; % Get the number of frames
%   for a = 2:n-1
%      % Create the next triplet of frames
%      A = cat(4, ims(a-1), ims(a), ims(a+1));
%      % Process the frame triplet
%   end
%
%   See also VIDEOREADER, IMSEQ.

% Copyright (C) Oliver Woodford 2011

classdef imstream < handle
    properties (Hidden = true, SetAccess = private)
        sh; % Stream handle
        curr_frame;
        % Image cache stuff
        image_buffer;
        buffer_indices;
        buffer_count;
        read_count;
    end
    
    methods
        % Constructor
        function this = imstream(fname, buf_size)
            [fext, fext, fext] = fileparts(fname);
            switch lower(fext(2:end))
                case {'bmp', 'tif', 'tiff', 'jpeg', 'jpg', 'png', 'ppm', 'pgm', 'pbm', 'gif'}
                    % Image sequence
                    this.sh = imseq(fname);
                case {'mpg', 'avi', 'mp4', 'm4v', 'mpeg', 'mxf', 'mj2', 'wmv', 'asf', 'asx', 'mov', 'ogg'}
                    % Video file
                    this.sh = VideoReader(fname);
                otherwise
                    error('File extension %s not recognised.', fext);
            end
            if nargin < 2
                buf_size = 1; % Default number of images to keep cached
            end
            buf_size = max(buf_size, 1);
            this.image_buffer = cell(buf_size, 1);
            this.buffer_indices = zeros(buf_size, 1);
            this.buffer_count = zeros(buf_size, 1);
            this.read_count = 0;
            % Current frame for VideoIO compatibility
            this.curr_frame = -1;  % Zero based!
        end
        % Destructor
        function delete(this)
            delete(this.sh);
        end
        % Pass on set and get requests to the underlying stream
        function varargout = get(this, varargin)
            [varargout{1:nargout}] = get(this.sh, varargin{:});
        end
        function set(this, varargin)
            set(this.sh, varargin{:});
        end
        % The main function - read!
        function A = read(this, frame)
            if nargin < 2 || ~isscalar(frame)
                errror('Only one frame can be read at a time');
            end
            % Check if buffered
            ind = find(this.buffer_indices == frame, 1);
            if isempty(ind)
                % Cache the frame
                % Find the least recently used slot
                [ind, ind] = min(this.buffer_count);
                % Read in the frame
                this.buffer_indices(ind) = frame;
                this.image_buffer{ind} = read(this.sh, frame);
            end
            % Retrieve the cached frame
            A = this.image_buffer{ind};
            % Update the count and frame number
            this.read_count = this.read_count + 1;
            this.buffer_count(ind) = this.read_count;
            this.curr_frame = frame - 1; % Zero based!
        end
        % Forward calls like imstream(a) to read
        function A = subsref(this, frame)
            switch frame(1).type
                case {'()', '{}'}
                    if numel(frame(1).subs) ~= 1
                        error('Only one dimensional indexing supported');
                    end
                    A = read(this, frame(1).subs{1});
                case '.'
                    if any(strcmp(frame(1).subs, {'read', 'num_frames', 'next', 'getframe', 'getnext', 'step', 'seek', 'close'}))
                        % Forward these references to the relevant method
                        A = builtin('subsref', this, frame);
                    elseif any(strcmp(frame(1).subs, methods(this.sh))) || any(strcmp(frame(1).subs, properties(this.sh)))
                        % Forward these references to the video/image
                        % sequence class
                        A = builtin('subsref', this.sh, frame);
                    else
                        error('%s is not a public property or method of the imstream or %s classes.', frame(1).subs, class(this.sh));
                    end
            end
        end
        % Get the number of frames
        function n = num_frames(this)
            n = get(this.sh, 'NumberOfFrames');
        end
        % Support the videoReader (from VideoIO toolbox) interface for backwards compatibility
        function b = next(this)
            b = step(this, 1);
        end
        function A = getframe(this)
            A = read(this, this.curr_frame+1); % Zero based!
        end
        function A = getnext(this)
            next(this);
            A = getframe(this);
        end
        function b = step(this, delta)
            b = seek(this, this.curr_frame + delta);
        end
        function b = seek(this, fnum)
            b = isempty(read(this, fnum+1)); % Zero based!
        end
        function this = close(this)
            delete(this);
        end
    end
    % Other functions
    methods(Static)
        function b = isPlatformSupported()
            b = true; % Always supported
        end
        function formats = getFileFormats()
            formats = cat(2, VideoReader.getFileFormats(), imseq.getFileFormats());
        end
    end
end
