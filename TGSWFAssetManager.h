//
//  TGSWFAssetManager.h
//  MySampleApp
//
//  Created by Salvatore Gionfriddo on 12/6/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TGSWFAssetManager : NSObject

+ (TGSWFAssetManager*)sharedAssetManager;

-(void) loadFromPlist:(NSString*)filename;

@end
