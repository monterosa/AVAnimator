//
//  AVAnimatorLayerTests.m
//
//  Created by Moses DeJong on 1/29/11.
//
//  License terms defined in License.txt.

#import "RegressionTests.h"

#import "AVAnimatorLayer.h"
#include "AVAnimatorLayerPrivate.h"

#import "AVAnimatorMedia.h"
#import "AVAnimatorMediaPrivate.h"

#import "AVAppResourceLoader.h"
#import "AVMvidFrameDecoder.h"

#import "AVFileUtil.h"

@interface AVAnimatorLayerTests : NSObject {}
@end

// The methods named test* will be automatically invoked by the RegressionTests harness.

@implementation AVAnimatorLayerTests

// Get a pixel value from an image

+ (void) getPixels16BPP:(CGImageRef)image
                     offset:(int)offset
                    nPixels:(int)nPixels
                  pixelPtr:(void*)pixelPtr
{
  // Query pixel data at a specific pixel offset
  
  CFDataRef pixelData = CGDataProviderCopyData(CGImageGetDataProvider(image));  
  CFDataGetBytes(pixelData, CFRangeMake(offset, sizeof(uint16_t) * nPixels), (UInt8*)pixelPtr);
  CFRelease(pixelData);
}

// This test case will load a mvid attached as a project resource
// and test the pixel colors to verify that the decoding logic is
// converting in the case of 16 BPP rle555 pixels.

+ (void) testBlackBlue2x2_16BPP
{
	id appDelegate = [[UIApplication sharedApplication] delegate];	
	UIWindow *window = [appDelegate window];
	NSAssert(window, @"window");  
  
  NSString *resourceName = @"2x2_black_blue_16BPP.mvid";
  
  // Create a plain AVAnimatorView without a movie controls and display
  // in portrait mode. This setup involves no containing views and
  // has no transforms applied to the AVAnimatorView.
  
  CGRect frame = CGRectMake(0, 0, 2, 2);
  UIView *view = [[[UIView alloc] initWithFrame:frame] autorelease];
  CALayer *viewLayer = view.layer;
  
  AVAnimatorLayer *avLayerObj = [AVAnimatorLayer aVAnimatorLayer:viewLayer];
  
  // Create Media object and link it to the animatorView
  
  AVAnimatorMedia *media = [AVAnimatorMedia aVAnimatorMedia];
  [avLayerObj attachMedia:media];
  
  // Create loader that will read a movie file from app resources.
  
	AVAppResourceLoader *resLoader = [AVAppResourceLoader aVAppResourceLoader];
  resLoader.movieFilename = resourceName;
	media.resourceLoader = resLoader;
  
  // Create decoder that will generate frames from Quicktime Animation encoded data
  
  AVMvidFrameDecoder *frameDecoder = [AVMvidFrameDecoder aVMvidFrameDecoder];
	media.frameDecoder = frameDecoder;
  
  media.animatorFrameDuration = 1.0;
  
  [window addSubview:view];
      
  [media prepareToAnimate];
  
  BOOL worked = [RegressionTests waitUntilTrue:media
                                      selector:@selector(isReadyToAnimate)
                                   maxWaitTime:10.0];
  NSAssert(worked, @"worked");
  
  NSAssert(media.state == READY, @"isReadyToAnimate");
  
  // At this point, initial keyframe should be displayed
  
  NSAssert([frameDecoder hasAlphaChannel] == FALSE, @"hasAlphaChannel");
  
  NSAssert(media.currentFrame == 0, @"currentFrame");
  
  NSAssert(avLayerObj.image != nil, @"image");
  
  NSAssert(media.prevFrame == nil, @"prev frame not set properly");
  
  uint16_t pixel[4];

  // First frame is all black pixels
  
  [self getPixels16BPP:avLayerObj.image.CGImage
                offset:0
               nPixels:4
              pixelPtr:&pixel[0]];
  
  NSAssert(pixel[0] == 0x0, @"pixel");  
  NSAssert(pixel[1] == 0x0, @"pixel");  
  NSAssert(pixel[2] == 0x0, @"pixel");  
  NSAssert(pixel[3] == 0x0, @"pixel");
  
  // Double check that the contents field matches the core graphics image

  NSAssert(avLayerObj.image.CGImage != nil, @"CGImage is nil");
  NSAssert((id)avLayerObj.image.CGImage == viewLayer.contents, @"contents not set");
  
  // Second frame is all blue pixels
  
  UIImage *frameBefore = avLayerObj.image;
  
  [media showFrame:1];
  
  UIImage *frameAfter = avLayerObj.image;
  
  NSAssert(frameAfter != nil, @"image");
  NSAssert(frameBefore != frameAfter, @"image");

  [self getPixels16BPP:avLayerObj.image.CGImage
                offset:0
               nPixels:4
              pixelPtr:&pixel[0]];
  
  NSAssert(pixel[0] == 0x1F, @"pixel");  
  NSAssert(pixel[1] == 0x1F, @"pixel");  
  NSAssert(pixel[2] == 0x1F, @"pixel");  
  NSAssert(pixel[3] == 0x1F, @"pixel");
  
  // Double check that the contents field matches the core graphics image
  
  NSAssert(avLayerObj.image.CGImage != nil, @"CGImage is nil");
  NSAssert((id)avLayerObj.image.CGImage == viewLayer.contents, @"contents not set");  
  
  return;
}

// This test case checks that the layer.image property can be set to nil
// to indicate that no image should be displayed in the layer.

+ (void) testSetImageToNil
{
	id appDelegate = [[UIApplication sharedApplication] delegate];	
	UIWindow *window = [appDelegate window];
	NSAssert(window, @"window");  
  
  NSString *resourceName = @"1x1.gif";
  NSString *resPath = [AVFileUtil getResourcePath:resourceName];
  
  CGRect frame = CGRectMake(0, 0, 2, 2);
  UIView *view = [[[UIView alloc] initWithFrame:frame] autorelease];
  CALayer *viewLayer = view.layer;
  
  AVAnimatorLayer *avLayerObj = [AVAnimatorLayer aVAnimatorLayer:viewLayer];
  NSAssert(avLayerObj, @"avLayerObj");
  
  [window addSubview:view];
  
  // Set image property of the view to a 1x1 image
  
  UIImage *image = [UIImage imageWithContentsOfFile:resPath];
  NSAssert(image, @"image");
  
  NSAssert(avLayerObj.image == nil, @"image should initially be nil");
  avLayerObj.image = image;
  NSAssert(avLayerObj.image != nil, @"image is nil");
  NSAssert(avLayerObj.image == image, @"image");
  
  // Now set the image propert to nil to make sure that clear the current image.
  
  avLayerObj.image = nil;
  NSAssert(avLayerObj.image == nil, @"image");
  
  return;
}

// Note that the opaque property is documented to have no effect on a CALayer when
// explicitly providing an image for the contents. Also, a AVAnimatorLayer can't
// be expected to set properties of the view that contains the layer, so if opaque
// were to be set on the outer layer, then the calling code would need to do that.
 
@end
