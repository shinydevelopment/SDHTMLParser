//
//  ViewController.m
//  HTMLtoAttributedString
//
//  Created by Greg Spiers on 03/12/2013.
//  Copyright (c) 2013 Shiny Development. All rights reserved.
//

#import "ViewController.h"
#import "HTMLParser.h"


@interface ViewController ()
@property (strong, nonatomic) IBOutlet UILabel *label;
@property (strong, nonatomic) IBOutlet UITextView *textView;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.

  NSString *HTMLString = @"<p>Hello world</p><p><b>Bold text</b><a href='http://google.com'>Google.com</a></p>";

  HTMLParser *parser = [[HTMLParser alloc] initWithFontSize:15 fontName:@"Superclarendon-Regular" boldFontName:@"Superclarendon-Bold" italicFontName:@"Superclarendon-Italic" boldItalicFontName:@"Superclarendon-BoldItalic"];
  NSAttributedString *attributedString = [parser attributedStringFromHTMLString:HTMLString];

  self.label.attributedText = attributedString;
  self.textView.attributedText = attributedString;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
