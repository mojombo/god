#include <ruby.h>
#include <sys/event.h>
#include <sys/time.h>
#include <errno.h>

VALUE cKQueueHandler;
VALUE cEventHandler = Qnil;
VALUE mGod;

static int kq;
static int num_events;

VALUE
kqh_register_event(klass, pid, event)
  VALUE klass;
  VALUE pid;
  VALUE event;
{
  struct kevent new_event;
  VALUE rb_event;
  
  // if (rb_intern("proc_exit") != event)
  //   rb_raise(rb_eNotImpError, "Event `%s` not implemented", rb_id2name(event));
  
  EV_SET(&new_event, FIX2UINT(pid), EVFILT_PROC,
         EV_ADD | EV_ENABLE, NOTE_EXIT, 0, 0);
  
  if (-1 == kevent(kq, &new_event, 1, NULL, 0, NULL))
    rb_raise(rb_eStandardError, strerror(errno));
  
  num_events++;
  return Qnil;
}

VALUE
kqh_handle_events()
{
  // TODO: Allocate the full list of events based on num_events
  struct kevent ev;
  int events_left = 0;
  
  // Push off const lookup till we run so we can require early
  if (Qnil == cEventHandler)
    cEventHandler = rb_const_get(mGod, rb_intern("EventHandler"));
  
  do {
    // TODO: Grab all events at once rather than one at a time
    events_left = kevent(kq, NULL, 0, &ev, 1, NULL);
    if (-1 == events_left)
      rb_raise(rb_eStandardError, strerror(errno));
    else if (0 < events_left) {
      if (ev.fflags & NOTE_EXIT)
        rb_funcall(cEventHandler, rb_intern("call"), 1, INT2NUM(ev.ident));
    }
  } while(0 < events_left);
  

  return Qnil;
}

void Init_kqueue_handler() {
  kq = kqueue();
  
  if (kq == -1)
    rb_raise(rb_eStandardError, "kqueue initilization failed");
  
  mGod = rb_const_get(rb_cObject, rb_intern("God"));
  cKQueueHandler = rb_define_class_under(mGod, "KQueueHandler", rb_cObject);
  rb_define_singleton_method(cKQueueHandler, "register_event", kqh_register_event, 2);
  rb_define_singleton_method(cKQueueHandler, "handle_events", kqh_handle_events, 0);
}