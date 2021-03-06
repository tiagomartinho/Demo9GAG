//
//  PostsTableViewController.m
//  Demo9GAG
//
//  Created by Vince Yuan on 16/7/15.
//  Copyright © 2015 Vince Yuan. All rights reserved.
//

#import "PostsTableViewController.h"
#import "Downloader.h"
#import "Post.h"
#import "PostsTableViewCell.h"
#import "SDWebImageManager.h"
#import "LoadMoreTableViewCell.h"
#import "SVProgressHUD.h"

@interface PostsTableViewController () <PostsTableViewCellDownloadDelegate>

@end

@implementation PostsTableViewController

- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _downloader = [[Downloader alloc] init];
        _posts = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;

    self.edgesForExtendedLayout = UIRectEdgeNone;

    UIRefreshControl *refresh = [[UIRefreshControl alloc] init];
    [refresh addTarget:self action:@selector(refreshPosts:) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refresh;

}

- (void)viewDidAppear:(BOOL)animated {
    _width = [UIScreen mainScreen].bounds.size.width;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)refreshPosts:(UIRefreshControl*)refresh {
    if (_downloader.isDownloading) {
        return;
    }

    _downloader.next = nil;
    [self.refreshControl beginRefreshing];
    [_downloader downloadWithCompletion:^(NSArray *posts, NSError *error) {
        if (error) {
            [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"Failed to load posts. %@", error] maskType:SVProgressHUDMaskTypeGradient];
        } else {
            [_posts removeAllObjects];
            [_posts addObjectsFromArray:posts];
            [self.tableView reloadData];
        }
        [self.refreshControl endRefreshing];
    }];

}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == SectionTypePosts) {
        return [_posts count];
    } else {
        return 1;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    if (indexPath.section == SectionTypePosts) {
        static NSString *CellIdentifier = @"PostsTableViewCell";
        PostsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (!cell) {
            cell = (PostsTableViewCell *)[PostsTableViewCell cellFromNibNamed:@"PostsTableViewCell"];
        }

        cell.downloadDelegate = self;
        [cell setupWithPosts:_posts index:indexPath.row width:_width];
        return cell;

    } else {
        LoadMoreTableViewCell *cell = (LoadMoreTableViewCell *)[LoadMoreTableViewCell cellFromNibNamed:@"LoadMoreTableViewCell"];
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {

    if (indexPath.section == SectionTypePosts) {

        Post *post = [_posts objectAtIndex:indexPath.row];
        CGFloat height = [PostsTableViewCell heightOfCellForPost:post width:_width];
        return height;

    } else {
        return 80;
    }
}

- (void)tableView:(nonnull UITableView *)tableView willDisplayCell:(nonnull UITableViewCell *)cell forRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    if (indexPath.section == SectionTypeLoadMore) {
        ((LoadMoreTableViewCell *)cell).activityIndicator.hidden = NO;
        [((LoadMoreTableViewCell *)cell).activityIndicator startAnimating];
        [_downloader downloadWithCompletion:^(NSArray *posts, NSError *error) {
            if (error) {
                [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"Failed to load posts. %@", error] maskType:SVProgressHUDMaskTypeGradient];
                [((LoadMoreTableViewCell *)cell).activityIndicator stopAnimating];
                ((LoadMoreTableViewCell *)cell).activityIndicator.hidden = YES;
            } else {
                [_posts addObjectsFromArray:posts];
                [self.tableView reloadData];
            }
        }];
    }
}

#pragma mark - PostsTableViewCellDownloadDelegate
- (void)postsTableViewCellDownloadedPostIndex:(NSInteger)index {
    // Delay reload
    [self performSelector:@selector(reloadCell:) withObject:[NSNumber numberWithInteger:index] afterDelay:0];
}

- (void)reloadCell:(NSNumber *)number {
    //[tableView beginUpdates];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForItem:[number integerValue] inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
    //[tableView endUpdates];

}

@end
