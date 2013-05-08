//
//  CLStreamCellView.h
//  liulianclient
//
//  Created by Joost💟Blair on 4/12/13.
//  Copyright (c) 2013 joojoo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JOStreamCellView : UIView
@property (nonatomic,strong) UIImageView * imageView;
@property (nonatomic,strong) UILabel * label;
@property (nonatomic,strong,readonly) UIView * contentView;
@property (nonatomic,weak) id target;
@property (nonatomic) SEL action;
- (void) prepareForReuse;
@end

