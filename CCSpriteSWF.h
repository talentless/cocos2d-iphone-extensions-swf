//
//  CCSpriteSWF.h
//  MySampleApp
//
//  Created by Salvatore Gionfriddo on 11/29/11.
//  Copyright (c) 2011 Taco Graveyard. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "cocos2d.h"
#import "MonkSWF.h"

@interface CCSpriteSWF : CCNode {
    MonkSWF::SWF *swf_;
    int frame_;
    int spriteIdx_;
    MonkSWF::IDefineSpriteTag*  swfSprite_;
    
    // image is flipped
	BOOL	flipX_;
	BOOL	flipY_;
}

@property BOOL flipX;
@property BOOL flipY;

@property (readonly) MonkSWF::SWF *swf;

-(int) displayFrame;
-(void) setDisplayFrame:(int)frameIndex;

/*
 Allows you to display a specific sprite within the swf rather than the entire movie.
 Defaults to -1, which shows the full movie.
 */
-(void) setDisplaySprite:(int)spriteIndex;
-(void) displayFullMovie;
-(int) displaySprite;

#pragma mark CCSpriteSWF - inits, etc

+(id) spriteWithFile:(NSString*)filename;
+(id) spriteWithSWF:(MonkSWF::SWF*)swf;

+(id) spriteWithFile:(NSString*)filename spriteIndex:(int)spriteIndex;
+(id) spriteWithSWF:(MonkSWF::SWF*)swf spriteIndex:(int)spriteIndex;

-(id) init;

-(id) initWithFile:(NSString*)filename;
-(id) initWithSWF:(MonkSWF::SWF*)swf;

-(id) initWithFile:(NSString*)filename spriteIndex:(int)spriteIndex;
-(id) initWithSWF:(MonkSWF::SWF*)swf spriteIndex:(int)spriteIndex;

#pragma mark CCSpriteSWF - conversions

-(CCSprite*) convertToSprite;
-(CCTexture2D*) renderToTexture;

@end

@interface CCTexture2D (withName)

-(id) initWithTextureName:(GLuint)textureName pixelFormat:(CCTexture2DPixelFormat)pixelFormat pixelsWide:(NSUInteger)width pixelsHigh:(NSUInteger)height contentSize:(CGSize)size;

@end
