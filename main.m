%% MAIN - Execucao unica do Algoritmo Genetico (ideal para o video)
% Altere os parametros abaixo e rode o script (F5).

clear; clc; close all;

params = struct();

% ---- Problema ----
params.areaRegiao  = 200;   % km^2 (regiao quadrada no 1o quadrante)
params.raio        = 10;    % km
params.maxAntenas  = 5;

% ---- Fitness ----
params.pesoCobertura    = 1.0;
params.penalidadeAntena = 0.05;

% ---- Algoritmo Genetico ----
params.tamPopulacao        = 60;
params.numGeracoes         = 150;
params.taxaCruzamento      = 0.85;
params.taxaMutacao         = 0.15;
params.taxaMutacaoAtivacao = 0.05;
params.numElite            = 2;
params.tamTorneio          = 3;
params.semente             = [];   % coloque um numero (ex.: 42) para repetir o resultado

tic;
res = ga_antenas(params);
tempo = toc;

m = res.melhor;
fprintf('\n================ MELHOR SOLUCAO ================\n');
fprintf('Lado da regiao      : %.4f km\n', res.params.lado);
fprintf('Antenas utilizadas  : %d\n', m.numAntenas);
for k = 1:size(m.posicoes, 1)
    fprintf('  Antena %d          : (%.4f ; %.4f) km\n', k, m.posicoes(k, 1), m.posicoes(k, 2));
end
fprintf('Area coberta        : %.4f km^2 de %.2f km^2\n', m.areaCoberta, res.params.areaRegiao);
fprintf('Percentual coberto  : %.2f%%\n', 100*m.cobertura);
fprintf('Fitness             : %.4f\n', m.fitness);
fprintf('Tempo de execucao   : %.2f s\n', tempo);

plotar_solucao(res);

% ---- Animacao da evolucao (otimo para o video) ----
mostrarAnimacao = true;
gravarVideo     = false;   % true grava "evolucao.mp4" na pasta atual
if mostrarAnimacao
    if gravarVideo
        animar_evolucao(res, 2, 'evolucao.mp4');
    else
        animar_evolucao(res, 2);
    end
end
