import base64

def decode(str, key='secret'):
    dec = []
    str = base64.urlsafe_b64decode(str).decode()
    for i in range(len(str)):
        key_c = key[i % len(key)]
        dec_c = chr((256 + ord(str[i]) - ord(key_c)) % 256)
        dec.append(dec_c)
    print(dec)
    return "".join(dec)
