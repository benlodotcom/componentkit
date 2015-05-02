/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKCollectionViewTransactionalDataSource.h"

#import "CKComponentInternal.h"
#import "CKCollectionViewDataSourceCell.h"
#import "CKTransactionalComponentDataSourceConfiguration.h"
#import "CKTransactionalComponentDataSourceListener.h"
#import "CKTransactionalComponentDataSourceItem.h"
#import "CKTransactionalComponentDataSourceState.h"
#import "CKTransactionalComponentDataSourceAppliedChanges.h"
#import "CKComponentRootView.h"
#import "CKComponentLayout.h"

@interface CKCollectionViewTransactionalDataSource () <
UICollectionViewDataSource,
CKTransactionalComponentDataSourceListener
>
{
  CKTransactionalComponentDataSource *_componentDataSource;
  CKTransactionalComponentDataSourceState *_currentState;
}
@end

@implementation CKCollectionViewTransactionalDataSource

- (instancetype)initWithCollectionView:(UICollectionView *)collectionView
                     componentProvider:(Class<CKComponentProvider>)componentProvider
                               context:(id<NSObject>)context
                        itemsSizeRange:(const CKSizeRange &)itemsSizeRange
{
  self = [super init];
  if (self) {
    CKTransactionalComponentDataSourceConfiguration *datasourceConfiguration = [[CKTransactionalComponentDataSourceConfiguration alloc] initWithComponentProvider:componentProvider
                                                                                                                                                          context:context
                                                                                                                                                        sizeRange:itemsSizeRange];
    _componentDataSource = [[CKTransactionalComponentDataSource alloc] initWithConfiguration:datasourceConfiguration];
    [_componentDataSource addListener:self];
    
    _collectionView = collectionView;
    _collectionView.dataSource = self;
    [_collectionView registerClass:[CKCollectionViewDataSourceCell class] forCellWithReuseIdentifier:kReuseIdentifier];
  }
  return self;
}

#pragma mark - Changeset application

- (void)applyChangeset:(CKTransactionalComponentDataSourceChangeset *)changeset
                  mode:(CKTransactionalComponentDataSourceMode)mode
              userInfo:(NSDictionary *)userInfo
{
  [_componentDataSource applyChangeset:changeset
                                  mode:CKTransactionalComponentDataSourceModeSynchronous
                              userInfo:userInfo];
}

static void applyChangesToCollectionView(CKTransactionalComponentDataSourceAppliedChanges *changes, UICollectionView *collectionView)
{
  [collectionView reloadItemsAtIndexPaths:[changes.updatedIndexPaths allObjects]];
  [collectionView deleteItemsAtIndexPaths:[changes.removedIndexPaths allObjects]];
  [collectionView deleteSections:changes.removedSections];
  for (NSIndexPath *from in changes.movedIndexPaths) {
    NSIndexPath *to = changes.movedIndexPaths[from];
    [collectionView moveItemAtIndexPath:from toIndexPath:to];
  }
  [collectionView insertSections:changes.insertedSections];
  [collectionView insertItemsAtIndexPaths:[changes.insertedIndexPaths allObjects]];
}

#pragma mark - CKTransactionalComponentDataSourceListener

- (void)transactionalComponentDataSource:(CKTransactionalComponentDataSource *)dataSource
                  didModifyPreviousState:(CKTransactionalComponentDataSourceState *)previousState
                       byApplyingChanges:(CKTransactionalComponentDataSourceAppliedChanges *)changes
{
  [_collectionView performBatchUpdates:^{
    applyChangesToCollectionView(changes, _collectionView);
    _currentState = [_componentDataSource state];
  } completion:NULL];
}

#pragma mark - State

- (CGSize)sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
  return [_currentState objectAtIndexPath:indexPath].layout.size;
}

#pragma mark - UICollectionViewDataSource

static NSString *const kReuseIdentifier = @"com.component_kit.collection_view_data_source.cell";

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
  CKTransactionalComponentDataSourceItem *item = [_currentState objectAtIndexPath:indexPath];
  CKCollectionViewDataSourceCell *cell = [_collectionView dequeueReusableCellWithReuseIdentifier:kReuseIdentifier forIndexPath:indexPath];
  CKMountComponentLayout(item.layout, cell.rootView);
  return cell;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
  return _currentState ? [_currentState numberOfSections] : 0;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
  return _currentState ? [_currentState numberOfObjectsInSection:section] : 0;
}

@end