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
//#include <vg/vgext.h>

unsigned long ccNextPOT(unsigned long x)
{
    x = x - 1;
    x = x | (x >> 1);
    x = x | (x >> 2);
    x = x | (x >> 4);
    x = x | (x >> 8);
    x = x | (x >>16);
    return x + 1;
}

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
        vgCreateContextSH(480, 320);
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
    return [CCSprite spriteWithTexture:[self convertToTexture]];
}

-(CCTexture2D*) convertToTexture {
    int w = swf_->getFrameWidth();
    int h = swf_->getFrameHeight();
    
    w *= CC_CONTENT_SCALE_FACTOR();
    h *= CC_CONTENT_SCALE_FACTOR();
    
    // screen fbo
	GLint				oldFBO_;
    
    // new fbo
    GLuint			fbo_;
	GLuint colorbuffer_;
    
    // multisampling buffers
	GLuint msaaFramebuffer_;
	GLuint msaaColorbuffer_;
    
    
    GLenum				pixelFormat_;
	CCTexture2D*		texture_;
    
    glGetIntegerv(CC_GL_FRAMEBUFFER_BINDING, &oldFBO_);
    
    NSUInteger powW = ccNextPOT(w);
    NSUInteger powH = ccNextPOT(h);
    
	GLuint						name_; // texture name
    
    glGenTextures(1, &name_);
    glBindTexture(GL_TEXTURE_2D, name_);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei) powW, (GLsizei) powH, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0);//data);
    
    // create texture
    texture_ = [[CCTexture2D alloc] initWithTextureName:name_ pixelFormat:kCCTexture2DPixelFormat_RGBA8888
                                             pixelsWide:powW pixelsHigh:powH contentSize:CGSizeMake(w, h)];
    
    [texture_ setAliasTexParameters];
    
    // generate FBO
    ccglGenFramebuffers(1, &fbo_);
    ccglBindFramebuffer(CC_GL_FRAMEBUFFER, fbo_);
    
    // associate texture with FBO
    ccglFramebufferTexture2D(CC_GL_FRAMEBUFFER, CC_GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, name_, 0);
    
    GLuint status = ccglCheckFramebufferStatus(CC_GL_FRAMEBUFFER);
    if (status != CC_GL_FRAMEBUFFER_COMPLETE)
    {
        [NSException raise:@"Render Texture" format:@"Could not attach texture to framebuffer"];
    }
    
    /* Create the MSAA framebuffer (offscreen) */
    glGenFramebuffersOES(1, &msaaFramebuffer_);
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, msaaFramebuffer_);
    
    glGenRenderbuffersOES(1, &msaaColorbuffer_); // render buffer for color
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, msaaColorbuffer_);
    glRenderbufferStorageMultisampleAPPLE(GL_RENDERBUFFER_OES, 4, GL_RGBA8_OES, powW, powH);
    glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, msaaColorbuffer_);
    
    status = glCheckFramebufferStatus(GL_FRAMEBUFFER) ;
    if(status != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"failed to make complete framebuffer object %x", status);
    }
    
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, msaaFramebuffer_);
    //*/
    // draw the swf
    
    glPushMatrix();
    
    if (swfSprite_) {
        swfSprite_->draw(frame_);
    } else {
        swf_->drawFrame(frame_);
    }
    glPopMatrix();
    
    ccglBindFramebuffer(CC_GL_FRAMEBUFFER, fbo_);
    glBindFramebufferOES( GL_READ_FRAMEBUFFER_APPLE, msaaFramebuffer_ );
    glResolveMultisampleFramebufferAPPLE();
    
    GLenum attachments[] = {GL_DEPTH_ATTACHMENT_OES, GL_COLOR_ATTACHMENT0_OES, GL_STENCIL_ATTACHMENT_OES};
    glDiscardFramebufferEXT(GL_READ_FRAMEBUFFER_APPLE, 3, attachments);
    
	ccglBindFramebuffer(CC_GL_FRAMEBUFFER, oldFBO_);
    
    ccglDeleteFramebuffers(1, &fbo_);
    ccglDeleteFramebuffers(1, &msaaFramebuffer_);
    glDeleteRenderbuffersOES(1, &msaaColorbuffer_);
    
    return texture_;
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
    
    float sfx, sfy;
    if (flipX_) { sfx = -1.0f; } else { sfx = 1.0f; }
    if (flipY_) { sfy = 1.0f; } else { sfy = -1.0f; }
    
    vgTranslate(self.swf->getFrameWidth() * self.anchorPoint.x * -1.0f,
                self.swf->getFrameHeight() * self.anchorPoint.y * -1.0f);
    vgScale(self.scaleX * CC_CONTENT_SCALE_FACTOR() * sfx, self.scaleY * CC_CONTENT_SCALE_FACTOR() * sfy);
    vgRotate(self.rotation * -1.0f);
    vgTranslate(self.positionInPixels.x, self.positionInPixels.y);
    
    if (swfSprite_) {
        swfSprite_->draw(frame_);
    } else {
        swf_->drawFrame(frame_);
    }
    
    glPopMatrix();
    
    glBlendFunc(CC_BLEND_SRC, CC_BLEND_DST);
    
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


#pragma mark CCTexture2D - withName

@implementation CCTexture2D (withName)

-(id) initWithTextureName:(GLuint)textureName pixelFormat:(CCTexture2DPixelFormat)pixelFormat pixelsWide:(NSUInteger)width pixelsHigh:(NSUInteger)height contentSize:(CGSize)size {
    if ((self = [super init]) ) {
        name_ = textureName;
        
        size_ = size;
        width_ = width;
        height_ = height;
        maxS_ = size.width / (float)width;
        maxT_ = size.height / (float)height;
        
        hasPremultipliedAlpha_ = YES;
        
        resolutionType_ = kCCResolutionUnknown;
    }
    return self;
}


@end
