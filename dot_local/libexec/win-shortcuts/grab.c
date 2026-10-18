#define _GNU_SOURCE
#include <SDL3/SDL.h>
#include <dlfcn.h>
#include <errno.h>
#include <poll.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/un.h>
#include <time.h>
#include <unistd.h>

/* Process-scoped policy. All SDL operations stay on the SDL event thread. */
static bool remote_mode;
static bool initialized;
static int listener = -1;
static SDL_WindowID last_window;
static ino_t endpoint_inode;
static dev_t endpoint_device;
static char socket_path[sizeof(((struct sockaddr_un *)0)->sun_path)];

static bool set_grab(SDL_Window *window, bool grabbed)
{
    bool (*real_set)(SDL_Window *, bool) = dlsym(RTLD_NEXT, "SDL_SetWindowKeyboardGrab");
    return real_set ? real_set(window, grabbed) : false;
}

static bool owns_endpoint(void)
{
    struct stat st;
    return lstat(socket_path, &st) == 0 && S_ISSOCK(st.st_mode) &&
           st.st_uid == getuid() && st.st_ino == endpoint_inode &&
           st.st_dev == endpoint_device;
}

static void cleanup(void)
{
    if (listener >= 0) {
        close(listener);
        listener = -1;
        if (owns_endpoint())
            unlink(socket_path);
    }
}

static void lose_control(void)
{
    remote_mode = false;
    SDL_Window *window = SDL_GetWindowFromID(last_window);
    if (window)
        set_grab(window, false);
    cleanup();
    fprintf(stderr, "win-shortcuts: control lost; released keyboard\n");
}

static void initialize(void)
{
    if (initialized)
        return;
    initialized = true;
    const char *directory = getenv("WIN_SHORTCUTS_DIR");
    struct stat st;
    if (!directory || (mkdir(directory, 0700) < 0 && errno != EEXIST) ||
        lstat(directory, &st) < 0 || !S_ISDIR(st.st_mode) ||
        st.st_uid != getuid() || (st.st_mode & 0777) != 0700)
        goto failed;
    int length = snprintf(socket_path, sizeof(socket_path), "%s/%ld.sock",
                          directory, (long)getpid());
    if (length < 0 || (size_t)length >= sizeof(socket_path))
        goto failed;
    int fd = socket(AF_UNIX, SOCK_SEQPACKET | SOCK_NONBLOCK | SOCK_CLOEXEC, 0);
    if (fd < 0)
        goto failed;
    struct sockaddr_un address = { .sun_family = AF_UNIX };
    memcpy(address.sun_path, socket_path, (size_t)length + 1);
    /* Never unlink a pre-existing endpoint, even if a stale PID is reused. */
    if (bind(fd, (struct sockaddr *)&address, sizeof(address)) < 0) {
        close(fd);
        goto failed;
    }
    if (chmod(socket_path, 0600) < 0 || listen(fd, 8) < 0 || lstat(socket_path, &st) < 0) {
        close(fd);
        unlink(socket_path);
        goto failed;
    }
    endpoint_inode = st.st_ino;
    endpoint_device = st.st_dev;
    listener = fd;
    atexit(cleanup);
    return;
failed:
    fprintf(stderr, "win-shortcuts: control unavailable; keeping shortcuts local\n");
}

static void service_control(void)
{
    initialize();
    if (listener < 0)
        return;
    if (!owns_endpoint()) {
        lose_control();
        return;
    }
    for (int count = 0; count < 8; count++) {
        int peer = accept4(listener, NULL, NULL, SOCK_CLOEXEC | SOCK_NONBLOCK);
        if (peer < 0) {
            if (errno != EAGAIN && errno != EWOULDBLOCK && errno != EINTR)
                lose_control();
            break;
        }
        struct ucred credentials;
        socklen_t size = sizeof(credentials);
        struct pollfd pending = { .fd = peer, .events = POLLIN };
        char command[32];
        const char *error = NULL;
        if (getsockopt(peer, SOL_SOCKET, SO_PEERCRED, &credentials, &size) < 0 ||
            credentials.uid != getuid() || poll(&pending, 1, 25) <= 0) {
            close(peer);
            continue;
        }
        ssize_t length = recv(peer, command, sizeof(command) - 1,
                              MSG_TRUNC | MSG_DONTWAIT);
        if (length <= 0 || (size_t)length >= sizeof(command)) {
            close(peer);
            continue;
        }
        command[length] = '\0';
        SDL_Window *window = SDL_GetKeyboardFocus();
        if (!window)
            window = SDL_GetWindowFromID(last_window);
        if (strcmp(command, "status") != 0) {
            bool desired = remote_mode;
            if (strcmp(command, "toggle") == 0)
                desired = !remote_mode;
            else if (strcmp(command, "local") == 0)
                desired = false;
            else if (strcmp(command, "remote") == 0)
                desired = true;
            else
                error = "error command";
            if (!error && desired && !SDL_GetKeyboardFocus())
                error = "error unfocused";
            if (!error) {
                if (window && set_grab(window, desired)) {
                    remote_mode = desired;
                    last_window = SDL_GetWindowID(window);
                } else {
                    remote_mode = false;
                    if (window)
                        set_grab(window, false);
                    error = "error grab";
                }
            }
        }
        char reply[64];
        if (error)
            snprintf(reply, sizeof(reply), "%s", error);
        else
            snprintf(reply, sizeof(reply), "%s %d", remote_mode ? "remote" : "local",
                     window ? (int)SDL_GetWindowKeyboardGrab(window) : 0);
        send(peer, reply, strlen(reply), MSG_NOSIGNAL);
        close(peer);
    }
}

bool SDL_SetWindowKeyboardGrab(SDL_Window *window, bool grabbed)
{
    (void)grabbed;
    initialize();
    if (window)
        last_window = SDL_GetWindowID(window);
    /* SDL/FreeRDP mouse-entry requests cannot change the user's chosen mode. */
    return set_grab(window, remote_mode);
}

bool SDL_PollEvent(SDL_Event *event)
{
    bool (*real_poll)(SDL_Event *) = dlsym(RTLD_NEXT, "SDL_PollEvent");
    service_control();
    return real_poll ? real_poll(event) : false;
}

void SDL_DestroyWindow(SDL_Window *window)
{
    void (*real_destroy)(SDL_Window *) = dlsym(RTLD_NEXT, "SDL_DestroyWindow");
    if (window && SDL_GetWindowID(window) == last_window)
        last_window = 0;
    if (real_destroy)
        real_destroy(window);
}

static long long monotonic_ms(void)
{
    struct timespec now;
    clock_gettime(CLOCK_MONOTONIC, &now);
    return (long long)now.tv_sec * 1000 + now.tv_nsec / 1000000;
}

bool SDL_WaitEventTimeout(SDL_Event *event, Sint32 timeout)
{
    bool (*real_wait)(SDL_Event *, Sint32) = dlsym(RTLD_NEXT, "SDL_WaitEventTimeout");
    if (!real_wait)
        return false;
    long long deadline = monotonic_ms() + timeout;
    for (;;) {
        service_control();
        long long remaining = deadline - monotonic_ms();
        Sint32 slice = timeout < 0 ? 50 : (Sint32)(remaining > 50 ? 50 :
                                                  remaining > 0 ? remaining : 0);
        bool ready = real_wait(event, slice);
        service_control();
        if (ready || (timeout >= 0 && monotonic_ms() >= deadline))
            return ready;
    }
}

bool SDL_WaitEvent(SDL_Event *event)
{
    return SDL_WaitEventTimeout(event, -1);
}
