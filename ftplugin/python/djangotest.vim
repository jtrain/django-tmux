if !has('python')
    finish
endif

if !exists("g:tmux_djangotest_manage_py")
    let g:tmux_djangotest_manage_py="python manage.py"
endif

if !exists("g:tmux_djangotest_test_cmd")
    let g:tmux_djangotest_test_cmd="test"
endif

if !exists("g:tmux_djangotest_test_file_contains")
    let g:tmux_djangotest_test_file_contains="unittest"
endif

if !exists("g:tmux_djangotest_file_prefix")
    let g:tmux_djangotest_file_prefix=""
endif

if !exists("g:tmux_djangotest_tmux_cmd")
    let g:tmux_djangotest_tmux_cmd="screen#ScreenShell"
endif
python << endpython

import re
import os
import vim

def is_test_file(fname):
    fd = open(fname, 'r')
    try:
        contents = fd.read()
        contains = vim.eval("g:tmux_djangotest_test_file_contains")
        return contains in contents
    finally:
        fd.close()

def find_appname(fname):
    """
    Look at the parent directory, if that directory isn't tests, then we
    will say it's our appname.
    """
    path = os.path.dirname(fname)
    if path.endswith('tests'):
        path = os.path.dirname(path)
    return os.path.basename(path)

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
        print "not a test file. looked for unittest and not found."
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
        extra = ".{classname}.{testname}".format(**locals())
    else:
        extra = ""

    # now send the command to tmux
    command = "{prefix}{manage_cmd} {test_cmd} {appname}{extra}".format(**locals())

    print command
    tmux(command)

def tmux(command):
    tmux_command = vim.eval("tmux_djangotest_tmux_cmd")
    vim.command('call {tmux_command}("clear && {command}")'.format(**locals()))

endpython
