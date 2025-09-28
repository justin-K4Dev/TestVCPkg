#include "stdafx.h"

#include <boost/filesystem.hpp>

namespace BoostLogic
{
    void Test()
    {
        namespace fs = boost::filesystem;
        std::cout << "[Boost] version: " << BOOST_LIB_VERSION << "\n";

        fs::path here = fs::current_path();
        std::cout << "List: " << here.string() << "\n";

        for (const auto& e : fs::directory_iterator(here)) {
            bool isdir = fs::is_directory(e.path());
            std::cout << (isdir ? "[D] " : "[F] ")
                << e.path().filename().string() << "\n";
        }
    }
}