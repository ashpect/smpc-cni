import requests
import random
import time
from utils import MOD, share_secret_n, mul_mod  

import os
N = int(os.getenv("NODE_COUNT", "3"))
BASE = os.getenv("BASE_HOSTNAME", "smpc-node")
SERVICE = os.getenv("HEADLESS_SERVICE", "smpc")
NAMESPACE = os.getenv("NAMESPACE", "default")
PORT = int(os.getenv("NODE_PORT", "8000"))

USE_K8S = os.getenv("USE_K8S", "false").lower() == "true"

def pod_url(i):
    if USE_K8S:
        # Kubernetes StatefulSet + Headless service
        return f"http://{BASE}-{i}.{SERVICE}.{NAMESPACE}.svc.cluster.local:{PORT}"
    else:
        # Docker Compose — service names are just node0, node1, node2...
        return f"http://node{i}:{PORT}"


def generate_beaver_triples_and_shares(n, MOD):
    a = random.randrange(0, MOD)
    b = random.randrange(0, MOD)
    c = (a * b) % MOD
    a_shares = share_secret_n(a, n)
    b_shares = share_secret_n(b, n)
    c_shares = share_secret_n(c, n)
    return (a_shares, b_shares, c_shares)

def main():
    x = int(os.getenv("INPUT_X", "123"))
    y = int(os.getenv("INPUT_Y", "45"))

    x_shares = share_secret_n(x, N)
    y_shares = share_secret_n(y, N)

    a_shares, b_shares, c_shares = generate_beaver_triples_and_shares(N, MOD)

    peers = [pod_url(i) for i in range(N)]
    print("Peered nodes:", peers)

    for i, url in enumerate(peers):
        payload = {
            "id": i,
            "x_share": int(x_shares[i]),
            "y_share": int(y_shares[i]),
            "a": int(a_shares[i]),
            "b": int(b_shares[i]),
            "c": int(c_shares[i]),
            "peers": peers
        }
        r = requests.post(f"{url}/init", json=payload, timeout=10)
        r.raise_for_status()

    time.sleep(1)  

    d_vals, e_vals = [], []
    for url in peers:
        r = requests.get(f"{url}/compute_d_e", timeout=10)
        data = r.json()
        d_vals.append(int(data["d"]))
        e_vals.append(int(data["e"]))

    d_total = sum(d_vals) % MOD
    e_total = sum(e_vals) % MOD
    print("d_total:", d_total, "e_total:", e_total)

    z_vals = []
    for url in peers:
        r = requests.post(f"{url}/compute_z", json={"d_total": d_total, "e_total": e_total}, timeout=10)
        data = r.json()
        z_vals.append(int(data["z"]))

    z = sum(z_vals) % MOD
    print(f"Final secure product (reconstructed): {z}")
    print("Plain product:", x * y)
    if z == (x * y) % MOD:
        print("SUCCESS: matches expected product modulo MOD.")
    else:
        print("ERROR: mismatch.")
    
if __name__ == "__main__":
    main()
