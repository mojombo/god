#include "ruby.h"

static VALUE mKernel;
void Init_execve();
VALUE method_execve(VALUE self, VALUE cmd, VALUE env);

void Init_execve() {
  mKernel = rb_const_get(rb_cObject, rb_intern("Kernel"));
  rb_define_method(mKernel, "execve", method_execve, 2);
}

VALUE method_execve(VALUE self, VALUE r_cmd, VALUE r_env) {
  char *shell = (char *)dln_find_exe("sh", 0);
  char *arg[] = { "sh", "-c", StringValuePtr(r_cmd), (char *)0 };
  
  struct RArray *env_array;
  env_array = RARRAY(r_env);
  char *env[env_array->len + 1];
  
  int i;
  for(i = 0; i < env_array->len; i++) {
    env[i] = StringValuePtr(env_array->ptr[i]);
  }
  
  env[env_array->len] = (char *)0;
  
  execve(shell, arg, env);
  return Qnil;
}