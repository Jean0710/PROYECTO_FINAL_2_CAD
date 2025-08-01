% ofdm.m
% Esquema 1 - Paso 6: OFDM con 64 subportadoras, 8-PSK interna
% Incluye PSD, PAPR y comparación de BER con 8-PSK sin OFDM

clear; clc; close all;

% -------------------------
% Cargar señal original y comprimir
% -------------------------
load('raw_signal.mat');
mu = 255;
x_mu = compand(x, mu, max(abs(x)), 'mu/compressor');

% -------------------------
% Codificación binaria (8-PSK)
% -------------------------
M = 8;
k = log2(M);
x_norm = rescale(x_mu, 0, 1);
symbols_q = round(x_norm * (2^k - 1));
data_bin = de2bi(symbols_q, k, 'left-msb');
tx_bits = reshape(data_bin.', [], 1);

% -------------------------
% Parámetros OFDM
% -------------------------
N = 64; cp_len = 16;
num_bits = floor(length(tx_bits)/(k*N)) * k*N;
tx_bits = tx_bits(1:num_bits);
symbols = bi2de(reshape(tx_bits, k, []).', 'left-msb');
mod_data = pskmod(symbols, M, pi/M);

% Organizar en bloques OFDM
num_blocks = length(mod_data)/N;
mod_blocks = reshape(mod_data, N, []);

pilot = 1 + 1i;
ofdm_tx = [];

for i = 1:num_blocks
    block = mod_blocks(:, i);
    block(1) = pilot;
    block_time = ifft(block, N);
    cp = block_time(end - cp_len + 1:end);
    ofdm_symbol = [cp; block_time];
    ofdm_tx = [ofdm_tx; ofdm_symbol];
end

% -------------------------
% Canal multipath + AWGN
% -------------------------
EbN0_dB = 0:2:10;
ber_ofdm = zeros(size(EbN0_dB));
ber_psk = zeros(size(EbN0_dB));

for i = 1:length(EbN0_dB)
    snr_db = EbN0_dB(i) + 10*log10(k);
    
    % ---- Transmisión directa 8-PSK (Paso 5) ----
    y1 = channel_mod(mod_data, snr_db);
    sym_rx1 = pskdemod(y1, M, pi/M);
    bits_rx1 = de2bi(sym_rx1, k, 'left-msb');
    bits_rx1 = reshape(bits_rx1.', [], 1);
    ber_psk(i) = sum(bits_rx1 ~= tx_bits(1:length(bits_rx1))) / length(bits_rx1);

    % ---- Transmisión OFDM ----
    y2 = channel_mod(ofdm_tx, snr_db);
    ofdm_rx = reshape(y2, N + cp_len, []);
    ofdm_rx = ofdm_rx(cp_len+1:end, :);
    rx_symbols = fft(ofdm_rx, N);
    rx_symbols = rx_symbols(2:end, :); % quitar piloto (posición 1)
    data_rx = rx_symbols(:);
    
    sym_rx2 = pskdemod(data_rx, M, pi/M);
    bits_rx2 = de2bi(sym_rx2, k, 'left-msb');
    bits_rx2 = reshape(bits_rx2.', [], 1);
    ber_ofdm(i) = sum(bits_rx2 ~= tx_bits(1:length(bits_rx2))) / length(bits_rx2);
end

% -------------------------
% PSD
% -------------------------
figure;
Yf = abs(fftshift(fft(ofdm_tx)));
f = linspace(-fs/2, fs/2, length(Yf));
plot(f, 20*log10(Yf));
xlabel('Frecuencia [Hz]'); ylabel('Magnitud [dB]');
title('PSD - Señal OFDM transmitida');
grid on;
saveas(gcf, 'psd_ofdm.png');

% -------------------------
% PAPR
% -------------------------
figure;
power = abs(ofdm_tx).^2;
papr = max(power) / mean(power);
plot(power, 'b');
hold on;
yline(mean(power), '--g', 'Media');
yline(max(power), '--r', 'Máximo');
xlabel('Muestra'); ylabel('Potencia');
title(sprintf('PAPR = %.2f', papr));
legend('Potencia', 'Media', 'Pico');
grid on;
saveas(gcf, 'papr_ofdm.png');

% -------------------------
% Comparación BER
% -------------------------
figure;
semilogy(EbN0_dB, ber_psk, 's-b', 'LineWidth', 2); hold on;
semilogy(EbN0_dB, ber_ofdm, 'o-r', 'LineWidth', 2);
grid on;
xlabel('Eb/No [dB]');
ylabel('BER');
title('BER: 8-PSK directa vs OFDM 8-PSK');
legend('8-PSK directa', 'OFDM 8-PSK');
saveas(gcf, 'ber_comparativa_ofdm.png');