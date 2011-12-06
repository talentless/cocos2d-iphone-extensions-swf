//
//  CCMultiSampleRenderTexture.m
//  CCSpriteFrameCache_SWF_Extension
//
//  Created by Salvatore Gionfriddo on 12/6/11.
//  Copyright (c) 2011 Taco Graveyard. All rights reserved.
//

#import "CCRenderMultisampledTexture.h"

@implementation CCRenderMultisampledTexture

-(id)initWithWidth:(int)w height:(int)h pixelFormat:(CCTexture2DPixelFormat) format
{
	if ((self = [super initWithWidth:w height:h pixelFormat:format]))
	{
		NSUInteger powW = texture_.pixelsWide;
		NSUInteger powH = texture_.pixelsHigh;
        
        /* Create the MSAA framebuffer (offscreen) */
        glGenFramebuffersOES(1, &msaaFramebuffer_);
        glBindFramebufferOES(GL_FRAMEBUFFER_OES, msaaFramebuffer_);
        
        glGenRenderbuffersOES(1, &msaaColorbuffer_); // render buffer for color
        glBindRenderbufferOES(GL_RENDERBUFFER_OES, msaaColorbuffer_);
        glRenderbufferStorageMultisampleAPPLE(GL_RENDERBUFFER_OES, 4, GL_RGBA8_OES, powW, powH);
        glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, msaaColorbuffer_);
        
        GLuint status = glCheckFramebufferStatus(GL_FRAMEBUFFER) ;
        if(status != GL_FRAMEBUFFER_COMPLETE) {
            NSLog(@"failed to make complete framebuffer object %x", status);
        }
        
		ccglBindFramebuffer(CC_GL_FRAMEBUFFER, oldFBO_);
	}
	return self;
}

-(void) begin {
    glPushMatrix();
	
	CGSize texSize = [texture_ contentSizeInPixels];
	
	// Adjust the orthographic propjection and viewport (effectively setting the projection to 2d)
	glViewport(0, 0, texSize.width, texSize.height);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    ccglOrtho(0,  texSize.width, 0, texSize.height, -1024 * CC_CONTENT_SCALE_FACTOR(),1024 * CC_CONTENT_SCALE_FACTOR());
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
	
	
	glGetIntegerv(CC_GL_FRAMEBUFFER_BINDING, &oldFBO_);
	ccglBindFramebuffer(CC_GL_FRAMEBUFFER, fbo_);//Will direct drawing to the frame buffer created above
	
	// Issue #1145
	// There is no need to enable the default GL states here
	// but since CCRenderTexture is mostly used outside the "render" loop
	// these states needs to be enabled.
	// Since this bug was discovered in API-freeze (very close of 1.0 release)
	// This bug won't be fixed to prevent incompatibilities with code.
	// 
	// If you understand the above mentioned message, then you can comment the following line
	// and enable the gl states manually, in case you need them.
	CC_ENABLE_DEFAULT_GL_STATES();
    
    // attach to multisampling frame buffer
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, msaaFramebuffer_);
}

-(void) end {
    // resolve multisampling frame buffer
    ccglBindFramebuffer(CC_GL_FRAMEBUFFER, fbo_);
    glBindFramebufferOES( GL_READ_FRAMEBUFFER_APPLE, msaaFramebuffer_ );
    glResolveMultisampleFramebufferAPPLE();
    
    [super end];
}

-(void)dealloc
{
    GLenum attachments[] = {GL_DEPTH_ATTACHMENT_OES, GL_COLOR_ATTACHMENT0_OES, GL_STENCIL_ATTACHMENT_OES};
    glDiscardFramebufferEXT(GL_READ_FRAMEBUFFER_APPLE, 3, attachments);
    
	ccglDeleteFramebuffers(1, &msaaFramebuffer_);
    glDeleteRenderbuffersOES(1, &msaaColorbuffer_);
	[super dealloc];
}

@end
