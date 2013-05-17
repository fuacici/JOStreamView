//
//  CLStreamView.m
//  liulianclient
//
//  Created by Joost💟Blair on 4/12/13.
//  Copyright (c) 2013 joojoo. All rights reserved.
//

#import "JOStreamView.h"
#import "JOStreamColumn.h"
#import <QuartzCore/QuartzCore.h>

#ifndef DebugLog 
    #if DEBUG
        #define DebugLog NSLog  
    #else
        #define DebugLog(s,...)
    #endif
#endif

@interface JOStreamView()
{
    
    CGRect visibleRect;
    BOOL isSwipe;
    UISwipeGestureRecognizerDirection swipeDirection;
    CGPoint beginPos;
    __strong JOStreamCellView * animatingCell;
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
static const float sSwipeLenght = 8;
@implementation JOStreamView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        _margin = CGSizeMake(5, 5);
        _space = CGSizeMake(3, 3);
        _scrollView = self;
        _scrollView.contentSize = CGSizeMake(_scrollView.bounds.size.width, _scrollView.bounds.size.height+1);
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
    _totalHeight=0;
    _columnWidth = (self.bounds.size.width- _margin.width*2 -_space.width * (_columnNum-1))/_columnNum;
    self.visibleCells = [NSMutableIndexSet indexSet];
    self.cells = [NSMutableArray arrayWithCapacity: _count];
    [self createColumns];
    [self addPlaceHoldersForRange:NSMakeRange(0, _count)];
    [self recaculateColumnsForCells: NSMakeRange(0 , _count)];
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
//        DebugLog(@"%@",@"cell is being dragged");
        return;
    }
    //load views
    visibleRect = CGRectMake(_scrollView.contentOffset.x, _scrollView.contentOffset.y, _scrollView.frame.size.width,  _scrollView.frame.size.height);
    NSMutableIndexSet * newIdx = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, _rectArray.count)];
    [newIdx removeIndexes: _visibleCells];
    
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
            [self loadViewAtIndex: idx animate: animated];
        }
    }];
}
#define AutoAdjustHeight 1
#define HorizontalLayout 1
- (void)addPlaceHoldersForRange:(NSRange )addedRange
{
    
    //split to  columns
    //&get the rects,
    CGRect  tframe = CGRectMake(0, 0,_columnWidth,0);
    for (int j =addedRange.location; j< addedRange.location + addedRange.length; j++)
    {
        CGSize s  = [_datasource streamView:self sizeForViewAtIndex: j];
        s.height =s.height* _columnWidth/s.width;
        s.width = _columnWidth;
        tframe.size = s;
        _totalHeight+= s.height;
        [_rectArray addObject:[NSValue valueWithCGRect: tframe]];
        [_cells addObject: [NSNull null]];
    }
    _totalHeight += addedRange.length *_space.height;
    
    //
}
- (void)createColumns
{
    for (int i =0; i< _columnNum; ++i)
    {
        JOStreamColumn * column = [[JOStreamColumn alloc] init];
        column.height = _margin.height;
        column.index = i;
        [_columns addObject:column];
    }
}
- (void)recaculateColumnsForCells:(NSRange) cellsRange
{
    float averageH = _totalHeight/_columnNum;
    float maxHeight = _scrollView.bounds.size.height+1;
 
    int autoAdjustCount =0;
    int tcol = 0;
    JOStreamColumn * tcolumn = nil;
    for (int i =cellsRange.location; i< cellsRange.location+cellsRange.length; ++i)
    {
        tcolumn =_columns[tcol];
        CGRect trct = [_rectArray[i] CGRectValue];
       float theight = tcolumn.height + trct.size.height/2.0f;
#if AutoAdjustHeight
        if (autoAdjustCount <_columnNum && theight>averageH)
        {
            //it maybe moved to  next column
//            DebugLog(@"### %@ col: %d index:%d",@"高度自适应", tcol,i);
            autoAdjustCount ++;
            tcol++;
            if (tcol>= _columnNum)
            {
                tcol=0;
            }
            i--;
            continue;
        }else
        {
            //it should be place to current column
            autoAdjustCount =0;
        }
#endif
        
        float x = _margin.width +tcol *( _columnWidth+ _space.width) ;
        trct.origin = CGPointMake(x, tcolumn.height);
        _rectArray[i] = [NSValue valueWithCGRect: trct];
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
- (JOStreamCellView *) loadViewAtIndex:(NSInteger) idx animate:(BOOL) animate
{
    JOStreamCellView * cell = _cells[idx];
    BOOL justMove = YES;

    
    if ([cell isKindOfClass:[NSNull class]])
    {
        cell = [_datasource streamView:self viewAtIndex:idx];
        _cells[idx] = cell;
        cell.target = self;
        cell.action = @selector(selectedCell);
        [_scrollView addSubview: cell];
        [_visibleCells addIndex: idx];
        //for animation
        justMove = NO;
    }
    CGRect tframe =  [_rectArray[idx] CGRectValue];
    if (animate)
    {
        CGRect originRct = cell.frame;
        if (!justMove)
        {
            originRct.origin.y = tframe.origin.y+originRct.size.height;
            originRct.origin.x = tframe.origin.x;
            cell.frame = originRct;
        }
        
        [UIView animateWithDuration:0.3 animations:^{
            cell.frame =tframe;
        }];
    }else
    {
        cell.frame = tframe;
    }
    
    
    
    
     NSAssert(![cell isEqual: [NSNull null]], @"enqueued cell can not be null");
    return cell;
}
- (void)enqueueCellAtIndex:(NSInteger) idx
{
    JOStreamCellView * cell = _cells[idx];
    NSAssert(![cell isEqual: [NSNull null]], @"enqueued cell can not be null");
    [cell removeFromSuperview];
    [_reusedCells addObject:cell];
    _cells[idx] = [NSNull null];
}
- (JOStreamCellView *) dequeueCell
{
    JOStreamCellView * cell = [_reusedCells anyObject];
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
- (NSInteger)indexForCell:(JOStreamCellView *) cell
{
   NSInteger idx =  [_cells indexOfObject: cell];
    return idx;
}
- (CGSize) actualSizeForCellAtIndex:(NSInteger) index
{
    return  [_rectArray[index] CGRectValue].size;
}
- (void)selectedCell:(JOStreamCellView*) cell
{
    int i = [self indexForCell:cell];
    if ([self.delegate respondsToSelector:@selector(streamView:didSelectView:atIndex:)])
    {
        [self.delegate streamView:self didSelectView:cell atIndex: i];
    }

}
- (void)removeCellAtIndex:(NSInteger) index animated:(BOOL) animated
{
    JOStreamCellView * cell = _cells[index];
    if ([cell isKindOfClass:[JOStreamCellView class]])
    {
        // recycle it first
        [self enqueueCellAtIndex:index];
    }
    //cells ,rects ,column remove index ,
    CGRect theRemoved = [_rectArray[index] CGRectValue];
    _totalHeight -= (theRemoved.size.height+_space.height);
    [_cells removeObjectAtIndex: index];
    [_rectArray removeObjectAtIndex: index];
    _count = _cells.count;
    [_visibleCells removeIndex: index];
    
    // make sure the greater indexes are right
    NSInteger st = [_visibleCells indexGreaterThanIndex: index];
    if (st!= NSNotFound)
    {
        [_visibleCells shiftIndexesStartingAtIndex:st by:-1];
    }
    
    //caculate affected column's cell rects
    NSInteger affectedCol = NSNotFound;
    for(JOStreamColumn * col in _columns)
    {
        // first find it's column index
        if ([col.cells containsIndex:index])
        {
            affectedCol = col.index;
            [col.cells removeIndex: index];
        }
        
        //just shift greater index
        NSInteger t = [col.cells indexGreaterThanIndex: index];
        if (t!= NSNotFound)
        {
            [col.cells shiftIndexesStartingAtIndex: t by:-1];
        }
       
    }
    
    // get new frame for those affected cells in same columns
    NSAssert(affectedCol != NSNotFound, @"remove cell always affecte one column");
    JOStreamColumn * col = _columns[affectedCol] ;
    int firstIndex = [col.cells indexGreaterThanOrEqualToIndex: index];
    if (firstIndex != NSNotFound)
    {
        col.height = _margin.height;
        [col.cells enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            CGRect trct = [_rectArray[idx] CGRectValue];
            if (idx>= index)
            {
                float x = _margin.width +col.index *( _columnWidth+ _space.width) ;
                trct.origin = CGPointMake(x, col.height);
                _rectArray[idx] = [NSValue valueWithCGRect: trct];
                if ( CGRectIntersectsRect(visibleRect, trct))
                {
                    [_visibleCells addIndex:idx];
                    [self loadViewAtIndex:idx animate:animated];
                }
            }
            col.height += trct.size.height+_space.height;
        }];
    }else
    {
        //cur is the last one
        col.height -= (theRemoved.size.height + _space.height);
    }
    
    
    float maxh = _scrollView.bounds.size.height+1;
    for(JOStreamColumn * col in _columns)
    {
        maxh = maxh > col.height? maxh:col.height;
    }
    _scrollView.contentSize = CGSizeMake(_scrollView.frame.size.width,maxh);
    if ([self.delegate respondsToSelector:@selector(streamView:didRemoveView:atIndex:)])
    {
        [self.delegate streamView:self didRemoveView:cell atIndex:index];
    }
}
- (void)appendCells:(int) amount animated:(BOOL) animated
{
    if (amount<=0)
    {
        return;
    }
    int old = _count;
    _count += amount;
    NSRange newCellsRange = NSMakeRange(old, amount);
    [self addPlaceHoldersForRange: newCellsRange];
    [self recaculateColumnsForCells:newCellsRange];
    [self refreshViews:animated];
}
- (void)reloadCellAtIndex:(NSInteger) index animated:(BOOL) animated
{

    //cells ,rects ,column remove index ,
    _cells[index] = [NSNull null];
    CGRect old = [_rectArray[index] CGRectValue];
    CGSize s  = [_datasource streamView:self sizeForViewAtIndex: index];
    s.height =s.height* _columnWidth/s.width;
    s.width = _columnWidth;
    old.size = s;
    _rectArray[index] = [NSValue valueWithCGRect: old];
    
    //caculate affected column's cell rects
    NSInteger affectedCol = [self columnIndexForCellAtIndex: index];
    // get new frame for those affected cells
    if (affectedCol != NSNotFound)
    {
        JOStreamColumn * col = _columns[affectedCol] ;
        col.height = _margin.height;
        [col.cells enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            CGRect trct = [_rectArray[idx] CGRectValue];
            if (idx>= index)
            {
                float x = _margin.width +col.index *( _columnWidth+ _space.width) ;
                trct.origin = CGPointMake(x, col.height);
                _rectArray[idx] = [NSValue valueWithCGRect: trct];
            }
            col.height += trct.size.height+_space.height;
        }];
        float maxh = _scrollView.bounds.size.height+1;
        for(JOStreamColumn * col in _columns)
        {
            maxh = maxh > col.height? maxh:col.height;
        }
        _scrollView.contentSize = CGSizeMake(_scrollView.frame.size.width,maxh);
        [self refreshViews:animated];
        
        
    }
}
- (NSInteger) columnIndexForCellAtIndex:(NSInteger) index
{
    for(JOStreamColumn * col in _columns)
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
        if (fabs(newpos.x - beginPos.x) >=sSwipeLenght)
        {
            isSwipe = YES;
            swipeDirection = (newpos.x - beginPos.x >0)?UISwipeGestureRecognizerDirectionRight:UISwipeGestureRecognizerDirectionLeft;
        }else if(fabs(newpos.y - beginPos.y) >=sSwipeLenght)
        {
            isSwipe = YES;
            swipeDirection = (newpos.y - beginPos.y >0)?UISwipeGestureRecognizerDirectionDown:UISwipeGestureRecognizerDirectionUp;
        }
    }
   
#if USE_CELL_SWIPE_ACTION
    UIView * tcell = [[touch view] superview];
       if (animatingCell == nil && isSwipe &&  [tcell isKindOfClass:[JOStreamCellView class]])
    {
        JOStreamCellView * cell = (JOStreamCellView *)tcell;
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
        if ([[[touch view] superview] isKindOfClass:[JOStreamCellView class]])
        {
            [self selectedCell: (JOStreamCellView*)[[touch view] superview]];
        }
    }else
    {
#if USE_CELL_SWIPE_ACTION
        NSNumber * radian = [animatingCell.layer.presentationLayer valueForKeyPath:@"transform.rotation.z"];
        if (fabs([radian floatValue])> 8 *M_PI/180.0f)
        {
            NSInteger idx = [self indexForCell: animatingCell];
            JOStreamCellView * tcell = animatingCell;
            [self cleanAnimatedCell];
            [self.delegate streamView:self didSwipeView:tcell atIndex: idx direction:swipeDirection];
        }else
        {
            [self cleanAnimatedCell];
        }
        

#endif
        
    }
    
}
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
#if USE_CELL_SWIPE_ACTION
    [self cleanAnimatedCell];
#endif
}

#if USE_CELL_SWIPE_ACTION
- (void) swipeAnimation:(CGSize) offset
{
    CATransform3D t = CATransform3DIdentity;
    float h = animatingCell.layer.bounds.size.height * 1.5;
    t = CATransform3DTranslate(t, offset.width, 0, 0);
    float angle = atanf(offset.width/h);
    t = CATransform3DRotate(t,angle, 0, 0, 1);
    animatingCell.layer.transform = t;
    
    //opacity= - PI/4 * |deltaX| +1;
    float opacity = -4*M_1_PI * fabs(angle)+1;
    animatingCell.layer.opacity = opacity;
//    DebugLog(@"offset : %@", NSStringFromCGSize(offset));
}
#endif
- (void)cleanAnimatedCell
{
#if USE_CELL_SWIPE_ACTION
    animatingCell.layer.opacity = 1;
    animatingCell.layer.transform = CATransform3DIdentity;
    animatingCell = nil;
    _scrollView.canCancelContentTouches  = YES;
#endif
}

@end
