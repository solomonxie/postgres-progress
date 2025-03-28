# REF: https://github.com/patroni/patroni/blob/master/patroni/scripts/aws.py
# REF: https://patroni.readthedocs.io/en/latest/yaml_configuration.html#postgresql

import sys


def handle_patroni_callback(action: str, **args):
    print(f'{action=}, {args=}')


if __name__ == '__main__':
    handle_patroni_callback(sys.argv[1], *sys.argv[2:])
