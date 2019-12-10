import base64
import sys

def encode(str, key='secret'):
    enc = []
    for i in range(len(str)):
        key_c = key[i % len(key)]
        enc_c = chr((ord(str[i]) + ord(key_c)) % 256)
        enc.append(enc_c)
    return base64.urlsafe_b64encode("".join(enc).encode()).decode()

if __name__ == "__main__":
    if len(sys.argv) == 3:
        print(encode(sys.argv[1], sys.argv[2]))
    elif len(sys.argv) == 2:
        print(encode(sys.argv[1]))
    else:
        print('Error: Expecting String and Key arguments only')
