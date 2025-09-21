#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class PhpResult;

/// Objective-C++ bridge to PHP runtime
@interface PhpBridge : NSObject

/// Initialize the PHP bridge
- (instancetype)init;

/// Execute inline PHP code
/// @param code PHP code to execute
/// @param stdinData Input data for STDIN
/// @param iniSettings PHP ini settings
/// @return Execution result
- (PhpResult*)executeInline:(NSString*)code 
                      stdinData:(nullable NSData*)stdinData 
                        ini:(nullable NSDictionary<NSString*, NSString*>*)iniSettings;

/// Execute a PHP script file
/// @param scriptPath Path to the PHP script
/// @param argv Command line arguments
/// @param stdinData Input data for STDIN
/// @param env Environment variables
/// @param iniSettings PHP ini settings
/// @return Execution result
- (PhpResult*)executeScript:(NSString*)scriptPath 
                       argv:(nullable NSArray<NSString*>*)argv 
                      stdinData:(nullable NSData*)stdinData 
                        env:(nullable NSDictionary<NSString*, NSString*>*)env 
                         ini:(nullable NSDictionary<NSString*, NSString*>*)iniSettings;

@end

/// Result of PHP execution
@interface PhpResult : NSObject

@property (nonatomic, readonly) int32_t exitCode;
@property (nonatomic, readonly) NSString* stdoutOutput;
@property (nonatomic, readonly) NSString* stderrOutput;

- (instancetype)initWithExitCode:(int32_t)exitCode 
                          stdout:(NSString*)stdoutOutput 
                          stderr:(NSString*)stderrOutput;

@end

NS_ASSUME_NONNULL_END