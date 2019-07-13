//
//  TYAddDeviceUtils.m
//  TuyaSmartHomeKit_Example
//
//  Created by Kennaki Kai on 2018/12/3.
//  Copyright © 2018 xuchengcheng. All rights reserved.
//

#import "TYAddDeviceUtils.h"

TYAddDeviceUtils * sharedAddDeviceUtils() {
    return [TYAddDeviceUtils sharedInstance];
}

@implementation TYAddDeviceUtils
+ (instancetype)sharedInstance {
    
    static TYAddDeviceUtils *sharedUtils = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!sharedUtils) {
            sharedUtils = [self new];
        }
    });
    return sharedUtils;
}

- (UILabel *)keyLabel {
    UILabel *label = [UILabel new];
    label.font = [UIFont systemFontOfSize:16];
    return label;
}

- (UITextField *)textField {
    UITextField *field = [UITextField new];
    field.layer.borderColor = UIColor.blackColor.CGColor;
    field.layer.borderWidth = 1;
    
    return field;
}

- (void)alertMessage:(NSString *)message {
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:message
                                                     message:nil
                                                    delegate:nil
                                           cancelButtonTitle:@"OK"
                                           otherButtonTitles:nil];
    [alert show];
}

+ (UIImage *)qrCodeWithString:(NSString *)str width:(CGFloat)width {
    CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    [filter setDefaults];
    NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
    [filter setValue:data forKey:@"inputMessage"];
    [filter setValue:@"M" forKey:@"inputCorrectionLevel"];
    CIImage *outPutImage = [filter outputImage];
    return [self _createNonInterpolatedImageFromCIImage:outPutImage withSize:width];
}

+ (UIImage *)_createNonInterpolatedImageFromCIImage:(CIImage *)image withSize:(CGFloat)size {
    CGRect extent = CGRectIntegral(image.extent);
    CGFloat scale = MIN(size/CGRectGetWidth(extent), size/CGRectGetHeight(extent));
    size_t width = CGRectGetWidth(extent) * scale;      //宽度像素
    size_t height = CGRectGetHeight(extent) * scale;    //高度像素
    
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceGray();//DeviceGray颜色空间
    CGContextRef bitmapRef = CGBitmapContextCreate(nil, width, height, 8, 0, cs, (CGBitmapInfo)kCGImageAlphaNone);
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef bitmapImage = [context createCGImage:image fromRect:extent];//创建CoreGraphics image
    CGContextSetInterpolationQuality(bitmapRef, kCGInterpolationNone);
    CGContextScaleCTM(bitmapRef, scale, scale);
    CGContextDrawImage(bitmapRef, extent, bitmapImage);
    
    CGImageRef scaledImage = CGBitmapContextCreateImage(bitmapRef);
    UIImage *resultImage = [UIImage imageWithCGImage:scaledImage];
    CGContextRelease(bitmapRef);
    CGImageRelease(bitmapImage);
    CGColorSpaceRelease(cs);
    CGImageRelease(scaledImage);
    return resultImage;
}

@end
