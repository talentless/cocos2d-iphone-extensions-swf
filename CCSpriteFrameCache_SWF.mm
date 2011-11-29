//
//  CCSpriteFrameCache_SWF.h
//  CCSpriteFrameCache_SWF_Extension
//
//  Created by Salvatore Gionfriddo on 11/28/11.
//  Copyright (c) 2011 Taco Graveyard. All rights reserved.
//

#include <vg/openvg.h>
#include <vg/vgu.h>

#import "CCSpriteFrameCache_SWF.h"
#import "MonkSWF.h"

@implementation CCSpriteFrameCache (SWF)

-(void) addSpriteFramesWithSWF:(NSString*)filename {
    [self addSpriteFramesWithSWF:filename pixelFormat:kCCTexture2DPixelFormat_RGBA8888];
}

-(void) addSpriteFramesWithSWF:(NSString*)filename pixelFormat:(CCTexture2DPixelFormat)format {
    NSString *path;
    path = [[NSBundle mainBundle] pathForResource:filename ofType:nil];
    
    NSData *data;
    data = [NSData dataWithContentsOfFile:path];
    
    int length = [data length];
    char *buffer = new char[length];
    
    // copy the data into the buffer
    [data getBytes:buffer length:length];
    
    // create a reader using the buffer
    MonkSWF::Reader reader(buffer, length);
    
    // create the swf using the reader
    MonkSWF::SWF *swf_;
    swf_ = new MonkSWF::SWF();
    swf_->initialize();
    swf_->read(&reader);
    
    // clean up the buffer
    delete [] buffer;
    
    // walk through the swf frames to create texture for each frame
    int totalFrames = swf_->numFrames();
    int width = swf_->getFrameWidth();
    int height = swf_->getFrameHeight();
    NSString * filenameMinusExtension = [filename substringToIndex:[filename length] - 4]; // assumes it ends in .swf
    
    for (int i = 0; i < totalFrames; i++) {
        CCRenderTexture * rt = [CCRenderTexture renderTextureWithWidth:width height:height pixelFormat:format];
        // clear the texture
        [rt begin];
        
        // draw the swf
        CCDirector *director;
        director = [CCDirector sharedDirector];
        
        ccDirectorProjection projection;
        projection = director.projection;
        [director setProjection:kCCDirectorProjection2D];
        
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        glEnableClientState(GL_VERTEX_ARRAY);
        
        vgLoadIdentity();
        vgScale(CC_CONTENT_SCALE_FACTOR() * 1.0f,
                CC_CONTENT_SCALE_FACTOR() * 1.0f);
        swf_->drawFrame(i);
        
        glBlendFunc(CC_BLEND_SRC, CC_BLEND_DST);
        
        [director setProjection:projection];
        
        // close out
        [rt end];
        
        CCSpriteFrame * spriteFrame = [[CCSpriteFrame alloc] initWithTexture:rt.sprite.texture
                                                                        rect:CGRectMake(0, 0, width, height)];
        [spriteFrames_ setObject:spriteFrame
                          forKey:[NSString stringWithFormat:@"%@_%d.png", filenameMinusExtension, (i+1)]];
        [spriteFrame release];
    }
    
    delete swf_;
}

@end
