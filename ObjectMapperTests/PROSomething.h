//
//  PROSomething.h
//  ObjectMapper
//
//  Created by Gregory Higley on 10/2/14.
//  Copyright (c) 2014 Prosumma LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PROObjectMapper.h"

@class PROSomethingElse;

@interface PROSomething : NSObject <PROMappableObject>
@property (nonatomic, readwrite, copy) NSString *simple;
@property (nonatomic, readwrite, copy) NSString *overridden;
@property (nonatomic, readwrite, assign) NSUInteger skipped;
@property (nonatomic, readwrite, strong) PROSomethingElse *somethingElse;
@end
