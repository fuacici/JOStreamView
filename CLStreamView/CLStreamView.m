//
//  CLStreamView.m
//  liulianclient
//
//  Created by Joost💟Blair on 4/12/13.
//  Copyright (c) 2013 yang alef. All rights reserved.
//

#import "CLStreamView.h"
#import "CLStreamColumn.h"
#import <QuartzCore/QuartzCore.h>

@interface CLStreamView()
{
    
    CGRect visibleRect;
    BOOL isSwipe;
    UISwipeGestureRecognizerDirection swipeDirection;
    CGPoint beginPos;
#if USE_CELL_SWIPE_ACTION
    __strong CLStreamCellView * animatingCell;
#endif
}
@property (nonatomic,strong) NSMutableArray * columns;
@property (nonatomic) NSInteger columnNum;
@property (nonatomic) NSMutableArray * rectArray;
@property (nonatomic) NSMutableArray * cells;
@property (nonatomic) NSMutableIndexSet * visibleCells;
@property (nonatomic) NSMutableSet * reusedCells;
@property (nonatomic) float totalHeight;
@property (nonatomic,strong) UIScrollView * scrollView;
@end

#pragma mark - implementation
@implementation CLStreamView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        _margin = CGSizeMake(5, 5);
        _space = CGSizeMake(3, 3);
        _scrollView = self;
//        [self addSubview: _scrollView];
    }
    return self;
}
- (void)reloadData
{
        [self cleanAnimatedCell];
    //get  whole count 
    _count = [_datasource numberOfViewsStreamView:self];
    if (_count ==0)
    {
        return;
    }
    //  get columnNum
    _columnNum = [_datasource  numberOfColumnsInStreamView:self];
    self.columns = [NSMutableArray arrayWithCapacity:_columnNum];
    self.rectArray = [NSMutableArray arrayWithCapacity:_count];
    if (!_reusedCells) {
        self.reusedCells = [NSMutableSet setWithCapacity:10];
    }else
    {
        NSArray * t = [_cells objectsAtIndexes: _visibleCells];
        [t makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [_reusedCells addObjectsFromArray: t];
    }
    self.visibleCells = [NSMutableIndexSet indexSet];
    self.cells = [NSMutableArray arrayWithCapacity: _count];
    [self populateColsCells];
    [self recaculateColumns];
    [self refreshViews:NO];


    
}
- (void)layoutSubviews
{
    [super layoutSubviews];
    [self refreshViews:NO];
}
- (void)refreshViews:(BOOL) animated
{
    if (animatingCell )
    {
        DebugLog(@"%@",@"dragging");
        return;
    }
    //load views
    visibleRect = CGRectMake(_scrollView.contentOffset.x, _scrollView.contentOffset.y, _scrollView.frame.size.width,  _scrollView.frame.size.height);
    NSMutableIndexSet * newIdx = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, _rectArray.count)];
//    [newIdx removeIndexes: _visibleCells];
    
    //clear the outbounded cells
    NSMutableIndexSet * idxToRemove = [NSMutableIndexSet indexSet];
    [_visibleCells enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        CGRect tr = [_rectArray[idx]  CGRectValue];
        if (!CGRectIntersectsRect(visibleRect, tr))
        {
            [idxToRemove addIndex: idx];
            [self enqueueCellAtIndex: idx];
        }
    }];
    [_visibleCells removeIndexes: idxToRemove];
    [newIdx enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        NSValue * value = _rectArray[idx];
        if ( CGRectIntersectsRect(visibleRect, [value CGRectValue]) )
        {
            [self loadViewAtIndex: idx animated: animated];
        }
    }];
}
#define AutoAdjustHeight 1
#define HorizontalLayout 1
- (void)populateColsCells
{
    _columnWidth = (self.bounds.size.width- _margin.width*2 -_space.width * (_columnNum-1))/_columnNum;
    //split to  columns
    //&get the rects,
    CGRect  tframe = CGRectMake(0, 0,_columnWidth,0);
    _totalHeight=0;
    for (int j =0; j<_count; j++)
    {
        CGSize s  = [_datasource streamView:self sizeForViewAtIndex: j];
        s.height =s.height* _columnWidth/s.width;
        s.width = _columnWidth;
        tframe.size = s;
        _totalHeight+= s.height;
        [_rectArray addObject:[NSValue valueWithCGRect: tframe]];
        [_cells addObject: [NSNull null]];
    }
    _totalHeight += (_count -1 - (_columnNum -1))*_space.height;
    //
    for (int i =0; i< _columnNum; ++i)
    {
        CLStreamColumn * column = [[CLStreamColumn alloc] init];
        column.height = _margin.height;
        column.index = i;
        [_columns addObject:column];
    }
}
- (void)recaculateColumns
{
    float averageH = _totalHeight/_columnNum;
    float maxHeight = 0;
 
    int tcol = 0;
    float theight=0;
    CLStreamColumn * tcolumn = nil;
    for (int i =0; i< _count; ++i)
    {
        tcolumn =_columns[tcol];
        CGRect trct = [_rectArray[i] CGRectValue];
        theight = tcolumn.height + trct.size.height/2.0f;
#if AutoAdjustHeight
        if (theight>averageH)
        {//it should be move to  next column
            DebugLog(@"### %@ col: %d index:%d",@"高度自适应", tcol,i);
            tcol++;
            if (tcol>= _columnNum)
            {
                tcol=0;
            }
            i--;
            continue;
        }
#endif
        
        float x = _margin.width +tcol *( _columnWidth+ _space.width) ;
        trct.origin = CGPointMake(x, tcolumn.height);
        [_rectArray replaceObjectAtIndex:i withObject:[NSValue valueWithCGRect: trct]];
        //update column data
        tcolumn.height += trct.size.height+_space.height;
        [tcolumn.cells addIndex:i];
  
#if HorizontalLayout
        //try to add next cell to next column
        tcol++;
        if (tcol>= _columnNum)
        {
            tcol=0;
        }
#endif
        //record the maximun height
        maxHeight =maxHeight> tcolumn.height ? maxHeight : tcolumn.height;
    }
    self.scrollView.contentSize = CGSizeMake(_scrollView.bounds.size.width, maxHeight);
    //end horizontal layout
    
}
- (CLStreamCellView *) loadViewAtIndex:(NSInteger) idx animated:(BOOL) animated
{
    CLStreamCellView * cell = [_cells objectAtIndex: idx];
    if ([_visibleCells containsIndex: idx])
    {
        return cell;
    }
    if (cell == animatingCell)
    {
        return cell;
    }
    if ([cell isKindOfClass:[NSNull class]])
    {
        cell = [_datasource streamView:self viewAtIndex:idx];
        [_cells replaceObjectAtIndex: idx withObject: cell];
        cell.target = self;
        cell.action = @selector(selectedCell);
        [_scrollView addSubview: cell];
        [_visibleCells addIndex: idx];
    }
    
    if (animated)
    {
        [UIView animateWithDuration:1.0f animations:^{
            cell.frame = [_rectArray[idx] CGRectValue];
        } completion:^(BOOL finished) {

        }];
    }else
    {
        cell.frame = [_rectArray[idx] CGRectValue];
    }
     NSAssert(![cell isEqual: [NSNull null]], @"enqueued cell can not be null");
    return cell;
}
- (void)enqueueCellAtIndex:(NSInteger) idx
{
    CLStreamCellView * cell = [_cells objectAtIndex:idx];
    if ([cell isEqual:[NSNull null]])
    {
        DebugLog(@"%@-%d",@"error",idx);
    }
    NSAssert(![cell isEqual: [NSNull null]], @"enqueued cell can not be null");
    [cell removeFromSuperview];
    [_reusedCells addObject:cell];
    [_cells replaceObjectAtIndex:idx withObject:[NSNull null]];
}
- (CLStreamCellView *) dequeueCell
{
    CLStreamCellView * cell = [_reusedCells anyObject];
    if (cell)
    {
        [_reusedCells removeObject: cell];
        [cell prepareForReuse];
    }
    
    return cell;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/
- (NSInteger)indexForCell:(CLStreamCellView *) cell
{
   NSInteger idx =  [_cells indexOfObject: cell];
    return idx;
}
- (CGSize) actualSizeForCellAtIndex:(NSInteger) index
{
    return  [_rectArray[index] CGRectValue].size;
}
- (void)selectedCell:(CLStreamCellView*) cell
{
    int i = [self indexForCell:cell];
    [self.delegate streamView:self didSelectView:cell atIndex: i];
}
- (void)removeCellAtIndex:(NSInteger) index animated:(BOOL) animated
{
    CLStreamCellView * cell = [_cells objectAtIndex: index];
    //cells ,rects ,column remove index , 
    [_cells removeObjectAtIndex: index];
    [_rectArray removeObjectAtIndex: index];
    _count = _cells.count;
    [_visibleCells removeIndex: index];
    NSInteger st = [_visibleCells indexGreaterThanOrEqualToIndex: index];
    if (st!= NSNotFound)
    {
        [_visibleCells shiftIndexesStartingAtIndex:st by:-1];
    }

    if ([cell isKindOfClass:[CLStreamCellView class]])
    {
        [cell removeFromSuperview];
        [_reusedCells addObject: cell];
    }
    
    //caculate affected column's cell rects
    NSInteger affectedCol = NSNotFound;
    for(CLStreamColumn * col in _columns)
    {
        if ([col.cells containsIndex:index])
        {
            affectedCol = col.index;
        }else
        {
            //just shift affecte index
            NSInteger t = [col.cells indexGreaterThanOrEqualToIndex: index];
            if (t!= NSNotFound)
            {
                [col.cells shiftIndexesStartingAtIndex: t by:-1];
            }
        }
    }
    
    // get new frame for those affected cells
    if (affectedCol != NSNotFound)
    {
        CLStreamColumn * col = _columns[affectedCol] ;
        int t = [col.cells indexGreaterThanOrEqualToIndex: index];
        NSAssert(t!= NSNotFound, @"must be in this column");
        [col.cells shiftIndexesStartingAtIndex: t by:-1];
        col.height = _margin.height;
        [col.cells enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            CGRect trct = [_rectArray[idx] CGRectValue];
            if (idx>= index)
            {
                float x = _margin.width +col.index *( _columnWidth+ _space.width) ;
                trct.origin = CGPointMake(x, col.height);
                [_rectArray replaceObjectAtIndex:idx withObject:[NSValue valueWithCGRect: trct]];
                //adjust them
                [_visibleCells removeIndex: idx];
            }
            col.height += trct.size.height+_space.height;
        }];
        [self refreshViews:animated];
        float maxh = 0;
        for(CLStreamColumn * col in _columns)
        {
            maxh = maxh > col.height? maxh:col.height;
        }
        _scrollView.contentSize = CGSizeMake(_scrollView.frame.size.width,maxh);
    }
}
- (void)reloadCellAtIndex:(NSInteger) index animated:(BOOL) animated
{

    //cells ,rects ,column remove index ,
    [_cells replaceObjectAtIndex:index withObject:[NSNull null]];
    CGRect old = [_rectArray[index] CGRectValue];
    CGSize s  = [_datasource streamView:self sizeForViewAtIndex: index];
    s.height =s.height* _columnWidth/s.width;
    s.width = _columnWidth;
    old.size = s;
    [_rectArray replaceObjectAtIndex:index withObject:[NSValue valueWithCGRect: old]];
    
    //caculate affected column's cell rects
    NSInteger affectedCol = [self columnIndexForCellAtIndex: index];
    // get new frame for those affected cells
    if (affectedCol != NSNotFound)
    {
        CLStreamColumn * col = _columns[affectedCol] ;
        col.height = _margin.height;
        [col.cells enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            CGRect trct = [_rectArray[idx] CGRectValue];
            if (idx>= index)
            {
                float x = _margin.width +col.index *( _columnWidth+ _space.width) ;
                trct.origin = CGPointMake(x, col.height);
                [_rectArray replaceObjectAtIndex:idx withObject:[NSValue valueWithCGRect: trct]];
            }
            col.height += trct.size.height+_space.height;
        }];
        float maxh = 0;
        for(CLStreamColumn * col in _columns)
        {
            maxh = maxh > col.height? maxh:col.height;
        }
        _scrollView.contentSize = CGSizeMake(_scrollView.frame.size.width,maxh);
        [self refreshViews:animated];
        
        
    }
}
- (NSInteger) columnIndexForCellAtIndex:(NSInteger) index
{
    for(CLStreamColumn * col in _columns)
    {
        if ([col.cells containsIndex:index])
        {
            return col.index;
        }
    }
    return NSNotFound;
}
#pragma mark - touch events
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch * touch = [touches anyObject];
    beginPos = [touch locationInView: _scrollView];
    isSwipe = NO;
    animatingCell = nil;
}
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch * touch = [touches anyObject];
    CGPoint newpos = [touch locationInView: _scrollView];
    if (!isSwipe)
    {
        if (fabs(newpos.x - beginPos.x) >=15)
        {
            isSwipe = YES;
            swipeDirection = (newpos.x - beginPos.x >0)?UISwipeGestureRecognizerDirectionRight:UISwipeGestureRecognizerDirectionLeft;
        }else if(fabs(newpos.y - beginPos.y) >=15)
        {
            isSwipe = YES;
            swipeDirection = (newpos.y - beginPos.y >0)?UISwipeGestureRecognizerDirectionDown:UISwipeGestureRecognizerDirectionUp;
        }
    }
   
#if USE_CELL_SWIPE_ACTION
       if (animatingCell == nil && isSwipe &&  [[touch view] isKindOfClass:[CLStreamCellView class]])
    {
        CLStreamCellView * cell = (CLStreamCellView *)[touch view] ;
        animatingCell = cell;
        _scrollView.canCancelContentTouches = NO;
    }
    if (animatingCell )
    {
        [self swipeAnimation: CGSizeMake(newpos.x - beginPos.x, newpos.y - beginPos.y)];
    }
#endif
}
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch * touch = [touches anyObject];
    if (!isSwipe)
    {
        if ([[touch view] isKindOfClass:[CLStreamCellView class]])
        {
            [self selectedCell: (CLStreamCellView*)[touch view]];
        }
    }else
    {
#if USE_CELL_SWIPE_ACTION
        NSNumber * angle = [animatingCell.layer valueForKeyPath:@"transform.rotation.z"];
        if (fabs([angle floatValue])> 5 *M_PI/180.0f)
        {
            NSInteger idx = [self indexForCell: animatingCell];
            [self.delegate streamView:self didSwipeView:animatingCell atIndex: idx direction:swipeDirection];
        }
        
        [self cleanAnimatedCell];
#endif
        
    }
    
}
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self cleanAnimatedCell];
}

- (void) swipeAnimation:(CGSize) offset
{
    CATransform3D t = CATransform3DIdentity;
    float h = animatingCell.layer.bounds.size.height * 1.5;
    t = CATransform3DTranslate(t, offset.width, 0, 0);
    float angle = atanf(offset.width/h);
    t = CATransform3DRotate(t,angle, 0, 0, 1);
    animatingCell.layer.transform = t;
    DebugLog(@"offset : %@", NSStringFromCGSize(offset));
}

- (void)cleanAnimatedCell
{
#if USE_CELL_SWIPE_ACTION
    animatingCell.layer.transform = CATransform3DIdentity;
    animatingCell = nil;
    _scrollView.canCancelContentTouches  = YES;
#endif
}
@end
