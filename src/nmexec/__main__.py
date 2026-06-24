import os
from nmexec.server import Cluster
from yolo9.train_dual import parse_opt as train_dual_parse_opt
from yolo9.train_dual import main as train_dual_main
from yolo9.detect import parse_opt as detect_parse_opt
from yolo9.detect import main as detect_main
from yolo9.val_dual import parse_opt as val_dual_parse_opt
from yolo9.val_dual import main as val_dual_main


def main():
    cpus = os.cpu_count()
    if not isinstance(cpus, int):
        cpus = 1

    cpus = min(cpus, 16)

    HOST = os.environ.get("NMEXEC_HOST", "0.0.0.0")
    PORT = int(os.environ.get("NMEXEC_PORT", 9786))

    cluster = Cluster(host=HOST, port=PORT)
    cluster.run(workers=cpus)


def train_dual():
    opt = train_dual_parse_opt()
    train_dual_main(opt)


def detect():
    opt = detect_parse_opt()
    detect_main(opt)


def val_dual():
    opt = val_dual_parse_opt()
    val_dual_main(opt)


if __name__ == "__main__":
    main()
