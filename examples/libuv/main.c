#include <stdio.h>
#include <stdlib.h>
#include <uv.h>

void timer_callback(uv_timer_t* handle) {
    int* count = (int*)handle->data;
    (*count)++;
    printf("Timer fired! Count: %d\n", *count);

    if (*count >= 3) {
        printf("Stopping timer after 3 fires\n");
        uv_timer_stop(handle);
    }
}

void idle_callback(uv_idle_t* handle) {
    static int idle_count = 0;
    idle_count++;

    if (idle_count >= 5) {
        printf("Idle callback ran %d times, stopping\n", idle_count);
        uv_idle_stop(handle);
    }
}

int main() {
    printf("libuv version: %s\n", uv_version_string());

    uv_loop_t* loop = uv_default_loop();

    // Timer example - fires every 500ms
    uv_timer_t timer;
    int timer_count = 0;
    uv_timer_init(loop, &timer);
    timer.data = &timer_count;
    uv_timer_start(&timer, timer_callback, 0, 500);

    // Idle example - runs when loop is idle
    uv_idle_t idle;
    uv_idle_init(loop, &idle);
    uv_idle_start(&idle, idle_callback);

    printf("Starting event loop...\n");
    uv_run(loop, UV_RUN_DEFAULT);
    printf("Event loop finished\n");

    uv_loop_close(loop);
    return 0;
}
