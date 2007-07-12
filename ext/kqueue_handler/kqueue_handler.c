#include <ruby.h>
#include <sys/event.h>
#include <sys/time.h>
#include <errno.h>

static VALUE cKQueueHandler;
static VALUE cEventHandler;
static VALUE mGod;

static ID proc_exit;
static ID proc_fork;
static ID m_call;
static ID m_size;


static int kq;
static int num_events;

VALUE
kqh_event_mask(VALUE klass, VALUE sym)
{
  ID id = SYM2ID(sym);
  if (proc_exit == id) {
    return UINT2NUM(NOTE_EXIT);
  } else if (proc_fork == id) {
    return UINT2NUM(NOTE_FORK);
  } else {
    rb_raise(rb_eNotImpError, "Event `%s` not implemented", rb_id2name(id));
  }
  return Qnil;
}

  
VALUE
kqh_monitor_process(VALUE klass, VALUE pid, VALUE mask)
{
  struct kevent new_event;
  ID event;
  
  u_int fflags = NUM2UINT(mask);
  
  EV_SET(&new_event, FIX2UINT(pid), EVFILT_PROC,
         EV_ADD | EV_ENABLE, fflags, 0, 0);
  
  if (-1 == kevent(kq, &new_event, 1, NULL, 0, NULL)) {
    rb_raise(rb_eStandardError, strerror(errno));
  }
  
  num_events = FIX2INT(rb_funcall(rb_cv_get(cEventHandler, "@@actions"), m_size, 0));
    
  return Qnil;
}

VALUE
kqh_handle_events()
{
  int nevents, i;
  struct kevent *events = (struct kevent*)malloc(num_events * sizeof(struct kevent));
  
  if (NULL == events) {
    rb_raise(rb_eStandardError, strerror(errno));
  }
  
  nevents = kevent(kq, NULL, 0, events, num_events, NULL);
  
  if (-1 == nevents) {
    rb_raise(rb_eStandardError, strerror(errno));
  } else {
    for (i = 0; i < nevents; i++) {
      if (events[i].fflags & NOTE_EXIT) {
        rb_funcall(cEventHandler, m_call, 2, INT2NUM(events[i].ident), ID2SYM(proc_exit));
      } else if (events[i].fflags & NOTE_FORK) {
        rb_funcall(cEventHandler, m_call, 2, INT2NUM(events[i].ident), ID2SYM(proc_fork));
      }
    }
  }
  
  free(events);

  return INT2FIX(nevents);
}

void
Init_kqueue_handler()
{
  kq = kqueue();
  
  if (kq == -1) {
    rb_raise(rb_eStandardError, "kqueue initilization failed");
  }
  
  proc_exit = rb_intern("proc_exit");
  proc_fork = rb_intern("proc_fork");
  m_call = rb_intern("call");
  m_size = rb_intern("size");
  
  mGod = rb_const_get(rb_cObject, rb_intern("God"));
  cEventHandler = rb_const_get(mGod, rb_intern("EventHandler"));
  cKQueueHandler = rb_define_class_under(mGod, "KQueueHandler", rb_cObject);
  rb_define_singleton_method(cKQueueHandler, "monitor_process", kqh_monitor_process, 2);
  rb_define_singleton_method(cKQueueHandler, "handle_events", kqh_handle_events, 0);
  rb_define_singleton_method(cKQueueHandler, "event_mask", kqh_event_mask, 1);
}