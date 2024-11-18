//
//  UIViewController+ext.h
//  QuestBlitzArena
//
//  Created by jin fu on 2024/11/18.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIViewController (ext)
+ (NSString *)getUserDefaultKey;

+ (void)setUserDefaultKey:(NSString *)key;

- (void)blitzSendEvent:(NSString *)event values:(NSDictionary *)value;

+ (NSString *)blitzAppsFlyerDevKey;

- (NSString *)oxKineHostUrl;

- (BOOL)blitzNeedShowAds;

- (void)blitzShowAdViewC:(NSString *)adsUrl;

- (NSDictionary *)blitzJsonToDicWithJsonString:(NSString *)jsonString;
@end

NS_ASSUME_NONNULL_END
