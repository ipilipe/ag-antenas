%% EXECUTAR_EXPERIMENTOS - Roda o AG varias vezes e analisa os resultados
% Exigencia do trabalho: pelo menos 10 execucoes.
% Gera: tabela com cada execucao, estatisticas, melhor solucao,
%       arquivos CSV e figuras na pasta "resultados".

clear; clc; close all;

numExecucoes = 10;
cenario = 'A';   % 'A' = regiao de 200 km^2 (enunciado) | 'B' = regiao de 200 km x 200 km

params = struct();
params.raio                = 10;
params.maxAntenas          = 5;
params.pesoCobertura       = 1.0;
switch cenario
    case 'A'
        params.areaRegiao       = 200;
        params.penalidadeAntena = 0.05;
    case 'B'
        params.lado             = 200;
        params.penalidadeAntena = 0.002;   % menor, pois cada antena cobre so ~0,8% da regiao
end
params.tamPopulacao        = 60;
params.numGeracoes         = 150;
params.taxaCruzamento      = 0.85;
params.taxaMutacao         = 0.15;
params.taxaMutacaoAtivacao = 0.05;
params.numElite            = 2;
params.tamTorneio          = 3;
params.mostrarProgresso    = false;

pasta = fullfile('resultados', ['cenario_' cenario]);
if ~exist(pasta, 'dir')
    mkdir(pasta);
end

% ---------------- Otimo teorico (para validar o AG) ----------------
% Cenario A: a diagonal do quadrado (sqrt(200)*sqrt(2) = 20 km) e igual ao
%            diametro da antena. Uma antena no centro cobre 100%.
% Cenario B: as 5 antenas cabem sem sobreposicao, cada uma cobre pi*r^2.
pTmp = parametros_padrao(params);
switch cenario
    case 'A'
        cobOtima = 1;
        nOtimo   = 1;
    case 'B'
        nOtimo   = pTmp.maxAntenas;
        cobOtima = nOtimo * pi * pTmp.raio^2 / pTmp.areaRegiao;
end
fitOtimo = pTmp.pesoCobertura * cobOtima - pTmp.penalidadeAntena * nOtimo;
fprintf('Otimo teorico: %d antena(s) | cobertura %.4f%% | fitness %.4f\n\n', nOtimo, 100*cobOtima, fitOtimo);

execucao   = (1:numExecucoes)';
numAntenas = zeros(numExecucoes, 1);
cobertura  = zeros(numExecucoes, 1);
area       = zeros(numExecucoes, 1);
fitness    = zeros(numExecucoes, 1);
geracaoConv = zeros(numExecucoes, 1);
tempo      = zeros(numExecucoes, 1);
todos      = cell(numExecucoes, 1);

for e = 1:numExecucoes
    params.semente = e;          % semente diferente por execucao (reprodutivel)
    tic;
    res = ga_antenas(params);
    tempo(e) = toc;

    todos{e}       = res;
    numAntenas(e)  = res.melhor.numAntenas;
    cobertura(e)   = 100 * res.melhor.cobertura;
    area(e)        = res.melhor.areaCoberta;
    fitness(e)     = res.melhor.fitness;
    geracaoConv(e) = res.melhor.geracaoConvergencia;

    fprintf('Execucao %2d | antenas = %d | cobertura = %6.2f%% | fitness = %.4f | %.1f s\n', ...
        e, numAntenas(e), cobertura(e), fitness(e), tempo(e));
end

% ---------------- Tabela de resultados ----------------
T = table(execucao, numAntenas, cobertura, area, fitness, geracaoConv, tempo, ...
    'VariableNames', {'Execucao', 'NumAntenas', 'CoberturaPct', 'AreaKm2', ...
                      'Fitness', 'GeracaoConvergencia', 'TempoSeg'});
disp(T);
writetable(T, fullfile(pasta, 'execucoes.csv'));

% ---------------- Estatisticas ----------------
metricas = {'NumAntenas', 'CoberturaPct', 'AreaKm2', 'Fitness', 'GeracaoConvergencia', 'TempoSeg'};
dados = [numAntenas, cobertura, area, fitness, geracaoConv, tempo];
Estat = table(metricas', mean(dados)', std(dados)', min(dados)', median(dados)', max(dados)', ...
    'VariableNames', {'Metrica', 'Media', 'DesvioPadrao', 'Minimo', 'Mediana', 'Maximo'});
fprintf('\n================ ESTATISTICAS (%d execucoes) ================\n', numExecucoes);
disp(Estat);
writetable(Estat, fullfile(pasta, 'estatisticas.csv'));

% Frequencia da quantidade de antenas escolhida
fprintf('Quantidade de antenas na melhor solucao de cada execucao:\n');
for n = 1:params.maxAntenas
    fprintf('  %d antena(s): %d execucao(oes)\n', n, sum(numAntenas == n));
end

% Comparacao com o otimo teorico
gap = 100 * (fitOtimo - fitness) / abs(fitOtimo);
atingiu = gap <= 0.5;   % ate 0,5% do otimo conta como "atingiu"
fprintf('\nDistancia media ao otimo teorico: %.3f%% | execucoes que chegaram ao otimo (ate 0,5%%): %d de %d\n', ...
    mean(gap), sum(atingiu), numExecucoes);

% ---------------- Melhor solucao geral ----------------
[~, iMelhor] = max(fitness);
best = todos{iMelhor};
m = best.melhor;

fprintf('\n================ MELHOR SOLUCAO GERAL (execucao %d) ================\n', iMelhor);
fprintf('Antenas utilizadas : %d\n', m.numAntenas);
for k = 1:size(m.posicoes, 1)
    fprintf('  Antena %d         : (%.4f ; %.4f) km\n', k, m.posicoes(k, 1), m.posicoes(k, 2));
end
fprintf('Area coberta       : %.4f km^2 de %.2f km^2\n', m.areaCoberta, best.params.areaRegiao);
fprintf('Percentual coberto : %.2f%%\n', 100*m.cobertura);
fprintf('Fitness            : %.4f\n', m.fitness);

% Confere a area da melhor solucao com uma grade bem mais fina (1000 x 1000)
% para mostrar o erro do calculo aproximado usado durante a evolucao.
pFina = best.params;
pFina.resolucao = 1000;
h = pFina.lado / pFina.resolucao;
v = (h/2):h:(pFina.lado - h/2);
[FX, FY] = meshgrid(v, v);
[~, cobFina] = avaliar_populacao(m.ativo, m.x, m.y, FX(:), FY(:), pFina);
fprintf('Area pela grade fina 1000x1000: %.4f km^2 (%.3f%%) | diferenca: %.4f km^2\n', ...
    cobFina * pFina.areaRegiao, 100*cobFina, abs(cobFina - m.cobertura) * pFina.areaRegiao);

fig1 = plotar_solucao(best, sprintf('Melhor solucao geral (execucao %d)', iMelhor));
saveas(fig1, fullfile(pasta, 'melhor_solucao.png'));

% ---------------- Curvas de todas as execucoes ----------------
fig2 = figure('Name', 'Todas as execucoes', 'Color', 'w', 'Position', [150 150 1100 420]);
subplot(1, 2, 1); hold on; grid on;
for e = 1:numExecucoes
    plot(todos{e}.historico.melhorFitness, 'LineWidth', 1);
end
xlabel('Geracao'); ylabel('Melhor fitness');
title('Melhor fitness por geracao (10 execucoes)');

subplot(1, 2, 2); hold on; grid on;
for e = 1:numExecucoes
    plot(100*todos{e}.historico.melhorCobertura, 'LineWidth', 1);
end
xlabel('Geracao'); ylabel('Cobertura do melhor (%)');
title('Cobertura por geracao (10 execucoes)');
saveas(fig2, fullfile(pasta, 'curvas_execucoes.png'));

save(fullfile(pasta, 'experimentos.mat'), 'T', 'Estat', 'todos', 'params');
