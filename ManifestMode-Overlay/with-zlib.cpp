#include "stdafx.h"

#include <vector>

#include <zlib.h>

namespace ZipLogic
{
    void Test()
    {
        const std::string input = "Hello zlib via vcpkg (classic)!";
        // ���� ���۴� �������� �� �˳���
        uLong srcLen = (uLong)input.size();
        uLongf compCap = compressBound(srcLen);
        std::vector<unsigned char> comp(compCap);

        // ����
        uLongf compLen = compCap;
        int rc = compress(comp.data(), &compLen,
            reinterpret_cast<const Bytef*>(input.data()), srcLen);
        if (rc != Z_OK)
        {
            std::cerr << "compress failed: " << rc << "\n"; return;
        }
        comp.resize(compLen);

        // ����
        std::vector<unsigned char> decomp(input.size());
        uLongf deLen = (uLongf)decomp.size();
        rc = uncompress(decomp.data(), &deLen, comp.data(), compLen);
        if (rc != Z_OK)
        {
            std::cerr << "uncompress failed: " << rc << "\n"; return;
        }
        std::string out(reinterpret_cast<char*>(decomp.data()), deLen);

        std::cout << "Original   : " << input << "\n";
        std::cout << "Decompressed: " << out << "\n";
    }
}