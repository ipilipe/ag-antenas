# Algoritmo Genético para Posicionamento de Antenas

AED da disciplina de Inteligência Artificial, curso de Ciência de Dados e Inteligência Artificial, PUC Goiás.

Aluno: Fellipe Gomes de Sousa Oliveira (matrícula 2026.1.0137.0006-9)
Professor: Victor Lima Queiroz

## O problema

Posicionar até 5 antenas (raio de 10 km cada) dentro de uma região quadrada de 200 km² no primeiro quadrante, buscando ao mesmo tempo:

- maximizar a área da região coberta (descontando sobreposições e o que fica fora da região);
- minimizar a quantidade de antenas.

Com área de 200 km², o lado da região é √200 ≈ 14,142 km.

## Como rodar

Requer MATLAB R2018b ou mais recente (usa `sgtitle` e `yyaxis`). Não precisa de nenhuma toolbox.

| Arquivo | Para que serve |
|---|---|
| `main.m` | Uma execução com gráficos e animação da evolução. Use no vídeo. |
| `executar_experimentos.m` | 10 execuções, tabela, estatísticas, comparação com o ótimo teórico e melhor solução geral. Salva tudo em `resultados/cenario_A` ou `cenario_B`. |
| `animar_evolucao.m` | Replay geração a geração do melhor indivíduo (pode gravar MP4). |
| `analise_parametros.m` | Varia população, cruzamento, mutação, elitismo e penalidade para medir o efeito de cada um. |
| `ga_antenas.m` | O Algoritmo Genético em si. |
| `avaliar_populacao.m` | Cálculo de área coberta e fitness. |
| `plotar_solucao.m` | Gráfico da região, antenas, cobertura e evolução. |
| `parametros_padrao.m` | Todos os parâmetros configuráveis e seus valores padrão. |

Todos os parâmetros podem ser trocados no início de `main.m` ou `executar_experimentos.m`.

## Decisões de modelagem

### Indivíduo (cromossomo)

Cada indivíduo tem 5 "vagas" de antena. Cada vaga guarda 3 genes: `ativo` (liga ou desliga), `x` e `y`.

```
[a1 x1 y1 | a2 x2 y2 | a3 x3 y3 | a4 x4 y4 | a5 x5 y5]
```

O gene `ativo` é o que permite ao AG decidir **quantas** antenas usar. Uma antena desligada não conta na cobertura nem na penalidade.

### Cálculo da área coberta

A região é dividida em uma grade de 150 x 150 pontos (22.500 pontos). Um ponto está coberto se estiver dentro de pelo menos uma antena. A cobertura é a fração de pontos cobertos.

Isso resolve as duas exigências do enunciado de uma vez:

- só conta a parte do círculo que fica dentro da região, porque os pontos só existem dentro dela;
- a sobreposição é descontada automaticamente, porque um ponto coberto por duas antenas conta uma vez só.

A precisão depende da resolução (cada ponto representa cerca de 0,0089 km²). O parâmetro `resolucao` pode ser aumentado se for preciso.

### Restrição de ficar dentro da região

Na mutação, as coordenadas são limitadas a `[0, lado]`. Assim nenhuma antena sai da região.

### Função fitness

```
fitness = pesoCobertura * cobertura - penalidadeAntena * numAntenas
```

com `cobertura` entre 0 e 1, `pesoCobertura = 1` e `penalidadeAntena = 0,05`.

Justificativa: cada antena "custa" 5 pontos percentuais de cobertura. Uma antena nova só vale a pena se aumentar a cobertura em mais de 5 p.p. Isso traduz o objetivo duplo do enunciado em um número só, e a penalidade é pequena o suficiente para que cobertura continue sendo a prioridade (perder 10% de área nunca compensa por economizar uma antena).

### Operadores genéticos

- **Seleção por torneio** (3 participantes): simples, não depende da escala do fitness (que pode ser negativo).
- **Cruzamento uniforme por vaga** (taxa 0,85): cada vaga do filho vem inteira de um dos pais. A antena é tratada como um bloco, então o filho nunca recebe o `x` de uma antena com o `y` de outra.
- **Mutação**: liga/desliga cada antena com probabilidade 0,05 e desloca sua posição com ruído gaussiano com probabilidade 0,15. O passo começa em 20% do lado e cai até 1% ao longo das gerações: no começo explora a região, no final ajusta fino.
- **Elitismo** (2 indivíduos): os dois melhores passam direto, garantindo que o melhor fitness nunca piora.

## Resultado esperado e checagem

O quadrado tem diagonal de √200 · √2 = 20 km, exatamente o diâmetro de uma antena. Ou seja, **uma única antena no centro (7,071 ; 7,071) cobre 100% da região**, porque a distância do centro até cada canto é exatamente 10 km.

Esse é o ótimo teórico, e serve como validação: um AG bem implementado deve convergir para 1 antena perto do centro, com cobertura de 100% e fitness 0,95. Nos testes, as 10 execuções chegaram a essa solução.

## Dois cenários testados

| | Cenário A (enunciado) | Cenário B (teste de generalização) |
|---|---|---|
| Região | 200 km² (lado ≈ 14,14 km) | 200 km x 200 km (40.000 km²) |
| Penalidade por antena | 0,05 | 0,002 |
| Ótimo teórico | 1 antena no centro, 100% | 5 antenas sem sobreposição, ≈ 3,93% |
| Fitness ótimo | 0,95 | ≈ 0,0293 |

O cenário B mostra que o mesmo algoritmo funciona quando a resposta certa é usar **todas** as antenas, e que a penalidade precisa estar na mesma escala do ganho de cobertura de uma antena (no cenário B, uma antena cobre só cerca de 0,8% da região; com penalidade 0,05 o AG preferiria ficar com uma antena só). Para trocar de cenário, mude a variável `cenario` no início de `executar_experimentos.m`.
