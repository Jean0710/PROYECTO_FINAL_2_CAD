% mod_8psk.m
% Esquema 1 - Paso 5: Modulación digital 8-PSK + canal multipath + BER
% Señal de sensores: temperatura, humedad y luz

clear; clc; close all;

% -------------------------
% Cargar señal original y comprimir
% -------------------------
load('raw_signal.mat');  % Variables: x y fs
mu = 255;
x_mu = compand(x, mu, max(abs(x)), 'mu/compressor');  % µ-law

% -------------------------
% Preparación de datos
% -------------------------
M = 8;                          % 8-PSK
k = log2(M);                   % bits por símbolo
x_norm = rescale(x_mu, 0, 1);  % llevar señal a [0,1]
symbols_q = round(x_norm * (2^k - 1));  % cuantización a 3 bits
data_bin = de2bi(symbols_q, k, 'left-msb');
data_tx = reshape(data_bin.', [], 1);

% Agrupar bits en símbolos
num_symbols = floor(length(data_tx)/k);
data_tx = data_tx(1:num_symbols * k);
bits_matrix = reshape(data_tx, k, []).';
symbols = bi2de(bits_matrix, 'left-msb');

% -------------------------
% Modulación 8-PSK
% -------------------------
mod_sig = pskmod(symbols, M, pi/M);  % con desplazamiento de fase Gray

% -------------------------
% Evaluación BER por canal
% -------------------------
EbN0_dB = 0:2:10;
ber_sim = zeros(size(EbN0_dB));

for i = 1:length(EbN0_dB)
    snr_db = EbN0_dB(i) + 10*log10(k);  % SNR total
    y = channel_mod(mod_sig, snr_db);  % Canal multipath + AWGN
    symbols_rx = pskdemod(y, M, pi/M);
    bits_rx = de2bi(symbols_rx, k, 'left-msb');
    bits_rx = reshape(bits_rx.', [], 1);

    ber_sim(i) = sum(bits_rx ~= data_tx) / length(data_tx);
end

% -------------------------
% Gráfica de constelación
% -------------------------
fig1 = figure;
plot(real(mod_sig), imag(mod_sig), 'o');
axis equal; grid on;
xlabel('Re'); ylabel('Im');
title('Constelación 8-PSK (Tx)');
saveas(fig1, 'constelacion_8psk.png');
disp('✅ Imagen guardada: constelacion_8psk.png');

% -------------------------
% Gráfica de BER
% -------------------------
fig2 = figure;
semilogy(EbN0_dB, ber_sim, 'o-r', 'LineWidth', 2);
grid on;
xlabel('Eb/No [dB]');
ylabel('BER');
title('Curva BER - Modulación 8-PSK con canal multipath');
saveas(fig2, 'ber_8psk.png');
disp('✅ Imagen guardada: ber_8psk.png');