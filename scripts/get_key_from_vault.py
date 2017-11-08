#!/usr/bin/python

from argparse import ArgumentParser
from requests import get, exceptions as req_exceptions
from urllib3 import disable_warnings, exceptions


def parse_args(msg):
    '''Initialize global variables'''

    parser = ArgumentParser(description=msg)
    parser.add_argument('-a', '--auth', metavar='Token', type=str, required=True,
                        help='Vault token')
    parser.add_argument('-s', '--secret', metavar='Secret', type=str, required=True,
                        help='Target secret to get value from Vault')
    parser.add_argument('-t', '--host', metavar='Domain', type=str, default='vault.jumia.com',
                        help='Vault host or domain (default: vault.jumia.com)')
    parser.add_argument('-p', '--port', metavar='Port', type=int, default=8200,
                        help='Vault port (default: 8200)')
    parser.add_argument('--prefix', metavar='Path', type=str, default='',
                        help='Vault prefix')
    parser.add_argument('--secret-backend', metavar='Backend', type=str, default='secret',
                        help='Vault secret backend (default: key-value)')
    parser.add_argument('--search-timeout', metavar='Seconds', type=int, default=60,
                        help='Timeout to expire HTTP GET requests (default: 60)')
    parser.add_argument('--ssl-enabled', action='store_true', default=True,
                        help='Vault access is over SSL (default: true)')
    parser.add_argument('--debug', action='store_true', default=False,
                        help='Enable debugging (default: false)')
    args = parser.parse_args()

    return args


def parse_json_response(http_response):
    '''Check and validate response from Vault'''
    data_info = []

    if http_response.ok:
        json_response = http_response.json()

        list_of_keys = True if "keys" in json_response["data"] else False

        if not list_of_keys:
            data_info = json_response["data"]["value"]
        else:
            # @todo - deal when secret path is getting a list of keys
            print ""

        return True, data_info

    return False, http_response.status_code


def read_vault_from_token(secret_path, check_if_list=False):
    '''Read values from a given secret endpoint'''
    endpoint = VAULT_URL + secret_path
    status = False
    params = ""

    if check_if_list:
        params = {
            "list": True
        }

    try:
        response = get(endpoint, headers=HEADERS, params=params,
                       verify=False, timeout=CONFIGS.search_timeout)
        status, secret_info = parse_json_response(response)

        if status:
            return True, secret_info
    except req_exceptions.RequestException as exception:
        if CONFIGS.debug:
            print(exception)

    return False, ""


if __name__ == "__main__":
    # Get passed arguments
    CONFIGS = parse_args("Get, at least, one secret from Vault")

    # Initialize global variables
    PROTOCOL = "http"
    if CONFIGS.ssl_enabled:
        PROTOCOL = "https"
        disable_warnings(exceptions.InsecureRequestWarning)

    VAULT_URL = '{0}://{1}:{2}/v1/{3}'.format(PROTOCOL,
                                              CONFIGS.host, CONFIGS.port, CONFIGS.secret_backend)

    HEADERS = {
        'Content-Type': 'application/json',
        'X-Vault-Token': CONFIGS.auth,
        'Accept': 'application/json'
    }

    VAULT_SECRET = CONFIGS.secret
    if CONFIGS.prefix != None:
        VAULT_SECRET = CONFIGS.prefix + "/" + CONFIGS.secret

    # Get value by the given vault secret
    STATUS, DATA = read_vault_from_token(VAULT_SECRET)

    # This condition checks if vault secret is a list of keys
    if not STATUS:
        STATUS, DATA = read_vault_from_token(VAULT_SECRET, True)

    # Returns to the output the required value or a list of values
    if STATUS and len(DATA) > 0:
        print(DATA)
        exit(0)

    exit(1)
