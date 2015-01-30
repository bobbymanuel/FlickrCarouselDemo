//
//  FlickerService.m
//  FlickrCarouselDemo
//
//  Created by Bobby Manuel on 1/29/15.
//  Copyright (c) 2015 Bobby Manuel. All rights reserved.
//

#import "FlickrService.h"
#import "FlickrCarouselModel.h"
#import "UIImageView+AFNetworking.h"

@interface FlickrService ()

@property(nonatomic, strong) AFHTTPRequestOperationManager *requestManager;

@property(nonatomic, strong) AFHTTPRequestOperationManager *imageRequestManager;

- (NSString *)sizeDescriptorForImageSize:(ImageSizeType)size;

- (BOOL)isSuccessfulResponse:(id)response;

- (id)deserializeFlickrResponse:(id)response;

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
    self.imageMetaCache = [NSMutableDictionary dictionary];
    self.requestManager = [AFHTTPRequestOperationManager manager];
    self.requestManager.responseSerializer = [AFHTTPResponseSerializer serializer];
    [self.requestManager.responseSerializer setAcceptableContentTypes:[NSSet setWithObjects:@"text/javascript", @"text/plain", @"application/json", nil]];
    self.imageRequestManager = [AFHTTPRequestOperationManager manager];
    self.imageRequestManager.responseSerializer = [AFImageResponseSerializer serializer];
    return self;
};

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

- (void)loadCarousel:(FlickrCarouselModel *)model {

    NSDictionary *params = @{
            @"extras" : @[@"url_b", @"url_t", @"url_m", @"url_z"],
            @"api_key" : FLICKR_API_KEY,
            @"page" : @"1",
            @"format" : @"json",
            @"method" : @"flickr.photos.getrecent"

    };

    __weak typeof(self) weakSelf = self;
    AFHTTPRequestOperation *request = [self.requestManager GET:FLICKER_API_URI
                                                    parameters:params
                                                       success:^(id operation, id response) {
                                                           // TODO: deserialize should be moved into a formal responseSerializer class
                                                           id data = [self deserializeFlickrResponse:response];
                                                           [weakSelf updateModel:model
                                                                    withResponse:data
                                                                         fromURI:FLICKER_API_URI];

                                                       } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                // TODO:Error handling To be implemented
                NSLog(@"%@", operation.responseString);
                NSLog(@"%@", error);
            }];
    [request start];
}

- (NSString *)resourcePathForPhotoId:(NSString *)photoId size:(ImageSizeType)size {
    NSString *sizeKey = [self sizeDescriptorForImageSize:size];
    NSDictionary *imageMeta = self.imageMetaCache[photoId];
    if (imageMeta != nil) {
        return [NSString stringWithFormat:@"http://farm%@.staticflickr.com/%@/%@_%@_%@.jpg", imageMeta[@"farm"], imageMeta[@"server"], imageMeta[@"id"], imageMeta[@"secret"], sizeKey];
    }
    return nil;
}


# pragma mark - response parsing

- (id)deserializeFlickrResponse:(id)response {
    NSString *responseString = [[NSString alloc] initWithBytes:[response bytes] length:[response length] encoding:NSUTF8StringEncoding];
    NSRange lead = [responseString rangeOfString:@"jsonFlickrApi("];

    id data = nil;
    if (lead.location != NSNotFound) {

        responseString = [responseString substringFromIndex:(lead.location + lead.length)];
        NSRange tail = [responseString rangeOfString:@")" options:NSBackwardsSearch];
        responseString = [responseString substringToIndex:tail.location];

        // TODO: handle serialization errors
        data = [NSJSONSerialization JSONObjectWithData:[responseString dataUsingEncoding:NSUTF8StringEncoding]
                                               options:0
                                                 error:nil];
    }

    return data;
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

#pragma mark - model operations

- (void)updateModel:(FlickrCarouselModel *)carouselModel withResponse:(id)response fromURI:(NSString *const)URI {
    if ([self isSuccessfulResponse:response]) {

        NSDictionary *validResponse = response;
        NSArray *photos = validResponse[@"photos"][@"photo"];
        NSMutableArray *validPhotos = [NSMutableArray arrayWithCapacity:photos.count];
        NSDictionary *validMeta;
        NSString *imageId;

        for (NSDictionary *photoMeta in photos) {
            validMeta = [self indexPhotoMeta:photoMeta];
            [validPhotos addObject:validMeta];
            imageId = validMeta[@"photoId"];

            // prefetch image previews
            if (validPhotos.count < MAX_PREVIEW_PREFETCH) {
                [self prefetchPreviewWithId:imageId];
            }

            // prefetch the first full image
            if (!validPhotos.count) {
                [self prefetchImageWithId:imageId];
            }
        }

        carouselModel.photos = validPhotos;
    } else {
        // TODO: Error handling to be implemented
    }
}

# pragma mark - indexing and caching operations

- (NSDictionary *)indexPhotoMeta:(NSDictionary *)photoMeta {
    NSMutableDictionary *meta = [photoMeta mutableCopy];
    NSString *photoId = [self photoIdFromMeta:meta];
    meta[@"photoId"] = photoId;
    self.imageMetaCache[photoId] = meta;
    return meta;
}

- (NSString *)photoIdFromMeta:(NSDictionary *)photoMeta {
    return [NSString stringWithFormat:@"%@_%@", photoMeta[@"id"], photoMeta[@"secret"]];
}

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
