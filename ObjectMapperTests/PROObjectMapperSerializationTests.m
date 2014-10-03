//
//  PROObjectMapperSerializationTests.m
//  ObjectMapper
//
//  Created by Gregory Higley on 10/3/14.
//  Copyright (c) 2014 Prosumma LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "PROObjectMapper.h"
#import "PROSomething.h"
#import "PROSomethingElse.h"

@interface PROObjectMapperSerializationTests : XCTestCase

@end

@implementation PROObjectMapperSerializationTests {
    PROObjectMapper *_mapper;
    PROSomething *_something;
    NSDictionary *_stateBag;
    NSError *_error;
}

- (void)setUp
{
    [super setUp];
    _mapper = [PROObjectMapper mapperWithClass:[PROSomething class]];
    _something = [PROSomething new];
    _something.overridden = @"Overridden!";
    _something.simple = @"Simple!";
    _something.skipped = 299;
    PROSomethingElse *_somethingElse = [PROSomethingElse new];
    _somethingElse.watusi = @"Watusi!";
    _something.somethingElse = _somethingElse;
    NSError *localError = nil;
    _stateBag = [_mapper serializeObject:_something error:&localError];
    _error = localError;
}

- (void)testThatAnErrorDidNotOccur
{
    if (_error) NSLog(@"%@", _error);
    XCTAssertNil(_error);
}

- (void)testSerializationOfSimpleProperty
{
    XCTAssertEqualObjects(_stateBag[@"simple"], _something.simple);
}

- (void)testSerializationOfOverriddenProperty
{
    XCTAssertEqualObjects(_stateBag[@"foo"], _something.overridden);
}

- (void)testSerializationOfReadOnlyProperty
{
    // A read-only property CAN be serialized. If you want to skip it,
    // e.g., because it's calculated, use an override.
    XCTAssertEqualObjects(_stateBag[@"readonlyNumber"], @(_something.readonlyNumber));
}

- (void)testSerializationOfSkippedProperty
{
    XCTAssertFalse(_stateBag[@"skipped"]);
}

- (void)testSerializationOfNestedMappableProperty
{
    XCTAssertTrue(_stateBag[@"somethingElse"]);
    XCTAssertEqualObjects(_stateBag[@"somethingElse"][@"watusi"], _something.somethingElse.watusi);
}

@end
