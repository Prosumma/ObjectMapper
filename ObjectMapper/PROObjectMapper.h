//
//  PROObjectMapper.h
//  ObjectMapper
//
//  Created by Gregory Higley on 10/2/14.
//  Copyright (c) 2014 Prosumma LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 Implementing this protocol indicates that a class supports
 custom and automatic mapping.
 
 There are no methods to implement. They are all part of an
 informal protocol.
 */
@protocol PROMappableObject <NSObject>

@end

/*!
 Represents the action of assigning a value to the target
 using the specified key.
 */
typedef BOOL (^PROMapBlock)(id target, NSString *key, id source, NSError **error);

/*!
 @abstract Maps between an object and any instance supporting KVC.
 */
@interface PROObjectMapper : NSObject
@property (nonatomic, readonly, assign) Class mappedClass;
+ (instancetype)mapperWithClass:(Class)mappedClass;
- (instancetype)initWithClass:(Class)mappedClass;
- (BOOL)serializeObject:(id)object into:(id)stateBag error:(NSError**)error;
- (NSDictionary*)serializeObject:(id)object error:(NSError**)error;
- (BOOL)deserializeStateBag:(id)stateBag into:(id)target error:(NSError**)error;
- (id)deserializeStateBag:(id)stateBag error:(NSError**)error;
@end
