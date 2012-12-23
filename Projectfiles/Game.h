//
//  Game.h
//  WordWind
//
//  Created by Eric Conner on 11/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "kobold2d.h"
#import "GCTurnBasedMatchHelper.h"

@interface Game : CCLayerColor
{
    CCSprite *selSprite;
    NSMutableArray *movableSprites;
}

+(id) scene;
-(void) findStringsDFS:(CCSprite *)sprite1 forComponents:(NSNumber *)components
              forMarks:(NSMutableDictionary *)marks;

@end
