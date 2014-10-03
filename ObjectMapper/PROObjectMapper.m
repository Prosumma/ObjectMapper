//
//  PROObjectMapper.m
//  ObjectMapper
//
//  Created by Gregory Higley on 10/2/14.
//  Copyright (c) 2014 Prosumma LLC. All rights reserved.
//

#import <objc/runtime.h>
#import "PROObjectMapper.h"

static NSString *const PROObjectMapperSerializationMappingsKey = @"serialization";
static NSString *const PROObjectMapperDeserializationMappingsKey = @"deserialization";
static NSRegularExpression *PROClassNameRegularExpression = nil;

static NSArray *PROUnmappableProperties = nil;
static NSMutableDictionary *PROObjectMappings = nil;
static PROMapBlock PRODefaultMapBlock = nil;
static PROMapBlock PROSkipMapBlock = nil;

@implementation PROObjectMapper

+ (void)initialize
{
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        PROObjectMappings = [NSMutableDictionary new];
        PROUnmappableProperties = @[ @"debugDescription", @"description", @"hash", @"superclass" ];
        PRODefaultMapBlock = [^(id target, NSString* key, id source, NSError **error) {
            [target setValue:[source valueForKey:key] forKey:key];
            return YES;
        } copy];
        PROSkipMapBlock = [^(id target, NSString* key, id source, NSError **error) {
            return YES;
        } copy];
        PROClassNameRegularExpression = [NSRegularExpression regularExpressionWithPattern:@"^@\"(\\w+)\"" options:NSRegularExpressionCaseInsensitive error:NULL];
    });
}

+ (NSDictionary*)mappingsForClass:(Class)mappedClass
{
    NSString *mappedClassName = NSStringFromClass(mappedClass);
    NSDictionary *result = nil;
    @synchronized (PROObjectMappings) {
        result = PROObjectMappings[mappedClassName];
        if (!result) {
            // Set up our mapping dictionaries
            NSMutableDictionary *serializationMappings = [NSMutableDictionary new];
            NSMutableDictionary *deserializationMappings = [NSMutableDictionary new];
            
            // Determine whether the mapped class offers custom mappings.
            BOOL customizable = [mappedClass conformsToProtocol:@protocol(PROMappableObject)];
            
            // Loop through our properties.
            unsigned int propertyCount = 0;
            objc_property_t *properties = class_copyPropertyList(mappedClass, &propertyCount);
            for (unsigned int p = 0; p < propertyCount; p++) {
                // Get property attributes up front.
                objc_property_t property = properties[p];
                // Name
                NSString *propertyName = @(property_getName(property));
                // Check whether this property is mappable, otherwise continue on.
                if ([PROUnmappableProperties containsObject:propertyName]) continue;
                // Type
                char *propertyTypeCString = property_copyAttributeValue(property, "T");
                NSString *propertyType = @(propertyTypeCString);
                free(propertyTypeCString);
                // Determine whether the property's type is a class that supports automatic mapping.
                __block Class nestedMappableClass = Nil;
                [PROClassNameRegularExpression enumerateMatchesInString:propertyType options:0 range:NSMakeRange(0, propertyType.length) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
                    NSString *nestedClassName = [propertyType substringWithRange:[result rangeAtIndex:1]];
                    Class nestedClass = NSClassFromString(nestedClassName);
                    if ([nestedClass conformsToProtocol:@protocol(PROMappableObject)]) nestedMappableClass = nestedClass;
                    *stop = YES;
                }];
                // Is the property read-only? This is useful only for deserialization, since read-only properties cannot be written to.
                // (Although a mappable class can override this.)
                char *readonly = property_copyAttributeValue(property, "R");
                
                // Create serialization mappings.
                PROMapBlock serializationMapBlock = nil;
                if (customizable) {
                    NSString *serializationMapBlockSelectorString = [NSString stringWithFormat:@"mapBlockForSerializationOf%@", [propertyName capitalizedString]];
                    SEL serializationMapBlockSelector = NSSelectorFromString(serializationMapBlockSelectorString);
                    if ([mappedClass respondsToSelector:serializationMapBlockSelector]) {
                        serializationMapBlock = ((PROMapBlock (*)(id, SEL))[mappedClass methodForSelector:serializationMapBlockSelector])(mappedClass, serializationMapBlockSelector);
                        if (!serializationMapBlock) serializationMapBlock = PROSkipMapBlock;
                    }
                }
                if (!serializationMapBlock && nestedMappableClass) {
                    serializationMapBlock = ^BOOL(id target, NSString *key, id source, NSError **error) {
                        NSError *localError = nil;
                        PROObjectMapper *nestedMapper = [PROObjectMapper mapperWithClass:nestedMappableClass];
                        [target setValue:[nestedMapper serializeObject:[source valueForKey:key] error:&localError] forKey:key];
                        if (error) *error = localError;
                        return !localError;
                    };
                }
                if (!serializationMapBlock) serializationMapBlock = PRODefaultMapBlock;
                
                // Assignment
                serializationMappings[propertyName] = [serializationMapBlock copy];
                
                // Create deserialization mappings.
                PROMapBlock deserializationMapBlock = nil;
                if (customizable) {
                    NSString *deserializationMapBlockSelectorString = [NSString stringWithFormat:@"mapBlockForDeserializationOf%@", [propertyName capitalizedString]];
                    SEL deserializationMapBlockSelector = NSSelectorFromString(deserializationMapBlockSelectorString);
                    if ([mappedClass respondsToSelector:deserializationMapBlockSelector]) {
                        deserializationMapBlock = ((PROMapBlock (*)(id, SEL))[mappedClass methodForSelector:deserializationMapBlockSelector])(mappedClass, deserializationMapBlockSelector);
                        if (!deserializationMapBlock) deserializationMapBlock = PROSkipMapBlock;
                    }
                }
                if (!deserializationMapBlock) {
                    if (!readonly) {
                        deserializationMapBlock = PRODefaultMapBlock;
                        if (nestedMappableClass) {
                            deserializationMapBlock = ^BOOL(id target, NSString *key, id source, NSError **error) {
                                NSError *localError = nil;
                                PROObjectMapper *nestedMapper = [PROObjectMapper mapperWithClass:nestedMappableClass];
                                [target setValue:[nestedMapper deserializeStateBag:[source valueForKey:key] error:&localError] forKey:key];
                                if (error) *error = localError;
                                return !localError;
                            };
                        }
                    } else {
                        deserializationMapBlock = PROSkipMapBlock;
                    }
                }
                
                // Assignment and cleanup
                deserializationMappings[propertyName] = [deserializationMapBlock copy];
                if (readonly) free(readonly);
            }
            
            free(properties);
            result = @{ PROObjectMapperSerializationMappingsKey : serializationMappings, PROObjectMapperDeserializationMappingsKey : deserializationMappings };
            PROObjectMappings[mappedClassName] = result;
        }
    }
    return result;
}

+ (NSDictionary*)mappingsForClass:(Class)mappedClass ofType:(NSString*)mappingType
{
    return [self mappingsForClass:mappedClass][mappingType];
}

+ (instancetype)mapperWithClass:(Class)mappedClass
{
    return [[self alloc] initWithClass:mappedClass];
}

- (instancetype)initWithClass:(Class)mappedClass
{
    self = [super init];
    if (self) {
        _mappedClass = mappedClass;
    }
    return self;
}

- (BOOL)serializeObject:(id)object into:(id)stateBag error:(NSError**)error
{
    NSDictionary *mappings = [[self class] mappingsForClass:self.mappedClass ofType:PROObjectMapperSerializationMappingsKey];
    __block NSError *localError;
    [mappings enumerateKeysAndObjectsUsingBlock:^(NSString *key, PROMapBlock map, BOOL *stop) {
        *stop = !map(stateBag, key, object, &localError);
    }];
    if (error) *error = localError;
    return !localError;
}

- (NSDictionary*)serializeObject:(id)object error:(NSError**)error
{
    NSMutableDictionary *dictionary = [NSMutableDictionary new];
    if ([self serializeObject:object into:dictionary error:error]) {
        return dictionary;
    }
    return nil;
}

- (BOOL)deserializeStateBag:(id)stateBag into:(id)target error:(NSError**)error
{
    NSDictionary *mappings = [[self class] mappingsForClass:self.mappedClass ofType:PROObjectMapperDeserializationMappingsKey];
    __block NSError *localError = nil;
    [mappings enumerateKeysAndObjectsUsingBlock:^(NSString *key, PROMapBlock map, BOOL *stop) {
        *stop = !map(target, key, stateBag, &localError);
    }];
    if (error) *error = localError;
    return !localError;
}

- (id)deserializeStateBag:(id)stateBag error:(NSError**)error
{
    id target = [self.mappedClass new];
    if ([self deserializeStateBag:stateBag into:target error:error]) {
        return target;
    }
    return nil;
}

@end
