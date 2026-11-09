#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>
#import <CoreGraphics/CoreGraphics.h>
int main(int argc, const char *argv[]) {
 @autoreleasepool {
  if (argc != 2) return 2;
  NSString *input=[NSString stringWithContentsOfFile:[NSString stringWithUTF8String:argv[1]] encoding:NSUTF8StringEncoding error:nil];
  if (!input) return 3;
  const size_t width=430,height=32,stride=width*4;
  CTFontRef font=CTFontCreateWithName(CFSTR("Arial"),16,NULL);
  for (NSString *line in [input componentsSeparatedByString:@"\n"]) {
   if (!line.length) continue;
   NSArray *parts=[line componentsSeparatedByString:@"\t"];
   if (parts.count!=2) return 4;
   unsigned char *pixels=calloc(height,stride);
   CGColorSpaceRef cs=CGColorSpaceCreateDeviceRGB();
   CGContextRef ctx=CGBitmapContextCreate(pixels,width,height,8,stride,cs,kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
   CGContextSetRGBFillColor(ctx,1,1,1,1); CGContextFillRect(ctx,CGRectMake(0,0,width,height));
   NSDictionary *attrs=@{(__bridge id)kCTFontAttributeName:(__bridge id)font,(__bridge id)kCTForegroundColorAttributeName:(__bridge id)CGColorGetConstantColor(kCGColorBlack)};
   NSAttributedString *text=[[NSAttributedString alloc] initWithString:parts[1] attributes:attrs];
   CTLineRef textLine=CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)text);
   CGContextSetTextPosition(ctx,8,9); CTLineDraw(textLine,ctx);
   NSMutableData *rgb=[NSMutableData dataWithLength:width*height*3]; unsigned char *dst=rgb.mutableBytes;
   for (size_t y=0;y<height;y++) for (size_t x=0;x<width;x++) {size_t src=(y*width+x)*4, out=(y*width+x)*3;dst[out]=pixels[src];dst[out+1]=pixels[src+1];dst[out+2]=pixels[src+2];}
   if (![rgb writeToFile:parts[0] atomically:YES]) return 5;
   CFRelease(textLine); CGContextRelease(ctx); CGColorSpaceRelease(cs);free(pixels);
  }
  CFRelease(font);
 }
 return 0;
}
