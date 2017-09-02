#import <Photos/Photos.h>

static UIColor* buttonColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.1];
static UIColor* successColor = [UIColor colorWithRed:0.2 green:0.7 blue:0.15 alpha:1];

@interface Musical : NSObject
- (NSString*)movieURLLocalPath;
- (NSString*)movieURLFullPath;
- (NSString*)movieURLFileName;
- (BOOL)movieURLIsCached;
@end

@interface MLMusicalsTableViewController : UITableViewController
@end

@interface MLRoundButton : UIButton
@end

@interface MLMusicalTableViewCell : UITableViewCell
@property(nonatomic) UIStackView* rightStackView;
@property(nonatomic) MLMusicalsTableViewController* parentTable;
@property(nonatomic) Musical* musical;
@property(nonatomic,retain) MLRoundButton* downloadButton; //new
- (void)saveMusicalToPhotos; //new
- (void)downloadButtonPressed; //new
@end

%hook MLMusicalTableViewCell

%property(nonatomic,retain) MLRoundButton *downloadButton;

%new
- (void)saveMusicalToPhotos
{
  if([self.musical movieURLIsCached])
  {
    //Musical is cached -> Save cached file to photos

    //Get path of cached file
    NSURL* localPath = [NSURL fileURLWithPath:[self.musical movieURLLocalPath]];

    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^
    {
      //Save file to photos
      [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:localPath];
    }
      completionHandler:^(BOOL success, NSError *error)
    {
      if(success)
      {
        dispatch_async(dispatch_get_main_queue(),
        ^{
          //Update background color to reflect that saving was successful
          [self.downloadButton setBackgroundColor:successColor];
        });
      }
    }];
  }
  else
  {
    //Musical is not cached -> Download video and save it to photos

    //Get videoURL
    NSURL* videoURL = [NSURL URLWithString:[self.musical movieURLFullPath]];

    //Get sharedSession
    NSURLSession* session = [NSURLSession sharedSession];

    //Create download task
    NSURLSessionDownloadTask* musicalDownloadTask =
      [session downloadTaskWithURL:videoURL
      completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error)
    {
      //Get expected filename
      NSString* filename = [self.musical movieURLFileName];

      NSLog(@"filename: %@", filename);

      //Rename file to filename
      [location setResourceValue:filename forKey:NSURLNameKey error:nil];

      //Update location with new filename
      location = [[location URLByDeletingLastPathComponent]
        URLByAppendingPathComponent:filename];

      if(!error)
      {
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^
        {
          //Save downloaded file to photos
          [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:location];
        }
          completionHandler:^(BOOL success, NSError *error)
        {
          //Remove file
          [[NSFileManager defaultManager] removeItemAtURL:location error:nil];

          if(success)
          {
            dispatch_async(dispatch_get_main_queue(),
            ^{
              //Update background color to reflect that saving was successful
              [self.downloadButton setBackgroundColor:successColor];
            });
          }
        }];
      }
    }];

    //Start download
    [musicalDownloadTask resume];
  }
}

%new
- (void)downloadButtonPressed
{
  PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
  switch(status)
  {
    case PHAuthorizationStatusNotDetermined:
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus authorizationStatus)
    {
      //Save video if user grants permission
      if(authorizationStatus == PHAuthorizationStatusAuthorized)
      {
        [self saveMusicalToPhotos];
      }
    }];
    break;

    case PHAuthorizationStatusAuthorized:
    //Save musical
    [self saveMusicalToPhotos];
    break;

    case PHAuthorizationStatusDenied:
    UIAlertController* permissionAlert = [UIAlertController
      alertControllerWithTitle:@"Error"
      message:@"In order to save a video through Downloadally, musical.ly needs permissions to photos!"
      preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
      style:UIAlertActionStyleCancel
      handler:nil];

    UIAlertAction* settingsAction = [UIAlertAction actionWithTitle:@"Settings"
    style:UIAlertActionStyleDefault
    handler:^(UIAlertAction* action)
    {
      [[UIApplication sharedApplication]
        openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }];

    [permissionAlert addAction:cancelAction];
    [permissionAlert addAction:settingsAction];

    [self.parentTable presentViewController:permissionAlert animated:YES completion:nil];

    break;
  }
}

%end

%hook MLMusicalsTableViewController

- (id)configureCell:(MLMusicalTableViewCell*)cell atIndexPath:(id)indexPath
{
  if(!cell.downloadButton)
  {
    //Create MLRoundButton
    cell.downloadButton = [%c(MLRoundButton) buttonWithType:UIButtonTypeCustom];

    //Add target function
    [cell.downloadButton addTarget:cell action:@selector(downloadButtonPressed)
      forControlEvents:UIControlEventTouchUpInside];

    //Set image to download icon
    [cell.downloadButton setImage:[UIImage imageWithContentsOfFile:
      @"/Library/Application Support/Downloadally.bundle/Download.png"]
      forState:UIControlStateNormal];

    //Make it look and feel like the other buttons
    cell.downloadButton.adjustsImageWhenHighlighted = YES;
    [cell.downloadButton setBackgroundColor:buttonColor];
    [cell.downloadButton.heightAnchor constraintEqualToConstant:48].active = true;
    [cell.downloadButton.widthAnchor constraintEqualToConstant:48].active = true;

    //Add button to StackView
    [cell.rightStackView insertArrangedSubview:cell.downloadButton
      atIndex:[cell.rightStackView.arrangedSubviews count] - 2];
  }
  else
  {
    [cell.downloadButton setBackgroundColor:buttonColor];
  }

  return %orig;
}

%end
