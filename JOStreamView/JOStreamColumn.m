//
//  CLStreamColumn.m
//  liulianclient
//
//  Created by Joost💟Blair on 4/12/13.
//  Copyright (c) 2013 joojoo. All rights reserved.
//

#import "JOStreamColumn.h"

@implementation JOStreamColumn
- (id)init
{
    self = [super init];
    if (self)
    {
        _cells = [NSMutableIndexSet indexSet];
        _visible = [NSMutableIndexSet indexSet];
    }
    return self;
}

@end
