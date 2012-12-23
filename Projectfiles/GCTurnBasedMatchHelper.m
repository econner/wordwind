//
//  GCTurnBasedMatchHelper.m
//  WordWind
//
//  This class provides convenience methods for communicating
//  with the Apple Game Center, making it easy to setup social
//  games and turn-based games.
//
//  Created by Eric Conner on 12/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GCTurnBasedMatchHelper.h"

@implementation GCTurnBasedMatchHelper
@synthesize gameCenterAvailable;
@synthesize currentMatch;
@synthesize delegate;

#pragma mark Initialization

/*
 * Singleton accessor.
 */
static GCTurnBasedMatchHelper *sharedHelper = nil;

+ (GCTurnBasedMatchHelper *) sharedInstance {
    if (!sharedHelper) {
        sharedHelper = [[GCTurnBasedMatchHelper alloc] init];
    }
    return sharedHelper;
}

/*
 * Test if the user's hardware can run gamecenter.
 */
- (BOOL)isGameCenterAvailable {
    // check for presence of GKLocalPlayer API
    Class gcClass = (NSClassFromString(@"GKLocalPlayer"));
    
    // check if the device is running iOS 4.1 or later
    NSString *reqSysVer = @"4.1";
    NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
    BOOL osVersionSupported = ([currSysVer compare:reqSysVer     
                                           options:NSNumericSearch] != NSOrderedAscending);
    
    return (gcClass && osVersionSupported);
}

/*
 * Setup this class and subscribe to Game Center notifs.
 */
- (id)init {
    if ((self = [super init])) {
        gameCenterAvailable = [self isGameCenterAvailable];
        if (gameCenterAvailable) {
            NSNotificationCenter *nc = 
            [NSNotificationCenter defaultCenter];
            [nc addObserver:self 
                   selector:@selector(authenticationChanged) 
                       name:GKPlayerAuthenticationDidChangeNotificationName 
                     object:nil];
        }
    }
    return self;
}

/*
 * Handler called when a user either authorizes or deauthorizes GameCenter
 * for our game.
 */
- (void)authenticationChanged {    
    
    if ([GKLocalPlayer localPlayer].isAuthenticated && 
        !userAuthenticated) {
        NSLog(@"Authentication changed: player authenticated.");
        userAuthenticated = TRUE;           
    } else if (![GKLocalPlayer localPlayer].isAuthenticated && 
               userAuthenticated) {
        NSLog(@"Authentication changed: player not authenticated");
        userAuthenticated = FALSE;
    }
    
}

#pragma mark User functions

- (void)authenticateLocalUser { 
    
    if (!gameCenterAvailable) return;
    
    NSLog(@"Authenticating local user...");
    if ([GKLocalPlayer localPlayer].authenticated == NO) {     
        [[GKLocalPlayer localPlayer] 
         authenticateWithCompletionHandler:nil];        
    } else {
        NSLog(@"Already authenticated!");
    }
}

- (void)findMatchWithMinPlayers:(int)minPlayers 
                     maxPlayers:(int)maxPlayers {
    if (!gameCenterAvailable) return;               
    
    GKMatchRequest *request = [[GKMatchRequest alloc] init]; 
    request.minPlayers = minPlayers;     
    request.maxPlayers = maxPlayers;
    
    GKTurnBasedMatchmakerViewController *mmvc = 
    [[GKTurnBasedMatchmakerViewController alloc] 
     initWithMatchRequest:request];    
    mmvc.turnBasedMatchmakerDelegate = self;
    mmvc.showExistingMatches = YES;
    
    presentingViewController = [[UIViewController alloc] init];
    [[[CCDirector sharedDirector] openGLView] addSubview:presentingViewController.view];
    [presentingViewController presentModalViewController:mmvc animated:YES];
}

#pragma mark GKTurnBasedMatchmakerViewControllerDelegate

-(void)turnBasedMatchmakerViewController:
(GKTurnBasedMatchmakerViewController *)viewController 
                            didFindMatch:(GKTurnBasedMatch *)match {
    [presentingViewController 
     dismissModalViewControllerAnimated:YES];
    self.currentMatch = match;
    GKTurnBasedParticipant *firstParticipant = 
    [match.participants objectAtIndex:0];
    if (firstParticipant.lastTurnDate) {
        NSLog(@"Going to take turn.");
        [delegate takeTurn:match];
    } else {
        NSLog(@"Entering new game.");
        [delegate enterNewGame:match];
        NSLog(@"Entered game.");
    }
}

-(void)turnBasedMatchmakerViewControllerWasCancelled: 
(GKTurnBasedMatchmakerViewController *)viewController {
    [presentingViewController 
     dismissModalViewControllerAnimated:YES];
    NSLog(@"has cancelled");
}

-(void)turnBasedMatchmakerViewController: 
(GKTurnBasedMatchmakerViewController *)viewController 
                        didFailWithError:(NSError *)error {
    [presentingViewController 
     dismissModalViewControllerAnimated:YES];
    NSLog(@"Error finding match: %@", error.localizedDescription);
}

-(void)turnBasedMatchmakerViewController: 
(GKTurnBasedMatchmakerViewController *)viewController 
                      playerQuitForMatch:(GKTurnBasedMatch *)match {
    NSLog(@"playerquitforMatch, %@, %@", 
          match, match.currentParticipant);
}

@end
