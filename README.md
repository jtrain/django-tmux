# Django-Tmux

Run your django tests in a tmux session directly from vim.

inspired by the work [vimux](https://github.com/benmills/vimux) et al have been doing with rails based tests.

## Installation

Install [pathogen](https://github.com/tpope/vim-pathogen) (skip if you already have pathogen)

Install a vim-tmux manager. I recommend [Screen](https://github.com/ervandew/screen)

Clone this repo to your bundle.

    cd ~/.vim/bundle
    git clone git://github.com/jtrain/django-tmux.git


## Features

You can run a single test at a time. Output matches the results of:


    python manage.py test appname.TestCase.test_function_name

You can run tests for an entire application at a time. Matches the result of:

    python manage.py test appname

## How to use
Put your cursor inside your test file on or inside a test function you would like to run.
Then hit the shortcut key (defined below) for run test. It will identify the test function
and the appname will be found.

Or put your cursor outside of a test function (like in setUp or a helper function). The test
suite for the whole app will run instead.

## Configuration Options

tmux_djangotest_manage_py (`default="python manage.py"`)
Command you use to run the manage.py file. Use this in combination with
`tmux_djangotest_file_prefix` to set up your Python/Virtualenv
 
    let g:tmux_djangotest_manage_py="python manage.py"

tmux_djangotest_test_cmd (`default="test"`)
The command you want manage.py to run. 
I default to test, but you may use whatever you want

    let g:tmux_djangotest_test_cmd="test"

tmux_djangotest_test_file_contains (`default="unittest"`)
The script checks for this word `unittest` in your test file. If you never
use the word `unittest` in your test files, put another word here that
is used instead.

    let g:tmux_djangotest_test_file_contains="unittest"

tmux_djangotest_file_prefix (`default=""`)
Used alongside `tmux_djangotest_manage_py` to set up the virtualenv. Note that
an example is `source ../bin/activate &&`. Note that it must have a `&&` following it.

    let g:tmux_djangotest_file_prefix=""

tmux_djangotest_tmux_cmd (default="screen#ScreenShell")
The function you use to send commands to tmux from vim. If you use the suggested screen.vim
project then you are good to go here. Otherwise you will have to look up the specifics of your
tmux handler for what they use to send commands.

    let g:tmux_djangotest_tmux_cmd="screen#ScreenShell"

## Shortcuts and settings I use for Screen

    " settings for screen-tmux
    let g:ScreenImpl = "Tmux"
    " init with 256 colours
    let g:ScreenShellTmuxInitArgs = '-2'
    " exit the child tmux when the host vim quits
    let g:ScreenShellQuitOnVimExit = 1
    " quits a spawned tmux from within vim
    map <Leader>q :ScreenQuit<CR>

    " shortcut to run test on Ctrl+b
    noremap <C-b> :python run_django_test()<CR>
