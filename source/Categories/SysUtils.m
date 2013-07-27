/*
    SysUtils.m

    This file is in the public domain.
*/

#import <Cocoa/Cocoa.h>
#import <Foundation/NSCharacterSet.h>

#import "SystemIncludes.h"  // for UTF8STRING()
#import "SysUtils.h"

@implementation NSObject(SysUtils)

//  checkOtool:
// ----------------------------------------------------------------------------

- (BOOL)checkOtool: (NSString*)filePath
{
    NSString* otoolPath = [self searchForCommand:@"otool" additonalPaths:[NSArray arrayWithObject:[self pathForXcodeTools]]];
    NSTask* otoolTask = [[[NSTask alloc] init] autorelease];
    NSPipe* silence = [NSPipe pipe];

    [otoolTask setLaunchPath: otoolPath];
    [otoolTask setStandardInput: [NSPipe pipe]];
    [otoolTask setStandardOutput: silence];
    [otoolTask setStandardError: silence];
    [otoolTask launch];
    [otoolTask waitUntilExit];

    return ([otoolTask terminationStatus] == 1);
}

//  pathForTool:
// ----------------------------------------------------------------------------
- (NSString*)pathForTool: (NSString*)toolName
{
    return [self searchForCommand:toolName
                   additonalPaths:[NSArray arrayWithObject:[self pathForXcodeTools]]];
}

- (NSString*) searchForCommand: (NSString*)command additonalPaths:(NSArray*)additionalPaths
{
    NSString* commandPath = nil;
    
    if ( ![ command isAbsolutePath ] ) {
            // Next, search the PATH enviornment variable for the script
            const char* pathEnv = getenv("PATH");
            NSString* pathStr   = [ NSString stringWithCString: pathEnv encoding: NSUTF8StringEncoding ];
            NSMutableArray* paths = [ NSMutableArray arrayWithArray:[ pathStr componentsSeparatedByString: @":" ]];
        if (additionalPaths != nil) {
            [ paths addObjectsFromArray:additionalPaths];
        }
            NSFileManager* fileManager = [ [ NSFileManager alloc ] init ];
            
            for ( NSString* path in paths ) {
                NSString* absPath = [ path stringByAppendingPathComponent: command ];
                
                if ( [ fileManager fileExistsAtPath: absPath ] ) {
                    commandPath = absPath;
                    break;
                }
            }
    }
    
    return commandPath;
}

- (NSString*)pathForXcodeTools
{
    NSString* relToolBase = [NSString pathWithComponents:
        [NSArray arrayWithObjects: @"/", @"usr", @"bin", nil]];
    NSString* selectToolPath = [relToolBase stringByAppendingPathComponent: @"xcode-select"];
    NSTask* selectTask = [[[NSTask alloc] init] autorelease];
    NSPipe* selectPipe = [NSPipe pipe];
    NSArray* args = [NSArray arrayWithObject: @"--print-path"];

    [selectTask setLaunchPath: selectToolPath];
    [selectTask setArguments: args];
    [selectTask setStandardInput: [NSPipe pipe]];
    [selectTask setStandardOutput: selectPipe];
    [selectTask launch];
    [selectTask waitUntilExit];

    int selectStatus = [selectTask terminationStatus];

    if (selectStatus == -1) {
        return nil;
    }

    NSData* selectData = [[selectPipe fileHandleForReading] availableData];
    NSString* absToolPath = [[[NSString alloc] initWithBytes: [selectData bytes]
                                                      length: [selectData length]
                                                    encoding: NSUTF8StringEncoding] autorelease];

    return [absToolPath stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

@end
