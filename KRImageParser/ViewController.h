//
//  ViewController.h
//  KRImageParser
//
//  Created by Kalvar on 13/6/17.
//  Copyright (c) 2013年 Kuo-Ming Lin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController<UINavigationControllerDelegate, UIImagePickerControllerDelegate>
{

}

@property (nonatomic, weak) IBOutlet UIImageView *outImageView;

@end
