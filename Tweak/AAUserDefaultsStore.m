#import <CoreFoundation/CoreFoundation.h>
#import <libSandy.h>
#import <roothide.h>

#import "../Model/AAAlertInfo.h"
#import "AADataStore.h"
#import "AAUserDefaultsStore.h"

static NSString *kPreferencesPath;
static NSString *const kLibSandyProfile = @"AutoAlerts";

@interface AAUserDefaultsStore ()
@property (nonatomic, strong) NSUserDefaults *userDefaults;
@end

@implementation AAUserDefaultsStore

- (instancetype)init {
	if (self = [super init]) {
		libSandy_applyProfile(kLibSandyProfile.UTF8String);

		if (!kPreferencesPath) {
			kPreferencesPath = @"/var/mobile/Library/Preferences/com.shiftcmdk.autoalerts.storage.plist";
		}

		self.userDefaults = [[NSUserDefaults alloc] initWithSuiteName:kPreferencesPath];
	}
	return self;
}

- (NSArray<NSDictionary *> *)_rawAlerts {
	NSArray *alerts = [self.userDefaults arrayForKey:@"alerts"];
	NSArray *result = alerts ?: @[];
	return result;
}

- (NSDictionary *)_dictFromAlert:(AAAlertInfo *)alert {
	return (@{
		@"actions": alert.actions ?: @[],
		@"title": alert.title ?: @"",
		@"message": alert.message ?: @"",
		@"textFields": alert.textFieldValues ?: @[],
		@"selectedAction": @(alert.selectedAction),
		@"customAppActions": alert.customAppActions ?: @{},
		@"bundleID": alert.bundleID ?: @"",
		@"identifier": alert.identifier ?: @""
	});
}

- (AAAlertInfo *)_alertFromDict:(NSDictionary *)dict {
	return [[AAAlertInfo alloc] initWithActions:dict[@"actions"]
										  title:dict[@"title"]
										message:dict[@"message"]
								textFieldValues:dict[@"textFields"]
								 selectedAction:[dict[@"selectedAction"] intValue]
							   customAppActions:[NSMutableDictionary dictionaryWithDictionary:dict[@"customAppActions"]]
									   bundleID:dict[@"bundleID"]];
}

- (void)_saveRawAlerts:(NSArray<NSDictionary *> *)raw {
	[self.userDefaults setObject:raw forKey:@"alerts"];
	[self.userDefaults synchronize];
}

- (void)initialize {
}

- (void)saveAlert:(AAAlertInfo *)alert error:(NSError **)error {
	NSMutableArray *raw = [[self _rawAlerts] mutableCopy];
	[raw addObject:[self _dictFromAlert:alert]];
	[self _saveRawAlerts:raw];
}

- (void)updateAlert:(AAAlertInfo *)alert error:(NSError **)error {
	NSMutableArray *raw = [[self _rawAlerts] mutableCopy];
	for (NSUInteger i = 0; i < raw.count; i++) {
		if ([raw[i][@"identifier"] isEqualToString:alert.identifier]) {
			raw[i] = [self _dictFromAlert:alert];
			break;
		}
	}
	[self _saveRawAlerts:raw];
}

- (void)deleteAlert:(AAAlertInfo *)alert error:(NSError **)error {
	[self deleteAlertWithID:alert.identifier error:error];
}

- (void)deleteAlertWithID:(NSString *)identifier error:(NSError **)error {
	NSMutableArray *raw = [[self _rawAlerts] mutableCopy];
	NSIndexSet *matches = [raw indexesOfObjectsPassingTest:^BOOL(NSDictionary *d, NSUInteger idx, BOOL *stop) {
		return [d[@"identifier"] isEqualToString:identifier];
	}];
	[raw removeObjectsAtIndexes:matches];
	[self _saveRawAlerts:raw];
}

- (void)deleteAlertsWithBundleID:(NSString *)bundleID error:(NSError **)error {
	NSMutableArray *raw = [[self _rawAlerts] mutableCopy];
	NSIndexSet *matches = [raw indexesOfObjectsPassingTest:^BOOL(NSDictionary *d, NSUInteger idx, BOOL *stop) {
		return [d[@"bundleID"] isEqualToString:bundleID];
	}];
	[raw removeObjectsAtIndexes:matches];
	[self _saveRawAlerts:raw];
}

- (AAAlertInfo *)alertWithID:(NSString *)alertID {
	NSArray *rawAlerts = [self _rawAlerts];

	for (NSDictionary *d in rawAlerts) {
		NSString *storedID = d[@"identifier"];
		if ([storedID isEqualToString:alertID]) {
			return [self _alertFromDict:d];
		}
	}
	return nil;
}

- (NSArray<AAAlertInfo *> *)allAlerts {
	NSArray *rawAlerts = [self _rawAlerts];
	NSMutableArray<AAAlertInfo *> *out = [NSMutableArray array];
	for (NSDictionary *d in rawAlerts) {
		[out addObject:[self _alertFromDict:d]];
	}
	return [out copy];
}

@end
