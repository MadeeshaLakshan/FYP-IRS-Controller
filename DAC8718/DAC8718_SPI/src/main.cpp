#include <Arduino.h>
#include <SPI.h>

// Pin definitions for ESP32 to DAC8718
#define SPI_SCK  18    // Serial Clock
#define SPI_MISO 19    // Master In Slave Out - Not used for write operations but defined for completeness
#define SPI_MOSI 23    // Master Out Slave In
#define SPI_CS   5     // Chip Select
#define LDAC_PIN 4     // Load DAC pin - optional, used to update all DACs simultaneously

// DAC8718 register addresses
#define DAC_REG_CONFIG      0x00
#define DAC_REG_DAC0        0x08  // DAC0 register
#define DAC_REG_DAC1        0x09  // DAC1 register
#define DAC_REG_DAC2        0x0A  // DAC2 register
#define DAC_REG_DAC3        0x0B  // DAC3 register
#define DAC_REG_DAC4        0x0C  // DAC4 register
#define DAC_REG_DAC5        0x0D  // DAC5 register
#define DAC_REG_DAC6        0x0E  // DAC6 register
#define DAC_REG_DAC7        0x0F  // DAC7 register

// Command modes
#define CMD_WRITE           0     // Write command (bit 23 = 0)
#define CMD_READ            1     // Read command (bit 23 = 1)

//Function prototypes
void writeDACRegister(uint8_t reg, uint16_t data);
void writeDAC(uint8_t channel, uint16_t value);
void updateAllDACs();

void setup() {
  Serial.begin(115200);
  while (!Serial) {
    ; // Wait for serial port to connect
  }
  
  // Initialize SPI
  SPI.begin(SPI_SCK, SPI_MISO, SPI_MOSI, SPI_CS);
  SPI.beginTransaction(SPISettings(1000000, MSBFIRST, SPI_MODE2));
  
  // Configure pins
  pinMode(SPI_CS, OUTPUT);
  digitalWrite(SPI_CS, HIGH);  // Deselect DAC
  
  if (LDAC_PIN >= 0) {
    pinMode(LDAC_PIN, OUTPUT);
    digitalWrite(LDAC_PIN, HIGH);  // LDAC high initially
  }
  Serial.println("DAC8718 initialized");
}

void loop() {
  // Example of setting different values to all 8 DAC outputs
  uint16_t dacValues[8] = {
    0,              // DAC0: 0V
    16383,          // DAC1: ~2.5V (mid-scale)
    32767,          // DAC2: ~5V (full-scale)
    8192,           // DAC3: ~1.25V (quarter-scale)
    24576,          // DAC4: ~3.75V (three-quarter-scale)
    4096,           // DAC5: ~0.625V (one-eighth-scale)
    28672,          // DAC6: ~4.375V (seven-eighth-scale)
    16384           // DAC7: ~2.5V (mid-scale)
  };
  
  // Write values to all DAC channels
  for (int i = 0; i < 8; i++) {
    writeDAC(i, dacValues[i]);
    Serial.printf("DAC%d set to %d (%.2fV)\n", i, dacValues[i], (dacValues[i] / 65535.0) * 5.0); // Assuming 5V reference
  }
  
  // If using LDAC pin, trigger update on all channels simultaneously
  if (LDAC_PIN >= 0) {
    updateAllDACs();
  }
  
  delay(5000);  // Wait 5 seconds before changing values
  
  // Create a ramp pattern
  for (int i = 0; i < 8; i++) {
    dacValues[i] = (i * 4681);  // Spread values across the range (0 to ~32767)
    writeDAC(i, dacValues[i]);
    Serial.printf("DAC%d set to %d (%.2fV)\n", i, dacValues[i], (dacValues[i] / 65535.0) * 5.0);
  }
  
  // Update all DACs simultaneously if using LDAC pin
  if (LDAC_PIN >= 0) {
    updateAllDACs();
  }
  
  delay(5000);  // Wait 5 seconds before repeating
}

// Function to write a 24-bit command to the DAC
void writeDACRegister(uint8_t reg, uint16_t data) {
  uint32_t command = 0;
  
  // Format the 24-bit command:
  // Bit 23: R/W (0 for write)
  // Bit 22-21: Not used (0)
  // Bit 20-16: Register address (5 bits)
  // Bit 15-0: Data (16 bits)
  command = (CMD_WRITE << 23) | ((reg & 0x1F) << 16) | (data & 0xFFFF);
  
  // Select the DAC
  digitalWrite(SPI_CS, LOW);
  
  // Send the 24-bit command in 3 bytes (MSB first)
  SPI.transfer((command >> 16) & 0xFF);  // Send bits 23-16
  SPI.transfer((command >> 8) & 0xFF);   // Send bits 15-8
  SPI.transfer(command & 0xFF);          // Send bits 7-0
  
  // Deselect the DAC
  digitalWrite(SPI_CS, HIGH);
}

// Write a value to a specific DAC channel (0-7)
void writeDAC(uint8_t channel, uint16_t value) {
  if (channel > 7) return;  // Validate channel
  
  // Write to the DAC register (DAC0 through DAC7)
  writeDACRegister(DAC_REG_DAC0 + channel, value);
}

// Update all DACs simultaneously using LDAC pin
void updateAllDACs() {
  if (LDAC_PIN >= 0) {
    digitalWrite(LDAC_PIN, LOW);
    delayMicroseconds(1);  // Pulse width minimum 20ns
    digitalWrite(LDAC_PIN, HIGH);
  }
}

