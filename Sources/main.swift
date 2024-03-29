// Visualize analog values on the screen.
// The line height changes with the value from the potentiometer.

import SwiftIO
import MadBoard
import ST7789

// Initialize the I2C0 and the lcd.
let i2c = I2C(Id.I2C0)
let lcd = LCD1602(i2c)

// Humidity sensor
let sht = SHT3x(i2c)

// Initialize the SPI pin and the digital pins for the LCD.
let bl = DigitalOut(Id.D2)
let rst = DigitalOut(Id.D12)
let dc = DigitalOut(Id.D13)
let cs = DigitalOut(Id.D5)
let spi = SPI(Id.SPI0, speed: 30_000_000)

// Initialize the LCD using the pins above. Rotate the screen to keep the original at the upper left.
let screen = ST7789(spi: spi, cs: cs, dc: dc, rst: rst, bl: bl, rotation: .angle90)

// The max line height drawn on the screen.
let maxHeight = 220

let white: UInt16 = 0xFFFF
let black: UInt16 = 0

// Store the previous heights to make a scrolling display.
var heightValues = [Int](repeating: 0, count: screen.width)

while true {
    let temperature = sht.readCelsius()
    let temperatureTruncated: Double = Double(Int(temperature * 10)) / 10.0

    let humidity = sht.readHumidity()
    let humidityTruncated: Double = Double(Int(humidity * 10)) / 10.0

    // String(format:) is not available here - it is part of Foundation
    lcd.write(x: 0, y: 0, "Temperature:\(temperatureTruncated)")
    lcd.write(x: 0, y: 1, "Humidity:\(humidityTruncated)%")

    // Read current analog value and map it to height.
    let height = min(Int((humidity - 38) * 30), maxHeight)

    // Update line heights for display.
    heightValues.removeFirst()
    heightValues.append(height)

    // Iterate over the array to draw vertical lines with the given height.
    for i in 0 ..< heightValues.count - 1 {
        let lastHeight = heightValues[i]
        let currentHeight = heightValues[i + 1]

        // Compare the line heights and update the line.
        if lastHeight > currentHeight {
            drawLine(x: i, y: screen.height - lastHeight, height: lastHeight - currentHeight, color: black)
        } else if lastHeight < currentHeight {
            drawLine(x: i, y: screen.height - currentHeight, height: currentHeight - lastHeight, color: white)
        }
    }

    sleep(ms: 100)
}

// Draw a vertical line on the screen.
func drawLine(x: Int, y: Int, height: Int, color: UInt16) {
    let buffer = [UInt16](repeating: color, count: height)
    buffer.withUnsafeBytes {
        screen.writeBitmap(x: x, y: y, width: 1, height: height, data: $0)
    }
}