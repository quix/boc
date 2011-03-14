#include "ruby.h"

static VALUE cBoc ;

static VALUE basic_object_method_sym ;

struct dispatch_args
{
    int argc ;
    VALUE* argv ;
    VALUE self ;
    ID method_id ;
} ;

static
VALUE
begin_section( VALUE data )
{
    struct dispatch_args* dargs = (struct dispatch_args*)data ;

    return rb_funcall_passing_block(
        dargs->self,
        dargs->method_id,
        dargs->argc,
        dargs->argv) ;
}

static
VALUE
ensure_section( VALUE unused )
{
    rb_ary_pop(
        rb_funcall(
            cBoc,
            rb_intern("stack"),
            0)) ;

    rb_thread_local_aset(
        rb_thread_current(),
        rb_intern("_boc_inside_enabled_method"),
        Qfalse) ;

    return Qnil ;
}

static VALUE
dispatch_common( VALUE method_sym, int argc, VALUE *argv, VALUE self )
{
    struct dispatch_args dargs ;

    dargs.argc = argc ;
    dargs.argv = argv ;
    dargs.self = self ;

    dargs.method_id = 
        rb_to_id(
            rb_str_plus(
                 rb_sym_to_s(method_sym),
                 rb_str_new2("__impl"))) ;

    rb_ary_push(
        rb_funcall(
            cBoc,
            rb_intern("stack"),
            0),
        rb_binding_new()) ;

    rb_thread_local_aset(
        rb_thread_current(),
        rb_intern("_boc_inside_enabled_method"),
        Qtrue) ;

    return rb_ensure(
        begin_section,
        (VALUE)&dargs,
        ensure_section,
        Qnil) ;
}

static
VALUE
dispatch_normal( int argc, VALUE *argv, VALUE self )
{
    return dispatch_common(
        rb_funcall(
            self,
            rb_intern("__method__"),
            0),
        argc,
        argv,
        self) ;
}

static
VALUE
dispatch_basic_object(int argc, VALUE *argv, VALUE self)
{
    return dispatch_common(
        basic_object_method_sym,
        argc,
        argv,
        self) ;
}

static
VALUE
enable_ext( VALUE self, VALUE klass, VALUE method_sym )
{
    rb_define_method(
        klass,
        RSTRING_PTR(rb_sym_to_s(method_sym)),
        dispatch_normal,
        -1) ;

    return Qnil ;
}

static
VALUE
enable_basic_object_ext( VALUE self, VALUE klass, VALUE method_sym )
{
    basic_object_method_sym = method_sym ;
        
    rb_define_method(
        klass,
        RSTRING_PTR(rb_sym_to_s(method_sym)),
        dispatch_basic_object,
        -1) ;

    return Qnil ;
}

void
Init_boc()
{
    cBoc = rb_define_module("Boc") ;

    rb_define_singleton_method(
        cBoc,
        "enable_ext",
        enable_ext,
        2) ;

    rb_define_singleton_method(
        cBoc,
        "enable_basic_object_ext",
        enable_basic_object_ext,
        2) ;
}
