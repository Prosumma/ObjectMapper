//
//  PROObjectMapperDeserializationTests.m
//  ObjectMapper
//
//  Created by Gregory Higley on 10/2/14.
//  Copyright (c) 2014 Prosumma LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "PROObjectMapper.h"
#import "PROSomething.h"
#import "PROSomethingElse.h"

@interface PROObjectMapperDeserializationTests : XCTestCase

@end

@implementation PROObjectMapperDeserializationTests {
    NSDictionary *_stateBag;
    PROObjectMapper *_mapper;
    PROSomething *_something;
    NSError *_error;
}

- (void)setUp
{
    [super setUp];
    _stateBag = @{ @"simple" : @"Simple!", @"foo" : @"Overridden!", @"skipped" : @(213), @"somethingElse" : @{ @"watusi" : @"Watusi!" }, @"readonlyNumber" : @(8193) };
    _mapper = [PROObjectMapper mapperWithClass:[PROSomething class]];
    NSError *localError = nil;
    _something = [_mapper deserializeStateBag:_stateBag error:&localError];
    _error = localError;
}

- (void)testThatAnErrorDidNotOccur
{
    if (_error) NSLog(@"%@", _error);
    XCTAssertNil(_error);
}

- (void)testDeserializationOfSimpleProperty
{
    XCTAssertEqualObjects(_something.simple, _stateBag[@"simple"]);
}

- (void)testDeserializationOfOverriddenProperty
{
    XCTAssertEqualObjects(_something.overridden, _stateBag[@"foo"]);
}

- (void)testDeserializationOfSkippedProperty
{
    XCTAssertEqual(_something.skipped, 0);
}

- (void)testDeserializationOfReadOnlyProperty
{
    // A read-only property cannot be deserialized because it is not writeable.
    // The only way to do so is with an override.
    XCTAssertNotEqualObjects(@(_something.readonlyNumber), _stateBag[@"readonlyNumber"]);
}

- (void)testDeserializationOfNestedMappableProperty
{
    XCTAssertEqualObjects(_something.somethingElse.watusi, _stateBag[@"somethingElse"][@"watusi"]);
}

@end
