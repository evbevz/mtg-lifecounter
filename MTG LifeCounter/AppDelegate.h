//
//  AppDelegate.h
//  MTG LifeCounter
//
//  Created by Mac on 05.10.11.
//  Copyright (c) 2021 Evgeny Bevz. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate>
{

    UINavigationController*     _navigationController;

}
@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) ViewController *viewController;

@end
