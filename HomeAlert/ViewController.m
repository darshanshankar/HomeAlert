//
//  ViewController.m
//  HomeAlert
//
//  Created by Darshan Shankar on 12/11/14.
//  Copyright (c) 2014 Darshan Shankar. All rights reserved.
//

#import "ViewController.h"
#import "Forecastr+CLLocation.h"
#import "CoreLocation/CoreLocation.h"

@interface ViewController ()
{
    Forecastr *forecastr;
    CLLocationManager *locationManager;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor blackColor]];
    
    [self getForecast];
}

- (void) getForecast {
    // TODO ios7 fallback needed
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:@"latitude"] && [defaults objectForKey:@"longitude"]) {
        CLLocationDegrees latDeg = ((NSNumber *)[defaults objectForKey:@"latitude"]).doubleValue;
        CLLocationDegrees longDeg = ((NSNumber *)[defaults objectForKey:@"longitude"]).doubleValue;
        CLLocation *loc = [[CLLocation alloc] initWithLatitude:latDeg longitude:longDeg];
        [self getForecastForLocation:loc];
    } else {
        locationManager = [[CLLocationManager alloc] init];
        locationManager.delegate = self;
        locationManager.distanceFilter = kCLDistanceFilterNone;
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer;
        
        if(CLLocationManager.authorizationStatus == kCLAuthorizationStatusNotDetermined) {
            [locationManager requestAlwaysAuthorization];
        }
    }
}

- (void) getForecastForLocation:(CLLocation *)location {
// TODO allow user to select F or C (US or SI)
    forecastr = [Forecastr sharedManager];
    forecastr.units = kFCUSUnits;
    // if C / SI
//    forecastr.units = kFCSIUnits;
    
    forecastr.apiKey = @"9e9beedf0b43879a4ffd1011097afbd2"; // You will need to set the API key here (only set it once in the entire app)
    NSArray *exclusions = @[kFCMinutelyForecast, kFCHourlyForecast, kFCAlerts, kFCFlags];
    
    [forecastr getForecastForLocation:location time:nil exclusions:exclusions success:^(id JSON) {
        NSDictionary *data = (NSDictionary *)JSON;
        NSDictionary *todayWeather = [[[data objectForKey:kFCDailyForecast] objectForKey:@"data"] objectAtIndex:0];
        NSString *summary = [todayWeather objectForKey:@"summary"];
        NSString *icon = [self unicodeForWeatherIconType:[todayWeather objectForKey:@"icon"]];
        NSNumber *lowTempFull = [todayWeather objectForKey:@"temperatureMin"];
        NSNumber *highTempFull = [todayWeather objectForKey:@"temperatureMax"];

        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        [formatter setRoundingMode:NSNumberFormatterRoundHalfUp];
        [formatter setMaximumFractionDigits:0];
        
        NSString *message = [NSString stringWithFormat:@"%@\n%@ High %@\u2109, Low %@\u2109", summary, icon, [formatter stringFromNumber:highTempFull], [formatter stringFromNumber:lowTempFull]];
        
        [self displayLocalNotificationWithMessage:message];
    } failure:^(NSError *error, id response) {
        [self displayLocalNotificationWithMessage:@"Sorry, I was unable to get the weather forecast."];
    }];
}

- (NSString *)unicodeForWeatherIconType:(NSString *)iconDescription
{
    //    NSString *kUnicodeSunny = @"\u2600";
    //    NSString *kUnicodeRain = @"\u2614";
    //    NSString *kUnicodeSnow = @"\u2744";
    //    NSString *kUnicodeCloudy = @"\u2601";
    //    NSString *kUnicodePartlyCloudy = @"\u26c5";
    //    NSString *kUnicodeThunderstorm = @"\u26a1";

    NSString *kUnicodeSunny = @"☀️";
    NSString *kUnicodeRain = @"☔️";
    NSString *kUnicodeSnow = @"❄️";
    NSString *kUnicodeCloudy = @"☁️";
    NSString *kUnicodePartlyCloudy = @"⛅️";
    NSString *kUnicodeThunderstorm = @"⚡️";
    NSString *kUnicodeClearNight = @"🌙";
    NSString *kUnicodeWind = @"💨";
    
    if ([iconDescription isEqualToString:kFCIconClearDay]) { return kUnicodeSunny; } // ☀️
    else if ([iconDescription isEqualToString:kFCIconClearNight]) { return kUnicodeClearNight; } // 🌙
    else if ([iconDescription isEqualToString:kFCIconRain]) { return kUnicodeRain; } // ☔️
    else if ([iconDescription isEqualToString:kFCIconSnow]) { return kUnicodeSnow; } // ❄️
    else if ([iconDescription isEqualToString:kFCIconSleet]) { return kUnicodeRain; } // ☔️
    else if ([iconDescription isEqualToString:kFCIconWind]) { return kUnicodeWind; } // 💨
    else if ([iconDescription isEqualToString:kFCIconFog]) { return kUnicodeWind; } // 💨
    else if ([iconDescription isEqualToString:kFCIconCloudy]) { return kUnicodeCloudy; } // ☁️
    else if ([iconDescription isEqualToString:kFCIconPartlyCloudyDay]) { return kUnicodePartlyCloudy; } // ⛅️
    else if ([iconDescription isEqualToString:kFCIconPartlyCloudyNight]) { return kUnicodePartlyCloudy; } // ⛅️
    else if ([iconDescription isEqualToString:kFCIconHail]) { return kUnicodeWind; } // 💨
    else if ([iconDescription isEqualToString:kFCIconThunderstorm]) { return kUnicodeThunderstorm; } // ⚡️
    else if ([iconDescription isEqualToString:kFCIconTornado]) { return kUnicodeWind; } // 💨
    else if ([iconDescription isEqualToString:kFCIconHurricane]) { return kUnicodeWind; } // 💨
    else return kUnicodeCloudy; // Default in case nothing matched ☁️
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if([CLLocationManager locationServicesEnabled]){
        [locationManager startUpdatingLocation];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    [locationManager stopUpdatingLocation];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithDouble:newLocation.coordinate.latitude] forKey:@"latitude"];
    [defaults setObject:[NSNumber numberWithDouble:newLocation.coordinate.longitude] forKey:@"longitude"];
    [defaults synchronize];
    [self getForecastForLocation:newLocation];
}

- (void)registerForNotifications {
// TODO ios7 fallback needed
    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeAlert|UIUserNotificationTypeBadge|UIUserNotificationTypeSound) categories:nil];
    [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
}

- (void)displayLocalNotificationWithMessage:(NSString *)message {
    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:5];
    localNotification.fireDate = date;
    localNotification.alertBody = message;
    
    // @"Rainy day, grab an umbrella!\n\u2614 H64\u2109 L54\u2109"
    // u00B0 = degree
    // u2109 = degree F
    // u2103 = degree C
    // u2614 = umbrella with rain
    
    localNotification.soundName = UILocalNotificationDefaultSoundName;
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
}

@end
