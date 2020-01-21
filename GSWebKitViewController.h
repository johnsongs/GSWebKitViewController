//
//  GSWebKitViewController.h
//  DispenserClient
//
//  Created by Johnson on 2018/8/15.
//  Copyright © 2018年 ios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

typedef NS_ENUM (NSInteger,GSNavigationBarStyle) {
    GSNavigationBarStyleDefault,     //默认
    GSNavigationBarStyleCustom       //自定义
};

typedef NS_ENUM(NSInteger, GSUserScriptInjectionTime) {
    GSUserScriptInjectionTimeAtDocumentStart,
    GSUserScriptInjectionTimeAtDocumentEnd
};

/**
 *子类化实现方法
 */
@protocol GSWebKitViewController

@optional

//网页加载完成
- (void)loadRequestFinish:(WKWebView *)webView;

//获取到数据，未开始加载
- (void)receiveData:(WKWebView *)webView;

//重定向
- (void)redirectRequest:(WKWebView *)webView;

//跳转-将要发起请求
- (BOOL)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction;
//跳转-接收到应答
- (BOOL)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(nonnull WKNavigationResponse *)navigationResponse;

@end

@interface GSWebKitViewController : UIViewController <GSWebKitViewController, WKNavigationDelegate>

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;

- (instancetype)initWebKitShowProgress:(BOOL)show;

- (void)reloadWebRequest;

/**
 加载URL

 @param url 调用URL
 */
- (void)loadRequestUrl:(NSURL *)url;


/**
 加载request
 用于定制request

 @param request 加载reques
 */
- (void)loadRequest:(NSURLRequest *)request;

@property (nonatomic, strong, readonly) NSURL *url;
@property (nonatomic, assign, readonly) BOOL showProgress; //默认值为NO不显示进度条
@property (nonatomic, assign) GSNavigationBarStyle navigationBarStyle; ///默认值为GSNavigationBarStyleDefault，当为GSNavigationBarStyleCustom时子类需实现-setNavigationBar

/**
 js调用原生接口
 eg：js调用window.webkit.messageHandlers.方法名对应(scriptName).postMessage(值，对应oc block中的WKScriptMessage类型对象);
 @param scriptName js调用原生接口的
 @param block 返回WKScriptMessage *对象
 */
- (void)addJavaScript:(NSString *)scriptName complete:(void(^)(WKScriptMessage *msg))block;

/**
 /// 调用js方法
 /// 调用该方法时需确保网页加载完成
 /// eg:sendMessage(value)
 
 @param scriptName js方法
 @param block 回传的数据
 */
- (void)sendJavaScript:(NSString *)scriptName complete:(void (^ _Nullable)(_Nullable id, NSError * _Nullable error))block;

- (void)sendJavaScript:(NSString *)scriptName injectionTime:(GSUserScriptInjectionTime)injectionTime error:(NSError **)error;

/**
 hook方法，当navigationBarStyle为GSNavigationBarStyleCustom才有效
 */
- (void)setNavigationBar;

@end
