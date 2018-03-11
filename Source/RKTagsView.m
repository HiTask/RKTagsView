#import "RKTagsView.h"

#define DEFAULT_BUTTON_TAG -9999
#define DEFAULT_BUTTON_HORIZONTAL_PADDING 6
#define DEFAULT_BUTTON_VERTICAL_PADDING 2
#define DEFAULT_BUTTON_CORNER_RADIUS 6
#define DEFAULT_BUTTON_BORDER_WIDTH 1

struct InputTextFieldLayoutCalculationContext
{
	CGRect textfieldFrame;
	CGRect lowerFrame;
	CGFloat contentWidth;
} InputTextFieldLayoutCalculationContext;


struct TagButtonLayoutCalculationContext
{
	CGRect buttonFrame;
	CGFloat contentWidth;
} TagButtonLayoutCalculationContext;


const CGFloat RKTagsViewAutomaticDimension = -0.0001;

@interface __RKInputTextField: UITextField
@property (nonatomic, weak) RKTagsView *tagsView;
@end

@interface RKTagsView()
@property () NSUInteger shownTagsCount;
@property (nonatomic, strong) NSMutableArray<NSString *> *mutableTags;
@property (nonatomic, strong) NSMutableArray<UIButton *> *mutableTagButtons;
@property (nonatomic, strong) NSMutableArray<UIButton *> *tagButtonsPool;
@property (nonatomic, strong, readwrite) UIScrollView *scrollView;
@property (nonatomic, strong) __RKInputTextField *inputTextField;
@property (nonatomic, strong) UIButton *becomeFirstResponderButton;
@property (nonatomic) BOOL needScrollToBottomAfterLayout;
- (BOOL)shouldInputTextDeleteBackward;
@end

#pragma mark - RKInputTextField

@implementation __RKInputTextField
- (void)deleteBackward {
  if ([self.tagsView shouldInputTextDeleteBackward]) {
    [super deleteBackward];
  }
}
@end

#pragma mark - RKTagsView

@implementation RKTagsView

#pragma mark Lifecycle

- (instancetype)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self) {
    [self commonSetup];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
  self = [super initWithCoder:coder];
  if (self) {
    [self commonSetup];
  }
  return self;
}

- (void)commonSetup {
  self.mutableTags = [NSMutableArray new];
  self.mutableTagButtons = [NSMutableArray new];
	self.tagButtonsPool = [NSMutableArray new];
  //
  self.scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
  self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  self.scrollView.backgroundColor = nil;
  [self addSubview:self.scrollView];
  //
  self.inputTextField = [__RKInputTextField new];
  self.inputTextField.tagsView = self;
  self.inputTextField.tintColor = self.tintColor;
  self.inputTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
  [self.inputTextField addTarget:self action:@selector(inputTextFieldChanged) forControlEvents:UIControlEventEditingChanged];
  [self.inputTextField addTarget:self action:@selector(inputTextFieldEditingDidBegin) forControlEvents:UIControlEventEditingDidBegin];
  [self.inputTextField addTarget:self action:@selector(inputTextFieldEditingDidEnd) forControlEvents:UIControlEventEditingDidEnd];
  [self.scrollView addSubview:self.inputTextField];
  //
  self.becomeFirstResponderButton = [[UIButton alloc] initWithFrame:self.bounds];
  self.becomeFirstResponderButton.backgroundColor = nil;
  [self.becomeFirstResponderButton addTarget:self.inputTextField action:@selector(becomeFirstResponder) forControlEvents:UIControlEventTouchUpInside];
  [self.scrollView addSubview:self.becomeFirstResponderButton];
  //
  _moreTagsStringSingular = @"+1 more tag";
  _moreTagsStringPlural = @"+%@ more tags";

	_addSpaceAtEndEditing = YES;
	_addTagBySpace = YES;
  _editable = YES;
  _selectable = YES;
  _allowsMultipleSelection = YES;
  _selectBeforeRemoveOnDeleteBackward = YES;
  _deselectAllOnEdit = YES;
  _deselectAllOnEndEditing = YES;
  _lineSpacing = 2;
  _interitemSpacing = 2;
  _tagButtonHeight = RKTagsViewAutomaticDimension;
  _textFieldHeight = RKTagsViewAutomaticDimension;
  _textFieldAlign = RKTagsViewTextFieldAlignCenter;
	_tagsViewAlign = RKTagsViewAlignLeft;
  _deliminater = [NSCharacterSet whitespaceCharacterSet];
  _scrollsHorizontally = NO;
}

#pragma mark Layout

- (void)layoutSubviews {
  [super layoutSubviews];
	
  CGFloat contentWidth = self.bounds.size.width - self.scrollView.contentInset.left - self.scrollView.contentInset.right;
  CGRect lowerFrame = CGRectZero;
  // layout tags buttons
  CGRect previousButtonFrame = CGRectZero;
	BOOL isViewOverfilled = NO;
	_shownTagsCount = 0;
  for (UIButton *button in self.mutableTagButtons) {
	  [button sizeToFit];
	  struct TagButtonLayoutCalculationContext buttonLayoutCalculationContext = [self calculateTagButtonLayout:button with:lowerFrame previousButtonFrame:previousButtonFrame contentWidth:contentWidth];

	  // Checks if current tag button and input text field overfill the view.
	  if (_numberOfTagLines > 0 && !_displayMoreTagsCount) {
		  NSUInteger lineIndex = [self lineIndexOfElementWith:buttonLayoutCalculationContext.buttonFrame];
		  if (lineIndex >= _numberOfTagLines) {
			  isViewOverfilled = YES;
		  }
	  } else if (_numberOfTagLines > 0 && _displayMoreTagsCount) {
		  NSUInteger notShownTagsCount = self.mutableTagButtons.count - _shownTagsCount;
		  [self updateMoreTagsLabel:notShownTagsCount];
		  [self.inputTextField sizeToFit];
		  struct InputTextFieldLayoutCalculationContext inputTextFieldLayoutCalculationContext = [self calculateTextFieldLayoutWith:buttonLayoutCalculationContext.buttonFrame previousButtonFrame:buttonLayoutCalculationContext.buttonFrame contentWidth:buttonLayoutCalculationContext.contentWidth];

		  NSUInteger lineIndex = [self lineIndexOfElementWith:inputTextFieldLayoutCalculationContext.textfieldFrame];
		  if (lineIndex >= _numberOfTagLines) {
			  isViewOverfilled = YES;
		  }
	  }

	  if (!isViewOverfilled) {
		  if (button.superview == nil) {
			  [self.scrollView addSubview:button];
		  }
		  
		  [self setOriginalFrame:buttonLayoutCalculationContext.buttonFrame forView:button];
		  contentWidth = buttonLayoutCalculationContext.contentWidth;
		  previousButtonFrame = buttonLayoutCalculationContext.buttonFrame;
		  if (CGRectGetMaxY(lowerFrame) < CGRectGetMaxY(buttonLayoutCalculationContext.buttonFrame)) {
			  lowerFrame = buttonLayoutCalculationContext.buttonFrame;
		  }
		  _shownTagsCount++;
	  } else {
		  break;
	  }
  }

	// Removes tag buttons from view which overfill it.
	for (NSUInteger i = _shownTagsCount; i < self.mutableTagButtons.count; i++) {
		UIButton *button = self.mutableTagButtons[i];
		[button removeFromSuperview];
	}

  // layout textfield if needed
  if (self.editable || _displayMoreTagsCount) {
	  [self updateMoreTagsLabel];
	  [self.inputTextField sizeToFit];
	  struct InputTextFieldLayoutCalculationContext layoutCalculationContext = [self calculateTextFieldLayoutWith:lowerFrame previousButtonFrame:previousButtonFrame contentWidth:contentWidth];
	  [self setOriginalFrame:layoutCalculationContext.textfieldFrame forView:self.inputTextField];
	  lowerFrame = layoutCalculationContext.lowerFrame;
	  contentWidth = layoutCalculationContext.contentWidth;
  }
  // set content size
  CGSize oldContentSize = self.contentSize;
  self.scrollView.contentSize = CGSizeMake(contentWidth, CGRectGetMaxY(lowerFrame));
  if ((_scrollsHorizontally && contentWidth > self.bounds.size.width) || (!_scrollsHorizontally && oldContentSize.height != self.contentSize.height)) {
    [self invalidateIntrinsicContentSize];
    if ([self.delegate respondsToSelector:@selector(tagsViewContentSizeDidChange:)]) {
      [self.delegate tagsViewContentSizeDidChange:self];
    }
  }
  // layout becomeFirstResponder button
  self.becomeFirstResponderButton.frame = CGRectMake(-self.scrollView.contentInset.left, -self.scrollView.contentInset.top, self.contentSize.width, self.contentSize.height);
  [self.scrollView bringSubviewToFront:self.becomeFirstResponderButton];
	
	[self fixTagsAligning];
}



- (NSUInteger)lineIndexOfElementWith:(CGRect)frame {
	NSUInteger lineIndex = (frame.origin.y - self.scrollView.contentInset.top) / (_lineSpacing + frame.size.height);
	return lineIndex;
}


- (BOOL)constantHeight {
	BOOL constantHeight = (_numberOfTagLines > 0);
	return constantHeight;
}


- (void)fixTagsAligning {
	if (_tagsViewAlign == RKTagsViewAlignLeft) {
		return;
	}
	
	NSUInteger i = 0;
	while (i < _shownTagsCount) {
		NSUInteger indexOfLastTagInRow = [self indexOfLastTagInRowStaringFrom:i];
		CGFloat rightPaddingOfRow = [self rightPaddingOfRowStaringFrom:i];
											  
		[self moveTagsFrom:i to:indexOfLastTagInRow byXOffset:rightPaddingOfRow];
		i = indexOfLastTagInRow + 1;
	}
}


- (void)moveTagsFrom:(NSUInteger)startIndex to:(NSUInteger)endIndex byXOffset:(CGFloat)offset {
	for (NSUInteger i = startIndex; i <= endIndex; i++) {
		UIButton *button = self.mutableTagButtons[i];
		CGRect frame = button.frame;
		frame.origin.x += offset;
		button.frame = frame;
	}
}


- (NSUInteger)indexOfLastTagInRowStaringFrom:(NSUInteger)startIndex {
	NSUInteger index = startIndex;
	UIButton *startButton = self.mutableTagButtons[startIndex];
	
	while (index < _shownTagsCount - 1) {
		UIButton *nextButton = self.mutableTagButtons[index + 1];
		if (nextButton.frame.origin.y != startButton.frame.origin.y) {
			break;
		}
		
		index++;
	}
	
	return index;
}


- (CGFloat)rightPaddingOfRowStaringFrom:(NSUInteger)startIndex {
	NSUInteger indexOfLastTagInRow = [self indexOfLastTagInRowStaringFrom:startIndex];
	UIButton *lastTagInRow = self.mutableTagButtons[indexOfLastTagInRow];
	CGFloat rightPaddingOfRow = self.scrollView.contentSize.width - self.scrollView.contentInset.right - (lastTagInRow.frame.origin.x + lastTagInRow.frame.size.width);
	
	return rightPaddingOfRow;
}


// input: UIView *button, CGRect previousButtonFrame, CGRect lowerFrame, CGFloat contentWidth
// output: CGFloat contentWidth, buttonFrame
- (struct TagButtonLayoutCalculationContext)calculateTagButtonLayout:(UIView *)button
																with:(CGRect)lowerFrame
												 previousButtonFrame:(CGRect)previousButtonFrame
														contentWidth:(CGFloat)contentWidth {
	struct TagButtonLayoutCalculationContext layoutCalculationContext;
	layoutCalculationContext.contentWidth = contentWidth;
	layoutCalculationContext.buttonFrame = [self originalFrameForView:button];

	if (_scrollsHorizontally || (CGRectGetMaxX(previousButtonFrame) + self.interitemSpacing + layoutCalculationContext.buttonFrame.size.width <= layoutCalculationContext.contentWidth)) {
		layoutCalculationContext.buttonFrame.origin.x = CGRectGetMaxX(previousButtonFrame);
		if (layoutCalculationContext.buttonFrame.origin.x > 0) {
			layoutCalculationContext.buttonFrame.origin.x += self.interitemSpacing;
		}
		layoutCalculationContext.buttonFrame.origin.y = CGRectGetMinY(previousButtonFrame);
		if (_scrollsHorizontally && CGRectGetMaxX(layoutCalculationContext.buttonFrame) > self.bounds.size.width) {
			layoutCalculationContext.contentWidth = CGRectGetMaxX(layoutCalculationContext.buttonFrame) + self.interitemSpacing;
		}
	} else {
		layoutCalculationContext.buttonFrame.origin.x = 0;
		layoutCalculationContext.buttonFrame.origin.y = MAX(CGRectGetMaxY(lowerFrame), CGRectGetMaxY(previousButtonFrame));
		if (layoutCalculationContext.buttonFrame.origin.y > 0) {
			layoutCalculationContext.buttonFrame.origin.y += self.lineSpacing;
		}
		if (layoutCalculationContext.buttonFrame.size.width > layoutCalculationContext.contentWidth) {
			layoutCalculationContext.buttonFrame.size.width = layoutCalculationContext.contentWidth;
		}
	}
	if (self.tagButtonHeight > RKTagsViewAutomaticDimension) {
		layoutCalculationContext.buttonFrame.size.height = self.tagButtonHeight;
	}

	return layoutCalculationContext;
}


// input: CGFloat contentWidth, lowerFrame, previousButtonFrame
// output: CGRect textfieldFrame, CGRect lowerFrame, CGFloat contentWidth
- (struct InputTextFieldLayoutCalculationContext)calculateTextFieldLayoutWith:(CGRect)lowerFrame
														  previousButtonFrame:(CGRect)previousButtonFrame
																 contentWidth:(CGFloat)contentWidth {
	struct InputTextFieldLayoutCalculationContext layoutCalculationContext;
	layoutCalculationContext.lowerFrame = lowerFrame;
	layoutCalculationContext.contentWidth = contentWidth;
	layoutCalculationContext.textfieldFrame = [self originalFrameForView:self.inputTextField];

	if (self.textFieldHeight > RKTagsViewAutomaticDimension) {
		layoutCalculationContext.textfieldFrame.size.height = self.textFieldHeight;
	}
	if (self.mutableTagButtons.count == 0) {
		layoutCalculationContext.textfieldFrame.origin.x = 0;
		layoutCalculationContext.textfieldFrame.size.width = contentWidth;
		layoutCalculationContext.lowerFrame = layoutCalculationContext.textfieldFrame;
		
		switch (self.textFieldAlign) {
			case RKTagsViewTextFieldAlignTop:
				layoutCalculationContext.textfieldFrame.origin.y = 0;
				break;
			case RKTagsViewTextFieldAlignCenter:
				layoutCalculationContext.textfieldFrame.origin.y = (self.bounds.size.height - layoutCalculationContext.textfieldFrame.size.height) / 2;
				break;
			case RKTagsViewTextFieldAlignBottom:
				layoutCalculationContext.textfieldFrame.origin.y = self.bounds.size.height - layoutCalculationContext.textfieldFrame.size.height;
		}
	} else if (_scrollsHorizontally || (CGRectGetMaxX(previousButtonFrame) + self.interitemSpacing + layoutCalculationContext.textfieldFrame.size.width <= contentWidth)) {
		layoutCalculationContext.textfieldFrame.origin.x = self.interitemSpacing + CGRectGetMaxX(previousButtonFrame);
		switch (self.textFieldAlign) {
			case RKTagsViewTextFieldAlignTop:
				layoutCalculationContext.textfieldFrame.origin.y = CGRectGetMinY(previousButtonFrame);
				break;
			case RKTagsViewTextFieldAlignCenter:
				layoutCalculationContext.textfieldFrame.origin.y = CGRectGetMinY(previousButtonFrame) + (previousButtonFrame.size.height - layoutCalculationContext.textfieldFrame.size.height) / 2;
				break;
			case RKTagsViewTextFieldAlignBottom:
				layoutCalculationContext.textfieldFrame.origin.y = CGRectGetMinY(previousButtonFrame) + (previousButtonFrame.size.height - layoutCalculationContext.textfieldFrame.size.height);
		}
		if (_scrollsHorizontally) {
			layoutCalculationContext.textfieldFrame.size.width = self.inputTextField.bounds.size.width;
			if (CGRectGetMaxX(layoutCalculationContext.textfieldFrame) > self.bounds.size.width) {
				layoutCalculationContext.contentWidth += layoutCalculationContext.textfieldFrame.size.width;
			}
		} else {
			layoutCalculationContext.textfieldFrame.size.width = layoutCalculationContext.contentWidth - layoutCalculationContext.textfieldFrame.origin.x;
		}
		if (CGRectGetMaxY(layoutCalculationContext.lowerFrame) < CGRectGetMaxY(layoutCalculationContext.textfieldFrame)) {
			layoutCalculationContext.lowerFrame = layoutCalculationContext.textfieldFrame;
		}
	} else {
		layoutCalculationContext.textfieldFrame.origin.x = 0;
		switch (self.textFieldAlign) {
			case RKTagsViewTextFieldAlignTop:
				layoutCalculationContext.textfieldFrame.origin.y = CGRectGetMaxY(previousButtonFrame) + self.lineSpacing;
				break;
			case RKTagsViewTextFieldAlignCenter:
				layoutCalculationContext.textfieldFrame.origin.y = CGRectGetMaxY(previousButtonFrame) + self.lineSpacing + (previousButtonFrame.size.height - layoutCalculationContext.textfieldFrame.size.height) / 2;
				break;
			case RKTagsViewTextFieldAlignBottom:
				layoutCalculationContext.textfieldFrame.origin.y = CGRectGetMaxY(previousButtonFrame) + self.lineSpacing + (previousButtonFrame.size.height - layoutCalculationContext.textfieldFrame.size.height);
		}
		layoutCalculationContext.textfieldFrame.size.width = layoutCalculationContext.contentWidth;
		CGRect nextButtonFrame = CGRectMake(0, CGRectGetMaxY(previousButtonFrame) + self.lineSpacing, 0, previousButtonFrame.size.height);
		layoutCalculationContext.lowerFrame = (CGRectGetMaxY(layoutCalculationContext.textfieldFrame) < CGRectGetMaxY(nextButtonFrame)) ?  nextButtonFrame : layoutCalculationContext.textfieldFrame;
	}

	return layoutCalculationContext;
}

- (CGSize)intrinsicContentSize {
  return self.contentSize;
}

#pragma mark Property Accessors

- (UITextField *)textField {
  return self.inputTextField;
}

- (NSArray<NSString *> *)tags {
  return self.mutableTags.copy;
}

- (NSArray<NSNumber *> *)selectedTagIndexes {
  NSMutableArray *mutableIndexes = [NSMutableArray new];
  for (int index = 0; index < self.mutableTagButtons.count; index++) {
    if (self.mutableTagButtons[index].selected) {
      [mutableIndexes addObject:@(index)];
    }
  }
  return mutableIndexes.copy;
}

- (void)setFont:(UIFont *)font {
  if (self.inputTextField.font == font) {
    return;
  }
  self.inputTextField.font = font;
  for (UIButton *button in self.mutableTagButtons) {
    if (button.tag == DEFAULT_BUTTON_TAG) {
      button.titleLabel.font = font;
      [button sizeToFit];
      [self setNeedsLayout];
    }
  }
}

- (UIFont *)font {
  return self.inputTextField.font;
}

- (CGSize)contentSize {
  return CGSizeMake(_scrollsHorizontally ? (self.scrollView.contentSize.width + self.scrollView.contentInset.left + self.scrollView.contentInset.right) : self.bounds.size.width, self.scrollView.contentSize.height + self.scrollView.contentInset.top + self.scrollView.contentInset.bottom);
}

- (void)setEditable:(BOOL)editable {
  if (_editable == editable) {
    return;
  }
  _editable = editable;
  [self invalidateInputTextFieldVisibility];
}


- (void)setDisplayMoreTagsCount:(BOOL)displayMoreTagsCount {
	if (_displayMoreTagsCount == displayMoreTagsCount) {
		return;
	}
	_displayMoreTagsCount = displayMoreTagsCount;
	[self invalidateInputTextFieldVisibility];
}


- (void)setNumberOfTagLines:(NSUInteger)numberOfTagLines {
	if (_numberOfTagLines == numberOfTagLines) {
		return;
	}
	_numberOfTagLines = numberOfTagLines;
	[self invalidateInputTextFieldVisibility];
}


- (void)invalidateInputTextFieldVisibility {
	if (_editable) {
		self.inputTextField.hidden = NO;
		self.becomeFirstResponderButton.hidden = self.inputTextField.isFirstResponder;
	} else if (!_displayMoreTagsCount) {
		[self endEditing:YES];
		self.inputTextField.text = @"";
		self.inputTextField.hidden = YES;
		self.becomeFirstResponderButton.hidden = YES;
	} else {
		[self endEditing:YES];
		self.inputTextField.hidden = NO;
		self.inputTextField.userInteractionEnabled = NO;
		self.becomeFirstResponderButton.hidden = YES;
		[self updateMoreTagsLabel];
	}
	[self setNeedsLayout];
}


- (void)setLineSpacing:(CGFloat)lineSpacing {
  if (_lineSpacing != lineSpacing) {
    _lineSpacing = lineSpacing;
    [self setNeedsLayout];
  }
}

- (void)setScrollsHorizontally:(BOOL)scrollsHorizontally {
  if (_scrollsHorizontally != scrollsHorizontally) {
    _scrollsHorizontally = scrollsHorizontally;
    [self setNeedsLayout];
  }
}

- (void)setInteritemSpacing:(CGFloat)interitemSpacing {
  if (_interitemSpacing != interitemSpacing) {
    _interitemSpacing = interitemSpacing;
    [self setNeedsLayout];
  }
}

- (void)setTagButtonHeight:(CGFloat)tagButtonHeight {
  if (_tagButtonHeight != tagButtonHeight) {
    _tagButtonHeight = tagButtonHeight;
    [self setNeedsLayout];
  }
}

- (void)setTextFieldHeight:(CGFloat)textFieldHeight {
  if (_textFieldHeight != textFieldHeight) {
    _textFieldHeight = textFieldHeight;
    [self setNeedsLayout];
  }
}

- (void)setTextFieldAlign:(RKTagsViewTextFieldAlign)textFieldAlign {
  if (_textFieldAlign != textFieldAlign) {
    _textFieldAlign = textFieldAlign;
    [self setNeedsLayout];
  }
}

- (void)setTintColor:(UIColor *)tintColor {
  if (super.tintColor == tintColor) {
    return;
  }
  super.tintColor = tintColor;
  self.inputTextField.tintColor = tintColor;
  for (UIButton *button in self.mutableTagButtons) {
    if (button.tag == DEFAULT_BUTTON_TAG) {
      button.tintColor = tintColor;
      button.layer.borderColor = tintColor.CGColor;
      button.backgroundColor = button.selected ? tintColor : nil;
      [button setTitleColor:tintColor forState:UIControlStateNormal];
    }
  }
}

#pragma mark Public

- (NSInteger)indexForTagAtScrollViewPoint:(CGPoint)point {
  for (int index = 0; index < self.mutableTagButtons.count; index++) {
    if (CGRectContainsPoint(self.mutableTagButtons[index].frame, point)) {
      return index;
    }
  }
  return NSNotFound;
}

- (nullable __kindof UIButton *)buttonForTagAtIndex:(NSInteger)index {
  if (index >= 0 && index < self.mutableTagButtons.count) {
    return self.mutableTagButtons[index];
  } else {
    return nil;
  }
}

- (void)reloadButtons {
  NSArray *tags = self.tags;
  [self removeAllTags];
  for (NSString *tag in tags) {
    [self addTag:tag];
  }
}

- (void)addTag:(NSString *)tag {
	[self addTag:tag updateMoreTagsLabel:YES];
}

- (void)addTag:(NSString *)tag updateMoreTagsLabel:(BOOL)updateMoreTagsLabel {
  if (tag == nil) {
	return;
  }

  NSString *tagToAdd;
  if (_trimAddedTag) {
	tagToAdd = [tag stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  } else {
	tagToAdd = tag;
  }
  if (tagToAdd.length > 0) {
	[self insertTag:tagToAdd atIndex:self.mutableTags.count updateMoreTagsLabel:NO];
	  [self updateMoreTagsLabel];
  }
}

- (void)addTags:(NSArray<NSString *> *)tags {
	for (NSString *tag in tags) {
		[self addTag:tag updateMoreTagsLabel:NO];
	}
	[self updateMoreTagsLabel];
}


- (void)insertTag:(NSString *)tag atIndex:(NSInteger)index  {
	[self insertTag:tag atIndex:index updateMoreTagsLabel:YES];
}

- (void)insertTag:(NSString *)tag atIndex:(NSInteger)index updateMoreTagsLabel:(BOOL)updateMoreTagsLabel {
	
	BOOL isReuseButtonDelegateImplemented = (self.delegate != nil && [self.delegate respondsToSelector:@selector(tagsView:reuseButton:forTagAtIndex:)]);
  if (index >= 0 && index <= self.mutableTags.count) {
    [self.mutableTags insertObject:tag atIndex:index];
    UIButton *tagButton;
	  if (isReuseButtonDelegateImplemented && self.tagButtonsPool.count > 0) {
		  tagButton = self.tagButtonsPool.lastObject;
		  [self.tagButtonsPool removeObject:tagButton];
		  [self.delegate tagsView:self reuseButton:tagButton forTagAtIndex:index];
	  } else if ([self.delegate respondsToSelector:@selector(tagsView:buttonForTagAtIndex:)]) {
      tagButton = [self.delegate tagsView:self buttonForTagAtIndex:index];
    } else {
      tagButton = [UIButton new];
      tagButton.layer.cornerRadius = DEFAULT_BUTTON_CORNER_RADIUS;
      tagButton.layer.borderWidth = DEFAULT_BUTTON_BORDER_WIDTH;
      tagButton.layer.borderColor = self.tintColor.CGColor;
      tagButton.titleLabel.font = self.font;
      tagButton.tintColor = self.tintColor;
      tagButton.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
      [tagButton setTitle:tag forState:UIControlStateNormal];
      [tagButton setTitleColor:self.tintColor forState:UIControlStateNormal];
      [tagButton setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
      tagButton.contentEdgeInsets = UIEdgeInsetsMake(DEFAULT_BUTTON_VERTICAL_PADDING, DEFAULT_BUTTON_HORIZONTAL_PADDING, DEFAULT_BUTTON_VERTICAL_PADDING, DEFAULT_BUTTON_HORIZONTAL_PADDING);
      tagButton.tag = DEFAULT_BUTTON_TAG;
    }
    [tagButton sizeToFit];
    tagButton.exclusiveTouch = YES;
    [tagButton addTarget:self action:@selector(tagButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.mutableTagButtons insertObject:tagButton atIndex:index];
	  self.shownTagsCount = self.mutableTags.count;
    [self.scrollView addSubview:tagButton];
	  if (updateMoreTagsLabel) {
		  [self updateMoreTagsLabel];
	  }
    [self setNeedsLayout];
  }
}

- (void)moveTagAtIndex:(NSInteger)index toIndex:(NSInteger)newIndex {
  if (index >= 0 && index <= self.mutableTags.count
      && newIndex >= 0 && newIndex <= self.mutableTags.count
      && index != newIndex) {
    NSString *tag = self.mutableTags[index];
    UIButton *button = self.mutableTagButtons[index];
    [self.mutableTags removeObjectAtIndex:index];
    [self.mutableTagButtons removeObjectAtIndex:index];
    [self.mutableTags insertObject:tag atIndex:newIndex];
    [self.mutableTagButtons insertObject:button atIndex:newIndex];
	  [self updateMoreTagsLabel];
    [self setNeedsLayout];
    [self layoutIfNeeded];
  }
}

- (void)removeTagAtIndex:(NSInteger)index {
  if (index >= 0 && index < self.mutableTags.count) {
	  UIButton *tagButton = self.mutableTagButtons[index];
	  [self.tagButtonsPool addObject:tagButton];
    [self.mutableTags removeObjectAtIndex:index];
    [tagButton removeFromSuperview];
	  self.shownTagsCount = self.mutableTags.count;
    [self.mutableTagButtons removeObject:tagButton];
	  [self updateMoreTagsLabel];
    [self setNeedsLayout];
  }
}

- (void)removeAllTags {
  [self.mutableTags removeAllObjects];
	self.shownTagsCount = self.mutableTags.count;
  [self.mutableTagButtons makeObjectsPerformSelector:@selector(removeFromSuperview) withObject:nil];
	[self.tagButtonsPool addObjectsFromArray:self.mutableTagButtons];
  [self.mutableTagButtons removeAllObjects];
	[self updateMoreTagsLabel];
  [self setNeedsLayout];
}

- (void)selectTagAtIndex:(NSInteger)index {
  if (index >= 0 && index < self.mutableTagButtons.count) {
    if (!self.allowsMultipleSelection) {
      [self deselectAll];
    }
    self.mutableTagButtons[index].selected = YES;
    if (self.mutableTagButtons[index].tag == DEFAULT_BUTTON_TAG) {
      self.mutableTagButtons[index].backgroundColor = self.tintColor;
    }
  }
}

- (void)deselectTagAtIndex:(NSInteger)index {
  if (index >= 0 && index < self.mutableTagButtons.count) {
    self.mutableTagButtons[index].selected = NO;
    if (self.mutableTagButtons[index].tag == DEFAULT_BUTTON_TAG) {
      self.mutableTagButtons[index].backgroundColor = nil;
    }
  }
}

- (void)selectAll {
  for (int index = 0; index < self.mutableTagButtons.count; index++) {
    [self selectTagAtIndex:index];
  }
}

- (void)deselectAll {
  for (int index = 0; index < self.mutableTagButtons.count; index++) {
    [self deselectTagAtIndex:index];
  }
}

#pragma mark Handlers


- (void)inputTextFieldChanged {
	if (_trimRepeatedSpacesAtInput) {
		NSInteger infiniteCycleGuardCount = 10;
		while ([self.textField.text containsString:@"  "] && --infiniteCycleGuardCount > 0) {
			self.textField.text = [self.textField.text stringByReplacingOccurrencesOfString:@"  " withString:@" "];
		}
	}
	
  if (self.deselectAllOnEdit) {
    [self deselectAll];
  }
	
  if (_addTagBySpace) {
	  NSMutableArray *tags = [[(self.inputTextField.text ?: @"") componentsSeparatedByCharactersInSet:self.deliminater] mutableCopy];
	  self.inputTextField.text = [tags lastObject];
	  [tags removeLastObject];
	  for (NSString *tag in tags) {
		if ([tag isEqualToString:@""] || ([self.delegate respondsToSelector:@selector(tagsView:shouldAddTagWithText:)] && ![self.delegate tagsView:self shouldAddTagWithText:tag])) {
		  continue;
		}
		[self addTag:tag];
		if ([self.delegate respondsToSelector:@selector(tagsViewDidChange:)]) {
		  [self.delegate tagsViewDidChange:self];
		}
	  }
  }
	
  [self setNeedsLayout];
  [self layoutIfNeeded];
	
  // scroll if needed
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    if (_scrollsHorizontally) {
      if (self.scrollView.contentSize.width > self.bounds.size.width) {
        CGPoint leftOffset = CGPointMake(self.scrollView.contentSize.width - self.bounds.size.width, -self.scrollView.contentInset.top);
        [self.scrollView setContentOffset:leftOffset animated:YES];
      }
    } else {
      if (self.scrollView.contentInset.top + self.scrollView.contentSize.height > self.bounds.size.height) {
        CGPoint bottomOffset = CGPointMake(-self.scrollView.contentInset.left, self.scrollView.contentSize.height - self.bounds.size.height - (-self.scrollView.contentInset.top));
        [self.scrollView setContentOffset:bottomOffset animated:YES];
      }
    }
  });
}

- (void)inputTextFieldEditingDidBegin {
  self.becomeFirstResponderButton.hidden = YES;
}

- (void)inputTextFieldEditingDidEnd {
  if (self.inputTextField.text.length > 0 && _addSpaceAtEndEditing) {
    self.inputTextField.text = [NSString stringWithFormat:@"%@ ", self.inputTextField.text];
    [self inputTextFieldChanged];
  }
  if (self.deselectAllOnEndEditing) {
    [self deselectAll];
  }
  self.becomeFirstResponderButton.hidden = !self.editable;
}

- (BOOL)shouldInputTextDeleteBackward {
	NSInteger cursorPosition = [self.textField offsetFromPosition:self.textField.beginningOfDocument toPosition:self.textField.selectedTextRange.start];
	BOOL isCursorPositionAtBeginningOfDocument = (cursorPosition == 0 && self.textField.selectedTextRange.isEmpty);

  NSArray<NSNumber *> *tagIndexes = self.selectedTagIndexes;
  if (tagIndexes.count > 0) {
    for (NSInteger i = tagIndexes.count - 1; i >= 0; i--) {
      if ([self.delegate respondsToSelector:@selector(tagsView:shouldRemoveTagAtIndex:)] && ![self.delegate tagsView:self shouldRemoveTagAtIndex:tagIndexes[i].integerValue]) {
        continue;
      }
      [self removeTagAtIndex:tagIndexes[i].integerValue];
      if ([self.delegate respondsToSelector:@selector(tagsViewDidChange:)]) {
        [self.delegate tagsViewDidChange:self];
      }
    }
    return NO;
  } else if (self.mutableTags.count > 0 && isCursorPositionAtBeginningOfDocument) {
    NSInteger lastTagIndex = self.mutableTags.count - 1;
    if (self.selectBeforeRemoveOnDeleteBackward) {
      if ([self.delegate respondsToSelector:@selector(tagsView:shouldSelectTagAtIndex:)] && ![self.delegate tagsView:self shouldSelectTagAtIndex:lastTagIndex]) {
        return NO;
      } else {
        [self selectTagAtIndex:lastTagIndex];
        return NO;
      }
    } else {
      if ([self.delegate respondsToSelector:@selector(tagsView:shouldRemoveTagAtIndex:)] && ![self.delegate tagsView:self shouldRemoveTagAtIndex:lastTagIndex]) {
        return NO;
      } else {
        [self removeTagAtIndex:lastTagIndex];
        if ([self.delegate respondsToSelector:@selector(tagsViewDidChange:)]) {
          [self.delegate tagsViewDidChange:self];
        }
        return NO;
      }
    }
    
  }
  else {
    return YES;
  }
}

- (void)tagButtonTapped:(UIButton *)button {
	int buttonIndex = (int)[self.mutableTagButtons indexOfObject:button];
	
	if ([self.delegate respondsToSelector:@selector(tagsView:tagTappedAtIndex:)]) {
		[self.delegate tagsView:self tagTappedAtIndex:buttonIndex];
	}
	
  if (self.selectable) {
    if (button.selected) {
      if ([self.delegate respondsToSelector:@selector(tagsView:shouldDeselectTagAtIndex:)] && ![self.delegate tagsView:self shouldDeselectTagAtIndex:buttonIndex]) {
        return;
      }
      [self deselectTagAtIndex:buttonIndex];
    } else {
      if ([self.delegate respondsToSelector:@selector(tagsView:shouldSelectTagAtIndex:)] && ![self.delegate tagsView:self shouldSelectTagAtIndex:buttonIndex]) {
        return;
      }
      [self selectTagAtIndex:buttonIndex];
    }
  }
}


#pragma mark Internal Helpers

- (CGRect)originalFrameForView:(UIView *)view {
  if (CGAffineTransformIsIdentity(view.transform)) {
    return view.frame;
  } else {
    CGAffineTransform currentTransform = view.transform;
    view.transform = CGAffineTransformIdentity;
    CGRect originalFrame = view.frame;
    view.transform = currentTransform;
    return originalFrame;
  }
}

- (void)setOriginalFrame:(CGRect)originalFrame forView:(UIView *)view {
  if (CGAffineTransformIsIdentity(view.transform)) {
    view.frame = originalFrame;
  } else {
    CGAffineTransform currentTransform = view.transform;
    view.transform = CGAffineTransformIdentity;
    view.frame = originalFrame;
    view.transform = currentTransform;
  }

}


- (void)updateMoreTagsLabel {
	NSUInteger notShownTagsCount = self.mutableTags.count - _shownTagsCount;
	[self updateMoreTagsLabel:notShownTagsCount];
}


- (void)updateMoreTagsLabel:(NSUInteger)notShownTagsCount {
	if (_displayMoreTagsCount) {
		if (notShownTagsCount == 1) {
			self.inputTextField.text = _moreTagsStringSingular;
		} else if (notShownTagsCount > 1) {
			self.inputTextField.text = [NSString stringWithFormat:_moreTagsStringPlural, @(notShownTagsCount)];
		} else {
			self.inputTextField.text = nil;
		}
	} else if (self.constantHeight) {
		self.inputTextField.text = nil;
	}
}

@end
