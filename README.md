sc
==

A MATLAB toolbox to turn gridded data into pretty images, and displaying images.

### Some of the functions

## sc

`sc` is a useful function for displaying rich image data, of use to anyone wishing to visualize and save 2D data in ways beyond that which MATLAB built-in functions allow.

This function can be used in place of MATLAB's `image`, `imagesc` and `imshow`, but does so much more. It is fast and displays images as they should be - correct aspect ratio, integer magnification, no axes. In addition, it can return the image as an output variable - useful for saving to disk, texture mapping surfaces, and post-rendering manipulation such as overlaying/combining two or more images.

All the MATLAB built-in colormaps are implemented, but without MATLAB's nasty discretization artifacts. Plus, there are many new colormaps which are helpful for viewing more complex data, such as optic flow, likelihoods over images, difference images, segmentations, stereo image pairs (as anaglyphs) and edge-maps with orientation. It also accepts user defined linear and non-linear colormaps.

`sc` comes with a complete demo (call `sc()`), to help you get the most out of it. It doesn't require that you have any toolboxes, either.

## imstream

`imstream` is a handle class which provides a consistent interface to both movies and sequences of images. For example:

    ims = imstream('xylophone.mp4');
    imshow(ims(9)); % Display the ninth frame of xylophone.mp4

or

    ims = imstream('sequence0001.png');
    imshow(ims(9)); % Display the ninth frame of the image sequence sequence0001.png, sequence0002.png etc.
  
## imdisp

`imdisp` is a function that can replace `image`, `imshow` and `montage`, without requiring any toolboxes. When displaying multiple images, it can display them in a grid or a smaller grid that can be scrolled through with keypresses. It can also visualize imstream objects:

    imdisp(imstream('xylophone.mp4'), 'Size', 1); % Use arrow keys to scroll through the movie

The function can be used as a visual DIR: call `imdisp()` to display all images in the current directory on a grid, or `imdisp({}, 'Size', 1)` to scroll through them one at a time.
