//
//  TranslucentNavigationBar.m
//  WRTMusic
//
//  Created by wrt on 15/9/21.
//  Copyright (c) 2015年 wrtsoft. All rights reserved.
//

#import "TranslucentNavigationBar.h"

@implementation TranslucentNavigationBar

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self _removeBackground];
        [self _setTinColor];
    }
    return self;
}
- (void)_removeBackground{
    for (UIView *view in self.subviews) {
        if ([view isKindOfClass:NSClassFromString(@"_UINavigationBarBackground")]) {
            view.hidden = YES;
        }
    }
}

- (void)_setTinColor{
    self.tintColor = [UIColor whiteColor];
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
}

- (void)awakeFromNib{
    [super awakeFromNib];
    [self _removeBackground];
    [self _setTinColor];
    NSLog(@"navigationBarSize:%@",NSStringFromCGSize(self.bounds.size));
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
