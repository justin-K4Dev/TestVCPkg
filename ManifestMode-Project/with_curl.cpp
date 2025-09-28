#include "stdafx.h"

#include <vector>

#include <curl/curl.h>


namespace CurlLogic
{
    // 수신 콜백
    static size_t writeToVec(void* contents, size_t size, size_t nmemb, void* userp) 
    {
        size_t n = size * nmemb;
        auto* out = static_cast<std::vector<unsigned char>*>(userp);
        out->insert(out->end(), (unsigned char*)contents, (unsigned char*)contents + n);
        return n;
    }

    void Test()
    {
        curl_global_init(CURL_GLOBAL_DEFAULT);

        CURL* h = curl_easy_init();
        if (!h) 
        { 
            std::cerr << "curl_easy_init failed\n";
            return;
        }

        const auto* vi = curl_version_info(CURLVERSION_NOW);
        std::cout << "[cURL] version: " << vi->version << "\n";
        std::cout << "[cURL] SSL    : " << (vi->ssl_version ? vi->ssl_version : "(none)") << "\n";

        std::vector<unsigned char> body;
        curl_easy_setopt(h, CURLOPT_URL, "https://example.com/");
        curl_easy_setopt(h, CURLOPT_FOLLOWLOCATION, 1L);
        curl_easy_setopt(h, CURLOPT_WRITEFUNCTION, &writeToVec);
        curl_easy_setopt(h, CURLOPT_WRITEDATA, &body);

        CURLcode rc = curl_easy_perform(h);
        if (rc != CURLE_OK) 
        {
            std::cerr << "curl: " << curl_easy_strerror(rc) << "\n";
        }
        else 
        {
            long code = 0;
            curl_easy_getinfo(h, CURLINFO_RESPONSE_CODE, &code);
            std::cout << "[cURL] HTTP status: " << code << "\n";
            std::cout << "[cURL] bytes      : " << body.size() << "\n";
        }
        curl_easy_cleanup(h);
        curl_global_cleanup();
    }
}