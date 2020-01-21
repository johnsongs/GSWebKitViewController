//
//  GSWebKitViewController.m
//  DispenserClient
//
//  Created by Johnson on 2018/8/15.
//  Copyright © 2018年 ios. All rights reserved.
//

#import "GSWebKitViewController.h"
#import "GSWebKitPostUrlBySession.h"

@interface GSWebKitViewController () <WKScriptMessageHandler>

@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, strong) WKWebViewConfiguration *webViewConfiguration;

@property (nonatomic, strong) NSMutableDictionary *recieveScriptBlock; //js调用原生接口

@property (nonatomic, assign) BOOL startLoadUrl;

@property (nonatomic, strong) NSMutableDictionary *alreadyRecieveScript;

//发起请求链接
- (void)loadRequestUrl:(NSURL *)url;
//显示进度条
- (void)showProgress:(BOOL)progress;

@end

@implementation GSWebKitViewController

//子类化时可使用init初始化，将url放到相应子类中，子类需实现-initWebKitWithUrl:showProgress:方法
- (instancetype)init {
    return [self initWebKitShowProgress:NO];
}

- (instancetype)initWebKitShowProgress:(BOOL)show {
    self = [super init];
    if (self) {
        _showProgress = show;
        self.navigationBarStyle = GSNavigationBarStyleDefault;
        [self showProgress:_showProgress];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setNavigationTool];
    for (NSString *key in self.alreadyRecieveScript.allKeys) {
        if (!self.recieveScriptBlock[key]) {
            [self.webView.configuration.userContentController addScriptMessageHandler:self name:key];
            [self.recieveScriptBlock setObject:self.alreadyRecieveScript[key] forKey:key];
        }
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    for (NSString *key in self.recieveScriptBlock.allKeys) {
        [self.webView.configuration.userContentController removeScriptMessageHandlerForName:key];
        [self.recieveScriptBlock removeObjectForKey:key];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.startLoadUrl = NO;
    self.webView.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame));
    // Do any additional setup after loading the view.
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.webView.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame));
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    if(_webView) {
        [_webView removeObserver:self forKeyPath:@"estimatedProgress"];
        [_webView.configuration.userContentController removeAllUserScripts];
    }
}

- (void)reloadWebRequest {
    [self.webView reload];
}

- (void)loadRequestUrl:(NSURL *)url {
    self.url = url;
    [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
}

- (void)loadRequest:(NSURLRequest *)request {
    self.startLoadUrl = YES;
    self.url = request.URL;
    if ([request.HTTPMethod isEqualToString:@"POST"]) {
        NSMutableURLRequest *tmpRequest = [request mutableCopy];
        [tmpRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        if ([[UIDevice currentDevice].systemVersion integerValue] < 11) {
            [GSWebKitPostUrlBySession POST:request handler:^(NSURLSessionTask * _Nonnull task, id  _Nonnull response, NSError * _Nonnull error) {
                
                /**
                 因WebKit的Cookie与系统存储的Cookie不通用，所以需要将通过请求接收到的response中的Set-Cookie
                 应答头，添加到WebKit当前加载的页面中。
                 [self.webView.configuration.userContentController addUserScript:cookieScript];
                 */
                NSString *setCookie = [self getCurrentCookie:task.currentRequest];
                WKUserScript *cookieScript = [[WKUserScript alloc] initWithSource:setCookie injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
                [self.webView.configuration.userContentController addUserScript:cookieScript];
                
                [self.webView loadHTMLString:response baseURL:request.URL];
            }];
        }else {
            [self.webView loadRequest:tmpRequest];
        }
    }else {
        [self.webView loadRequest:request];
    }
}

- (void)showProgress:(BOOL)progress {
    self.showProgress = progress;
}

- (UIProgressView *)progressView {
    if (!_progressView) {
        _progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
        _progressView.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.frame), 5);
        [self.view addSubview:_progressView];
    }
    return _progressView;
}

- (void)setNavigationTool {
    if (self.navigationBarStyle == GSNavigationBarStyleDefault) {
        NSBundle *bundle = [NSBundle bundleForClass:[GSWebKitViewController class]];
        NSString *path = [bundle pathForResource:@"GSWebKitViewController" ofType:@"bundle"];
        NSBundle *imageBundle = [NSBundle bundleWithPath:path];
        
        UIImage *backImage = [[UIImage imageNamed:@"rrswebkit_back" inBundle:imageBundle compatibleWithTraitCollection:nil] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        
        UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithImage:backImage style:UIBarButtonItemStylePlain target:self action:@selector(goBackEvent:)];
        [backItem setImageInsets:UIEdgeInsetsMake(0, -8, 0, 0)];
        
        UIBarButtonItem *cancleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(cancleEvent:)];
        [cancleItem setImageInsets:UIEdgeInsetsMake(0, -28, 0, 0)];
        [self.navigationItem setLeftBarButtonItems:@[backItem, cancleItem]];
    }else {
        [self setNavigationBar];
    }
}

- (void)setNavigationBar {
    NSAssert(NO, @"需在子类中实现该方法");
}

- (void)goBackEvent:(UIButton *)button {
    if (_webView.backForwardList.backItem) {
        [_webView goBack];
    }else {
        [self popViewController];
    }
}

- (void)cancleEvent:(UIButton *)button {
    [self popViewController];
    
//    [self.webView.configuration.userContentController removeAllUserScripts];

}

- (void)popViewController {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)setUrl:(NSURL *)url {
    _url = url;
}

- (void)setShowProgress:(BOOL)showProgress {
    _showProgress = showProgress;
//    [self showProgress:_showProgress];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"estimatedProgress"]) {
        float progress = [change[NSKeyValueChangeNewKey] floatValue];
        if (self.progressView && progress < 1 && self.showProgress) {
            self.progressView.progress = progress;
            self.progressView.hidden = NO;
        }else if (!self.progressView || progress == 1){
            self.progressView.hidden = YES;
        }else {
            self.progressView.hidden = YES;
        }
    }
}

- (WKWebViewConfiguration *)webViewConfiguration {
    if (!_webViewConfiguration) {
        _webViewConfiguration = [[WKWebViewConfiguration alloc] init];
    }
    return _webViewConfiguration;
}

- (WKWebView *)webView {
    if (!_webView) {
        _webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:self.webViewConfiguration];
        _webView.navigationDelegate = self;
        [self.view addSubview:_webView];
        [_webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:nil];
    }
    
    return _webView;
}

- (void)webView:(WKWebView *)webView didCommitNavigation:(null_unspecified WKNavigation *)navigation {
    [self receiveData:webView];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation  {
    [self loadRequestFinish:webView];
}

- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(null_unspecified WKNavigation *)navigation {
    [self redirectRequest:webView];
}


- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(nonnull void (^)(WKNavigationActionPolicy))decisionHandler {
    decisionHandler([self webView:webView decidePolicyForNavigationAction:navigationAction]?WKNavigationActionPolicyAllow:WKNavigationActionPolicyCancel);
}


- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(nonnull WKNavigationResponse *)navigationResponse decisionHandler:(nonnull void (^)(WKNavigationResponsePolicy))decisionHandler {
    decisionHandler([self webView:webView decidePolicyForNavigationResponse:navigationResponse]?WKNavigationResponsePolicyAllow:WKNavigationResponsePolicyCancel);
}

#pragma mark - WKScriptMessageHandler
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if (self.recieveScriptBlock[message.name]) {
        void(^block)(WKScriptMessage *msg) = (void(^)(WKScriptMessage *msg))self.recieveScriptBlock[message.name];
        if (block) {
            block(message);
        }
    }
}

#pragma mark - Delegate
- (void)receiveData:(WKWebView *)webView {
    
}

- (void)loadRequestFinish:(WKWebView *)webView {
    
}

- (void)redirectRequest:(WKWebView *)webView {
    
}

- (BOOL)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction {
    return YES;
}

- (BOOL)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(nonnull WKNavigationResponse *)navigationResponse {
    return YES;
}

- (void)addJavaScript:(NSString *)scriptName complete:(void(^)(WKScriptMessage *msg))block {
    if (self.recieveScriptBlock[scriptName]) {
        [self.webView.configuration.userContentController removeScriptMessageHandlerForName:scriptName];
    }
    [self.recieveScriptBlock setObject:block forKey:scriptName];
    [self.webView.configuration.userContentController addScriptMessageHandler:self name:scriptName];
    [self.alreadyRecieveScript setObject:block forKey:scriptName];
}

- (void)sendJavaScript:(NSString *)scriptName complete:(void (^ _Nullable)(_Nullable id, NSError * _Nullable error))block {
    [self.webView evaluateJavaScript:scriptName completionHandler:block];
}

- (void)sendJavaScript:(NSString *)scriptName injectionTime:(GSUserScriptInjectionTime)injectionTime error:(NSError *__autoreleasing *)error {
    if (self.startLoadUrl) {
        *error = [NSError errorWithDomain:@"GSWebKitViewController" code:400 userInfo:@{NSLocalizedDescriptionKey:@"需要在调用URL之前调用该参数"}];
        return;
    }
    [self.webView.configuration.userContentController addUserScript:[self madeScriptWithJsMethod:scriptName injectionTime:injectionTime]];
}

- (NSString *)getCurrentCookie:(NSURLRequest *)request {
    NSMutableString *setCookie = [[NSMutableString alloc] init];
    NSArray <NSHTTPCookie *>*cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];
    for (NSHTTPCookie *cookie in cookies) {
        NSURL *url = request.URL;
        if ([cookie.domain isEqualToString:url.host] && ([url.path containsString:cookie.path] || [cookie.path isEqualToString:@"/"])) {
            if (!cookie.expiresDate) {
                [setCookie appendString:[NSString stringWithFormat:@"document.cookie='%@=%@';",cookie.name,cookie.value]];
            }else if ([cookie.expiresDate earlierDate:[NSDate date]] != cookie.expiresDate) {
                [setCookie appendString:[NSString stringWithFormat:@"document.cookie='%@=%@';",cookie.name,cookie.value]];
            }
        }
    }
    return setCookie;
}

- (NSMutableDictionary *)alreadyRecieveScript {
    if (!_alreadyRecieveScript) {
        _alreadyRecieveScript = [[NSMutableDictionary alloc] initWithCapacity:10];
    }
    return _alreadyRecieveScript;
}

- (NSMutableDictionary *)recieveScriptBlock {
    if (!_recieveScriptBlock) {
        _recieveScriptBlock = [[NSMutableDictionary alloc] init];
    }
    return _recieveScriptBlock;
}

static inline WKUserScriptInjectionTime GSInjectionTime(GSUserScriptInjectionTime injectionTime) {
    WKUserScriptInjectionTime wkInjection = WKUserScriptInjectionTimeAtDocumentStart;
    if (injectionTime == GSUserScriptInjectionTimeAtDocumentStart) {
        wkInjection = WKUserScriptInjectionTimeAtDocumentStart;
    }
    if (injectionTime == GSUserScriptInjectionTimeAtDocumentEnd) {
        wkInjection = WKUserScriptInjectionTimeAtDocumentEnd;
    }
    return wkInjection;
}

- (WKUserScript *)madeScriptWithJsMethod:(NSString *)js injectionTime:(GSUserScriptInjectionTime)injectionTime {
    return [[WKUserScript alloc] initWithSource:js injectionTime:GSInjectionTime(injectionTime) forMainFrameOnly:YES];
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
