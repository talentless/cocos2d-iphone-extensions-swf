//
//  TGSWFAssetManager.m
//  MySampleApp
//
//  Created by Salvatore Gionfriddo on 12/6/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TGSWFAssetManager.h"
#import "cocos2d.h"
#import "CCSpriteSWF.h"
#import "CCRenderMultisampledTexture.h"

@implementation TGSWFAssetManager

#pragma mark Singleton Stuff

static TGSWFAssetManager *sharedAssetManager = nil;

+ (TGSWFAssetManager*)sharedAssetManager {
	@synchronized(self) {
		if(sharedAssetManager == nil) {
			[[self alloc] init];
		}
	}
	return sharedAssetManager;
}

+ (id)allocWithZone:(NSZone *)zone {
    @synchronized(self) {
        if (sharedAssetManager == nil) {
            sharedAssetManager = [super allocWithZone:zone];
            
            return sharedAssetManager;  // assignment and return on first allocation
        }
    }
    return nil; //on subsequent allocation attempts return nil
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (id)retain {
    return self;
}

- (unsigned)retainCount {
    return UINT_MAX;  //denotes an object that cannot be released
} 

- (void)release {
    //do nothing
}

- (id)autorelease {
    return self;
}

#pragma mark Asset Management

/*
 Reads a plist to determine what swfs should be converted to pngs and saved
 
 Warning: This should be called when loading a scene not during gameplay.
 
 Format Example:
 
 {"tacotoss.swf": [
    {"formatString": "taco_dealer_%02d.png", // format string is passed the frame index plus the offset
     "formatIndexOffset": 1, // the offset added to the frame index for formatting
     "frameRangeStart": 0, // the starting frame
     "frameRangeEnd": 2, // the ending frame
    },
    {"formatString": "taco.png",
     "formatIndexOffset": 0,
     "frameRangeStart": 3,
     "frameRangeEnd": 3,
    },
 ]}
 
 Yields:
 
    taco_dealer_01.png
    taco_dealer_02.png
    taco_dealer_03.png
    taco.png
 
 Other Params:
 
 width: defaults to 550
 height: defaults to 400
 offsetX
 offsetY
 frameArray
 spritesheetName
 dithering
 pixel format
 
 */
-(void) loadFromPlist:(NSString*)filename {
    // load plist
    NSString *path = [CCFileUtils fullPathFromRelativePath:filename];
    NSDictionary * swfs = [NSDictionary dictionaryWithContentsOfFile:path];
    
    // for each asset
    for (NSString * swfName in swfs) {
        NSArray * swfDefs = [swfs objectForKey:swfName];
        
        CCSpriteSWF * swfSprite = nil;
        
        for (NSDictionary * swfDef in swfDefs) {
            // load config values
            NSString * formatString = [swfDef objectForKey:@"formatString"];
            int frameRangeStart = [[swfDef valueForKey:@"frameRangeStart"] intValue];
            int frameRangeEnd = [[swfDef valueForKey:@"frameRangeEnd"] intValue];
            int formatIndexOffset = [[swfDef valueForKey:@"formatIndexOffset"] intValue];
            int width = 550;
            int height = 400;
            if ([swfDef valueForKey:@"width"]) { width = [[swfDef valueForKey:@"width"] intValue]; }
            if ([swfDef valueForKey:@"height"]) { height = [[swfDef valueForKey:@"height"] intValue]; }
            
            for (int i = frameRangeStart; i <= frameRangeEnd; i++) {
                // generate png name
                NSString * pngName = [NSString stringWithFormat:formatString, i+formatIndexOffset];
                // generate other path stuff
                NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                NSString *documentsDirectory = [paths objectAtIndex:0];
                NSString  *pngPath = [documentsDirectory stringByAppendingPathComponent:pngName];
                // check frame cache for png
                if ([[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:pngName]) {
                    NSLog(@"Found %@ in frame cache.", pngName);
                    continue;
                }
                // check disk for png
                if ([[CCTextureCache sharedTextureCache] addImage:pngName]) {
                    NSLog(@"Loading %@ from disk or texture cache.", pngName);
                    CCTexture2D * texture = [[CCTextureCache sharedTextureCache] textureForKey:pngName];
                    CCSpriteFrame * frame = [CCSpriteFrame frameWithTexture:texture rect:CGRectMake(0, 0, width, height)];
                    [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFrame:frame name:pngName];
                    continue;
                }
                NSLog(@"Generating %@ for the first time.", pngName);
                // if swf has not been loaded yet, then load it
                if (!swfSprite) { swfSprite = [CCSpriteSWF spriteWithFile:swfName]; }
                // generate image
                CCRenderMultisampledTexture * rmst = [CCRenderMultisampledTexture
                                                    renderTextureWithWidth:(swfSprite.swf->getFrameWidth())
                                                    height:(swfSprite.swf->getFrameHeight())];
                
                [rmst begin];
                swfSprite.swf->drawFrame(i);
                [rmst end];
                
                // save to disk
                CCRenderTexture * rt = [CCRenderTexture renderTextureWithWidth:width
                                                                        height:height];
                [rt begin];
                CGSize texSize = [rmst.sprite.texture contentSizeInPixels];
                
                // Adjust the orthographic propjection and viewport (effectively setting the projection to 2d)
                glViewport(0, 0, texSize.width, texSize.height);
                glMatrixMode(GL_PROJECTION);
                glLoadIdentity();
                ccglOrtho(0,  texSize.width, 0, texSize.height, -1024 * CC_CONTENT_SCALE_FACTOR(),1024 * CC_CONTENT_SCALE_FACTOR());
                glMatrixMode(GL_MODELVIEW);
                glLoadIdentity();
                
                CCSprite * s = [CCSprite spriteWithTexture:rmst.sprite.texture];
                s.position = ccp(swfSprite.swf->getFrameWidth() / 2, swfSprite.swf->getFrameHeight() / 2);
                [s visit];
                [rt end];
                
                [rt saveBuffer:pngName format:kCCImageFormatPNG];
                
                // load into spriteFrameCache
                CCTexture2D * texture = rmst.sprite.texture;
                CCSpriteFrame * frame = [CCSpriteFrame frameWithTexture:texture rect:CGRectMake(0, 0,
                                                                                                width,
                                                                                                height)];
                [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFrame:frame name:pngName];
                
            }
        }
    }
}

@end
