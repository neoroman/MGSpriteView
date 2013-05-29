//
//  MGSpriteView.m
//  MGSpriteView
//
//  Created by mokagio on 10/05/2013.
//

#import "MGSpriteView.h"
#import "MGSpriteSheetParser.h"
#import "MGSampleRect.h"
#import "MCSpriteLayer.h"

@interface MGSpriteView ()
@property (nonatomic, strong) MCSpriteLayer *animatedLayer;
@property (nonatomic, strong) NSArray *sampleRects;
@property (nonatomic, assign) NSUInteger fps;
@property (nonatomic, assign) CGFloat scaleFactor;
- (NSUInteger)numberOfFrames;
- (void)setInitialPosition;
- (void)setPositionWithSample:(MGSampleRect *)sample;
- (void)setInitialTransform;
- (void)setTransformWithSample:(MGSampleRect *)sample;

- (void)findScaleFactor;
@end

@implementation MGSpriteView

#pragma mark - Designated Initializer

- (id)initWithFrame:(CGRect)frame
spriteSheetFileName:(NSString *)spriteSheetFilename
                fps:(NSUInteger)fps
{
    self = [super init];
    if (self) {
        
        self.view = [[UIView alloc] initWithFrame:frame];
        self.fps = fps;
        
        CGImageRef image = [[UIImage imageNamed:spriteSheetFilename] CGImage];
        NSString *plistFileName = [spriteSheetFilename stringByDeletingPathExtension];
        plistFileName = [plistFileName stringByAppendingPathExtension:@"plist"];
        MGSpriteSheetParser *parser = [[MGSpriteSheetParser alloc] init];
        parser.imageRef = image;
        self.sampleRects = [parser sampleRectsFromFileAtPath:plistFileName];
        
        [self findScaleFactor];

        self.animatedLayer = [MCSpriteLayer layerWithImage:image];
        self.animatedLayer.delegate = self;
        
        [self setInitialPosition];
        [self setInitialTransform];
        
        [self.view.layer addSublayer:self.animatedLayer];
    }
    return self;
}

- (void)runAnimation
{
    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"sampleIndex"];
    anim.fromValue = [NSNumber numberWithInt:1];
    anim.toValue = [NSNumber numberWithInt:self.numberOfFrames + 1];
    anim.duration = [self duration];
    anim.repeatCount = 1;
    [self.animatedLayer addAnimation:anim forKey:nil];
}

#pragma mark - Getters

- (CFTimeInterval)duration
{
    return (1.0 / self.fps) * self.numberOfFrames;
}

- (NSUInteger)numberOfFrames
{
    return [self.sampleRects count];
}

#pragma mark - CALayer Delegate

- (void)displayLayer:(CALayer *)layer;
{
    if (layer == self.animatedLayer) {
        MCSpriteLayer *spriteLayer = (MCSpriteLayer*)layer;
        unsigned int idx = [spriteLayer currentSampleIndex];
        if (idx == 0)
            return;
        
        MGSampleRect *sample = self.sampleRects[idx - 1];

        spriteLayer.bounds = sample.bounds;
        spriteLayer.contentsRect = sample.contentRect;
        [self setPositionWithSample:sample];
        [self setTransformWithSample:sample];
    }
}

#pragma mark - 

- (void)setInitialPosition
{
    MGSampleRect *firstSample = self.sampleRects[0];
    [self setPositionWithSample:firstSample];
}

- (void)setPositionWithSample:(MGSampleRect *)sample
{
    CGFloat evaluatedOffsetX = 0;
    CGFloat evaluatedOffsetY = 0;
    
    evaluatedOffsetX = sample.offset.x;
    evaluatedOffsetY = sample.offset.y;
    
    CGFloat x = self.view.layer.frame.size.width / 2 + evaluatedOffsetX * self.scaleFactor;
    CGFloat y = self.view.layer.frame.size.height / 2 + evaluatedOffsetY * self.scaleFactor;
    self.animatedLayer.position = CGPointMake(x, y);
}

- (void)setInitialTransform
{
    MGSampleRect *firstSample = self.sampleRects[0];
    [self setTransformWithSample:firstSample];
}

- (void)setTransformWithSample:(MGSampleRect *)sample
{
    CATransform3D rotation = CATransform3DIdentity;
    if (sample.rotated) {
        rotation = CATransform3DMakeRotation(-M_PI_2, 0.0, 0.0, 1.0);
    }
    
    CATransform3D scale = CATransform3DMakeScale(self.scaleFactor, self.scaleFactor, 0.0);
    
    self.animatedLayer.transform = CATransform3DConcat(rotation, scale);
}

#pragma mark - Scaling

- (void)findScaleFactor
{
    CGFloat maxWidth = 0;
    CGFloat maxHeight = 0;
    for (MGSampleRect *sampleRect in self.sampleRects) {
        CGFloat width = sampleRect.rotated ? sampleRect.bounds.size.height : sampleRect.bounds.size.width;
        CGFloat height = sampleRect.rotated ? sampleRect.bounds.size.width : sampleRect.bounds.size.height;
        if (width > maxWidth) {
            maxWidth = width;
        }
        if (height > maxHeight) {
            maxHeight = height;
        }
    }
    
    CGFloat scaleFactorWidth = self.view.frame.size.width / maxWidth;
    CGFloat scaleFactorHeight = self.view.frame.size.height / maxHeight;
    
    self.scaleFactor = MIN(scaleFactorHeight, scaleFactorWidth);
}

@end