#ifndef __SIMPLE_H_INCLUDE__
#define __SIMPLE_H_INCLUDE__

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

extern const int64_t SIMPLE_VALUE;

int64_t simple_function();

#ifdef __cplusplus
}
#endif

static inline int64_t simple_static_function() { return 84; }

#endif
