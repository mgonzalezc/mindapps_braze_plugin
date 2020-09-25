#import <Flutter/Flutter.h>

@class ABKInAppMessage;
@class ABKContentCard;

@interface BrazePlugin : NSObject<FlutterPlugin>

+ (void)processInAppMessage:(ABKInAppMessage *)inAppMessage;

+ (void)processContentCards:(NSArray<ABKContentCard *> *)cards;

@end
