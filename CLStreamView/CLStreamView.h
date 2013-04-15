//
//  CLStreamView.h
//  liulianclient
//
//  Created by Joost💟Blair on 4/12/13.
//  Copyright (c) 2013 yang alef. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CLStreamCellView.h"

#pragma mark - Delegate

@protocol CLStreamViewDataSource,CLStreamViewDelegate ;

@interface CLStreamView : UIScrollView
@property (nonatomic,weak) id<CLStreamViewDataSource> datasource;
@property (nonatomic,weak) id<CLStreamViewDelegate,UIScrollViewDelegate> delegate;
@property (nonatomic,readonly) NSInteger count;
@property (nonatomic,readonly) float columnWidth;
@property (nonatomic) CGSize margin;
@property (nonatomic) CGSize space;
- (void)reloadData;
- (CLStreamCellView *) dequeueCell;
- (CGSize) actualSizeForCellAtIndex:(NSInteger) index;
- (NSInteger)indexForCell:(CLStreamCellView *) cell;
@end

@protocol CLStreamViewDelegate <UIScrollViewDelegate>

@optional
- (void)streamView:(CLStreamView *) streamView didSelectView:(CLStreamCellView *)cell atIndex:(NSInteger)index;
@end

#pragma mark - DataSource

@protocol CLStreamViewDataSource <NSObject>

@required
- (NSInteger)numberOfViewsStreamView:(CLStreamView *) streamView;
- (NSInteger)numberOfColumnsInStreamView:(CLStreamView *) streamView;
- (CLStreamCellView *)streamView:(CLStreamView *)streamView viewAtIndex:(NSInteger)index;
- (CGSize)streamView:(CLStreamView *)streamView sizeForViewAtIndex:(NSInteger)index;

@end

