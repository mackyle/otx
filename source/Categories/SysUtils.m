/*
    SysUtils.m

    This file is in the public domain.
*/

#import <Cocoa/Cocoa.h>
#import <Foundation/NSCharacterSet.h>

#import "SystemIncludes.h"  // for UTF8STRING()
#import "SysUtils.h"

@implementation NSObject(SysUtils)

//  searchForCommand:additionalPaths:
// ----------------------------------------------------------------------------

- (NSString *)searchForCommand: (NSString *)command additionalPaths: (NSArray *)additionalPaths
{
    NSString *commandPath = nil;

    if (![command isAbsolutePath]) {
        // Next, search the PATH enviornment variable for the script

        NSMutableArray *paths;
        const char *pathEnv = getenv("PATH");
        if (pathEnv) {
            NSString *pathStr = [NSString stringWithCString: pathEnv encoding: NSUTF8StringEncoding];
            paths = [NSMutableArray arrayWithArray: [pathStr componentsSeparatedByString: @":"]];
        } else {
            paths = [NSMutableArray array];
        }

        if (additionalPaths != nil)
            [paths addObjectsFromArray: additionalPaths];

        NSFileManager* fileManager = [[[NSFileManager alloc] init] autorelease];

        NSUInteger i, pathsCount = [paths count];
        for (i = 0; i < pathsCount; i++) {
            NSString *path = (NSString *)[paths objectAtIndex: i];
            NSString* absPath = [path stringByAppendingPathComponent: command];

            if ([fileManager fileExistsAtPath: absPath]) {
                commandPath = absPath;
                break;
            }
        }
    }

    return commandPath;
}

//  pathForXcodeTools
// ----------------------------------------------------------------------------

- (NSString *)pathForXcodeTools
{
    NSString *relToolBase =
        [NSString pathWithComponents: [NSArray arrayWithObjects: @"/", @"usr", @"bin", nil]];
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

    if (selectStatus == -1)
        return nil;

    NSData* selectData = [[selectPipe fileHandleForReading] availableData];
    NSString* absToolPath = [[[NSString alloc] initWithBytes: [selectData bytes]
                                                      length: [selectData length]
                                                    encoding: NSUTF8StringEncoding] autorelease];

    return [absToolPath stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

//  pathForTool:
// ----------------------------------------------------------------------------

- (NSString *)pathForTool: (NSString *)toolName
{
    NSString *xcodeToolPath = [self pathForXcodeTools];
    return [self searchForCommand: toolName
                  additionalPaths: xcodeToolPath
                                   ? [NSArray arrayWithObject: [self pathForXcodeTools]]
                                   : nil];
}

//  checkOtool:
// ----------------------------------------------------------------------------

- (BOOL)checkOtool: (NSString*)filePath
{
    NSString *otoolPath = [self pathForTool: @"otool"];
    if (!otoolPath)
        return NO;

    NSTask *otoolTask = [[[NSTask alloc] init] autorelease];
    NSPipe *silence = [NSPipe pipe];

    [otoolTask setLaunchPath: otoolPath];
    [otoolTask setStandardInput: [NSPipe pipe]];
    [otoolTask setStandardOutput: silence];
    [otoolTask setStandardError: silence];
    [otoolTask launch];
    [otoolTask waitUntilExit];

    return ([otoolTask terminationStatus] == 1);
}

@end
