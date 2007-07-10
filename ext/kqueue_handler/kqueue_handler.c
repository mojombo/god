#include <ruby.h>
#include <sys/event.h>
#include <sys/time.h>
#include <errno.h>

VALUE cKQueueHandler;
VALUE cEventHandler;
VALUE mGod;

static ID proc_exit;
static ID call;
static int kq;
static int num_events;

VALUE
kqh_register_event(VALUE klass, VALUE pid, VALUE event)
{
  struct kevent new_event;
  VALUE rb_event;
  u_int fflags;
  
  if (proc_exit == SYM2ID(event)) {
    fflags = NOTE_EXIT;
  } else {
    rb_raise(rb_eNotImpError, "Event `%s` not implemented", rb_id2name(event));
  }
  
  EV_SET(&new_event, FIX2UINT(pid), EVFILT_PROC,
         EV_ADD | EV_ENABLE, fflags, 0, 0);
  
  if (-1 == kevent(kq, &new_event, 1, NULL, 0, NULL)) {
    rb_raise(rb_eStandardError, strerror(errno));
  }
  
  num_events++;
  return Qnil;
}

VALUE
kqh_handle_events()
{
  int nevents, i;
  struct kevent *events = (struct kevent*)malloc(num_events * sizeof(struct kevent));
  
  if (NULL == events)
    rb_raise(rb_eStandardError, strerror(errno));
  
  nevents = kevent(kq, NULL, 0, events, num_events, NULL);
  
  if (-1 == nevents) {
    rb_raise(rb_eStandardError, strerror(errno));
  } else {
    for (i = 0; i < nevents; i++) {
      if (events[i].fflags & NOTE_EXIT) {
        rb_funcall(cEventHandler, call, 1, INT2NUM(events[i].ident));
      }
    }
  }
  
  free(events);

  return INT2FIX(nevents);
}

void Init_kqueue_handler() {
  kq = kqueue();
  
  if (kq == -1)
    rb_raise(rb_eStandardError, "kqueue initilization failed");
  
  proc_exit = rb_intern("proc_exit");
  call = rb_intern("call");
  
  mGod = rb_const_get(rb_cObject, rb_intern("God"));
  cEventHandler = rb_const_get(mGod, rb_intern("EventHandler"));
  cKQueueHandler = rb_define_class_under(mGod, "KQueueHandler", rb_cObject);
  rb_define_singleton_method(cKQueueHandler, "register_event", kqh_register_event, 2);
  rb_define_singleton_method(cKQueueHandler, "handle_events", kqh_handle_events, 0);
}