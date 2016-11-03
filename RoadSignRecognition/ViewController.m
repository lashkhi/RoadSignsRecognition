//
//  ViewController.m
//  RoadSignRecognition
//
//  Created by David Lashkhi on 30/10/2016.
//  Copyright © 2016 David Lashkhi. All rights reserved.
//

#import "ViewController.h"
#import <CraftAROnDeviceRecognitionSDK/CraftARSDK.h>
#import <CraftAROnDeviceRecognitionSDK/CraftAROnDeviceIR.h>
#import <CraftAROnDeviceRecognitionSDK/CraftARCollection.h>
#import <CraftAROnDeviceRecognitionSDK/CraftARCollectionManager.h>



@interface ViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, CraftARSDKProtocol, SearchProtocol>
@property (nonatomic, strong) UIImagePickerController *imagePicker;
@property (nonatomic, strong) UIImage *imageToRecognize;
@property (nonatomic, strong) CraftARSDK *sdk;
@property (nonatomic, strong) CraftAROnDeviceIR *oir;
@property (nonatomic, strong) CraftARQueryImage *arImage;
@property (nonatomic, strong) CraftARSDK* mSDK;
@property (nonatomic, strong) CraftARCollectionManager* mCollectionManager;
@property (nonatomic, strong) CraftAROnDeviceIR* mOnDeviceIR;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self addCollectionBundle];
    
    

}

- (void) viewWillAppear:(BOOL) animated {
    [super viewWillAppear:animated];
    
    // setup the CraftAR SDK
    self.sdk = [CraftARSDK sharedCraftARSDK];
    
    // Become delegate of the SDK to receive capture initialization callbacks
    self.sdk.delegate = self;
    
    // Initialize the video capture on our preview view.
    [self.sdk startCaptureWithView:self.view];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - basic setup

- (void)addCollectionBundle {
    self.mSDK = [CraftARSDK sharedCraftARSDK];
    self.mCollectionManager = [CraftARCollectionManager sharedCollectionManager];
    
    self.mOnDeviceIR = [CraftAROnDeviceIR sharedCraftAROnDeviceIR];
    
    NSError* error;
    // Get the collection if it is already in the device
    CraftAROnDeviceCollection* demoCollection = [self.mCollectionManager getCollectionWithToken:@"e000e1e5ecc44b76" andError:&error];
    
    // if it is not in the device load it
    if (demoCollection == nil) {
        NSLog(@"Error getting collection: %@", [error localizedDescription]);
        [self addDemoCollection];
    } else {
        [demoCollection syncWithOnDone:^(CraftAROnDeviceCollection *collection, int itemDownloads, int downloadErrors) {
            [self loadDemoCollection: demoCollection];
        } andOnError:^(NSError *error) {
            NSLog(@"Error synchronizing collection: %@", [error localizedDescription]);
        }];

    }

    
    if (error != nil    ) {
        // Error getting collection
    }
    
    // if it is not in the device load it
    if (demoCollection == nil) {
       // [self addDemoCollection];
    } else {
        // demo collection is already added to the device
    }
}

- (void) addDemoCollection {
    
    // Get the collection bundle file that contains the image database for recognition
    NSString* bundlePath = [[NSBundle mainBundle] pathForResource:
                            @"afbd55248c2e440696c4af82d7808dd0" ofType: @"zip"];
    
    // Add the collection to the device
    [self.mCollectionManager addCollectionFromBundle:bundlePath withOnProgress:^(float progress) {
        NSLog(@"Add bundle progress: %f", progress);
    } andOnSuccess:^(CraftARCollection *collection) {
        // the collection is now added to the device
    } andOnError:^(NSError *error) {
        NSLog(@"Error adding collection: %@", [error localizedDescription]);
    }];
}


- (void) loadDemoCollection: (CraftAROnDeviceCollection*) collection {
    
    // Load the collection before doing any searches
    [self.mOnDeviceIR setCollection:collection setActive:YES withOnProgress:^(float progress) {
        NSLog(@"Load collection progress: %f", progress);
    } onSuccess:^{
        // Now the collection is ready for recognition
    } andOnError:^(NSError *error) {
        NSLog(@"Error adding collection: %@", [error localizedDescription]);
    }];
}





- (IBAction)selectImage:(id)sender {
    
    [_sdk singleShotSearch];

       self.imagePicker = [[UIImagePickerController alloc] init];
    self.imagePicker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    
    self.imagePicker.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType: UIImagePickerControllerSourceTypeSavedPhotosAlbum];
    
    
    self.imagePicker.allowsEditing = NO;
    
    self.imagePicker.delegate = self;
    
    [self presentViewController:self.imagePicker animated:YES completion:nil];
}

#pragma mark - UIImagePickerControllerDelegate

// This method is called when an image has been chosen from the library or taken from the camera.
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    self.imageToRecognize = [info valueForKey:UIImagePickerControllerOriginalImage];
    [self dismissViewControllerAnimated:YES completion:nil];
    [self recognizeImage];

}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Recognize image

- (void) didStartCapture {
    
    // Get On Device Image Recognition class (for on-device searches)
    // and set it as the search controller delegate for the SDK
    _oir = [CraftAROnDeviceIR sharedCraftAROnDeviceIR];
    _sdk.searchControllerDelegate = _oir.mSearchController;
    
    // Set the view controller as delegate of the OnDeviceIR to recieve the
    // search results
    _oir.delegate = self;
}


- (void)recognizeImage {
    
    if (!self.imageToRecognize) {
        return;
    }
    
    self.arImage = [[CraftARQueryImage alloc] initWithUIImage:self.imageToRecognize];
    
    [self.oir searchWithImage:self.arImage andRequestCode:1 withOnResults:^(NSArray *results, NSInteger requestCode) {
        NSLog(@"Found something ");
    } andOnError:^(NSError *error, NSInteger requestCode) {
        //
    }];
    
    [self.oir searchWithImage:self.arImage withOnResults:^(NSArray *results) {
        NSLog(@"Found something ");
    } andOnError:^(NSError *error) {
        //
    }];
    
}

- (void) didGetSearchResults:(NSArray *)resultItems {
     NSLog(@"Found something");
}

@end
