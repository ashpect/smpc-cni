MOD = 2**61 - 1

def share_secret_n(x, n):
    import random
    shares = [random.randrange(0, MOD) for _ in range(n-1)]
    last = (x - sum(shares)) % MOD
    return shares + [last]

def add_mod(a, b):
    return (a + b) % MOD

def sub_mod(a, b):
    return (a - b) % MOD

def mul_mod(a, b):
    return (a * b) % MOD
