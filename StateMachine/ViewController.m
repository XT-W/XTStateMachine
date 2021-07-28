//
//  ViewController.m
//  StateMachine
//
//  Created by Gavin on 2018/8/14.
//  Copyright © 2018年 Gavin. All rights reserved.
//

#import "ViewController.h"
#import "Rocket.h"

@interface ViewController ()
@property (nonatomic, strong) Rocket *rocket;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (IBAction)buildANewOneTapped:(id)sender {
    [self buildANewRocket];
    [self.rocket loop];
}

- (void)buildANewRocket {
    [self.rocket.rocketView removeFromSuperview];
    [self.rocket.repairmanView removeFromSuperview];
    _rocket = [Rocket new];
    [self.view addSubview:self.rocket.rocketView];
    [self.view addSubview:self.rocket.repairmanView];
}

@end
