//
//  FlickerService.h
//  FlickrCarouselDemo
//
//  Created by Bobby Manuel on 1/29/15.
//  Copyright (c) 2015 Bobby Manuel. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AFImageResponseSerializer;

typedef NS_ENUM(NSUInteger, ImageSizeType) {
    ImageSizeThumb,
    ImageSizeSmall,
    ImageSizeMedium,
    ImageSizeLarge
};

@class AFJSONResponseSerializer;
@class AFHTTPRequestOperationManager;
@class FlickrCarouselModel;

static NSString *const FLICKR_API_KEY = @"7b783c55dc1fcab943366a287b75cb1c";

static NSString *const FLICKER_GETRECENT_URI = @"https://api.flickr.com/services/rest/?method=flicker.photos.getRecent";

static const int MAX_PREVIEW_PREFETCH = 5;

@interface FlickrService : NSObject

@property(nonatomic, strong) NSMutableDictionary *imageMetaCache;

+ (instancetype)sharedService;

- (void)refreshCarousel:(FlickrCarouselModel *)model;

- (NSString *)resourcePathForPhotoId:(NSString *)photoId size:(ImageSizeType)size;

- (void)cacheImageWithPath:(NSString *)path;

- (UIImage *)cachedImageWithPath:(NSString *)path;

- (void)prefetchPreviewWithId:(NSString *)imageId;

- (void)prefetchImageWithId:(NSString *)imageId;

@end
