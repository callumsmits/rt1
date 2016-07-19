//
//  globalSettings.h
//  rt1
//
//  Created by Callum Smits on 28/08/2014.
//  Copyright (c) 2014 a. All rights reserved.
//

#ifndef rt1_globalSettings_h
#define rt1_globalSettings_h


// These settings control most generic aspects of making the movie
// After changing please re-build the target program(s)

// Image dimensions
#define kImageWidth 1024
#define kImageHeight 768

// Number of image aliases that are rendered and combined for the final image
// A higher number increases image quality - use 1 for preview and 8 - 32 depending on your computer for final output
#define kaaQuality 4

// Maximum number of scene lights
#define kMaxNumLights 8

// location of all output files
// This directory should also contain the sub-directories animationData and images
#define kRenderOutputRoot "/Users/calsmi/Documents/Development/rt1Output/"

// Movie parameters

// Movie length in frames
#define kNumFramesToRender 1

// Movie frame rate
#define kMovieFrameRate 30

// Movie file name - saved in the output directory below
#define kMovieOutputName "output.mov"

//Movie codec and file-type
#define kMovieOutputCodec AVVideoCodecAppleProRes4444
#define kMovieOutputFileType AVFileTypeQuickTimeMovie
//#define kMovieOutputCodec AVVideoCodecH264
//#define kMovieOutputFileType AVFileTypeMPEG4

// Render parameters

// Whether or not to render atom 'intrinsic' lights
#define kRenderCorrectIntrinsicLighting 1

// Have a small pause between rendering each alias
#define kTakeARest 0

// Whether or not the rt1 target also performs rendering
// Monolithic (ie all in one) is good for testing
// Rendering separately using movieGenerator is better for previews/rendering because image state is preserved between renders
#define kMonolithic 1

// Whether to use multithreading to speed-up rendering when monolithic
#define kMonolithicMultithreadedRender 1

// Should the movieGenerator target attempt to use the GPU
#define kMovieGeneratorUseGPU 1

// Location of the rt1 source code for loading the openCL code
#define kRenderCLKernelsPath "/Users/calsmi/Documents/Development/rt1/rt1/"

#endif
