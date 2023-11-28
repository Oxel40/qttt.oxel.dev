def add(a: int, b: int):
    return a+b

if __name__ == "__main__":
    while True:
        inp = input()
        args = map(int, inp.split())
        print(add(*args))
