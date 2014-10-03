//
//  PROSomething.m
//  ObjectMapper
//
//  Created by Gregory Higley on 10/2/14.
//  Copyright (c) 2014 Prosumma LLC. All rights reserved.
//

#import "PROSomething.h"
#import "PROObjectMapper.h"
#import "PROSomethingElse.h"

@implementation PROSomething

+ (PROMapBlock)mapBlockForSerializationOfOverridden
{
    return ^BOOL(id target, NSString *key, PROSomething *source, NSError **error) {
        // We're going to ignore the value of key, and write "overridden" in as "foo".
        [target setValue:source.overridden forKey:@"foo"];
        return YES;
    };
}

+ (PROMapBlock)mapBlockForDeserializationOfOverridden
{
    return ^BOOL(PROSomething *target, NSString *key, id source, NSError **error) {
        // When we serialize, we use "foo" instead of "overridden", so we'll reverse that process.
        target.overridden = [source valueForKey:@"foo"];
        return YES;
    };
}

+ (PROMapBlock)mapBlockForSerializationOfSkipped
{
    // Skip it.
    return nil;
}

+ (PROMapBlock)mapBlockForDeserializationOfSkipped
{
    // Skip it.
    return nil;
}

@end
