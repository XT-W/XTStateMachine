XTStateMachine提供了简单的状态机能力，实现了如下的状态机动作
##### 状态机动作类型
 __输入动作__ ：依赖于当前状态和输入条件进行（transition）
 __转移动作__ ：在进行特定转移时进行
进入动作：在进入状态时进行（未实现，如有需求可添加）
退出动作：在退出状态时进行（未实现，如有需求可添加）


## 使用方法
XTStateMachine的使用方法类似[spring-statemachine](http://projects.spring.io/spring-statemachine/)，状态的转移依赖于事件触发。事件、起始状态、结束状态的关系通过transition来链接。初始化时，使用addTransition添加转移映射
```
- (void)addTransition:(XTStateMachineTransition *)transition;
```
transition的定义如下，包含事件，起始状态，结束状态，动作。其中【输入动作】包含在transition的action里
```
@interface XTStateMachineTransition : NSObject
/**
 起始状态，可以多状态
 */
@property (nonatomic, strong) NSArray<NSNumber *> *from;
/**
 结束状态，只能为单一状态
 */
@property (nonatomic, assign) XTStateMachineState to;
/**
 事件
 */
@property (nonatomic, assign) XTStateMachineEvent event;
/**
 动作，表示状态变化后的回调
 */
@property (nonatomic, strong) XTStateMachineAction action;
```
当事件发生时，外部调用方使用sendEvent来通知状态机变更状态
```
- (void)sendEvent:(XTStateMachineEvent)event;
```
如果需要得到状态转移的回调，可以实现XTStateMachineDelegate协议，对应【转移动作】
```
@protocol XTStateMachineDelegate <NSObject>
- (void)stateDidChangedFrom:(XTStateMachineState)from To:(XTStateMachineState)to;
@end
```
## demo
 dome使用状态机模拟了一个可回收式火箭发射的过程，首先定义状态和事件
``` objective-c
typedef NS_ENUM(XTStateMachineState, DemoState) {
    DemoStatePreparing, // 准备
    DemoStateFlying, // 飞行
    DemoStateLanding, // 降落
    DemoStateShutDown, // 发动机停车
    DemoStateCrash // 坠毁
};

typedef NS_ENUM(XTStateMachineEvent, DemoEvent) {
    DemoEventLaunch,
    DemoEventSeparate,
    DemoEventTouchDown,
    DemoEventRecycle,
    DemoEventException
};
```
 然后初始化状态机实例

``` objective-c
@interface StateMachineDemo () <XTStateMachineDelegate>
@end

@implementation StateMachineDemo {
    XTStateMachine *_fsm;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _fsm = [[XTStateMachine alloc] initWithInitialState: DemoStatePreparing delegate:self];
    }
    return self;
}

// MARK: - XTStateMachineDelegate
- (void)stateDidChangedFrom:(XTStateMachineState)from To:(XTStateMachineState)to {
    // 当状态变化时，可以统一在这里处理
}
```
定义transition，定义方式可以使用以下两种方法
```
// 方法
- (void)addTransition:(XTStateMachineTransition *)transition;

// 注解
@transition(<#Event#>, @[@(<#From#>)], <#To#>) {
    <#Action#>
}
```
在demo中我们采用注解方式实现
``` objective-c
// 事件
// 起飞
@transition(DemoEventLaunch, @[@(DemoStatePreparing)], DemoStateFlying) {
    NSLog(@"起飞");
}

// 分离
@transition(DemoEventSeparate, @[@(DemoStateFlying)], DemoStateLanding) {
    NSLog(@"星箭分离，火箭返回中");
}

// 降落
@transition(DemoEventTouchDown, @[@(DemoStateLanding)], DemoStateShutDown) {
    NSLog(@"成功着陆");
}

// 回收
@transition(DemoEventRecycle, @[@(DemoStateShutDown)], DemoStatePreparing) {
    NSLog(@"进厂回收");
}

// 坠毁
@transition(DemoEventException, @[@(DemoStatePreparing),
                                  @(DemoStateFlying),
                                  @(DemoStateLanding),
                                  @(DemoStateShutDown)], DemoStateCrash) {
    NSLog(@"发生故障，火箭坠毁");
}
@end
```
到此为止，状态机的定义完成了，接下来让我们来启动状态机，发射火箭
``` objective-c
- (void)loop {
    __weak typeof(self) weakSelf = self;
    [_fsm sendEvent:DemoEventLaunch];
    BOOL crash = arc4random() % 3 == 0;
    if (crash) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(arc4random() % 4000 * NSEC_PER_MSEC)), 
dispatch_get_main_queue(), ^{
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
```
loop执行过程中输出一下信息
```
2018-08-15 15:04:40.781965+0800 StateMachine[46238:52523967] 起飞
2018-08-15 15:04:42.980528+0800 StateMachine[46238:52523967] 星箭分离，火箭返回中
2018-08-15 15:04:45.177993+0800 StateMachine[46238:52523967] 成功着陆
2018-08-15 15:04:45.725648+0800 StateMachine[46238:52523967] 进厂回收
2018-08-15 15:04:46.823431+0800 StateMachine[46238:52523967] 起飞
2018-08-15 15:04:47.193720+0800 StateMachine[46238:52523967] 发生故障，火箭坠毁
```

完整demo已上传至附件
