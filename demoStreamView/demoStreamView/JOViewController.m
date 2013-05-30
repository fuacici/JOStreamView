//
//  JOViewController.m
//  demoStreamView
//
//  Created by Joost💟Blair on 5/8/13.
//  Copyright (c) 2013 eker. All rights reserved.
//

#import "JOViewController.h"
#import "JOStreamView.h"

@interface JOViewController ()<JOStreamViewDataSource,JOStreamViewDelegate>
@property (nonatomic,strong) JOStreamView * stream;
@property (nonatomic,strong) NSMutableArray * item;
@end

@implementation JOViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    _item = [NSMutableArray arrayWithCapacity:10];
    for (int i =0; i!= 300; ++i) {
        [_item addObject:[NSString  stringWithFormat:@"origin %d", i]];
    }
    _stream = [[JOStreamView alloc] initWithFrame:self.view.bounds];
    _stream.delegate = self;
    _stream.datasource = self;
    [self.view addSubview: _stream];
    [_stream reloadData];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (int)numberOfColumnsInStreamView:(JOStreamView *)streamView
{
    return  2;
}
- (int)numberOfViewsStreamView:(JOStreamView *)streamView
{
    return _item.count;
}
- (CGSize) streamView:(JOStreamView *)streamView sizeForViewAtIndex:(NSInteger)index
{
    return CGSizeMake(150, 240);
}
- (JOStreamCellView *)streamView:(JOStreamView *)streamView viewAtIndex:(NSInteger)index
{
    JOStreamCellView * cell = [streamView dequeueCell];
    CGSize t = [streamView actualSizeForCellAtIndex:index];
    if (!cell)
    {
        cell = [[JOStreamCellView alloc] initWithFrame: CGRectMake(0, 0, t.width, t.height)];
    }
    cell.label.text = _item[index];
    [cell.label sizeToFit];
    cell.imageView.image = [UIImage imageNamed:@"test.jpg"];
    return cell;
}
- (void)streamView:(JOStreamView *)streamView didSwipeView:(JOStreamCellView *)cell atIndex:(NSInteger)index direction:(UISwipeGestureRecognizerDirection)direction
{
    [_item removeObjectAtIndex: index];
    [streamView removeCellAtIndex: index animated:YES];
}
@end
