import sys
from functools import wraps

def catchdecorator (debug):
    def wrapper (func):
        @wraps (func)
        def wrappedfunc (*args, **kwargs):
            try:
                func (*args, **kwargs)
            except Exception as e:
                if debug:
                    raise e
                else:
                    print ('Internal error: {}'.format (str (e)), file=sys.stderr)
            except KeyboardInterrupt:
                print ('Interrupted', file=sys.stderr)

        return wrappedfunc
    return wrapper

