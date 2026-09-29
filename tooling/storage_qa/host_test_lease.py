"""Keep cooperating storage QA runners serial on a memory-constrained host."""
import os
from pathlib import Path
import tempfile


class HostTestLease:
    def __init__(self, path=None):
        self.path = Path(path) if path else (
            Path(tempfile.gettempdir()) / 'ui-lab-storage-qa-host.lock')
        self.stream = None

    def __enter__(self):
        stream = self.path.open('a+b')
        try:
            if os.name == 'nt':
                import msvcrt
                if self.path.stat().st_size == 0:
                    stream.write(b'\0')
                    stream.flush()
                stream.seek(0)
                msvcrt.locking(stream.fileno(), msvcrt.LK_NBLCK, 1)
            else:
                import fcntl
                fcntl.flock(stream, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except OSError as error:
            stream.close()
            raise RuntimeError(
                'Another storage QA runner holds the host test slot. '
                'Wait for it to finish before starting this run.') from error
        self.stream = stream
        return self

    def __exit__(self, *_):
        # OS releases the lock even on process death. Do not unlink the file:
        # another process could hold the old inode while a new lock is created.
        self.stream.close()
        self.stream = None
