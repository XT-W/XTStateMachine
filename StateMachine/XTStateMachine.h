//
//  XTStateMachine.h
//
//
//  Created by Gavin on 2018/7/3.
//  Copyright © 2018年 Gavin. All rights reserved.
//

#import <Foundation/Foundation.h>

#define __xt_concat_inner(A, B) A##B
#define __xt_concat(a,b) __xt_concat_inner(a, b)

#define transition(...) \
class NSObject; \
- (XTStateMachineTransition *)__xt_concat(__xt_sm_add_transition, __COUNTER__) { \
    return [[XTStateMachineTransition alloc] initWithAnnotation:__VA_ARGS__]; \
} \
- (void)__xt_concat(__xt_sm_transition_action, __COUNTER__)

typedef NSInteger XTStateMachineState;
typedef NSInteger XTStateMachineEvent;
#define XTStateMachineStateUnknown -1


typedef void(^XTStateMachineAction)(XTStateMachineState from, XTStateMachineState to);


@interface XTStateMachineTransition : NSObject

@property (nonatomic, strong) NSArray<NSNumber *> *from;
@property (nonatomic, assign) XTStateMachineState to;
@property (nonatomic, assign) XTStateMachineEvent event;

/**
 状态变化后的回调
 */
@property (nonatomic, strong) XTStateMachineAction action;

- (instancetype)initWithState:(XTStateMachineState)from event:(XTStateMachineEvent)event to:(XTStateMachineState)to action:(XTStateMachineAction)action;
- (instancetype)initWithAnnotation:(XTStateMachineEvent)event, ...;
- (instancetype)initWithStates:(NSArray<NSNumber *> *)from event:(XTStateMachineEvent)event to:(XTStateMachineState)to action:(XTStateMachineAction)action;
- (BOOL)isValid:(XTStateMachineTransition *)object;
@end


@class XTStateMachine;

@protocol XTStateMachineDelegate <NSObject>
- (void)stateDidChangedFrom:(XTStateMachineState)from To:(XTStateMachineState)to;
@end


@interface XTStateMachine : NSObject

@property (nonatomic, assign, readonly) XTStateMachineState currentState;

/**
 如果需要使用注解方式定义transition，则必须设置delegate
 */
@property (nonatomic, weak) id<XTStateMachineDelegate> delegate;

- (instancetype)init;
- (instancetype)initWithInitialState:(XTStateMachineState)initialState;
- (instancetype)initWithInitialState:(XTStateMachineState)initialState delegate:(id<XTStateMachineDelegate>)delegate NS_DESIGNATED_INITIALIZER;
- (void)sendEvent:(XTStateMachineEvent)event;
- (void)addTransition:(XTStateMachineTransition *)transition;
@end
