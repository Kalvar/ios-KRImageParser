//
//  KRImageParser.m
//  V1.0
//
//  Created by Kalvar ( ilovekalvar@gmail.com ) on 11/10/27.
//  Copyright 2013年 Kuo-Ming Lin. All rights reserved.
//

#import "KRImageParser.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <CoreLocation/CoreLocation.h>

//預設的裁圖呎吋
static CGFloat _krImageParserTableViewCellImageDefaultWidth  = 100.0f * 2;
static CGFloat _krImageParserTableViewCellImageDefaultHeight = 100.0f * 2;
//檔案類型的判斷
static NSString *_krImageParserIsJPEG  = @"public.jpeg";
static NSString *_krImageParserIsPNG   = @"public.png";
static NSString *_krImageParserIsMovie = @"public.movie";
static NSString *_krImageParserIsNull  = @"(null)";


@interface KRImageParser ()
{
    //暫存正在進行處理動作的臨時圖片陣列
    NSMutableDictionary *_tempImages;
}

@property (nonatomic, strong) NSMutableDictionary *_tempImages;

@end


@interface KRImageParser ( fixPrivate )

-(UIImage *)_scaleImage:(UIImage *)_image toSize:(CGSize)_size;
-(UIImage *)_scaleCutImage:(UIImage *)_image toWidth:(float)_toWidth toHeight:(float)_toHeight;
-(UIImage *)_rotateImage:(UIImage *)_orignalImage orignalOrient:(NSInteger)_orignalOrient;
-(UIImage *)_thumbnailFromVideo:(NSString *)_videoPath isLocalFile:(BOOL)_isLocalFile;
//
-(void)_firedDelegateOnDidFinishedParseImages;
-(void)_firedDelegateOnDidFinishedParseSingleImage;
-(void)_firedDelegateOnDidFailedParseImages;
-(void)_parseAssetsImageWithPath:(NSString *)_imagePath setImageId:(NSString *)_imageId parseOnce:(BOOL)_parseOnce;

@end

@implementation KRImageParser ( fixPrivate )


/*
 * @ 直接縮放圖片，但不裁圖
 */
-(UIImage *)_scaleImage:(UIImage *)_image toSize:(CGSize)_size
{
    //繪製改變大小的圖片並截圖
    UIGraphicsBeginImageContext(_size);
    [_image drawInRect:CGRectMake(0, 0, _size.width, _size.height)];
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaledImage;
}

/*
 * @ 中心點裁圖
 */
-(UIImage *)_scaleCutImage:(UIImage *)_image toWidth:(float)_toWidth toHeight:(float)_toHeight
{
    float _x = 0.0f;
    float _y = 0.0f;
    CGRect _frame    = CGRectMake(_x, _y, _toWidth, _toHeight);
    float _oldWidth  = _image.size.width;
    float _oldHeight = _image.size.height;
    //先等比例縮圖
    float _scaleRatio   = MAX( (_toWidth / _oldWidth), (_toHeight / _oldHeight) );
    float _equalWidth   = (int)( _oldWidth * _scaleRatio );
    float _equalHeight  = (int)( _oldHeight * _scaleRatio );
    _image = [self _scaleImage:_image toSize:CGSizeMake(_equalWidth, _equalHeight)];
    _x = floor( (_equalWidth -  _toWidth) / 2 );
    _y = floor( (_equalHeight - _toHeight) / 2 );
    _frame = CGRectMake(_x, _y, _toWidth, _toHeight);
    CGImageRef _smallImage = CGImageCreateWithImageInRect( [_image CGImage], _frame );
    UIImage *_doneImage    = [UIImage imageWithCGImage:_smallImage];
    CGImageRelease(_smallImage);
    return _doneImage;
}

/*
 * @ 旋轉(rotate)圖片成直向
 *   - _orignalImage  : 原始圖
 *   - _orignalOrient : 原始圖的方向
 */
-(UIImage *)_rotateImage:(UIImage *)_orignalImage orignalOrient:(NSInteger)_orignalOrient
{
    CGImageRef imgRef = _orignalImage.CGImage;
    CGFloat width     = CGImageGetWidth(imgRef);
    CGFloat height    = CGImageGetHeight(imgRef);
    CGAffineTransform transform = CGAffineTransformIdentity;
    CGRect bounds      = CGRectMake(0, 0, width, height);
    CGFloat scaleRatio = 1;
    CGFloat boundHeight;
    UIImageOrientation orient = _orignalOrient;
    switch( orient )
    {
        case UIImageOrientationUp:
            transform = CGAffineTransformIdentity;
            break;
        case UIImageOrientationUpMirrored:
            transform = CGAffineTransformMakeTranslation(width, 0.0);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            break;
        case UIImageOrientationDown:
            transform = CGAffineTransformMakeTranslation(width, height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformMakeTranslation(0.0, height);
            transform = CGAffineTransformScale(transform, 1.0, -1.0);
            break;
        case UIImageOrientationLeftMirrored:
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(height, width);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
        case UIImageOrientationLeft:
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(0.0, width);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
        case UIImageOrientationRightMirrored:
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeScale(-1.0, 1.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
        case UIImageOrientationRight:
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(height, 0.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
        default:
            //不支援的圖片方向
            [NSException raise:NSInternalInconsistencyException format:@"Invalid Image Orientation"];
            break;
            
    }
    UIGraphicsBeginImageContext(bounds.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (orient == UIImageOrientationRight || orient == UIImageOrientationLeft)
    {
        CGContextScaleCTM(context, -scaleRatio, scaleRatio);
        CGContextTranslateCTM(context, -height, 0);
    }
    else
    {
        CGContextScaleCTM(context, scaleRatio, -scaleRatio);
        CGContextTranslateCTM(context, 0, -height);
    }
    CGContextConcatCTM(context, transform);
    CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, width, height), imgRef);
    UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return imageCopy;
}

/*
 * @ 為影片製作縮圖
 *   - _videoPath   : 檔案路徑
 *   - _isLocalFile : 是否來自於 Device 本身儲存的檔案( 本機端 )
 */
-(UIImage *)_thumbnailFromVideo:(NSString *)_videoPath isLocalFile:(BOOL)_isLocalFile
{
    NSURL *videoUrl;
    if( _isLocalFile )
    {
        videoUrl = [NSURL fileURLWithPath:_videoPath];
    }
    else
    {
        videoUrl = [NSURL URLWithString:_videoPath];
    }
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videoUrl options:nil];
    AVAssetImageGenerator *generate = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    //允許顯示原始圖片的拍攝角度與方向( EXIF )資訊
    generate.appliesPreferredTrackTransform = YES;
    NSError *err = NULL;
    //設定取得第幾秒時的影片縮圖
    //CMTime time  = CMTimeMake(1, 60);
    CMTime time = CMTimeMakeWithSeconds(1, 60);
    CGImageRef imgRef = [generate copyCGImageAtTime:time actualTime:nil error:&err];
    UIImage *currentImage = [[UIImage alloc] initWithCGImage:imgRef];
    CGImageRelease(imgRef);
    return currentImage;
}

-(void)_firedDelegateOnDidFinishedParseImages
{
    if( self.delegate )
    {
        if( [self.delegate respondsToSelector:@selector(krImageParser:didFinishedParseImages:withFailedParseImageIds:)] )
        {
            [self.delegate krImageParser:self
                  didFinishedParseImages:self.parsedImages
                 withFailedParseImageIds:self.failedImages];
        }
    }
}

-(void)_firedDelegateOnDidFinishedParseSingleImage
{
    if( self.delegate )
    {
        if( [self.delegate respondsToSelector:@selector(krImageParser:didFinishedParseSingleImage:)] )
        {
            [self.delegate krImageParser:self didFinishedParseSingleImage:self.parsedImage];
        }
    }
}

-(void)_firedDelegateOnDidFailedParseImages
{
    if( self.delegate )
    {
        if( [self.delegate respondsToSelector:@selector(krImageParser:didFailedParseImageIds:)] )
        {
            [self.delegate krImageParser:self didFailedParseImageIds:self.failedImages];
        }
    }
}

/*
 * @ 單一解析 Assets 圖片
 *   - 會依 ImageId 將解析完成的圖片檔，各別存在 self.parsedImages 字典陣列裡。
 *
 * @ 參數說明
 *   - _imagePath : 要解析的完整圖片路徑
 *   - _imageId   : 設定該張圖片的 ID Key
 *   - _parseOnce : 是否只解析一次
 *
 */
-(void)_parseAssetsImageWithPath:(NSString *)_imagePath
                      setImageId:(NSString *)_imageId
                       parseOnce:(BOOL)_parseOnce
{
    //如果不是主執行緒
    //if( ![NSThread isMainThread] ){ ... }
    
    /*
     * @ Assests 圖片來源參考路徑( ReferenceURL )
     *   - 必須是 NSURL 的型態
     */
    NSURL *_imageReferenceURL = [NSURL URLWithString:_imagePath];
    
    /*
     * @ 設定結果 Block
     *   - 遞迴處理內部圖片，採取氣泡排序的演算法
     */
    ALAssetsLibraryAssetForURLResultBlock _resultBlock = ^(ALAsset *asset)
    {
        /*
         * @ 如果圖片還未被解析
         */
        if( ![self.parsedImages objectForKey:_imageId] )
        {
            /*
             * @ 照片的拍攝地點
             *   - 緯度與經度
             */
            //CLLocation *location = [asset valueForProperty:ALAssetPropertyLocation];
            //NSLog(@"coordinate:%f %f", location.coordinate.latitude, location.coordinate.longitude);
            /*
             *  @ 照片的拍攝日期
             */
            //NSDate *date = [asset valueForProperty:ALAssetPropertyDate];
            //NSLog(@"date:%@\n\n", date);
            /*
             * @ 取出照片資訊
             *   - presentations
             *     - 圖像
             *     - 外觀
             */
            NSArray *_imagePresentations = [asset valueForProperty:ALAssetPropertyRepresentations];
            //解析後的多媒體圖片
            UIImage *mediaImage;
            /*
             * @ 取出的檔案類型
             *   - 是 public.movie ( 影片 )
             *   - 或 public.image ( 圖片 )
             */
            NSString *_choicedMediaType = [NSString stringWithFormat:@"%@", [[self._tempImages objectForKey:_imageId] objectAtIndex:1]];
            /*
             * @ 圖片是 JPG 檔
             *   - 注意，使用相機照的照片，都為 JPEG 圖片檔。
             */
            if ( [_imagePresentations containsObject:_krImageParserIsJPEG] ) {
                //解析 ReferenceURL 並還原照片
                ALAssetRepresentation *presentation = [asset representationForUTI:_krImageParserIsJPEG];
                if( self.wantOrignalImage )
                {
                    /* 
                     * @ 使用 fullResolutionImage 取出完整 2.3MB  圖檔
                     *   - 如此，才有 EXIF 照片資訊可供照片重繪轉向 ( 轉成直向 )。
                     */
                    mediaImage = [self _rotateImage:[UIImage imageWithCGImage:presentation.fullResolutionImage]
                                      orignalOrient:presentation.orientation];
                }
                else
                {
                    /*
                     * @ 使用 fullScreenImage 取出 800KB 全螢幕呎吋圖檔
                     *   - 這裡沒有 EXIF 照片資訊，無法進行轉向重繪
                     */
                    mediaImage = [UIImage imageWithCGImage:presentation.fullScreenImage];                         
                }
            }
            else if( [_imagePresentations containsObject:_krImageParserIsPNG] )
            {
                ALAssetRepresentation *presentation = [asset representationForUTI:_krImageParserIsPNG];
                if( self.wantOrignalImage )
                {
                    mediaImage = [self _rotateImage:[UIImage imageWithCGImage:presentation.fullResolutionImage]
                                      orignalOrient:presentation.orientation];
                }
                else
                {
                    mediaImage = [UIImage imageWithCGImage:presentation.fullScreenImage];
                }
            }
            else
            {
                //進行影片縮圖
                mediaImage = nil;
                if( [_choicedMediaType isEqualToString:_krImageParserIsMovie] )
                {
                    mediaImage = [self _thumbnailFromVideo:_imagePath isLocalFile:YES];
                }
            }
            if( mediaImage != nil )
            {
                //將圖片裁成統一呎吋並存入解析完成的陣列
                if( self.needToScale )
                {
                    UIImage *_scaledImage = [self _scaleCutImage:mediaImage toWidth:self.scaleWidth  toHeight:self.scaleHeight];
                    [self.parsedImages setValue:_scaledImage forKey:_imageId];
                }
                else
                {
                    [self.parsedImages setValue:mediaImage forKey:_imageId];  
                }
            }
            else
            {
                //將圖片處理失敗的 Id 存起來
                [self.failedImages addObject:_imageId];
            } 
            //刪除暫存陣列裡，處理完畢的圖片
            [self._tempImages removeObjectForKey:_imageId];
            //只想解析一張圖片
            if( _parseOnce )
            {
                //不論解析幾張，都是觸發這函式
                [self _firedDelegateOnDidFinishedParseImages];
                //這裡目前都不會觸發，但先寫起來備用
                //[self _firedDelegateOnDidFinishedParseSingleImage];
            }
            else
            {
                //設定一個計數用的暫存陣列
                NSDictionary *_tempCounts = [NSDictionary dictionaryWithDictionary:self._tempImages];
                //如果還有圖片未被解析
                if( [_tempCounts count] > 0 )
                {
                    for( NSString *_tempImageId in _tempCounts ){
                        /* 
                         * @ 先檢查圖片路徑是否為空
                         *   - 因為是從資料庫撈出來的，所以如果欄位為空值，會顯示成字串型態的 @"(null)"
                         */
                        NSString *_tempImagePath = [[self._tempImages objectForKey:_tempImageId] objectAtIndex:0];
                        if( [_tempImagePath isEqualToString:_krImageParserIsNull] )
                        {
                            [self._tempImages removeObjectForKey:_tempImageId];
                            //如果暫存陣列已為空
                            if( [self._tempImages count] == 0 )
                            {
                                [self _firedDelegateOnDidFinishedParseImages];
                            }
                            continue;
                        }
                        //遞迴處理下一張
                        NSString *_filePath = [[self._tempImages objectForKey:_tempImageId] objectAtIndex:0];
                        [self _parseAssetsImageWithPath:_filePath
                                             setImageId:_tempImageId
                                              parseOnce:NO];
                        break;
                    }
                }
                else
                {
                    //圖片全部完成
                    [self _firedDelegateOnDidFinishedParseImages];
                }                  
            }
        }
        else
        {
            [self _firedDelegateOnDidFinishedParseImages];
        }
    };
    
    /*
     * @ 設定錯誤的 Block
     */
    ALAssetsLibraryAccessFailureBlock _failureBlock  = ^(NSError *error)
    {
        //NSLog(@"errror:%@", error.debugDescription);
    };
    
    /*
     * @ 建立 AssetsLibrary 物件
     */
    ALAssetsLibrary *assestsLibrary = [[ALAssetsLibrary alloc] init];
    
    /* 
     * @ 開始解析還原圖片
     *   - 使用 Block 進行非同步的多執行緒
     */
    [assestsLibrary assetForURL:_imageReferenceURL
                    resultBlock:_resultBlock
                   failureBlock:_failureBlock];
    
}

@end

@implementation KRImageParser

@synthesize delegate;
@synthesize parsedImage,
            parsedImages,
            failedImages;
@synthesize needToScale,
            wantOrignalImage;
@synthesize scaleWidth,
            scaleHeight;
@synthesize _tempImages;


-(id)init
{
    self = [super init];
    if(self)
    {
        self.delegate        = nil;
        self.parsedImage     = nil;
        parsedImages         = [[NSMutableDictionary alloc] initWithCapacity:0];
        failedImages         = [[NSMutableArray alloc] initWithCapacity:0];
        _tempImages          = [[NSMutableDictionary alloc] initWithCapacity:0];
        self.needToScale     = NO;
        self.scaleWidth      = _krImageParserTableViewCellImageDefaultWidth;
        self.scaleHeight     = _krImageParserTableViewCellImageDefaultHeight;
    }
    return self;
}

+(KRImageParser *)sharedManager
{
    static dispatch_once_t pred;
    static KRImageParser *_singleton = nil;
    dispatch_once(&pred, ^{
        _singleton = [[KRImageParser alloc] init];
    });
    return _singleton;
    //return [[self alloc] init];
}

#pragma My Methods
/*
 * @ 解析單張或多張 Assets 圖片
 *
 * @ 參數說明
 *   - _needParses ( NSDictionary )
 *      - KEY   ( NSString ) : 圖片的 ID KEY
 *      - VALUE ( NSArray )  : 
 *        # 索引值 0，圖片的 Assets 路徑 ( Device 相簿的圖片 URL 路徑 )，
 *        # 索引值 1，mediaType 檔案類型 ( public.image OR public.movie )。
 *      - 例如
 *        # [99]   = array( 圖片的 Assets 路徑, public.image );
 *        # [100]  = array( 圖片的 Assets 路徑, public.movie );
 *        # [a101] = array( 圖片的 Assets 路徑, public.image );
 *
 * @ 一次解析多張 Assets 圖片
 * 
 * @ 可呼叫 self.parsedImages 參數得到解析後的圖片字典陣列。
 */
-(void)parseMoreImagesInfo:(NSDictionary *)_needParses
{
    if( [_needParses count] > 0 )
    {
        dispatch_queue_t queue = dispatch_queue_create("_startParseImagesInfoQueue", NULL);
        dispatch_async(queue, ^{
            self._tempImages = [NSMutableDictionary dictionaryWithDictionary:_needParses];
            //只取第一筆資料進行初次處理 : 後續處理交予遞迴進行動作
            for( NSString *imageId in _needParses )
            {
                NSString *mediaPath = [NSString stringWithString:[[_needParses objectForKey:imageId] objectAtIndex:0]];
                [self _parseAssetsImageWithPath:mediaPath
                                     setImageId:imageId
                                      parseOnce:NO];
                break;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                //...
            });
        });
    }
}

/*
 * @ 一次解析只一張 Assets 圖片
 *   - _imagePath : 圖片或影片的 Assets URL 來源
 *   - _mediaType : 圖片是 public.image ; 影片是 public.movie
 *   - _imageId   : 解析後的圖片索引 ID KEY
 *
 * @ 可呼叫 self.parsedImages 參數得到解析後的圖片字典陣列
 *
 * @ 有圖片 Cache 機制
 *
 */
-(void)parseOneImageWithPath:(NSString *)_imagePath setImageId:(NSString *)_imageId isPhoto:(BOOL)_isPhoto
{
    NSString *_kMediaType = ( _isPhoto ) ? krImageParserMediaTypeIsImage : krImageParserMediaTypeIsMovie;
    dispatch_queue_t queue = dispatch_queue_create("_startParseImagesInfoQueue", NULL);
    dispatch_async(queue, ^{
        self._tempImages = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                            [NSArray arrayWithObjects:_imagePath, _kMediaType, nil], _imageId,
                            nil];
        [self _parseAssetsImageWithPath:_imagePath setImageId:_imageId parseOnce:YES];
        dispatch_async(dispatch_get_main_queue(), ^{
            //...
        });
    });  
}

-(void)parseOneImageWithPath:(NSString *)_imagePath isPhoto:(BOOL)_isPhoto
{
    [self parseOneImageWithPath:_imagePath setImageId:@"0" isPhoto:_isPhoto];
}

-(void)parseOneImageWithPath:(NSString *)_imagePath
{
    [self parseOneImageWithPath:_imagePath isPhoto:YES];
}

/*
 * @ 一次解析一張 Assets 圖片
 *   - 有圖片 Cache 機制
 */
-(void)parseOneImageWithPath:(NSString *)_imagePath
                   mediaType:(NSString *)_mediaType
                  setImageId:(NSString *)_imageId
              successHandler:( void (^)(UIImage *parsedImage) )_successHandler
              failureHandler:( void (^)(NSString *failedImageId) )_failureHandler
{
    NSURL *_imageReferenceURL = [NSURL URLWithString:_imagePath];
    ALAssetsLibraryAssetForURLResultBlock _resultBlock = ^(ALAsset *asset){
        NSArray *_imagePresentations = [asset valueForProperty:ALAssetPropertyRepresentations];
        //有可解析的資料
        UIImage *mediaImage = nil;
        if ( [_imagePresentations containsObject:_krImageParserIsJPEG] )
        {
            ALAssetRepresentation *presentation = [asset representationForUTI:_krImageParserIsJPEG];
            if( self.wantOrignalImage )
            {
                mediaImage = [self _rotateImage:[UIImage imageWithCGImage:presentation.fullResolutionImage]
                                  orignalOrient:presentation.orientation];
            }
            else
            {
                mediaImage = [UIImage imageWithCGImage:presentation.fullScreenImage];
            }
        }
        else if ( [_imagePresentations containsObject:_krImageParserIsPNG] )
        {
            ALAssetRepresentation *presentation = [asset representationForUTI:_krImageParserIsPNG];
            if( self.wantOrignalImage )
            {
                mediaImage = [self _rotateImage:[UIImage imageWithCGImage:presentation.fullResolutionImage]
                                  orignalOrient:presentation.orientation];
            }
            else
            {
                mediaImage = [UIImage imageWithCGImage:presentation.fullScreenImage];
            }
        }
        else
        {
            if( [_mediaType isEqualToString:_krImageParserIsMovie] )
            {
                mediaImage = [self _thumbnailFromVideo:_imagePath isLocalFile:YES];
            } 
        }
        
        if( mediaImage != nil )
        {
            if( self.needToScale )
            {
                mediaImage = [self _scaleCutImage:mediaImage toWidth:self.scaleWidth toHeight:self.scaleHeight];
            }
            [self.parsedImages setValue:mediaImage forKey:_imageId];
            _successHandler(mediaImage);
            //_successHandler(self.parsedImages);
        }
        else
        {
            [self.failedImages addObject:_imageId];
            _failureHandler(_imageId);
        }
        //[self refresh];
    };
    
    ALAssetsLibraryAccessFailureBlock _failureBlock  = ^(NSError *error){
        //NSLog(@"errror:%@", error.description);
    };
    
    ALAssetsLibrary *assestsLibrary = [[ALAssetsLibrary alloc] init];
    [assestsLibrary assetForURL:_imageReferenceURL
                    resultBlock:_resultBlock
                   failureBlock:_failureBlock];
}

-(void)parseOneImageWithPath:(NSString *)_imagePath
              successHandler:( void (^)(UIImage *parsedImage) )_successHandler
              failureHandler:( void (^)(NSString *failedImageId) )_failureHandler
{
    [self parseOneImageWithPath:_imagePath
                      mediaType:krImageParserMediaTypeIsImage
                     setImageId:@"0"
                 successHandler:_successHandler
                 failureHandler:_failureHandler];
}

/*
 * @ 一次解析一張 Assets 圖片
 *   - 沒有圖片 Cache 機制，射後不理。
 */
-(void)parseOneImageNoCacheWithPath:(NSString *)_imagePath
                     successHandler:( void (^)(UIImage *parsedImage) )_successHandler
{
    NSURL *_imageReferenceURL = [NSURL URLWithString:_imagePath];
    ALAssetsLibraryAssetForURLResultBlock _resultBlock = ^(ALAsset *asset){
        NSArray *_imagePresentations = [asset valueForProperty:ALAssetPropertyRepresentations];
        UIImage *mediaImage = nil;
        if ( [_imagePresentations containsObject:_krImageParserIsJPEG] )
        {
            ALAssetRepresentation *presentation = [asset representationForUTI:_krImageParserIsJPEG];
            if( self.wantOrignalImage )
            {
                mediaImage = [self _rotateImage:[UIImage imageWithCGImage:presentation.fullResolutionImage]
                                  orignalOrient:presentation.orientation];
            }
            else
            {
                mediaImage = [UIImage imageWithCGImage:presentation.fullScreenImage];
            }
        }
        else if ( [_imagePresentations containsObject:_krImageParserIsPNG] )
        {
            ALAssetRepresentation *presentation = [asset representationForUTI:_krImageParserIsPNG];
            if( self.wantOrignalImage )
            {
                mediaImage = [self _rotateImage:[UIImage imageWithCGImage:presentation.fullResolutionImage]
                                  orignalOrient:presentation.orientation];
            }
            else
            {
                mediaImage = [UIImage imageWithCGImage:presentation.fullScreenImage];
            }
        }
        if( mediaImage != nil )
        {
            if( self.needToScale )
            {
                mediaImage = [self _scaleCutImage:mediaImage toWidth:self.scaleWidth toHeight:self.scaleHeight];
            }
            _successHandler(mediaImage);
        }
    };
    
    ALAssetsLibraryAccessFailureBlock _failureBlock  = ^(NSError *error){
        //NSLog(@"errror:%@", error.description);
    };
    
    ALAssetsLibrary *assestsLibrary = [[ALAssetsLibrary alloc] init];
    [assestsLibrary assetForURL:_imageReferenceURL
                    resultBlock:_resultBlock
                   failureBlock:_failureBlock];
}

/*
 * @ 將圖片或影片儲存在 Device 相簿裡
 */
-(void)saveMediaToSavedAlbumWithFilePath:(NSString *)_filePath savePhoto:(BOOL)_savePhoto
{
    if( _savePhoto )
    {
        //存圖片
        UIImage *_image = [UIImage imageWithContentsOfFile:_filePath];
        UIImageWriteToSavedPhotosAlbum(_image, self, nil, nil);        
    }
    else
    {
        //存影片
        NSString *path = [NSString stringWithFormat:@"%@", _filePath];
        UISaveVideoAtPathToSavedPhotosAlbum(path, self, nil, nil);         
    }
}

/*
 * @ 釋放記憶體
 *   - 最後在要操作完或不使用 KRImageParser 時，一定要執行釋放記憶體的動作。
 */
-(void)refresh
{
    if( [self.parsedImages count] > 0 )
    {
        [self.parsedImages removeAllObjects];
    }
    if( self.parsedImage )
    {
        self.parsedImage = nil;
    }
    if( [self.failedImages count] > 0 )
    {
        [self.failedImages removeAllObjects];
    }
    //if( [self._tempImages count] > 0 ){ [self._tempImages removeAllObjects]; }
}


@end


