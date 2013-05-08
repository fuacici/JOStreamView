//
//  CLStreamView.h
//  liulianclient
//
//  Created by Joost💟Blair on 4/12/13.
//  Copyright (c) 2013 joojoo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JOStreamCellView.h"

#define USE_CELL_SWIPE_ACTION 0

#pragma mark - Delegate

@protocol JOStreamViewDataSource,JOStreamViewDelegate ;

@interface JOStreamView : UIScrollView
@property (nonatomic,weak) id<JOStreamViewDataSource> datasource;
@property (nonatomic,weak) id<JOStreamViewDelegate,UIScrollViewDelegate> delegate;
@property (nonatomic,readonly) NSInteger count;
@property (nonatomic,readonly) float columnWidth;
@property (nonatomic) CGSize margin;
@property (nonatomic) CGSize space;
- (void)reloadData;
- (JOStreamCellView *) dequeueCell;
- (CGSize) actualSizeForCellAtIndex:(NSInteger) index;
- (NSInteger)indexForCell:(JOStreamCellView *) cell;
- (void)removeCellAtIndex:(NSInteger) index animated:(BOOL) animated;
- (void)appendCells:(int) amount;
@end

@protocol JOStreamViewDelegate <UIScrollViewDelegate>

@optional
- (void)streamView:(JOStreamView *) streamView didSelectView:(JOStreamCellView *)cell atIndex:(NSInteger)index;
- (void)streamView:(JOStreamView *) streamView didRemoveView:(JOStreamCellView *)cell atIndex:(NSInteger)index;
#if USE_CELL_SWIPE_ACTION
- (void)streamView:(CLStreamView *) streamView didSwipeView:(CLStreamCellView *)cell atIndex:(NSInteger)index direction:(UISwipeGestureRecognizerDirection) direction;
#endif
@end

#pragma mark - DataSource

@protocol JOStreamViewDataSource <NSObject>

@required
- (NSInteger)numberOfViewsStreamView:(JOStreamView *) streamView;
- (NSInteger)numberOfColumnsInStreamView:(JOStreamView *) streamView;
- (JOStreamCellView *)streamView:(JOStreamView *)streamView viewAtIndex:(NSInteger)index;
- (CGSize)streamView:(JOStreamView *)streamView sizeForViewAtIndex:(NSInteger)index;

@end

