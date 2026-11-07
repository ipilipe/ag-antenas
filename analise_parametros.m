%% ANALISE_PARAMETROS - Efeito dos parametros do AG nos resultados
% Varia um parametro por vez (os outros ficam no padrao) e roda
% algumas execucoes para cada valor. Serve de base para a secao
% "efeito dos parametros" do relatorio.

clear; clc; close all;

execPorConfig = 5;

base = struct();
base.areaRegiao       = 200;
base.raio             = 10;
base.maxAntenas       = 5;
base.numGeracoes      = 100;
base.mostrarProgresso = false;

experimentos = {
    'tamPopulacao',     [10 30 60 100]
    'taxaCruzamento',   [0.0 0.5 0.85 1.0]
    'taxaMutacao',      [0.01 0.05 0.15 0.40]
    'numElite',         [0 1 2 5]
    'penalidadeAntena', [0.0 0.01 0.05 0.20]
};

if ~exist('resultados', 'dir')
    mkdir('resultados');
end

linhas = {};
figure('Name', 'Analise de parametros', 'Color', 'w', 'Position', [100 100 1300 650]);

for k = 1:size(experimentos, 1)
    nome    = experimentos{k, 1};
    valores = experimentos{k, 2};
    curvaMedia = zeros(base.numGeracoes, numel(valores));

    for v = 1:numel(valores)
        fitV = zeros(execPorConfig, 1);
        cobV = zeros(execPorConfig, 1);
        antV = zeros(execPorConfig, 1);
        for e = 1:execPorConfig
            params = base;
            params.(nome) = valores(v);
            params.semente = 1000*k + 10*v + e;
            res = ga_antenas(params);
            fitV(e) = res.melhor.fitness;
            cobV(e) = 100 * res.melhor.cobertura;
            antV(e) = res.melhor.numAntenas;
            curvaMedia(:, v) = curvaMedia(:, v) + res.historico.melhorFitness / execPorConfig;
        end
        linhas(end+1, :) = {nome, valores(v), mean(fitV), std(fitV), mean(cobV), mean(antV)}; %#ok<SAGROW>
        fprintf('%-17s = %6.3f | fitness = %.4f (dp %.4f) | cobertura = %6.2f%% | antenas = %.1f\n', ...
            nome, valores(v), mean(fitV), std(fitV), mean(cobV), mean(antV));
    end

    subplot(2, 3, k); hold on; grid on;
    for v = 1:numel(valores)
        plot(curvaMedia(:, v), 'LineWidth', 1.3);
    end
    legenda = arrayfun(@(x) sprintf('%s = %g', nome, x), valores, 'UniformOutput', false);
    legend(legenda, 'Location', 'southeast', 'FontSize', 7);
    xlabel('Geracao'); ylabel('Melhor fitness (media)');
    title(nome);
end

R = cell2table(linhas, 'VariableNames', ...
    {'Parametro', 'Valor', 'FitnessMedio', 'FitnessDP', 'CoberturaMediaPct', 'AntenasMedia'});
disp(R);
writetable(R, fullfile('resultados', 'analise_parametros.csv'));
saveas(gcf, fullfile('resultados', 'analise_parametros.png'));
