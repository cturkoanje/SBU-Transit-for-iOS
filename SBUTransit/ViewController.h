//
//  ViewController.h
//  SBUTransit
//
//  Created by Chrstian Turkoanje on 5/21/13.
//  Copyright (c) 2013 Christian Turkoanje. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GoogleMaps/GoogleMaps.h>
#import "JCGridMenuController.h"
#import "MBHUDView.h"
#import "MBAlertView.h"
#import "MBFlatAlertView.h"


@interface ViewController : UIViewController
{
    IBOutlet UIView *mapViewOnScreen;
}

@property (nonatomic, strong) JCGridMenuController *gmDemo;
@property (nonatomic, assign) BOOL menuIsVisible;


@end
