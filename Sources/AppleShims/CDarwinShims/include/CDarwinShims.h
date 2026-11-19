#pragma once
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#if !defined(_WIN32) && !defined(__linux__)
struct __attribute__((swift_name("timespec"))) _crossswift_timespec_s {
  intptr_t tv_sec;
  intptr_t tv_nsec;
};

struct __attribute__((swift_name("stat"))) _crossswift_stat_s {
  uint16_t st_mode;
  uint32_t st_uid;
  uint32_t st_gid;
  uint32_t st_flags;
  int64_t st_size;
  struct _crossswift_timespec_s st_mtimespec;
  struct _crossswift_timespec_s st_atimespec;
  struct _crossswift_timespec_s st_ctimespec;
  struct _crossswift_timespec_s st_birthtimespec;
};

int _crossswift_stat(const char *path, struct _crossswift_stat_s *buf)
    __attribute__((swift_name("stat(_:_:)")));

int _crossswift_lstat(const char *path, struct _crossswift_stat_s *buf)
    __attribute__((swift_name("lstat(_:_:)")));

int _crossswift_fstat(int fd, struct _crossswift_stat_s *buf)
    __attribute__((swift_name("fstat(_:_:)")));

int _crossswift_fstatat(int dirfd, const char *path, struct _crossswift_stat_s *buf, int flag)
    __attribute__((swift_name("fstatat(_:_:_:_:)")));
#endif

#ifdef __cplusplus
}
#endif
