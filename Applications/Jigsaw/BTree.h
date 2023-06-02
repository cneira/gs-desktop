#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>


@interface BTree : NSObject
{
    BTree *first, *second, *parent;
    id leaf;
    NSInteger tag;
}

+ fromLines:(NSEnumerator *)en;

- initWithLeaf:(id)theLeaf;
- initWithPairFirst:(BTree *)fp andSecond:(BTree *)sp;

- leaf;
- (BTree *)first;
- (BTree *)second;
- (NSInteger)tag;

- setFirst:(BTree *)theFirst;
- setSecond:(BTree *)theSecond;

- setParent:(BTree *)theParent;
- parent;

- (BTree *)findLeaf:(id)theLeaf;

- (NSMutableArray *)leaves;

- inorderWithTarget:(id)t sel:(SEL)what;
- inorderWithPointer:(void *)ptr sel:(SEL)what;
- inorderWithInt:(int)val sel:(SEL)what;

- (int)count;

- substituteLeaves:(NSMutableDictionary *)dict;

- (NSString *)toString;

- (void)deallocAll;

@end


