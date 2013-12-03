#import "HTMLParser.h"

enum {
  HTMLParserSupportedTagBold = 1 << 0,
  HTMLParserSupportedTagItalic = 1 << 1,
  HTMLParserSupportedTagUnderline = 1 << 2,
  HTMLParserSupportedTagLink = 1 << 3,
  HTMLParserSupportedTagParagraph = 1 << 4
};
typedef NSInteger HTMLParserSupportedTags;

@interface HTMLParser ()
@property (assign, nonatomic) CGFloat fontSize;
@property (strong, nonatomic) NSString * fontName;
@property (strong, nonatomic) NSString * boldFontName;
@property (strong, nonatomic) NSString * italicFontName;
@property (strong, nonatomic) NSString * boldItalicFontName;
@end

@implementation HTMLParser

- (id)init
{
  [self doesNotRecognizeSelector:_cmd];
  return nil;
}

- (id)initWithFontSize:(CGFloat)fontSize fontName:(NSString *)fontName boldFontName:(NSString *)boldFontName italicFontName:(NSString *)italicFontName boldItalicFontName:(NSString *)boldItalicFontName
{
  self = [super init];
  if (self) {
    self.fontSize = fontSize;
    self.fontName = fontName;
    self.boldFontName = boldFontName;
    self.italicFontName = italicFontName;
    self.boldItalicFontName = boldItalicFontName;
  }
  return self;
}

- (NSMutableAttributedString *)attributedStringFromHTMLString:(NSString *)htmlString
{
  NSInteger const RegexCaptureRangeIndexStart = 1;
  NSInteger const RegexCaptureRangeIndexOpenOrCloseTag = 2;
  NSInteger const RegexCaptureRangeIndexTagName = 3;
  NSInteger const RegexCaptureRangeIndexURL = 4;
  // No need for capture 5
  NSInteger const RegexCaptureRangeIndexClosingText = 6;

  // Start with an empty attributed string.
  NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:@""];

  // Get the regex from a class method so it can be reused.
  NSRegularExpression *splitRegex = [HTMLParser HTMLSplittingRegularExpression];

  // Split the entire fragment and we'll deal with one match at a time.
  NSArray *splitMatches = [splitRegex matchesInString:htmlString options:0 range:NSMakeRange(0, [htmlString length])];

  // Keep track of which tags are open.
  HTMLParserSupportedTags currentOpenTags = 0;

  // Keep track of where in the string an open link/p tag started and what the URL was (if applicable).
  NSInteger startLinkOffset = -1;
  NSInteger startParagraphOffset = -1;
  NSURL *lastCapturedLinkURL = nil;

  for (NSTextCheckingResult *result in splitMatches) {

    // Add an attributed string created with the start capture.
    NSRange startCaptureRange = [result rangeAtIndex:RegexCaptureRangeIndexStart];
    if (startCaptureRange.length != 0) {
      NSString *startString = [[htmlString substringWithRange:startCaptureRange] gtm_stringByUnescapingFromHTML];
      startString = [HTMLParser removeDuplicateWhitespaceFromString:startString];
      [attributedString appendAttributedString:[self attributedStringFromString:startString withAttributes:currentOpenTags]];
    }

    // Get the URL out if it's there (only there if the match was a a tag)
    NSURL *capturedURL = nil;
    NSRange URLCaptureRange = [result rangeAtIndex:RegexCaptureRangeIndexURL];
    if (URLCaptureRange.length != 0) {
      // Get the URL string, trimming any whitespace around it
      NSString *URLString = [[htmlString substringWithRange:URLCaptureRange] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
      // Escape the URL string so we can create an NSURL
      URLString = [URLString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
      capturedURL = [NSURL URLWithString:URLString];
    }

    // Act appropriately based on tag type
    HTMLParserSupportedTags tagType = 0;
    NSRange tagCaptureRange = [result rangeAtIndex:RegexCaptureRangeIndexTagName];
    // This should always be captured, but check length anyways so we avoid a crash if some bad data in was allowed in.
    if (tagCaptureRange.length != 0) {
      NSString *tagName = [htmlString substringWithRange:tagCaptureRange];

      if ([tagName isEqualToString:@"strong"] || [tagName isEqualToString:@"b"]) {
        tagType = HTMLParserSupportedTagBold;
      } else if ([tagName isEqualToString:@"em"] || [tagName isEqualToString:@"i"]) {
        tagType = HTMLParserSupportedTagItalic;
      } else if ([tagName isEqualToString:@"u"]) {
        tagType = HTMLParserSupportedTagUnderline;
      } else if ([tagName isEqualToString:@"a"]) {
        tagType = HTMLParserSupportedTagLink;
      } else if ([tagName isEqualToString:@"p"]){
        tagType = HTMLParserSupportedTagParagraph;
      } else {
        // Unsupported tag, just ignore it
      }
    }

    // Determin if this is an opening or closing tag
    NSRange openCloseCaptureRange = [result rangeAtIndex:RegexCaptureRangeIndexOpenOrCloseTag];
    if (openCloseCaptureRange.length != 0) {
      // This is a closing tag.
      // Exclusive OR with the tagType so we can turn off the tag that just closed.
      currentOpenTags ^= tagType;

      // If this is a closing tag and 'a' we need to store the offset of the link and the URL it points to.
      if (tagType == HTMLParserSupportedTagLink) {
        // Avoid empty links
        NSInteger endLinkOffset = [attributedString length];
        if (startLinkOffset != endLinkOffset) {
          // Set the attributes to create the link on the attributed string using the correct range and the last captured URL.
          [attributedString addAttribute:NSLinkAttributeName value:lastCapturedLinkURL range:NSMakeRange(startLinkOffset, endLinkOffset - startLinkOffset)];
        }
      } else if (tagType == HTMLParserSupportedTagParagraph) {
        // Avoid empty paragraphs
        NSInteger endParagraphOffset = [attributedString length];
        if (startParagraphOffset != endParagraphOffset) {
          // Need to add a paragraph separator unicode character
          [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\u2029"]];
        }
      }
    } else {
      // This is a opening tag.
      // Need to turn current tag to 'on' by OR'ing with the tag.
      currentOpenTags |= tagType;

      if (tagType == HTMLParserSupportedTagLink) {
        // Need to keep track of where this link started
        startLinkOffset = [attributedString length];
        // Store the last link URL we have seen so we can use it when we find the closing 'a' tag.
        lastCapturedLinkURL = capturedURL;
      } else if (tagType == HTMLParserSupportedTagParagraph) {
        // Need to keep track of where this paragraph started
        startParagraphOffset = [attributedString length];
      }
    }

    // Check if there's any trailing text without tags to add to the string.
    // This might be the only capture in the fragment if the fragment did not have any tags.
    NSRange closingTextCaptureRange = [result rangeAtIndex:RegexCaptureRangeIndexClosingText];
    if (closingTextCaptureRange.length != 0) {
      NSString *endString = [[htmlString substringWithRange:closingTextCaptureRange] gtm_stringByUnescapingFromHTML];
      endString = [HTMLParser removeDuplicateWhitespaceFromString:endString];
      // Whatever tags are still open are what style we will use. This means an unclosed tag applies to the end of the fragment.
      [attributedString appendAttributedString:[self attributedStringFromString:endString withAttributes:currentOpenTags]];
    }
  }

  return attributedString;
}

- (NSAttributedString *)attributedStringFromString:(NSString *)string withAttributes:(HTMLParserSupportedTags)openAttributes
{
  NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:string];

  UIFont *font = nil;
  if ((openAttributes & HTMLParserSupportedTagBold) && (openAttributes & HTMLParserSupportedTagItalic)) {
    font = [UIFont fontWithName:self.boldItalicFontName size:self.fontSize];
  } else if (openAttributes & HTMLParserSupportedTagBold) {
    font = [UIFont fontWithName:self.boldFontName size:self.fontSize];
  } else if (openAttributes & HTMLParserSupportedTagItalic) {
    font = [UIFont fontWithName:self.italicFontName size:self.fontSize];
  } else {
    // We don't have bold or italic on at the moment, use the default font
    font = [UIFont fontWithName:self.fontName size:self.fontSize];
  }
  if (font) {
    [attributedString addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, [attributedString length])];
  }

  if (openAttributes & HTMLParserSupportedTagUnderline) {
    [attributedString addAttribute:(NSString *)kCTUnderlineStyleAttributeName value:[NSNumber numberWithInt:1] range:NSMakeRange(0, [attributedString length])];
  }

  return attributedString;
}

#pragma mark Class methods
+ (NSString *)removeDuplicateWhitespaceFromString:(NSString *)string
{
  // TODO: This should probably be in a category on NSString.
  NSError *error = nil;
  NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"  +" options:NSRegularExpressionCaseInsensitive error:&error];
  string = [regex stringByReplacingMatchesInString:string options:0 range:NSMakeRange(0, [string length]) withTemplate:@" "];

  regex = [NSRegularExpression regularExpressionWithPattern:@"\n\n+" options:NSRegularExpressionCaseInsensitive error:&error];
  string = [regex stringByReplacingMatchesInString:string options:0 range:NSMakeRange(0, [string length]) withTemplate:@"\n"];

  return string;
}

+ (NSRegularExpression *)HTMLSplittingRegularExpression
{
  static dispatch_once_t predicate = 0;
  __strong static NSRegularExpression *sharedHTMLSplittingRegularExpression = nil;
  dispatch_once(&predicate, ^{
    // Split entire html fragment on strings/tags or end of fragment
    NSError *error = nil;

    // This looks complex but it's mostly just dealing with slight edge cases in the html like extra spaces. Everything we need is captured and then we checked what we got
    // and process appropriately.
    sharedHTMLSplittingRegularExpression = [NSRegularExpression
                                               regularExpressionWithPattern:@"(?:(?:(.*?)<\\s*(/??)(\\w+)(?:(?:[^>]*?(?:(?:src)|(?:href))=(?:\'|\"){1}(.*?)(?:\'|\"){1}.*?/?)|(.*?))>)|(.*$))"
                                               options:NSRegularExpressionCaseInsensitive | NSRegularExpressionDotMatchesLineSeparators // Needed to get to the start of the text which can be on a different line
                                               error:&error];
    // Find problems with this regex during dev, it should never error.
    NSAssert1(sharedHTMLSplittingRegularExpression, @"Regex invalid: %@", error);
  });
  
  return sharedHTMLSplittingRegularExpression;
}

@end
