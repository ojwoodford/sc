%IMSEQ Open an image sequence as if it were a video stream.
%
%    h = imseq(filename)
% 
% This class creates an interface to a sequence of images similar to that
% of MATLAB's VideoReader class. However, the read method can only read an
% image at a time.
%
% The format of the filename is assumed to contain an integer, and the
% sequence is assumed to increment that integer by one for each consecutive
% frame, e.g.:
%    input.98.jpg, input.99.jpg, input.100.jpg, etc.
%  The integer can also be zero padded, e.g.:
%    0000.png, 0001.png, 0002.png, etc.
%
% IN:
%    filename - string containing the full or partial path to the first
%               frame in an image sequence.
%
% OUT:
%    h - handle to the stream.
%
%    See also VIDEOREADER, IMSTREAM.

% Copyright (C) Oliver Woodford 2011

classdef imseq < hgsetget
    properties (Hidden = true, GetAccess = private, SetAccess = private)
        % Internal properties
        path;
        format_string;
        zero_index;
    end
    properties (SetAccess = private)
        % Visible properties
        NumberOfFrames;
        Duration;
        FrameRate;
        Height;
        Width;
        BitsPerPixel;
        Name;
        VideoFormat;
        Type;
    end
    properties
        % Writable properties
        CurrentTime;
    end
    properties
        % Editable properties
        Tag;
        UserData;
    end
    
    % Functions - copy of VideoReader functions
    methods
        % Contructor
        function this = imseq(sname)
            this.Name = sname;
            [fpath, fname, fext] = fileparts(which(sname));
            if isempty(fname)
                [fpath, fname, fext] = fileparts(sname);
                if isempty(fpath)
                    fpath = cd;
                else
                    fpath = cd(cd(fpath));
                end
            end
            % Find the last set of consecutive digits
            [start, finish] = regexp(fname, '[0-9]+');
            if isempty(start)
                error('No image index found.');
            end
            start = start(end);
            finish = finish(end);
            this.format_string = sprintf('%s%%.%dd%s%s', fname(1:start-1), finish-start+1, fname(finish+1:end), fext);
            this.path = [fpath filesep];
            this.zero_index = str2double(fname(start:finish)) - 1;
            this.FrameRate = 30;
            % Compute sequence length
            fnum = this.zero_index;
            while 1
                fnum = fnum + 1;
                % Check we can open the file for reading
                fh = fopen([this.path sprintf(this.format_string, fnum)], 'r');
                if fh == -1
                    break;
                end
                fclose(fh);
            end
            this.NumberOfFrames = fnum - 1 - this.zero_index;
            this.Duration = this.NumberOfFrames / this.FrameRate;
            % Compute frame info
            A = read(this, 1);
            this.Width = size(A, 2);
            this.Height = size(A, 1);
            switch class(A)
                case {'uint8', 'int8'}
                    this.BitsPerPixel = 8;
                case {'uint16', 'int16'}
                    this.BitsPerPixel = 16;
                case {'uint32', 'int32', 'single'}
                    this.BitsPerPixel = 32;
                case {'uint64', 'int64', 'double'}
                    this.BitsPerPixel = 64;
            end
            this.BitsPerPixel = size(A, 3) * this.BitsPerPixel;
            str = {'Gray%d', '%d', 'RGB%d', 'CMYK%d'};
            this.VideoFormat = sprintf(str{size(A, 3)}, this.BitsPerPixel);
            this.Type = 'imseq';
            this.Tag = '';
            this.CurrentTime = 0;
        end
        % Destructor
        function this = delete(this)
        end
        % Read - same as VideoReader
        function A = read(this, fnum)
            if fnum == Inf
                % Seek to the end
                fnum = this.NumberOfFrames;
            end
            this.CurrentTime = fnum / this.FrameRate;
            if fnum < 1 || fnum > this.NumberOfFrames
                error('Frame %d is not in the range of allowed frames: [1 %d].', fnum, this.NumberOfFrames);
            end
            [A, map] = imread([this.path sprintf(this.format_string, this.zero_index+fnum)]);
            if ~isempty(map)
                A = reshape(map(uint32(A)+1,:), [size(A) size(map, 2)]); % Assume indexed from 0
            end
        end
        % hasFrame - same as VideoReader
        function tf = hasFrame(this)
            tf = this.CurrentTime < this.Duration;
        end
        % readFrame - same as VideoReader
        function A = readFrame(this)
            A = read(this, round(this.CurrentTime * this.FrameRate) + 1);
        end
    end
    % Other VideoReader functions
    methods(Static)
        function b = isPlatformSupported()
            b = true; % Always supported
        end
        function formats = getFileFormats()
            extensions = {'bmp', 'tif', 'tiff', 'jpeg', 'jpg', 'png', 'ppm', 'pgm', 'pbm', 'gif'};
            formats = audiovideo.FileFormatInfo.empty();
            for a = 1:numel(extensions)
                formats(a) = audiovideo.FileFormatInfo(extensions{a}, [upper(extensions{a}) ' file sequence'], true, false);
            end
        end
    end
end