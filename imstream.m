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
        number_of_frames;
        curr_frame;
        last_frame_lowlevel;
        buffer; % Image cache stuff
    end
    
    methods
        % Constructor
        function this = imstream(fname, varargin)
            if iscell(fname)
                % Assume this is a list of images
                this.sh = imseq(fname);
                this.number_of_frames = this.sh.NumberOfFrames;
            else
                [~, ~, fext] = fileparts(fname);
                switch lower(fext(2:end))
                    case {'bmp', 'tif', 'tiff', 'jpeg', 'jpg', 'png', 'ppm', 'pgm', 'pbm', 'gif'}
                        % Image sequence
                        this.sh = imseq(fname);
                        this.number_of_frames = this.sh.NumberOfFrames;
                    case {'mpg', 'avi', 'mp4', 'm4v', 'mpeg', 'mxf', 'mj2', 'wmv', 'asf', 'asx', 'mov', 'ogg'}
                        % Video file
                        this.sh = VideoReader(fname);
                        this.number_of_frames = round(this.sh.Duration * this.sh.FrameRate);
                    otherwise
                        error('File extension %s not recognised.', fext);
                end
            end
            % Create the buffered stream
            this.buffer = cache(@(n) read_lowlevel(this, n), varargin{:});
            % Current frame for VideoIO compatibility
            this.curr_frame = 0;
            this.last_frame_lowlevel = 0;
        end
        % Destructor
        function delete(this)
            delete(this.sh);
        end
        % Disp - pass on to the underlying stream
        function disp(this, varargin)
            disp(this.sh, varargin{:});
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
            A = get(this.buffer, frame); % Read from the buffered stream
            this.curr_frame = frame;
        end
        % Forward calls like imstream(a) to read
        function varargout = subsref(this, frame)
            switch frame(1).type
                case {'()', '{}'}
                    if numel(frame(1).subs) ~= 1
                        error('Only one dimensional indexing supported');
                    end
                    [varargout{1:nargout}] = read(this, frame(1).subs{1});
                case '.'
                    if any(strcmp(frame(1).subs, methods(this)))
                        % Forward these references to the relevant method
                        [varargout{1:nargout}] = builtin('subsref', this, frame);
                    elseif any(strcmp(frame(1).subs, methods(this.sh))) || any(strcmp(frame(1).subs, properties(this.sh)))
                        % Forward these references to the video/image
                        % sequence class
                        [varargout{1:nargout}] = builtin('subsref', this.sh, frame);
                    else
                        error('%s is not a public property or method of the imstream or %s classes.', frame(1).subs, class(this.sh));
                    end
            end
        end
        % Get the number of frames
        function n = num_frames(this)
            n = this.number_of_frames;
        end
        function n = numel(this, varargin)
            if nargin > 1
                n = prod(cellfun(@numel, varargin));
            else
                n = num_frames(this);
            end
        end
        function sz = size(this, dim)
            sz = [num_frames(this) 1];
            if nargin < 2
                return;
            end
            sz = sz(min(dim, end));
        end
        % Support the videoReader (from VideoIO toolbox) interface for backwards compatibility
        function b = next(this)
            b = step(this, 1);
        end
        function A = getframe(this)
            A = read(this, this.curr_frame);
        end
        function A = getnext(this)
            next(this);
            A = getframe(this);
        end
        function b = step(this, delta)
            b = seek(this, this.curr_frame + delta);
        end
        function b = seek(this, fnum)
            b = isempty(read(this, fnum));
        end
        function this = close(this)
            delete(this);
        end
        % Support for new videoReader methods
        function b = hasFrame(this)
            b = this.curr_frame < num_frames(this);
        end
        function A = readFrame(this)
            A = read(this, this.curr_frame + 1);
        end
        % The low-level read, which uses time-based reads
        function A = read_lowlevel(this, fnum)
            fnum = double(fnum);
            if fnum ~= this.last_frame_lowlevel + 1
                this.sh.CurrentTime = (fnum - 1) / this.sh.FrameRate;
            end
            A = readFrame(this.sh);
            this.last_frame_lowlevel = fnum;
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
