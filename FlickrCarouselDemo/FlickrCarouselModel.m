//
//  FlickrCarouselModel.m
//  FlickrCarouselDemo
//
//  Created by Bobby Manuel on 1/29/15.
//  Copyright (c) 2015 Bobby Manuel. All rights reserved.
//

#import "FlickrCarouselModel.h"
#import "CarouselImageViewController.h"
#import "FlickrService.h"

/*
 A controller object that manages a simple model -- a collection of month names.
 
 The controller serves as the data source for the page view controller; it therefore implements pageViewController:viewControllerBeforeViewController: and pageViewController:viewControllerAfterViewController:.
 It also implements a custom method, viewControllerAtIndex: which is useful in the implementation of the data source methods, and in the initial configuration of the application.
 
 There is no need to actually create view controllers for each page in advance -- indeed doing so incurs unnecessary overhead. Given the data model, these methods create, configure, and return a new view controller on demand.
 */


@interface FlickrCarouselModel ()

@end

@implementation FlickrCarouselModel

- (instancetype)init {
    self = [super init];
    if (self) {
        // Create the data model.
        _photos = nil;
        [[FlickrService sharedService] loadCarousel:self];
    }
    return self;
}

- (CarouselImageViewController *)viewControllerAtIndex:(NSUInteger)index storyboard:(UIStoryboard *)storyboard {
    // Return the data view controller for the given index.
    if (([self.photos count] == 0) || (index >= [self.photos count])) {
        return nil;
    }

    // Create a new view controller and pass suitable data.
    CarouselImageViewController *photoViewController = [storyboard instantiateViewControllerWithIdentifier:@"CarouselImageViewController"];
    [photoViewController view];
    photoViewController.photoMeta = self.photos[index];
    return photoViewController;
}

- (NSUInteger)indexOfViewController:(CarouselImageViewController *)viewController {
    // Return the index of the given data view controller.
    // For simplicity, this implementation uses a static array of model objects and the view controller stores the model object; you can therefore use the model object to identify the index.
    return [self.photos indexOfObject:viewController.photoMeta];
}

#pragma mark - Page View Controller Data Source

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    NSUInteger index = [self indexOfViewController:(CarouselImageViewController *) viewController];
    if ((index == 0) || (index == NSNotFound)) {
        return nil;
    }
    index--;
    return [self viewControllerAtIndex:index storyboard:viewController.storyboard];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    NSUInteger index = [self indexOfViewController:(CarouselImageViewController *) viewController];
    if (index == NSNotFound) {
        return nil;
    }

    index++;
    if (index == [self.photos count]) {
        return nil;
    }
    return [self viewControllerAtIndex:index storyboard:viewController.storyboard];
}

@end
