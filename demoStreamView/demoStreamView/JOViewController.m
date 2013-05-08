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
@end

@implementation JOViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
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
    return 10;
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
    cell.imageView.image = [UIImage imageNamed:@"test.jpg"];
    return cell;
}
@end
