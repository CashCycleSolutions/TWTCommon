//
//  TWTPickerControl.m
//  TWTCommon
//
//  Created by Jeremy Ellison on 8/26/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "TWTPickerControl.h"
#import "UIView+TWTAdditions.h"
#import "NSString+TWTAdditions.h"

@interface TWTPickerControl (Private)

- (void)updateToolbar;
- (void)updateLabel;

@end


@implementation TWTPickerControl

// todo: The following need to update UI when set. Perhaps a -redraw: method to call after?
@synthesize placeholderText = _placeholderText;
@synthesize font = _font;
@synthesize selectedFont = _selectedFont;
@synthesize textLabel = _label;
@synthesize doneButton = _doneButton;
@synthesize nextButton = _nextButton;
@synthesize toolbar = _toolbar;
@synthesize titleView = _titleView;
@synthesize delegate = _delegate;
@synthesize dataSource = _dataSource;
@synthesize selection = _selection;

- (id)initWithFrame:(CGRect)frame {
	if (self = [super initWithFrame:frame]) {
		_label = [[UILabel alloc] initWithFrame:self.bounds];
		[self addSubview:_label];
		self.placeholderText = @"Default Text";
		_label.backgroundColor = [UIColor clearColor];
		self.font = _label.font;
		[self addTarget:self action:@selector(touchUpInside:) forControlEvents:UIControlEventTouchUpInside];
		_pickerView = [[UIView alloc] initWithFrame:CGRectMake(0, 480, 320, 250)];
		_picker = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 48, 320, 150)];
		[_picker sizeToFit];
		_picker.showsSelectionIndicator = YES;
		[_pickerView addSubview:_picker];
		_toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, 48)];
		[_pickerView addSubview:_toolbar];
		_pickerView.clipsToBounds = YES;
		_picker.dataSource = self;
		_picker.delegate = self;
		self.selection = [NSArray array];
		
		[self updateToolbar];
		[self updateLabel];
	}
	return self;
}

- (void)setFont:(UIFont *)font {
	[font retain];
	[_font release];
	_font = font;
	_label.font = font;
}

- (void)dealloc {
	[self removeTarget:self action:@selector(touchUpInside:) forControlEvents:UIControlEventTouchUpInside];
	_delegate = nil;
	[self resignFirstResponder];
	[_pickerView removeFromSuperview];
	[_picker release];
	[_pickerView release];
	[_toolbar release];
	[_nextButton release];
	[_doneButton release];
	[_label release];
	[_font release];
	_font = nil;
	[_selectedFont release];
	_selectedFont = nil;
	[_dataSource release];
	_dataSource = nil;

	[super dealloc];
}

- (void)updateToolbar {
	[_doneButton release];
	[_nextButton release];
	_doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleBordered target:self action:@selector(dismissPicker:)];
	_nextButton = [[UIBarButtonItem alloc] initWithTitle:@"Next" style:UIBarButtonItemStyleBordered target:self action:@selector(nextButtonWasTouched:)];
	if (nil == _titleView) {
		[_toolbar setItems:[NSArray arrayWithObjects:
							_doneButton,
							[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease],
							_nextButton, nil]];
	} else {
		[_toolbar setItems:[NSArray arrayWithObjects:
							_doneButton,
							[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease],
							[[[UIBarButtonItem alloc] initWithCustomView:_titleView] autorelease],
							[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease],
							_nextButton, nil]];
	}
}

- (BOOL)hasSelection {
	return ([self.selection count] > 0 && NO == [self.selection containsObject:[NSNull null]]);
}

- (void)updateLabel {
	if (NO == self.hasSelection) {
		self.textLabel.text = self.placeholderText;
	} else {
		NSMutableArray* array = [NSMutableArray arrayWithCapacity:[self.selection count]];
		for (int i = 0; i < [self.selection count]; i++) {
			[array addObject:[self pickerView:_picker titleForRow:[[self.selection objectAtIndex:i] intValue] forComponent:i]];
		}
		if ([_delegate respondsToSelector:@selector(picker:labelTextForChoices:)]) {
			self.textLabel.text = [_delegate picker:self labelTextForChoices:array];
		} else {
			self.textLabel.text = [array componentsJoinedByString:@" "];
		}
	}
}

- (BOOL)canBecomeFirstResponder {
	return YES;
}

- (BOOL)resignFirstResponder {
	[UIView beginAnimations:@"Hide Picker" context:nil];
	_pickerView.frame = CGRectMake(0, self.window.bounds.size.height + _pickerView.bounds.size.height, 320, _pickerView.bounds.size.height);
	[UIView commitAnimations];
	_label.font = self.font;
	if ([_delegate respondsToSelector:@selector(picker:willHidePicker:)]) {
		[_delegate picker:self willHidePicker:_pickerView];
	}
	return [super resignFirstResponder];
}

- (BOOL)becomeFirstResponder {
	// replace nulls in selection with 0.
	for (int i = 0; i < [[self.dataSource components] count]; i++) {
		if ([self.selection objectAtIndex:i] == [NSNull null]) {
			[self.selection replaceObjectAtIndex:i withObject:[NSNumber numberWithInt:0]];
		}
	}
	[self updateLabel];
	
	UIWindow* keyWindow = [[UIApplication sharedApplication] keyWindow];
	[[keyWindow findFirstResonder] resignFirstResponder];
	[self.window addSubview:_pickerView];
	[_pickerView sizeToFit];
	[UIView beginAnimations:@"Show Picker" context:nil];
	_pickerView.frame = CGRectMake(0, self.window.bounds.size.height - _pickerView.bounds.size.height, 320, _pickerView.bounds.size.height);
	[UIView commitAnimations];
	if (self.selectedFont) {
		_label.font	= self.selectedFont;
	}
	if ([_delegate respondsToSelector:@selector(picker:didShowPicker:)]) {
		[_delegate picker:self didShowPicker:_pickerView];
	}
	return [super becomeFirstResponder];
}

- (void)touchUpInside:(id)sender {
	[self becomeFirstResponder];
}

- (void)dismissPicker:(id)sender {
	[self resignFirstResponder];
}

- (void)nextButtonWasTouched:(id)sender {
	if ([(NSObject*)_delegate respondsToSelector:@selector(picker:nextButtonWasTouched:)]) {
		[_delegate picker:self nextButtonWasTouched:sender];
	}
	[self dismissPicker:self];
}

- (void)resetSelection {
	NSMutableArray* array = [NSMutableArray arrayWithCapacity:[[self.dataSource components] count]];
	for (int i = 0; i < [[self.dataSource components] count]; i++) {
		[array addObject:[NSNull null]];
	}
	self.selection = array;
	[self updateLabel];
}

- (void)setSelection:(NSMutableArray *)selection {
	[selection retain];
	[_selection release];
	_selection = selection;
	
	// Ensure the underlying picker selection is correct
	for (NSInteger i = 0; i < [[self.dataSource components] count]; i++) {		
		NSNumber* row = [selection objectAtIndex:i];
		if ([row isKindOfClass:[NSNumber class]]) {
			[_picker selectRow:[row intValue] inComponent:i animated:YES];
		}
	}
	
	[self updateLabel];
}

- (NSString*)selectionText {
	if (self.hasSelection) {
		return self.textLabel.text;
	} else {
		return nil;
	}
}

- (void)setDataSource:(TWTPickerDataSource *)source {
	[source retain];
	[_dataSource release];
	_dataSource = source;
	[_picker reloadAllComponents];
	[self resetSelection];
}

- (void)setTitleView:(UIView *)titleView {
	[titleView retain];
	[_titleView release];
	_titleView = titleView;
	[self updateToolbar];
}

- (void)setPlaceholderText:(NSString *)str {
	NSString* newPlaceholder = [str copy];
	[_placeholderText release];
	_placeholderText = newPlaceholder;
	[self updateLabel];
}

// Picker View DataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
	return [_dataSource.components count];
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
	return [[_dataSource.components objectAtIndex:component] count];
}

// Picker View Delegate

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
	return [[_dataSource.components objectAtIndex:component] objectAtIndex:row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
	[self.selection removeObjectAtIndex:component];
	[self.selection insertObject:[NSNumber numberWithInt:row] atIndex:component];
	[self updateLabel];
	[self sizeToFit];
	
	if ([_delegate respondsToSelector:@selector(picker:didSelectChoiceAtIndex:forComponent:)]) {
		[_delegate picker:self didSelectChoiceAtIndex:row forComponent:component];
	}
}

@end