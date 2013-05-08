//
//  CLStreamView.h
//  liulianclient
//
//  Created by Joost💟Blair on 4/12/13.
//  Copyright (c) 2013 yang alef. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CLStreamCellView.h"

#define USE_CELL_SWIPE_ACTION 0

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
- (void)removeCellAtIndex:(NSInteger) index animated:(BOOL) animated;
- (void)appendCells:(int) amount;
@end

@protocol CLStreamViewDelegate <UIScrollViewDelegate>

@optional
- (void)streamView:(CLStreamView *) streamView didSelectView:(CLStreamCellView *)cell atIndex:(NSInteger)index;
- (void)streamView:(CLStreamView *) streamView didRemoveView:(CLStreamCellView *)cell atIndex:(NSInteger)index;
#if USE_CELL_SWIPE_ACTION
- (void)streamView:(CLStreamView *) streamView didSwipeView:(CLStreamCellView *)cell atIndex:(NSInteger)index direction:(UISwipeGestureRecognizerDirection) direction;
#endif
@end

#pragma mark - DataSource

@protocol CLStreamViewDataSource <NSObject>

@required
- (NSInteger)numberOfViewsStreamView:(CLStreamView *) streamView;
- (NSInteger)numberOfColumnsInStreamView:(CLStreamView *) streamView;
- (CLStreamCellView *)streamView:(CLStreamView *)streamView viewAtIndex:(NSInteger)index;
- (CGSize)streamView:(CLStreamView *)streamView sizeForViewAtIndex:(NSInteger)index;

@end

