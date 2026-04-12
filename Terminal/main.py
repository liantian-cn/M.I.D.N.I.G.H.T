import sys
from terminal import Termnal


def main() -> int:
    termnal = Termnal()
    return termnal.run()


if __name__ == '__main__':
    sys.exit(main())
