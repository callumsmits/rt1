//
//  movie.h
//  rt1
//
//  Created by Stock Lab on 8/05/2014.
//  Copyright (c) 2014 a. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface movie : NSObject {
    int frameRate;
}

@property (nonatomic) int frameRate;

- (void)setupMP4VideoWithPath:(NSString *)fileName withSize:(NSSize)size;
- (void)setupProResVideoWithPath:(NSString *)fileName withSize:(NSSize)size;
- (void)addFrameToMovieFromBuffer:(unsigned char *)pixels;
- (void)addFrameToMovieFromImage:(NSImage *)image;
- (void)finishMovie;

@end
