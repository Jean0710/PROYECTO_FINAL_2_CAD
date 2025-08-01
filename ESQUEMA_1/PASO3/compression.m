% compression.m
% Esquema 1 - Paso 3: Compresión Wavelet + µ-law
% Señal combinada de sensores: temperatura, humedad y luz
% Entregables: compression.m, compression_metrics.csv

clear; clc; close all;

% -------------------------
% Cargar señal original
% -------------------------
load('raw_signal.mat');  % Variables: x (3 sensores), fs

% -------------------------
% Parámetros de compresión
% -------------------------
mu = 255;                      % µ-law parameter
wavelet_name = 'db4';          % Tipo de wavelet
n_level = 4;                   % Niveles de descomposición

% -------------------------
% 1. Compresión Wavelet
% -------------------------
[c, l] = wavedec(x, n_level, wavelet_name);  % descomposición DWT
x_wavelet_rec = waverec(c, l, wavelet_name); % reconstrucción
mse_wavelet = mean((x - x_wavelet_rec).^2);  % error cuadrático medio

% -------------------------
% 2. Compresión µ-law sobre señal reconstruida de wavelet
% -------------------------
x_mu = compand(x_wavelet_rec, mu, max(abs(x_wavelet_rec)), 'mu/compressor');
x_mu_rec = compand(x_mu, mu, max(abs(x_wavelet_rec)), 'mu/expander');

% -------------------------
% Métricas de compresión
% -------------------------
mse_total = mean((x - x_mu_rec).^2);        % Error total
bits_original = numel(x) * 16;              % Supone 16 bits/muestra sin comprimir
bits_compressed = numel(x_mu) * 8;          % Supone 8 bits/muestra comprimida
compression_ratio = bits_original / bits_compressed;

% -------------------------
% Mostrar resultados
% -------------------------
fprintf('\n📦 COMPRESIÓN DE SEÑAL (Sensores: temperatura, humedad, luz)\n');
fprintf('MSE solo Wavelet      : %.6f\n', mse_wavelet);
fprintf('MSE total (Wavelet + µ-law): %.6f\n', mse_total);
fprintf('Razón de compresión   : %.2f : 1\n', compression_ratio);

% -------------------------
% Exportar resultados a CSV
% -------------------------
T = table(mse_wavelet, mse_total, compression_ratio, ...
    'VariableNames', {'MSE_Wavelet', 'MSE_Total', 'Compression_Ratio'});

writetable(T, 'compression_metrics.csv');
disp('✅ Tabla exportada como compression_metrics.csv');