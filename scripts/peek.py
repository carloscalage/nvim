#!/usr/bin/env python3
"""
Le JSON ou JSONL do stdin e imprime uma versao legivel para leitura qualitativa.

Dois modos:
  --mode tree (padrao): arvore com conectores (├─ └─ │), expande \\n em quebras reais,
                        expande strings que contem JSON e mantem acentuacao. Melhor para ler.
  --mode json:          JSON identado e valido (ensure_ascii=False), para trabalho estrutural.

Aceita tanto um unico JSON (uma linha ou varias) quanto JSONL (um objeto por linha).
Nunca modifica o arquivo, so escreve no stdout.
"""
import json
import sys

# conectores da arvore
TEE = "├─ "
ELB = "└─ "
BAR = "│  "
GAP = "   "
DOT = "▪"  # marcador de item de lista que abre um bloco


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


def try_nested_json(value):
    """Se a string for JSON (objeto/lista) serializado, devolve o valor parseado."""
    if not isinstance(value, str):
        return None
    text = value.strip()
    if text[:1] not in "{[":
        return None
    try:
        parsed = json.loads(text)
    except (json.JSONDecodeError, ValueError):
        return None
    if isinstance(parsed, (dict, list)):
        return parsed
    return None


def scalar(value):
    if value is None:
        return "null"
    if value is True:
        return "true"
    if value is False:
        return "false"
    if isinstance(value, (dict, list)):  # container vazio
        return "{}" if isinstance(value, dict) else "[]"
    return str(value)


def is_block(value):
    return isinstance(value, str) and "\n" in value


def classify(is_key, key, value):
    """Decide como um par (dict) ou item (lista) vira cabeca + eventual conteudo.

    Retorna (head, kind, payload):
      kind == "children" -> payload e um container a expandir
      kind == "block"    -> payload e o texto multilinha
      kind == "leaf"     -> head ja esta completa
    """
    tag = (str(key)) if is_key else DOT
    nested = try_nested_json(value)
    if nested is not None:
        return tag + "  (json)", "children", nested
    if isinstance(value, (dict, list)) and value:
        return tag, "children", value
    if is_block(value):
        head = (str(key) + ": |") if is_key else DOT + " |"
        return head, "block", value
    if is_key:
        return str(key) + ": " + scalar(value), "leaf", None
    return scalar(value), "leaf", None


def render_children(container, prefix, out):
    if isinstance(container, dict):
        items = list(container.items())
        for i, (k, v) in enumerate(items):
            render_entry(prefix, i == len(items) - 1, True, k, v, out)
    else:
        for i, v in enumerate(container):
            render_entry(prefix, i == len(container) - 1, False, None, v, out)


def render_entry(prefix, last, is_key, key, value, out):
    connector = ELB if last else TEE
    child_prefix = prefix + (GAP if last else BAR)
    head, kind, payload = classify(is_key, key, value)
    out.append(prefix + connector + head)
    if kind == "children":
        render_children(payload, child_prefix, out)
    elif kind == "block":
        for line in payload.split("\n"):
            out.append(child_prefix + "  " + line)


def render_record(record, out):
    # nivel de topo: sem conectores, uma linha em branco entre campos
    if isinstance(record, dict):
        items = list(record.items())
        for i, (k, v) in enumerate(items):
            if i > 0:
                out.append("")
            render_top(str(k), v, out)
    elif isinstance(record, list):
        render_children(record, "", out)
    else:
        out.append(scalar(record))


def render_top(key, value, out):
    nested = try_nested_json(value)
    if nested is not None:
        out.append(key + "  (json)")
        render_children(nested, "", out)
    elif isinstance(value, (dict, list)) and value:
        out.append(key)
        render_children(value, "", out)
    elif is_block(value):
        out.append(key + ": |")
        for line in value.split("\n"):
            out.append("  " + line)
    else:
        out.append(key + ": " + scalar(value))


def main():
    mode = "tree"
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
            render_record(record, out)

    sys.stdout.write("\n".join(out) + "\n")


if __name__ == "__main__":
    main()
