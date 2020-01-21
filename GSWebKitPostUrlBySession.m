//
//  GSWebKitPostUrlBySession.m
//  Pods-GSWebKitViewController_Example
//
//  Created by Johnson on 2018/10/26.
//

#import "GSWebKitPostUrlBySession.h"

@interface GSWebKitPostUrlBySession () <NSURLSessionDataDelegate, NSURLSessionDelegate, NSURLSessionTaskDelegate>

@property (nonatomic, strong) NSURLSessionDataTask *task;
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSURLRequest *request;
@property (nonatomic, strong) NSMutableData *data;
@property (nonatomic, copy) GSWebKitNetBlock getResponse;

@end

@implementation GSWebKitPostUrlBySession

+ (void)POST:(NSURLRequest *)request handler:(GSWebKitNetBlock)handler {
    GSWebKitPostUrlBySession *postSession = [[GSWebKitPostUrlBySession alloc] init];
    postSession.request = request;
    postSession.getResponse = handler;
    [postSession connect];
}

- (void)connect {
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    _session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
    _task = [_session dataTaskWithRequest:_request];
    [_task resume];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
    self.data = [NSMutableData data];
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    [self.data appendData:data];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    NSString *string = [[NSString alloc]initWithData:_data encoding:NSUTF8StringEncoding];
    if (_getResponse) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.getResponse(self.task, string, error);
            [self.session finishTasksAndInvalidate];
        });
    }
}

@end
