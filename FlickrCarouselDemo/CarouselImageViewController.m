//
//  CarouselImageViewController.m
//  FlickrCarouselDemo
//
//  Created by Bobby Manuel on 1/29/15.
//  Copyright (c) 2015 Bobby Manuel. All rights reserved.
//

#import "CarouselImageViewController.h"
#import "FlickrService.h"
#import "UIImageView+AFNetworking.h"

@interface CarouselImageViewController ()

@end

@implementation CarouselImageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.dataLabel.text = [self.photoMeta description];
}

- (void)setPhotoMeta:(id)photoMeta {
    _photoMeta = photoMeta;
    self.photoId = photoMeta[@"photoId"];
    FlickrService *service = [FlickrService sharedService];
    NSString *resourcePath = [service resourcePathForPhotoId:self.photoId size:ImageSizeMedium];
    UIImage *image = [service cachedImageWithPath:resourcePath];

    if (image == nil) {
        NSString *previewPath = [service resourcePathForPhotoId:self.photoId size:ImageSizeThumb];
        UIImage *preview = [service cachedImageWithPath:previewPath];
        if (preview == nil) {
            preview = [UIImage imageNamed:@"loadingImage.png"];
        }
        [self.imageView setImageWithURL:[[NSURL alloc] initWithString:resourcePath] placeholderImage:preview];
    } else {
        [self.imageView setImage:image];
    }

}


@end
