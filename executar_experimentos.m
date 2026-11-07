%% EXECUTAR_EXPERIMENTOS - Roda o AG varias vezes e analisa os resultados
% Exigencia do trabalho: pelo menos 10 execucoes.
% Gera: tabela com cada execucao, estatisticas, comparacao com o otimo
%       teorico, melhor solucao, arquivos CSV e figuras na pasta "resultados".
%
% COMO ESCOLHER O CENARIO (digite no Command Window):
%   executar_experimentos                     -> roda o cenario A (padrao)
%   cenario = 'B'; executar_experimentos      -> roda o cenario B
%   cenario = 'A'; executar_experimentos      -> volta para o cenario A

clearvars -except cenario; clc; close all;

if ~exist('cenario', 'var')
    cenario = 'A';   % 'A' = regiao de 200 km^2 (enunciado) | 'B' = regiao de 200 km x 200 km
end
cenario = upper(char(cenario));
numExecucoes = 10;

params = struct();
params.raio                = 10;
params.maxAntenas          = 5;
params.pesoCobertura       = 1.0;
switch cenario
    case 'A'
        params.areaRegiao       = 200;
        params.penalidadeAntena = 0.05;
        params.resolucao        = 150;    % celula de ~0,094 km
    case 'B'
        params.lado             = 200;
        params.penalidadeAntena = 0.002;  % menor, pois cada antena cobre so ~0,8% da regiao
        params.resolucao        = 800;    % celula de 0,25 km (grade grossa deixa o AG "trapacear")
    otherwise
        error('Cenario invalido. Use ''A'' ou ''B''.');
end
params.tamPopulacao        = 60;
params.numGeracoes         = 150;
params.taxaCruzamento      = 0.85;
params.taxaMutacao         = 0.15;
params.taxaMutacaoAtivacao = 0.05;
params.numElite            = 2;
params.tamTorneio          = 3;
params.mostrarProgresso    = false;

fprintf('================ CENARIO %s ================\n', cenario);

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
fprintf('Otimo teorico: %d antena(s) | cobertura %.4f%% | area %.2f km^2 | fitness %.5f\n', ...
    nOtimo, 100*cobOtima, cobOtima * pTmp.areaRegiao, fitOtimo);
fprintf('Grade usada pelo AG: %d x %d celulas (%.3f km cada)\n\n', ...
    pTmp.resolucao, pTmp.resolucao, pTmp.lado / pTmp.resolucao);

% Grade fina usada so para CONFERIR a area da solucao final de cada execucao
pFina = pTmp;
pFina.resolucao = max(1000, 4 * pTmp.resolucao);

execucao    = (1:numExecucoes)';
numAntenas  = zeros(numExecucoes, 1);
cobertura   = zeros(numExecucoes, 1);
coberturaFina = zeros(numExecucoes, 1);
area        = zeros(numExecucoes, 1);
fitness     = zeros(numExecucoes, 1);
fitnessFina = zeros(numExecucoes, 1);
geracaoConv = zeros(numExecucoes, 1);
tempo       = zeros(numExecucoes, 1);
todos       = cell(numExecucoes, 1);

for e = 1:numExecucoes
    params.semente = e;          % semente diferente por execucao (reprodutivel)
    tic;
    res = ga_antenas(params);
    tempo(e) = toc;

    m = res.melhor;
    [fF, cF] = avaliar_populacao(m.ativo, m.x, m.y, [], [], pFina);

    todos{e}         = res;
    numAntenas(e)    = m.numAntenas;
    cobertura(e)     = 100 * m.cobertura;
    coberturaFina(e) = 100 * cF;
    area(e)          = m.areaCoberta;
    fitness(e)       = m.fitness;
    fitnessFina(e)   = fF;
    geracaoConv(e)   = m.geracaoConvergencia;

    fprintf('Execucao %2d | antenas = %d | cobertura = %8.4f%% (grade fina %8.4f%%) | fitness = %.5f | %.1f s\n', ...
        e, numAntenas(e), cobertura(e), coberturaFina(e), fitness(e), tempo(e));
end

% ---------------- Tabela de resultados ----------------
T = table(execucao, numAntenas, cobertura, coberturaFina, area, fitness, fitnessFina, geracaoConv, tempo, ...
    'VariableNames', {'Execucao', 'NumAntenas', 'CoberturaPct', 'CoberturaFinaPct', 'AreaKm2', ...
                      'Fitness', 'FitnessFina', 'GeracaoConvergencia', 'TempoSeg'});
disp(T);
writetable(T, fullfile(pasta, 'execucoes.csv'));

% ---------------- Estatisticas ----------------
metricas = {'NumAntenas', 'CoberturaPct', 'CoberturaFinaPct', 'AreaKm2', 'Fitness', ...
            'FitnessFina', 'GeracaoConvergencia', 'TempoSeg'};
dados = [numAntenas, cobertura, coberturaFina, area, fitness, fitnessFina, geracaoConv, tempo];
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

% Comparacao com o otimo teorico (usando a grade fina, que e mais proxima do valor real)
gap = 100 * (fitOtimo - fitnessFina) / abs(fitOtimo);
atingiu = abs(gap) <= 0.5;   % ate 0,5% do otimo conta como "atingiu"
fprintf('\nDistancia media ao otimo teorico (grade fina): %.3f%% | execucoes que chegaram ao otimo (ate 0,5%%): %d de %d\n', ...
    mean(gap), sum(atingiu), numExecucoes);

% ---------------- Melhor solucao geral ----------------
[~, iMelhor] = max(fitnessFina);
best = todos{iMelhor};
m = best.melhor;

fprintf('\n================ MELHOR SOLUCAO GERAL (execucao %d) ================\n', iMelhor);
fprintf('Antenas utilizadas : %d\n', m.numAntenas);
for k = 1:size(m.posicoes, 1)
    fprintf('  Antena %d         : (%.4f ; %.4f) km\n', k, m.posicoes(k, 1), m.posicoes(k, 2));
end
fprintf('Area coberta       : %.4f km^2 de %.2f km^2\n', m.areaCoberta, best.params.areaRegiao);
fprintf('Percentual coberto : %.4f%%\n', 100*m.cobertura);
fprintf('Fitness            : %.5f\n', m.fitness);
fprintf('Area pela grade fina %dx%d: %.4f km^2 (%.4f%%) | diferenca: %.4f km^2\n', ...
    pFina.resolucao, pFina.resolucao, coberturaFina(iMelhor)/100 * pFina.areaRegiao, ...
    coberturaFina(iMelhor), abs(coberturaFina(iMelhor) - cobertura(iMelhor))/100 * pFina.areaRegiao);
fprintf('Area exata do otimo teorico: %.4f km^2\n', cobOtima * pFina.areaRegiao);

fig1 = plotar_solucao(best, sprintf('Cenario %s - Melhor solucao geral (execucao %d)', cenario, iMelhor));
saveas(fig1, fullfile(pasta, 'melhor_solucao.png'));

% ---------------- Curvas de todas as execucoes ----------------
fig2 = figure('Name', 'Todas as execucoes', 'Color', 'w', 'Position', [150 150 1100 420]);
subplot(1, 2, 1); hold on; grid on;
for e = 1:numExecucoes
    plot(todos{e}.historico.melhorFitness, 'LineWidth', 1);
end
xlabel('Geracao'); ylabel('Melhor fitness');
title(sprintf('Cenario %s - Melhor fitness por geracao (10 execucoes)', cenario));

subplot(1, 2, 2); hold on; grid on;
for e = 1:numExecucoes
    plot(100*todos{e}.historico.melhorCobertura, 'LineWidth', 1);
end
xlabel('Geracao'); ylabel('Cobertura do melhor (%)');
title(sprintf('Cenario %s - Cobertura por geracao (10 execucoes)', cenario));
saveas(fig2, fullfile(pasta, 'curvas_execucoes.png'));

save(fullfile(pasta, 'experimentos.mat'), 'T', 'Estat', 'todos', 'params');
