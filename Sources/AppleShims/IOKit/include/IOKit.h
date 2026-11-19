#ifndef CROSSSWIFT_IOKIT_H
#define CROSSSWIFT_IOKIT_H
#include <stdbool.h>
#include <stdint.h>
typedef uint32_t mach_port_t;
typedef uint32_t io_object_t;
typedef uint32_t io_connect_t;
typedef uint32_t io_service_t;
typedef uint32_t io_registry_entry_t;
typedef uint32_t io_iterator_t;
typedef int32_t kern_return_t;
static const mach_port_t kIOMainPortDefault = 0;
static const mach_port_t mach_task_self_ = 0;
static const io_object_t IO_OBJECT_NULL = 0;
static const kern_return_t KERN_SUCCESS = 0;
static inline void *IOServiceMatching(const char *name) { (void)name; return (void *)0; }
static inline io_service_t IOServiceGetMatchingService(mach_port_t mainPort, void *matching) { (void)mainPort; (void)matching; return IO_OBJECT_NULL; }
static inline kern_return_t IOServiceOpen(io_service_t service, mach_port_t owningTask, uint32_t type, io_connect_t *connect) {
  (void)service; (void)owningTask; (void)type;
  if (connect) *connect = IO_OBJECT_NULL;
  return -1;
}
static inline kern_return_t IOServiceClose(io_connect_t connect) { (void)connect; return KERN_SUCCESS; }
static inline kern_return_t IOObjectRelease(io_object_t object) { (void)object; return KERN_SUCCESS; }
#endif
