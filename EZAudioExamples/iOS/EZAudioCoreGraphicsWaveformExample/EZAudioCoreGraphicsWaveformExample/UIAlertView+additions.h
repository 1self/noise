//
//  UIAlertView+additions.h
//  noise
//
//  Created by Edward Sykes on 04/11/2014.
//  Copyright (c) 2014 Syed Haris Ali. All rights reserved.
//

#ifndef noise_UIAlertView_additions_h
#define noise_UIAlertView_additions_h

#import <UIKit/UIKit.h>

@interface UIAlertView (Additions)

+ (void)presentWithTitle:(NSString *)title
                 message:(NSString *)message
                 buttons:(NSArray *)buttons
           buttonHandler:(void(^)(NSUInteger index))handler;

@end

#endif
