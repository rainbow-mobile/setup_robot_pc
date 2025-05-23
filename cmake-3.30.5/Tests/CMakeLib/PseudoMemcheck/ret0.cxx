#include <string>
#include <vector>

#include "cmsys/Encoding.hxx"

#include <cmSystemTools.h>

// clang-format off
#define RETVAL 0
#define CMAKE_COMMAND "/home/rainbow/setup_robot_pc/cmake-3.30.5/Bootstrap.cmk/cmake"
// clang-format on

int main(int ac, char** av)
{
  cmsys::Encoding::CommandLineArguments args =
    cmsys::Encoding::CommandLineArguments::Main(ac, av);
  int argc = args.argc();
  const char* const* argv = args.argv();

  std::string exename = argv[0];
  std::string logarg;
  bool nextarg = false;
  // execute the part after the last argument?
  // the logfile path gets passed as environment variable PSEUDO_LOGFILE
  bool exec = false;

  if (exename.find("valgrind") != std::string::npos) {
    logarg = "--log-file=";
  } else if (exename.find("purify") != std::string::npos) {
#ifdef _WIN32
    logarg = "/SAVETEXTDATA=";
#else
    logarg = "-log-file=";
#endif
  } else if (exename.find("BC") != std::string::npos) {
    nextarg = true;
    logarg = "/X";
  } else if (exename.find("cuda-memcheck") != std::string::npos) {
    nextarg = true;
    exec = true;
    logarg = "--log-file";
  }

  if (!logarg.empty()) {
    std::string logfile;
    for (int i = 1; i < argc; i++) {
      std::string arg = argv[i];
      if (arg.find(logarg) == 0) {
        if (nextarg) {
          if (i == argc - 1) {
            return 1; // invalid command line
          }
          logfile = argv[i + 1];
        } else {
          logfile = arg.substr(logarg.length());
        }
        // keep searching, it may be overridden later to provoke an error
      }
    }

    // find the last argument position
    int lastarg_pos = 1;
    for (int i = 1; i < argc; ++i) {
      std::string arg = argv[i];
      if (arg.find("--") == 0) {
        lastarg_pos = i;
      }
    }

    if (!logfile.empty()) {
      cmSystemTools::Touch(logfile, true);
      // execute everything after the last argument with additional environment
      int callarg_pos = lastarg_pos + (nextarg ? 2 : 1);
      if (exec && callarg_pos < argc) {
        std::vector<std::string> callargs{ CMAKE_COMMAND, "-E", "env",
                                           "PSEUDO_LOGFILE=" + logfile };
        callargs.insert(callargs.end(), &argv[callarg_pos], &argv[argc]);
        cmSystemTools::RunSingleCommand(callargs);
      }
    }
  }

  return RETVAL;
}
