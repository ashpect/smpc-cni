from fastapi import FastAPI
from pydantic import BaseModel
from node import Node
from utils import MOD

app = FastAPI()
node = None

class InitRequest(BaseModel):
    id: int
    x_share: int
    y_share: int
    a: int
    b: int
    c: int
    peers: list[str] = []

class ValuesRequest(BaseModel):
    d_total: int
    e_total: int

@app.post("/init")
def init_node(req: InitRequest):
    global node
    triple = (req.a, req.b, req.c)
    node = Node(req.id, req.x_share, req.y_share, triple)
    node.peers = req.peers
    return {"status": "initialized"}

@app.get("/compute_d_e")
def compute_d_e():
    d, e = node.local_d_e(MOD)
    return {"d": int(d), "e": int(e)}

@app.post("/compute_z")
def compute_z(req: ValuesRequest):
    is_designated = (node.id == 0)
    z = node.compute_z_share(req.d_total, req.e_total, is_designated, MOD)
    return {"z": int(z)}

@app.get("/health")
def health():
    return {"status":"ok"}
