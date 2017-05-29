//
//  MainPresenter.m
//  MMLanScanDemo
//
//  Created by Michael Mavris on 04/11/2016.
//  Copyright © 2016 Miksoft. All rights reserved.
//

#import "MainPresenter.h"
#import "LANProperties.h"
#import "MMLANScanner.h"
#import "MMDevice.h"

@interface MainPresenter()<MMLANScannerDelegate>

@property (nonatomic,weak)id <MainPresenterDelegate> delegate;
@property(nonatomic,strong)MMLANScanner *lanScanner;
@property(nonatomic,assign,readwrite)BOOL isScanRunning;
@property(nonatomic,assign,readwrite)float progressValue;
@end

@implementation MainPresenter {
    NSMutableArray *connectedDevicesMutable;
    NSDate* scanStartTime;
}

#pragma mark - Init method
//Initialization with delegate
-(instancetype)initWithDelegate:(id <MainPresenterDelegate>)delegate {

    self = [super init];
    
    if (self) {
        
        self.isScanRunning=NO;
       
        self.delegate=delegate;
        
        self.lanScanner = [[MMLANScanner alloc] initWithDelegate:self];
    }
    
    return self;
}

#pragma mark - Button Actions
//This method is responsible for handling the tap button action on MainVC. In case the scan is running and the button is tapped it will stop the scan
-(void)scanButtonClicked {

    scanStartTime = [NSDate date];
    //Checks if is already scanning
    if (self.isScanRunning) {
        
        [self stopNetworkScan];
    }
    else {
        
        [self startNetworkScan];
    }
    
}

-(void)startNetworkScan {
    
    self.isScanRunning=YES;
    
    connectedDevicesMutable = [[NSMutableArray alloc] init];
    
    self.lanScanner = [[MMLANScanner alloc] initWithDelegate:self];
//    self.lanScanner.maxConcurrentOperationCount = 20;
//    [self.lanScanner start];
        [self.lanScanner startPingAllHostsForIP:@"192.168.0.1" subnet:@"255.255.255.0"];
//        [self.lanScanner startPingAllHostsForIP:@"195.191.1.1" subnet:@"255.255.255.0"];
};

-(void)stopNetworkScan {
    
    [self.lanScanner stop];
    
    self.isScanRunning=NO;
}

#pragma mark - SSID
//Getting the SSID string using LANProperties
-(NSString*)ssidName {

    return [NSString stringWithFormat:@"SSID: %@",[LANProperties fetchSSIDInfo]];
};

#pragma mark - MMLANScannerDelegate methods
//The delegate methods of MMLANScanner
-(void)lanScanDidFindNewDevice:(MMDevice*)device{
    
    //Check if the MMDevice is already added
    if (![connectedDevicesMutable containsObject:device]) {

        [connectedDevicesMutable addObject:device];
    }
    
    //Updating the array that holds the data. MainVC will be notified by KVO
    self.connectedDevices = [NSArray arrayWithArray:connectedDevicesMutable];
}

static float times = 0;
static float total = 0;

-(void)lanScanDidFinishScanningWithStatus:(MMLanScannerStatus)status{

    total += connectedDevicesMutable.count;
    times += 1;
    NSLog(@"done scanning, %u device(s), %.02f secs (avg cnt %.1f)", connectedDevicesMutable.count, -scanStartTime.timeIntervalSinceNow, total/times);

    self.isScanRunning=NO;
    
    //Checks the status of finished. Then call the appropriate method
    if (status == MMLanScannerStatusFinished) {
        
        [self.delegate mainPresenterIPSearchFinished];
    }
    else if (status==MMLanScannerStatusCancelled) {
       
        [self.delegate mainPresenterIPSearchCancelled];
    }
}

-(void)lanScanProgressPinged:(float)pingedHosts from:(NSInteger)overallHosts {
    
    //Updating the progress value. MainVC will be notified by KVO
    self.progressValue=pingedHosts/overallHosts;
}

-(void)lanScanDidFailedToScan {
   
    self.isScanRunning=NO;

    [self.delegate mainPresenterIPSearchFailed];
}

@end
