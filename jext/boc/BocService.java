package boc ;

import org.jruby.Ruby ;
import org.jruby.RubyModule ;
import org.jruby.RubyBinding ;
import org.jruby.RubySymbol ;
import org.jruby.RubyClass ;
import org.jruby.anno.JRubyMethod ;
import org.jruby.exceptions.RaiseException ;
import org.jruby.runtime.Arity ;
import org.jruby.runtime.Block ;
import org.jruby.runtime.ThreadContext ;
import org.jruby.runtime.callback.Callback ;
import org.jruby.runtime.builtin.IRubyObject ;
import org.jruby.runtime.load.BasicLibraryService ;

public class BocService implements BasicLibraryService
{
    static RubyModule s_boc ;
    static RubyClass s_removed_error ;

    public boolean basicLoad( Ruby ruby )
    {
        s_boc = ruby.defineModule("Boc") ;

        s_boc.getSingletonClass().
            defineAnnotatedMethods(SingletonMethods.class) ;

        s_removed_error = ruby.defineClassUnder(
            "InformationRemovedError",
            ruby.getException(),
            ruby.getException().getAllocator(),
            s_boc) ;

        return true ;
    }

    public static class SingletonMethods
    {
        @JRubyMethod( name = "enable_ext", alias = {"enable_basic_object_ext"} )
        public static IRubyObject
        s_enable_ext( IRubyObject recv, IRubyObject klass, IRubyObject sym )
        {
            String method_name = ((RubySymbol)sym).toString() ;

            ((RubyModule)klass).defineMethod(
                method_name,
                new Dispatcher(method_name + "__impl")) ;

            return recv.getRuntime().getNil() ;
        }
    }

    public static class Dispatcher implements Callback
    {
        String m_impl ;

        public Dispatcher( String impl )
        {
            m_impl = impl ;
        }
        
        public IRubyObject
        execute( IRubyObject recv, IRubyObject[] args, Block block )
        {
            Ruby ruby = recv.getRuntime() ;
            ThreadContext context = ruby.getCurrentContext() ;
            IRubyObject stack = s_boc.callMethod(context, "stack") ;

            stack.callMethod(
                context,
                "push", 
                RubyBinding.newBinding(ruby, context.previousBinding())) ;

            try
            {
                return recv.callMethod(context, m_impl, args, block) ;
            }
            catch( java.lang.NullPointerException e )
            {
                throw new RaiseException(
                    ruby, s_removed_error, s_error_msg, true) ;
            }
            finally
            {
                stack.callMethod(context, "pop") ;
            }
        }

        public Arity getArity()
        {
            return Arity.OPTIONAL ;
        }
    }

    static String s_error_msg = "\n" +
    "\n" +
    "__________________________________________________________________\n" +
    "Boc (binding of caller) failed because JRuby removed the necessary\n" +
    "information. To prevent this from happening, pass the following\n" +
    "command-line flag to jruby:\n" +
    "\n" +
    "    -J-Djruby.astInspector.enabled=false\n" +
    "\n" +
    "Alternatively, place a do-nothing block somewhere in the caller:\n" +
    "\n" +
    "    p { }\n" +
    "    # ...your code...\n" +
    "\n" +
    "==================================================================\n" ;
}
