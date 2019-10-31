#!/usr/bin/env python
import sys
import os
import re
import time
import keyword

class ArgInfo:
    name_regex = re.compile('[A-Za-z_]*[0-9A-Za-z_]')

    def __init__(self):
        self.name = ''
        self.default_value = ''
        self.data_type = ''
        self.count_token = ''
        self.switch_name_list = []

    def get_switch_name_list(self):
        return self.switch_name_list

    def set_switch_name_list(self, switch_name_list):
        for switch_name in switch_name_list:
            if switch_name.startswith('-'):
                switch_name = switch_name[1:]
            if switch_name.startswith('-'):
                switch_name = switch_name[1:]
            self.validate_name(switch_name)
        self.switch_name_list = switch_name_list

    def get_name(self):
        return self.name

    def set_name(self, name):
        self.validate_name(name)
        self.name = name

    def get_default_value(self):
        return self.default_value

    def set_default_value(self, default_value):
        self.default_value = default_value

    def get_type(self):
        return self.data_type

    def set_type(self, type):
        self.data_type = type

    def get_count_token(self):
        return self.count_token

    def set_count_token(self, count):
        self.count_token = count

    def validate_name(self, name):
        result = ArgInfo.name_regex.match(name)
        if not result:
            raise ValueError('Illegal name: {0}'.format(name))

    def validate_no_duplicate_switches(arg_info_list):
        switch_list = []
        for arg_info in arg_info_list:
            for switch_name in arg_info.get_switch_name_list():
                if switch_name in switch_list:
                    raise ValueError('Duplicate switch name {0}.'.format(switch_name))
                switch_list.append(switch_name)

    def write_program_header(outfile, base_program_name, param_list):
        outfile.write('#!/usr/bin/env python\n')
        outfile.write('"""\n')
        outfile.write('    python {0}.py\n\n'.format(base_program_name))
        outfile.write('    TODO: Add usage information here.\n')
        outfile.write('"""\n')
        outfile.write('import sys\n')
        outfile.write('# TODO: Uncomment or add imports here.\n')
        outfile.write('#import os\n')
        outfile.write('#import re\n')
        outfile.write('#import time\n')
        outfile.write('#import subprocess\n')
        if param_list != None and len(param_list) > 0:
            outfile.write('from argparse import ArgumentParser\n')
        outfile.write('\n')
        return

    def get_function_call_string(function_name, param_list):
        function_call = '{0}('.format(function_name)
        number_of_params = len(param_list)
        for i in xrange(0, number_of_params):
            function_call = '{0}{1}'.format(function_call, param_list[i])
            if i != (number_of_params - 1):
                function_call = '{0}, '.format(function_call)
        function_call = '{0})'.format(function_call)
        return function_call

    def write_function_start(outfile, function_name, param_list):
        if function_name == 'main':
            outfile.write('# Start of main program.\n')
        function_call = get_function_call_string(function_name, param_list)
        function_declaration = 'def {0}:\n'.format(function_call)
        outfile.write(function_declaration)
        if function_name != 'main':
            outfile.write('    """ TODO: Add docstring here. """\n')
        return

    def write_execute_function(outfile, base_program_name, param_list):
        function_name = 'execute_{0}'.format(base_program_name)
        write_function_start(outfile, function_name, param_list)
        outfile.write('    # TODO: Add or delete code here.\n')
        outfile.write('    # Dump all passed argument values.\n')
        for param in param_list:
            outfile.write("    print '{0} = {1}0{2}'.format(repr({3}))\n".format(param, '{', '}', param))
        outfile.write('    return 0\n\n')
        return
