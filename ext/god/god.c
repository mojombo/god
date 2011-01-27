#include <god.h>

VALUE mGod;

void Init_god()
{
  mGod = rb_define_module("God");

  #if defined(__FreeBSD__) || defined(__APPLE__) || defined(__OpenBSD__) || defined(__NetBSD__)
    Init_kqueue_handler();
  #endif

  #ifdef __linux__
    Init_netlink_handler();
  #endif
}
