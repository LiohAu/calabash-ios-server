//
//  UIScriptASTClassName.m
//  Created by Karl Krukow on 12/08/11.
//  Copyright 2011 LessPainful. All rights reserved.
//

#import "UIScriptASTClassName.h"
#import "LPTouchUtils.h"


@implementation UIScriptASTClassName
@synthesize className = _className;


- (id) initWithClassName:(NSString *) className {
  self = [super init];
  if (self) {
    if ([@"*" isEqualToString:className]) {
      className = @"UIView";
    }
    self.className = [[className copy] autorelease];
    _class = NSClassFromString(self.className);
  }
  return self;
}


- (NSMutableArray *) evalWith:(NSArray *) views direction:(UIScriptASTDirectionType) dir visibility:(UIScriptASTVisibilityType) visibility {

  NSMutableArray *res = [NSMutableArray arrayWithCapacity:8];

  for (UIView *view in views) {
    switch (dir) {
      case UIScriptASTDirectionTypeDescendant:
        [self evalDescWith:view result:res visibility:visibility];
        break;
      case UIScriptASTDirectionTypeChild:
        [self evalChildWith:view result:res visibility:visibility];
        break;
      case UIScriptASTDirectionTypeParent:
        [self evalParentsWith:view result:res visibility:visibility];
        break;
      case UIScriptASTDirectionTypeSibling:
        [self evalSiblingsWith:view result:res visibility:visibility];
        break;
    }
  }


  return res;
}


static NSInteger sortFunction(UIView *v1, UIView *v2, void *ctx) {
  CGPoint p1 = v1.frame.origin;
  CGPoint p2 = v2.frame.origin;
  if (p1.x < p2.x) {
    return -1;
  } else if (p1.x == p2.x) {
    if (p1.y < p2.y) {
      return -1;
    } else if (p1.y == p2.y) {
      return 0;
    } else {
      return 1;
    }
  } else {
    return 1;
  }
}


- (void) addView:(UIView *) view toArray:(NSMutableArray *) res ifMatchesVisibility:(UIScriptASTVisibilityType) visibility {
  if (visibility == UIScriptASTVisibilityTypeAll || [LPTouchUtils isViewVisible:view]) {
    [res addObject:view];
  }
}

- (NSMutableArray *)cellsForCollectionView:(UICollectionView *)collectionView
{
  NSMutableArray * cells = [[NSMutableArray alloc] initWithCapacity: 30];
  id<UICollectionViewDataSource> dataSource = [collectionView dataSource];
  if (dataSource)
  {
    NSInteger sections = [dataSource numberOfSectionsInCollectionView: collectionView];
    for (NSInteger section = 0; section < sections; section++)
    {
      NSInteger rows = [dataSource collectionView: collectionView numberOfItemsInSection: section];
      for (NSInteger row = 0; row < rows; row++)
      {
        UICollectionViewCell * cell = [dataSource collectionView: collectionView cellForItemAtIndexPath: [NSIndexPath indexPathForRow: row inSection: section]];
        if (cell)
          [cells addObject: cell];
      }
    }
  }
  
  return cells;
}

- (NSMutableArray *)cellsForTableView:(UITableView *)tableView
{
  NSMutableArray * cells = [[NSMutableArray alloc] initWithCapacity: 30];
  id<UITableViewDataSource> dataSource = [tableView dataSource];
  if (dataSource)
  {
    NSInteger sections = [dataSource numberOfSectionsInTableView: tableView];
    for (NSInteger section = 0; section < sections; section++)
    {
      NSInteger rows = [dataSource tableView: tableView numberOfRowsInSection: section];
      for (NSInteger row = 0; row < rows; row++)
      {
        UITableViewCell * cell = [dataSource tableView: tableView cellForRowAtIndexPath: [NSIndexPath indexPathForRow: row inSection: section]];
        if (cell)
          [cells addObject: cell];
      }
    }
  }
  
  return cells;
}

- (void) evalDescWith:(UIView *) view result:(NSMutableArray *) res visibility:(UIScriptASTVisibilityType) visibility {
  if ([view isKindOfClass:_class]) {
    [self addView:view toArray:res ifMatchesVisibility:visibility];
  }

  if (visibility == UIScriptASTVisibilityTypeAll && [view isKindOfClass: [UICollectionView class]] && [_class isSubclassOfClass: [UICollectionViewCell class]])
    [res addObjectsFromArray: [self cellsForCollectionView: (UICollectionView *)view]];
  else if (visibility == UIScriptASTVisibilityTypeAll && [view isKindOfClass: [UITableView class]] && [_class isSubclassOfClass: [UITableViewCell class]])
    [res addObjectsFromArray: [self cellsForTableView: (UITableView *)view]];
  else
  {
    for (UIView *subview in [[view subviews]
            sortedArrayUsingFunction:sortFunction context:view]) {
      [self evalDescWith:subview result:res visibility:visibility];
    }
  }
}

- (void) evalChildWith:(UIView *) view result:(NSMutableArray *) res visibility:(UIScriptASTVisibilityType) visibility {
  
  if (visibility == UIScriptASTVisibilityTypeAll && [view isKindOfClass: [UICollectionView class]] && [_class isSubclassOfClass: [UICollectionViewCell class]])
    [res addObjectsFromArray: [self cellsForCollectionView: (UICollectionView *)view]];
  else if (visibility == UIScriptASTVisibilityTypeAll && [view isKindOfClass: [UITableView class]] && [_class isSubclassOfClass: [UITableViewCell class]])
    [res addObjectsFromArray: [self cellsForTableView: (UITableView *)view]];
  else
  {
    for (UIView *childView in [view subviews]) {
      if ([childView isKindOfClass:_class]) {
        [self addView:childView toArray:res ifMatchesVisibility:visibility];
      }
    }
  }
}


- (void) evalParentsWith:(UIView *) view result:(NSMutableArray *) res visibility:(UIScriptASTVisibilityType) visibility {
//    if ([view isKindOfClass:_class]) {
//        [res addObject:view];
//    }
  //I guess view itself isnt part of parents.
  UIView *parentView = [view superview];
  if ([parentView isKindOfClass:_class]) {
    [self addView:parentView toArray:res ifMatchesVisibility:visibility];
  }

  if (parentView) {
    [self evalParentsWith:parentView result:res visibility:visibility];
  }
}


- (void) evalSiblingsWith:(UIView *) view result:(NSMutableArray *) res visibility:(UIScriptASTVisibilityType) visibility {
  UIView *parentView = [view superview];
  
  if (visibility == UIScriptASTVisibilityTypeAll && [parentView isKindOfClass: [UICollectionView class]] && [_class isSubclassOfClass: [UICollectionViewCell class]])
    [res addObjectsFromArray: [self cellsForCollectionView: (UICollectionView *)view]];
  else if (visibility == UIScriptASTVisibilityTypeAll && [parentView isKindOfClass: [UITableView class]] && [_class isSubclassOfClass: [UITableViewCell class]])
    [res addObjectsFromArray: [self cellsForTableView: (UITableView *)view]];
  else
  {
    NSArray *children = [parentView subviews];
    for (UIView *siblingOrSelf in children) {
      if (siblingOrSelf != view && [siblingOrSelf isKindOfClass:_class]) {
        [self addView:siblingOrSelf toArray:res ifMatchesVisibility:visibility];
      }
    }
  }
}


- (NSString *) description {
  return [NSString stringWithFormat:@"view:'%@'", self.className];
}


- (void) dealloc {
  _class = NULL;
  [_className release];
  _className = nil;
  [super dealloc];
}

@end
