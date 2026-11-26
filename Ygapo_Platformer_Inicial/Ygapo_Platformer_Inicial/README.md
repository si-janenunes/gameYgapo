# Ygapó — Raid do Teatro Amazonas

Protótipo 2D de batalha lateral em Godot 4.7. Ygá aparece diante do Teatro Amazonas e, ao confirmar a entrada na raid, enfrenta o monstro de lodo no interior.

## Abrir

1. Abra o gerenciador de projetos do Godot 4.7 (ou compatível).
2. Importe `project.godot` nesta pasta.
3. Execute o projeto com **F6** ou **F5**.

## Jogar

- Na fachada: clique em **ENTRAR NA RAID** ou pressione **Enter**.
- **Arranhão**: clique no botão ou pressione **J**.
- **Laser**: clique no botão ou pressione **K**. Custa 30 MP.
- **Poção**: clique em **USAR** ou pressione **H**. Recupera até 32 HP.
- O monstro ataca periodicamente; cada golpe reduz HP e recupera um pouco de MP.
- Ao vencer ou perder, use **JOGAR NOVAMENTE** para recomeçar.

Os quadros de HP e MP ficam sobre cada combatente. A barra de itens fica abaixo do monstro, e os golpes ficam abaixo de Ygá. As imagens usadas no protótipo são cópias dos arquivos fornecidos, guardadas em `assets/`; as artes originais permanecem na raiz do workspace.

## Estrutura

- `scenes/main.tscn`: cena inicial do projeto.
- `scripts/main.gd`: fachada, transição para a raid, interface e lógica de combate.
- `assets/battle/`: cópias das artes de personagem, monstro, golpes e itens.
- `assets/scenery/`: cenários fornecidos do Teatro.
