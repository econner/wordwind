//
//  MainMenu.m
//  WordWind
//
//  Created by Eric Conner on 11/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MainMenu.h"
#import "Game.h"

CCSprite *ship1;
CCSprite *ship2;


@implementation MainMenu

-(id) init
{
    ccColor4B background = ccc4(39,40,34,255);
	if( (self=[super initWithColor:background] )) {
    
        // Standard method to create a button
        CCMenuItem *newMenuItem = [CCMenuItemImage 
                                    itemFromNormalImage:@"new.png" selectedImage:@"new.png" 
                                    target:self selector:@selector(newGame:)];
        newMenuItem.position = ccp(160, 60);
        CCMenu *mainMenu = [CCMenu menuWithItems:newMenuItem, nil];
        mainMenu.position = CGPointZero;
        [self addChild:mainMenu];
    }
    [GCTurnBasedMatchHelper sharedInstance].delegate = self;
    return self;
}

- (void)newGame:(id)sender {
    [[GCTurnBasedMatchHelper sharedInstance] 
     findMatchWithMinPlayers:2 maxPlayers:12];
}

#pragma mark - GCTurnBasedMatchHelperDelegate

-(void)enterNewGame:(GKTurnBasedMatch *)match {
    NSLog(@"Entering new game...");
    //mainTextController.text = @"Once upon a time";
    [[CCDirector sharedDirector] replaceScene:[CCTransitionZoomFlipX
                                               transitionWithDuration:0.5 
                                               scene:[Game scene]]];
}

-(void)takeTurn:(GKTurnBasedMatch *)match {
    NSLog(@"Taking turn for existing game...");
    if ([match.matchData bytes]) {
        NSString *storySoFar = 
        [NSString stringWithUTF8String:[match.matchData bytes]];
        NSLog(storySoFar);
        //mainTextController.text = storySoFar;
    }
}

- (void)receiveEndGame:(GKTurnBasedMatch *)match {
    NSLog(@"Received end game.");
}
- (void)sendNotice:(NSString *)notice 
          forMatch:(GKTurnBasedMatch *)match {
    NSLog(@"Sent notice.");
}

- (void)sendTurn:(id)sender {
    GKTurnBasedMatch *currentMatch = 
    [[GCTurnBasedMatchHelper sharedInstance] currentMatch];
    NSString *sendString = @"Hello There!";
    NSData *data = [sendString dataUsingEncoding:NSUTF8StringEncoding ];
    
    NSUInteger currentIndex = [currentMatch.participants 
                               indexOfObject:currentMatch.currentParticipant];
    GKTurnBasedParticipant *nextParticipant;
    nextParticipant = [currentMatch.participants objectAtIndex: 
                       ((currentIndex + 1) % [currentMatch.participants count ])];
    [currentMatch endTurnWithNextParticipant:nextParticipant 
                                   matchData:data completionHandler:^(NSError *error) {
                                       if (error) {
                                           NSLog(@"%@", error);
                                       }
                                   }];
    NSLog(@"Send Turn, %@, %@", data, nextParticipant);
}


@end
