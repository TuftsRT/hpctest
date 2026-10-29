// Exercise several compiled Boost libraries: filesystem, regex,
// program_options and date_time.
#include <boost/filesystem.hpp>
#include <boost/regex.hpp>
#include <boost/program_options.hpp>
#include <boost/date_time/gregorian/gregorian.hpp>
#include <iostream>

namespace fs = boost::filesystem;
namespace po = boost::program_options;

int main(int argc, char **argv)
{
    po::options_description desc("options");
    desc.add_options()("count", po::value<int>()->default_value(3), "count");
    po::variables_map vm;
    po::store(po::parse_command_line(argc, argv, desc), vm);
    po::notify(vm);
    std::cout << "program_options count = " << vm["count"].as<int>() << std::endl;

    fs::path p = fs::path("a") / "b" / "file.txt";
    std::cout << "filesystem extension = " << p.extension().string() << std::endl;
    std::cout << "filesystem cwd exists = " << fs::exists(fs::current_path()) << std::endl;

    boost::regex re("(\\d{4})-(\\d{2})-(\\d{2})");
    boost::smatch m;
    std::string s = "released on 2025-04-10";
    if (boost::regex_search(s, m, re))
        std::cout << "regex year = " << m[1] << std::endl;

    boost::gregorian::date d(2025, 4, 10);
    std::cout << "date_time day of week = " << d.day_of_week() << std::endl;
    return 0;
}
