//
//  FlickrCarouselViewController.m
//  FlickrCarouselDemo
//
//  Created by Bobby Manuel on 1/29/15.
//  Copyright (c) 2015 Bobby Manuel. All rights reserved.
//

#import "FlickrCarouselViewController.h"
#import "FlickrCarouselModel.h"
#import "CarouselImageViewController.h"

@interface FlickrCarouselViewController ()

@property(readonly, strong, nonatomic) FlickrCarouselModel *modelController;

- (void)setupPageViewController;

- (void)reloadPageController;
@end

@implementation FlickrCarouselViewController {
    FlickrCarouselModel *_modelController;
};

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupPageViewController];
    // Add the page view controller's gesture recognizers to the book view controller's view so that the gestures are started more easily.
    self.view.gestureRecognizers = self.pageViewController.gestureRecognizers;
}

- (void)setupPageViewController {
    self.pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];

    [self reloadPageController];

    self.pageViewController.dataSource = self.modelController;

    [self addChildViewController:self.pageViewController];
    [self.view addSubview:self.pageViewController.view];

    CGRect pageViewRect = self.view.frame;
    self.pageViewController.view.frame = pageViewRect;

    [self.pageViewController didMoveToParentViewController:self];
}

- (void)reloadPageController {
    CarouselImageViewController *startingViewController = [self.modelController viewControllerAtIndex:0 storyboard:self.storyboard];
    NSArray *viewControllers = @[startingViewController];
    [self.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (FlickrCarouselModel *)modelController {
    // Return the model controller object, creating it if necessary.
    if (!_modelController) {
        _modelController = [[FlickrCarouselModel alloc] init];
        [_modelController addObserver:self
                           forKeyPath:@"photos.count"
                              options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                              context:nil];
    }
    return _modelController;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == _modelController) {
        if (change[@"new"] != change[@"old"]) {
            [self reloadPageController];
        }
    }
}

@end
