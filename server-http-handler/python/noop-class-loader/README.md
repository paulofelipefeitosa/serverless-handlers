# Noop HTTP Server

## Generate Bullshified Project

```bash
cd bullshifier
bash bullshifier.sh --base_code='<path-to-basecode>' --copies='<basecode-copies-number>' --pattern='<class-name-to-be-replaced>' --preffix='<new-pattern-preffix>' --suffix='<new-pattern-suffix>'
```

### Example
```bash
bash bullshifier.sh --base_code=ArgInfo.py --copies=50 --pattern="ArgInfo" --preffix="class " --suffix=":"
```


## Configuration

Open the file 'appconfig.ini' and edit the following properties:
```bash
[DEFAULT]
module_path=bullshifier.ArgInfo
classname=ArgInfo
classes=50
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