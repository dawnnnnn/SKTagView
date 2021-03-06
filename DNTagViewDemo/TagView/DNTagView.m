//
//  DNTagView.m
//  DNTagView
//
//  Created by dawnnnnn on 16/9/1.
//  Copyright © 2016年 dawnnnnn. All rights reserved.
//

#import "DNTagView.h"

@interface DNTagView ()<UITextFieldDelegate>

@property (nonatomic, assign) DNTagViewState state;
@property (nonatomic, strong) NSMutableArray *tags;

@property (nonatomic, strong) DNTagButton *tmpButton;
@property (nonatomic, strong) DNTagButton *lastButton;
@property (nonatomic, strong) UIMenuController *menu;

@property (nonatomic, assign) BOOL didSetup;
@property (nonatomic, assign) NSInteger viewIndex, tagIndex;

@end


@implementation DNTagView

#pragma mark - init

- (instancetype)initWithState:(DNTagViewState)state {
    self = [super init];
    if (self) {
        self.state = state;
        self.menuEnable = YES;
        if (self.state == DNTagViewStateEdit) {
            [self addSubview:self.inputText];
            UITapGestureRecognizer *tapGes = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(willInput)];
            [self addGestureRecognizer:tapGes];
        }
    }
    return self;
}


#pragma mark - Lifecycle

- (CGSize)intrinsicContentSize {

    NSArray *subviews = self.subviews;
    UIView *previousView = nil;
    CGFloat topPadding = self.padding.top;
    CGFloat bottomPadding = self.padding.bottom;
    CGFloat leftPadding = self.padding.left;
    CGFloat rightPadding = self.padding.right;
    CGFloat itemSpacing = self.interitemSpacing;
    CGFloat lineSpacing = self.lineSpacing;
    CGFloat currentX = leftPadding;
    CGFloat intrinsicHeight = topPadding;
    CGFloat intrinsicWidth = leftPadding;
    
    if (!self.singleLine && self.preferredMaxLayoutWidth > 0) {
        NSInteger lineCount = 0;
        for (UIView *view in subviews) {
            CGSize size = view.intrinsicContentSize;
            if (previousView) {
                CGFloat width = size.width;
                currentX += itemSpacing;
                if (currentX + width + rightPadding <= self.preferredMaxLayoutWidth) {
                    currentX += size.width;
                } else {
                    lineCount ++;
                    currentX = leftPadding + size.width;
                    intrinsicHeight += size.height;
                }
            } else {
                lineCount ++;
                intrinsicHeight += size.height;
                currentX += size.width;
            }
            previousView = view;
            intrinsicWidth = MAX(intrinsicWidth, currentX + rightPadding);
        }
        
        intrinsicHeight += bottomPadding + lineSpacing * (lineCount - 1);
    } else {
        for (UIView *view in subviews) {
            CGSize size = view.intrinsicContentSize;
            intrinsicWidth += size.width;
        }
        intrinsicWidth += itemSpacing * (subviews.count - 1) + rightPadding;
        intrinsicHeight += ((UIView *)subviews.firstObject).intrinsicContentSize.height + bottomPadding;
    }
    
    return CGSizeMake(intrinsicWidth, intrinsicHeight);
}

- (void)layoutSubviews {
    if (!self.singleLine) {
        self.preferredMaxLayoutWidth = self.frame.size.width;
    }
    
    [super layoutSubviews];
    
    [self layoutTags];
}

#pragma mark - Private

- (void)layoutTags {
    if (self.state == DNTagViewStateEdit) {
        [self bringSubviewToFront:self.inputText];
    }
    
    NSArray *subviews = self.subviews;
    UIView *previousView = nil;
    CGFloat topPadding = self.padding.top;
    CGFloat leftPadding = self.padding.left;
    CGFloat rightPadding = self.padding.right;
    CGFloat itemSpacing = self.interitemSpacing;
    CGFloat lineSpacing = self.lineSpacing;
    CGFloat currentX = leftPadding;
    
    if (!self.singleLine && self.preferredMaxLayoutWidth > 0) {
        for (UIView *view in subviews) {
            CGSize size = view.intrinsicContentSize;
            if (previousView) {
                CGFloat width = size.width;
                currentX += itemSpacing;
                if (currentX + width + rightPadding <= self.preferredMaxLayoutWidth) {
                    view.frame = CGRectMake(currentX, CGRectGetMinY(previousView.frame), size.width, size.height);
                    currentX += size.width;
                } else {
                    CGFloat width = MIN(size.width, self.preferredMaxLayoutWidth - leftPadding - rightPadding);
                    view.frame = CGRectMake(leftPadding, CGRectGetMaxY(previousView.frame) + lineSpacing, width, size.height);
                    currentX = leftPadding + width;
                }
            } else {
                CGFloat width = MIN(size.width, self.preferredMaxLayoutWidth - leftPadding - rightPadding);
                view.frame = CGRectMake(leftPadding, topPadding, width, size.height);
                currentX += width;
            }
            
            previousView = view;
        }
    } else {
        for (UIView *view in subviews) {
            CGSize size = view.intrinsicContentSize;
            view.frame = CGRectMake(currentX, topPadding, size.width, size.height);
            currentX += size.width;
            currentX += itemSpacing;
            
            previousView = view;
        }
    }
    
    self.didSetup = YES;
}

#pragma mark - IBActions

- (void)onTag:(DNTagButton *)btn {
    if (self.state != DNTagViewStateEdit) {
        return;
    }
    self.tmpButton.selected = NO;
    [self.tmpButton setBackgroundColor:self.tmpButton.mtag.bgColor];
    self.tmpButton = btn;
    
    btn.selected = YES;
    [btn setBackgroundColor:self.tmpButton.mtag.highlightedBgColor];
    
    self.viewIndex = [self.subviews indexOfObject:btn];
    self.tagIndex = [self.tags indexOfObject:btn.mtag.text];
    
    CGRect buttonFrame = btn.frame;
    [self.inputText resignFirstResponder];
    [self becomeFirstResponder];
    
    if (!self.menuEnable) {
        return;
    }
    [self.menu setTargetRect:buttonFrame inView:self];
    NSAssert([self becomeFirstResponder], @"Sorry, UIMenuController will not work with %@ since it cannot become first responder", self);
    [self.menu setMenuVisible:YES animated:YES];
    
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)menuDelete:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(deleteTag:)]) {
        [self.delegate deleteTag:self.tagIndex];
    }
    [self removeTagAtIndex:self.viewIndex];
}


#pragma mark - Public

- (void)addTag: (DNTag *)tag {
    NSParameterAssert(tag);
    DNTagButton *btn = [DNTagButton buttonWithTag:tag];
    [btn addTarget:self action: @selector(onTag:) forControlEvents: UIControlEventTouchUpInside];
    [self addSubview:btn];
    [self.tags addObject:tag.text];
    
    self.didSetup = NO;
    [self invalidateIntrinsicContentSize];
}

- (void)insertTag:(DNTag *)tag atIndex:(NSUInteger)index {
    NSParameterAssert(tag);
    if (index + 1 > self.tags.count) {
        [self addTag: tag];
    } else {
        DNTagButton *btn = [DNTagButton buttonWithTag: tag];
        [btn addTarget: self action: @selector(onTag:) forControlEvents: UIControlEventTouchUpInside];
        [self insertSubview: btn atIndex: index];
        [self.tags insertObject: tag.text atIndex: index];
        
        self.didSetup = NO;
        [self invalidateIntrinsicContentSize];
    }
}

- (void)removeTag:(DNTag *)tag {
    NSParameterAssert(tag);
    NSUInteger index = [self.tags indexOfObject: tag.text];
    if (NSNotFound == index) {
        return;
    }
    
    [self.tags removeObjectAtIndex: index];
    if (self.subviews.count > index) {
        [self.subviews[index] removeFromSuperview];
    }
    
    self.didSetup = NO;
    [self invalidateIntrinsicContentSize];
}

- (void)removeTagAtIndex: (NSUInteger)index {
    if (index + 1 > self.tags.count) {
        return;
    }
    
    [self.tags removeObjectAtIndex: index];
    if (self.subviews.count > index) {
        [self.subviews[index] removeFromSuperview];
    }
    
    self.didSetup = NO;
    [self invalidateIntrinsicContentSize];
}

- (void)removeAllTags {
    [self.tags removeAllObjects];
    for (UIView *view in self.subviews) {
        [view removeFromSuperview];
    }
    
    self.didSetup = NO;
    [self invalidateIntrinsicContentSize];
}

- (void)willInput {
    [self.inputText becomeFirstResponder];
}


#pragma mark - textfield delegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    self.tmpButton.selected = NO;
    [self.tmpButton setBackgroundColor:self.tmpButton.mtag.bgColor];
    [self.menu setMenuVisible:NO animated:YES];
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (self.delegate && [self.delegate respondsToSelector:@selector(completeInputText:)]) {
        [self.delegate completeInputText:textField.text];
        textField.text = @"";
    }
    return YES;
}

- (void)textFieldDidChanged:(UITextField*)textField{
    self.didSetup = NO;
    [self layoutTags];
    [self invalidateIntrinsicContentSize];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(didInputText:)]) {
        [self.delegate didInputText:textField.text];
    }
}


#pragma mark - getter

- (NSMutableArray *)tags {
    if(_tags == nil) {
        _tags = [NSMutableArray array];
    }
    return _tags;
}

- (void)setPreferredMaxLayoutWidth: (CGFloat)preferredMaxLayoutWidth {
    if (preferredMaxLayoutWidth != _preferredMaxLayoutWidth) {
        _preferredMaxLayoutWidth = preferredMaxLayoutWidth;
        _didSetup = NO;
        [self invalidateIntrinsicContentSize];
    }
}

- (DNTextField *)inputText {
    if (_inputText == nil) {
        _inputText = [DNTextField new];
        _inputText.textColor = [UIColor blackColor];
        _inputText.font = [UIFont systemFontOfSize:15];
        _inputText.placeholder = @"输入标签";
        _inputText.returnKeyType = UIReturnKeyDone;
        _inputText.enablesReturnKeyAutomatically = YES;
        _inputText.delegate = self;
        [_inputText addTarget:self action:@selector(textFieldDidChanged:) forControlEvents:UIControlEventEditingChanged];
    }
    return _inputText;
}

- (UIMenuController *)menu {
    if (_menu == nil) {
        UIMenuItem *deleteItem = [[UIMenuItem alloc] initWithTitle:@"删除"action:@selector(menuDelete:)];
        _menu = [UIMenuController sharedMenuController];
        _menu.arrowDirection = UIMenuControllerArrowDefault;
        [_menu setMenuItems:[NSArray arrayWithObject:deleteItem]];
    }
    return _menu;
}

@end
