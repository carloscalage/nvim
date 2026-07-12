#!/usr/bin/env python3
"""
Le JSON ou JSONL do stdin e imprime uma versao legivel para leitura qualitativa.

Dois modos:
  --mode yaml (padrao): formato tipo YAML, expande \\n em quebras reais e
                        mantem acentuacao (nao escapa unicode). Melhor para ler texto.
  --mode json:          JSON identado e valido (ensure_ascii=False), para trabalho estrutural.

Aceita tanto um unico JSON (uma linha ou varias) quanto JSONL (um objeto por linha).
Nunca modifica o arquivo, so escreve no stdout.
"""
import json
import sys


def parse(data):
    data = data.strip()
    if not data:
        return []
    # tenta como um unico valor JSON (minificado em uma linha ou identado)
    try:
        return [json.loads(data)]
    except json.JSONDecodeError:
        pass
    # cai para JSONL: um objeto por linha
    records = []
    for line in data.splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            records.append(json.loads(line))
        except json.JSONDecodeError as exc:
            records.append({"__peek_erro__": str(exc), "__linha__": line})
    return records


def scalar(value):
    if value is None:
        return "null"
    if value is True:
        return "true"
    if value is False:
        return "false"
    return str(value)


def render(obj, indent, out):
    pad = "  " * indent
    if isinstance(obj, dict):
        if not obj:
            out.append(pad + "{}")
            return
        for key, value in obj.items():
            render_pair(str(key) + ":", value, indent, out)
    elif isinstance(obj, list):
        if not obj:
            out.append(pad + "[]")
            return
        for value in obj:
            render_pair("-", value, indent, out, dash=True)
    else:
        out.append(pad + scalar(obj))


def render_pair(label, value, indent, out, dash=False):
    pad = "  " * indent
    if isinstance(value, (dict, list)) and value:
        out.append(pad + label)
        render(value, indent + 1, out)
    elif isinstance(value, str) and "\n" in value:
        # bloco de texto multilinha: label seguido do texto identado
        out.append(pad + label + " |")
        for line in value.split("\n"):
            out.append(pad + "  " + line)
    else:
        sep = " " if dash else " "
        out.append(pad + label + sep + scalar(value))


def main():
    mode = "yaml"
    if "--mode" in sys.argv:
        mode = sys.argv[sys.argv.index("--mode") + 1]

    records = parse(sys.stdin.read())
    out = []
    multiple = len(records) > 1

    for i, record in enumerate(records):
        if multiple:
            if i > 0:
                out.append("")
            out.append("# record " + str(i + 1))
        if mode == "json":
            out.extend(json.dumps(record, indent=2, ensure_ascii=False).split("\n"))
        else:
            render(record, 0, out)

    sys.stdout.write("\n".join(out) + "\n")


if __name__ == "__main__":
    main()
