/*
 Copyright (c) 2015, Apple Inc. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1.  Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2.  Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.
 
 3.  Neither the name of the copyright holder(s) nor the names of any contributors
 may be used to endorse or promote products derived from this software without
 specific prior written permission. No license is granted to the trademarks of
 the copyright holders even if such marks are included in this software.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


#import "ORKConsentReviewController.h"

#import "ORKSignatureView.h"
#import "ORKVerticalContainerView_Internal.h"

#import "ORKConsentDocument_Internal.h"

#import "ORKHelpers_Internal.h"
#import "ORKSkin.h"


static const CGFloat iPadStepTitleLabelFontSize = 50.0;
@interface ORKConsentReviewController () <UIScrollViewDelegate>

@end


@implementation ORKConsentReviewController {
    UIToolbar *_toolbar;
    NSString *_htmlString;
    NSMutableArray *_variableConstraints;
    UILabel *_iPadStepTitleLabel;
    NSString *_iPadStepTitle;
    UIBarButtonItem *_agreeButton;
}

- (instancetype)initWithHTML:(NSString *)html delegate:(id<ORKConsentReviewControllerDelegate>)delegate requiresScrollToBottom:(BOOL)requiresScrollToBottom {
    self = [super init];
    if (self) {
        _htmlString = html;
        _delegate = delegate;
        
        _agreeButton = [[UIBarButtonItem alloc] initWithTitle:ORKLocalizedString(@"BUTTON_AGREE", nil) style:UIBarButtonItemStylePlain target:self action:@selector(ack)];
        _agreeButton.enabled = !requiresScrollToBottom;
        
        self.toolbarItems = @[
                             [[UIBarButtonItem alloc] initWithTitle:ORKLocalizedString(@"BUTTON_DISAGREE", nil) style:UIBarButtonItemStylePlain target:self action:@selector(cancel)],
                             [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                             _agreeButton];
    }
    return self;
}

- (void)setTextForiPadStepTitleLabel:(NSString *)text {
    _iPadStepTitle = text;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _toolbar = [[UIToolbar alloc] init];
    
    _toolbar.items = [@[_cancelButtonItem,
                       [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]] arrayByAddingObjectsFromArray:self.toolbarItems];
    
    self.view.backgroundColor = ORKColor(ORKConsentBackgroundColorKey);
    if (self.navigationController.navigationBar) {
        [self.navigationController.navigationBar setBarTintColor:self.view.backgroundColor];
    }
    
    _toolbar.translatesAutoresizingMaskIntoConstraints = NO;
    _toolbar.translucent = YES;

    [self updateLayoutMargins];

    [self setupiPadStepTitleLabel];
    [self.view addSubview:_toolbar];
    
    [self setUpStaticConstraints];
}

- (void)setCancelButtonItem:(UIBarButtonItem *)cancelButtonItem {
    if (!_cancelButtonItem) {
        _cancelButtonItem = cancelButtonItem;
    }
}

- (void)setupiPadStepTitleLabel {
    if (!_iPadStepTitleLabel) {
        _iPadStepTitleLabel = [UILabel new];
    }
    _iPadStepTitleLabel.numberOfLines = 0;
    _iPadStepTitleLabel.textAlignment = NSTextAlignmentNatural;
    [_iPadStepTitleLabel setFont:[UIFont systemFontOfSize:iPadStepTitleLabelFontSize weight:UIFontWeightBold]];
    _iPadStepTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [_iPadStepTitleLabel setAdjustsFontSizeToFitWidth:YES];
    [_iPadStepTitleLabel setText:_iPadStepTitle];
    [self.view addSubview:_iPadStepTitleLabel];
}

- (void)updateLayoutMargins {
    const CGFloat margin = ORKStandardHorizontalMarginForView(self.view);
}
    
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [self updateLayoutMargins];
}

- (void)setUpStaticConstraints {
}

- (void)updateViewConstraints {
}

- (IBAction)cancel {
    if (self.delegate && [self.delegate respondsToSelector:@selector(consentReviewControllerDidCancel:)]) {
        [self.delegate consentReviewControllerDidCancel:self];
    }
}

- (void)doAck {
    if (self.delegate && [self.delegate respondsToSelector:@selector(consentReviewControllerDidAcknowledge:)]) {
        [self.delegate consentReviewControllerDidAcknowledge:self];
    }
}

- (IBAction)ack {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:ORKLocalizedString(@"CONSENT_REVIEW_ALERT_TITLE", nil)
                                                                   message:self.localizedReasonForConsent
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:ORKLocalizedString(@"BUTTON_CANCEL", nil) style:UIAlertActionStyleDefault handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:ORKLocalizedString(@"BUTTON_AGREE", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        // Have to dispatch, so following transition animation works
        dispatch_async(dispatch_get_main_queue(), ^{
            [self doAck];
        });
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (!_agreeButton.isEnabled && [self scrolledToBottom:scrollView]) {
        _agreeButton.enabled = YES;
    }
}

- (BOOL)scrolledToBottom:(UIScrollView *)scrollView {
    CGPoint offset = scrollView.contentOffset;
    CGRect bounds = scrollView.bounds;
    UIEdgeInsets inset = scrollView.contentInset;
    CGFloat currentOffset = offset.y + bounds.size.height - inset.bottom;
    return (currentOffset - scrollView.contentSize.height >= 0);
}

@end
