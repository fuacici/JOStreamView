//
//  CLStreamView.m
//  liulianclient
//
//  Created by Joost💟Blair on 4/12/13.
//  Copyright (c) 2013 yang alef. All rights reserved.
//

#import "CLStreamView.h"
#import "CLStreamColumn.h"

@interface CLStreamView()
{
    
    CGRect visibleRect;
    BOOL isSwipe;
    UISwipeGestureRecognizerDirection swipeDirection;
    CGPoint beginPos;
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
    }
    self.visibleCells = [NSMutableIndexSet indexSet];
    self.cells = [NSMutableArray arrayWithCapacity: _count];
    _columnWidth = (self.bounds.size.width- _margin.width*2 -_space.width * (_columnNum-1))/_columnNum;

    [self recaculateColumns];
    [self refreshViews];
    
}
- (void)layoutSubviews
{
    [super layoutSubviews];
    [self refreshViews];
}
- (void)refreshViews
{
    //load views
    visibleRect = CGRectMake(_scrollView.contentOffset.x, _scrollView.contentOffset.y, _scrollView.frame.size.width,  _scrollView.frame.size.height);
    NSMutableIndexSet * newIdx = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, _rectArray.count)];
    [newIdx removeIndexes: _visibleCells];
    
    //clear the hidden cells
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
            [_visibleCells addIndex: idx];
            [self loadViewAtIndex: idx];
        }
    }];
}
#define AutoAdjustHeight 1
#define HorizontalLayout 1
- (void)recaculateColumns
{
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
    float averageH = _totalHeight/_columnNum;
   
    //horizontal layout
    float maxHeight = 0;
    for (int i =0; i< _columnNum; ++i)
    {
        CLStreamColumn * column = [[CLStreamColumn alloc] init];
        column.height = _margin.height;
        [_columns addObject:column];
    }
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
    
    


    //end while
}
- (CLStreamCellView *) loadViewAtIndex:(NSInteger) idx
{
    CLStreamCellView * cell = [_cells objectAtIndex: idx];
    if ([cell isKindOfClass:[NSNull class]])
    {
        cell = [_datasource streamView:self viewAtIndex:idx];
        cell.frame = [_rectArray[idx] CGRectValue];
        [_cells replaceObjectAtIndex: idx withObject: cell];
        cell.target = self;
        cell.action = @selector(selectedCell);
    }
    [_scrollView addSubview: cell];
     NSAssert(![cell isEqual: [NSNull null]], @"enqueued cell can not be null");
    return cell;
}
- (void)enqueueCellAtIndex:(NSInteger) idx
{
    CLStreamCellView * cell = [_cells objectAtIndex:idx];
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
- (void)caculateRectForColumn:(NSInteger) columnidx
{
//    CLStreamColumn * column = _columns[columnidx];
//    int end = column.cells.location+column.cells.length;
//    float curH= _margin.height;
//    float x = _margin.width +columnidx *( _columnWidth+ _space.width) ;
//    for (int i = column.cells.location; i< end; ++i)
//    {
//        CGPoint tPos = CGPointMake(x, curH);
//    
//        CGSize tSize = [_rectArray[i] CGSizeValue];
//        curH+= _space.height + tSize.height;
//    }
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

#pragma mark -view 
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch * touch = [touches anyObject];
    beginPos = [touch locationInView: _scrollView];
    isSwipe = NO;
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
       if (isSwipe &&  [[touch view] isKindOfClass:[CLStreamCellView class]])
    {
        CLStreamCellView * cell = (CLStreamCellView *)[touch view] ;
        
    }
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

    }
    }

@end
