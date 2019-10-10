//
//  HWCookiesManager.h
//  SpeakerNetworkConfig
//
//  Created by wenming liu on 2019/8/31.
//  Copyright © 2019年 wenming liu. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WKWebView;
@interface HWCookiesManager : NSObject



+ (void)saveCookies:(WKWebView *)webView handle:(void (^)(BOOL isSuccessful))saveResponse;

/**
 更新cookies

 @param webView WKWebView
 */
+ (NSArray *)updateCookies:(WKWebView *)webView;
@end

