#!/usr/bin/python

import sys
file1 = open("Makefile", "r")
#print('Number of arguments:', len(sys.argv), 'arguments.') #debugging
num_args = len(sys.argv) # getting total args
if num_args > 1: # if args greater than just file name
    pos = num_args-1

    while pos != 1:
        curr_arg=str(sys.argv[pos]) # Current arg = arg at pos in string format
        #print('Arg:', pos, ' ', curr_arg) # debugging Arg@pos=...

        if "=" in curr_arg: # if there is an equals in the arg
            arg_name = curr_arg.split('=')[0] # get left side of equals
            final_arg_name = "$(" + arg_name + ")"
            # setting Arg does not exist
            flag = 0
            for line in file1:
                if final_arg_name in line:
                    if "#" in line:
                        arg_pos=line.find(final_arg_name) # find pos of arg
                        num_pos=line.find("#") # find pos of comment
                        if num_pos < arg_pos:
                            flag = 0 # Arg does not exist if there is a comment
                            break
                    flag = 1
                    break
            if flag == 0:
                raise ValueError("This Arguement:", final_arg_name, "is not declared in the Makefile")
        pos=pos-1