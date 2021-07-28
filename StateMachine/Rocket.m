//
//  Rocket.m
//
//
//  Created by Gavin on 2018/8/14.
//  Copyright © 2018年 Gavin. All rights reserved.
//

#import "Rocket.h"
#import "XTStateMachine.h"

typedef NS_ENUM(XTStateMachineState, DemoState) {
    DemoStatePreparing,
    DemoStateFlying,
    DemoStateLanding,
    DemoStateShutDown,
    DemoStateCrash
};

typedef NS_ENUM(XTStateMachineEvent, DemoEvent) {
    DemoEventLaunch,
    DemoEventSeparate,
    DemoEventTouchDown,
    DemoEventRecycle,
    DemoEventException
};

@interface Rocket () <XTStateMachineDelegate>
@property (nonatomic, strong) XTStateMachine *fsm;
@property (nonatomic, assign) BOOL reuse;
@end

@implementation Rocket

- (instancetype)init {
    self = [super init];
    if (self) {
        _fsm = [[XTStateMachine alloc] initWithInitialState:DemoStatePreparing delegate:self];
        _reuse = YES;
        _rocketView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"rocket"]];
        _repairmanView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"repairman"]];
        _repairmanView.hidden = YES;
        CGSize screenSize = UIScreen.mainScreen.bounds.size;
        self.rocketView.frame = CGRectMake(screenSize.width/2 - 100/2, screenSize.height - 200, 100, 100);
        self.repairmanView.frame = CGRectMake(screenSize.width/2 + 100/2, screenSize.height - 200 + 50, 50, 50);
    }
    return self;
}

- (void)loop {
    __weak typeof(self) weakSelf = self;
    [_fsm sendEvent:DemoEventLaunch];
    BOOL crash = arc4random() % 3 == 0;
    if (crash) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(arc4random() % 4000 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
            [weakSelf.fsm sendEvent:DemoStateCrash];
            weakSelf.reuse = NO;
        });
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakSelf.fsm sendEvent:DemoEventSeparate];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf.fsm sendEvent:DemoEventTouchDown];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weakSelf.fsm sendEvent:DemoEventRecycle];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    if (weakSelf.reuse) {
                        [weakSelf loop];
                    }
                });
            });
        });
    });
}

// MARK: - XTStateMachineDelegate
- (void)stateDidChangedFrom:(XTStateMachineState)from To:(XTStateMachineState)to {
    // 当状态变化时，可以统一在这里处理
}

// 事件
// 起飞
@transition(DemoEventLaunch, @[@(DemoStatePreparing)], DemoStateFlying) {
    NSLog(@"起飞");
    self.repairmanView.hidden = YES;
    [UIView animateWithDuration:2 animations:^{
        CGSize screenSize = UIScreen.mainScreen.bounds.size;
        self.rocketView.frame = self.rocketView.frame = CGRectMake(screenSize.width/2 - 100/2, 100, 100, 100);
    }];
}

// 分离
@transition(DemoEventSeparate, @[@(DemoStateFlying)], DemoStateLanding) {
    NSLog(@"星箭分离，火箭返回中");
    [UIView animateWithDuration:2 animations:^{
        CGSize screenSize = UIScreen.mainScreen.bounds.size;
        self.rocketView.frame = self.rocketView.frame = CGRectMake(screenSize.width/2 - 100/2, screenSize.height - 200, 100, 100);
    }];
}

// 降落
@transition(DemoEventTouchDown, @[@(DemoStateLanding)], DemoStateShutDown) {
    NSLog(@"成功着陆");
}

// 回收
@transition(DemoEventRecycle, @[@(DemoStateShutDown)], DemoStatePreparing) {
    NSLog(@"进厂回收");
    self.repairmanView.hidden = NO;
}

// 坠毁
@transition(DemoEventException, @[@(DemoStatePreparing),
                                  @(DemoStateFlying),
                                  @(DemoStateLanding),
                                  @(DemoStateShutDown)], DemoStateCrash) {
    NSLog(@"发生故障，火箭坠毁");
    self.rocketView.image = [UIImage imageNamed:@"crash"];
    CFTimeInterval pausedTime = [self.rocketView.layer convertTime:CACurrentMediaTime() toLayer:nil];
    self.rocketView.layer.timeOffset = pausedTime;
    self.rocketView.layer.speed = .0;
}
@end
