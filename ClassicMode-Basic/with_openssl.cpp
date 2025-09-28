#include "stdafx.h"

#include <openssl/sha.h>
#include <openssl/opensslv.h>

#if defined(OPENSSL_VERSION_MAJOR)
#define OPENSSL_VER_STRING OpenSSL_version(OPENSSL_VERSION)
#include <openssl/crypto.h>
#include <openssl/ssl.h>
#else
#define OPENSSL_VER_STRING SSLeay_version(SSLEAY_VERSION)
#endif



namespace OpenSSLLogic
{
    static std::string to_hex(const unsigned char* data, size_t len) 
    {
        static const char* hex = "0123456789abcdef";
        
        std::string s; 
        s.reserve(len * 2);
        
        for (size_t i = 0; i < len; ++i) 
        {
            unsigned char b = data[i];
            s.push_back(hex[b >> 4]);
            s.push_back(hex[b & 0x0F]);
        }

        return s;
    }

    void Test()
    {
        // OpenSSL SHA-256
        const std::string data = "abc";
        unsigned char digest[SHA256_DIGEST_LENGTH];
        SHA256(reinterpret_cast<const unsigned char*>(data.data()), data.size(), digest);
        std::cout << "[OpenSSL] SHA256('abc'): " << to_hex(digest, sizeof(digest)) << "\n";
        std::cout << "[OpenSSL] version      : " << OPENSSL_VER_STRING << "\n";
    }
}