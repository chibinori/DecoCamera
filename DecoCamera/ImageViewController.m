//
//  ImageViewController.m
//  DecoCamera
//
//  Created by 酒井紀明 on 2015/12/19.
//  Copyright © 2015年 noriaki.sakai. All rights reserved.
//

#import "ImageViewController.h"
#import <CoreImage/CoreImage.h>

@interface ImageViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@property (weak, nonatomic) IBOutlet UIButton *grayButton;
@property (assign, nonatomic) BOOL isGray;

@property (weak, nonatomic) IBOutlet UIButton *twiceAsLarge;
@property (weak, nonatomic) IBOutlet UIButton *halfAsLarge;
@property (assign, nonatomic) float magnification;

@property (weak, nonatomic) IBOutlet UIButton *allResetButton;

@property (weak, nonatomic) IBOutlet UISlider *sl;

@property (strong, nonatomic) UIImage *grayScaleImage;

- (IBAction)saveButtonAction:(id)sender;
- (IBAction)grayButtonAction:(id)sender;

- (IBAction)twiceAsLargeButtonAction:(id)sender;
- (IBAction)halfAsLargeButtonAction:(id)sender;

- (IBAction)allResetButtonAction:(id)sender;


- (IBAction)backButtonAction:(id)sender;

@end

@implementation ImageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.imageView.image = self.editImage;
    self.isGray = NO;
    self.magnification = 1.0f;
    
    self.sl.minimumValue = -100;
    self.sl.maximumValue = 100;
    self.sl.value = 0;
}


- (IBAction)saveButtonAction:(id)sender {
    
    SEL selector = @selector(onCompleteCapture:didFinishSavingWithError:contextInfo:);
    //画像を保存する
    UIImageWriteToSavedPhotosAlbum(self.imageView.image, self, selector, NULL);
}

//画像保存完了時のセレクタ
- (void)onCompleteCapture:(UIImage *)screenImage didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"保存終了" message:@"画像を保存しました" preferredStyle:UIAlertControllerStyleAlert];
    
    // addActionした順に左から右にボタンが配置されます
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        
    }]];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (IBAction)grayButtonAction:(id)sender {
    self.isGray = !self.isGray;
    
    if (self.isGray) {
        UIImage *grayScaleImage = nil;
        
        if (self.grayScaleImage == nil) {
            
            [self.grayButton setTitle:@"Reset" forState:UIControlStateNormal];
            
            UIImage *image = self.editImage;
            CGRect imageRect = (CGRect){0.0, 0.0, image.size.width, image.size.height};
            
            // CoreGraphicsのモノクロ色空間を準備します
            CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
            
            // ビットマップコンテキストを作りサイズと色空間を設定します
            CGContextRef context = CGBitmapContextCreate(nil, image.size.width, image.size.height, 8, 0, colorSpace, kCGImageAlphaNone);
            
            // ビットマップコンテキストに画像を描画します
            CGContextDrawImage(context, imageRect, [image CGImage]);
            
            // ビットマップコンテキストに描画された画像を取得します
            CGImageRef imageRef = CGBitmapContextCreateImage(context);
            
            // 取得した画像からUIImageを作ります
            grayScaleImage = [UIImage imageWithCGImage:imageRef];
            
            // 準備した色空間、ビットマップコンテキスト、取得した画像をメモリから解放します
            CGColorSpaceRelease(colorSpace);
            CGContextRelease(context);
            CFRelease(imageRef);
            self.grayScaleImage = grayScaleImage;
        }
        
        
        UIImage* resultImage = [self effectImage:self.sl.value];
        
        // Storyboard上のUIImageViewに画像を描画します
        self.imageView.image = resultImage;
    } else {
        
        self.grayButton.titleLabel.text = @"Gray";
        [self.grayButton setTitle:@"Gray" forState:UIControlStateNormal];

        UIImage* resultImage = [self effectImage:self.sl.value];
        self.imageView.image = resultImage;
    }
}

- (IBAction)didValueChanged:( UISlider *)slider
{
    NSLog(@"%f", slider.value);
    
    UIImage* resultImage = [self effectImage:slider.value];
    
    self.imageView.image = resultImage;
}

- (UIImage*)effectImage:(float)brightnessOfSlider {
    
    float brightness = brightnessOfSlider / (float)100;
    
    UIImage *sourceImage;
    if (self.isGray) {
        sourceImage = self.grayScaleImage;
    } else {
        sourceImage = self.editImage;
    }
    
    sourceImage = [self resizeImage:sourceImage];
    
    // UIImageをCIImageに変換
    CIImage *ciImage = [[CIImage alloc] initWithImage:sourceImage];
    
    // フィルタの作成
    CIFilter *ciFilter = [CIFilter filterWithName:@"CIColorControls"
                                    keysAndValues:kCIInputImageKey, ciImage,
                          @"inputBrightness", [NSNumber numberWithFloat:brightness]
                          ,nil];
    // 結果画像の取り出し
    CIImage* filterdImage = [ciFilter outputImage];
    
    
    // CIImageからUIImageに変換
    CIContext *ciContext = [CIContext contextWithOptions:nil];
    CGImageRef imgRef = [ciContext createCGImage:filterdImage fromRect:[filterdImage extent]];
    UIImage* resultImage = [UIImage imageWithCGImage:imgRef scale:1.0f orientation:UIImageOrientationUp];
    CGImageRelease(imgRef);
    
    return resultImage;
}

- (UIImage*)resizeImage:(UIImage*)source
{
    CGSize resizedSize = CGSizeMake(source.size.width * self.magnification,
                                    source.size.height * self.magnification);
    
    UIGraphicsBeginImageContext(resizedSize);
    [source drawInRect:CGRectMake(0, 0, resizedSize.width, resizedSize.height)];
    UIImage* resultImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return resultImage;
}

- (IBAction)twiceAsLargeButtonAction:(id)sender {
    // ２倍以上にはしない
    if (self.magnification < 2.0f
        && fabs(self.magnification - 2.0f) > FLT_EPSILON) {
        self.magnification = self.magnification * 2.0;
    }
    
    UIImage* resultImage = [self effectImage:self.sl.value];
    self.imageView.image = resultImage;
}

- (IBAction)halfAsLargeButtonAction:(id)sender {
    // １／２倍以下にはしない
    if (self.magnification > 0.5
        && fabs(self.magnification - 0.5f) > FLT_EPSILON) {
        self.magnification = self.magnification * 0.5;
    }
    
    UIImage* resultImage = [self effectImage:self.sl.value];
    self.imageView.image = resultImage;
}

- (IBAction)allResetButtonAction:(id)sender {
    
    self.imageView.image = self.editImage;

    self.isGray = NO;
    self.magnification = 1.0f;
    
    self.sl.value = 0;
    
    [self.grayButton setTitle:@"Gray" forState:UIControlStateNormal];
}



- (IBAction)backButtonAction:(id)sender {
    
    [self.navigationController popToRootViewControllerAnimated:YES];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
