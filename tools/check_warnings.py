#!/usr/bin/env python3
"""Lista os avisos (warnings) do GDScript de todo o projeto e falha se houver algum.

O Godot só mostra esses avisos no editor (no modo headless eles somem), então este
script abre o editor sem janela e pergunta ao servidor de linguagem dele (porta 6005),
que devolve os mesmos avisos da aba Depurador > Erros.

Uso: python3 tools/check_warnings.py [pasta do projeto]
Precisa do `godot` no PATH (ou da variável GODOT) e do projeto já importado
(`godot --headless --import`). Sai com 1 se encontrar qualquer aviso.
"""
import json
import os
import pathlib
import socket
import subprocess
import sys
import time

RAIZ = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else ".").resolve()
PORTA = 6005
IGNORAR = ("addons", ".godot", ".git")


class Cliente:
    def __init__(self, sock):
        self.sock = sock
        self.buf = b""

    def enviar(self, msg):
        corpo = json.dumps(msg).encode()
        self.sock.sendall(b"Content-Length: %d\r\n\r\n" % len(corpo) + corpo)

    def ler(self, espera):
        """Próxima mensagem do servidor, ou None se nada chegar em `espera` segundos."""
        self.sock.settimeout(espera)
        while True:
            fim = self.buf.find(b"\r\n\r\n")
            if fim >= 0:
                cabecalho = self.buf[:fim].decode().lower().split("\r\n")
                tamanho = int(next(l for l in cabecalho if l.startswith("content-length")).split(":")[1])
                if len(self.buf) >= fim + 4 + tamanho:
                    corpo = self.buf[fim + 4:fim + 4 + tamanho]
                    self.buf = self.buf[fim + 4 + tamanho:]
                    return json.loads(corpo)
            try:
                dados = self.sock.recv(65536)
            except socket.timeout:
                return None
            if not dados:
                return None
            self.buf += dados


def conectar(editor, limite=120):
    inicio = time.time()
    while time.time() - inicio < limite:
        if editor.poll() is not None:
            sys.exit("O editor do Godot fechou antes de abrir o servidor de linguagem.")
        try:
            return socket.create_connection(("127.0.0.1", PORTA), timeout=5)
        except OSError:
            time.sleep(1)
    sys.exit("O servidor de linguagem do Godot não abriu a tempo.")


def main():
    godot = os.environ.get("GODOT", "godot")
    editor = subprocess.Popen(
        [godot, "--headless", "--editor", "--path", str(RAIZ)],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    try:
        cli = Cliente(conectar(editor))
        cli.enviar({"jsonrpc": "2.0", "id": 1, "method": "initialize",
                    "params": {"processId": None, "rootUri": RAIZ.as_uri(), "capabilities": {}}})
        while True:
            msg = cli.ler(60)
            if msg is None or msg.get("id") == 1:
                break
        cli.enviar({"jsonrpc": "2.0", "method": "initialized", "params": {}})
        arquivos = [p for p in sorted(RAIZ.rglob("*.gd"))
                    if not any(x in p.relative_to(RAIZ).parts for x in IGNORAR)]
        for p in arquivos:
            cli.enviar({"jsonrpc": "2.0", "method": "textDocument/didOpen",
                        "params": {"textDocument": {"uri": p.as_uri(), "languageId": "gdscript",
                                                    "version": 1, "text": p.read_text(encoding="utf-8")}}})
        achados = {}
        ocioso = 0
        while ocioso < 3:  # 3 esperas seguidas sem novidade: o servidor terminou
            msg = cli.ler(3)
            if msg is None:
                ocioso += 1
                continue
            ocioso = 0
            if msg.get("method") == "textDocument/publishDiagnostics":
                achados[msg["params"]["uri"]] = msg["params"]["diagnostics"]
    finally:
        editor.terminate()
        try:
            editor.wait(timeout=20)
        except subprocess.TimeoutExpired:
            editor.kill()
    total = 0
    for uri, diags in sorted(achados.items()):
        for d in diags:
            total += 1
            caminho = pathlib.Path(uri[len("file://"):]).relative_to(RAIZ)
            print(f"{caminho}:{d['range']['start']['line'] + 1}: {d['message']}")
    print(f"{len(arquivos)} script(s) verificado(s), {total} aviso(s).")
    sys.exit(1 if total else 0)


if __name__ == "__main__":
    main()
