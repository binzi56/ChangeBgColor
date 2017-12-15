//
//  ViewController.m
//  ChangeBgColorDemo
//
//  Created by 帅斌 on 2017/12/14.
//  Copyright © 2017年 personal. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *originImageView;
@property (weak, nonatomic) IBOutlet UIImageView *resultImageView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}
- (IBAction)originImageAction:(UIButton *)sender {
    [self handleImageAction:0];
}

- (IBAction)grayImageAction:(UIButton *)sender {
    [self handleImageAction:1];
}

- (IBAction)highQualityImageAction:(UIButton *)sender {
    [self handleImageAction:2];
}


- (void)handleImageAction:(NSInteger)index {
    UIImage *resultImage;
    if (index == 0) {
        //原始图
        resultImage = [self returnOrginImage:self.originImageView.image];
    }else if (index == 1){
        //灰度图
        resultImage = [self returnGrayImage:self.originImageView.image];
    }else{
        //高保真
        resultImage = [self returnHightQualityImage:self.originImageView.image];
    }
    
    //展示图片
    self.resultImageView.image = resultImage;
    
    //存储
    NSData *resultData = UIImagePNGRepresentation(resultImage);
    NSString *pathDocuments = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0];
    NSString *createPath = [NSString stringWithFormat:@"%@/name_index_%ld.png",pathDocuments, index];
    [resultData writeToFile:createPath atomically:YES];
    NSLog(@"存储index_%ld的图片路径:\n%@", index,createPath);
}

//返回灰度图像
-(UIImage*)returnGrayImage:(UIImage*)sourceImage{
    int width = sourceImage.size.width;
    int height = sourceImage.size.height;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    CGContextRef context = CGBitmapContextCreate (nil,width,height,8,0,colorSpace,kCGImageAlphaNone);
    CGColorSpaceRelease(colorSpace);
    
    if (context == NULL) {
        return nil;
    }
    
    CGContextDrawImage(context,CGRectMake(0, 0, width, height), sourceImage.CGImage);
    UIImage *grayImage = [UIImage imageWithCGImage:CGBitmapContextCreateImage(context)];
    CGContextRelease(context);
    
    return grayImage;
}

//返回高保真图像(只返回黑白两种颜色)
- (UIImage *)returnHightQualityImage:(UIImage *)sourceImage{
    NSData *imageData = UIImagePNGRepresentation(sourceImage);
    
    CGImageSourceRef sourceRef = CGImageSourceCreateWithData((CFDataRef)imageData, NULL);
    CGImageRef imageRef = CGImageSourceCreateImageAtIndex(sourceRef, 0, NULL);
    
    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    
    unsigned char *data = calloc(width * height * 4, sizeof(unsigned char)); // 取图片首地址
    size_t bitsPerComponent = 8; // r g b a 每个component bits数目
    size_t bytesPerRow = width * 4; // 一张图片每行字节数目 (每个像素点包含r g b a 四个字节)
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB(); // 创建rgb颜色空间
    
    CGContextRef context = CGBitmapContextCreate(data, width, height, bitsPerComponent, bytesPerRow, space, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    
    for (size_t i = 0; i < height; i++)
    {
        for (size_t j = 0; j < width; j++)
        {
            // 设置每个像素的rgba值
            size_t pixelIndex = i * width * 4 + j * 4;
            
            unsigned char red   = data[pixelIndex];
            unsigned char green = data[pixelIndex + 1];
            unsigned char blue  = data[pixelIndex + 2];
            
            //取灰度值
            unsigned char gray = 0.299 * red + 0.587 * green + 0.114 * blue;
            gray = gray > 150 ? 255 : 0;
            data[pixelIndex]     = gray;    // r
            data[pixelIndex + 1] = gray;    // g
            data[pixelIndex + 2] = gray;    // b
            data[pixelIndex + 3] = gray == 255 ? 0 : 255;    // a (255 代表透明)
        }
    }
    
    CGImageRef newImage = CGBitmapContextCreateImage(context);
    UIImage *image = [[UIImage alloc] initWithCGImage:newImage];
    return image;
}

//返回原始图像(将图片的背景置为透明)
- (UIImage *)returnOrginImage:(UIImage *)sourceImage
{
    //分配内存
    const int imageWidth = sourceImage.size.width;
    const int imageHeight = sourceImage.size.height;
    size_t bytesPerRow = imageWidth * 4;
    uint32_t* rgbImageBuf = (uint32_t*)malloc(bytesPerRow * imageHeight);
    
    //创建context
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(rgbImageBuf, imageWidth, imageHeight, 8, bytesPerRow, colorSpace,kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipLast);
    CGContextDrawImage(context, CGRectMake(0, 0, imageWidth, imageHeight), sourceImage.CGImage);
    
    //遍历像素
    int pixelNum = imageWidth * imageHeight;
    uint32_t* pCurPtr = rgbImageBuf;
    for (int i = 0; i < pixelNum; i++, pCurPtr++){
        //接近白色
        //将像素点转成子节数组来表示---ARGB
        //ptr[0]:透明度,ptr[1]:R,ptr[2]:G,ptr[3]:B
        
        //分别取出RGB值后。进行判断需不需要设成透明。
        uint8_t* ptr = (uint8_t*)pCurPtr;
        if (ptr[1] > 140 && ptr[2] > 140 && ptr[3] > 140) {
            //当RGB值都大于140则比较接近白色的都将透明度设为0
            //demo中的图片有点灰, 所以设置了140, 可以根据需要自行设置
            ptr[0] = 0;
        }
    }
    
    //将内存转成image
    CGDataProviderRef dataProvider =CGDataProviderCreateWithData(NULL, rgbImageBuf, bytesPerRow * imageHeight, nil);
    CGImageRef imageRef = CGImageCreate(imageWidth, imageHeight,8, 32, bytesPerRow, colorSpace,kCGImageAlphaLast |kCGBitmapByteOrder32Little, dataProvider,NULL, true,kCGRenderingIntentDefault);
    CGDataProviderRelease(dataProvider);
    
    UIImage *resultUIImage = [UIImage imageWithCGImage:imageRef];
    
    //释放
    CGImageRelease(imageRef);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    return resultUIImage;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
