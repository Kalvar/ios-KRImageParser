//
//  KRImageParser.h
//  V1.0
//
//  Created by Kalvar ( ilovekalvar@gmail.com ) on 11/10/27.
//  Copyright 2013年 Kuo-Ming Lin. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString *krImageParserMediaTypeIsMovie = @"public.movie";
static NSString *krImageParserMediaTypeIsImage = @"public.image";

@protocol KRImageParserDelegate;

@interface KRImageParser : NSObject
{
    __weak id<KRImageParserDelegate> delegate;
    //儲存處理過後的圖片
    UIImage *parsedImage;
    //儲存處理過後的圖片陣列
    NSMutableDictionary *parsedImages;
    //儲存處理失敗的圖片陣列
    NSMutableArray *failedImages;
    //是否裁圖
    BOOL needToScale;
    //要取出完整圖檔 / 還是符合全螢幕呎吋圖檔即可 ?
    BOOL wantOrignalImage;
    //要裁圖的呎吋
    CGFloat scaleWidth;
    CGFloat scaleHeight;
}

@property (nonatomic, weak) id<KRImageParserDelegate> delegate;
@property (nonatomic, strong) UIImage *parsedImage;
@property (nonatomic, strong) NSMutableDictionary *parsedImages;
@property (nonatomic, strong) NSMutableArray *failedImages;
//
@property (nonatomic, assign) BOOL needToScale;
@property (nonatomic, assign) BOOL wantOrignalImage;
@property (nonatomic, assign) CGFloat scaleWidth;
@property (nonatomic, assign) CGFloat scaleHeight;

+(KRImageParser *)sharedManager;
-(void)parseMoreImagesInfo:(NSDictionary *)_needParses;
-(void)parseOneImageWithPath:(NSString *)_imagePath setImageId:(NSString *)_imageId isPhoto:(BOOL)_isPhoto;
-(void)parseOneImageWithPath:(NSString *)_imagePath isPhoto:(BOOL)_isPhoto;
-(void)parseOneImageWithPath:(NSString *)_imagePath;
-(void)parseOneImageWithPath:(NSString *)_imagePath
                   mediaType:(NSString *)_mediaType
                  setImageId:(NSString *)_imageId
              successHandler:( void (^)(UIImage *parsedImage) )_successHandler
              failureHandler:( void (^)(NSString *failedImageId) )_failureHandler;
-(void)parseOneImageWithPath:(NSString *)_imagePath
              successHandler:( void (^)(UIImage *parsedImage) )_successHandler
              failureHandler:( void (^)(NSString *failedImageId) )_failureHandler;
-(void)parseOneImageNoCacheWithPath:(NSString *)_imagePath
                     successHandler:( void (^)(UIImage *parsedImage) )_successHandler;
-(void)saveMediaToSavedAlbumWithFilePath:(NSString *)_filePath savePhoto:(BOOL)_savePhoto;
-(void)refresh;

@end

@protocol KRImageParserDelegate <NSObject>

/*
 * @ 已完成解析多張圖片
 *   - _parsedImages,   存放解析成功的圖片檔案
 *   - _failedImageIds, 存放解析失敗的圖片 ID Key
 */
-(void)krImageParser:(KRImageParser *)_krImageParser didFinishedParseImages:(NSDictionary *)_parsedImages withFailedParseImageIds:(NSMutableArray *)_failedImageIds;
/*
 * @ 已完成解析單張圖片
 *   - _parsedImage, 存放解析成功的圖片檔案
 */
-(void)krImageParser:(KRImageParser *)_krImageParser didFinishedParseSingleImage:(UIImage *)_parsedImage;
/*
 * @ 圖片解析失敗
 *   - _failedImageIds, 存放解析失敗的圖片 ID Key
 */
-(void)krImageParser:(KRImageParser *)_krImageParser didFailedParseImageIds:(NSMutableArray *)_failedImageIds;



@end


