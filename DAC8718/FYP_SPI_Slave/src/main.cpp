/*#include <Arduino.h>
#include <ESP32SPISlave.h>

// SPI custom pins
# define SPI_MISO 19
# define SPI_MOSI 23
# define SPI_SCK 18
# define SPI_SS 5

// SPI settings
ESP32SPISlave slave;
// Queued transactions
static constexpr size_t QUEUE_SIZE = 1;
// Buffer size must be multiples of 4 bytes
static constexpr size_t BUFFER_SIZE = 32;
uint8_t rx_buf[BUFFER_SIZE];


void printBuffer(uint8_t* , int);

void setup() {
  Serial.begin(115200);
  delay(2000);
  //Initialize SPI bus with defined pins as SLAVE
  slave.setDataMode(SPI_MODE2); 
  slave.setQueueSize(QUEUE_SIZE);
  // VSPI or HSPI (virtual or hardward SPI)
  slave.begin(VSPI,SPI_SCK,SPI_MISO,SPI_MOSI,SPI_SS); 
  delay(2000);
  Serial.println("start spi slave");
}

void loop() {
  if (slave.hasTransactionsCompletedAndAllResultsHandled()) {
    slave.queue(NULL, rx_buf, BUFFER_SIZE);
    slave.trigger();
  }

  if (slave.hasTransactionsCompletedAndAllResultsReady(QUEUE_SIZE)) {
    size_t received_bytes = slave.numBytesReceived();
    Serial.printf("Received %d bytes: ", received_bytes);
    printBuffer(rx_buf, received_bytes);
  }
}

void printBuffer(uint8_t* buffer, int bufferSize) {
  for (int i = 0; i < bufferSize; ++i) {
    Serial.printf("%02X ", buffer[i]);
  }
  Serial.println();
}*/



#include <Arduino.h>
#include <ESP32SPISlave.h>

// SPI custom pins
#define SPI_MISO 19
#define SPI_MOSI 23
#define SPI_SCK 18
#define SPI_SS 5

// Packet configuration
#define BITS_PER_PACKET 24
#define NUM_PACKETS 8
#define BYTES_PER_PACKET (BITS_PER_PACKET / 8)
#define TOTAL_BYTES (BYTES_PER_PACKET * NUM_PACKETS)


uint32_t data24bit1 = 0x000000;
uint32_t data24bit2 = 0xFFFFFF;
uint32_t data24bit3 = 0x010101;

// SPI settings
ESP32SPISlave slave;
// Keep queue size as in original code
static constexpr size_t QUEUE_SIZE = 1;
// Increased buffer size to handle larger packets
static constexpr size_t BUFFER_SIZE = 64;  // Larger buffer to capture more data
uint8_t rx_buf[BUFFER_SIZE];

// Variables to track packets
uint32_t total_bytes_received = 0;
uint8_t all_packets[TOTAL_BYTES];
uint8_t packet_count = 0;
bool data_received = false;

/*FUNCTION DECLARATION-----------------------------------------------------------*/
void printBuffer(uint8_t* buffer, int bufferSize);
void printPacket(uint8_t* buffer, int start, int packetSize);
void processReceivedData(uint8_t* buffer, size_t bytesReceived);
void send24bitData(uint32_t data);
/*-------------------------------------------------------------------------------*/

/*VOID SETUP CONFIGURATION-------------------------------------------------------*/
void setup() {
  Serial.begin(115200);
  delay(2000);
  
  
  // Initialize SPI bus with defined pins as SLAVE
  slave.setDataMode(SPI_MODE3);
  slave.setQueueSize(QUEUE_SIZE);
  
  // VSPI or HSPI (virtual or hardware SPI)
  slave.begin(VSPI, SPI_SCK, SPI_MISO, SPI_MOSI, SPI_SS);
  
  delay(2000);
  Serial.println("SPI Slave Started - Ready to receive 8 x 24-bit packets");
  Serial.println("------------------------------------------------------");
  
  // Queue up the first transaction
  slave.queue(NULL, rx_buf, BUFFER_SIZE);
  slave.trigger();
}
/*-------------------------------------------------------------------------------*/

/*LOOP---------------------------------------------------------------------------*/
void loop() {


  // Check if we need to queue a transaction
  if (slave.hasTransactionsCompletedAndAllResultsHandled()) {
    // Queue a new transaction first to be ready for next data
    slave.queue(NULL, rx_buf, BUFFER_SIZE);
    slave.trigger();
  }

  // Process received data if available
  if (slave.hasTransactionsCompletedAndAllResultsReady(QUEUE_SIZE)) {
    size_t received_bytes = slave.numBytesReceived();
    
    if (received_bytes > 0) {
      Serial.printf("Received %d bytes: ", received_bytes);
      processReceivedData(rx_buf, received_bytes);
      data_received = true;
    }
  }
}
/*-------------------------------------------------------------------------------*/

/*FUNCTION: Process received data------------------------------------------------*/
void processReceivedData(uint8_t* buffer, size_t bytesReceived) {
  // Store received bytes in our collection buffer
  if (total_bytes_received + bytesReceived <= TOTAL_BYTES) {
    memcpy(&all_packets[total_bytes_received], buffer, bytesReceived);
    total_bytes_received += bytesReceived;
  }
  
  // Print current received data
  printBuffer(buffer, bytesReceived);
    
  // Calculate how many complete packets we have
  int packets_in_buffer = bytesReceived / BYTES_PER_PACKET;
  packet_count += packets_in_buffer;
    
  // Check if we have any complete packets to process
  if (packets_in_buffer > 0) {
    Serial.printf("Received %d complete 24-bit packet(s)\n", packets_in_buffer);
        
    // Print each packet as 24-bit value
    for (int i = 0; i < packets_in_buffer; i++) {
      Serial.printf("Packet data: ");
      printPacket(buffer, i * BYTES_PER_PACKET, BYTES_PER_PACKET);
    }
  }
    
  // If we have any partial packet data
  int remaining = bytesReceived % BYTES_PER_PACKET;
  if (remaining > 0) {
    Serial.printf("Partial packet data (%d bytes)\n", remaining);
  }
    
  // Check if we've received all expected packets
  if (packet_count >= NUM_PACKETS) {
    Serial.println("\n=== All expected packets received ===");
    Serial.println("Complete data:");
    printBuffer(all_packets, total_bytes_received);
    Serial.println("------------------------------------------------------");
        
    // Reset for next batch
    total_bytes_received = 0;
    packet_count = 0;
    memset(all_packets, 0, TOTAL_BYTES);
  }
}
/*-------------------------------------------------------------------------------*/

/*FUNCTION: Print a single packet in hex format----------------------------------*/
void printPacket(uint8_t* buffer, int start, int packetSize) {
  uint32_t value = 0;
  
  // Combine bytes into a 24-bit value (big-endian)
  for (int i = 0; i < packetSize; i++) {
    value = (value << 8) | buffer[start + i];
  }
  
  // Print as a 24-bit hex value
  Serial.printf("0x%06X\n", value);
}
/*-------------------------------------------------------------------------------*/

/*FUNCTION: Print received buffer in hex format----------------------------------*/
void printBuffer(uint8_t* buffer, int bufferSize) {
  for (int i = 0; i < bufferSize; ++i) {
    Serial.printf("%02X ", buffer[i]);
  }
  Serial.println();
}
/*-------------------------------------------------------------------------------*/
void send24bitData(uint32_t data) {
  // Mask and shift to get each byte
  uint8_t byte1 = (data >> 16) & 0xFF; // Most significant byte
  uint8_t byte2 = (data >> 8) & 0xFF;  // Middle byte
  uint8_t byte3 = data & 0xFF;         // Least significant byte

  // Send bytes over UART
  Serial.write(byte1);
  Serial.write(byte2);
  Serial.write(byte3);
}