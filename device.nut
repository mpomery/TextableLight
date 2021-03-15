#require "WS2812.class.nut:3.0.0"

ledStripCount <- 4; // Number of short strips you have
ledStripLength <- 20; // Number of LEDs per short strip
totalLedCount <- ledStripLength * ledStripCount;

spi <- hardware.spi257;
pixels <- WS2812(spi, totalLedCount);

function redraw(pixelColours) {
    server.log("Updating the light!");
    
    for (local i = 0; i < pixelColours.len(); i++) {
        for (local j = 0; j < ledStripCount; j++)
        {
            local pixelNum = (j * ledStripLength) + i;
            local colour = pixelColours[pixelColours.len() - (i + 1)]
            pixels.set(pixelNum, colour);
        }
    }
    pixels.draw();
}
agent.on("redraw", redraw);