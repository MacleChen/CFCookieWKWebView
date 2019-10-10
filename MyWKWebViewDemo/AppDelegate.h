//
//  AppDelegate.h
//  MyWKWebViewDemo
//
//  Created by 陈帆 on 2019/10/9.
//  Copyright © 2019 陈帆. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong) NSPersistentContainer *persistentContainer;

- (void)saveContext;


@end

