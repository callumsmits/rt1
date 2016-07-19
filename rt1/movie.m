//
//  movie.m
//  rt1
//
//  Created by Stock Lab on 8/05/2014.
//  Copyright (c) 2014 a. All rights reserved.
//

#import "movie.h"
#import <AVFoundation/AVFoundation.h>
#include <AppKit/AppKit.h>
#import "globalSettings.h"

#define kMovieRetryDelay 0.1

@interface movie () {
    AVAssetWriter *videoWriter;
    AVAssetWriterInput *videoWriterInput;
    AVAssetWriterInputPixelBufferAdaptor *adaptor;
    NSSize frameSize;
    int64_t f;
}

@property (nonatomic, strong) AVAssetWriter *videoWriter;
@property (nonatomic, strong) AVAssetWriterInput *videoWriterInput;
@property (nonatomic, strong) AVAssetWriterInputPixelBufferAdaptor *adaptor;

- (void)setupMovieWithName:(NSString *)path ofType:(NSString *)type withSize:(NSSize)size;

@end

@implementation movie

@synthesize videoWriter, videoWriterInput, adaptor;
@synthesize frameRate;

- (void)setupMP4VideoWithPath:(NSString *)fileName withSize:(NSSize)size {
    frameSize = size;
    frameRate = kMovieFrameRate;
    f = 0;
    [self setupMovieWithName:fileName ofType:AVVideoCodecH264 withSize:size];
}

- (void)setupProResVideoWithPath:(NSString *)fileName withSize:(NSSize)size {
    frameSize = size;
    frameRate = kMovieFrameRate;
    f = 0;
    [self setupMovieWithName:fileName ofType:AVVideoCodecAppleProRes4444 withSize:size];
}

- (void)setupVideoWithPath:(NSString *)fileName withSize:(NSSize)size {
    frameSize = size;
    frameRate = kMovieFrameRate;
    f = 0;
    [self setupMovieWithName:fileName ofType:kMovieOutputCodec withSize:size];
}

- (void)setupMovieWithName:(NSString *)path ofType:(NSString *)type withSize:(NSSize)size {
    NSLog(@"Setting up movie");
    
    NSError *error = nil;
    
    if([[NSFileManager defaultManager] fileExistsAtPath:path]){
        [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
    }

    NSMutableDictionary *compressionSettings = NULL;
    compressionSettings = [NSMutableDictionary dictionary];
    
    [compressionSettings setObject:AVVideoColorPrimaries_ITU_R_709_2
                            forKey:AVVideoColorPrimariesKey];
    [compressionSettings setObject:AVVideoTransferFunction_ITU_R_709_2
                            forKey:AVVideoTransferFunctionKey];
    [compressionSettings setObject:AVVideoYCbCrMatrix_ITU_R_709_2
                            forKey:AVVideoYCbCrMatrixKey];
    
    self.videoWriter = [[AVAssetWriter alloc] initWithURL:
                        [NSURL fileURLWithPath:path] fileType:kMovieOutputFileType
                                                    error:&error];
    NSParameterAssert(videoWriter);
    
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   type, AVVideoCodecKey,
                                   [NSNumber numberWithInt:size.width], AVVideoWidthKey,
                                   [NSNumber numberWithInt:size.height], AVVideoHeightKey,
//                                   compressionSettings, AVVideoColorPropertiesKey,
                                   nil];
    
    self.videoWriterInput = [AVAssetWriterInput
                             assetWriterInputWithMediaType:AVMediaTypeVideo
                             outputSettings:videoSettings];
    
//    NSDictionary *pixelAttributes = @{(id)kCVPixelBufferWidthKey: @(size.width),
//                                      (id)kCVPixelBufferHeightKey: @(size.height),
//                                      (id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32ARGB),
//                                      (id)kCVPixelBufferCGBitmapContextCompatibilityKey: @YES};
    
    self.adaptor = [AVAssetWriterInputPixelBufferAdaptor
                    assetWriterInputPixelBufferAdaptorWithAssetWriterInput:videoWriterInput
                    sourcePixelBufferAttributes:nil];
    
    NSParameterAssert(videoWriterInput);
    NSParameterAssert([videoWriter canAddInput:videoWriterInput]);
    videoWriterInput.expectsMediaDataInRealTime = NO;
    [videoWriter addInput:videoWriterInput];
    
    //Start a session:
    [videoWriter startWriting];
    [videoWriter startSessionAtSourceTime:kCMTimeZero];
    
    
}

- (CVPixelBufferRef) newPixelBufferFromCGImage: (CGImageRef) image
{
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, frameSize.width,
                                          frameSize.height, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
    CGContextRef context = CGBitmapContextCreate(pxdata, frameSize.width,
                                                 frameSize.height, 8, 4*frameSize.width, rgbColorSpace,
                                                 kCGImageAlphaPremultipliedFirst);
    NSParameterAssert(context);
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image),
                                           CGImageGetHeight(image)), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

- (void)addFrameToMovieFromBuffer:(unsigned char *)pixels {
    
    CVReturn ok;
    CVPixelBufferRef buffer;
    
//    CVReturn result = CVPixelBufferPoolCreatePixelBuffer(NULL, adaptor.pixelBufferPool, &buffer);
    
//    if (result != kCVReturnSuccess)
//        NSLog(@"Error: Failed to create pixel buffer");

    ok = CVPixelBufferCreateWithBytes(NULL, frameSize.width, frameSize.height, kCVPixelFormatType_32ARGB, pixels, sizeof(unsigned char) * 4 * frameSize.width, NULL, NULL, NULL, &buffer);
    
    //    NSLog(@"Pixel buffer create: %d", ok);
    
    //[self pixelBufferFromCGImage:[img CGImage] andSize:size];
    
    /*CVPixelBufferLockBaseAddress(buffer, 0);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
    
    if (colorSpace == NULL)
        return;
    
    int width = (int)CVPixelBufferGetWidth(buffer);
    int height = (int)CVPixelBufferGetHeight(buffer);
    
    CGContextRef context = CGBitmapContextCreate(
                                    CVPixelBufferGetBaseAddress(buffer),
                                    width,
                                    height,
                                    8,
                                    CVPixelBufferGetBytesPerRow(buffer),
                                    colorSpace,
                                    kCGImageAlphaPremultipliedFirst
                                    );
    
    
    if (context == NULL)
        return;
    
    NSBitmapImageRep *repGen = [[NSBitmapImageRep alloc]
                                initWithBitmapDataPlanes: nil  // allocate the pixel buffer for us
                                pixelsWide: width
                                pixelsHigh: height
                                bitsPerSample: 8
                                samplesPerPixel: 4
                                hasAlpha: YES
                                isPlanar: NO
                                colorSpaceName: @"NSCalibratedRGBColorSpace"
                                bytesPerRow: width * 4     // passing 0 means "you figure it out"
                                bitsPerPixel: 32];   // this must agree with bitsPerSample and samplesPerPixel
    
    NSBitmapImageRep *rep = [repGen bitmapImageRepByRetaggingWithColorSpace:[NSColorSpace sRGBColorSpace]];
    
    for (int i = 0; i < height; i++ )
    {
        for (int j = 0; j < width; j++ )
        {
            NSUInteger colourArray[4] = {pixels[4 * (i * (int)width + j) + 1], pixels[4 * (i * (int)width + j) + 2], pixels[4 * (i * (int)width + j) + 3], pixels[4 * (i * (int)width + j)]};
            
            [rep setPixel:colourArray atX:j y:i];
        }
    }
    
    CGImageRef frame = [rep CGImage];
    
    CGRect rect = CGRectMake(0, 0, width, height);
    CGContextDrawImage(context, rect, frame);*/
    
    int j = 0;
    BOOL append_ok = NO;
    
    while (!append_ok && j < 30)
    {
        if (adaptor.assetWriterInput.readyForMoreMediaData)
        {
//            printf("appending %d attemp %d\n", f, j);
            
            CMTime frameTime = CMTimeMake(f,(int32_t) frameRate);
            append_ok = [adaptor appendPixelBuffer:buffer withPresentationTime:frameTime];
            
            if(buffer && append_ok)
                CVPixelBufferRelease(buffer);
        }
        else
        {
            printf("adaptor not ready %d, %d\n", (int)f, j);
            [NSThread sleepForTimeInterval:kMovieRetryDelay];
        }
        j++;
    }
    if (!append_ok) {
        printf("Error appending image %d\n", (int)f);
    }
//    if (context)
//        CGContextRelease(context);
    
//    if (colorSpace)
//        CGColorSpaceRelease(colorSpace);
    
//    if (buffer) {
//        CVPixelBufferUnlockBaseAddress(buffer, 0);
//        CVPixelBufferRelease(buffer);
//    }
    f++;
}

- (void)addFrameToMovieFromImage:(NSImage *)image {
//    CVReturn ok;
    CVPixelBufferRef buffer;
    
    buffer = [self newPixelBufferFromCGImage:[image CGImageForProposedRect:NULL context:NULL hints:NULL]];
    
//    ok = CVPixelBufferCreateWithBytes(NULL, frameSize.width, frameSize.height, kCVPixelFormatType_32ARGB, pixels, sizeof(unsigned char) * 4 * frameSize.width, NULL, NULL, NULL, &buffer);
    //    NSLog(@"Pixel buffer create: %d", ok);
    
//    [self pixelBufferFromCGImage:[image CGImage] andSize:frameSize];
    
    /*CVPixelBufferLockBaseAddress(buffer, 0);
     CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
     
     if (colorSpace == NULL)
     return;
     
     int width = (int)CVPixelBufferGetWidth(buffer);
     int height = (int)CVPixelBufferGetHeight(buffer);
     
     CGContextRef context = CGBitmapContextCreate(
     CVPixelBufferGetBaseAddress(buffer),
     width,
     height,
     8,
     CVPixelBufferGetBytesPerRow(buffer),
     colorSpace,
     kCGImageAlphaPremultipliedFirst
     );
     
     
     if (context == NULL)
     return;
     
     NSBitmapImageRep *repGen = [[NSBitmapImageRep alloc]
     initWithBitmapDataPlanes: nil  // allocate the pixel buffer for us
     pixelsWide: width
     pixelsHigh: height
     bitsPerSample: 8
     samplesPerPixel: 4
     hasAlpha: YES
     isPlanar: NO
     colorSpaceName: @"NSCalibratedRGBColorSpace"
     bytesPerRow: width * 4     // passing 0 means "you figure it out"
     bitsPerPixel: 32];   // this must agree with bitsPerSample and samplesPerPixel
     
     NSBitmapImageRep *rep = [repGen bitmapImageRepByRetaggingWithColorSpace:[NSColorSpace sRGBColorSpace]];
     
     for (int i = 0; i < height; i++ )
     {
     for (int j = 0; j < width; j++ )
     {
     NSUInteger colourArray[4] = {pixels[4 * (i * (int)width + j) + 1], pixels[4 * (i * (int)width + j) + 2], pixels[4 * (i * (int)width + j) + 3], pixels[4 * (i * (int)width + j)]};
     
     [rep setPixel:colourArray atX:j y:i];
     }
     }
     
     CGImageRef frame = [rep CGImage];
     
     CGRect rect = CGRectMake(0, 0, width, height);
     CGContextDrawImage(context, rect, frame);*/
    
    int j = 0;
    BOOL append_ok = NO;
    
    while (!append_ok && j < 30)
    {
        if (adaptor.assetWriterInput.readyForMoreMediaData)
        {
            //            printf("appending %d attemp %d\n", f, j);
            
            CMTime frameTime = CMTimeMake(f,(int32_t) frameRate);
            append_ok = [adaptor appendPixelBuffer:buffer withPresentationTime:frameTime];
            
            if(buffer && append_ok)
            CVPixelBufferRelease(buffer);
        }
        else
        {
            printf("adaptor not ready %d, %d\n", (int)f, j);
            [NSThread sleepForTimeInterval:kMovieRetryDelay];
        }
        j++;
    }
    if (!append_ok) {
        printf("Error appending image %d\n", (int)f);
    }
    //    if (context)
    //        CGContextRelease(context);
    
    //    if (colorSpace)
    //        CGColorSpaceRelease(colorSpace);
    
    //    if (buffer) {
    //        CVPixelBufferUnlockBaseAddress(buffer, 0);
    //        CVPixelBufferRelease(buffer);
    //    }
    f++;
}

- (void)finishMovie {
    
    //Finish the session:
    [videoWriterInput markAsFinished];
    [videoWriter finishWriting];
    NSLog(@"Movie Ended");
    
}

@end
