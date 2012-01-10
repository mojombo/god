#ifdef __linux__ /* only build on linux */

#include <ruby.h>
#include <sys/types.h>
#include <unistd.h>
#include <sys/socket.h>
#include <linux/netlink.h>
#include <linux/connector.h>
#define _LINUX_TIME_H
#include <linux/cn_proc.h>
#include <errno.h>

static VALUE mGod;
static VALUE cNetlinkHandler;
static VALUE cEventHandler;

static ID proc_exit;
static ID proc_fork;
static ID m_call;
static ID m_watching_pid;

static int nl_sock;   /* socket for netlink connection  */


VALUE
nlh_handle_events()
{
  char buff[CONNECTOR_MAX_MSG_SIZE];
  struct nlmsghdr *hdr;
  struct proc_event *event;

  VALUE extra_data;

  fd_set fds;

  FD_ZERO(&fds);
  FD_SET(nl_sock, &fds);

  if (0 > rb_thread_select(nl_sock + 1, &fds, NULL, NULL, NULL)) {
    rb_raise(rb_eStandardError, "%s", strerror(errno));
  }

  /* If there were no events detected, return */
  if (! FD_ISSET(nl_sock, &fds)) {
    return INT2FIX(0);
  }

  /* if there are events, make calls */
  if (-1 == recv(nl_sock, buff, sizeof(buff), 0)) {
    rb_raise(rb_eStandardError, "%s", strerror(errno));
  }

  hdr = (struct nlmsghdr *)buff;

  if (NLMSG_ERROR == hdr->nlmsg_type) {
    rb_raise(rb_eStandardError, "%s", strerror(errno));
  } else if (NLMSG_DONE == hdr->nlmsg_type) {

    event = (struct proc_event *)((struct cn_msg *)NLMSG_DATA(hdr))->data;

    switch(event->what) {
      case PROC_EVENT_EXIT:
        if (Qnil == rb_funcall(cEventHandler, m_watching_pid, 1, INT2FIX(event->event_data.exit.process_pid))) {
          return INT2FIX(0);
        }

        extra_data = rb_hash_new();
        rb_hash_aset(extra_data, ID2SYM(rb_intern("pid")), INT2FIX(event->event_data.exit.process_pid));
        rb_hash_aset(extra_data, ID2SYM(rb_intern("exit_code")), INT2FIX(event->event_data.exit.exit_code));
        rb_hash_aset(extra_data, ID2SYM(rb_intern("exit_signal")), INT2FIX(event->event_data.exit.exit_signal));
        rb_hash_aset(extra_data, ID2SYM(rb_intern("thread_group_id")), INT2FIX(event->event_data.exit.process_tgid));

        rb_funcall(cEventHandler, m_call, 3, INT2FIX(event->event_data.exit.process_pid), ID2SYM(proc_exit), extra_data);
        return INT2FIX(1);

      case PROC_EVENT_FORK:
        if (Qnil == rb_funcall(cEventHandler, m_watching_pid, 1, INT2FIX(event->event_data.fork.parent_pid))) {
          return INT2FIX(0);
        }

        extra_data = rb_hash_new();
        rb_hash_aset(extra_data, ID2SYM(rb_intern("parent_pid")), INT2FIX(event->event_data.fork.parent_pid));
        rb_hash_aset(extra_data, ID2SYM(rb_intern("parent_thread_group_id")), INT2FIX(event->event_data.fork.parent_tgid));
        rb_hash_aset(extra_data, ID2SYM(rb_intern("child_pid")), INT2FIX(event->event_data.fork.child_pid));
        rb_hash_aset(extra_data, ID2SYM(rb_intern("child_thread_group_id")), INT2FIX(event->event_data.fork.child_tgid));

        rb_funcall(cEventHandler, m_call, 3, INT2FIX(event->event_data.fork.parent_pid), ID2SYM(proc_fork), extra_data);
        return INT2FIX(1);

      default:
        break;
    }
  }

  return Qnil;
}


#define NL_MESSAGE_SIZE (sizeof(struct nlmsghdr) + sizeof(struct cn_msg) + \
                         sizeof(int))

void
connect_to_netlink()
{
  struct sockaddr_nl sa_nl; /* netlink interface info */
  char buff[NL_MESSAGE_SIZE];
  struct nlmsghdr *hdr; /* for telling netlink what we want */
  struct cn_msg *msg;   /* the actual connector message */

  /* connect to netlink socket */
  nl_sock = socket(PF_NETLINK, SOCK_DGRAM, NETLINK_CONNECTOR);

  if (-1 == nl_sock) {
    rb_raise(rb_eStandardError, "%s", strerror(errno));
  }

  bzero(&sa_nl, sizeof(sa_nl));
  sa_nl.nl_family = AF_NETLINK;
  sa_nl.nl_groups = CN_IDX_PROC;
  sa_nl.nl_pid    = getpid();

  if (-1 == bind(nl_sock, (struct sockaddr *)&sa_nl, sizeof(sa_nl))) {
    rb_raise(rb_eStandardError, "%s", strerror(errno));
  }

  /* Fill header */
  hdr = (struct nlmsghdr *)buff;
  hdr->nlmsg_len = NL_MESSAGE_SIZE;
  hdr->nlmsg_type = NLMSG_DONE;
  hdr->nlmsg_flags = 0;
  hdr->nlmsg_seq = 0;
  hdr->nlmsg_pid = getpid();

  /* Fill message */
  msg = (struct cn_msg *)NLMSG_DATA(hdr);
  msg->id.idx = CN_IDX_PROC;  /* Connecting to process information */
  msg->id.val = CN_VAL_PROC;
  msg->seq = 0;
  msg->ack = 0;
  msg->flags = 0;
  msg->len = sizeof(int);
  *(int*)msg->data = PROC_CN_MCAST_LISTEN;

  if (-1 == send(nl_sock, hdr, hdr->nlmsg_len, 0)) {
    rb_raise(rb_eStandardError, "%s", strerror(errno));
  }
}

void
Init_netlink_handler_ext()
{
  proc_exit = rb_intern("proc_exit");
  proc_fork = rb_intern("proc_fork");
  m_call = rb_intern("call");
  m_watching_pid = rb_intern("watching_pid?");

  mGod = rb_const_get(rb_cObject, rb_intern("God"));
  cEventHandler = rb_const_get(mGod, rb_intern("EventHandler"));
  cNetlinkHandler = rb_define_class_under(mGod, "NetlinkHandler", rb_cObject);
  rb_define_singleton_method(cNetlinkHandler, "handle_events", nlh_handle_events, 0);

  connect_to_netlink();
}

#endif
