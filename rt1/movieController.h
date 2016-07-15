//
//  movieController.h
//  rt1
//
//  Created by Stock Lab on 8/05/2014.
//  Copyright (c) 2014 a. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "modelObject.h"
#import "sceneController.h"

@interface movieController : NSObject {
    modelObject *world;
}

@property (nonatomic, strong) modelObject *world;

- (void)setupMovieControllerWithScene:(modelObject *)newScene sceneController:(sceneController *)controller totalNumFrames:(int)nf frameSize:(NSSize)s;
- (void)renderMovie;
- (void)renderMovieST;

@end
