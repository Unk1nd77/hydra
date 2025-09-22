#ifndef _SYS_LOCK_H
#define _SYS_LOCK_H

#ifdef __cplusplus
extern "C" {
#endif

typedef int _LOCK_T;
typedef int _LOCK_RECURSIVE_T;
typedef void *_lock_t;

#define __LOCK_INIT(class,lock) static int lock = 0;
#define __LOCK_INIT_RECURSIVE(class,lock) static int lock = 0;
#define __lock_init(lock) ((void) 0)
#define __lock_init_recursive(lock) ((void) 0)
#define __lock_close(lock) ((void) 0)
#define __lock_close_recursive(lock) ((void) 0)
#define __lock_acquire(lock) ((void) 0)
#define __lock_acquire_recursive(lock) ((void) 0)
#define __lock_try_acquire(lock) 0
#define __lock_try_acquire_recursive(lock) 0
#define __lock_release(lock) ((void) 0)
#define __lock_release_recursive(lock) ((void) 0)

// Additional lock functions used by wear_levelling
#define _lock_init(lock) __lock_init(lock)
#define _lock_close(lock) __lock_close(lock)
#define _lock_acquire(lock) __lock_acquire(lock)
#define _lock_release(lock) __lock_release(lock)

#ifdef __cplusplus
}
#endif

#endif /* _SYS_LOCK_H */
