//
//  FlickrCarouselModel.h
//  FlickrCarouselDemo
//
//  Created by Bobby Manuel on 1/29/15.
//  Copyright (c) 2015 Bobby Manuel. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CarouselImageViewController;

@interface FlickrCarouselModel : NSObject <UIPageViewControllerDataSource>
@property(strong, nonatomic) NSArray *photos;

- (CarouselImageViewController *)viewControllerAtIndex:(NSUInteger)index storyboard:(UIStoryboard *)storyboard;

- (NSUInteger)indexOfViewController:(CarouselImageViewController *)viewController;

@end

