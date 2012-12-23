//
//  Game.m
//  WordWind
//
//  Created by Eric Conner on 11/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Game.h"
#import <UIKit/UITextChecker.h>
#import "Lexicontext.h"

@implementation Game

CCLayer *scoreLayer;
CCLayer *spriteLayer;
NSMutableArray *curComponents;

+(id) scene
{
    CCScene *scene = [CCScene node];
    Game *layer = [Game node];
    [scene addChild: layer];
    return scene;
}

-(id) init
{
    ccColor4B background = ccc4(39,40,34,255);
    if( (self=[super initWithColor:background] )) {
        [self initializeGame];
    }
    return self;
}

-(void) initializeGame
{
    scoreLayer = [[CCLayer alloc] init];
    [self addChild:scoreLayer];
    
    spriteLayer = [[CCLayer alloc] init];
    [[CCTouchDispatcher sharedDispatcher] addTargetedDelegate:self
                                                     priority:0
                                              swallowsTouches:YES];
    [self setupSprites];
    [self addChild:spriteLayer];
    NSLog(@"Setting the delegate here.");
}

-(void) setupSprites
{
    CGSize winSize = [CCDirector sharedDirector].winSize;
    
    movableSprites = [[NSMutableArray alloc] init];
    // TODO: more intelligent letter combinations
    for (char letter = 'A'; letter <= 'D'; letter++) {
        NSString *s = [NSString stringWithFormat:@"%c", letter];
        CCLabelTTF *curLetter = [CCLabelTTF labelWithString:s
                                                 fontName:@"Targa" 
                                                 fontSize:64];
        float offsetFraction = ((float)(letter - 'A' + 1))/(4);
        curLetter.position = ccp(winSize.width*offsetFraction, winSize.height/2);

        [movableSprites addObject:curLetter];
        [spriteLayer addChild:curLetter];

    }
}

-(void) clampPosition:(CGPoint*)pos forSprite:(CCSprite*)sprite {
    CGSize winSize = [CCDirector sharedDirector].winSize;
    int letterWidth = sprite.boundingBox.size.width / 2;
    int letterHeight = sprite.boundingBox.size.height / 2;
    pos->x = clampf(pos->x, letterWidth, winSize.width - letterWidth);
    pos->y = clampf(pos->y, letterHeight, winSize.height - letterHeight);
}


-(void) moveSpriteForTouch:(CGPoint)translation
{
    if (!selSprite) {
        return;
    }
    
    CGPoint newPos = ccpAdd(selSprite.position, translation);
    [self clampPosition:&newPos forSprite:selSprite];
    
    selSprite.position = newPos;
}

-(void) selectSpriteForTouch:(CGPoint)touchLocation {
    CCSprite * newSprite = nil;
    for (CCSprite *sprite in movableSprites) {
        if (CGRectContainsPoint(sprite.boundingBox, touchLocation)) {
            newSprite = sprite;
            break;
        }
    }
    if (newSprite != selSprite) {
        [selSprite stopAllActions];
        [selSprite runAction:[CCRotateTo actionWithDuration:0.1 angle:0]];
        CCRotateTo * rotLeft = [CCRotateBy actionWithDuration:0.1 angle:-4.0];
        CCRotateTo * rotCenter = [CCRotateBy actionWithDuration:0.1 angle:0.0];
        CCRotateTo * rotRight = [CCRotateBy actionWithDuration:0.1 angle:4.0];
        CCSequence * rotSeq = [CCSequence actions:rotLeft, rotCenter, rotRight, rotCenter, nil];
        [newSprite runAction:[CCRepeatForever actionWithAction:rotSeq]];            
        selSprite = newSprite;
    }
}

-(BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event {    
    CGPoint touchLocation = [self convertTouchToNodeSpace:touch];
    [self selectSpriteForTouch:touchLocation]; 
    return TRUE;    
}

-(void) ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event {       
    CGPoint touchLocation = [self convertTouchToNodeSpace:touch];
    
    CGPoint oldTouchLocation = [touch previousLocationInView:touch.view];
    oldTouchLocation = [[CCDirector sharedDirector] convertToGL:oldTouchLocation];
    oldTouchLocation = [self convertToNodeSpace:oldTouchLocation];
    
    CGPoint translation = ccpSub(touchLocation, oldTouchLocation);
    [self moveSpriteForTouch:translation];    
}

-(void) ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event {
    if (!selSprite) {
        return;
    }
    [self findStrings];
    [self resolveCollisions];
    for(NSArray* sortedComponent in curComponents) {
        [self ensureOnBoard:sortedComponent];
    }
    // TODO: test if strings are valid words
}

-(void) findStringsDFS:(CCSprite *)sprite1 forComponents:(NSNumber *)components
         forMarks:(NSMutableDictionary *)marks 
{
    NSNumber *key1 = [NSNumber numberWithUnsignedInt:[sprite1 hash]];
    [marks setObject: components forKey: key1];
    
    for(CCSprite *sprite2 in movableSprites) {
        if(sprite2 == sprite1)
            continue;
        
        CGRect sprite1Box = sprite1.boundingBox;
        // small buffer zone so letters dont have to be touching
        sprite1Box.size.width += 3;
        if (CGRectIntersectsRect(sprite1Box, sprite2.boundingBox)) {
            // need most of overlap in direction of height
            int heightOffset = abs(sprite1.position.y - sprite2.position.y);
            float overlapRatio = (float)heightOffset / sprite1.boundingBox.size.height;
            if(overlapRatio > 0.5) {
                continue;
            }            
            NSNumber *key2 = [NSNumber numberWithUnsignedInt:[sprite2 hash]];
            if([marks objectForKey:key2]) {
                continue;      
            }
            
            [self findStringsDFS:sprite2 forComponents:components forMarks:marks];
        }
    }
}

-(BOOL) collisionsExist {
    for(CCSprite *sprite1 in movableSprites) {
        for(CCSprite *sprite2 in movableSprites) {
            if(sprite1 == sprite2)
                continue;
            if (CGRectIntersectsRect(sprite1.boundingBox, sprite2.boundingBox)) {
                // need most of overlap in direction of height
                double heightOffset = abs(sprite1.position.y - sprite2.position.y);
                double widthOffset = abs(sprite1.position.x - sprite2.position.x);
                float overlapYPercent = 1 - heightOffset / sprite1.boundingBox.size.height;    
                float overlapXPercent = 1 - widthOffset / sprite2.boundingBox.size.width;
                if(overlapXPercent > 0.4 && overlapYPercent > 0.65)
                    return true;
            }
        }
    }
    return false;
}

-(void) resolveCurCollisions {
    for(NSArray* sortedComponent in curComponents) {
        // translate all members to prevent overlaps
        for(int idx = 0; idx < (int)sortedComponent.count - 1; idx++) {
            CCSprite *curSprite = [sortedComponent objectAtIndex:idx];
            CCSprite *nextSprite = [sortedComponent objectAtIndex:(idx+1)];
            double xBound = curSprite.position.x + 0.8 * curSprite.boundingBox.size.width;
            if(nextSprite.position.x < xBound) {
                CGPoint newPos = ccp(xBound, nextSprite.position.y);
                nextSprite.position = newPos;
            }
        }
    }
}

-(void) resolveCollisions {
    while([self collisionsExist]) {
        [self resolveCurCollisions];
        [self findStrings];
    }
}

-(void) ensureOnBoard:(NSArray*)sortedLetters {
    if(sortedLetters.count == 0)
        return;
    
    CCSprite* sprite = [sortedLetters objectAtIndex:0];
    float letterWidth = sprite.boundingBox.size.width / 2;
    if(sprite.position.x < letterWidth) {
        float amountToMove = abs(letterWidth - sprite.position.x);
        for(CCSprite *curSprite in sortedLetters) {
            CGPoint newPos = ccp(curSprite.position.x + amountToMove, curSprite.position.y);
            curSprite.position = newPos;
        }
    }
    
    CGSize winSize = [CCDirector sharedDirector].winSize;
    sprite = [sortedLetters objectAtIndex:sortedLetters.count - 1];
    if(sprite.position.x > winSize.width - letterWidth) {
        float amountToMove = -(sprite.position.x - (winSize.width - letterWidth));
        for(CCSprite *curSprite in sortedLetters) {
            CGPoint newPos = ccp(curSprite.position.x + amountToMove, curSprite.position.y);
            curSprite.position = newPos;
        }
    }
}

-(void) findStrings {
    NSMutableDictionary *marks = [NSMutableDictionary dictionary];
    
    NSNumber *components = [NSNumber numberWithInt:0];
    for (CCSprite *sprite1 in movableSprites) {
        // sprite is already in some component
        NSNumber *key = [NSNumber numberWithUnsignedInt:[sprite1 hash]];
        if([marks objectForKey:key]) {
            continue;      
        }
        
        components = [NSNumber numberWithInt:[components intValue] + 1];
        [self findStringsDFS:sprite1 forComponents:components forMarks:marks];
    }
    
    curComponents = [[NSMutableArray alloc] init];
    for(int idx = 1; idx <= [components intValue]; idx++) {
        NSMutableArray *curComponent = [[NSMutableArray alloc] init];
        for (CCSprite *sprite in movableSprites) {
            NSNumber *key = [NSNumber numberWithUnsignedInt:[sprite hash]];
            NSNumber *value = [marks objectForKey:key];
            if([value intValue] == idx) {
                [curComponent addObject:sprite];
            }
        }
        
        // sort connected letters by x coordinate
        NSArray *sortedComponent;
        sortedComponent = [curComponent sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
            CGFloat first = ((CCSprite*)a).position.x;
            CGFloat second = ((CCSprite*)b).position.x;
            if(first < second) {
                return (NSComparisonResult)NSOrderedAscending;
            }
            if(first > second) {
                return (NSComparisonResult)NSOrderedDescending;
            }
            return (NSComparisonResult)NSOrderedSame;
        }];
        [curComponents addObject:sortedComponent];
        
        NSArray *componentStrs = [sortedComponent valueForKeyPath:@"string"];
        NSString *candidateWord = [componentStrs componentsJoinedByString:@""];
        NSString *lowerCase = [candidateWord lowercaseString];
        
        Lexicontext *dictionary = [Lexicontext sharedDictionary];
        NSString *definition = [dictionary definitionFor:lowerCase];
        NSLog(definition);
    }
}

@end
