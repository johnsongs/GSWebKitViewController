//
//  GSWebKitPostUrlBySession.h
//  Pods-GSWebKitViewController_Example
//
//  Created by Johnson on 2018/10/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^GSWebKitNetBlock)(NSURLSessionTask *task, id response, NSError *error);

@interface GSWebKitPostUrlBySession : NSObject

+ (void)POST:(NSURLRequest *)request handler:(GSWebKitNetBlock)handler;

@end

NS_ASSUME_NONNULL_END
