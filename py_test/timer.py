import time
def timer(func):
    start = time.time()
    func()
    print(time.time() - start)

def func1():
    print('in func1')


def func2():
    print('in func2')

timer(func1)
timer(func2)
