# Noop HTTP Server

## Generate Bullshified Project

```bash
cd bullshifier
bash bullshifier.sh --base_code='<path-to-basecode>' --copies='<basecode-copies-number>' --pattern='<class-name-to-be-replaced>' --preffix='<new-pattern-preffix>' --suffix='<new-pattern-suffix>'
```

## Install

```bash
pip3 install flask gevent
```

## Run

```bash
python3 -u app.py '<app-config-filepath>'
```

## Requests

```bash
curl http://localhost:9000/
```