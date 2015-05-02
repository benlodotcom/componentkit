/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <Foundation/Foundation.h>

#import <ComponentKit/CKDimension.h>

#import "CKTransactionalComponentDataSource.h"

/**
 This class is an implementation of a `UICollectionViewDataSource` that can be used along with components. For each set of changes (i.e insertion/deletion/update
 of items and/or insertion/deletion of sections) the datasource will compute asynchronously on a background thread the corresponding component trees and then
 apply the corresponding UI changes to the collection view leveraging automatically view reuse.
 
 Doing so this reverses the traditional approach for a `UICollectionViewDataSource`. Usually the controller layer will *tell* the `UICollectionView` to update and
 then the `UICollectionView` *ask* the datasource for the data. Here the model is  more Reactive, from an external prospective, the datasource is *told* what
 changes to apply and then *tell* the collection view to apply the corresponding changes.
 */
@interface CKCollectionViewTransactionalDataSource : NSObject

- (instancetype)initWithCollectionView:(UICollectionView *)collectionView
                     componentProvider:(Class<CKComponentProvider>)componentProvider
                               context:(id<NSObject>)context
                        itemsSizeRange:(const CKSizeRange &)itemsSizeRange;

- (void)applyChangeset:(CKTransactionalComponentDataSourceChangeset *)changeset
                  mode:(CKTransactionalComponentDataSourceMode)mode
              userInfo:(NSDictionary *)userInfo;

- (CGSize)sizeForItemAtIndexPath:(NSIndexPath *)indexPath;

@property (readonly, nonatomic, strong) UICollectionView *collectionView;

@end