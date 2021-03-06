#import "BrazePlugin.h"
#import "AppboyKit.h"
#import "ABKContentCardsViewController.h"

@implementation BrazePlugin

FlutterMethodChannel *_channel;

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  _channel = [FlutterMethodChannel
                                   methodChannelWithName:@"braze_plugin"
                                   binaryMessenger:[registrar messenger]];
  [_channel setMethodCallHandler:^(FlutterMethodCall *call, FlutterResult result) {
    NSString *method = [call method];
    NSDictionary *arguments = [call arguments];

    if ([method isEqualToString:@"changeUser"]) {
      NSString *userId = arguments[@"userId"];
      [[Appboy sharedInstance] changeUser:userId];
      result(nil);
    } else if ([method isEqualToString:@"getInstallTrackingId"]) {
      NSString *deviceId = [[Appboy sharedInstance] getDeviceId];
      result(deviceId);
    } else if ([method isEqualToString:@"requestContentCardsRefresh"]) {
      [[Appboy sharedInstance] requestContentCardsRefresh];
      result(nil);
    } else if ([method isEqualToString:@"launchContentCards"]) {
      ABKContentCardsViewController *contentCardsModal = [[ABKContentCardsViewController alloc] init];
      contentCardsModal.navigationItem.title = @"Content Cards";
      UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
      UIViewController *mainViewController = keyWindow.rootViewController;
      [mainViewController presentViewController:contentCardsModal animated:YES completion:nil];
      result(nil);
    } else if ([method isEqualToString:@"logContentCardClicked"]) {
      NSString *contentCardJSONString = arguments[@"contentCardString"];
      ABKContentCard *contentCard = [[ABKContentCard alloc] init];
      [BrazePlugin getContentCardFromString:contentCardJSONString withContentCard:contentCard];
      [contentCard logContentCardClicked];
      result(nil);
    } else if ([method isEqualToString:@"logContentCardDismissed"]) {
      NSString *contentCardJSONString = arguments[@"contentCardString"];
      ABKContentCard *contentCard = [[ABKContentCard alloc] init];
      [BrazePlugin getContentCardFromString:contentCardJSONString withContentCard:contentCard];
      [contentCard logContentCardDismissed];
      result(nil);
    } else if ([method isEqualToString:@"logContentCardImpression"]) {
      NSString *contentCardJSONString = arguments[@"contentCardString"];
      ABKContentCard *contentCard = [[ABKContentCard alloc] init];
      [BrazePlugin getContentCardFromString:contentCardJSONString withContentCard:contentCard];
      [contentCard logContentCardImpression];
      result(nil);
    } else if ([method isEqualToString:@"logInAppMessageClicked"]) {
      NSString *inAppMessageJSONString = arguments[@"inAppMessageString"];
      ABKInAppMessage *inAppMessage = [[ABKInAppMessage alloc] init];
      [BrazePlugin getInAppMessageFromString:inAppMessageJSONString withInAppMessage:inAppMessage];
      [inAppMessage logInAppMessageClicked];
      result(nil);
    } else if ([method isEqualToString:@"logInAppMessageImpression"]) {
      NSString *inAppMessageJSONString = arguments[@"inAppMessageString"];
      ABKInAppMessage *inAppMessage = [[ABKInAppMessage alloc] init];
      [BrazePlugin getInAppMessageFromString:inAppMessageJSONString withInAppMessage:inAppMessage];
      [inAppMessage logInAppMessageImpression];
      result(nil);
    } else if ([method isEqualToString:@"logInAppMessageButtonClicked"]) {
      NSString *inAppMessageJSONString = arguments[@"inAppMessageString"];
      NSNumber *idNumber = arguments[@"buttonId"];
      ABKInAppMessageImmersive *inAppMessageImmersive = [[ABKInAppMessageImmersive alloc] init];
      [self getInAppMessageFromString:inAppMessageJSONString withInAppMessage:inAppMessageImmersive];
      [inAppMessageImmersive logInAppMessageClickedWithButtonID:[idNumber intValue]];
      result(nil);
    } else if ([method isEqualToString:@"addAlias"]) {
      NSString *aliasName = arguments[@"aliasName"];
      NSString *aliasLabel = arguments[@"aliasLabel"];
      [[Appboy sharedInstance].user addAlias:aliasName withLabel:aliasLabel];
      result(nil);
    } else if ([method isEqualToString:@"logCustomEvent"] || [method isEqualToString:@"logCustomEventWithProperties"]) {
      NSString *eventName = arguments[@"eventName"];
      NSDictionary *properties = arguments[@"properties"];
      [Appboy sharedInstance].sdkFlavor = FLUTTER;
      [[Appboy sharedInstance] logCustomEvent:eventName withProperties:properties];
      result(nil);
    } else if ([method isEqualToString:@"logPurchase"] || [method isEqualToString:@"logCustomEventWithProperties"]) {
     NSString *productId = arguments[@"productId"];
     NSString *currencyCode = arguments[@"currencyCode"];
     NSNumber *priceNumber = arguments[@"price"];
     NSDecimalNumber *price = [NSDecimalNumber decimalNumberWithDecimal:[priceNumber decimalValue]];
     NSNumber *quantity = arguments[@"quantity"];
     NSDictionary *properties = arguments[@"properties"];
     [[Appboy sharedInstance] logPurchase:productId inCurrency:currencyCode atPrice:price withQuantity:quantity.unsignedIntValue andProperties:properties];
      result(nil);
    } else if ([method isEqualToString:@"setFirstName"]) {
      NSString *firstName = arguments[@"firstName"];
      [Appboy sharedInstance].user.firstName = firstName;
      result(nil);
    } else if ([method isEqualToString:@"setLastName"]) {
      NSString *lastName = arguments[@"lastName"];
      [Appboy sharedInstance].user.lastName = lastName;
      result(nil);
    } else if ([method isEqualToString:@"setLanguage"]) {
      NSString *language = arguments[@"language"];
      [Appboy sharedInstance].user.language = language;
      result(nil);
    } else if ([method isEqualToString:@"setCountry"]) {
      NSString *country = arguments[@"country"];
      [Appboy sharedInstance].user.country = country;
      result(nil);
    } else if ([method isEqualToString:@"setGender"]) {
      NSString *gender = arguments[@"gender"];
      [BrazePlugin setGender:gender];
      result(nil);
    } else if ([method isEqualToString:@"setHomeCity"]) {
      NSString *homeCity = arguments[@"homeCity"];
      [Appboy sharedInstance].user.homeCity = homeCity;
      result(nil);
    } else if ([method isEqualToString:@"setDateOfBirth"]) {
      NSCalendar *calendar = [NSCalendar currentCalendar];
      NSDateComponents *components = [[NSDateComponents alloc] init];
      NSNumber *day = arguments[@"day"];
      NSNumber *month = arguments[@"month"];
      NSNumber *year = arguments[@"year"];
      [components setDay:day.intValue];
      [components setMonth:month.intValue];
      [components setYear:year.intValue];
      NSDate *dateOfBirth = [calendar dateFromComponents:components];
      [Appboy sharedInstance].user.dateOfBirth = dateOfBirth;
      result(nil);
    } else if ([method isEqualToString:@"setEmail"]) {
      NSString *email = arguments[@"email"];
      [Appboy sharedInstance].user.email = email;
      result(nil);
    } else if ([method isEqualToString:@"setPhoneNumber"]) {
      NSString *phoneNumber = arguments[@"phoneNumber"];
      [Appboy sharedInstance].user.phone = phoneNumber;
      result(nil);
    } else if ([method isEqualToString:@"setAvatarImageUrl"]) {
      NSString *avatarImageUrl = arguments[@"avatarImageUrl"];
      [Appboy sharedInstance].user.avatarImageURL = avatarImageUrl;
      result(nil);
    } else if ([method isEqualToString:@"setPushNotificationSubscriptionType"]) {
      NSString *type = arguments[@"type"];
      ABKNotificationSubscriptionType pushNotificationSubscriptionType = [BrazePlugin getSubscriptionType:type];
      [Appboy sharedInstance].user.pushNotificationSubscriptionType = pushNotificationSubscriptionType;
      result(nil);
    } else if ([method isEqualToString:@"setEmailNotificationSubscriptionType"]) {
      NSString *type = arguments[@"type"];
      ABKNotificationSubscriptionType emailNotificationSubscriptionType = [BrazePlugin getSubscriptionType:type];
      [Appboy sharedInstance].user.emailNotificationSubscriptionType = emailNotificationSubscriptionType;
      result(nil);
    } else if ([method isEqualToString:@"setStringCustomUserAttribute"]) {
      NSString *key = arguments[@"key"];
      NSString *value = arguments[@"value"];
      [[Appboy sharedInstance].user setCustomAttributeWithKey:key andStringValue:value];
      result(nil);
    } else if ([method isEqualToString:@"setIntCustomUserAttribute"]) {
      NSString *key = arguments[@"key"];
      NSNumber *value = arguments[@"value"];
      [[Appboy sharedInstance].user setCustomAttributeWithKey:key andIntegerValue:value.intValue];
      result(nil);
    } else if ([method isEqualToString:@"setDoubleCustomUserAttribute"]) {
      NSString *key = arguments[@"key"];
      NSNumber *value = arguments[@"value"];
      [[Appboy sharedInstance].user setCustomAttributeWithKey:key andDoubleValue:value.doubleValue];
      result(nil);
    } else if ([method isEqualToString:@"setBoolCustomUserAttribute"]) {
      NSString *key = arguments[@"key"];
      BOOL value = [arguments[@"value"] boolValue];
      [[Appboy sharedInstance].user setCustomAttributeWithKey:key andBOOLValue:value];
      result(nil);
    } else if ([method isEqualToString:@"setDateCustomUserAttribute"]) {
      NSString *key = arguments[@"key"];
      NSNumber *value = arguments[@"value"];
      NSDate *date = [NSDate dateWithTimeIntervalSince1970:value.doubleValue];
      [[Appboy sharedInstance].user setCustomAttributeWithKey:key andDateValue:date];
      result(nil);
    } else if ([method isEqualToString:@"setLocationCustomAttribute"]) {
      NSString *key = arguments[@"key"];
      NSNumber *lat = arguments[@"lat"];
      NSNumber *longitude = arguments[@"long"];
      [[Appboy sharedInstance].user addLocationCustomAttributeWithKey:key latitude:lat.doubleValue longitude:longitude.doubleValue];
      result(nil);
    } else if ([method isEqualToString:@"addToCustomAttributeArray"]) {
      NSString *key = arguments[@"key"];
      NSString *value = arguments[@"value"];
      [[Appboy sharedInstance].user addToCustomAttributeArrayWithKey:key value:value];
      result(nil);
    } else if ([method isEqualToString:@"removeFromCustomAttributeArray"]) {
      NSString *key = arguments[@"key"];
      NSString *value = arguments[@"value"];
      [[Appboy sharedInstance].user removeFromCustomAttributeArrayWithKey:key value:value];
      result(nil);
    } else if ([method isEqualToString:@"incrementCustomUserAttribute"]) {
      NSString *key = arguments[@"key"];
      NSNumber *value = arguments[@"value"];
      [[Appboy sharedInstance].user incrementCustomUserAttribute:key by:value.intValue];
      result(nil);
    } else if ([method isEqualToString:@"unsetCustomUserAttribute"]) {
      NSString *key = arguments[@"key"];
      [[Appboy sharedInstance].user unsetCustomAttributeWithKey:key];
      result(nil);
    } else if ([method isEqualToString:@"registerAndroidPushToken"]) {
      // This is an Android only feature, do nothing.
    } else if ([method isEqualToString:@"requestImmediateDataFlush"]) {
      [[Appboy sharedInstance] flushDataAndProcessRequestQueue];
      result(nil);
    } else if ([method isEqualToString:@"setAttributionData"]) {
      NSString *network = arguments[@"network"];
      NSString *campaign = arguments[@"campaign"];
      NSString *adGroup = arguments[@"adGroup"];
      NSString *creative = arguments[@"creative"];
      ABKAttributionData *attributionData = [[ABKAttributionData alloc]
                                         initWithNetwork:network
                                         campaign:campaign
                                         adGroup:adGroup
                                         creative:creative];
      [[Appboy sharedInstance].user setAttributionData:attributionData];
      result(nil);
    } else if ([method isEqualToString:@"wipeData"]) {
      [Appboy wipeDataAndDisableForAppRun];
      result(nil);
    } else if ([method isEqualToString:@"requestLocationInitialization"]) {
      // This is an Android only feature, do nothing.
    } else if ([method isEqualToString:@"enableSDK"]) {
      [Appboy requestEnableSDKOnNextAppRun];
      result(nil);
    } else if ([method isEqualToString:@"disableSDK"]) {
      [Appboy disableSDK];
      result(nil);
    } else {
      result(FlutterMethodNotImplemented);
    }
  }];
}

+ (void) getInAppMessageFromString:(NSString *)inAppMessageJSONString withInAppMessage:(ABKInAppMessage *)inAppMessage {
  NSData *inAppMessageData = [inAppMessageJSONString dataUsingEncoding:NSUTF8StringEncoding];
  NSError *e = nil;
  id deserializedInAppMessageDict = [NSJSONSerialization JSONObjectWithData:inAppMessageData options:NSJSONReadingMutableContainers error:&e];
  [inAppMessage setValuesForKeysWithDictionary:deserializedInAppMessageDict];
}

+ (void) getContentCardFromString:(NSString *)contentCardJSONString withContentCard:(ABKContentCard *)contentCard {
  NSData *contentCardData = [contentCardJSONString dataUsingEncoding:NSUTF8StringEncoding];
  NSError *e = nil;
  id deserializedContentCardDict = [NSJSONSerialization JSONObjectWithData:contentCardData options:NSJSONReadingMutableContainers error:&e];
  [contentCard setValuesForKeysWithDictionary:deserializedContentCardDict];
}

+ (ABKNotificationSubscriptionType)getSubscriptionType:(NSString *)subscriptionValue {
  if ([subscriptionValue isEqualToString:@"SubscriptionType.unsubscribed"]) {
    return ABKUnsubscribed;
  } else if ([subscriptionValue isEqualToString:@"SubscriptionType.subscribed"]) {
    return ABKSubscribed;
  } else if ([subscriptionValue isEqualToString:@"SubscriptionType.opted_in"]) {
    return ABKOptedIn;
  } else {
    return ABKUnsubscribed;
  }
}

+ (void)processInAppMessage:(ABKInAppMessage *)inAppMessage {
  NSData *inAppMessageData = [inAppMessage serializeToData];
  NSString *inAppMessageString = [[NSString alloc] initWithData:inAppMessageData encoding:NSUTF8StringEncoding];
  NSDictionary *arguments = @{
    @"inAppMessage" : inAppMessageString
  };
  [_channel invokeMethod:@"handleBrazeInAppMessage" arguments:arguments];
}

+ (void)processContentCards:(NSArray<ABKContentCard *> *)cards {
  NSMutableArray *cardStrings = [NSMutableArray array];
  for (int i = 0; i < [cards count]; i++) {
    ABKContentCard *card = cards[i];
    NSData *cardData = [card serializeToData];
    NSString *cardString = [[NSString alloc] initWithData:cardData encoding:NSUTF8StringEncoding];
    [cardStrings addObject:cardString];
  }
  NSDictionary *arguments = @{
    @"contentCards" : cardStrings
  };
  [_channel invokeMethod:@"handleBrazeContentCards" arguments:arguments];
}

+ (void)setGender:(NSString *)gender {
  if ([[gender capitalizedString] hasPrefix:@"F"]) {
    [[Appboy sharedInstance].user setGender:ABKUserGenderFemale];
  } else if ([[gender capitalizedString] hasPrefix:@"M"]) {
      [[Appboy sharedInstance].user setGender:ABKUserGenderMale];
  } else if ([[gender capitalizedString] hasPrefix:@"N"]) {
      [[Appboy sharedInstance].user setGender:ABKUserGenderNotApplicable];
  } else if ([[gender capitalizedString] hasPrefix:@"O"]) {
      [[Appboy sharedInstance].user setGender:ABKUserGenderOther];
  } else if ([[gender capitalizedString] hasPrefix:@"P"]) {
      [[Appboy sharedInstance].user setGender:ABKUserGenderPreferNotToSay];
  } else if ([[gender capitalizedString] hasPrefix:@"U"]) {
      [[Appboy sharedInstance].user setGender:ABKUserGenderUnknown];
  }
}

@end
