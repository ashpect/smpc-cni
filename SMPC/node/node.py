from utils import MOD

class Node:
    def __init__(self, id, x_share, y_share, triple):
        self.id = id
        self.x = x_share
        self.y = y_share
        self.a, self.b, self.c = triple
        self.peers = []

    def local_d_e(self, MOD):
        d = (self.x - self.a) % MOD
        e = (self.y - self.b) % MOD
        return d, e

    def compute_z_share(self, d_total, e_total, is_designated, MOD):
        z = (self.c + (d_total * self.b) + (e_total * self.a)) % MOD
        if is_designated:
            z = (z + (d_total * e_total)) % MOD
        return z
