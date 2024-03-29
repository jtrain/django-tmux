if !(has('python') || has('python3'))
    finish
endif
if has('python3')
    command! -nargs=1 Python2or3 python3 <args>
else
    command! -nargs=1 Python2or3 python <args>
endif

if !exists("g:tmux_djangotest_manage_py")
    let g:tmux_djangotest_manage_py="python manage.py"
endif

if !exists("g:tmux_djangotest_test_cmd")
    let g:tmux_djangotest_test_cmd="test"
endif

if !exists("g:tmux_djangotest_test_file_name_prefix")
    let g:tmux_djangotest_test_file_name_prefix="test"
endif

if !exists("g:tmux_djangotest_file_prefix")
    let g:tmux_djangotest_file_prefix=""
endif

if !exists("g:tmux_djangotest_tmux_cmd")
    let g:tmux_djangotest_tmux_cmd="screen#ScreenShell"
endif
Python2or3 << endpython

import re
import os
import vim
import ast


def is_test_file(fname):
    return os.path.basename(fname).startswith(
        vim.eval("g:tmux_djangotest_test_file_name_prefix")
    )

def find_appname(fname):
    """
    Look at the parent directory, if that directory isn't tests, then we
    will say it's our appname.

    Then, we look in apps.py for the AppConfig subclass
    """
    path = os.path.dirname(fname)

    for path in walk_up(path):
        appname = get_app_name_from_apps_module(path)
        if appname is not None:
            relative = os.path.relpath(
                fname, appname.replace('.', os.path.sep)
            )
            return os.path.join(
                appname.replace('.', os.path.sep),
                relative
            ).replace(os.path.sep, '.').replace('.py', '')

    return os.path.basename(fname).replace('.py', '')

def walk_up(path):
    while path:
        yield path
        if 'manage.py' in os.listdir(path):
            break
        path = os.path.dirname(path)


def get_app_name_from_apps_module(path):
    try:
        with open(os.path.join(path, 'apps.py')) as f:
            content = f.read()
            module = ast.parse(content)
            for node in module.body:
                if isinstance(node, ast.ClassDef):
                    for base in node.bases:
                        if "AppConfig" in ast.dump(base):
                            # Assuming the name attribute of AppConfig contains the name of the app
                            for attr in node.body:
                                if isinstance(attr, ast.Assign) and attr.targets[0].id == "name":
                                    return attr.value.s
    except (OSError, AttributeError):
        return None


def get_test_name():
    """
    Finds the test name for the django test under the cursor..
    """
    return match_in_current_buffer('def (test_[\_\w]+)')


def get_class_name():
    return match_in_current_buffer('^class ([\_\w]+)')


def match_in_current_buffer(regex_str):
    cb = vim.current.window.buffer
    (lineno, col) = vim.current.window.cursor
    regex = re.compile(regex_str)
    for no in reversed(range(1, lineno + 1)):
        linetext = cb[no]
        try:
            match, = regex.search(linetext).groups()
        except (ValueError, AttributeError):
            continue
        return match
    return None


def run_django_test():
    """
    Assumes the current file is named tests.py

    it will run the following command in the tmux session:

    ./manage.py test appname

    or

    # if the cursor is on a test_* function def.
    ./manage.py test appname.TestClass.test_name

    where appname is the test's containing folder.

    check if a particular test is under the cursor and run that.
    """

    cb = vim.current.buffer
    fname = cb.name

    if not is_test_file(fname):
        print("not a test file. file name doesn't begin with %s" %
              vim.eval("g:tmux_djangotest_test_file_name_prefix"))
        return

    # is it a specific test?
    classname = None
    testname = get_test_name()
    if testname:
        classname = get_class_name()

    # yes it's a test file let's find the owner.
    appname = find_appname(fname)

    manage_cmd = vim.eval("tmux_djangotest_manage_py")
    test_cmd = vim.eval("tmux_djangotest_test_cmd")
    prefix = vim.eval("tmux_djangotest_file_prefix")

    if testname and classname:
        # a single test to run.
        extra = ".{classname}.{testname}".format(**{
            'classname': classname, 'testname': testname
        })
    else:
        extra = ""

    # now send the command to tmux
    command = "{prefix}{manage_cmd} {test_cmd} {appname}{extra}".format(**{
        'prefix': prefix, 'manage_cmd': manage_cmd, 'test_cmd': test_cmd,
        'appname': appname, 'extra': extra
    })

    print(command)
    tmux(command)

def tmux(command):
    tmux_command = vim.eval("tmux_djangotest_tmux_cmd")
    vim.command('call {tmux_command}("clear && {command}")'.format(**{
        'tmux_command': tmux_command, 'command': command
    }))
endpython
