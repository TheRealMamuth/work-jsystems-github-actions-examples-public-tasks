# Kroki Zadania 02

```yaml
name: 02 - Workflow Events

on:
  workflow_dispatch:

jobs:
  echo:
    runs-on: ubuntu-latest
    steps:
      - name: Show the triggering event
        run: echo "I' ve been triggered by the workflow_dispatch event ${{ github.event_name }}"
```

Zapisz i wypushuj zmiany do repozytorium.

Po wykonaniu pusha, przechodzimy do zakładki "Actions" w naszym repozytorium na GitHubie.

```yaml
name: 02 - Workflow Events

on:
  push:
    branches:
      - main
  workflow_dispatch:

jobs:
  echo:
    runs-on: ubuntu-latest
    steps:
      - name: Show the triggering event
        run: echo "I' ve been triggered by the workflow_dispatch event ${{ github.event_name }}"
```

Oczywiście akcje w on moga byc podane za pomoca listy:

```yaml
name: 02 - Workflow Events

on:
  - push
  - workflow_dispatch

jobs:
  echo:
    runs-on: ubuntu-latest
    steps:
      - name: Show the triggering event
        run: echo "I' ve been triggered by the workflow_dispatch event ${{ github.event_name }}"
```

Zobaczmy jeszcze inne przykłady zdarzeń wyzwalających workflow.

```yaml
name: 02 - Workflow Events

on:
  push:
    branches:
      - main # tylko push do main
  workflow_dispatch:
  pull_request:
    branches:
      - main # pull requesty do main
  schedule:
    - cron: '0 0 * * *'  # Codziennie o północy

jobs:
  echo:
    runs-on: ubuntu-latest
    steps:
      - name: Show the triggering event
        run: echo "I' ve been triggered by the workflow_dispatch event ${{ github.event_name }}"
```
