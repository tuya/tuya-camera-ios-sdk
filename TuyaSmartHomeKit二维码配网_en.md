### Tuya smart iOS sdk qr code network distribute file

Make sure you has access to TuyaSmartHomeKit (Click [HERE](https://github.com/TuyaInc/tuyasmart_home_ios_sdk/blob/master/ios-sdk.md) to view the document).

#### Get Current WiFi SSID

```objective-c
self.ssid = [TuyaSmartActivator currentWifiSSID];
```

#### Get Token

```objective-c
long long homeId = 'current home id';
[[TuyaSmartActivator sharedInstance] getTokenWithHomeId:homeId success:^(NSString *result) {
	self.token = result;
} failure:^(NSError *error) {
}];
```

#### Build QR Code Information

```objective-c
// self.ssid
// self.token
// self.pwd		// current wifi password
NSDictionary *dictionary = @{
                            @"s": self.ssid,
                            @"p": self.pwd,
                            @"t": self.token
                            };
NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:nil];
self.wifiJsonStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
```

#### Begin Network Distribute

Use the wifijsonstr to get qr code, make sure that the device is at network distribute status, put the qr code in front of cameram, device will have the indicate voice once it get the qr code information. mornitor the network distribute result with below interface:

```objective-c
[[TuyaSmartActivator sharedInstance] startConfigWiFi:TYActivatorModeQRCode ssid:self.ssid password:self.pwd token:self.token timeout:100];
```

#### Stop Network Distribute

```objective-c
[[TuyaSmartActivator sharedInstance] stopConfigWiFi];
```

#### Call Back The Result 

Call back the result with the delegate: TuyaSmartActivatorDelegate, the delegate method :

```
// deviceModel the model class of device
- (void)activator:(TuyaSmartActivator *)activator didReceiveDevice:(TuyaSmartDeviceModel *)deviceModel error:(NSError *)error;
```

