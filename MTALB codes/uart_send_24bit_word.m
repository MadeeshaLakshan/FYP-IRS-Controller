% MATLAB script to send 24-bit word via UART
% Configure and send a 24-bit data word over serial port

function uart_send_24bit_word(data_word, port_name)
    % Default values
    if nargin < 2
        port_name = 'COM3';  % Change to your port (COM1, COM2, etc. on Windows; /dev/ttyUSB0 on Linux)
    end
    if nargin < 1
        data_word = 0xABCDEF;  % Default 24-bit test value
    end
    
    % Ensure data is within 24-bit range
    data_word = bitand(data_word, 0xFFFFFF);
    
    % Configure serial port
    s = serialport(port_name, 115200);  % 115200 baud rate
    configureTerminator(s, "LF");
    s.DataBits = 8;
    s.Parity = "none";
    s.StopBits = 1;
    s.FlowControl = "none";
    
    try
        % Split 24-bit word into 3 bytes (MSB first)
        byte1 = bitshift(bitand(data_word, 0xFF0000), -16);  % MSB
        byte2 = bitshift(bitand(data_word, 0x00FF00), -8);   % Middle byte
        byte3 = bitand(data_word, 0x0000FF);                 % LSB
        
        % Send bytes
        write(s, [byte3, byte2, byte1], "uint8");
        
        fprintf('Sent 24-bit word: 0x%06X\n', data_word);
        fprintf('Bytes sent: 0x%02X 0x%02X 0x%02X\n', byte1, byte2, byte3);
        
        % Optional: Wait for response or acknowledgment
        % response = read(s, 1, "uint8");
        
    catch ME
        fprintf('Error: %s\n', ME.message);
    end
    
    % Clean up
    clear s;
end

