//
//  AppStoreUpdateManager.m
//  AppStoreUpdateKit
//
//  Created by Jovi on 12/19/18.
//  Copyright © 2018 Jovi. All rights reserved.
//

#import "AppStoreUpdateManager.h"
#import "AppStoreUpdateAppObject.h"

static AppStoreUpdateManager *instance;
@implementation AppStoreUpdateManager{
    void (^_checkUpdateCompletionBlock)(BOOL rslt, AppStoreUpdateAppObject *AppObj);
}

+(instancetype)sharedManager{
    @synchronized (self) {
        if (nil == instance) {
            instance = [[AppStoreUpdateManager alloc] init];
        }
        return instance;
    }
}

-(instancetype)init{
    if (self = [super init]) {
        _checkUpdateCompletionBlock = NULL;
    }
    return self;
}

-(BOOL)checkAppUpdate:(AppStoreUpdateAppObject *)appObj{
    BOOL bRslt = NO;
    if (nil == [appObj productID]) {
        return bRslt;
    }
    NSError *error;
    NSData *response = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://itunes.apple.com/lookup?id=%@",[appObj productID]]]] returningResponse:nil error:nil];
    if (nil == response) {
        return bRslt;
    }
    NSDictionary *appInfoDic = [NSJSONSerialization JSONObjectWithData:response options:NSJSONReadingMutableLeaves error:&error];
    if (nil != error) {
        return bRslt;
    }
    
    NSNumber *rsltCount = [appInfoDic valueForKey:@"resultCount"];
    if (1 > [rsltCount integerValue]) {
        return bRslt;
    }
    NSArray *array = [appInfoDic valueForKey:@"results"];
    NSDictionary *dict = [array objectAtIndex:0];
    [appObj setLatestVersion:[dict valueForKey:@"version"]];
    [appObj setReleaseNotes:[dict valueForKey:@"releaseNotes"]];
    bRslt = YES;
    return bRslt;
}

-(void)checkAppUpdateAsync:(AppStoreUpdateAppObject *)appObj withCompletionBlock:(void (^)(BOOL rslt, AppStoreUpdateAppObject *AppObj))block{
    _checkUpdateCompletionBlock = block;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        BOOL bRslt = [self checkAppUpdate: appObj];
        if (NULL != self->_checkUpdateCompletionBlock) {
            self->_checkUpdateCompletionBlock(bRslt, appObj);
        }
    });
}

-(BOOL)requestAppUpdateWindow:(AppStoreUpdateAppObject *)appObj withCompletionCallback:(void (^)(AppUpdateWindowResult rslt, AppStoreUpdateAppObject *AppObj))block{
    return YES;
}

-(void)skipCurrentNewVersion:(AppStoreUpdateAppObject *)appObj{
    if (nil == [appObj latestVersion] || nil == [appObj productID]) {
        return;
    }
    [[NSUserDefaults standardUserDefaults] setValue:[appObj latestVersion] forKey:[appObj productID]];
}

-(BOOL)isCurrentNewVersionSkipped:(AppStoreUpdateAppObject *)appObj{
    BOOL bRslt = NO;
    if (nil == [appObj latestVersion] || nil == [appObj productID]) {
        return bRslt;
    }
    NSString *skippedVersion = [[NSUserDefaults standardUserDefaults] valueForKey:[appObj productID]];
    NSComparisonResult comparisonResult = [skippedVersion compare:[appObj latestVersion] options:NSNumericSearch];
    if (NSOrderedAscending != comparisonResult) {
        bRslt = YES;
    }
    return bRslt;
}

@end