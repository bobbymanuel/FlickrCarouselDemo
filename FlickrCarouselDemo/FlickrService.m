//
//  FlickerService.m
//  FlickrCarouselDemo
//
//  Created by Bobby Manuel on 1/29/15.
//  Copyright (c) 2015 Bobby Manuel. All rights reserved.
//

#import "FlickrService.h"
#import "AFNetworking.h"
#import "FlickrCarouselModel.h"
#import "UIImageView+AFNetworking.h"

@interface FlickrService ()

@property(nonatomic, strong) AFHTTPRequestOperationManager *requestManager;

@property(nonatomic, strong) AFHTTPRequestOperationManager *imageRequestManager;

- (NSString *)sizeDescriptorForImageSize:(ImageSizeType)size;

- (BOOL)isSuccessfulResponse:(id)response;

- (void)updateModel:(FlickrCarouselModel *)carouselModel withResponse:(id)response fromURI:(NSString *const)URI;

- (NSString *)photoIdFromMeta:(NSDictionary *)photoMeta;

@end

@implementation FlickrService

+ (instancetype)sharedService {
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (id)init {
    self = [super init];
    self.requestManager = [AFHTTPRequestOperationManager manager];
    self.requestManager.responseSerializer = [AFJSONResponseSerializer serializer];
    self.imageRequestManager = [AFHTTPRequestOperationManager manager];
    self.imageRequestManager.responseSerializer = [AFImageResponseSerializer serializer];
    return self;
}

- (NSString *)sizeDescriptorForImageSize:(ImageSizeType)size {
    switch (size) {
        case ImageSizeThumb:
            return @"t";
        case ImageSizeSmall:
            return @"m";
        case ImageSizeMedium:
            return @"z";
        case ImageSizeLarge:
            return @"b";
        default:
            return @"z";
    }
}

- (NSString *)resourcePathForPhotoId:(NSString *)photoId size:(ImageSizeType)size {
    NSString *sizeKey = [NSString stringWithFormat:@"url_%@", [self sizeDescriptorForImageSize:size]];
    NSDictionary *imageMeta = self.imageMetaCache[photoId];
    if (imageMeta != nil) {
        return imageMeta[sizeKey];
    }
    return nil;
}

- (void)refreshCarousel:(FlickrCarouselModel *)model {

    NSDictionary *params = @{
            @"extras" : @[@"url_b", @"url_t", @"url_m", @"url_z"],
            @"api_key" : FLICKR_API_KEY,
            @"page" : @"1",
            @"format" : @"json"
    };

    __weak typeof(self) weakSelf = self;
    AFHTTPRequestOperation *request = [self.requestManager GET:FLICKER_GETRECENT_URI
                                                    parameters:params
                                                       success:^(id operation, id response) {

                                                           [weakSelf updateModel:model
                                                                    withResponse:response
                                                                         fromURI:FLICKER_GETRECENT_URI];

                                                       } failure:^(id operation, NSError *error) {
                // TODO:Error handling To be implemented
            }];
    [request start];
}


- (void)updateModel:(FlickrCarouselModel *)carouselModel withResponse:(id)response fromURI:(NSString *const)URI {
    if ([self isSuccessfulResponse:response]) {
        NSDictionary *validResponse = response;
        NSArray *photos = validResponse[@"photos"];
        int prefetchCount = 0;

        for (NSDictionary *photoMeta in photos) {
            NSString *photoId = [self cachePhotoMeta:photoMeta];
            if (prefetchCount < MAX_PREVIEW_PREFETCH) {
                [self prefetchPreviewWithId:photoId];
            }
            if (!prefetchCount) {
                [self prefetchImageWithId:photoId];
            }
            prefetchCount++;
        }
        carouselModel.photos = photos;
    } else {
        // TODO: Error handling to be implemented
    }
}

- (NSString *)cachePhotoMeta:(NSDictionary *)photoMeta {
    NSMutableDictionary *meta = [photoMeta mutableCopy];
    NSString *photoId = [self photoIdFromMeta:meta];
    meta[@"photoId"] = photoId;
    self.imageMetaCache[photoId] = [NSDictionary dictionaryWithDictionary:meta];
    return photoId;
}

- (NSString *)photoIdFromMeta:(NSDictionary *)photoMeta {
    return [NSString stringWithFormat:@"%@_%@", photoMeta[@"id"], photoMeta[@"secret"]];
}

- (BOOL)isSuccessfulResponse:(id)response {
    BOOL validResponse;
    validResponse = NO;
    if ([response respondsToSelector:@selector(objectForKey:)]) {
        NSString *status = [response objectForKey:@"stat"];
        if ([[status lowercaseString] isEqualToString:@"ok"]) {
            validResponse = YES;
        } else {
            // TODO: Error handling to be implemented
        }
    }
    return validResponse;
}

#pragma mark - image caching

- (void)prefetchImageWithId:(NSString *)imageId {
    NSString *path = [self resourcePathForPhotoId:imageId size:ImageSizeMedium];
    [self cacheImageWithPath:path];
}

- (void)prefetchPreviewWithId:(NSString *)imageId {
    NSString *path = [self resourcePathForPhotoId:imageId size:ImageSizeThumb];
    [self cacheImageWithPath:path];
}

- (UIImage *)cachedImageWithPath:(NSString *)path {
    id <AFImageCache> imageCache = [UIImageView sharedImageCache];
    return [imageCache cachedImageForRequest:[self requestWithPath:path]];
}

- (void)cacheImageWithPath:(NSString *)path {
    id <AFImageCache> imageCache = [UIImageView sharedImageCache];
    UIImage *image = [imageCache cachedImageForRequest:[self requestWithPath:path]];
    NSDictionary *params = @{
            @"api_key" : FLICKR_API_KEY,
    };

    __weak typeof(self) weakSelf = self;
    if (image == nil) {
        [self.imageRequestManager GET:path
                           parameters:params
                              success:^(id operation, id response) {
                                  if ([response isKindOfClass:[UIImage class]]) {
                                      [[UIImageView sharedImageCache] cacheImage:response
                                                                      forRequest:[weakSelf requestWithPath:path]];
                                  };
                              }
                              failure:^(id operation, NSError *error) {
                                  // Error handling to be resolved later
                              }];
    };
}

- (NSURLRequest *)requestWithPath:(NSString *)path {
    return [NSURLRequest requestWithURL:[[NSURL alloc] initWithString:path]];
}


@end
