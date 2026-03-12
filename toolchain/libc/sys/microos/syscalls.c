#include <sys/stat.h>
#include <sys/types.h>
#include <sys/fcntl.h>
#include <sys/times.h>
#include <sys/errno.h>
#include <sys/time.h>
#include <stdio.h>
#include <errno.h>
#include <stdint.h>
#include <reent.h>

#include "config.h"

char** environ = NULL;

static void *heap_current = NULL;
extern char _end; 

extern struct _reent *_impure_ptr;

static int file_positions[MAX_FD] = {0};


void _exit(int status) {
    __asm__ volatile("int $0x30" : : "a"(SYS_EXIT_ID), "b"(status));
    while (1) { }
}

int _close(int fd) {
    if (fd <= 2) {
        // ignore close on stdin/stdout/stderr, but return success
        return 0;
    }
    __asm__ volatile("int $0x30" : : "a"(SYS_CLOSE_ID), "b"(fd));
    return 0;
}
int close(int fd) __attribute__((alias("_close")));

int _execve(char *name, char **argv, char **env) {
    errno = ENOSYS;
    return -1;
}
int execve(char *name, char **argv, char **env) __attribute__((alias("_execve")));

int _fork(void) {
    errno = ENOSYS;
    return -1;
}
int fork(void) __attribute__((alias("_fork")));

int _fstat(int fd, struct stat *st) {
    if (fd == 0 || fd == 1 || fd == 2) {
        st->st_mode = S_IFCHR | 0644;
        st->st_size = 0;
        st->st_blksize = 512;
        st->st_blocks = 0;
        st->st_nlink = 1;
        st->st_uid = 0;
        st->st_gid = 0;
        st->st_dev = 0;
        st->st_ino = 0;
        st->st_atime = 0;
        st->st_mtime = 0;
        st->st_ctime = 0;
        return 0;
    }

    int size = -1;
    __asm__ volatile("int $0x30" : "=c"(size) : "a"(SYS_FILESIZE_ID), "b"(fd));
    
    st->st_mode = S_IFREG | 0644;
    st->st_size = size;
    st->st_blksize = 512;
    st->st_blocks = (size + 511) / 512;
    st->st_nlink = 1;
    st->st_uid = 0;
    st->st_gid = 0;
    st->st_dev = 0;
    st->st_ino = 0;
    st->st_atime = 0;
    st->st_mtime = 0;
    st->st_ctime = 0;
    
    return 0;
}
int fstat(int fd, struct stat *st) __attribute__((alias("_fstat")));

int _getpid(void) {
    return 1;
}
int getpid(void) __attribute__((alias("_getpid")));

int _isatty(int fd) {
    return (fd >= 0 && fd <= 2) ? 1 : 0;
}
int isatty(int fd) __attribute__((alias("_isatty")));

int _kill(int pid, int sig) {
    errno = ENOSYS;
    return -1;
}
int kill(int pid, int sig) __attribute__((alias("_kill")));

int _link(char *old, char *new) {
    errno = ENOSYS;
    return -1;
}
int link(char *old, char *new) __attribute__((alias("_link")));

int _lseek(int fd, int offset, int whence) {
    if (fd < 0 || fd >= MAX_FD) {
        errno = EBADF;
        return -1;
    }
    
    int size = -1;
    __asm__ volatile("int $0x30" : "=c"(size) : "a"(SYS_FILESIZE_ID), "b"(fd));
    
    switch (whence) {
        case SEEK_SET:
            file_positions[fd] = offset;
            break;
        case SEEK_CUR:
            file_positions[fd] += offset;
            break;
        case SEEK_END:
            file_positions[fd] = (size >= 0 ? size : 0) + offset;
            break;
        default:
            errno = EINVAL;
            return -1;
    }
    
    return file_positions[fd];
}
int lseek(int fd, int offset, int whence) __attribute__((alias("_lseek")));

int _open(const char *name, int flags, int mode) {
    int fd = -1;
        
    __asm__ volatile("int $0x30" : "=d"(fd) : "a"(SYS_OPEN_ID), "b"(name), "c"(flags));
    
    if (fd < 0 && (flags & O_CREAT)) {
        __asm__ volatile("int $0x30" : : "a"(SYS_TOUCH_ID), "b"(name));
        __asm__ volatile("int $0x30" : "=d"(fd) : "a"(SYS_OPEN_ID), "b"(name), "c"(flags));
    }
    
    if (fd < 0) {
        errno = ENOENT;
        return -1;
    }
    
    if (fd >= 0 && fd < MAX_FD) {
        file_positions[fd] = 0;
        
        if (flags & O_APPEND) {
            int size = -1;
            __asm__ volatile("int $0x30" : "=c"(size) : "a"(SYS_FILESIZE_ID), "b"(fd));
            file_positions[fd] = size;
        }
        
        if (flags & O_TRUNC) {
            __asm__ volatile("int $0x30" : : "a"(SYS_TRUNCATE_ID), "b"(fd), "c"(0));
        }
    }
    
    return fd;
}
int open(const char *name, int flags, ...) {
    return _open(name, flags, 0);
}

int _read(int fd, char *ptr, int len) {
    if (fd == 0) {
        int i;
        for (i = 0; i < len; i++) {
            char c = 0;
            while (c == 0) {
                __asm__ volatile("int $0x30" : "=b"(c) : "a"(SYS_ASYNC_GETC_ID));
            }

            ptr[i] = c;
            __asm__ volatile("int $0x30" : : "a"(SYS_WRITE_ID), "b"(1), "c"(&ptr[i]), "d"(1), "S"(0));

            if (c == '\n') {
                return i + 1;
            }
        }
        return len;
    }
    
    int offset = (fd < MAX_FD) ? file_positions[fd] : 0;
    // if offset + len exceeds file size, adjust len
    int size = -1;
    __asm__ volatile("int $0x30" : "=c"(size) : "a"(SYS_FILESIZE_ID), "b"(fd));
    if (size >= 0 && offset + len > size) {
        len = size - offset;
        if (len < 0) {
            return 0;
        };
    }
    __asm__ volatile("int $0x30" : : "a"(SYS_READ_ID), "b"(fd), "c"(ptr), "d"(len), "S"(offset));
    
    if (fd < MAX_FD) {
        file_positions[fd] += len;
    }
    
    return len;
}
int read(int fd, char *ptr, int len) __attribute__((alias("_read")));

caddr_t _sbrk(int incr) {
    void *prev_heap;
    
    if (heap_current == NULL) {
        heap_current = &_end;
    }
    
    prev_heap = heap_current;
    
    if (incr > 0) {
        void *new_end = (void*)((char*)heap_current + incr);
        char *addr = (char*)(((uintptr_t)heap_current + 0xFFF) & ~0xFFF);
        char *end_addr = (char*)(((uintptr_t)new_end + 0xFFF) & ~0xFFF);
        while (addr < end_addr) {
            __asm__ volatile("int $0x30" : : "a"(SYS_MMAP_ID), "b"(addr));
            addr += 4096;
        }
    }
    
    heap_current = (void*)((char*)heap_current + incr);
    
    return (caddr_t)prev_heap;
}
caddr_t sbrk(int incr) __attribute__((alias("_sbrk")));

int _stat(const char *file, struct stat *st) {
    int fd = _open(file, O_RDONLY, 0);
    if (fd < 0) {
        errno = ENOENT;
        return -1;
    }
    
    int ret = _fstat(fd, st);
    _close(fd);
    return ret;
}
int stat(const char *file, struct stat *st) __attribute__((alias("_stat")));

clock_t _times(struct tms *buf) {
    errno = ENOSYS;
    return (clock_t)-1;
}
clock_t times(struct tms *buf) __attribute__((alias("_times")));

int _unlink(char *name) {
    int fd = -1;
    __asm__ volatile("int $0x30" : "=d"(fd) : "a"(SYS_OPEN_ID), "b"(name), "c"(0));
    
    if (fd < 0) {
        errno = ENOENT;
        return -1;
    }
    
    __asm__ volatile("int $0x30" : : "a"(SYS_DELETE_ID), "b"(fd));
    return 0;
}
int unlink(char *name) __attribute__((alias("_unlink")));

int _wait(int *status) {
    errno = ECHILD;
    return -1;
}
int wait(int *status) __attribute__((alias("_wait")));

int _write(int fd, char *ptr, int len) {
    int offset = (MAX_FD) ? file_positions[fd] : 0;
    
    if (fd == 1 || fd == 2) {
        offset = 0;
    }
    
    __asm__ volatile("int $0x30" : : "a"(SYS_WRITE_ID), "b"(fd), "c"(ptr), "d"(len), "S"(offset));
    
    if (fd < MAX_FD && fd > 2) {
        file_positions[fd] += len;
    }
    
    return len;
}
int write(int fd, char *ptr, int len) __attribute__((alias("_write")));

_ssize_t _write_r(struct _reent *ptr, int fd, const void *buf, size_t cnt) {
    return (_ssize_t)_write(fd, (char*)buf, (int)cnt);
}

_ssize_t _read_r(struct _reent *ptr, int fd, void *buf, size_t cnt) {
    return (_ssize_t)_read(fd, (char*)buf, (int)cnt);
}

int _gettimeofday(struct timeval *tv, void *tz) {
    errno = ENOSYS;
    return -1;
}
int gettimeofday(struct timeval *tv, void *tz) __attribute__((alias("_gettimeofday")));

_fpos64_t __sseek64(struct _reent *ptr, void *cookie, _fpos64_t offset, int whence) {
    register FILE *fp = (FILE *)cookie;
    register _off_t ret;
    
    ret = _lseek_r(ptr, fp->_file, (_off_t)offset, whence);
    if (ret == -1L) {
        fp->_flags &= ~__SOFF;
    } else {
        fp->_flags |= __SOFF;
        fp->_offset = ret;
    }
    return (_fpos64_t)ret;
}

_ssize_t __swrite64(struct _reent *ptr, void *cookie, const char *buf, int n) {
    register FILE *fp = (FILE *)cookie;
    
    if (fp->_flags & __SAPP) {
        _lseek_r(ptr, fp->_file, (_off_t)0, SEEK_END);
    }
    fp->_flags &= ~__SOFF;
    
    return _write_r(ptr, fp->_file, buf, n);
}
