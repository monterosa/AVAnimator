//
//  AVFrame.m
//
//  Created by Moses DeJong on 9/2/12.
//
//  License terms defined in License.txt.

#import "AVFrame.h"

#import "CGFrameBuffer.h"

@implementation AVFrame

@synthesize image = m_image;
@synthesize cgFrameBuffer = m_cgFrameBuffer;

// Constructor

+ (AVFrame*) aVFrame
{
  AVFrame *obj = [[[AVFrame alloc] init] autorelease];
  return obj;
}

- (void) dealloc
{
  self.image = nil;
  self.cgFrameBuffer = nil;
  [super dealloc];
}

// Getter for self.image property. The property is platform specific.

- (
#if TARGET_OS_IPHONE
UIImage*
#else
NSImage*
#endif // TARGET_OS_IPHONE
  )
  image
{
  if (self->m_image == nil)
  {
    if (self.cgFrameBuffer != nil) {
      [self makeImageFromFramebuffer];
    }
  }
  return self->m_image;
}

- (void) makeImageFromFramebuffer
{
  CGFrameBuffer *cgFrameBuffer = self.cgFrameBuffer;
    
  CGImageRef imgRef = [cgFrameBuffer createCGImageRef];
  NSAssert(imgRef != NULL, @"CGImageRef returned by createCGImageRef is NULL");
  
#if TARGET_OS_IPHONE
  UIImage *uiImage = [UIImage imageWithCGImage:imgRef];
  NSAssert(uiImage, @"uiImage is nil");
  
  self.image = uiImage;
#else
  // Mac OS X

  NSSize size = NSMakeSize(cgFrameBuffer.width, cgFrameBuffer.height);
  NSImage *nsImage = [[[NSImage alloc] initWithCGImage:imgRef size:size] autorelease];
  NSAssert(nsImage, @"nsImage is nil");
  
  self.image = nsImage;
#endif // TARGET_OS_IPHONE
  
  CGImageRelease(imgRef);
  NSAssert(cgFrameBuffer.isLockedByDataProvider, @"image buffer should be locked by frame image");  
}

@end