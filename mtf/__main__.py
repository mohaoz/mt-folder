"""Allow ``python -m mtf`` to behave like the ``mtf`` command."""

from .cli import main

raise SystemExit(main())
