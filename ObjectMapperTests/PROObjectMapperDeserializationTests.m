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
}

- (void)setUp
{
    [super setUp];
    _stateBag = @{ @"simple" : @"Simple!", @"foo" : @"Overridden!", @"skipped" : @(213), @"somethingElse" : @{ @"watusi" : @"Watusi!" } };
    _mapper = [PROObjectMapper mapperWithClass:[PROSomething class]];
    _something = [_mapper deserializeStateBag:_stateBag error:NULL];
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

- (void)testDeserializationOfNestedMappableProperty
{
    XCTAssertEqualObjects(_something.somethingElse.watusi, _stateBag[@"somethingElse"][@"watusi"]);
}

@end
