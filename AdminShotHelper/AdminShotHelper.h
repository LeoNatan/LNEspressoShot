//
//  AdminShotHelper.h
//  LNEspressoShot
//
//  Created by Léo Natan on 22/03/2026.
//

NS_ASSUME_NONNULL_BEGIN

@protocol AdminShotHelperProtocol <NSObject>

- (void)helpWithUser:(NSString*)user completionHandler:(void (^)(void))completionHandler;

@end

NS_ASSUME_NONNULL_END
