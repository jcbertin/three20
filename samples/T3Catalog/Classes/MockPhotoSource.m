#import "MockPhotoSource.h"

@implementation MockPhotoSource

@synthesize title = _title;

- (id)initWithType:(MockPhotoSourceType)type title:(NSString*)title photos:(NSArray*)photos
    photos2:(NSArray*)photos2 {
  if (self = [super init]) {
    _type = type;
    _delegates = [[NSMutableArray alloc] init];
    
    self.title = title;
    _photos = photos2 ? [[photos mutableCopy] retain] : [[NSMutableArray alloc] init];
    _tempPhotos = photos2 ? [photos2 retain] : [photos retain];

    for (int i = 0; i < _photos.count; ++i) {
      id<T3Photo> photo = [_photos objectAtIndex:i];
      if ((NSNull*)photo != [NSNull null]) {
        photo.photoSource = self;
        photo.index = i;
      }
    }

    if (_type & MockPhotoSourceDelayed || photos2) {
      _isInvalid = T3Invalid;
    } else {
      [self performSelector:@selector(fakeLoadReady)];
    }
  }
  return self;
}

- (void)dealloc {
  [_fakeLoadTimer invalidate];
  [_delegates release];
  [_photos release];
  [_tempPhotos release];
  [_title release];
  [super dealloc];
}

- (void)fakeLoadReady {
  _fakeLoadTimer = nil;
  _isInvalid = T3Valid;

  if (_type & MockPhotoSourceLoadError) {
    [_request.delegate request:_request didFailWithError:nil];

    for (id<T3PhotoSourceDelegate> delegate in _delegates) {
      [delegate photoSource:self didFailWithError:nil];
    }
  } else {
    NSMutableArray* newPhotos = [NSMutableArray array];

    for (int i = 0; i < _photos.count; ++i) {
      id<T3Photo> photo = [_photos objectAtIndex:i];
      if ((NSNull*)photo != [NSNull null]) {
        [newPhotos addObject:photo];
      }
    }

    [newPhotos addObjectsFromArray:_tempPhotos];
    [_tempPhotos release];
    _tempPhotos = nil;

    [_photos release];
    _photos = [newPhotos retain];
    
    for (int i = 0; i < _photos.count; ++i) {
      id<T3Photo> photo = [_photos objectAtIndex:i];
      if ((NSNull*)photo != [NSNull null]) {
        photo.photoSource = self;
        photo.index = i;
      }
    }

    [_request.delegate request:_request loadedData:nil media:nil];

    for (id<T3PhotoSourceDelegate> delegate in _delegates) {
      [delegate photoSourceLoaded:self];
    }
  }
  
  [_request release];
  _request = nil;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// T3Object

- (T3InvalidState)isInvalid {
  return _isInvalid;
}

- (void)setIsInvalid:(T3InvalidState)state {
  _isInvalid = state;
}

- (NSString*) viewURL {
  return nil;
}

+ (id<T3Object>)fromURL:(NSURL*)url {
  return nil;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// T3PhotoSource

- (NSInteger)numberOfPhotos {
  if (_tempPhotos) {
    return _photos.count + (_type & MockPhotoSourceVariableCount ? 0 : _tempPhotos.count);
  } else {
    return _photos.count;
  }
}

- (NSInteger)maxPhotoIndex {
  return _photos.count-1;
}

- (BOOL)loading {
  return !!_fakeLoadTimer;
}

- (id<T3Photo>)photoAtIndex:(NSInteger)index {
  if (index < _photos.count) {
    id photo = [_photos objectAtIndex:index];
    if (photo == [NSNull null]) {
      return nil;
    } else {
      return photo;
    }
  } else {
    return nil;
  }
}

- (void)loadPhotos:(T3URLRequest*)request fromIndex:(NSInteger)fromIndex
    toIndex:(NSInteger)toIndex {
  if (request.cachePolicy & T3URLRequestCachePolicyNetwork) {
    _request = [request retain];
    [_request.delegate requestLoading:_request];
    
    for (id<T3PhotoSourceDelegate> delegate in _delegates) {
      [delegate photoSourceLoading:self];
    }
    
    _fakeLoadTimer = [NSTimer scheduledTimerWithTimeInterval:2 target:self
      selector:@selector(fakeLoadReady) userInfo:nil repeats:NO];
  }
}

- (void)addDelegate:(id<T3PhotoSourceDelegate>)delegate {
  [_delegates addObject:delegate];
}

- (void)removeDelegate:(id<T3PhotoSourceDelegate>)delegate {
  [_delegates removeObject:delegate];
}

@end

///////////////////////////////////////////////////////////////////////////////////////////////////

@implementation MockPhoto

@synthesize photoSource = _photoSource, size = _size, index = _index, caption = _caption;

- (id)initWithURL:(NSString*)url smallURL:(NSString*)smallURL size:(CGSize)size {
  return [self initWithURL:url smallURL:smallURL size:size caption:nil];
}

- (id)initWithURL:(NSString*)url smallURL:(NSString*)smallURL size:(CGSize)size
    caption:(NSString*)caption {
  if (self = [super init]) {
    _photoSource = nil;
    _url = [url copy];
    _smallURL = [smallURL copy];
    _thumbURL = [smallURL copy];
    _size = size;
    _caption = [caption copy];
    _index = NSIntegerMax;
  }
  return self;
}

- (void)dealloc {
  [_url release];
  [_smallURL release];
  [_thumbURL release];
  [_caption release];
  [super dealloc];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// T3Object

- (T3InvalidState)isInvalid {
  return T3Valid;
}

- (void)setIsInvalid:(T3InvalidState)state {
}

- (NSString*)viewURL {
  return nil;
}

+ (id<T3Object>)fromURL:(NSURL*)url {
  return nil;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// T3Photo

- (NSString*)urlForVersion:(T3PhotoVersion)version {
  if (version == T3PhotoVersionLarge) {
    return _url;
  } else if (version == T3PhotoVersionMedium) {
    return _url;
  } else if (version == T3PhotoVersionSmall) {
    return _smallURL;
  } else if (version == T3PhotoVersionThumbnail) {
    return _thumbURL;
  } else {
    return nil;
  }
}

@end