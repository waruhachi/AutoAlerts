#import "../Model/AAAlertInfo.h"
#import "AADataStore.h"
#import "AAUserDefaultsStore.h"

static NSString *const kAlertsKey = @"AutoAlertsStoredAlerts";

@interface AAUserDefaultsStore ()
@end

@implementation AAUserDefaultsStore

#pragma mark - Helpers

- (NSMutableArray<NSDictionary *> *)_rawAlerts {
	NSArray *saved = [[NSUserDefaults standardUserDefaults] objectForKey:kAlertsKey];
	return saved ? [saved mutableCopy] : [NSMutableArray array];
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
	[[NSUserDefaults standardUserDefaults] setObject:raw forKey:kAlertsKey];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - AADataStore

- (void)initialize {
	// Nothing to initialize for user defaults
}

- (void)saveAlert:(AAAlertInfo *)alert error:(NSError **)error {
	NSMutableArray *raw = [self _rawAlerts];
	[raw addObject:[self _dictFromAlert:alert]];
	[self _saveRawAlerts:raw];
}

- (void)updateAlert:(AAAlertInfo *)alert error:(NSError **)error {
	NSMutableArray *raw = [self _rawAlerts];
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
	NSMutableArray *raw = [self _rawAlerts];
	NSIndexSet *matches = [raw indexesOfObjectsPassingTest:^BOOL(NSDictionary *d, NSUInteger idx, BOOL *stop) {
		return [d[@"identifier"] isEqualToString:identifier];
	}];
	[raw removeObjectsAtIndexes:matches];
	[self _saveRawAlerts:raw];
}

- (void)deleteAlertsWithBundleID:(NSString *)bundleID error:(NSError **)error {
	NSMutableArray *raw = [self _rawAlerts];
	NSIndexSet *matches = [raw indexesOfObjectsPassingTest:^BOOL(NSDictionary *d, NSUInteger idx, BOOL *stop) {
		return [d[@"bundleID"] isEqualToString:bundleID];
	}];
	[raw removeObjectsAtIndexes:matches];
	[self _saveRawAlerts:raw];
}

- (AAAlertInfo *)alertWithID:(NSString *)alertID {
	for (NSDictionary *d in [self _rawAlerts]) {
		if ([d[@"identifier"] isEqualToString:alertID]) {
			return [self _alertFromDict:d];
		}
	}
	return nil;
}

- (NSArray<AAAlertInfo *> *)allAlerts {
	NSMutableArray<AAAlertInfo *> *out = [NSMutableArray array];
	for (NSDictionary *d in [self _rawAlerts]) {
		[out addObject:[self _alertFromDict:d]];
	}
	return [out copy];
}

@end
