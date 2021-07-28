//
//  XTStateMachine.m
//
//
//  Created by Gavin on 2018/7/3.
//  Copyright © 2018年 Gavin. All rights reserved.
//

#import "XTStateMachine.h"
#import <objc/runtime.h>

@implementation XTStateMachineTransition

- (instancetype)initWithState:(XTStateMachineState)from event:(XTStateMachineEvent)event to:(XTStateMachineState)to action:(XTStateMachineAction)action {
    return [self initWithStates:@[@(from)] event:event to:to action:action];
}

- (instancetype)initWithAnnotation:(XTStateMachineEvent)event, ... {
    va_list argList;
    va_start(argList, event);
    NSArray<NSNumber *> *from = va_arg(argList, NSArray<NSNumber *> *);
    XTStateMachineState to = va_arg(argList, XTStateMachineState);
    va_end(argList);
    return [self initWithStates:from event:event to:to action:nil];
}

- (instancetype)initWithStates:(NSArray<NSNumber *> *)from event:(XTStateMachineEvent)event to:(XTStateMachineState)to action:(XTStateMachineAction)action {
    self = [super init];
    if (self) {
        _from = from;
        _to = to;
        _event = event;
        _action = action;
    }
    return self;
}


- (BOOL)isValid:(XTStateMachineTransition *)object {
    if (self.event == object.event) {
        NSSet *set1 = [NSSet setWithArray:self.from];
        NSSet *set2 = [NSSet setWithArray:object.from];
        BOOL isIntersect = [set1 intersectsSet:set2];
        if (isIntersect) {
            return NO;
        }
    }
    return YES;
}

@end


@implementation XTStateMachine {
    NSMutableArray<XTStateMachineTransition *> *_transitions;
    NSMutableDictionary<NSNumber *, NSHashTable<XTStateMachineTransition *> *> *_eventMap;
}

- (instancetype)init {
    return [self initWithInitialState:XTStateMachineStateUnknown];
}

- (instancetype)initWithInitialState:(XTStateMachineState)initialState {
    return [self initWithInitialState:initialState delegate:nil];
}

- (instancetype)initWithInitialState:(XTStateMachineState)initialState delegate:(id<XTStateMachineDelegate>)delegate {
    self = [super init];
    if (self) {
        _transitions = [[NSMutableArray alloc] init];
        _eventMap = [[NSMutableDictionary alloc] init];
        _currentState = initialState;
        _delegate = delegate;
        
        [self _transitionAnnotation];
    }
    return self;
}

- (void)addTransition:(XTStateMachineTransition *)transition {
    @synchronized (self) {
        [_transitions addObject:transition];
        if (!_eventMap[@(transition.event)]) {
            [_eventMap setObject:[NSHashTable weakObjectsHashTable] forKey:@(transition.event)];
        }
        for (XTStateMachineTransition *existTransition in [_eventMap objectForKey:@(transition.event)]) {
            NSAssert([existTransition isValid:transition], @"添加状态转移冲突，from状态存在交集");
            if ( !([existTransition isValid:transition]) ) {
                NSLog(@"添加状态转移冲突，from状态存在交集");
            }
        }
        [[_eventMap objectForKey:@(transition.event)] addObject:transition];        
    }
}

- (void)sendEvent:(XTStateMachineEvent)event {
    @synchronized (self) {
        NSHashTable<XTStateMachineTransition *> *transitions = [_eventMap objectForKey:@(event)];
        if (!transitions) {
            NSLog(@"未找到event:%@对应的transaction", @(event));
            return;
        }
        for (XTStateMachineTransition *transition in transitions) {
            for (NSNumber *from in transition.from) {
                if (from.integerValue == self.currentState) {
                    NSLog(@"状态转移 event:%@ current state:%@ from:%@ -> to:%@", @(event), @(self.currentState), from, @(transition.to));
                    self.currentState = transition.to;
                    if (transition.action) {
                        transition.action(from.integerValue, transition.to);
                    }
                    return;
                }
            }
        }
    }
}

- (void)setCurrentState:(XTStateMachineState)newState {
    if (_currentState == newState) {
        return;
    }
    
    if ([self.delegate respondsToSelector:@selector(stateDidChangedFrom:To:)]) {
        [self.delegate stateDidChangedFrom:_currentState To:newState];
    }
    
    _currentState = newState;
}

- (void)_transitionAnnotation {
    Class clz = [self.delegate class];
    uint methodCount = 0;
    Method *methods = class_copyMethodList(clz, &methodCount);
    
    for (uint i = 0; i < methodCount; i++) {
        Method method = methods[i];
        NSString *name = [NSString stringWithCString:sel_getName(method_getName(method)) encoding:NSASCIIStringEncoding];
        if ([name hasPrefix:@"__xt_sm_add_transition"]) {
            //如果是一条注解
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            XTStateMachineTransition *trans = [self.delegate performSelector:method_getName(method)];
            NSAssert(i+1 < methodCount, @"注解错误：注解后未找到方法");
            if ( !(i+1 < methodCount) ) {
                NSLog(@"注解错误：注解后未找到方法");
            }
            SEL action = method_getName(methods[i+1]);
            __weak typeof(self) weakSelf = self;
            trans.action = ^(XTStateMachineState from, XTStateMachineState to) {
                [weakSelf.delegate performSelector:action];
            };
            [self addTransition:trans];
#pragma clang diagnostic pop
        }
    }
    free(methods);
}

@end
