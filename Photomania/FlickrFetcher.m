//
//  FlickrFetcher.m
//
//  Created for Stanford CS193p Fall 2013.
//  Copyright 2013 Stanford University. All rights reserved.
//

#import "FlickrFetcher.h"
#import "FlickrAPIKey.h"

@implementation FlickrFetcher

+ (NSURL *)URLForQuery:(NSString *)query
{
    query = [NSString stringWithFormat:@"%@&nojsoncallback=1&api_key=%@&format=json", query, FlickrAPIKey];
    query = [query stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return [NSURL URLWithString:query];
}

+ (NSURL *)URLforTopPlaces

{
    return [self URLForQuery:@"https://api.flickr.com/services/rest/?method=flickr.places.getTopPlacesList&place_type_id=7"];
}


+ (NSURL *)URLforRecentGeoreferencedPhotos;
{
    return [self URLForQuery:[NSString stringWithFormat:@"https://api.flickr.com/services/rest/?method=flickr.photos.search&license=1,2,4,7&has_geo=1&extras=original_format,description,geo,date_upload,owner_name"]];
}

+ (NSString *)urlStringForPhoto:(NSDictionary *)photo format:(FlickrPhotoFormat)format
{
    id farm = [photo objectForKey:@"farm"];
    id server = [photo objectForKey:@"server"];
    id photo_id = [photo objectForKey:@"id"];
    id secret = [photo objectForKey:@"secret"];
    if (format == FlickrPhotoFormatOriginal) secret = [photo objectForKey:@"originalsecret"];
    
    NSString *fileType = @"jpg";
    if (format == FlickrPhotoFormatOriginal) fileType = [photo objectForKey:@"originalformat"];
    
    if (!farm || !server || !photo_id || !secret) return nil;
    
    NSString *formatString = @"s";
    switch (format) {
        case FlickrPhotoFormatSquare:    formatString = @"s"; break;
        case FlickrPhotoFormatLarge:     formatString = @"b"; break;
        case FlickrPhotoFormatOriginal:  formatString = @"o"; break;
    }
    
    return [NSString stringWithFormat:@"https://farm%@.static.flickr.com/%@/%@_%@_%@.%@", farm, server, photo_id, secret, formatString, fileType];
}

+ (NSURL *)URLforPhoto:(NSDictionary *)photo format:(FlickrPhotoFormat)format;
{
    return [NSURL URLWithString:[self urlStringForPhoto:photo format:format]];
}

#define FLICKR_PLACE_NEIGHBORHOOD_NAME @"place.neighbourhood._content"
#define FLICKR_PLACE_NEIGHBORHOOD_PLACE_ID @"place.neighbourhood.place_id"
#define FLICKR_PLACE_LOCALITY_NAME @"place.locality._content"
#define FLICKR_PLACE_LOCALITY_PLACE_ID @"place.locality.place_id"
#define FLICKR_PLACE_REGION_NAME @"place.region._content"
#define FLICKR_PLACE_REGION_PLACE_ID @"place.region.place_id"
#define FLICKR_PLACE_COUNTY_NAME @"place.county._content"
#define FLICKR_PLACE_COUNTY_PLACE_ID @"place.county.place_id"
#define FLICKR_PLACE_COUNTRY_NAME @"place.country._content"
#define FLICKR_PLACE_COUNTRY_PLACE_ID @"place.country.place_id"
#define FLICKR_PLACE_REGION @"place.region"

@end