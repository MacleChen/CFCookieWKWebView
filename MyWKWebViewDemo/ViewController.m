//
//  ViewController.m
//  MyWKWebViewDemo
//
//  Created by 陈帆 on 2019/10/9.
//  Copyright © 2019 陈帆. All rights reserved.
//

#import "ViewController.h"
#import <WebKit/WebKit.h>

#import "HWCookiesManager.h"

@interface ViewController () <WKUIDelegate, WKNavigationDelegate>

@property (strong, nonatomic) WKWebView *webView;
@property (strong, nonatomic) WKWebViewConfiguration *webConfig;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.webView.UIDelegate = self;
    self.webView.navigationDelegate = self;
     NSString *string = @"/oauth2/v2/authorize?access_type=offline&response_type=code&client_id=100253825&lang=zh-cn&redirect_uri=hms%3A%2F%2Fredirect_url&scope=https%3A%2F%2Fwww.huawei.com%2Fauth%2Faccount%2Fbase.profile+https%3A%2F%2Fsmarthome.com%2Fauth%2Fsmarthome%2Fskill+https%3A%2F%2Fsmarthome.com%2Fauth%2Fsmarthome%2Fdevices&state=state&display=mobile";
    NSArray *cookiesArray = [HWCookiesManager updateCookies:self.webView];
    
    NSString *string2 = [NSString stringWithFormat:@"https://login.vmall.com%@",string];
    
    //request首次携带Cookie
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:string2]];
    
    for (NSHTTPCookie *cookie in cookiesArray) {
        NSDictionary *cookieDict = [cookie dictionaryWithValuesForKeys:@[NSHTTPCookieName,
                                                                         NSHTTPCookieValue,
                                                                         NSHTTPCookieDomain,
                                                                         NSHTTPCookiePath]];
        NSString *cookieStr = @"";
        for (NSString *cookieKey in cookieDict.allKeys) {
            NSString *keyValue = [NSString stringWithFormat:@"%@=%@;",cookieKey,[cookieDict objectForKey:cookieKey]];
            cookieStr = [cookieStr stringByAppendingString:keyValue];
        }
        // cookie 写入request
        [request addValue:cookieStr forHTTPHeaderField:@"Cookie"];
    }

    // 跨域Cookie注入
    NSDictionary *cookieNewDict = [request allHTTPHeaderFields];
    NSString *cookieNewStr = [NSString stringWithFormat:@"document.cookie = '%@';", [cookieNewDict objectForKey:@"Cookie"]];
    WKUserContentController* userContentController = WKUserContentController.new;
    WKUserScript *cookieInScript = [[WKUserScript alloc] initWithSource:cookieNewStr
                                                              injectionTime:WKUserScriptInjectionTimeAtDocumentStart
                                                           forMainFrameOnly:NO];
    [userContentController addUserScript:cookieInScript];
    self.webView.configuration.userContentController = userContentController;
    
    // 延迟再次更新Cookie
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [HWCookiesManager updateCookies:self.webView];
        [self.webView loadRequest:request];
    });
}

- (IBAction)leftBarBtnClick:(UIBarButtonItem *)sender {
    [self.webView goBack];
}

- (IBAction)rightBarBtnClick:(UIBarButtonItem *)sender {
    [self.webView goForward];
}



- (WKWebView *)webView {
    if (!_webView) {
        _webView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:self.webConfig];
        [self.view addSubview:self.webView];
    }
    
    return _webView;
}

- (WKWebViewConfiguration *)webConfig {
    if (!_webConfig) {
        _webConfig = [[WKWebViewConfiguration alloc] init];
    }
    return _webConfig;
}


#pragma mark - WKNavigationDelegate

// MARK: 页面开始加载时调用
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation{
    NSLog(@"页面开始加载");
}

// MARK: 内容开始加载
- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation {
    NSLog(@"内容开始加载");
}

// MARK: 页面加载完成之后调用
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation{
    NSLog(@"加载完成");
}

// MARK: 页面加载出错
- (void)webView:(WKWebView *)webView didFailLoadWithError:(nonnull NSError *)error {
    NSLog(@"error:%@",error);
}

// MARK: 页面加载失败时调用
- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error{
    NSLog(@"加载失败");
    if (error.code == 101 || error.code == 102 || error.code == NSURLErrorUnsupportedURL || error.code == NSURLErrorServerCertificateUntrusted || error.code == NSURLErrorCancelled) {
        return ;
    }
}

// MARK: 根据WebView对于即将跳转的HTTP请求头信息和相关信息来决定是否跳转
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler{
    NSLog(@"重定向%@", webView.URL.host);
    // 如果是跳转一个新页面
    if ([navigationAction.request.URL.absoluteString containsString:@"authorization_code"]) {
        NSLog(@"重定向到 redirect_url 成功");
        NSString *code = [navigationAction.request.URL.query componentsSeparatedByString:@"="][1];
        NSRange range = [code rangeOfString:@"&state"];
        if (range.length == 0) {
            NSLog(@"%@", [NSString stringWithFormat:@"重定向到 redirect_url 失败: %@",navigationAction.request.URL]);
            decisionHandler(WKNavigationActionPolicyAllow);
            return;
        }
        NSString *subCode = [code substringToIndex:range.location];
        NSString *authCode = [subCode stringByRemovingPercentEncoding];
        [self handleAuthCode:authCode withWebView:webView];
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}

/** 处理 AuthCode 授权码 */
- (void)handleAuthCode:(NSString *)authCode withWebView:(WKWebView *)webView {
    NSLog(@"Success: %@", authCode);
    [HWCookiesManager saveCookies:self.webView handle:nil];
}

@end
