//
//  CCSpriteSWF.m
//  MySampleApp
//
//  Created by Salvatore Gionfriddo on 11/29/11.
//  Copyright (c) 2011 Taco Graveyard. All rights reserved.
//

#include <vg/openvg.h>
#include <vg/vgu.h>
#import "CCSpriteSWF.h"

@implementation CCSpriteSWF

#pragma mark CCSpriteSWF - properties

@synthesize flipX = flipX_;
@synthesize flipY = flipY_;

@synthesize swf = swf_;

-(int) displayFrame {
    return frame_;
}

-(void) setDisplayFrame:(int)frameIndex {
    NSAssert(frameIndex < swf_->numFrames(), @"Argument outside valid index range.");
    NSAssert(frameIndex >= 0, @"Argument outside valid index range.");
    
    frame_ = frameIndex;
}

-(void) setDisplaySprite:(int)spriteIndex {
    NSAssert(spriteIndex < swf_->numSprites(), @"Argument outside valid index range.");
    NSAssert(spriteIndex >= 0, @"Argument outside valid index range. Use displayFullMovie to reset.");
    
    spriteIdx_ = spriteIndex;
    swfSprite_ = swf_->spriteAt( spriteIdx_ );
}

-(void) displayFullMovie {
    spriteIdx_ = -1;
    swfSprite_ = nil;
}

-(int) displaySprite {
    return spriteIdx_;
}

#pragma mark CCSpriteSWF - inits, etc

+(id) spriteWithFile:(NSString*)filename {
    return [[[super alloc] initWithFile:filename] autorelease];
}
+(id) spriteWithSWF:(MonkSWF::SWF*)swf {
    return [[[super alloc] initWithSWF:swf] autorelease];
}

+(id) spriteWithFile:(NSString*)filename spriteIndex:(int)spriteIndex {
    return [[[super alloc] initWithFile:filename spriteIndex:spriteIndex] autorelease];
}

+(id) spriteWithSWF:(MonkSWF::SWF*)swf spriteIndex:(int)spriteIndex {
    return [[super alloc] initWithSWF:swf spriteIndex:spriteIndex];
}

-(id) init {
    if ( (self=[super init]) ) {
        frame_ = 0; // default
        spriteIdx_ = -1; // show the movie rather than a specific sprite
        swfSprite_ = nil;
    }
    return self;
}

-(id) initWithFile:(NSString*)filename {
    if ( (self = [self init]) ) {
        [self setAnchorPoint:ccp(0.5, 0.5)];
        
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
        swf_ = new MonkSWF::SWF();
        swf_->initialize();
        swf_->read(&reader);
        
        // clean up the buffer
        delete [] buffer;
    }
    
    return self;
}

-(id) initWithSWF:(MonkSWF::SWF*)swf {
    if ( (self = [self init]) ) {
        swf_ = swf;
    }
    
    return self;
}

-(id) initWithFile:(NSString *)filename spriteIndex:(int)spriteIndex {
    if ( (self = [self initWithFile:filename]) ) {
        [self setDisplaySprite:spriteIndex];
    }
    
    return self;
}

-(id) initWithSWF:(MonkSWF::SWF *)swf spriteIndex:(int)spriteIndex {
    if ( (self = [self initWithSWF:swf]) ) {
        [self setDisplaySprite:spriteIndex];
    }
    return self;
}

#pragma mark CCSpriteSWF - conversions

-(CCSprite*) convertToSprite {
    int width = swf_->getFrameWidth();
    int height = swf_->getFrameHeight();
    
    CCRenderTexture * rt = [CCRenderTexture renderTextureWithWidth:width height:height];
    // clear the texture
    [rt begin];
    
    // draw the swf
    CCDirector *director;
    director = [CCDirector sharedDirector];
    
    ccDirectorProjection projection;
    projection = director.projection;
    [director setProjection:kCCDirectorProjection2D];
    
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glEnableClientState(GL_VERTEX_ARRAY);
    
    vgLoadIdentity();
    vgScale(CC_CONTENT_SCALE_FACTOR() * 1.0f,
            CC_CONTENT_SCALE_FACTOR() * 1.0f);
    if (swfSprite_) {
        swfSprite_->draw(frame_);
    } else {
        swf_->drawFrame(frame_);
    }
    
    [director setProjection:projection];
    
    // close out
    [rt end];
    
    return rt.sprite;
}

-(CCTexture2D*) convertToTexture {
    return [[self convertToSprite] texture];
}

#pragma mark CCSpriteSWF - draw

-(void) draw {
    [super draw];
    
    CCDirector *director;
    director = [CCDirector sharedDirector];
    
    ccDirectorProjection projection;
    projection = director.projection;
    [director setProjection:kCCDirectorProjection2D];
    
    glDisable(GL_TEXTURE_2D);
    glDisableClientState(GL_COLOR_ARRAY);
    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
    
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glEnableClientState(GL_VERTEX_ARRAY);
    
    glPushMatrix();
    
    vgLoadIdentity();
    
    float sx, sy;
    if (flipX_) { sx = -1.0f; } else { sx = 1.0f; }
    if (flipY_) { sy = 1.0f; } else { sy = -1.0f; }
    
    vgTranslate(self.swf->getFrameWidth() * self.anchorPoint.x * -1.0f,
                self.swf->getFrameHeight() * self.anchorPoint.y * -1.0f);
    vgScale(self.scaleX * CC_CONTENT_SCALE_FACTOR() * sx, self.scaleY * CC_CONTENT_SCALE_FACTOR() * sy);
    vgRotate(self.rotation * -1.0f);
    vgTranslate(self.positionInPixels.x, self.positionInPixels.y);
    
    if (swfSprite_) {
        swfSprite_->draw(frame_);
    } else {
        swf_->drawFrame(frame_);
    }
    
    glPopMatrix();
    
    glEnable(GL_TEXTURE_2D);
    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_COLOR_ARRAY);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    
    [director setProjection:projection];
}

#pragma mark CCSpriteSWF - dealloc

-(void) dealloc {
    delete swf_;
    [super dealloc];
}

@end
