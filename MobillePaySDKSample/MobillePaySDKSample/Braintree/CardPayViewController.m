//
//  CardPayViewController.m
//  MobillePaySDKSample
//
//  Created by fly.zhu on 2021/1/14.
//  Copyright © 2021 Yuanex, Inc. All rights reserved.
//

#import "CardPayViewController.h"
#import "YSTestApi.h"
#import <YuansferMobillePaySDK/YSCardPay.h>

@interface CardPayViewController ()
@property (weak, nonatomic) IBOutlet UILabel *resultLabel;
@property (nonatomic, strong) IBOutlet UITextField *cardNumberField;
@property (nonatomic, strong) IBOutlet UITextField *expirationMonthField;
@property (nonatomic, strong) IBOutlet UITextField *expirationYearField;

@property (weak, nonatomic) IBOutlet UIButton *autofillButton;
@property (weak, nonatomic) IBOutlet UIButton *submitButton;

@property (nonatomic, copy) NSString *transactionNo;

@end

@implementation CardPayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setFieldsEnabled:NO];
    [self prepay];
}

- (void) prepay {
     __weak __typeof(self)weakSelf = self;
    [YSTestApi callPrepay:@"0.01"
               completion:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        // 是否出错
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                strongSelf.resultLabel.text = error.localizedDescription;
            });
             return;
        }
        
        // 验证 response 类型
        if (![response isKindOfClass:[NSHTTPURLResponse class]]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                strongSelf.resultLabel.text = @"Response is not a HTTP URL response.";
            });
             return;
        }
        
        // 验证 response code
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode != 200) {
            dispatch_async(dispatch_get_main_queue(), ^{
                strongSelf.resultLabel.text = [NSString stringWithFormat:@"HTTP response status code error, statusCode = %ld.", (long)httpResponse.statusCode];
            });
             return;
        }
        
        // 确保有 response data
        if (data == nil || !data || data.length == 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                strongSelf.resultLabel.text = @"No response data.";
            });
             return;
        }
        
        // 确保 JSON 解析成功
        id responseObject = nil;
        NSError *serializationError = nil;
        @autoreleasepool {
            responseObject = [NSJSONSerialization JSONObjectWithData:data
                                                             options:kNilOptions
                                                               error:&serializationError];
        }
        if (serializationError) {
            dispatch_async(dispatch_get_main_queue(), ^{
                strongSelf.resultLabel.text = [NSString stringWithFormat:@"Deserialize JSON error, %@", serializationError.localizedDescription];
            });
             return;
        }
        
        // 检查业务状态码, 注意测试环境的状态码与正式环境状态码有点区别，这里只判断了正式环境的
        if (![[responseObject objectForKey:@"ret_code"] isEqualToString:@"000100"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                strongSelf.resultLabel.text = [NSString stringWithFormat:@"Yuansfer error, %@.", [responseObject objectForKey:@"ret_msg"]];
            });
             return;
        }
        
        strongSelf.transactionNo = [[responseObject objectForKey:@"result"] objectForKey:@"transactionNo"];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [strongSelf setFieldsEnabled:YES];
            strongSelf.resultLabel.text = @"prepay接口调用成功,可提交支付数据进行处理";
            // 注意，下一行是静态测试授权码，仅用于测试，实际项目中应该是下二行从服务器接口获取动态授权码
            [[YSApiClient sharedInstance] initBraintreeClient:@"sandbox_ktnjwfdk_wfm342936jkm7dg6"];
            // [[YSApiClient sharedInstance] initBraintreeClient:[[responseObject objectForKey:@"result"] objectForKey:@"authorization"]];
            [strongSelf collectDeviceData:[YSApiClient sharedInstance].apiClient];
        });
    }];
}

- (void) payProcess:(NSString *)nonce {
     __weak __typeof(self)weakSelf = self;
    [YSTestApi callProcess:self.transactionNo paymentMethod:@"credit_card" nonce:nonce
                deviceData:self.deviceData
         completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        
        // 是否出错
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                strongSelf.resultLabel.text = error.localizedDescription;
            });
             return;
        }
        
        // 验证 response 类型
        if (![response isKindOfClass:[NSHTTPURLResponse class]]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                strongSelf.resultLabel.text = @"Response is not a HTTP URL response.";
            });
             return;
        }
        
        // 验证 response code
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode != 200) {
            dispatch_async(dispatch_get_main_queue(), ^{
                strongSelf.resultLabel.text = [NSString stringWithFormat:@"HTTP response status code error, statusCode = %ld.", (long)httpResponse.statusCode];
            });
             return;
        }
        
        // 确保有 response data
        if (!data || data.length == 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                strongSelf.resultLabel.text = @"No response data.";
            });
             return;
        }
        
        // 确保 JSON 解析成功
        id responseObject = nil;
        NSError *serializationError = nil;
        @autoreleasepool {
            responseObject = [NSJSONSerialization JSONObjectWithData:data
                                                             options:kNilOptions
                                                               error:&serializationError];
        }
        if (serializationError) {
            dispatch_async(dispatch_get_main_queue(), ^{
                strongSelf.resultLabel.text = [NSString stringWithFormat:@"Deserialize JSON error, %@", serializationError.localizedDescription];
            });
             return;
        }
        
        // 检查业务状态码, 注意测试环境的状态码与正式环境状态码有点区别，这里只判断了正式环境的
        if (![[responseObject objectForKey:@"ret_code"] isEqualToString:@"000100"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                strongSelf.resultLabel.text = [NSString stringWithFormat:@"Yuansfer error, %@.", [responseObject objectForKey:@"ret_msg"]];
            });
             return;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            //显示支付成功
            strongSelf.resultLabel.text = @"Card Pay支付成功";
        });
    }];
}

- (IBAction)submitForm {
    BTCard *card = [[BTCard alloc] initWithNumber:self.cardNumberField.text
    expirationMonth:self.expirationMonthField.text
    expirationYear:self.expirationYearField.text
                cvv:nil];
    [YSCardPay requestCardPayment:card completion:^(BTCardNonce *tokenized, NSError *error) {
        [self setFieldsEnabled:YES];
        if (error) {
            self.resultLabel.text = [NSString stringWithFormat:@"process接口失败:%@", error.domain];
            return;
        }
        [self payProcess:tokenized.nonce];
    }];
}

- (IBAction)setupDemoData {
    self.cardNumberField.text = [@"4111111111111111" copy];
    self.expirationMonthField.text = [@"06" copy];
    self.expirationYearField.text = [@"2022" copy];
}

- (void)setFieldsEnabled:(BOOL)enabled {
    self.cardNumberField.enabled = enabled;
    self.expirationMonthField.enabled = enabled;
    self.expirationYearField.enabled = enabled;
    self.submitButton.enabled = enabled;
    self.autofillButton.enabled = enabled;
}

@end
