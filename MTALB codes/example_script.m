% Example usage:
% Send specific 24-bit value
%uart_send_24bit_word(0x111111, 'COM7');
%pause(1);
% Send multiple test values
test_values = [0x000000, 0xFFFFFF, 0x123456, 0x654321, 0x101010,0x010101,0x555555,0x505055];
for i = 1:length(test_values)
    uart_send_24bit_word(test_values(i), 'COM7');
    pause(1);  % Small delay between transmissions
end