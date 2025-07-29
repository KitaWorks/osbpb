local argparse = require 'osbpb.lib.argparse'

local misc = require 'osbpb.misc'

local package = require 'osbpb.cmd.package'

-- subcommands

local function do_package(args)
   
end

local function do_install(args)
end

--` define arguments

local parser = argparse(
   'osbpb',
   'OSBPB - The package manager and maker for eternalOS'
)

-- TODO add group

parser:option('-p --package',     'Enter packaging environment')
parser:option('-i --install',     'Install package(s)')
parser:option('-u --uninstall',   'Uninstall package(s)')
parser:option('-l --list',        'List installed packages')
parser:option('-o --extract',     'Unpack a package file')

parser:option('-h --help',        'Show this help text and exit')

-- parser:option('-y --skip',       'Skip questions and '
parser:option('-e --eval',
   'Eval a command instead of running into an interactive shell'):
   args(1)
parser:option('-s --source',      'Copy a folder to /src inside'):
   args(1)

parser:option('-v',               'Be verbose')

parser:argument('rest',
   'Optional arguments corresponding to subcommands'):
   args('?')

-- parse arguments

local args = parser:parse()

-- insert rest into args - it's easier to parse
args.__index = args.rest
args.rest.__metatable = nil
setmetatable(args, args)

args.parser = parser

misc.on(args, {
   help = help,
   package = package,
})

