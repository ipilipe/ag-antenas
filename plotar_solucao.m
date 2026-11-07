function fig = plotar_solucao(res, titulo)
% PLOTAR_SOLUCAO  Mostra a regiao, as antenas, a cobertura e a evolucao do AG.
%
%   fig = plotar_solucao(res)
%   fig = plotar_solucao(res, 'Titulo da figura')

    if nargin < 2
        titulo = 'Algoritmo Genetico - Posicionamento de Antenas';
    end

    p  = res.params;
    m  = res.melhor;
    hs = res.historico;
    L  = p.lado;

    fig = figure('Name', titulo, 'Color', 'w', 'Position', [100 100 1300 480]);

    % ---------------- 1) Regiao e antenas ----------------
    subplot(1, 3, 1);
    hold on; axis equal; box on;

    % Mapa de cobertura (pontos da grade cobertos por pelo menos 1 antena)
    coberto = false(size(res.grade.GX));
    for j = find(m.ativo)
        coberto = coberto | ((res.grade.GX - m.x(j)).^2 + (res.grade.GY - m.y(j)).^2 <= p.raio^2);
    end
    n = p.resolucao;
    mapa = reshape(coberto, n, n);
    imagesc([res.grade.GX(1) res.grade.GX(end)], [res.grade.GY(1) res.grade.GY(end)], mapa);
    colormap(gca, [1 1 1; 0.70 0.85 1.00]);   % branco = sem sinal, azul = coberto
    set(gca, 'YDir', 'normal');

    % Circulos completos de cada antena (tracejado)
    t = linspace(0, 2*pi, 300);
    cores = lines(p.maxAntenas);
    k = 0;
    for j = find(m.ativo)
        k = k + 1;
        plot(m.x(j) + p.raio*cos(t), m.y(j) + p.raio*sin(t), '--', 'Color', cores(k, :), 'LineWidth', 1.2);
        plot(m.x(j), m.y(j), '^', 'MarkerSize', 10, 'MarkerFaceColor', cores(k, :), 'MarkerEdgeColor', 'k');
        text(m.x(j), m.y(j), sprintf('  A%d (%.2f; %.2f)', k, m.x(j), m.y(j)), 'FontSize', 8);
    end

    % Borda da regiao
    rectangle('Position', [0 0 L L], 'EdgeColor', 'k', 'LineWidth', 2);

    margem = p.raio;
    xlim([-margem, L + margem]);
    ylim([-margem, L + margem]);
    xlabel('x (km)'); ylabel('y (km)');
    title(sprintf('%d antena(s) | cobertura %.2f%% | %.2f de %.2f km^2', ...
        m.numAntenas, 100*m.cobertura, m.areaCoberta, p.areaRegiao));

    % ---------------- 2) Evolucao do fitness ----------------
    subplot(1, 3, 2);
    plot(hs.melhorFitness, 'LineWidth', 2); hold on;
    plot(hs.mediaFitness, 'LineWidth', 1.2);
    grid on;
    xlabel('Geracao'); ylabel('Fitness');
    legend('Melhor', 'Media da populacao', 'Location', 'southeast');
    title('Evolucao do fitness');

    % ---------------- 3) Evolucao da area coberta ----------------
    subplot(1, 3, 3);
    yyaxis left;
    plot(100*hs.melhorCobertura, 'LineWidth', 2);
    ylabel('Cobertura do melhor (%)');
    yyaxis right;
    stairs(hs.melhorNumAntenas, 'LineWidth', 1.2);
    ylabel('Antenas do melhor');
    ylim([0, p.maxAntenas + 1]);
    grid on;
    xlabel('Geracao');
    title('Area coberta e numero de antenas');

    sgtitle(titulo);
end
