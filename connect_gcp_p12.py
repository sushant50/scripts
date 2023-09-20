'''
This program verifies a Signed JWT created by Google Service Account P12 credentials
First a JWT is signed with the P12 Private Key.
The certificate is extracted from the P12 file and used to verify the signature
'''

import json
import time
import base64
import jwt
import OpenSSL.crypto
import requests
# from google.auth.transport import requests

# Set how long this token will be valid in seconds
expires_in = 3600   # Expires in 1 hour

#scopes = "https://www.googleapis.com/auth/cloud-platform"

# Details on the Google Service Account. The email must match the Google Console.
sa_filename = ''
sa_password = 'notasecret'
p12_email = ''

iap_client_id = 'apps.googleusercontent.com'
url='https://34.160.27.56.nip.io/'
oauth_token_uri="https://www.googleapis.com/oauth2/v4/token"
# You can control what is verified in the JWT. For example to allow expired JWTs
# set 'verify_exp' to False
options = {
    'verify_signature': True,
    'verify_exp': True,
    'verify_nbf': True,
    'verify_iat': True,
    'verify_aud': True,
    'require_exp': False,
    'require_iat': False,
    'require_nbf': False
}

def load_private_key(p12_path, p12_password):
    ''' Read the private key and return as base64 encoded '''

    # print('Opening:', p12_path)
    with open(p12_path, 'rb') as f:
        data = f.read()

    # print('Loading P12 (PFX) contents:')
    p12 = OpenSSL.crypto.load_pkcs12(data, p12_password)

    # Dump the Private Key in PKCS#1 PEM format
    pkey = OpenSSL.crypto.dump_privatekey(
            OpenSSL.crypto.FILETYPE_PEM,
            p12.get_privatekey())

    # return the private key
    return pkey

def load_public_key(p12_path, p12_password):
    ''' Read the public key and return as base64 encoded '''

    # print('Opening:', p12_path)
    with open(p12_path, 'rb') as f:
        p12_data = f.read()

    # print('Loading P12 (PFX) contents:')
    p12 = OpenSSL.crypto.load_pkcs12(p12_data, p12_password)

    public_key = OpenSSL.crypto.dump_publickey(
                    OpenSSL.crypto.FILETYPE_PEM,
                    p12.get_certificate().get_pubkey())

    return public_key

def create_signed_jwt(p12_path, p12_password, p12_email, iap_client_id, oauth_token_uri):
    ''' Create an AccessToken from a service account p12 credentials file '''

    pkey = load_private_key(p12_path, p12_password)
    print(pkey)

    issued = int(time.time())
    expires = issued + expires_in   # expires_in is in seconds

    # Note: this token expires and cannot be refreshed. The token must be recreated

    # JWT Headers
    additional_headers = {
            "alg": "RS256",
            "typ": "JWT"  # Google uses SHA256withRSA,

    }

    # JWT Payload
    payload = {
        "iss": p12_email,   # Issuer claim
        "sub": p12_email,   # Issuer claim
        "aud": oauth_token_uri,    # Audience claim
        "iat": issued,      # Issued At claim
        "exp": expires,     # Expire time,
        "email": p12_email,
        "target_audience": iap_client_id
    }

    # Encode the headers and payload and sign creating a Signed JWT (JWS)
    sig = jwt.encode(payload, pkey, algorithm="RS256", headers=additional_headers)

    return sig

def pad(data):
    """ pad base64 string """

    missing_padding = len(data) % 4
    data += '=' * (4 - missing_padding)
    return data

def print_jwt(signed_jwt):
    """ Print a JWT Header and Payload """

    s = signed_jwt.encode().decode('utf-8').split('.')

    print('Header:')
    h = base64.urlsafe_b64decode(pad(s[0])).decode('utf-8')
    print(json.dumps(json.loads(h), indent=4))

    print('Payload:')
    p = base64.urlsafe_b64decode(pad(s[1])).decode('utf-8')
    print(json.dumps(json.loads(p), indent=4))

if __name__ == '__main__':
    s_jwt = create_signed_jwt(sa_filename, sa_password, p12_email, iap_client_id, oauth_token_uri)
    data = {
    'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
    'assertion': s_jwt,
    }
    response = requests.post('https://www.googleapis.com/oauth2/v4/token', data=data)
    headers = {
    'Authorization': 'Bearer '+response.json()['id_token'],
    }
    
    response = requests.get(url + 'api/v1/mks', headers=headers)
    print(response.content)
