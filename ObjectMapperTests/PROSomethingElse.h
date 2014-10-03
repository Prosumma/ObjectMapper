//
//  PROSomethingElse.h
//  ObjectMapper
//
//  Created by Gregory Higley on 10/3/14.
//  Copyright (c) 2014 Prosumma LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PROObjectMapper.h"

@interface PROSomethingElse : NSObject <PROMappableObject>
@property (nonatomic, readwrite, copy) NSString *watusi;
@end
