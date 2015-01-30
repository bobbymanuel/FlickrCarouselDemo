//
//  CarouselImageViewController.h
//  FlickrCarouselDemo
//
//  Created by Bobby Manuel on 1/29/15.
//  Copyright (c) 2015 Bobby Manuel. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CarouselImageViewController : UIViewController

@property(strong, nonatomic) IBOutlet UILabel *dataLabel;
@property(strong, nonatomic) id photoMeta;

@property(nonatomic, copy) NSString *photoId;
@property(nonatomic, strong) IBOutlet UIImageView *imageView;
@end

