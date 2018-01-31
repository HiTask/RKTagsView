//
//  RKViewController.m
//  RKTagsView
//
//  Created by Roman Kulesha on 03/02/2016.
//  Copyright (c) 2016 Roman Kulesha. All rights reserved.
//

#import "RKViewController.h"
#import "RKCustomButton.h"
#import <RKTagsView.h>

@interface RKViewController () <UITextFieldDelegate, RKTagsViewDelegate>

@property (weak, nonatomic) IBOutlet RKTagsView *tagsView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tagsViewHeightConstraint;
@property (weak, nonatomic) IBOutlet UILabel *interitemSpacingCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *lineSpacingCountLabel;

@end

@implementation RKViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.tagsView.addTagBySpace = NO;
  self.tagsView.trimAddedTag = YES;
  self.tagsView.textField.placeholder = @"Add tag...";
  self.tagsView.textField.returnKeyType = UIReturnKeyDone;
  self.tagsView.textField.delegate = self;
  self.tagsView.delegate = self;
}

#pragma mark - User Interaction

- (IBAction)editableChanged:(UISwitch *)sender {
  self.tagsView.editable = sender.on;
}

- (IBAction)selectableChanged:(UISwitch *)sender {
  self.tagsView.selectable = sender.on;
}

- (IBAction)multiselectChanged:(UISwitch *)sender {
  self.tagsView.allowsMultipleSelection = sender.on;
}

- (IBAction)buttonStyleChanged:(UISegmentedControl *)sender {
  if (sender.selectedSegmentIndex == 0) {
    self.tagsView.delegate = nil;
  } else {
    self.tagsView.delegate = self;
  }
  [self.tagsView reloadButtons];
}

- (IBAction)enableHeightConstraintChanged:(UISwitch *)sender {
  self.tagsViewHeightConstraint.priority = sender.on ? 999 : 1;
  [self.view layoutIfNeeded];
}

- (IBAction)scrollsHorizontallyChanged:(UISwitch *)sender {
  self.tagsView.scrollsHorizontally = sender.on;
  [self.view layoutIfNeeded];
}

- (IBAction)interitemSpacingChanged:(UIStepper *)sender {
  self.tagsView.interitemSpacing = sender.value;
  self.interitemSpacingCountLabel.text = [NSString stringWithFormat:@"%0.0f", sender.value];
}

- (IBAction)linespacingChanged:(UIStepper *)sender {
  self.tagsView.lineSpacing = sender.value;
  self.lineSpacingCountLabel.text = [NSString stringWithFormat:@"%0.0f", sender.value];
}

- (IBAction)generateTagsTapped {
//  NSString *text = @"Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Donec quam felis, ultricies nec, pellentesque eu, pretium quis, sem. Nulla consequat massa quis enim. Donec pede justo, fringilla vel, aliquet nec, vulputate eget, arcu. In enim justo, rhoncus ut, imperdiet a, venenatis vitae, justo. Nullam dictum felis eu pede mollis pretium. Integer tincidunt.";
	  NSString *text = @"Lorem ipsum  dolor sit amet,  consectetuer adipiscing elit.";
  [self.tagsView removeAllTags];
  NSArray *tagsToAdd = [text componentsSeparatedByString:@"  "];
  for (NSString *word in tagsToAdd) {
    if (word.length > 0) {
      [self.tagsView addTag:word];
    }
  }
}

- (IBAction)removeTagsTapped {
  [self.tagsView removeAllTags];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  [textField resignFirstResponder];
  return YES;
}

#pragma mark - RKTagsViewDelegate

//- (UIButton *)tagsView:(RKTagsView *)tagsView buttonForTagAtIndex:(NSInteger)index {
//  RKCustomButton *customButton = [RKCustomButton buttonWithType:UIButtonTypeSystem];
//  customButton.titleLabel.font = tagsView.font;
//  [customButton setTitle:[NSString stringWithFormat:@"%@", tagsView.tags[index]] forState:UIControlStateNormal];
//  [customButton runBubbleAnimation];
//  return customButton;
//}


@end
