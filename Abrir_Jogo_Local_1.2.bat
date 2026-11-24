@echo off
cd /d "%~dp0"
start "" /b python -m http.server 8012 --bind 127.0.0.1
timeout /t 2 /nobreak >nul
start "" "http://127.0.0.1:8012/index.html"
echo Jogo Aventura em Manaus versao 1.2 aberto no navegador.
echo Feche esta janela para parar o servidor local.
pause
