@interface HTMLParser : NSObject
- (id)initWithFontSize:(CGFloat)fontSize fontName:(NSString *)fontName boldFontName:(NSString *)boldFontName italicFontName:(NSString *)italicFontName boldItalicFontName:(NSString *)boldItalicFontName;
- (NSMutableAttributedString *)attributedStringFromHTMLString:(NSString *)htmlString;
@end
