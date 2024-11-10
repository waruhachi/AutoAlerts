#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface AAAppIconCell: UITableViewCell

@property (nonatomic, retain) UIImageView *appIconImageView;
@property (nonatomic, retain) UILabel *appTitleLabel;
@property (nonatomic, retain) NSLayoutConstraint *imageWidthConstraint;
@property (nonatomic, retain) NSLayoutConstraint *imageHeightConstraint;

@end