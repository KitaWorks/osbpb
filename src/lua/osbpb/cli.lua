local misc = require 'osbpb.misc'

local subcmds = {
   help = require 'osbpb.cmd.help',
   package = require 'osbpb.cmd.package',
}

local argparse = require 'osbpb.ext.argparse'

-- define arguments

local parser = argparse(
   'osbpb',
   'OSBPB - The package manager and maker for eternalOS'
):add_help(false)

-- TODO add group

parser:flag('-p --package',       'Enter packaging environment')
parser:flag('-i --install',       'Install package(s)')
parser:flag('-u --uninstall',     'Uninstall package(s)')
parser:flag('-l --list',          'List installed packages')
parser:flag('-o --extract',       'Unpack a package file')

parser:flag('-h --help',          'Show this help text and exit')

parser:option('-e --eval',
   'Eval a command instead of running into an interactive shell'):
   args(1):argname '<string>'
parser:option('-s --source',      'Copy a folder to /src inside'):
   args(1):argname '<folder>'

parser:flag('-v',                 'Be verbose')

parser:argument('args',
   'Optional arguments corresponding to subcommands'):
   args '*':target 'rest'

-- parse arguments

local args = parser:parse()

-- insert rest into args - it's easier to parse

args.__index = args.rest
args.rest.__metatable = nil
setmetatable(args, args)

args.parser = parser

-- so now `args` includes all arguments including optional and variadic
-- and a parser instance

-- call the subcommand

local triggered, ret = misc.oncase(args, subcmds)

if not triggered then
   return subcmds.help(args)
end

