//
//  CLStreamColumn.m
//  liulianclient
//
//  Created by Joost💟Blair on 4/12/13.
//  Copyright (c) 2013 yang alef. All rights reserved.
//

#import "CLStreamColumn.h"

@implementation CLStreamColumn
- (id)init
{
    self = [super init];
    if (self)
    {
        _cells = [NSMutableIndexSet indexSet];
    }
    return self;
}

@end
