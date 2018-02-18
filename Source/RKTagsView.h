#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

UIKIT_EXTERN const CGFloat RKTagsViewAutomaticDimension; // use sizeToFit

typedef NS_ENUM(NSInteger, RKTagsViewTextFieldAlign) { // align is relative to a last tag
  RKTagsViewTextFieldAlignTop,
  RKTagsViewTextFieldAlignCenter,
  RKTagsViewTextFieldAlignBottom,
};

typedef NS_ENUM(NSInteger, RKTagsViewAlign) {
	RKTagsViewAlignLeft,
	RKTagsViewAlignRight,
};

@class RKTagsView;

@protocol RKTagsViewDelegate <NSObject>

@optional

- (UIButton *)tagsView:(RKTagsView *)tagsView buttonForTagAtIndex:(NSInteger)index; // used default tag button if not implemented
- (BOOL)tagsView:(RKTagsView *)tagsView shouldAddTagWithText:(NSString *)text; // called when 'space' key pressed. return NO to ignore tag
- (BOOL)tagsView:(RKTagsView *)tagsView shouldSelectTagAtIndex:(NSInteger)index; // called when tag pressed. return NO to disallow selecting tag
- (BOOL)tagsView:(RKTagsView *)tagsView shouldDeselectTagAtIndex:(NSInteger)index; // called when selected tag pressed. return NO to disallow deselecting tag
- (void)tagsView:(RKTagsView *)tagsView tagTappedAtIndex:(NSInteger)index; // called when tag pressed, regardless of its selection state.
- (BOOL)tagsView:(RKTagsView *)tagsView shouldRemoveTagAtIndex:(NSInteger)index; // called when 'backspace' key pressed. return NO to disallow removing tag

- (void)tagsViewDidChange:(RKTagsView *)tagsView; // called when tag was added or removed by user
- (void)tagsViewContentSizeDidChange:(RKTagsView *)tagsView;

@end

@interface RKTagsView: UIView

@property (nonatomic, strong, readonly) UIScrollView *scrollView; // scrollView delegate is not used
@property (nonatomic, strong, readonly) UITextField *textField; // textfield delegate is not used
@property (nonatomic, copy, readonly) NSArray<NSString *> *tags;
@property (nonatomic, copy, readonly) NSArray<NSNumber *> *selectedTagIndexes;
@property (nonatomic, weak, nullable) IBOutlet id<RKTagsViewDelegate> delegate;
@property (nonatomic, readonly) CGSize contentSize;

@property (nonatomic) BOOL addSpaceAtEndEditing; // default is YES
@property (nonatomic) BOOL trimRepeatedSpacesAtInput; // default is NO
// Doesn't allow to display tags more then view's height.
@property (nonatomic) BOOL constantHeight; // default is NO
// Works only when constantHeight = YES and editable = NO, show not shown tags count in textField instead of placeholder.
@property (nonatomic) BOOL displayMoreTagsCount; // default is NO
@property (nonatomic) NSString *moreTagsStringSingular; // default is @"+1 more tag"
@property (nonatomic) NSString *moreTagsStringPlural; // default is @"+%@ more tags"
@property (nonatomic) BOOL addTagBySpace; // default is YES
// Sets to trims input tag string, spaces and new lines.
@property (nonatomic) BOOL trimAddedTag; // default is NO
@property (nonatomic, strong) UIFont *font; // default is font from textfield
@property (nonatomic) BOOL editable; // default is YES
@property (nonatomic) BOOL selectable; // default is YES
@property (nonatomic) BOOL allowsMultipleSelection; // default is YES
@property (nonatomic) BOOL selectBeforeRemoveOnDeleteBackward; // default is YES
@property (nonatomic) BOOL deselectAllOnEdit; // default is YES
@property (nonatomic) BOOL deselectAllOnEndEditing; // default is YES
@property (nonatomic) BOOL scrollsHorizontally; // default is NO

@property (nonatomic) CGFloat lineSpacing; // default is 2
@property (nonatomic) CGFloat interitemSpacing; // default is 2
@property (nonatomic) CGFloat tagButtonHeight; // default is auto
@property (nonatomic) CGFloat textFieldHeight; // default is auto
@property (nonatomic) RKTagsViewTextFieldAlign textFieldAlign; // default is center
// Use it only when displayMoreTagsCount = NO and editable = NO.
@property (nonatomic) RKTagsViewAlign tagsViewAlign; // default is left

@property (nonatomic, strong) NSCharacterSet* deliminater; // defailt is [NSCharacterSet whitespaceCharacterSet]

- (NSInteger)indexForTagAtScrollViewPoint:(CGPoint)point; // NSNotFound if not found
- (nullable __kindof UIButton *)buttonForTagAtIndex:(NSInteger)index;
- (void)reloadButtons;

- (void)addTag:(NSString *)tag;
- (void)insertTag:(NSString *)tag atIndex:(NSInteger)index;
- (void)moveTagAtIndex:(NSInteger)index toIndex:(NSInteger)newIndex; // can be animated
- (void)removeTagAtIndex:(NSInteger)index;
- (void)removeAllTags;

- (void)selectTagAtIndex:(NSInteger)index;
- (void)deselectTagAtIndex:(NSInteger)index;
- (void)selectAll;
- (void)deselectAll;

@end

NS_ASSUME_NONNULL_END
