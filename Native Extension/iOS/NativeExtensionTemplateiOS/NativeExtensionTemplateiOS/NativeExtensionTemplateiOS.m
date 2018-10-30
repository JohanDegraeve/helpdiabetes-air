//
//  NativeExtensionTemplateiOS.m
//  NativeExtensionTemplateiOS
//
//  Created by Johan Degraeve on 24/05/2018.
//  Copyright © 2018 Johan Degraeve. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FlashRuntimeExtensions.h"
#import "NativeExtensionTemplateiOS.h"
#include "FPANEUtils.h"
#include "PlaySound.h"

static FREContext _context;

PlaySound * _soundPlayer;

FREObject traceNSLog( FREContext ctx, void* funcData, uint32_t argc, FREObject argv[] ) {
   NSLog(@"%@", FPANE_FREObjectToNSString(argv[0]));
    return NULL;
}

FREObject isPlayingSound (FREContext ctx, void* funcData, uint32_t argc, FREObject argv[0]) {
    return FPANE_BOOLToFREObject([_soundPlayer isPlayingSound]);
}

FREObject playSound (FREContext ctx, void* funcData, uint32_t argc, FREObject argv[0]) {
    //Get desired system volume
    //Play the sound
    [_soundPlayer playSound:[FPANE_FREObjectToNSString(argv[0]) mutableCopy] withVolume:101];
    return nil;
}

FREObject init( FREContext ctx, void* funcData, uint32_t argc, FREObject argv[] ) {
    NSLog(@"helpdiabetestrace ANE NativeExtensionTemplateiOS.m Initializing context");
    _soundPlayer =[PlaySound alloc];
    _context = ctx;
    return NULL;
}

void NativeExtensionTemplateExtensionInitializer( void** extDataToSet, FREContextInitializer* ctxInitializerToSet, FREContextFinalizer* ctxFinalizerToSet ) {
    extDataToSet = NULL;
    *ctxInitializerToSet = &NativeExtensionTemplateContextInitializer;
    *ctxFinalizerToSet = &NativeExtensionTemplateContextFinalizer;
    
}

void NativeExtensionTemplateContextInitializer(void* extData, const uint8_t* ctxType, FREContext ctx, uint32_t* numFunctionsToTest, const FRENamedFunction** functionsToSet) {
    
    *numFunctionsToTest = 4;
    
    FRENamedFunction * func = (FRENamedFunction *) malloc(sizeof(FRENamedFunction) * *numFunctionsToTest);
    
    func[0].name = (const uint8_t*) "traceNSLog";
    func[0].functionData = NULL;
    func[0].function = &traceNSLog;

    func[1].name = (const uint8_t*) "init";
    func[1].functionData = NULL;
    func[1].function = &init;

    func[2].name = (const uint8_t*) "playSound";
    func[2].functionData = NULL;
    func[2].function = &playSound;

    func[3].name = (const uint8_t*) "isPlayingSound";
    func[3].functionData = NULL;
    func[3].function = &isPlayingSound;

    *functionsToSet = func;
}

void NativeExtensionTemplateContextFinalizer( FREContext ctx )
{
    return;
}

void NativeExtensionTemplateExtensionFinalizer( FREContext ctx )
{
    return;
}

