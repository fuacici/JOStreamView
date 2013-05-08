//
//  CLStreamColumn.h
//  liulianclient
//
//  Created by Joost💟Blair on 4/12/13.
//  Copyright (c) 2013 joojoo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JOStreamColumn : NSObject
@property (nonatomic) CGFloat  height;
@property (nonatomic) CGFloat  width;
@property (nonatomic,strong,readonly) NSMutableIndexSet* cells;
@property (nonatomic) int index;
@end
