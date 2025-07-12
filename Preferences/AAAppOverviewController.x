#import <CoreFoundation/CFNotificationCenter.h>

#import "../Tweak/AAAlertManager.h"
#import "AAAlertOverviewController.h"
#import "AAAppOverviewController.h"
#import "AADeleteDelegate.h"
#import "AARootListController.h"

@interface AAAppOverviewController () <UITableViewDelegate, UITableViewDataSource, AADeleteDelegate>

@end

@implementation AAAppOverviewController

- (void)viewDidLoad {
	[super viewDidLoad];

	self.navigationItem.title = self.app.name;

	self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
	self.tableView.delegate = self;
	self.tableView.dataSource = self;

	[self.view addSubview:self.tableView];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];

	dispatch_async(dispatch_get_main_queue(), ^{
		NSArray<AAAlertInfo *> *allAlerts = [[AAAlertManager sharedManager] allAlerts];
		NSMutableArray<AAAlertInfo *> *alertsForThisApp = [NSMutableArray array];

		for (AAAlertInfo *alert in allAlerts) {
			if ([alert.bundleID isEqualToString:self.app.bundleID]) {
				[alertsForThisApp addObject:alert];
			}
		}

		self.app.infos = alertsForThisApp;
		[self.tableView reloadData];
	});
}

- (void)viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];

	self.tableView.frame = self.view.bounds;
}

- (void)didDelete {
	dispatch_async(dispatch_get_main_queue(), ^{
		NSArray<AAAlertInfo *> *allAlerts = [[AAAlertManager sharedManager] allAlerts];
		NSMutableArray<AAAlertInfo *> *alertsForThisApp = [NSMutableArray array];

		for (AAAlertInfo *alert in allAlerts) {
			if ([alert.bundleID isEqualToString:self.app.bundleID]) {
				[alertsForThisApp addObject:alert];
			}
		}

		self.app.infos = alertsForThisApp;

		if (alertsForThisApp.count == 0) {
			for (UIViewController *vc in self.navigationController.viewControllers) {
				if ([vc isKindOfClass:[AARootListController class]]) {
					[self.navigationController popToViewController:vc animated:YES];
					return;
				}
			}
			if (self.deleteDelegate) {
				[self.deleteDelegate didDelete];
			}
			[self.navigationController popViewControllerAnimated:YES];
		} else {
			[self.tableView reloadData];
		}
	});
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.app.infos.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AlertOverviewCell"];

	AAAlertInfo *info = [self.app.infos objectAtIndex:indexPath.row];

	if (!cell) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"AlertOverviewCell"];
	}

	cell.textLabel.text = info.title;
	cell.detailTextLabel.text = info.message;

	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

	return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (section == 0) {
		return @"Automated alerts";
	}

	return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	AAAlertOverviewController *ctrl = [[AAAlertOverviewController alloc] init];
	ctrl.alertInfo = [self.app.infos objectAtIndex:indexPath.row];
	ctrl.appsDict = self.appsDict;
	ctrl.deleteDelegate = self;

	[self.navigationController pushViewController:ctrl animated:YES];

	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		UIAlertController *deleteAlert = [UIAlertController alertControllerWithTitle:@"Delete alert" message:@"Do you really want to delete this automated alert?" preferredStyle:UIAlertControllerStyleActionSheet];

		UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
			if (indexPath.row >= self.app.infos.count) {
				[self.tableView reloadData];
				return;
			}

			AAAlertInfo *alertToDelete = self.app.infos[indexPath.row];

			NSError *deleteError = nil;
			[[AAAlertManager sharedManager] deleteAlertWithID:alertToDelete.identifier error:&deleteError];

			if (deleteError) {
				return;
			}

			CFNotificationCenterPostNotification(
				CFNotificationCenterGetDarwinNotifyCenter(),
				(CFStringRef)[NSString stringWithFormat:@"com.shiftcmdk.autoalerts.delete.%@", alertToDelete.identifier],
				NULL,
				NULL,
				YES);

			NSArray<AAAlertInfo *> *allAlerts = [[AAAlertManager sharedManager] allAlerts];
			NSMutableArray<AAAlertInfo *> *alertsForThisApp = [NSMutableArray array];

			for (AAAlertInfo *alert in allAlerts) {
				if ([alert.bundleID isEqualToString:self.app.bundleID]) {
					[alertsForThisApp addObject:alert];
				}
			}

			self.app.infos = alertsForThisApp;

			if (alertsForThisApp.count == 0) {
				for (UIViewController *vc in self.navigationController.viewControllers) {
					if ([vc isKindOfClass:[AARootListController class]]) {
						[self.navigationController popToViewController:vc animated:YES];
						return;
					}
				}
				if (self.deleteDelegate) {
					[self.deleteDelegate didDelete];
				}
				[self.navigationController popViewControllerAnimated:YES];
			} else {
				[self.tableView reloadData];
			}
		}];

		UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];

		[deleteAlert addAction:deleteAction];
		[deleteAlert addAction:cancelAction];

		UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];

		deleteAlert.popoverPresentationController.sourceView = cell;
		deleteAlert.popoverPresentationController.sourceRect = cell.bounds;

		[self presentViewController:deleteAlert animated:YES completion:nil];
	}
}

@end
