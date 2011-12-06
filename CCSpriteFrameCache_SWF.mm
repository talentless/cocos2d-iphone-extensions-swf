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
#import "CCSpriteSWF.h"

@implementation CCSpriteFrameCache (SWF)

-(void) addSpriteFramesWithSWF:(NSString*)filename {
    [self addSpriteFramesWithSWF:filename pixelFormat:kCCTexture2DPixelFormat_RGBA8888];
}

-(void) addSpriteFramesWithSWF:(NSString*)filename pixelFormat:(CCTexture2DPixelFormat)format {
    CCSpriteSWF * spriteSwf = [CCSpriteSWF spriteWithFile:filename];
    
    // walk through the swf frames to create texture for each frame
    int totalFrames = spriteSwf.swf->numFrames();

    NSString * filenameMinusExtension = [filename substringToIndex:[filename length] - 4]; // assumes it ends in .swf
    
    for (int i = 0; i < totalFrames; i++) {
        spriteSwf.displayFrame = i;
        
        int width = spriteSwf.swf->getFrameWidth();
        int height = spriteSwf.swf->getFrameHeight();
        
        CCSpriteFrame * spriteFrame = [[CCSpriteFrame alloc] initWithTexture:[spriteSwf renderToTexture]
                                                                        rect:CGRectMake(0, 0, width, height)];
        [spriteFrames_ setObject:spriteFrame
                          forKey:[NSString stringWithFormat:@"%@_%d.png", filenameMinusExtension, (i+1)]];
        [spriteFrame release];
    }
}

@end
