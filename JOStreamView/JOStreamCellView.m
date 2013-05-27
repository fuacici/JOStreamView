//
//  CLStreamCellView.m
//  liulianclient
//
//  Created by Joost💟Blair on 4/12/13.
//  Copyright (c) 2013 joojoo. All rights reserved.
//

#import "JOStreamCellView.h"
#import <QuartzCore/QuartzCore.h>
@implementation JOStreamCellView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization cod
        _imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        _label = [[UILabel alloc] initWithFrame:CGRectZero];
        _contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        _contentView.backgroundColor = [UIColor whiteColor];
        _contentView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
        [self addSubview: _contentView];
        [_contentView addSubview: _imageView];
        [_contentView addSubview:_label];
    }
    return self;
}
- (void)prepareForReuse
{
    
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.


//- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
//{
//    if (_target && [_target respondsToSelector:@selector(selectedCell:)])
//    {
//        [_target performSelector:@selector(selectedCell:) withObject:self];
//    }
//}


@end
