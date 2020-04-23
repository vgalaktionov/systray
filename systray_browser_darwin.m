#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#include "systray.h"

@interface SystrayApplication: NSApplication

@end
  
@implementation SystrayApplication
  - (void) sendEvent:(NSEvent *)event {
    if ([event type] == NSKeyDown) {
        if (([event modifierFlags] & NSDeviceIndependentModifierFlagsMask) == NSCommandKeyMask) {
            if ([[event charactersIgnoringModifiers] isEqualToString:@"x"]) {
                if ([self sendAction:@selector(cut:) to:nil from:self])
                    return;
            }
            else if ([[event charactersIgnoringModifiers] isEqualToString:@"c"]) {
                if ([self sendAction:@selector(copy:) to:nil from:self])
                    return;
            }
            else if ([[event charactersIgnoringModifiers] isEqualToString:@"v"]) {
                if ([self sendAction:@selector(paste:) to:nil from:self])
                    return;
            }
            else if ([[event charactersIgnoringModifiers] isEqualToString:@"z"]) {
                if ([self sendAction:@selector(undo:) to:nil from:self])
                    return;
            }
            else if ([[event charactersIgnoringModifiers] isEqualToString:@"a"]) {
                if ([self sendAction:@selector(selectAll:) to:nil from:self])
                    return;
            }
        }
        else if (([event modifierFlags] & NSDeviceIndependentModifierFlagsMask) == (NSCommandKeyMask | NSShiftKeyMask)) {
            if ([[event charactersIgnoringModifiers] isEqualToString:@"Z"]) {
                if ([self sendAction:@selector(redo:) to:nil from:self])
                    return;
            }
        }
    }
    [super sendEvent:event];
}  
@end

NSWindowController *windowController = nil;
NSWindow *window = nil;
WKWebView *webView = nil;

void configureAppWindow(char* title, int width, int height)
{
  if (windowController != nil) {
    // already configured, ignore
    return;
  }

  SystrayApplication *app = [SystrayApplication sharedApplication];
  [app setActivationPolicy:NSApplicationActivationPolicyRegular];
  [app activateIgnoringOtherApps:YES];

  NSRect frame = NSMakeRect(0, 0, width, height);
  int mask = NSWindowStyleMaskTitled | NSWindowStyleMaskResizable | NSWindowStyleMaskClosable;
  window = [[NSWindow alloc] initWithContentRect:frame
                              styleMask:mask
                              backing:NSBackingStoreBuffered
                              defer:NO];
  [window setTitle:[[NSString alloc] initWithUTF8String:title]];
  [window center];

  NSView *contentView = [window contentView];
  webView = [[WKWebView alloc] initWithFrame:[contentView bounds]];
  [webView setTranslatesAutoresizingMaskIntoConstraints:NO];
  [contentView addSubview:webView];
  [contentView addConstraint:
    [NSLayoutConstraint constraintWithItem:webView
        attribute:NSLayoutAttributeWidth
        relatedBy:NSLayoutRelationEqual
        toItem:contentView
        attribute:NSLayoutAttributeWidth
        multiplier:1
        constant:0]];
  [contentView addConstraint:
    [NSLayoutConstraint constraintWithItem:webView
        attribute:NSLayoutAttributeHeight
        relatedBy:NSLayoutRelationEqual
        toItem:contentView
        attribute:NSLayoutAttributeHeight
        multiplier:1
        constant:0]];

  // Window controller:
  windowController = [[NSWindowController alloc] initWithWindow:window];
  
  free(title);
}

void doShowAppWindow(char* url)
{
  if (windowController == nil) {
    // no app window to open
    return;
  }

  id nsURL = [NSURL URLWithString:[[NSString alloc] initWithUTF8String:url]];
  id req = [[NSURLRequest alloc] initWithURL: nsURL
                                 cachePolicy: NSURLRequestUseProtocolCachePolicy
                                 timeoutInterval: 5];
  [webView loadRequest:req];
  [windowController showWindow:window];
  free(url);
}

void showAppWindow(char* url)
{
  dispatch_async(dispatch_get_main_queue(), ^{
    doShowAppWindow(url);
  });
}
