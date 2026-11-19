#include "HIToolbox.h"
#include <string.h>

struct OpaqueEventRef {
  EventHotKeyID hotKeyID;
  uint32_t kind;
};

typedef struct {
  EventHandlerUPP handler;
  void *userData;
} RegisteredHandler;

static int g_dispatcher_sentinel = 0;
static RegisteredHandler g_handlers[16];
static int g_handler_count = 0;
static CrossSwiftRegisterHotKeyFn g_register_fn = NULL;
static CrossSwiftUnregisterHotKeyFn g_unregister_fn = NULL;

EventTargetRef GetEventDispatcherTarget(void) {
  return (EventTargetRef)&g_dispatcher_sentinel;
}

OSStatus InstallEventHandler(
  EventTargetRef inTarget,
  EventHandlerUPP inHandler,
  intptr_t inNumTypes,
  const EventTypeSpec *inList,
  void *inUserData,
  EventHandlerRef *outRef
) {
  (void)inTarget;
  (void)inNumTypes;
  (void)inList;
  if (!inHandler || g_handler_count >= 16) {
    return eventNotHandledErr;
  }
  int index = g_handler_count++;
  g_handlers[index].handler = inHandler;
  g_handlers[index].userData = inUserData;
  if (outRef) {
    *outRef = (EventHandlerRef)&g_handlers[index];
  }
  return noErr;
}

OSStatus RegisterEventHotKey(
  uint32_t inHotKeyCode,
  uint32_t inHotKeyModifiers,
  EventHotKeyID inHotKeyID,
  EventTargetRef inTarget,
  uint32_t inOptions,
  EventHotKeyRef *outRef
) {
  (void)inTarget;
  (void)inOptions;
  if (!g_register_fn) {
    return eventNotHandledErr;
  }
  void *handle = NULL;
  OSStatus status = g_register_fn(inHotKeyCode, inHotKeyModifiers, inHotKeyID, &handle);
  if (outRef) {
    *outRef = (EventHotKeyRef)handle;
  }
  return status;
}

OSStatus UnregisterEventHotKey(EventHotKeyRef inHotKey) {
  if (!g_unregister_fn || !inHotKey) {
    return noErr;
  }
  return g_unregister_fn((void *)inHotKey);
}

OSStatus GetEventParameter(
  EventRef inEvent,
  uint32_t inName,
  uint32_t inDesiredType,
  uint32_t *outActualType,
  intptr_t inBufferSize,
  intptr_t *outActualSize,
  void *outData
) {
  if (!inEvent || !outData) {
    return eventNotHandledErr;
  }
  if (inName == kEventParamDirectObject && inDesiredType == typeEventHotKeyID) {
    if (inBufferSize < (intptr_t)sizeof(EventHotKeyID)) {
      return eventNotHandledErr;
    }
    memcpy(outData, &inEvent->hotKeyID, sizeof(EventHotKeyID));
    if (outActualType) {
      *outActualType = typeEventHotKeyID;
    }
    if (outActualSize) {
      *outActualSize = (intptr_t)sizeof(EventHotKeyID);
    }
    return noErr;
  }
  return eventNotHandledErr;
}

uint32_t GetEventKind(EventRef inEvent) {
  return inEvent ? inEvent->kind : 0;
}

void _crossswift_carbon_set_hotkey_hooks(
  CrossSwiftRegisterHotKeyFn registerFn,
  CrossSwiftUnregisterHotKeyFn unregisterFn
) {
  g_register_fn = registerFn;
  g_unregister_fn = unregisterFn;
}

void _crossswift_carbon_dispatch_hotkey(
  OSType signature,
  uint32_t id,
  uint32_t kind
) {
  struct OpaqueEventRef ev;
  ev.hotKeyID.signature = signature;
  ev.hotKeyID.id = id;
  ev.kind = kind;
  for (int i = 0; i < g_handler_count; ++i) {
    if (g_handlers[i].handler) {
      g_handlers[i].handler(NULL, &ev, g_handlers[i].userData);
    }
  }
}
