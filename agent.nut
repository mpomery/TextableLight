#require "Twilio.class.nut:1.0.1"
#require "utilities.lib.nut:3.0.1"

// As we are only responding, we can use null for our Twilio library config.
twilio <- Twilio(null, null, null);

ledStripLength <- 20; // Number of LEDs per short strip
ledsPerColour <- 2; // How many LEDs each colour should take

pixelColours <- array();

server.log(format("Twilio Webhook URL: %s/twilio", http.agenturl()));

// List of colour names and their hex codes
local knownColours = {"aqua":"00ffff",
    "black":"000000",
    "blue":"0000ff",
    "brown":"a52a2a",
    "cyan":"00ffff",
    "darkblue":"00008b",
    "darkgreen":"006400",
    "darkred":"8b0000",
    "fuchsia":"ff00ff",
    "gold":"ffd700",
    "goldenrod":"daa520",
    "gray":"808080",
    "green":"008000",
    "hotpink":"ff00b4",
    "indigo":"4b0082",
    "lavender":"e6e6fa",
    "lightblue":"add8e6",
    "lightgreen":"90ee90",
    "lime":"00ff00",
    "magenta":"ff00ff",
    "maroon":"800000",
    "navy":"000080",
    "orange":"ff4500",
    "pink":"ff00b4",
    "purple":"800080",
    "rebeccapurple":"663399",
    "red":"ff0000",
    "silver":"c0c0c0",
    "teal":"008080",
    "turquoise":"40e0d0",
    "violet":"ee82ee",
    "white":"ffffff",
    "yellow":"ffff00"
};

// Converts the input to a Hex Code using the above lookup table
function lookupColour(colour) {
    colour = colour.tolower()
    colour = split(colour, "#").reduce(@(a, b) a + b);
    colour = split(colour, " ").reduce(@(a, b) a + b);
    
    if (isHexCode(colour)) {
        return colour;
    }
    
    try {
        local c = knownColours[colour];
        return c;
    }
    catch (ex) {
        server.log(ex);
    }
}

// Check if a string is a hex code.
function isHexCode(input) {
    hexCharsExp <- regexp2("[0-9a-f]+");
    return input != null && input.len() == 6 && hexCharsExp.match(input);
}

// Convert a hex code to it's components.
function hexCodeToRGB(hexCode) {
    if (isHexCode(hexCode)) {
        local colourCompents = {};
        local hexBlob = utilities.hexStringToBlob(hexCode);
        colourCompents.red <- hexBlob[0];
        colourCompents.green <- hexBlob[1];
        colourCompents.blue <- hexBlob[2];
        
        return colourCompents;
    }
    else {
        server.log("Not a valid hexcode: " + hexCode);
        return null;
    }
}

// Take the input and add it to the light!
function addColourTolight(colour) {
    if (colour.len() > 20) {
        return "Error: Input too long!";
    }

    hexCode <- lookupColour(colour);
    colourCompents <- hexCodeToRGB(hexCode);
    
    if (colourCompents == null) {
        return format("Error: '%s' is not a known colour", colour);
    }
    
    // Check for a minimum intensity, then add it to the light!
    if (colourCompents.red + colourCompents.green + colourCompents.blue >= 100) {
        for (local i = 0; i < ledsPerColour; i++) {
            pixelColours.insert(0, [colourCompents.red, colourCompents.green, colourCompents.blue]);
        }
        
        if (pixelColours.len() > ledStripLength) {
            pixelColours.resize(ledStripLength, null);
        }
        
        return format("Successfully added %s to the light", colour);
    }
    else {
            return format("Error: '%s' is not bright enough", colour);
    }
}

function redraw()
{
    device.send("redraw", pixelColours);
}

// Handle Web Requests from Twilio!
function httpHandler(request, response) {
    local path = request.path.tolower();

    if (path == "/twilio" || path == "/twilio/") {
        try {
            server.log(request.body);
            local data = http.urldecode(request.body);
            local colourRequested = data.Body;
            local sender = data.From;
            
            local responseMessage = addColourTolight(colourRequested);
            redraw();

            twilio.respond(response, responseMessage);
        }
        catch(ex) {
            server.log("Uh oh, something went horribly wrong: " + ex);
            response.send(400, "Error");
        }
    }
    else {
        // Default response: 404 Error
        response.send(404, "Error");
    }
}
http.onrequest(httpHandler);

// If there is no array defined, start with a rainbow!
function onConnect() {
    if (pixelColours.len() == 0) {
        addColourTolight("red");
        addColourTolight("red");
        addColourTolight("orange");
        addColourTolight("orange");
        addColourTolight("yellow");
        addColourTolight("green");
        addColourTolight("blue");
        addColourTolight("indigo");
        addColourTolight("violet");
        addColourTolight("purple");
    }

    redraw();
}
device.onconnect(onConnect);