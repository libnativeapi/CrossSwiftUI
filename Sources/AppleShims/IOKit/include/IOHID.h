#ifndef CROSSSWIFT_IOHID_H
#define CROSSSWIFT_IOHID_H
#include "IOKit.h"
typedef void *IOHIDEventSystemClientRef;
typedef void *IOHIDServiceClientRef;
typedef uint32_t IOHIDRequestType;
static const IOHIDRequestType kIOHIDRequestTypeListenEvent = 1;
static const int32_t kIOHIDAccessTypeGranted = 0;
static const uint32_t kIOHIDParamConnectType = 1;
static const int32_t kIOHIDCapsLockState = 1;
static inline int32_t IOHIDCheckAccess(IOHIDRequestType req) { (void)req; return kIOHIDAccessTypeGranted; }
static inline int IOHIDRequestAccess(IOHIDRequestType req) { (void)req; return 1; }
static inline kern_return_t IOHIDGetModifierLockState(io_connect_t handle, int32_t selector, bool *state) {
  (void)handle; (void)selector;
  if (state) *state = false;
  return -1;
}
static inline kern_return_t IOHIDSetModifierLockState(io_connect_t handle, int32_t selector, bool state) {
  (void)handle; (void)selector; (void)state;
  return -1;
}
#endif
