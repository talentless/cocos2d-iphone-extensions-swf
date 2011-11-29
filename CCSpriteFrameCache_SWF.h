//
//  CCSpriteFrameCache_SWF.h
//  CCSpriteFrameCache_SWF_Extension
//
//  Created by Salvatore Gionfriddo on 11/28/11.
//  Copyright (c) 2011 Taco Graveyard. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@interface CCSpriteFrameCache (SWF)

-(void) addSpriteFramesWithSWF:(NSString*)filename;
-(void) addSpriteFramesWithSWF:(NSString*)filename pixelFormat:(CCTexture2DPixelFormat)format;

@end
