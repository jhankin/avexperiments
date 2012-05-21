//
//  CameraViewController.m
//  AVExperiments
//
//  Created by Joe Hankin on 5/4/12.
//  Copyright (c) 2012 Blackboard, Inc. All rights reserved.
//

#import "CameraViewController_YUV.h"
#import "FZMacros.h"
#import "VideoProcessor.h"
#import <CoreVideo/CoreVideo.h>

typedef struct {
    float Position[3];
    float Color[4];
    float TexCoord[2];
} Vertex;

const Vertex Vertices[] = {
    {{1, -1, 0},    {1, 0, 0, 1},   {1,0}},
    {{1, 1, 0},     {0, 1, 0, 1},   {0,0}},
    {{-1, 1, 0},    {0, 0, 1, 1},   {0,1}},
    {{-1, -1, 0},   {0, 0, 0, 1},   {1,1}}
};

const GLubyte Indices[] = {
    0, 1, 2,
    2, 3, 0
};


static CGFloat DegreesToRadians(CGFloat degrees) {return degrees * M_PI / 180;};


@interface CameraViewController_YUV () {
    EAGLContext *_context;
    GLuint _colorRenderBuffer;
    GLuint _positionSlot;
    GLuint _colorSlot;
    GLuint _texCoordSlot;
    GLuint _textureUniform;
}

#pragma mark - OpenGL View Configuration

- (void)setupContext;
- (void)setupRenderBuffer;
- (void)setupFrameBuffer;
- (void)compileShaders;
- (void)setupVBOs;
- (void)setupDisplayLink;

@end

@implementation CameraViewController_YUV

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _session = [[AVCaptureSession alloc] init];
        _dataOutput = [[AVCaptureVideoDataOutput alloc] init];
        _serialQueue = dispatch_queue_create("com.chronocide.avexperiments.videoprocessorqueue", DISPATCH_QUEUE_SERIAL);
        [_dataOutput setSampleBufferDelegate:self queue:_serialQueue];
        
        
        NSArray *availableVideoCVPixelFormatTypes = _dataOutput.availableVideoCVPixelFormatTypes;
        if ([availableVideoCVPixelFormatTypes containsObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange]]) {
            [_dataOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange] forKey:(NSString *)kCVPixelBufferPixelFormatTypeKey]];
        }
    }
    return self;
}

- (void)dealloc {
    [_session release];
    [_dataOutput release];
    dispatch_release(_serialQueue);
    [_context release];
    [super dealloc];
}

- (void)loadView {
    OpenGLView *eaglView = [[OpenGLView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    _eaglLayer = (CAEAGLLayer *)eaglView.layer;
    _eaglLayer.opaque = YES;
    self.view = eaglView;
    [eaglView release];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setupCamera];
    [self setupOpenGL];
        
    /*
    UIButton *doneButton = [UIButton buttonWithType:UIButtonTypeContactAdd];
    [doneButton addTarget:self action:@selector(doneButtonPress:) forControlEvents:UIControlEventTouchUpInside];
    [doneButton setFrame:CGRectMake(0, 0, doneButton.frame.size.width, doneButton.frame.size.height)];
    [self.view addSubview:doneButton];
     */
}
#pragma mark - Camera Configuration

- (void)setupCamera {
    
    if ([_session canSetSessionPreset:AVCaptureSessionPresetMedium]) {
        _session.sessionPreset = AVCaptureSessionPresetMedium; 
    } 
    
    NSArray *devices = [AVCaptureDevice devices];
    AVCaptureDevice *device = nil;
    for (device in devices) {
        NSLog(@"Device name: %@", [device localizedName]);
        if ([device hasMediaType:AVMediaTypeVideo] && [device position] == AVCaptureDevicePositionBack) {
            break;
        }
    }
    
    NSError *error = nil;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    if (!input) {
        NSLog(@"No input created.  Error: %@", [error localizedDescription]);
    }
    
    [_session beginConfiguration];
    if ([_session canAddInput:input]) {
        [_session addInput:input];
    } else {
        NSLog(@"Session cannot add input %@.", input);
    }
    
    if ([_session canAddOutput:_dataOutput]) {
        [_session addOutput:_dataOutput];
    } else {
        NSLog(@"Session cannot add output %@.", _dataOutput);
    }
    [_session commitConfiguration];
    [_session startRunning];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(captureSessionRuntimeError:) name:AVCaptureSessionRuntimeErrorNotification object:nil];

}

#pragma mark - OpenGL View Configuration

- (void)setupOpenGL {
    [self setupContext];
    [self setupRenderBuffer];
    [self setupFrameBuffer];
    [self compileShaders];
    [self setupVBOs];
    [self setupDisplayLink];
}

- (void)setupContext {
    _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!_context) {
        NSLog(@"Failed to initialize context.");
        exit(1);
    }
    
    if (![EAGLContext setCurrentContext:_context]) {
        NSLog(@"Failed to set current context.");
        exit(1);
    }
}

- (void)setupRenderBuffer {
    glGenRenderbuffers(1, &_colorRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer];
}

- (void)setupFrameBuffer {
    GLuint framebuffer;
    glGenFramebuffers(1, &framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderBuffer);    
}

- (GLuint)compileShader:(NSString *)shaderName withType:(GLenum)shaderType {
    NSString *shaderPath = [[NSBundle mainBundle] pathForResource:shaderName ofType:@"glsl"];
    NSError *error = nil;
    NSString *shaderString = [NSString stringWithContentsOfFile:shaderPath encoding:NSUTF8StringEncoding error:&error];
    if (!shaderString) {
        NSLog(@"Error loading shader: %@", error.localizedDescription);
        exit(1);
    }
    
    // Create OpenGL object to represent the shader.
    GLuint shaderHandle = glCreateShader(shaderType);
    
    // Convert shader code to C-string and pass OpenGL the source code.
    const char *shaderStringUTF8 = [shaderString UTF8String];
    int shaderStringLength = [shaderString length];
    glShaderSource(shaderHandle, 1, &shaderStringUTF8, &shaderStringLength);
    
    // Compile the shader code.
    glCompileShader(shaderHandle);
    
    // Check if it was successful.
    GLint compileSuccess;
    // iv suffix == "integer vector"? or "integer value"?
    glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSuccess);
    if (compileSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetShaderInfoLog(shaderHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"Compile error from OpenGL: %@", messageString);
        exit(1);
    }
    
    return shaderHandle;
}

- (void)compileShaders {
    // Compile your two shaders.
    GLuint vertexShader = [self compileShader:@"SimpleVertex" withType:GL_VERTEX_SHADER];
    GLuint fragmentShader = [self compileShader:@"SimpleFragment" withType:GL_FRAGMENT_SHADER];
    
    // Create an OpenGL program to link the shaders into the pipeline.
    GLuint programHandle = glCreateProgram();
    glAttachShader(programHandle, vertexShader);
    glAttachShader(programHandle, fragmentShader);
    glLinkProgram(programHandle);
    
    // Check for link errors.
    GLint linkSuccess;
    glGetProgramiv(programHandle, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetShaderInfoLog(programHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"Compile error from OpenGL: %@", messageString);
        exit(1);
    }
    
    // Set our linked program to be the one OpenGL uses in the pipeline.
    glUseProgram(programHandle);
    
    _positionSlot = glGetAttribLocation(programHandle, "Position");
    _colorSlot = glGetAttribLocation(programHandle, "SourceColor");
    _texCoordSlot = glGetAttribLocation(programHandle, "TexCoordIn");
    glEnableVertexAttribArray(_positionSlot);
    glEnableVertexAttribArray(_colorSlot);
    glEnableVertexAttribArray(_texCoordSlot);
    
    _textureUniform = glGetUniformLocation(programHandle, "Texture");
    
//    [self makeDonald];
//    glUniform1i(_textureUniform, 0);
}

// VBO == Vertex Buffer Object, an OpenGL object to store per-vertex data and indices.
- (void)setupVBOs {
    GLuint vertexBuffer;
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertices), Vertices, GL_STATIC_DRAW);
    
    GLuint indexBuffer;
    glGenBuffers(1, &indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Indices), Indices, GL_STATIC_DRAW);
}


- (void)setupDisplayLink {
//    CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render:)];
//    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    [_context release];
    _context = nil;
    [_session stopRunning];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

//- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
//{
//    return (interfaceOrientation == UIInterfaceOrientationPortrait);
//}

- (void)doneButtonPress:(id)sender {
    [_session stopRunning];
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - Notifications

- (void)captureSessionRuntimeError:(NSNotification *)notification {

}
/*
- (void)render {
    glClearColor(0, 104.0/255.0, 55.0/255.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    // 1
    glViewport(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    
    // 2
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, 
                          sizeof(Vertex), 0);
    glVertexAttribPointer(_colorSlot, 4, GL_FLOAT, GL_FALSE, 
                          sizeof(Vertex), (GLvoid*) (sizeof(float) * 3));
    
    // 3
    glDrawElements(GL_TRIANGLES, sizeof(Indices)/sizeof(Indices[0]), 
                   GL_UNSIGNED_BYTE, 0);
    [_context presentRenderbuffer:GL_RENDERBUFFER];

}
 */

- (void)render:(CADisplayLink *)displayLink {
    glEnable(GL_TEXTURE_2D);
    glEnable(GL_BLEND);
    glBlendFunc(GL_ONE, GL_SRC_COLOR);
    glClearColor(0, 104.0/255.0, 55.0/255.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);

    glViewport(self.view.frame.origin.x, self.view.frame.origin.y, self.view.frame.size.width, self.view.frame.size.height);
    glVertexAttribPointer(_positionSlot, // refer to the Position pointer
                          3, // each position vector has 3 floats
                          GL_FLOAT, // tell OpenGL they're floats
                          GL_FALSE, // do not normalize the values
                          sizeof(Vertex), // the stride -- i.e., the size of each data point -- is the sizeof the Vertex struct
                          0 // we're looking at the first element of the Vertex struct for position
                          );
    
    glVertexAttribPointer(_colorSlot, // refer to the SourceColor pointer
                          4, // each color vector has 4 floats
                          GL_FLOAT, // tell OpenGL they're floats
                          GL_FALSE, // do not normalize the values
                          sizeof(Vertex), // the stride -- i.e., the size of each data point -- is the sizeof the Vertex struct
                          (GLvoid *)(sizeof(float) * 3) // we're looking at the second element of the Vertex -- i.e. offset by the 3 position floats at the start
                          );
    glVertexAttribPointer(_texCoordSlot, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid *) (sizeof(float) * 7));
//    
//    glActiveTexture(GL_TEXTURE0);
//    glBindTexture(GL_TEXTURE_2D, _bgraTexture);
//    glUniform1i(_textureUniform, 0);
    
    glDrawElements(GL_TRIANGLES, // drawing manner -- in this case, straight-up triangles
                   sizeof(Indices) / sizeof(Indices[0]), // number of elements in Indices array
                   GL_UNSIGNED_BYTE, // size of each index (GLubyte, see declaration of Indices)
                   0 // ordinarily, a pointer to indices -- our indices were already passed to OpenGL in the GL_ELEMENT_ARRAY_BUFFER (see setupVBOs), so no pointer needed here
                   );
    [_context presentRenderbuffer:GL_RENDERBUFFER];
    glFlush();
}

#pragma mark - Textures

- (void)cleanupTextures {
    if (_lumaGluint) {
        glDeleteTextures(1, &_lumaGluint);
        _lumaGluint = 0;
    }
    
    if (_chromaGluint) {
        glDeleteTextures(1, &_chromaGluint);
        _chromaGluint = 0;
    }
}

- (void)generateTextures {
    GLenum error = 0;
    
    [self cleanupTextures];
    
    error = glGetError();
    glActiveTexture(GL_TEXTURE0);
    glGenTextures(1, &_lumaGluint);
    error = glGetError();
    
    NSLog(@"Generated texture: %u", _lumaGluint);
    glBindTexture(GL_TEXTURE_2D, _lumaGluint);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    error = glGetError();
    glUniform1i(_textureUniform, 0);
    error = glGetError();
    
    glActiveTexture(GL_TEXTURE1);
    glGenTextures(1, &_chromaGluint);
    error = glGetError();
    
    NSLog(@"Generated texture: %u", _chromaGluint);
    glBindTexture(GL_TEXTURE_2D, _chromaGluint);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    error = glGetError();
    glUniform1i(_textureUniform, 0);
}


#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate Method

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {

//    dispatch_async(dispatch_get_main_queue(), ^{
//        [self render:nil];
//    });
    
    CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    CVReturn err = CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    void *yPlaneBaseAddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    void *uvPlaneBaseAddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
    
    
    if (err) {
        NSLog(@"Error locking base address: %d", err);
    }
    size_t width = CVPixelBufferGetWidth(pixelBuffer);
    size_t height = CVPixelBufferGetHeight(pixelBuffer);
    OSType pixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer);
    void *baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer);
//    CGImageRef image = [self newCGImageFromPixelBuffer:pixelBuffer];
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self generateTextures];
        glActiveTexture(GL_TEXTURE0);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RED_EXT, width, height, 0, GL_RED_EXT, GL_UNSIGNED_BYTE, yPlaneBaseAddress);
        glActiveTexture(GL_TEXTURE1);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RG_EXT, width / 2, height / 2, 0, GL_RG_EXT, GL_UNSIGNED_BYTE, uvPlaneBaseAddress);

//        [self setTextureImageFromCGImage:image];
        [self render:nil];
//        CGImageRelease(image);
        
    });
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0); 
}

- (CGImageRef)newCGImageFromPixelBuffer:(CVImageBufferRef)pixelBuffer {
    
    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(pixelBuffer);    
    size_t width = CVPixelBufferGetWidth(pixelBuffer);
    size_t height = CVPixelBufferGetHeight(pixelBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    
    CGImageRef newImage = CGBitmapContextCreateImage(newContext);
    
    CGContextRelease(newContext);
    CGColorSpaceRelease(colorSpace);
    
    return newImage;
}

- (void)setTextureImageFromCGImage:(CGImageRef)CGImage {
    GLuint width = CGImageGetWidth(CGImage);
    GLuint height = CGImageGetHeight(CGImage);
    
    CGBitmapInfo info = CGImageGetBitmapInfo(CGImage);
    size_t bpp = CGImageGetBitsPerPixel(CGImage);
    GLenum internal, format;
	// Choose OpenGL format
	switch(bpp)
	{
		default:
		case 32:
		{
			internal = GL_RGBA;
			switch(info & kCGBitmapAlphaInfoMask)
			{
				case kCGImageAlphaPremultipliedFirst:
				case kCGImageAlphaFirst:
				case kCGImageAlphaNoneSkipFirst:
					format = GL_BGRA;
					break;
				default:
					format = GL_RGBA;
			}
			break;
		}
		case 24:
			internal = format = GL_RGB;
			break;
		case 16:
			internal = format = GL_LUMINANCE_ALPHA;
			break;
		case 8:
			internal = format = GL_LUMINANCE;
			break;
	}
	CFDataRef data = CGDataProviderCopyData(CGImageGetDataProvider(CGImage));
	GLubyte *pixels = (GLubyte *)CFDataGetBytePtr(data);
    glTexImage2D(GL_TEXTURE_2D, 0, internal, width, height, 0, format, GL_UNSIGNED_BYTE, pixels);
    
    GLenum error = glGetError();
    if (error) {
        DLog(@"GLError: %u", error);
    }
    CFRelease(data);
}

- (void)setTextureFromBytePointer:(GLubyte *)bytePointer width:(size_t)width height:(size_t)height {
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, bytePointer);
    GLenum error = glGetError();
    if (error) {
        DLog(@"GLError: %u", error);
    }
}

@end
