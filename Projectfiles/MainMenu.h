//
//  MainMenu.h
//  WordWind
//
//  The MainMenu interface is a CCLayer that implements a 
//  GCTurnBasedMatchHelperDelegate interface, allowing integration
//  with Apple's Game Center for creating and playing turn based
//  social games.
//
//  Created by Eric Conner on 11/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "kobold2d.h"
#import "GCTurnBasedMatchHelper.h"

@interface MainMenu : CCLayerColor <GCTurnBasedMatchHelperDelegate>
{
}

@end
