#import "FlashRuntimeExtensions.h"

void NativeExtensionTemplateContextInitializer(void* extData, const uint8_t* ctxType, FREContext ctx, uint32_t* numFunctionsToTest, const FRENamedFunction** functionsToSet);
void NativeExtensionTemplateContextFinalizer(FREContext ctx);
void NativeExtensionTemplateExtensionInitializer(void** extDataToSet, FREContextInitializer* ctxInitializerToSet, FREContextFinalizer* ctxFinalizerToSet);
void NativeExtensionTemplateExtensionFinalizer(void *extData);
