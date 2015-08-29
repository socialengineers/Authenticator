//
//  OTPTokenEntryViewController.m
//  Authenticator
//
//  Copyright (c) 2013 Matt Rubin
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of
//  this software and associated documentation files (the "Software"), to deal in
//  the Software without restriction, including without limitation the rights to
//  use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
//  the Software, and to permit persons to whom the Software is furnished to do so,
//  subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//  FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//  COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//  IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "OTPTokenEntryViewController.h"
@import OneTimePasswordLegacy;
@import Base32;


typedef enum : NSUInteger {
    OTPTokenEntrySectionBasic,
    OTPTokenEntrySectionAdvanced,
    OTPNumberOfTokenEntrySections,
} OTPTokenEntrySection;

typedef enum : NSUInteger {
    OTPTokenEntryBasicRowIssuer,
    OTPTokenEntryBasicRowName,
    OTPTokenEntryBasicRowSecret,
    OTPNumberOfTokenEntryBasicRows,
} OTPTokenEntryBasicRow;

typedef enum : NSUInteger {
    OTPTokenEntryAdvancedRowType,
    OTPTokenEntryAdvancedRowDigits,
    OTPTokenEntryAdvancedRowAlgorithm,
    OTPNumberOfTokenEntryAdvancedRows,
} OTPTokenEntryAdvancedRow;


@interface OTPTokenEntryViewController ()
    <OTPTextFieldCellDelegate>

@property (nonatomic, strong) OTPTextFieldCell *issuerCell;
@property (nonatomic, strong) OTPTextFieldCell *accountNameCell;
@property (nonatomic, strong) OTPTextFieldCell *secretKeyCell;

@property (nonatomic) BOOL showsAdvancedOptions;
@property (nonatomic, strong) OTPSegmentedControlCell *tokenTypeCell;
@property (nonatomic, strong) OTPSegmentedControlCell *digitCountCell;
@property (nonatomic, strong) OTPSegmentedControlCell *algorithmCell;

@end


@implementation OTPTokenEntryViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Add Token";
}


#pragma mark - Target Actions

- (void)doneAction
{
    [self createToken];
}

- (void)createToken
{
    if (!self.formIsValid) return;

    NSData *secret = [NSData dataWithBase32String:self.secretKeyCell.textField.text];

    if (secret.length) {
        OTPToken *token = [OTPToken new];
        token.type = (self.tokenTypeCell.value == OTPTokenTypeIndexTimer) ? OTPTokenTypeTimer : OTPTokenTypeCounter;
        token.secret = secret;
        token.name = self.accountNameCell.textField.text;
        token.issuer = self.issuerCell.textField.text;

        switch (self.digitCountCell.value) {
            case OTPTokenDigitsIndexSix:
                token.digits = 6;
                break;
            case OTPTokenDigitsIndexSeven:
                token.digits = 7;
                break;
            case OTPTokenDigitsIndexEight:
                token.digits = 8;
                break;
        }

        switch (self.algorithmCell.value) {
            case OTPTokenAlgorithmIndexSHA1:
                token.algorithm = OTPAlgorithmSHA1;
                break;
            case OTPTokenAlgorithmIndexSHA256:
                token.algorithm = OTPAlgorithmSHA256;
                break;
            case OTPTokenAlgorithmIndexSHA512:
                token.algorithm = OTPAlgorithmSHA512;
                break;
        }

        if (token.password) {
            id <OTPTokenSourceDelegate> delegate = self.delegate;
            [delegate tokenSource:self didCreateToken:token];
            return;
        }
    }

    // If the method hasn't returned by this point, token creation failed
    [SVProgressHUD showErrorWithStatus:@"Invalid Token"];
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return OTPNumberOfTokenEntrySections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case OTPTokenEntrySectionBasic:
            return OTPNumberOfTokenEntryBasicRows;
        case OTPTokenEntrySectionAdvanced:
            return self.showsAdvancedOptions ? OTPNumberOfTokenEntryAdvancedRows : 0;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case OTPTokenEntrySectionBasic:
            switch (indexPath.row) {
                case OTPTokenEntryBasicRowIssuer:
                    return self.issuerCell;
                case OTPTokenEntryBasicRowName:
                    return self.accountNameCell;
                case OTPTokenEntryBasicRowSecret:
                    return self.secretKeyCell;
            }
            break;
        case OTPTokenEntrySectionAdvanced:
            switch (indexPath.row) {
                case OTPTokenEntryAdvancedRowType:
                    return self.tokenTypeCell;
                case OTPTokenEntryAdvancedRowDigits:
                    return self.digitCountCell;
                case OTPTokenEntryAdvancedRowAlgorithm:
                    return self.algorithmCell;
            }
            break;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case OTPTokenEntrySectionBasic:
            return 74;
        case OTPTokenEntrySectionAdvanced:
            return 54;
    }
    return 0;
}


#pragma mark - Cells

- (OTPSegmentedControlCell *)tokenTypeCell
{
    if (!_tokenTypeCell) {
        _tokenTypeCell = [OTPSegmentedControlCell tokenTypeCell];
    }
    return _tokenTypeCell;
}

- (OTPTextFieldCell *)issuerCell
{
    if (!_issuerCell) {
        _issuerCell = [OTPTextFieldCell issuerCellWithDelegate:self];
    }
    return _issuerCell;
}

- (OTPTextFieldCell *)accountNameCell
{
    if (!_accountNameCell) {
        _accountNameCell = [OTPTextFieldCell nameCellWithDelegate:self
                                                    returnKeyType:UIReturnKeyNext];
    }
    return _accountNameCell;
}

- (OTPTextFieldCell *)secretKeyCell
{
    if (!_secretKeyCell) {
        _secretKeyCell = [OTPTextFieldCell secretCellWithDelegate:self];
    }
    return _secretKeyCell;
}

- (OTPSegmentedControlCell *)digitCountCell
{
    if (!_digitCountCell) {
        _digitCountCell = [OTPSegmentedControlCell digitCountCell];
    }
    return _digitCountCell;
}

- (OTPSegmentedControlCell *)algorithmCell
{
    if (!_algorithmCell) {
        _algorithmCell = [OTPSegmentedControlCell algorithmCell];
    }
    return _algorithmCell;
}


#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == OTPTokenEntrySectionAdvanced) {
        return 54;
    }
    return 1;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (section == OTPTokenEntrySectionAdvanced) {
        UIButton *headerView = [UIButton new];
        [headerView setTitle:@"Advanced Options" forState:UIControlStateNormal];
        headerView.titleLabel.textAlignment = NSTextAlignmentCenter;
        headerView.titleLabel.textColor = [UIColor otpForegroundColor];
        headerView.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
        [headerView addTarget:self action:@selector(revealAdvancedOptions) forControlEvents:UIControlEventTouchUpInside];
        return headerView;
    }
    return nil;
}

- (void)revealAdvancedOptions
{
    if (!self.showsAdvancedOptions) {
        self.showsAdvancedOptions = YES;
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:OTPTokenEntrySectionAdvanced] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:(OTPNumberOfTokenEntryAdvancedRows - 1)
                                                                  inSection:OTPTokenEntrySectionAdvanced]
                              atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
}


#pragma mark - OTPTextFieldCellDelegate

- (void)textFieldCellDidChange:(nonnull OTPTextFieldCell *)textFieldCell
{
    [self validateForm];
}

- (void)textFieldCellDidReturn:(nonnull OTPTextFieldCell *)textFieldCell
{
    if (textFieldCell == self.issuerCell) {
        [self.accountNameCell.textField becomeFirstResponder];
    } else if (textFieldCell == self.accountNameCell) {
        [self.secretKeyCell.textField becomeFirstResponder];
    } else {
        [textFieldCell.textField resignFirstResponder];
        [self createToken];
    }
}


#pragma mark - Validation

- (BOOL)formIsValid
{
    return ((self.issuerCell.textField.text.length ||
             self.accountNameCell.textField.text.length) &&
            self.secretKeyCell.textField.text.length);
}

@end
