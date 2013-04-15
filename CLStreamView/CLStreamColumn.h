//
//  CLStreamColumn.h
//  liulianclient
//
//  Created by Joost💟Blair on 4/12/13.
//  Copyright (c) 2013 yang alef. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CLStreamColumn : NSObject
@property (nonatomic) CGFloat  height;
@property (nonatomic) CGFloat  width;
@property (nonatomic,strong,readonly) NSMutableIndexSet* cells;
@end
