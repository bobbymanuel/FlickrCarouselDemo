//
//  RootViewController.h
//  FlickrCarouselDemo
//
//  Created by Bobby Manuel on 1/29/15.
//  Copyright (c) 2015 Bobby Manuel. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RootViewController : UIViewController <UIPageViewControllerDelegate>

@property (strong, nonatomic) UIPageViewController *pageViewController;

@end

