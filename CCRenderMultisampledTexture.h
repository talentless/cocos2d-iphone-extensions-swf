//
//  CCMultiSampleRenderTexture.h
//  CCSpriteFrameCache_SWF_Extension
//
//  Created by Salvatore Gionfriddo on 12/6/11.
//  Copyright (c) 2011 Taco Graveyard. All rights reserved.
//

#import "cocos2d.h"

@interface CCRenderMultisampledTexture : CCRenderTexture
{
    GLuint msaaFramebuffer_;
	GLuint msaaColorbuffer_;
}

@end
