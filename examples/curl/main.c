#include <curl/curl.h>
#include <stdio.h>
#include <string.h>

// Callback to discard response body
static size_t discard_callback(void *contents, size_t size, size_t nmemb, void *userp) {
    (void)contents;
    (void)userp;
    return size * nmemb;
}

int main(void) {
    CURL *curl;
    CURLcode res;

    printf("curl version: %s\n", curl_version());

    curl_global_init(CURL_GLOBAL_DEFAULT);
    curl = curl_easy_init();

    if (curl) {
        // Just demonstrate that curl initializes and can be configured
        curl_easy_setopt(curl, CURLOPT_URL, "https://example.com");
        curl_easy_setopt(curl, CURLOPT_NOBODY, 1L);  // HEAD request only
        curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, discard_callback);

        printf("Performing HEAD request to https://example.com...\n");
        res = curl_easy_perform(curl);

        if (res == CURLE_OK) {
            long response_code;
            curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &response_code);
            printf("Response code: %ld\n", response_code);
        } else {
            printf("curl_easy_perform() failed: %s\n", curl_easy_strerror(res));
        }

        curl_easy_cleanup(curl);
    }

    curl_global_cleanup();
    return 0;
}
