//
//  ViewController.m
//  KRImageParser
//
//  Created by Kalvar on 13/6/17.
//  Copyright (c) 2013年 Kuo-Ming Lin. All rights reserved.
//

#import "ViewController.h"
#import "KRImageParser.h"

@interface ViewController ()

@property (nonatomic, assign) NSString *_photoPath;

@end

@implementation ViewController

@synthesize outImageView;
@synthesize _photoPath;

- (void)viewDidLoad
{
    [super viewDidLoad];
	self._photoPath = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
}

#pragma --mark Parsing Methods
-(void)parseMethod1
{
    //No Cache when parsed.
    [[KRImageParser sharedManager] parseOneImageNoCacheWithPath:self._photoPath
                                                 successHandler:^(UIImage *parsedImage) {
                                                     self.outImageView.image = parsedImage;
                                                 }];
}

-(void)parseMethod2
{
    //Scale the image.
    KRImageParser *_krImageParser = [[KRImageParser alloc] init];
    _krImageParser.needToScale = YES;
    _krImageParser.scaleWidth  = 100.0f;
    _krImageParser.scaleHeight = 100.0f;
    [_krImageParser parseOneImageWithPath:self._photoPath
                           successHandler:^(UIImage *parsedImage) {
                               self.outImageView.image = parsedImage;
                           } failureHandler:^(NSString *failedImageId) {
                               NSLog(@"Error Image ID : %@", failedImageId);
                           }];
}

-(void)parseMethod3
{
    //Capture the Video image.
    NSString *_videoPath = @"/var/sample.avi";
    [[KRImageParser sharedManager] parseOneImageWithPath:_videoPath
                                               mediaType:krImageParserMediaTypeIsMovie
                                              setImageId:@"1"
                                          successHandler:^(UIImage *parsedImage) {
                                              self.outImageView.image = parsedImage;
                                          } failureHandler:^(NSString *failedImageId) {
                                              //...
                                          }];
}

-(void)parseMethod4
{
    //To once parse more images.
    NSArray *_images1 = [NSArray arrayWithObjects:
                         @"assets-library://asset/asset.JPG?id=285699CD-1&ext=JPG",
                         krImageParserMediaTypeIsImage, nil];
    
    NSArray *_images2 = [NSArray arrayWithObjects:
                         @"assets-library://asset/asset.JPG?id=285699CD-20&ext=JPG",
                         krImageParserMediaTypeIsImage, nil];
    
    NSArray *_images3 = [NSArray arrayWithObjects:
                         @"assets-library://asset/asset.JPG?id=285699CD-3&ext=JPG",
                         krImageParserMediaTypeIsImage, nil];
    
    NSDictionary *_moreParses = [NSDictionary dictionaryWithObjectsAndKeys:
                                 _images1, @"1",
                                 _images2, @"2",
                                 _images3, @"3",
                                 nil];
    
    [[KRImageParser sharedManager] parseMoreImagesInfo:_moreParses];
}

#pragma --mark IBActions
-(IBAction)pickPhoto:(id)sender
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate   = self;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:picker animated:YES completion:nil];
}

#pragma UIImagePickerDelegate
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [picker dismissViewControllerAnimated:YES completion:nil];
    //self.outImageView.image = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    //NSURL needs convert to NSString to go parser.
    self._photoPath = [NSString stringWithFormat:@"%@", [info objectForKey:UIImagePickerControllerReferenceURL]];
    [self parseMethod1]; //It works
    //[self parseMethod2]; //It works
    //[self parseMethod3]; //It works
    //[self parseMethod4]; //It works
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

@end
