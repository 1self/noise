//
//  UIAlertView+additions.m
//  noise
//
//  Created by Edward Sykes on 04/11/2014.
//  Copyright (c) 2014 Syed Haris Ali. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "UIAlertView+Additions.h"

#import <objc/runtime.h>

@implementation UIAlertView (Additions)

static const char *HANDLER_KEY = "com.mattrajca.alertview.handler";

+ (void)presentWithTitle:(NSString *)title
                 message:(NSString *)message
                 buttons:(NSArray *)buttons
           buttonHandler:(void (^)(NSUInteger))handler {
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:nil
                                          otherButtonTitles:nil];
    
    [alert setDelegate:alert];
    
    [buttons enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [alert addButtonWithTitle:obj];
    }];
    
    if (handler)
        objc_setAssociatedObject(alert, HANDLER_KEY, handler, OBJC_ASSOCIATION_COPY_NONATOMIC);
    
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    id handler = objc_getAssociatedObject(alertView, HANDLER_KEY);
    
    if (handler)
        ((void(^)())handler)(buttonIndex);
}

@end