#include "headers/Musical.h"
#include "headers/MLMusicalTableViewCell.h"
#include "headers/MLRoundButton.h"
#include "headers/MLRoundImageView.h"
#include "headers/WPSAlertController.m" //To make presenting AlertControllers more easy
#include <Photos/Photos.h>

%hook MLMusicalTableViewCell

MLRoundButton *downloadButton = [objc_getClass("MLRoundButton") buttonWithType:UIButtonTypeCustom]; //The button
CGRect downloadButtonFrame; //Frame for button
_Bool firstStart = true; //Self explanatory
NSURL *currentURL = nil; //Storing current video path here
NSURL *prevURL = nil; //Storing previous video path here (for comparing)

- (void)layoutSubviews
{
  if(firstStart)
  {
    downloadButtonFrame = self.commentsButton.frame; //Assign frame on first start
    firstStart = false;
  }

  int moveUpBy = 49; //Value to move the buttons up

  //Check if method was already run / buttons are already moved (sometimes it gets executed more than one time)
  if(self.moreActionButton.frame.origin.y - moveUpBy == self.commentsButton.frame.origin.y)
  {
    //Move all buttons up by the variable "moveUpBy"
    self.userAvatarImageView.frame = CGRectMake(self.userAvatarImageView.frame.origin.x,self.userAvatarImageView.frame.origin.y - moveUpBy,self.userAvatarImageView.frame.size.width,self.userAvatarImageView.frame.size.height);
    self.likeNumLabel.frame = CGRectMake(self.likeNumLabel.frame.origin.x,self.likeNumLabel.frame.origin.y - moveUpBy,self.likeNumLabel.frame.size.width,self.likeNumLabel.frame.size.height);
    self.likeButton.frame = CGRectMake(self.likeButton.frame.origin.x,self.likeButton.frame.origin.y - moveUpBy,self.likeButton.frame.size.width,self.likeButton.frame.size.height);
    self.commentsNumLabel.frame = CGRectMake(self.commentsNumLabel.frame.origin.x,self.commentsNumLabel.frame.origin.y - moveUpBy,self.commentsNumLabel.frame.size.width,self.commentsNumLabel.frame.size.height);
    self.commentsButton.frame = CGRectMake(self.commentsButton.frame.origin.x,self.commentsButton.frame.origin.y - moveUpBy,self.commentsButton.frame.size.width,self.commentsButton.frame.size.height);
  }
  %orig;
}

- (void)continuePlay
{
  %orig;
  [self setButton];
}

- (void)startPlay
{
  %orig;
  [self setButton];
}

%new
- (void)setButton
{
  //Set current URL
  currentURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@", [self.musical movieURLLocalPath]]];

  //Configure button to look like the others
  [downloadButton addTarget:self action:@selector(saveVideo) forControlEvents:UIControlEventTouchUpInside];
  [downloadButton setImage:[UIImage imageWithContentsOfFile:@"/Library/Application Support/Downloadally.bundle/download.png"] forState:UIControlStateNormal];
  downloadButton.adjustsImageWhenHighlighted = true;
  downloadButton.frame = downloadButtonFrame;
  [downloadButton setUp];
  [downloadButton setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.1]];

  //Add button
  [self addSubview:downloadButton];
}

%new
- (void)saveVideo
{
  //Resolves an issue where a single video would be saved mulitple times
  if(currentURL != prevURL)
  {
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    switch (status)
    {
      //Access to photos granted, save video
      case PHAuthorizationStatusAuthorized:
          [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^
          {
            [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:currentURL];
          }
          completionHandler:^(BOOL success, NSError *error){}];
          [downloadButton setBackgroundColor:[UIColor colorWithRed:0.18 green:0.7 blue:0.15 alpha:1]];
          [downloadButton.superview addSubview:downloadButton];
          break;

      //Permission not determined yet, ask user
      case PHAuthorizationStatusNotDetermined:
      [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus authorizationStatus)
      {
        //Save video if user grants permission
        if (authorizationStatus == PHAuthorizationStatusAuthorized)
          {
            [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^
            {
              [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:currentURL];
            }
            completionHandler:^(BOOL success, NSError *error){}];
            [downloadButton setBackgroundColor:[UIColor colorWithRed:0.18 green:0.7 blue:0.15 alpha:1]];
            [downloadButton.superview addSubview:downloadButton];
          }
      }];
        break;

        //If permission was denied, show a popup asking for permission
        default:
          WPSAlertController *permissionError = [WPSAlertController alertControllerWithTitle:@"Error" message:@"Musical.ly needs permissions to photos in order for downloadally to save videos" preferredStyle:UIAlertControllerStyleAlert];

          UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
          {
            [permissionError dismissViewControllerAnimated:YES completion:nil];
          }];

          UIAlertAction *settings = [UIAlertAction actionWithTitle:@"Settings" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action)
          {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
          }];

          [permissionError addAction:cancel];
          [permissionError addAction:settings];
          [permissionError show];
          break;
    }
  }
  //Set "previous" path for next download
  prevURL = currentURL;
}
%end
