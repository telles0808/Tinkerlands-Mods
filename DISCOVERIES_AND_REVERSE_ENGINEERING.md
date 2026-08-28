# Tinkerlands - Engenharia Reversa, Arquitetura e Descobertas

> **Autor:** Telles0808  
> **Data:** 28 de Agosto de 2026  
> **Repositório:** [Tinkerlands-Mods (GitHub)](https://github.com/telles0808/Tinkerlands-Mods)

---

## 1. Arquitetura da Engine & Pipeline de Modding

### Engine & Execução
* **Game Engine:** GameMaker Studio compilado em modo **YYC (C++ nativo)** com extensão **Apollo** (`Apollo_x64.dll`).
* **Estrutura de Dados:**
  * Binário principal: `tinkerlands.exe` e `data.win`.
  * Banco de dados interno: tabelas estruturadas (`db_npc`, `db_item`, `db_quest`, `db_biome`, etc.).
  * Textos e Localização: arquivos `.lang` em formato chave/valor com interpolação de tokens (ex: `%Name%`, `{npcName}`).

### Pipeline de Empacotamento de Mods
1. **Codificação Especial GML:**
   * O parser do Apollo / ModTool requer tratamento de caracteres no código GML antes da montagem do pacote:
     * Vírgulas `,` são convertidas em `#$#`.
     * Aspas duplas `"` são convertidas em `%$%`.
     * Quebras de linha são convertidas em `\n`.
2. **Identificadores Únicos por Mod (`id`):**
   * Cada mod deve possuir um ID numérico único no JSON de script exportado para evitar colisões no registro de scripts do loader interno:
     * `Fog = 5001`
     * `RealClock = 5002`
     * `BO (Better Organizer) = 5003`
     * `TomTom = 5004`
     * `Monitor = 5005`
3. **Deploy & Recarregamento:**
   * Empacotamento em arquivo `.mod` (estrutura zip contendo a pasta `scripts/` e `info.json`).
   * Limpeza de cache em `%LOCALAPPDATA%\Tinkerlands\temp`.
   * Incremento do contador em `%LOCALAPPDATA%\Tinkerlands\packver` para forçar a engine a invalidar cache e recarregar os assets.

---

## 2. Ciclo de Vida da Engine & Prevenção de Falhas

### Estágios de Execução (`OnModLoad`, `OnWorldGenerationEnd`, `OnModDrawGUIEnd`)
* **`OnModLoad`:** Executado no estágio preliminar de carga da engine.
  * *Restrição Crítica:* Tentar criar instâncias de mods (`ModInstance`), manipular a janela gráfica (`window_set_position`, `window_set_fullscreen`) ou executar operações de I/O em disco bloqueia a inicialização da API gráfica DirectX, gerando congelamento permanente com tela branca.
* **`OnWorldGenerationEnd`:** Momento seguro para inicialização de instâncias de mods, alocação de estruturas de dados e leitura de arquivos de configuração, quando o mundo, superfícies e objetos da cena já estão carregados na memória.
* **`OnModDrawGUIEnd`:** Estágio de renderização acionado após o desenho de toda a interface nativa do jogo, ideal para elementos sobrepostos (topmost overlays).

---

## 3. Orientações de Integração com a Engine

Diretrizes técnicas confirmadas para funcionamento estável e integração orgânica com o jogo base:

### 1. Detecção do Modo Tutorial (`WORLD_FLAGS.tutorialCompleted`)
* O estado do tutorial é controlado pela flag global `WORLD_FLAGS.tutorialCompleted`.
* Durante a fase de introdução (`tutorialCompleted == false`), interfaces auxiliares, radares e contadores devem permanecer inativos para evitar sobreposição aos diálogos e tutoriais guiados.

### 2. Regiões de Rede e Entidades do Navio (`netRegion`)
* A engine segmenta ilhas e áreas instanciadas (como o interior do navio) utilizando o identificador `netRegion` no jogador (`MY_PLAYER.netRegion`) e nas entidades (`_npc.netRegion`).
* NPCs do navio (ex: Barqueiro) só devem ser processados ou exibidos no radar se estiverem na mesma região ativa do jogador (`_npc.netRegion == MY_PLAYER.netRegion` e `_npc.visible == true`).
* Isso previne a ocorrência de "NPCs fantasmas" rastreados no oceano ou em coordenadas inválidas em ilhas remotas.
* Durante transições de ilha ou entrada/saída de estruturas, os arrays de rastreamento devem ser limpos imediatamente.

### 3. Detecção de Telas Cheias de Navegação e Mapas
* Os controladores nativos `objGUIMapChartController` (mapa ampliado do mundo) e `objGUIShipNavigationController` (painel de navegação marítima) indicam menus modais em tela cheia. Nesses momentos, o HUD de jogo regular e os radares direcionais devem ser suspensos.

### 4. Bloqueio de Ataque e Ação ao Interagir com a UI (`craftMo`)
* Ao clicar em botões e elementos gráficos criados por mods na camada GUI, para impedir que o clique atravesse a interface e cause ataques involuntários com armas ou ferramentas no mundo, sinaliza-se à engine:
  ```gml
  with(objGUIIngameController)
  {
      craftMo = true;
  }
  Input.DisableMenuInputs(0.1);
  ```

---

## 4. Mapeamento, Projeção de Coordenadas e Sistema TomTom

### Projeção do Espaço de Mundo para a Tela do Mapa Aberto
* As coordenadas de pontos de interesse e marcadores (pins) são armazenadas em coordenadas de mundo `(world_x, world_y)`.
* Durante a renderização do mapa aberto (`objGUIMapChartController`), a projeção na tela respeita a origem da superfície e a escala de zoom:
  ```gml
  var _screen_x = _map_origin_x + (_pin.world_x - _cam_x) * _map_zoom;
  var _screen_y = _map_origin_y + (_pin.world_y - _cam_y) * _map_zoom;
  ```
* Essa projeção garante ancoragem fixa ao terreno durante o deslocamento (pan) e zoom do mapa.

### Cálculo Direcional e Distância para o TomTom
* O vetor de orientação das setas perimétricas fora do campo de visão é derivado do ângulo absoluto em relação ao jogador:
  ```gml
  var _angle = point_direction(MY_PLAYER.x, MY_PLAYER.y, _pin.world_x, _pin.world_y);
  var _distance_px = point_distance(MY_PLAYER.x, MY_PLAYER.y, _pin.world_x, _pin.world_y);
  var _distance_meters = round(_distance_px / 16.0);
  ```
* O sprite da seta é rotacionado usando `_angle` diretamente em `Draw.SpriteExt`, acompanhado da legenda `_pin.name + " (" + string(_distance_meters) + "m)"`.

### Sistema de Lixeira no HUD e Exclusão por Arrastar
* A zona de descarte (Lixeira) é desenhada em posição fixa de tela na camada de GUI apenas enquanto o mapa estiver aberto.
* Ao clicar e segurar sobre um marcador, o estado de arrasto (`dragged_pin_id`) é ativado.
* Ao soltar o botão esquerdo (`mouse_check_button_released(mb_left)`), verifica-se se o cursor colide com os limites da lixeira (`point_in_rectangle`). Em caso positivo, o marcador é removido da lista ativa e a persistência em disco é atualizada.

### Compensação do Travamento de Borda do Minimapa (Minimap Edge Clamping)
* **O Problema da Borda:** No HUD, o minimapa nativo opera sobre uma superfície delimitada (`0` até `MAP_WIDTH` e `MAP_HEIGHT`). Quando o jogador caminha em direção às bordas do mapa, a câmera do minimapa **trava a rolagem** para não exibir espaço vazio fora do mundo. Como consequência, o ícone do jogador sai do centro e se desloca até a borda da moldura.
* Cálculos ingênuos baseados na diferença relativa ao jogador `(_target - _player)` presumem que o jogador está sempre no centro do minimapa. Quando o jogador atinge as bordas, essa fórmula faz com que os marcadores se movam na direção oposta ao terreno.
* **Solução com Câmera Virtual Clamped (`TomTom_GetMinimapCameraCenter`):**
  1. Extração dinâmica das dimensões reais do mapa a partir da superfície nativa do minimapa `MINIMAP.surfaceWorld` via `surface_get_width` / `surface_get_height` (com fallback nas variáveis globais `MAP_WIDTH`, `MAP_HEIGHT`).
  2. Cálculo do raio de visão do minimapa em tiles:
     ```gml
     var _halfViewX = ((_miniRight - _miniLeft) * 0.5) / _miniScale;
     var _halfViewY = ((_miniBottom - _miniTop) * 0.5) / _miniScale;
     ```
  3. Travamento matemático da câmera virtual nos limites do mapa:
     ```gml
     var _camX = clamp(_playerMapX, _halfViewX, max(_halfViewX, _mapW - _halfViewX));
     var _camY = clamp(_playerMapY, _halfViewY, max(_halfViewY, _mapH - _halfViewY));
     ```
  4. Posição projetada no minimapa:
     ```gml
     var _targetMiniX = _miniCenterX + (_targetMapX - _camX) * _miniScale;
     var _targetMiniY = _miniCenterY + (_targetMapY - _camY) * _miniScale;
     ```
  * **Resultado:** Os marcadores permanecem 100% ancorados ao chão e alinhados milimetricamente aos elementos de cenário, tanto no interior da ilha quanto nas extremidades do mapa.

### Isolamento Canônico de Ilhas de Expedição (`RandomIslandXxY`)
* No navio, as ilhas geradas proceduralmente são dispostas em uma matriz de navegação e salvas em disco sob o padrão `RandomIsland<Coluna>x<Linha>.sav` (ex: `RandomIsland2x0.sav`, `RandomIsland3x0.sav`, `RandomIsland4x4.sav`).
* **Peculiaridade da VM do GameMaker:** A struct nativa `WORLD` é uma `globalvar`. A função `variable_global_exists("WORLD")` retorna `false` por buscar apenas no dicionário de `global.WORLD`.
* **Acesso Seguro:** Deve-se acessar `WORLD` diretamente com tratamento de exceção `try / catch`:
  ```gml
  function TomTom_GetWorldStruct()
  {
      try { if(is_struct(WORLD)) return WORLD; } catch(_e) {}
      try { if(variable_global_exists("WORLD")) { var _gw = variable_global_get("WORLD"); if(is_struct(_gw)) return _gw; } } catch(_e2) {}
      return undefined;
  }
  ```
* **Campos Críticos da Struct `WORLD`:**
  * `WORLD.name`: Retorna a chave canônica da ilha (ex: `"RandomIsland2x0"`). Na ilha principal, retorna `"undefined"` ou `"main"`.
  * `WORLD.isRandomIsland`: Booleano identificador de ilha secundária/expedição.
  * `WORLD.islandID`: ID numérico único da ilha nesta sessão (ex: `13.0`).
  * `WORLD.seed`: Seed numérica da geração procedural do terreno (ex: `4144428694.0`).
  * `WORLD.mapgenID`: ID do bioma/gerador (ex: `52.0` para Ilha Vulcânica). **Importante:** Ilhas diferentes do mesmo bioma compartilham o mesmo `mapgenID`. Portanto, o isolamento de marcadores por ilha deve priorizar sempre `WORLD.name`, `WORLD.islandID` ou `WORLD.seed`.

### Marcador de Conclusão / Explorado (Sprite Nativo do Codex)
* O sprite `sprGUIIngameIconCheck` na engine do Tinkerlands é nativamente **vermelho** (ícone de recusa/bloqueio). Misturas de cor via código transformam-no em vermelho-escuro/preto devido à multiplicação de canais.
* O ícone autêntico de confirmação verde em pixel-art da engine é `sprGUIIngameCodexIconCompleted`.
* **Filtragem de Radar:** Marcadores que indicam áreas já visitadas/exploradas (tipo 6) devem ser renderizados apenas no Mapa e no Minimapa, sendo filtrados fora do radar direcional de borda de tela (`TomTom_DrawScreenRadar`) para manter o campo de visão desobstruído para objetivos ativos.

---

## 5. Arquitetura de Inventário, Baús e Classificação de Itens (BO)

### O Segredo do Cadeado / Favorito no GameMaker YYC
* No GameMaker compilado, propriedades booleanas dentro de `ds_map` são salvas como o valor numérico real `1`.
* A checagem com `is_bool()` falha nesses casos. A verificação à prova de falhas deve aceitar equivalência de verdade:
  ```gml
  function BO_ItemIsMovable(_item)
  {
      if(!is_numeric(_item) || !ds_exists(_item, ds_type_map)) return false;
      if(!ds_map_exists(_item, 6) || _item[? 6] < 1) return false;

      if(ds_map_exists(_item, "favorite") && (_item[? "favorite"] == 1 || _item[? "favorite"] == true)) return false;
      if(ds_map_exists(_item, "favoriteItem") && (_item[? "favoriteItem"] == 1 || _item[? "favoriteItem"] == true)) return false;
      if(ds_map_exists(_item, "is_favorite") && (_item[? "is_favorite"] == 1 || _item[? "is_favorite"] == true)) return false;
      if(ds_map_exists(_item, "locked") && (_item[? "locked"] == 1 || _item[? "locked"] == true)) return false;

      var _k = ds_map_find_first(_item);
      while(!is_undefined(_k))
      {
          var _k_str = string_lower(string(_k));
          if(_k_str == "favorite" || _k_str == "favoriteitem" || _k_str == "locked" || _k_str == "padlock")
          {
              var _v = _item[? _k];
              if(_v == 1 || _v == true || _v == "1" || _v == "true") return false;
          }
          _k = ds_map_find_next(_item, _k);
      }
      return true;
  }
  ```

### Classificação Inteligente e Dissecção da Categoria "Etc"
* No banco de dados nativo do jogo, grande parte dos recursos, consumíveis, pergaminhos e chaves vêm categorizados sob a string genérica `"Etc"`.
* Para evitar que itens não-recursos (como pergaminhos de teleporte e chaves de sonar) caiam na aba de Madeira (Recursos), utiliza-se uma tabela de classificação por vocação e palavras-chave:
  1. **Aba Madeira (Bit 1 - Recursos / Materiais):** Ingredientes, especiarias, peixes crus e itens cujo ID/Nome contenha palavras como `wood`, `log`, `ore`, `stone`, `ingot`, `bar`, `fiber`, `crystal`, `obsidian`, `coal`, `leather`, `bone`, `feather`, `silk`, `leaf`, `herb`, `shroom`, `seed`, `gem`, `amethyst`, etc.
  2. **Aba Parede de Pedra (Bit 2 - Construção / Mobília):** `Building`, `Floor`, `Storage`, `Crafting Table`, `Cable` e itens com `wall`, `door`, `chest`, `table`, `chair`, `torch`, `furnace`, `anvil`, `platform`, `wire`.
  3. **Aba Poção Vermelha (Bit 4 - Consumíveis / Alimentos):** `Usable` e itens com `potion`, `flask`, `bottle`, `food`, `stew`, `soup`, `bread`, `pie`, `berry`, `fruit`, `drink`, `tea`.
  4. **Aba Escudo de Madeira (Bit 8 - Equipamentos / Acessórios):** `Weapon`, `Tool`, `Head`, `Body`, `Legs`, `Accesory`, `Hook`, `Fishing Rod`, `Pet` e itens com `sword`, `pickaxe`, `axe`, `hammer`, `bow`, `staff`, `shield`, `armor`, `ring`, `amulet`, `compass`, `sonar`, `saddle`.
  5. **Aba Flecha (Bit 16 - Munições / Arremessáveis):** `Ammo`, `Throwable` e itens com `arrow`, `bullet`, `dart`, `bomb`, `dynamite`, `shuriken`, `grenade`.
  6. **Aba Moeda de Ouro (Bit 32 - Miscelânea & Valiosos):** `Currency`, `Map`, `Recipe`, `Summon` e itens com `scroll`, `coin`, `blueprint`, `ticket`, `token`, `relic` e qualquer outro `"Etc"` não categorizado.

### Persistência de Filtros por Posição Física do Baú
* Os baús são ancorados estavelmente no mundo pelas suas coordenadas inteiras:
  * Baús normais: `"chest_x" + string(round(x)) + "_y" + string(round(y))`
  * Baús astrais: `"astral_x" + string(round(x)) + "_y" + string(round(y))`
* O salvamento em disco (`BO_filters.cfg`) utiliza o formato:
  `chave_posicao|apenas_existentes|mascara_bits_categoria`

### Otimizações Críticas de Performance no BO
1. **Eliminação de Loops $O(N^2)$ com `instance_find`:**
   * No GameMaker, chamar `instance_find(obj, i)` dentro de um loop `for (var i = 0; i < instance_number(obj); i++)` causa uma busca de lista interna a partir do índice 0 a cada iteração, tornando o custo computacional quadrático ($O(N^2)$). Em mapas com 50+ baús, isso causava quedas severas de taxa de quadros.
   * **Substituição por `with(obj)`:** O bloco `with(objInteractableChest)` itera linearmente em $O(N)$ em código compilado C++ nativo e permite `break` imediato ao encontrar o alvo, reduzindo o tempo de varredura de centenas de milissegundos para microssegundos.
2. **Remoção de I/O Síncrono de Disco em Tempo Real:**
   * A função `BO_LogImmediate` abria, escrevia e fechava `BO.log` no disco dezenas de vezes por frame durante a abertura e triagem de baús. Como o acesso a disco no Windows bloqueia a thread principal da engine, isso gerava micro-travamentos constantes. Em builds finais, todo log síncrono contínuo em disco foi eliminado.
3. **Throttling de Polling no Step:**
   * O método `BO_PreloadNearbyFilters()` não deve ser executado a 60 FPS no `Step`. O pré-carregamento foi configurado para ocorrer **uma única vez** no momento da abertura do inventário (`!_bo.inventory_visible_last`).
   * A checagem de baú aberto ativo (`BO_UpdateOpenChest`) foi espaçada para cada 10 quadros (~6 vezes por segundo), liberando mais de 85% de tempo de CPU sem impactar a responsividade da interface.

---

## 6. Anatomia dos NPCs (`objNPC`) & Sistema de Retratos

### A Divisão dos NPCs

```
                           ┌───────────────────────────────┐
                           │            objNPC             │
                           └──────────────┬────────────────┘
                                          │
                  ┌───────────────────────┴───────────────────────┐
                  ▼                                               ▼
     [ NPCs Humanoides ]                              [ NPCs Únicos / Especiais ]
  • Ferreira, Guia, Mineiro,                       • Gizmo, Goggs, Gumns, Pinguim,
    Enfermeira, Carpinteiro, etc.                    Robô, Dríades, Lunários, etc.
  • Sprites de Base Genéricos:                     • Sprites Próprios Exclusivos:
    - sprBasePlayerIdle01/02/03                      - sprNPCGizmoIdle01
    - sprBasePlayerHead01/02/03                      - sprNPCDryadIdle01
  • Visual composto por Equipamentos:                - sprNPCBankerPenguinIdle01
    - npc_blacksmith_helmet                          - sprNPCTownGhost
    - npc_blacksmith_armor                         • Nome do asset no GML contém a chave
  • Nome do asset no GML NÃO tem o papel             do NPC imediatamente!
    do NPC!
```

### Resolução $O(1)$ por `npcID`
* Cada `objNPC` possui a propriedade numérica `_npc.npcID` diretamente associada à base de dados `db_npc`.
* A função `Radar_GetPortrait` faz um `switch(_npc.npcID)` direto, eliminando buscas por strings, regex e dependência de idioma.

---

## 7. Tabela de Mapeamento Completo de NPCs

Extraído diretamente de `db_npc` e dos arquivos de idioma `english.lang` e `portuguese.lang`:

| ID | Key Interna | Título EN (`K_NPC_*`) | Título PT (`K_NPC_*`) | Nomes Próprios Sorteados | Sprite Retrato (`sprNPCPortrait*`) | Tipo de Sprite |
|---|---|---|---|---|---|---|
| `0` | `guide` | Wilson the Guide | Wilson, o Guia | Wilson, Doro/Teo, Harry/Rique | `sprNPCPortraitGuide` | Humanoide (`sprBasePlayerIdle03`) |
| `1` | `blacksmith` | %Name% the Blacksmith | %Name%, a Ferreira | Minerva, Nono | `sprNPCPortraitBlacksmith` | Humanoide (`sprBasePlayerIdle01`) |
| `3` | `merchant` | %Name% the Merchant | %Name%, a Mercadora | Ali, Yuria | `sprNPCPortraitMerchant` | Humanoide (`sprBasePlayerIdle01`) |
| `4` | `wandering_merchant` | %Name% the Travelling Merchant | %Name%, o Mercador Itinerante | Mute/Silente, Eshin | `sprNPCPortraitWanderingMerchant` | Humanoide (`sprBasePlayerIdle01`) |
| `5` | `bard` | %Name% the Bard | %Name%, o Bardo | Donut/Sonho, Bikini/Biquíni, Gabi | `sprNPCPortraitBard` | Humanoide (`sprBasePlayerIdle02`) |
| `6` | `witch` | %Name% the Witch | %Name%, a Bruxa | Pirilala, Luna | `sprNPCPortraitWitch` | Humanoide (`sprBasePlayerIdle01`) |
| `8` | `miner` | %Name% the Miner | %Name%, o Minerador | Joe/Zé, Tony/Toninho, Hans/João | `sprNPCPortraitMiner` | Humanoide (`sprBasePlayerIdle01`) |
| `9` | `farmer` | %Name% the Farmer | %Name%, o Fazendeiro | Dave/Tião, Koala/Coala | `sprNPCPortraitFarmer` | Humanoide (`sprBasePlayerIdle02`) |
| `10` | `carpenter` | %Name% the Carpenter | %Name%, o Carpinteiro | Petto, Jesus, Canyonero/Caminhoneiro | `sprNPCPortraitCarpenter` | Humanoide (`sprBasePlayerIdle01`) |
| `11` | `skeleton` | %Name% the Skeleton | %Name%, o Esqueleto | Bones/Ossada, Symbols/Calciano, Webdings/Esquelouco | `sprNPCPortraitSkeleton` | Especial / Humanoide |
| `12` | `chef` | %Name% the Chef | %Name%, o Chef | Fat Gordon/Polpetone, Grandote/Pançudo, Carlos | `sprNPCPortraitChef` | Humanoide (`sprBasePlayerIdle01`) |
| `13` | `fisherman` | %Name% the Fisherman | %Name%, o Pescador | Jeff Fisher/Juca, Crusty/Orlando | `sprNPCPortraitFisherman` | Humanoide (`sprBasePlayerIdle01`) |
| `14` | `summoner` | %Name% the Summoner | %Name%, o Evocador | Hulu, Poe | `sprNPCPortraitSummoner` | Humanoide (`sprBasePlayerIdle01`) |
| `15` | `electrician` | %Name% the Electrician | %Name%, o Eletricista | Wire-Link/Fio-solto, Wired/Bitola | `sprNPCPortraitElectrician` | Humanoide (`sprBasePlayerIdle01`) |
| `18` | `stylist` | %Name% the Stylist | %Name%, o Estilista | Normal Hands Edward, Mortadelo | `sprNPCPortraitStylish` | Humanoide (`sprBasePlayerIdle01`) |
| `19` | `ghostlands_ghost` | Ghost | Fantasma | — | `sprNPCPortraitGhost` | Especial (`sprNPCTownGhost`) |
| `21` | `cartographer` | %Name% Cartographer | %Name%, o Cartógrafo | Willy, Ron/Ronaldo | `sprNPCPortraitCartographer` | Humanoide (`sprBasePlayerIdle01`) |
| `22` | `michael` | Michael | Michael | Michael | `sprNPCPortraitMichael` | Especial |
| `23` | `gizmo` | Gizmo | Gizmo | Gizmo | `sprNPCPortraitGizmo` | Especial (`sprNPCGizmoIdle01`) |
| `24` | `goggs` | Goggs | Goggs | Goggs | `sprNPCPortraitGoggs` | Especial (`sprNPCGoggsIdle01`) |
| `25` | `gums` | Gums | Gums | Gums | `sprNPCPortraitGumns` | Especial (`sprNPCGumsIdle01`) |
| `26` | `nurse` | %Name% the Nurse | %Name%, a Enfermeira | Erin/Érica, Valentine/Valentina, Martha/Marta | `sprNPCPortraitNurse` | Humanoide (`sprBasePlayerIdle03`) |
| `27` | `librarian` | %Name% the Librarian | %Name%, a Bibliotecária | Sandra, Beatrice/Beatriz | `sprNPCPortraitLibrarian` | Humanoide (`sprBasePlayerIdle01`) |
| `28` | `robot` | %Name% the Robot | %Name%, o Robô | Mr.Roboto/Sr. Roboto, B1N-D3R | `sprNPCPortraitRobot` | Especial |
| `29` | `penguin` | %Name% the Penguin | %Name%, o Pinguim | Mr Noot/Sr. Noot, Oswald/Oswaldo | `sprNPCPortraitPenguin` | Especial (`sprNPCBankerPenguinIdle01`) |
| `30` | `enchantress` | %Name% the Enchantress | %Name%, a Encantadora | Sandal, Aiusht | `sprNPCPortraitEnchantress` | Humanoide (`sprBasePlayerIdle01`) |
| `31` | `dryad_liora` | Liora | Líora | Liora | `sprNPCPortraitDryad04` | Especial (`sprNPCDryadIdle04`) |
| `32` | `dryad_willowen` | Willowen | Salgueira | Willowen | `sprNPCPortraitDryad02` | Especial (`sprNPCDryadIdle02`) |
| `33` | `dryad_herby` | Herby | Érvio | Herby | `sprNPCPortraitDryad03` | Especial (`sprNPCDryadIdle03`) |
| `34` | `dryad_laurelo` | Laurelo | Lourélio | Laurelo | `sprNPCPortraitDryad01` | Especial (`sprNPCDryadIdle01`) |
| `35` | `loonaru_gloomo` | Gloomo | Penumbro | Gloomo | `sprNPCPortraitLoonaru01` | Especial (`sprNPCLoonaruIdle01`) |
| `36` | `loonaru_noctoo` | Noctoo | Breu | Noctoo | `sprNPCPortraitLoonaru02` | Especial (`sprNPCLoonaruIdle02`) |
| `37` | `loonaru_dooska` | Dooska | Ocásia | Dooska | `sprNPCPortraitLoonaru03` | Especial (`sprNPCLoonaruIdle03`) |
| `38` | `loonaru_moonia` | Moonia | Luana | Moonia | `sprNPCPortraitLoonaru04` | Especial (`sprNPCLoonaruIdle04`) |

---

## 8. Estrutura de Arquivos de Salvamento & Memória em Tempo de Execução

### Localização dos Saves
* Localização padrão: `%LOCALAPPDATA%\Tinkerlands\worlds\<savegameXX>\`
* Arquivos principais:
  * `main.sav`: Dados do mundo mãe (ilha principal).
  * `main_bk1.sav` a `main_bk5.sav`: Histórico de backups automáticos da ilha mãe.
  * `RandomIslandXxY.sav`: Arquivo de cada ilha de expedição descoberta na grade marítima.

### Arquivos de Configuração e Persistência dos Mods
* Armazenados em `%LOCALAPPDATA%\Tinkerlands\`:
  * `tomtom_pins.cfg`:
    * Linha 1 (Configuração global do mod): `#CFG|radar_mode|track_npcs|track_chests|track_mobs`
    * Linhas seguintes (Marcadores): `map_x|map_y|pin_type|island_key|map_level`
  * `BO_filters.cfg`:
    * Registros de filtros de baús: `posicao_container|existing_only|category_mask` (ex: `chest_x1424_y2720|1|40`)

### Anatomia do Cabeçalho JSON dos Saves
Os arquivos de ilha contêm um cabeçalho JSON compactado que pode ser lido na memória de processo ou inspecionado:
```json
{
  "name": "RandomIsland2x0",
  "isRandomIsland": true,
  "islandID": 13.0,
  "mapgenID": 52.0,
  "seed": 4144428694.0,
  "gamemode": 0.0,
  "spawn": [15.0, 225.0],
  "dungeons": [...],
  "biomeData": [...]
}
```

---

## 9. Conteúdo e Organização da Pasta `Dumps`

Todos os arquivos brutos de engenharia reversa e utilitários estão consolidados em `D:\98 - Games\Mods\Tinkerlands\Dumps\`:

* 📄 **`strings_dump.txt`**: Extração bruta completa de todos os identificadores, nomes de scripts, variáveis, objetos e sprites do executável e data.win do jogo (gerado via `strings64.exe`).
* 📄 **`strings_dump_filtered.txt`**: Versão compacta com foco em scripts, variáveis e assets de mods.
* 📁 **`languages/`**: Todos os arquivos oficiais de idioma do jogo extraídos da instalação Steam (`english.lang`, `portuguese.lang`, `spanish.lang`, etc.).
* 📁 **`scripts/`**: Utilitários PowerShell para consulta e extração.
* 📄 **`DISCOVERIES_AND_REVERSE_ENGINEERING.md`**: Este relatório completo de arquitetura, mecânicas e soluções.
