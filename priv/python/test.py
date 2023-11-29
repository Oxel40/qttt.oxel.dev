import sys
import json


def deb_print(*args, **kwargs):
    print(*args, **kwargs, file=sys.stderr)


if __name__ == "__main__":
    while True:
        inp = input()
        board = json.loads(inp)
        deb_print(board)
        print(json.dumps(board))
