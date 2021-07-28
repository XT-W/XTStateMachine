//
//  Rocket.h
//
//
//  Created by Gavin on 2018/8/14.
//  Copyright © 2018年 Gavin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface Rocket : NSObject
@property (nonatomic, strong) UIImageView *rocketView;
@property (nonatomic, strong) UIImageView *repairmanView;
- (void)loop;
@end
