import QtQuick 
import QtQuick.Controls 
import QtQuick.Layouts
import org.qfield
import org.qgis

import Theme

import "qrc:/qml" as QFieldItems

Item {
 id: plugin

 property var canvas: iface.mapCanvas().mapSettings
 property var mainWindow: iface.mainWindow()
 property var dashBoard: iface.findItemByObjectName('dashBoard')
 property var overlayFeatureFormDrawer: iface.findItemByObjectName('overlayFeatureFormDrawer')
 property var positionSource: iface.findItemByObjectName('positionSource')
 property var canvasCrs : canvas.destinationCrs ;
 //property var crsGeo : canvasCrs.isGeographic // is the canvas Geogrpahic (true (deg)) or projected (false (m))
 property var canvasEPSG : parseInt(canvas.project.crs.authid.split(":")[1]); // Canvas CRS
 property var mapCanvas: iface.mapCanvas()
 property var geometryHighlighter: iface.findItemByObjectName('geometryHighlighter')



//changable stuff 
//default values
property var fsize : "15" // general font size
property var zoomV : "4" // zoom level 
property var decm : "0"  // decimal places for meter coordinates
property var decd : "5"  // decimal places for degree coordinates
  
 //Default visibility of various boxes
property var igvis: true // visibility of Irish grid
property var ukgvis: false // visibility of UK grid
property var custom1vis: false // visibility of custom1
property var custom2vis: false // visibility of custom2 
property var wgs84vis: false // visibility of wgs84 // always visible
property var dmvis: true // visibility of DM
property var dmsvis: false // visibility of DMS
property var dmsBoxesvis: true // visibility of DMS boxes
property var customisationvis: false // visibility of customisation
property var crosshairvis: true // visibility of crosshair
// for testing:
property var degwa : "70"  // width of degree input box when no decimals in it
property var minwa : "70"  // width of minute input box when no decimals in degree box



 Component.onCompleted: {
    iface.addItemToPluginsToolbar(digitizeButton)
    igukGridsFilter2.locatorBridge.registerQFieldLocatorFilter(igukGridsFilter2);
    }

 Component.onDestruction: { 
    igukGridsFilter2.locatorBridge.deregisterQFieldLocatorFilter(igukGridsFilter2);
    }   


// Irish Grid/ UK Grid Locator Filter
QFieldLocatorFilter {
    id: igukGridsFilter2
    delay: 1000
    name: "IG & UK Grids"
    displayName: "IG & UK Grid finder"
    prefix: "grid"
    locatorBridge: iface.findItemByObjectName('locatorBridge')
    source: Qt.resolvedUrl('plugin_stuff/grids.qml')
    

function triggerResult(result) {
  if (result.userData && result.userData.geometry) {
    const geometry = result.userData.geometry;
    const crs = CoordinateReferenceSystemUtils.fromDescription(result.userData.crs);

    // Reproject the geometry to the map's CRS
    const reprojectedGeometry = GeometryUtils.reprojectPoint(
      geometry,
      crs,
      mapCanvas.mapSettings.destinationCrs
    );

    // Center the map on the reprojected geometry
   mapCanvas.mapSettings.setCenter(reprojectedGeometry, true);

    // Highlight the geometry on the map
    var pointGeometry = GeometryUtils.createGeometryFromWkt(`POINT(${mapCanvas.mapSettings.center.x} ${mapCanvas.mapSettings.center.y})`);
    geometryHighlighter.geometryWrapper.qgsGeometry = pointGeometry;

  } else {
    mainWindow.displayToast("Invalid geometry in result");
  }
}
function triggerResultFromAction(result, actionId) {
  if (result.userData && result.userData.geometry) {
    const geometry = result.userData.geometry;
    const crs = CoordinateReferenceSystemUtils.fromDescription(result.userData.crs);

    // Reproject the geometry to the map's CRS
    const reprojectedPoint = GeometryUtils.reprojectPoint(
      geometry,
      crs,
      mapCanvas.mapSettings.destinationCrs
    );

    if (actionId === 1) {
      // Set the navigation destination
      const navigation = iface.findItemByObjectName('navigation');
      if (navigation) {
        navigation.destination = reprojectedPoint;
        mainWindow.displayToast("Destination set successfully");
      } else {
        mainWindow.displayToast("Navigation component not found");
      }

    } else if (actionId === 2) {
      // Ensure an 'Points' layer is selected
        if (!dashBoard.activeLayer || dashBoard.activeLayer.name != 'Points') {
        mainWindow.displayToast(qsTr("Select 'Points' layer and try again"));
        dashBoard.open();
        return;
        }
      
       // Create the geometry 
      var reprojectedGeometry = GeometryUtils.createGeometryFromWkt(`POINT(${reprojectedPoint.x} ${reprojectedPoint.y})`)
       
      // Create a new feature
      var feature = FeatureUtils.createFeature(dashBoard.activeLayer, reprojectedGeometry);

      // Open the form for the new feature
      overlayFeatureFormDrawer.featureModel.feature = feature;
      overlayFeatureFormDrawer.state = "Add";
      overlayFeatureFormDrawer.open();
    }
  } else {
    mainWindow.displayToast("Invalid action or geometry");
  }
  
}
}   




//small crosshair
 Rectangle{
 id: crosshair
 visible: true 
 parent: iface.mapCanvas()
 color: "transparent"
 border.color: "grey"
 width: 20
 height:20
 border.width: 1 
 radius: width / 2
 x: (mainWindow.width - width) / 2
 y: (mainWindow.height - height) / 2
 
 // Center the crosshair on the map canvas
 anchors.centerIn: parent

 // Crosshair lines
 Rectangle {
 width: parent.width 
 height: 1
 color: "grey"
 anchors.verticalCenter: parent.verticalCenter
 }
 Rectangle {
 width: 1
 height: parent.height 
 color: "grey"
 anchors.horizontalCenter: parent.horizontalCenter
 }
 } 

QfToolButton {
 id: digitizeButton
 bgcolor: Theme.darkGray
 iconSource: 'plugin_stuff/icon2.svg'
 round: true 
 onClicked: { mainDialog.open() }}
 



Dialog {
 id: mainDialog
 parent: mainWindow.contentItem
 visible: false
 modal: true
 font: Theme.defaultFont
 Layout.preferredHeight: 35
 width: 350


 x: (mainWindow.width - width) / 2
 y: (mainWindow.height - height) / 2

 ColumnLayout {
 anchors.fill: parent
 anchors.margins : 1



RowLayout{
 Layout.fillWidth: true
 Label {
 id: label_1
 visible: true
 font.bold: true
 wrapMode: Text.Wrap
 text: qsTr("Grab:")
 font.pixelSize: font_Size.text
 font.family: "Arial" // Set font family
 font.italic: true // Make text italic
 } 

Button {
 text: qsTr("Screencenter")
 font.bold: true
  Layout.fillWidth: true
 font.pixelSize: font_Size.text 
 font.family: "Arial"
 font.italic: true
 Layout.preferredHeight: 35 
 onClicked: {
 var pos = canvas.center
 updateCoordinates(pos.x, pos.y, canvasEPSG, custom1CRS.text, custom2CRS.text)
 } 
 } 

 
 Button {
 text: qsTr("GPS")
 font.bold: true
  Layout.fillWidth: true
 font.pixelSize: font_Size.text 
 Layout.preferredHeight: 35 
 property bool isPositionValid: positionSource.active && positionSource.positionInformation.latitudeValid && positionSource.positionInformation.longitudeValid

 onClicked: {
 if (!isPositionValid) {
 mainWindow.displayToast(qsTr("GPS must be active"))} else 
 { 
 var pos = positionSource.projectedPosition
 updateCoordinates(pos.x, pos.y, canvasEPSG, custom1CRS.text, custom2CRS.text) 
 }
 }
 }
     CheckBox {
        id: showCustomisation
        checked: false
        onCheckedChanged: {
        customisation.visible = checked
        }
    } 
}


ColumnLayout{
visible: true 
//spacing: 1

// Irish Grid
RowLayout{
    id: igridrow
    visible: igvis

TextField {
 id: igInputBox //1
 Layout.preferredHeight: 35
 font.pixelSize: font_Size.text 
 font.family: "Arial"
 font.bold: true
 font.italic: true
 Layout.fillWidth: true
 placeholderText: "Irish Grid: X 00000 00000"
 property bool isProgrammaticUpdate: false
 // Custom validation logic
 onTextChanged: {

    if (isProgrammaticUpdate) {
 // Skip validation if the text is being updated programmatically
 isProgrammaticUpdate = false
 return
 }
   igInputBox.placeholderText  = "IG"
 // Remove any non-alphanumeric characters (except spaces)
 var cleanedText = igInputBox.text.replace(/[^A-Za-z0-9\s]/g, '')

 // Ensure the first character is a valid letter from the matrix
 if (cleanedText.length > 0 && !igletterMatrix[cleanedText[0].toUpperCase()]) {
 cleanedText = cleanedText.substring(1)
 }

 // Insert spaces at the correct positions
 if (cleanedText.length > 1 && cleanedText[1] !== ' ') {
 cleanedText = cleanedText[0] + ' ' + cleanedText.substring(1)
 }
 if (cleanedText.length > 7 && cleanedText[7] !== ' ') {
 cleanedText = cleanedText.substring(0, 7) + ' ' + cleanedText.substring(7)
 }

 // Ensure the characters after the first space are digits
 if (cleanedText.length > 2) {
 var firstNumberPart = cleanedText.substring(2, 7)
 if (!/^\d{0,5}$/.test(firstNumberPart)) {
 firstNumberPart = firstNumberPart.replace(/\D/g, '')
 cleanedText = cleanedText.substring(0, 2) + firstNumberPart + cleanedText.substring(7)
 }
 }

 // Ensure the characters after the second space are digits
 if (cleanedText.length > 8) {
 var secondNumberPart = cleanedText.substring(8, 13)
 if (!/^\d{0,5}$/.test(secondNumberPart)) {
 secondNumberPart = secondNumberPart.replace(/\D/g, '')
 cleanedText = cleanedText.substring(0, 8) + secondNumberPart + cleanedText.substring(13)
 }
 }

 // Limit the total length to 13 characters (X 00000 00000)
 if (cleanedText.length > 13) {
 cleanedText = cleanedText.substring(0, 13)
 }

 // Update the text field
 igInputBox.text = cleanedText

 // Convert IG to other formats
 if (igInputBox.isValidInput()) {
 var letter = igInputBox.text.substring(0, 1).toUpperCase()
 var X5 = parseInt(igInputBox.text.substring(2, 7), 10)
 var Y5 = parseInt(igInputBox.text.substring(8, 13), 10)
 var matrixEntry = igletterMatrix[letter]
 var xIN = X5 + (matrixEntry.first * 100000)
 var yIN = Y5 + (matrixEntry.second * 100000)
 
 updateCoordinates(xIN, yIN, 29903, custom1CRS.text, custom2CRS.text , 1) 
 }
 }

 // Function to validate the final input
 function isValidInput() {
 var regex = /^[A-Za-z]\s\d{5}\s\d{5}$/
 return regex.test(igInputBox.text) && igletterMatrix[igInputBox.text[0].toUpperCase()]
 }
}


Button {
    text: qsTr("C")
    id: copyIG  
    font.bold: true
    width: 10
    height: 10

    background: Rectangle {
        color: "#B3EBF2" 
        radius: width / 2
    }
    onClicked: {
        let text = igInputBox.text;
        let textEdit = Qt.createQmlObject('import QtQuick; TextEdit { }', plugin);
        textEdit.text = text;
        textEdit.selectAll();
        textEdit.copy();
        textEdit.destroy();
        mainWindow.displayToast("Copied: " + text);
    }
}
} 
// UK Grid 
 
RowLayout{
    id:ukgridrow 
    visible: ukgvis

TextField {
 id: ukInputBox //2
 Layout.preferredHeight: 35
 font.pixelSize: font_Size.text 
 font.family: "Arial"
 font.bold: true
 font.italic: true 
 Layout.fillWidth: true
 placeholderText: "UK Grid: XX 00000 00000"
 
 // Flag to indicate programmatic updates
 property bool isProgrammaticUpdate: false

 // Custom validation logic
 onTextChanged: {
ukInputBox.placeholderText  = "UKG"    
 if (isProgrammaticUpdate) {
 // Skip validation if the text is being updated programmatically
 isProgrammaticUpdate = false
 return
 }

 // Remove any non-alphanumeric characters (except spaces)
 var cleanedText = ukInputBox.text.replace(/[^A-Za-z0-9\s]/g, '')

 // Ensure the first two characters are valid letters from the matrix
 if (cleanedText.length > 1) {
 var firstTwoLetters = cleanedText.substring(0, 2).toUpperCase()
 if (!ukletterMatrix[firstTwoLetters]) {
 cleanedText = cleanedText.substring(2)
 }
 }

 // Insert spaces at the correct positions
 if (cleanedText.length > 2 && cleanedText[2] !== ' ') {
 cleanedText = cleanedText.substring(0, 2) + ' ' + cleanedText.substring(2)
 }
 if (cleanedText.length > 8 && cleanedText[8] !== ' ') {
 cleanedText = cleanedText.substring(0, 8) + ' ' + cleanedText.substring(8)
 }

 // Ensure the characters after the first space are digits
 if (cleanedText.length > 3) {
 var firstNumberPart = cleanedText.substring(3, 8)
 if (!/^\d{0,5}$/.test(firstNumberPart)) {
 firstNumberPart = firstNumberPart.replace(/\D/g, '')
 cleanedText = cleanedText.substring(0, 3) + firstNumberPart + cleanedText.substring(8)
 }
 }

 // Ensure the characters after the second space are digits
 if (cleanedText.length > 9) {
 var secondNumberPart = cleanedText.substring(9, 14)
 if (!/^\d{0,5}$/.test(secondNumberPart)) {
 secondNumberPart = secondNumberPart.replace(/\D/g, '')
 cleanedText = cleanedText.substring(0, 9) + secondNumberPart + cleanedText.substring(14)
 }
 }

 // Limit the total length to 14 characters (XX 00000 00000)
 if (cleanedText.length > 14) {
 cleanedText = cleanedText.substring(0, 14)
 }

 // Update the text field
 ukInputBox.text = cleanedText

 // Convert UK Grid to other formats
 if (ukInputBox.isValidInput()) {
 var letter = ukInputBox.text.substring(0, 2).toUpperCase()
 var X5 = parseInt(ukInputBox.text.substring(3, 8), 10)
 var Y5 = parseInt(ukInputBox.text.substring(9, 14), 10)
 var matrixEntry = ukletterMatrix[letter]
 var xIN = X5 + (matrixEntry.first * 100000)
 var yIN = Y5 + (matrixEntry.second * 100000)
 
 updateCoordinates(xIN, yIN, 27700, custom1CRS.text, custom2CRS.text, 2) 
 }
 }

 // Function to validate the final input
 function isValidInput() {
 var regex = /^[A-Za-z]{2}\s\d{5}\s\d{5}$/
 return regex.test(ukInputBox.text) && ukletterMatrix[ukInputBox.text.substring(0, 2).toUpperCase()]
 }
}
Button {
    text: qsTr("C")
    id: copyUK  
    //visible: false
    font.bold: true
    width: 10
    height: 10
    background: Rectangle {
        color: "#B3EBF2"
        radius: width / 2
    }
    onClicked: {
        let text = ukInputBox.text;
        let textEdit = Qt.createQmlObject('import QtQuick; TextEdit { }', plugin);
        textEdit.text = text;
        textEdit.selectAll();
        textEdit.copy();
        textEdit.destroy();
        mainWindow.displayToast("Copied: " + text);
    }
}
} 
 
// Custom1 Row
RowLayout { 
    id: custom1row
    visible: custom1vis

//custombox1

TextField {
    id: custom1BoxXY //3
    property bool isProgrammaticUpdate: false
    Layout.preferredHeight: 35
    Layout.preferredWidth: 180
    font.pixelSize: font_Size.text
    font.family: "Arial"
    font.bold: true
    font.italic: true
    placeholderText: "X,Y or Long (E), Lat (N)"
    //visible: false
    text: ""

    // Timer for delayed validation
    Timer {
        id: validationTimer
        interval: 500 // 500ms delay
        running: false
        repeat: false
        onTriggered: {
            // Run validation logic here
            validateInput(custom1BoxXY);

            // Parse coordinates more robustly
            var parts = custom1BoxXY.text.split(',').map(function(part) {
                return parseFloat(part.trim());
            });

            if (parts.length === 2 && !isNaN(parts[0]) && !isNaN(parts[1])) {
                updateCoordinates(parts[0], parts[1], custom1CRS.text, custom1CRS.text, custom2CRS.text, 3);
            }
        }
    }

    onTextChanged: {
        if (isProgrammaticUpdate) {
            isProgrammaticUpdate = false;
            return;
        }

        // Restart the timer on every keystroke
        validationTimer.restart();
    }
}

//end of custombox1 


 TextField {
 id: custom1CRS
  Layout.fillWidth: true
 Layout.preferredHeight: 35 
 placeholderText: " EPSG"
 font.pixelSize: font_Size.text // Smaller text size
 font.family: "Arial" // Set font family
 font.italic: true // Make text italic
 font.bold: true
 text: canvasEPSG
 // Enforce integer number input
 validator: IntValidator {
 bottom: 0 // Allow any negative number
 top: 10000000 // Allow any positive number
 } 
 
 }
 Button {
    text: qsTr("C")
    id: custom1copy
    font.bold: true
    width: 35
    height: 35
    background: Rectangle {
        color: "#B3EBF2"
        radius: width / 2
    }
    onClicked: {
        let text = custom1BoxXY.text;
        let textEdit = Qt.createQmlObject('import QtQuick; TextEdit { }', plugin);
        textEdit.text = text;
        textEdit.selectAll();
        textEdit.copy();
        textEdit.destroy();
        mainWindow.displayToast("Copied: " + text);
    }
}

 }
 
// custom2
RowLayout {
 id: custom2row
 visible: custom2vis  

//second custom box   
TextField {
    id: custom2BoxXY
    property bool isProgrammaticUpdate: false
    Layout.preferredWidth: 180
    Layout.preferredHeight: 35
    font.pixelSize: font_Size.text
    font.family: "Arial"
    font.italic: true
    font.bold: true
    placeholderText: "X,Y or Long (E), Lat (N)"
    //visible: false
    text: ""

    Timer {
        id: validationTimer2
        interval: 500
        running: false
        repeat: false
        onTriggered: {
            // Run validation logic here
            validateInput(custom2BoxXY);

            // Parse coordinates more robustly
            var parts = custom2BoxXY.text.split(',').map(function(part) {
                return parseFloat(part.trim());
            });

            if (parts.length === 2 && !isNaN(parts[0]) && !isNaN(parts[1])) {
                updateCoordinates(parts[0], parts[1], custom2CRS.text, custom1CRS.text, custom2CRS.text, 4);
            }
        }
    }

    onTextChanged: {
        if (isProgrammaticUpdate) {
            isProgrammaticUpdate = false;
            return;
        }
        validationTimer2.restart();
    }
}
//end of second custom box



 TextField {
 id: custom2CRS
  Layout.fillWidth: true
 Layout.preferredHeight: 35 
 placeholderText: " EPSG"
 font.pixelSize: font_Size.text
 font.family: "Arial" // Set font family
 font.bold: true
 font.italic: true // Make text italic
 text: "4326"
 //visible: false
 // Enforce integer number input
 validator: IntValidator {
 bottom: 0 // Allow any negative number
 top: 10000000 // Allow any positive number
 }
  }

 Button {
    text: qsTr("C")
    id: custom2copy
    font.bold: true
    //visible: false
    width: 35
    height: 35
    background: Rectangle {
        color: "#B3EBF2"
        radius: width / 2
    }
    onClicked: {
        let text = custom2BoxXY.text;
        let textEdit = Qt.createQmlObject('import QtQuick; TextEdit { }', plugin);
        textEdit.text = text;
        textEdit.selectAll();
        textEdit.copy();
        textEdit.destroy();
        mainWindow.displayToast("Copied: " + text);
    }
 }
}


// wgs1984 
RowLayout{
 id: wgsdegreesrow
 visible: wgs84vis 
TextField {
 id: wgs84Box //5
  Layout.fillWidth: true
 font.bold: true
 Layout.preferredHeight: 35
 font.pixelSize: font_Size.text 
 font.family: "Arial"
 font.italic: true
 placeholderText: "Lat(N), Long(E) "
 text: ""
 property bool isProgrammaticUpdate: false
 
 onTextChanged: {

    if (isProgrammaticUpdate) {
 // Skip validation if the text is being updated programmatically
 isProgrammaticUpdate = false
 return
 }
    wgs84Box.placeholderText  = "Lat Long"
 var cursorPos = cursorPosition // Store cursor position
 var originalText = text

 // Clean input: allow digits, minus, dot, comma, and spaces
 var cleanedText = text.replace(/[^0-9-.,\s]/g, '')

 // Split by comma
 var parts = cleanedText.split(',')
 if (parts.length > 2) {
 cleanedText = parts[0] + ',' + parts[1]
 parts = cleanedText.split(',')
 }

 // Process each part
 for (var i = 0; i < parts.length; i++) {
 var num = parts[i].trim()

 // Allow partial input (e.g., "-", "45.", "45.1") during typing
 if (num === '' || num === '-' || num.match(/^-?\d*\.?\d*$/)) {
 // If it’s a valid partial number (including just a dot), keep it as-is
 parts[i] = num
 continue
 }

 // Remove extra dots (keep only the first one)
 var dots = (num.match(/\./g) || []).length
 if (dots > 1) {
 var firstDotIndex = num.indexOf('.')
 num = num.substring(0, firstDotIndex + 1) + num.substring(firstDotIndex + 1).replace(/\./g, '')
 }

 // Parse and clamp the value
 var value = parseFloat(num)
 if (isNaN(value)) {
 num = num.replace(/[^0-9-.]/g, '') // Remove invalid characters
 } else if (value < -90) {
 num = '-90'
 } else if (value > 90) {
 num = '90'
 } else {
 num = value.toString()
 }
 parts[i] = num
 }

 // Reconstruct the text
 cleanedText = parts[0] || ''
 if (parts.length > 1) {
 cleanedText += ', ' + (parts[1] || '')
 }

 // Update text only if it changed, and restore cursor
 if (text !== cleanedText) {
 text = cleanedText
 cursorPosition = cursorPos
 
 // convert get X,Y from textfield:
 {var parts = wgs84Box.text.split(',')
 var xlat = parts[0] 
 var ylon = parts[1] 
 
 updateCoordinates(ylon, xlat, 4326, custom1CRS.text, custom2CRS.text,5)} 
 }
 }
}
 Button {
    text: qsTr("C")
    id: wgs84copy
    font.bold: true
    //visible: true
    width: 35
    height: 35
    background: Rectangle {
        color: "#B3EBF2"
        radius: width / 2
    }
    onClicked: {
        let text = wgs84Box.text;
        let textEdit = Qt.createQmlObject('import QtQuick; TextEdit { }', plugin);
        textEdit.text = text;
        textEdit.selectAll();
        textEdit.copy();
        textEdit.destroy();
        mainWindow.displayToast("Copied: " + text);
    }
}
}

RowLayout{
    id: dmrow
    visible: dmvis
TextField {
 id: wgs84DMBox //6
  Layout.fillWidth: true
 Layout.preferredHeight: 35
 font.pixelSize: font_Size.text 
 font.family: "Arial"
 font.italic: true
 font.bold: true
 placeholderText: "D M.mm (Read only)" //"Lat(N), Long(E) (e.g., 34° 27.36', 56° 40.2')"
 //visible: false
 text: ""

 property bool isProgrammaticUpdate: false
 
  onTextChanged: {
 //   wgs84DMBox.placeholderText  = "Lat Long"
  if (isProgrammaticUpdate) {
 // Skip validation if the text is being updated programmatically
 isProgrammaticUpdate = false
 return
 }
 
  
 }}
 Button {
    text: qsTr("C")
    id: wgsdm84copy
    font.bold: true
    width: 35
    height: 35
    background: Rectangle {
        color: "#B3EBF2"
        radius: width / 2
    }
    onClicked: {
        let text = wgs84DMBox.text;
        let textEdit = Qt.createQmlObject('import QtQuick; TextEdit { }', plugin);
        textEdit.text = text;
        textEdit.selectAll();
        textEdit.copy();
        textEdit.destroy();
        mainWindow.displayToast("Copied: " + text);
    }
}
 

}
RowLayout{
    id: dmsrow
    visible : dmsvis
TextField {
 id: wgs84DMSBox //6
  Layout.fillWidth: true
 Layout.preferredHeight: 35
 font.pixelSize: font_Size.text 
 font.family: "Arial"
 font.italic: true
 font.bold: true
 placeholderText: "D M S.ss (Read only)" //"Lat(N), Long(E) (e.g., 34° 27.36', 56° 40.2')"
 text: ""

 property bool isProgrammaticUpdate: false
 
 // need to get this to work or delete it....
 onTextChanged: {
 //   wgs84DMBox.placeholderText  = "Lat Long"
  if (isProgrammaticUpdate) {
 // Skip validation if the text is being updated programmatically
 isProgrammaticUpdate = false
 return
 }
 

 }}
 Button {
    text: qsTr("C")
    id: wgsdms84copy
    font.bold: true
    width: 35
    height: 35
    background: Rectangle {
        color: "#B3EBF2"
        radius: width / 2
    }
    onClicked: {
        let text = wgs84DMSBox.text;
        let textEdit = Qt.createQmlObject('import QtQuick; TextEdit { }', plugin);
        textEdit.text = text;
        textEdit.selectAll();
        textEdit.copy();
        textEdit.destroy();
        mainWindow.displayToast("Copied: " + text);
    }
}
 
}
// Seperate input boxes for lat Degrees, lon Minutes, lat Degrees and long minutes. 
// Entering decimals in the Degrees boxes will remove the minute boxes.
// update of the other coordinate boxes is achieved by button which enters the parsed 
// ddlat and ddlong from these boxes into the above wgs84Box.
 
RowLayout {
   
 id: latlongboxesDMS
 spacing: 5
 visible: dmsBoxesvis

 // Latitude Degrees
 TextField {
 id: latDegrees
 Layout.preferredWidth: 60
 Layout.fillWidth: true
 Layout.preferredHeight: 35
 font.pixelSize: font_Size.text
 font.bold: true
 font.family: "Arial"
 font.italic: true
 placeholderText: "D"
 leftPadding: 4
 rightPadding: 0
 validator: DoubleValidator {
 bottom: -90
 top: 90
 decimals: 5
 }
 Timer {
 id: latDegClampTimer
 interval: 1000
 running: false
 repeat: false
 onTriggered: {
 var value = parseFloat(latDegrees.text)
 if (!isNaN(value)) {
 value = Math.max(-90, Math.min(90, value))
 latDegrees.text = value // update to safe value (preserve decimals)
 }
 }
 }

 onTextChanged: {
 latDegClampTimer.restart() // each change restarts the timer
 
 if (lonDegrees.text.includes('.') || latDegrees.text.includes('.')) { // if there is a decimal in the either degrees box just show degrees & clear data in minutes and seconds boxes
 latMinutes.visible = false
 latMinutes.text = ""
 latSeconds.visible = false
 latSeconds.text = ""
 lonMinutes.visible = false
  lonMinutes.text = "" 
 lonSeconds.visible = false
 lonSeconds.text = ""
 } 
 else if(lonMinutes.text.includes('.') || latMinutes.text.includes('.')){ // if there is a decimal in the minutes box show degrees and minutes & clear data in seconds box
  lonDegrees.Layout.preferredWidth = degwa
  latDegrees.Layout.preferredWidth = degwa
  latMinutes.visible = true
  latSeconds.visible = false
  latSeconds.text = ""  
  lonMinutes.visible = true
  lonSeconds.visible = false
  lonSeconds.text = ""
 }
    else {   // if there are no decimals in the degrees or minutes boxes show all boxes
  lonDegrees.Layout.preferredWidth = degwa
  latDegrees.Layout.preferredWidth = degwa
  latMinutes.visible = true
  lonMinutes.visible = true
  lonMinutes.Layout.preferredWidth = minwa
  latMinutes.Layout.preferredWidth = minwa
  latSeconds.visible = true
  lonSeconds.visible = true 
 }
 } 
 }

 // Latitude Minutes (decimal)
 TextField {
 id: latMinutes
 Layout.preferredWidth: 60
 Layout.fillWidth: true
 Layout.preferredHeight: 35
 font.pixelSize: font_Size.text
 font.family: "Arial"
 font.bold: true
 font.italic: true
 leftPadding: 4
 rightPadding: 0
 placeholderText: "M"
 validator: DoubleValidator {
 bottom: 0
 top: +60
 decimals: 4
 }
Timer {
 id: latMinClampTimer
 interval: 1000
 running: false
 repeat: false
 onTriggered: {
 var value = parseFloat(latMinutes.text)
 if (!isNaN(value)) {
 value = Math.max(0, Math.min(59.999, value))
 latMinutes.text = value
 }
 }
}
onTextChanged: {
 latMinClampTimer.restart()
var hideSecs = latMinutes.text.includes(".") || lonMinutes.text.includes(".")|| lonDegrees.text.includes(".")|| latDegrees.text.includes(".");
  lonSeconds.visible = !hideSecs;
  latSeconds.visible = !hideSecs;
  if (hideSecs== true) {lonSeconds.text = "" 
  latSeconds.text = ""}
}
 }

 // Latitude Seconds
 TextField {
 id: latSeconds
 visible: true
 Layout.fillWidth: true
 Layout.preferredHeight: 35
 font.pixelSize: font_Size.text
 font.family: "Arial"
 font.bold: true
 font.italic: true
 leftPadding: 4
 rightPadding: 0
 placeholderText: "S"
 validator: DoubleValidator {
 bottom: 0
 top: 60
 decimals: 3
 }
 Timer {
 id: latSecClampTimer
 interval: 1000
 running: false
 repeat: false
 onTriggered: {
 var value = parseFloat(latSeconds.text)
 if (!isNaN(value)) {
 value = Math.max(0, Math.min(60, value))
 latSeconds.text = value
 }
 }
}
onTextChanged: latSecClampTimer.restart()

 }

 // Longitude Degrees
 TextField {
 id: lonDegrees
 Layout.preferredWidth: 60
 Layout.fillWidth: true
 Layout.preferredHeight: 35
  font.pixelSize: font_Size.text
 font.family: "Arial"
 font.bold: true
 font.italic: true
leftPadding: 4



 rightPadding: 0
 placeholderText: "D"
 validator: DoubleValidator {
 bottom: -180
 top: 180
 decimals: 5
 }
Timer {
 id: lonDegClampTimer
 interval: 1000
 running: false
 repeat: false
 onTriggered: {
 var value = parseFloat(lonDegrees.text)
 if (!isNaN(value)) {
 value = Math.max(-180, Math.min(180, value))
 lonDegrees.text = value
 }
 }
}
onTextChanged: {lonDegClampTimer.restart()

 
 if (lonDegrees.text.includes('.') || latDegrees.text.includes('.')) { // if there is a decimal in the either degrees box just show degrees & clear data in minutes and seconds boxes
 latMinutes.visible = false
 latMinutes.text = ""
 latSeconds.visible = false
 latSeconds.text = ""
 lonMinutes.visible = false
  lonMinutes.text = "" 
 lonSeconds.visible = false
 lonSeconds.text = ""
 } 
 else if(lonMinutes.text.includes('.') || latMinutes.text.includes('.')){ // if there is a decimal in the minutes box show degrees and minutes & clear data in seconds box
  lonDegrees.Layout.preferredWidth = degwa
  latDegrees.Layout.preferredWidth = degwa
  latMinutes.visible = true
  latSeconds.visible = false
  latSeconds.text = ""  
  lonMinutes.visible = true
  lonSeconds.visible = false
  lonSeconds.text = ""
 }
    else {   // if there are no decimals in the degrees or minutes boxes show all boxes
  lonDegrees.Layout.preferredWidth = degwa
  latDegrees.Layout.preferredWidth = degwa
  latMinutes.visible = true
  lonMinutes.visible = true
  lonMinutes.Layout.preferredWidth = minwa
  latMinutes.Layout.preferredWidth = minwa
  latSeconds.visible = true
  lonSeconds.visible = true 
    } 
 }
 }

 // Longitude Minutes (decimal)
 TextField {
 id: lonMinutes
 Layout.preferredWidth: 60
 Layout.fillWidth: true
 Layout.preferredHeight: 35
 font.pixelSize: font_Size.text
 font.family: "Arial"
 font.bold: true
 font.italic: true
 leftPadding: 4
 rightPadding: 0
 placeholderText: "M"
 validator: DoubleValidator {
 bottom: 0
 top: 60
 decimals: 4
 }
Timer {
 id: lonMinClampTimer
 interval: 1000
 running: false
 repeat: false
 onTriggered: {
 var value = parseFloat(lonMinutes.text)
 if (!isNaN(value)) {
 value = Math.max(0, Math.min(59.999, value))
 lonMinutes.text = value
 }
 }
}
onTextChanged: {
 lonMinClampTimer.restart();
 var hideSecs = latMinutes.text.includes(".") || lonMinutes.text.includes(".")|| lonDegrees.text.includes(".")|| latDegrees.text.includes(".");
  lonSeconds.visible = !hideSecs;
  latSeconds.visible = !hideSecs;
  if (hideSecs== true) {lonSeconds.text = "" 
  latSeconds.text = ""}

 }
 }

 // Longitude Seconds
 TextField {
 id: lonSeconds
 visible: true
 Layout.fillWidth: true
 Layout.preferredHeight: 35
 font.pixelSize: font_Size.text
 font.family: "Arial"
 font.bold: true
 font.italic: true
 leftPadding: 4
 rightPadding: 0
 placeholderText: "S"
 validator: DoubleValidator {
 bottom: 0
 top: 60
 decimals: 3
 }
 Timer {
 id: lonSecClampTimer
 interval: 1000
 running: false
 repeat: false
 onTriggered: {
 var value = parseFloat(lonSeconds.text)
 if (!isNaN(value)) {
 value = Math.max(0, Math.min(60, value))
 lonSeconds.text = value
 }
 }
}
onTextChanged: lonSecClampTimer.restart()

 }

 // Update Button
 Button {
 text: "←" // update from this row should get rid of this in future.....
     font.bold: true
    visible: true
    width: 35
    height: 35
    background: Rectangle {
        color: "#edad98"
        radius: width / 2
    }


 onClicked:{ 
 var latDeg = parseFloat(latDegrees.text) || 0
 var latMin = parseFloat(latMinutes.text) || 0
 var latSec = parseFloat(latSeconds.text) || 0
 var lonDeg = parseFloat(lonDegrees.text) || 0
 var lonMin = parseFloat(lonMinutes.text) || 0
 var lonSec = parseFloat(lonSeconds.text) || 0
 
 // should I notify the wgs84boxBox that this is a programmtic update?.
 wgs84Box.isProgrammaticUpdate = true
 // update the wgs84Box 
 if (latDeg < 0) { var latDecimal = latDeg - (latMin / 60) - (latSec / 3600) } 
 else
 var latDecimal = latDeg + (latMin / 60) + (latSec / 3600)
 if (lonDeg < 0) {
 var lonDecimal = lonDeg - (lonMin / 60) - (lonSec / 3600) } 
 else   
 var lonDecimal = lonDeg + (lonMin / 60) + (lonSec / 3600) 

 wgs84Box.text = latDecimal.toFixed(decimalsd.text) + ", " + lonDecimal.toFixed(decimalsd.text)

 // convert get X,Y from textfield:
 {var parts = wgs84Box.text.split(',')
 var xlat = parts[0] 
 var ylon = parts[1] 
 
 updateCoordinates(ylon, xlat, 4326, custom1CRS.text, custom2CRS.text,5)} 
 }


onPressAndHold: {
 var latDeg = parseFloat(latDegrees.text) || 0
 var latMin = parseFloat(latMinutes.text) || 0
 var latSec = parseFloat(latSeconds.visible ? latSeconds.text : 0) || 0
 var lonDeg = parseFloat(lonDegrees.text) || 0
 var lonMin = parseFloat(lonMinutes.text) || 0
 var lonSec = parseFloat(lonSeconds.visible ? lonSeconds.text : 0) || 0
 
 var latDecimal = latDeg + (latMin / 60) + (latSec / 3600)
 var lonDecimal = lonDeg + (lonMin / 60) + (lonSec / 3600)
 wgs84Box.text = latDecimal.toFixed(decimalsd.text) + ", " + lonDecimal.toFixed(decimalsd.text)

 // convert get X,Y from textfield:
 {var parts = wgs84Box.text.split(',')
 var xlat = parts[0] 
 var ylon = parts[1] 
 
 updateCoordinates(ylon, xlat, 4326, custom1CRS.text, custom2CRS.text,5)} 
 bigDialog2.open()
 } 
 }
 }
}

 
 
 
RowLayout{ 
 Label {
 id: label_2
 visible: true
 wrapMode: Text.Wrap
 font.bold: true
 text: qsTr("Do:")
 font.pixelSize: font_Size.text 
 font.family: "Arial" // Set font family
 font.italic: true // Make text italic
 } 
 
 Button {
 
 text: qsTr("Pan/\nZoom")
 font.bold: true
  Layout.fillWidth: true
 font.pixelSize: font_Size.text  -3
 Layout.preferredHeight: 60 
 onClicked: { //pan to point
 // Parse coordinates from text fields 
 var parts = wgs84Box.text.split(',')
 var xIN = parts[1] 
 var yIN = parts[0] 
 var customcrsIN = CoordinateReferenceSystemUtils.fromDescription("EPSG:4326"); 
 
 var customcrsOUT = CoordinateReferenceSystemUtils.fromDescription("EPSG:" + canvasEPSG); 
 var transformedPoint = GeometryUtils.reprojectPoint(GeometryUtils.point(xIN, yIN), customcrsIN, customcrsOUT); 
  
 iface.mapCanvas().mapSettings.center.x = transformedPoint.x;
 iface.mapCanvas().mapSettings.center.y = transformedPoint.y;
mainDialog.close() 

// Highlight:
var pointGeometry = GeometryUtils.createGeometryFromWkt(`POINT(${transformedPoint.x} ${transformedPoint.y})`);
geometryHighlighter.geometryWrapper.qgsGeometry = pointGeometry;


 mainWindow.displayToast( transformedPoint.x + ", " + transformedPoint.y)
 
 }
 onPressAndHold: { // zoom to point
 var parts = wgs84Box.text.split(',')
 var xIN = parts[1] 
 var yIN = parts[0] 
 var customcrsIN = CoordinateReferenceSystemUtils.fromDescription("EPSG:4326"); 
 
 var customcrsOUT = CoordinateReferenceSystemUtils.fromDescription("EPSG:" + canvasEPSG); 
 var transformedPoint = GeometryUtils.reprojectPoint(GeometryUtils.point(xIN, yIN), customcrsIN, customcrsOUT); 
 
 // zoom 
var offset =  Math.exp( parseFloat(zoom.text) * 1.2);
if (offset > 1000000) {offset = 1000000}
if (offset < 1) {offset = 1}
if(canvasCrs.isGeographic){ offset = offset/111000}

var xMin = transformedPoint.x - offset;
var xMax = transformedPoint.x + offset;
var yMin = transformedPoint.y - offset;
var yMax = transformedPoint.y + offset;

var polygonWkt = `POLYGON((
 ${xMin} ${yMin},
 ${xMax} ${yMin},
 ${xMax} ${yMax},
 ${xMin} ${yMax},
 ${xMin} ${yMin}
))`;

var geometry = GeometryUtils.createGeometryFromWkt(polygonWkt);


 
 const extent = GeometryUtils.reprojectRectangle(
 GeometryUtils.boundingBox(geometry),
 CoordinateReferenceSystemUtils.fromDescription("EPSG:" + canvasEPSG), 
 mapCanvas.mapSettings.destinationCrs
 )
 mapCanvas.mapSettings.setExtent(extent, true);
 mainDialog.close()
  // Set geometry to highlighter
var pointGeometry = GeometryUtils.createGeometryFromWkt(`POINT(${transformedPoint.x} ${transformedPoint.y})`);
geometryHighlighter.geometryWrapper.qgsGeometry = pointGeometry;

 } 
 }
 
Button {
 text: qsTr("Add")
 font.bold: true
  Layout.fillWidth: true
 font.pixelSize: font_Size.text 
 Layout.preferredHeight: 60 

 onClicked: {
  // Ensure an 'Points' layer is selected
        if (!dashBoard.activeLayer || dashBoard.activeLayer.name != 'Points') {
        mainWindow.displayToast(qsTr("Select 'Points' layer and try again"));
        dashBoard.open();
        return;
        }

 // Parse coordinates & transform
 var parts = wgs84Box.text.split(',');
 var transformedPoint = GeometryUtils.reprojectPoint(
 GeometryUtils.point(parts[1], parts[0]), // x, y
 CoordinateReferenceSystemUtils.fromDescription("EPSG:4326"),
 CoordinateReferenceSystemUtils.fromDescription("EPSG:" + canvasEPSG)
 );

 // Create the geometry and feature
 var geometry = GeometryUtils.createGeometryFromWkt(
 `POINT(${transformedPoint.x} ${transformedPoint.y})`
 );
 var feature = FeatureUtils.createFeature(dashBoard.activeLayer, geometry);

 // Open the form for the new feature
 overlayFeatureFormDrawer.featureModel.feature = feature;
 overlayFeatureFormDrawer.state = "Add";
 overlayFeatureFormDrawer.open();

 // Display coordinates once
 mainWindow.displayToast(`${transformedPoint.x}, ${transformedPoint.y}`);

 mainDialog.close();
// Geometry highlighter
 var pointGeometry = GeometryUtils.createGeometryFromWkt(`POINT(${transformedPoint.x} ${transformedPoint.y})`);
 geometryHighlighter.geometryWrapper.qgsGeometry = pointGeometry;
 
 }
 }
}

Button {
 visible: true
 text: "Navigate/\nWeb"
  Layout.fillWidth: true
 font.bold: true
 font.pixelSize: font_Size.text -3
 Layout.preferredHeight: 60 
 onClicked: { 
 let navigation = iface.findItemByObjectName('navigation');
 
 // Parse coordinates and transform
 var parts = wgs84Box.text.split(',');
 var transformedPoint = GeometryUtils.reprojectPoint(
 GeometryUtils.point(parts[1], parts[0]),
 CoordinateReferenceSystemUtils.fromDescription("EPSG:4326"),
 CoordinateReferenceSystemUtils.fromDescription("EPSG:" + canvasEPSG)
 );
 
 iface.mapCanvas().mapSettings.center.x = transformedPoint.x;
 iface.mapCanvas().mapSettings.center.y = transformedPoint.y;
 mainWindow.displayToast("navigating to:"+ transformedPoint.x + ", " + transformedPoint.y);

 // Directly set destination
 navigation.destination = transformedPoint;
 mainDialog.close()
 }
  onPressAndHold: {
    var parts = wgs84Box.text.split(',');
    if (parts.length < 2) {
        console.log("Invalid coordinate format");
        return;
    }

    var lon = parseFloat(parts[1]); // Ensure proper order
    var lat = parseFloat(parts[0]);

    var MapsUrl = "https://www.google.com/maps/search/?api=1&query="+ lat + "," + lon // pin
    //var MapsUrl = "https://www.google.com/maps/dir/?api=1&destination=" + lat + "%2C" + lon  + "&travelmode=driving"; // navigate
    //var MapsUrl = "https://www.openstreetmap.org/#map=15/"+ lat +"/"+lon; // OSM
   
    Qt.openUrlExternally(MapsUrl);
     mainDialog.close()
}


}
Button {
 text: qsTr("BIG")
 
 font.bold: true
  Layout.fillWidth: true
 font.pixelSize: font_Size.text 
 Layout.preferredHeight: 60 
 onClicked: { 
    bigDialog.open() 
    }

 onPressAndHold: {
     bigDialog2.open() 
     }
 }
 } 
 

 
Frame{
id: customisation
 Layout.fillWidth: true
visible: false


Column{

    anchors.fill: parent
    anchors.margins: 1

GridLayout{  //grid 1
    columns: 4
    rows: 2
    columnSpacing: 0
    rowSpacing: 0
    
     Layout.fillWidth: true 


Label{
 id:font_Size1
 font.pixelSize: 10
 font.family: "Arial"
 font.italic: true
 text : "Font Size:"
 Layout.preferredHeight: 10 
 }

 TextField{
 id:font_Size
 font.pixelSize: 10
 font.family: "Arial"
 font.italic: true
 text : fsize
 Layout.preferredWidth: 40 
 Layout.preferredHeight: 20 
 validator: IntValidator {
        bottom: 5
        top: 25
    }
 }

 Label{
 id:zoomlabel
 font.pixelSize: 10
 font.family: "Arial"
 font.italic: true
 text : "      Zoom:"
 Layout.preferredHeight: 10 
 }

  TextField{
 id:zoom
 font.pixelSize: 10
 font.family: "Arial"
 font.italic: true
 text : zoomV
 Layout.preferredWidth: 40 
 Layout.preferredHeight: 20 
 validator: IntValidator {
        bottom: 1
        top: 10
    } 
 } 

Label{
 id:decimals1
 font.pixelSize: 10
 font.family: "Arial"
 font.italic: true
 text : "Decimals (m):"
 Layout.preferredHeight: 10 
 }

  TextField{
 id:decimalsm
 font.pixelSize: 10
 font.family: "Arial"
 font.italic: true
 text : decm
 Layout.preferredWidth: 40 
 Layout.preferredHeight: 20
 validator: IntValidator {
      bottom: 0
      top: 10
  }  
 }
 
 Label{
 id:decimals2
 font.pixelSize: 10
 font.family: "Arial"
 font.italic: true
 text : "Decimals (deg):"
 Layout.preferredHeight: 10 
 }
 
 TextField{
 id:decimalsd
 font.pixelSize: 10
 font.family: "Arial"
 font.italic: true
 text : decd
 Layout.preferredWidth: 40 
 Layout.preferredHeight: 20 
 validator: IntValidator {
        bottom: 0
        top: 10
    } 
 } 
} //end of grid 1

GridLayout{  // grid 2
    columns: 3
    rows: 3
    columnSpacing: 0
    rowSpacing: 0
    Layout.fillWidth: true

//row 1
    CheckBox {
        id: showIG
        text: "Irish Grid"
        font.pixelSize: 10
        checked: true
        onCheckedChanged: {
            igridrow.visible= checked
        }
    }


                        CheckBox {
        id: showDegrees
        text: "Degrees"
        font.pixelSize: 10
        checked: false
        onCheckedChanged: {
            wgsdegreesrow.visible = checked   
        }
    }
     CheckBox {
        id: showDMS
        text: "D M S.ss"
        font.pixelSize: 10
        checked: false
        onCheckedChanged: {
            dmsrow.visible = checked
        }
    }

 
//row 2


    CheckBox {
        id: showUK
        text: "UK Grid"
        font.pixelSize: 10
        checked: false
        onCheckedChanged: {
            ukgridrow.visible = checked
        }
    }
       //     CheckBox {
       // id: showCustom2
       // text: "Custom 2"
       // font.pixelSize: 10
       // checked: false
       // onCheckedChanged: {
      //      custom2row.visible = checked         
       // }
    //}
                CheckBox {
        id: showDM
        text: "D M.mm"
        font.pixelSize: 10
        checked: true
        onCheckedChanged: {
            dmrow.visible = checked            
        }
    }
        CheckBox {
        id: showCustom1
        text: "Custom 1"
        font.pixelSize: 10
        checked: false
        onCheckedChanged: {
            custom1row.visible = checked
        }
    }


//row 3
 
  
     Button {
 text: qsTr("Reset")
 font.pixelSize: 10 
 Layout.preferredHeight: 35 
 onClicked: {
 custom1CRS.text = canvasEPSG
 custom2CRS.text = "4326"
 font_Size.text = fsize
 decimalsm.text = decm
 decimalsd.text = decd
 zoom.text = zoomV

    
    showIG.checked = igvis
    showUK.checked = ukgvis
    showCustom1.checked = custom1vis 
    //showCustom2.checked = custom2vis
    showDegrees.checked = wgs84vis    
    showDM.checked = dmvis
    showDMS.checked = dmsvis
    showDMSboxes.checked = dmsBoxesvis
    showCustomisation.checked = customisationvis
    showCrosshair.checked = crosshairvis

 }
 }


    CheckBox {
        id: showCrosshair
        text: "Crosshair"
        font.pixelSize: 10
        checked: true
        onCheckedChanged: {
            crosshair.visible = checked
        }
    }
                CheckBox {
        id: showDMSboxes
        text: "DMSBoxes"
        font.pixelSize: 10
        checked: true
        onCheckedChanged: {
            latlongboxesDMS.visible = checked   
        }
    }

 } // end of grid2
 } // end of column 
  
} // end of customisation 
} // end of big column
Dialog {
    id: bigDialog
    font.pixelSize: 35
    width: 350
    height: 400
    modal: true
    anchors.centerIn: parent

    Column {
        spacing: 20
        width: parent.width
        anchors.centerIn: parent

        // GPS Box
        Rectangle {
            id: gpsBox
            width: parent.width
            implicitHeight: childrenRect.height + 20
            color: "#D9CCE7"
            radius: 10
            border.color: "black"
            border.width: 0.5
            anchors.horizontalCenter: parent.horizontalCenter

            Column {
                id: childrenRect
                width: parent.width
                spacing: 10
                anchors.margins: 10
                anchors.centerIn: parent

                Label {
                    text: "GPS"
                    font.pixelSize: 20
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                // IG (GPS)
                MouseArea {
                    width: parent.width
                    height: gpsIG.implicitHeight
                    onClicked: {
                        let text = gpsIG.text;
                        let textEdit = Qt.createQmlObject('import QtQuick; TextEdit { }', plugin);
                        textEdit.text = text;
                        textEdit.selectAll();
                        textEdit.copy();
                        textEdit.destroy();
                        mainWindow.displayToast("Copied: " + text);
                    }

                    Label {
                        id: gpsIG
                        text: (positionSource.active && positionSource.positionInformation.latitudeValid && positionSource.positionInformation.longitudeValid)
        ? ((showIG.checked
            ? justIG(positionSource.projectedPosition, canvasEPSG)
            : justUKG(positionSource.projectedPosition, canvasEPSG)))
        : "No GPS"
                        font.pixelSize: 35
                        wrapMode: Text.Wrap
                        horizontalAlignment: Text.AlignHCenter
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }

                // LL (GPS)
                MouseArea {
                    width: parent.width
                    height: gpsLL.implicitHeight
                    onClicked: {
                        let text = gpsLL.text;
                        let textEdit = Qt.createQmlObject('import QtQuick; TextEdit { }', plugin);
                        textEdit.text = text;
                        textEdit.selectAll();
                        textEdit.copy();
                        textEdit.destroy();
                        mainWindow.displayToast("Copied: " + text);
                    }

                    Label {
                        id: gpsLL
                        text: (positionSource.active && positionSource.positionInformation.latitudeValid && positionSource.positionInformation.longitudeValid)
                            ? justLL(positionSource.projectedPosition, canvasEPSG)
                            : ""
                        font.pixelSize: 30
                        wrapMode: Text.Wrap
                        horizontalAlignment: Text.AlignHCenter
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }
        }

        // Screen Center Box
        Rectangle {
            id: screenBox
            width: parent.width
            implicitHeight: childrenRect2.height + 20
            color: "#f0f0f0"
            radius: 10
            border.color: "black"
            border.width: 0.5
            anchors.horizontalCenter: parent.horizontalCenter

            Column {
                id: childrenRect2
                width: parent.width
                spacing: 10
                anchors.margins: 10
                anchors.centerIn: parent

                Label {
                    text: "Screen Center"
                    font.pixelSize: 20
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                // IG (Screen Center)
                MouseArea {
                    width: parent.width
                    height: screenIG.implicitHeight
                    onClicked: {
                        let text = screenIG.text;
                        let textEdit = Qt.createQmlObject('import QtQuick; TextEdit { }', plugin);
                        textEdit.text = text;
                        textEdit.selectAll();
                        textEdit.copy();
                        textEdit.destroy();
                        mainWindow.displayToast("Copied: " + text);
                    }

                    Label {
                        id: screenIG
                        text:  showIG.checked ? justIG(canvas.center, canvasEPSG) :justUKG(canvas.center, canvasEPSG)
                        font.pixelSize: 35
                        wrapMode: Text.Wrap
                        horizontalAlignment: Text.AlignHCenter
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }

                // LL (Screen Center)
                MouseArea {
                    width: parent.width
                    height: screenLL.implicitHeight
                    onClicked: {
                        let text = screenLL.text;
                        let textEdit = Qt.createQmlObject('import QtQuick; TextEdit { }', plugin);
                        textEdit.text = text;
                        textEdit.selectAll();
                        textEdit.copy();
                        textEdit.destroy();
                        mainWindow.displayToast("Copied: " + text);
                    }

                    Label {
                        id: screenLL
                        text: justLL(canvas.center, canvasEPSG)
                        font.pixelSize: 30
                        wrapMode: Text.Wrap
                        horizontalAlignment: Text.AlignHCenter
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }
        }
    }
}

Dialog {
    id: bigDialog2
    font.pixelSize: 35
    width: 400
    height: 350
    modal: true
    anchors.centerIn: parent

    // Third Box: Box contents
    Rectangle {
        id: boxBox
        width: parent.width
        implicitHeight: childrenRect3.height + 20
        color: "#f0fef0"
        radius: 10
        border.color: "black"
        border.width: 0.5
        anchors.horizontalCenter: parent.horizontalCenter

        Column {
            id: childrenRect3
            width: parent.width
            spacing: 10
            anchors.margins: 10
            anchors.centerIn: parent

            Label {
                text: "Text box contents"
                font.pixelSize: 20
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                anchors.horizontalCenter: parent.horizontalCenter
            }

            // igInputBox text
            MouseArea {
                width: parent.width
                height: igCopy.implicitHeight
                onClicked: {
                    let text = igCopy.text;
                    let textEdit = Qt.createQmlObject('import QtQuick; TextEdit { }', plugin);
                    textEdit.text = text;
                    textEdit.selectAll();
                    textEdit.copy();
                    textEdit.destroy();
                    mainWindow.displayToast("Copied: " + text);
                }

                Label {
                    id: igCopy
                    text: igInputBox.text
                    font.pixelSize: 35
                    wrapMode: Text.Wrap
                    horizontalAlignment: Text.AlignHCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }

            // wgs84Box text
            MouseArea {
                width: parent.width
                height: wgs84Copy.implicitHeight
                onClicked: {
                    let text = wgs84Copy.text;
                    let textEdit = Qt.createQmlObject('import QtQuick; TextEdit { }', plugin);
                    textEdit.text = text;
                    textEdit.selectAll();
                    textEdit.copy();
                    textEdit.destroy();
                    mainWindow.displayToast("Copied: " + text);
                }

                Label {
                    id: wgs84Copy
                    text: wgs84Box.text
                    font.pixelSize: 30
                    wrapMode: Text.Wrap
                    horizontalAlignment: Text.AlignHCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }

            // wgs84DMBox text
            MouseArea {
                width: parent.width
                height: wgs84DMCopy.implicitHeight
                onClicked: {
                    let text = wgs84DMCopy.text;
                    let textEdit = Qt.createQmlObject('import QtQuick; TextEdit { }', plugin);
                    textEdit.text = text;
                    textEdit.selectAll();
                    textEdit.copy();
                    textEdit.destroy();
                    mainWindow.displayToast("Copied: " + text);
                }

                Label {
                    id: wgs84DMCopy
                    text: wgs84DMBox.text
                    font.pixelSize: 30
                    wrapMode: Text.Wrap
                    horizontalAlignment: Text.AlignHCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }

            // wgs84DMSBox text
            MouseArea {
                width: parent.width
                height: wgs84DMSCopy.implicitHeight
                onClicked: {
                    let text = wgs84DMSCopy.text;
                    let textEdit = Qt.createQmlObject('import QtQuick; TextEdit { }', plugin);
                    textEdit.text = text;
                    textEdit.selectAll();
                    textEdit.copy();
                    textEdit.destroy();
                    mainWindow.displayToast("Copied: " + text);
                }

                Label {
                    id: wgs84DMSCopy
                    text: wgs84DMSBox.text
                    font.pixelSize: 30
                    wrapMode: Text.Wrap
                    horizontalAlignment: Text.AlignHCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }
}

}
 



 // Lookup table for the IG letter matrix (for EPSG:29903 /29902)
 property var igletterMatrix: {
 'V': { first: 0, second: 0 },
 'W': { first: 1, second: 0 },
 'X': { first: 2, second: 0 },
 'Y': { first: 3, second: 0 },
 'Z': { first: 4, second: 0 },
 'Q': { first: 0, second: 1 },
 'R': { first: 1, second: 1 },
 'S': { first: 2, second: 1 },
 'T': { first: 3, second: 1 },
 'L': { first: 0, second: 2 },
 'M': { first: 1, second: 2 },
 'N': { first: 2, second: 2 },
 'O': { first: 3, second: 2 },
 'P': { first: 4, second: 2 },
 'F': { first: 0, second: 3 },
 'G': { first: 1, second: 3 },
 'H': { first: 2, second: 3 },
 'J': { first: 3, second: 3 },
 'K': { first: 4, second: 3 },
 'A': { first: 0, second: 4 },
 'B': { first: 1, second: 4 },
 'C': { first: 2, second: 4 },
 'D': { first: 3, second: 4 },
 'E': { first: 4, second: 4 }
 }
// Lookup table for the UK letter matrix (for EPSG:27700)
property var ukletterMatrix: {
 'SV': { first: 0, second: 0 },
 'SW': { first: 1, second: 0 },
 'SX': { first: 2, second: 0 },
 'SY': { first: 3, second: 0 },
 'SZ': { first: 4, second: 0 },
 'TV': { first: 5, second: 0 },
 'SR': { first: 1, second: 1 },
 'SS': { first: 2, second: 1 },
 'ST': { first: 3, second: 1 },
 'SU': { first: 4, second: 1 },
 'TQ': { first: 5, second: 1 },
 'TR': { first: 6, second: 1 },
 'SM': { first: 1, second: 2 },
 'SN': { first: 2, second: 2 },
 'SO': { first: 3, second: 2 },
 'SP': { first: 4, second: 2 },
 'TL': { first: 5, second: 2 },
 'TM': { first: 6, second: 2 },
 'SH': { first: 2, second: 3 },
 'SJ': { first: 3, second: 3 },
 'SK': { first: 4, second: 3 },
 'TF': { first: 5, second: 3 },
 'TG': { first: 6, second: 3 },
 'SC': { first: 2, second: 4 },
 'SD': { first: 3, second: 4 },
 'SE': { first: 4, second: 4 },
 'TA': { first: 5, second: 4 },
 'NW': { first: 1, second: 5 },
 'NX': { first: 2, second: 5 },
 'NY': { first: 3, second: 5 },
 'NZ': { first: 4, second: 5 },
 'OV': { first: 5, second: 5 },
 'NR': { first: 1, second: 6 },
 'NS': { first: 2, second: 6 },
 'NT': { first: 3, second: 6 },
 'NU': { first: 4, second: 6 },
 'NL': { first: 0, second: 7 },
 'NM': { first: 1, second: 7 },
 'NN': { first: 2, second: 7 },
 'NO': { first: 3, second: 7 },
 'HW': { first: 1, second: 10 },
 'HX': { first: 2, second: 10 },
 'HY': { first: 3, second: 10 },
 'HZ': { first: 4, second: 10 },
 'NF': { first: 0, second: 8 },
 'NG': { first: 1, second: 8 },
 'NH': { first: 2, second: 8 },
 'NJ': { first: 3, second: 8 },
 'NK': { first: 4, second: 8 },
 'NA': { first: 0, second: 9 },
 'NB': { first: 1, second: 9 },
 'NC': { first: 2, second: 9 },
 'ND': { first: 3, second: 9 },
 'HT': { first: 3, second: 11 },
 'HU': { first: 4, second: 11 },
 'HP': { first: 4, second: 12 }}

function validateInput(textBox) {
    // Your validation logic here
    console.log("Validating input for:", textBox.objectName);

    // Example validation logic
    var inputText = textBox.text;
    var cleanedText = inputText.replace(/[^0-9-.,\s]/g, '');
    var parts = cleanedText.split(',');

    if (parts.length > 2) {
        cleanedText = parts[0] + ',' + parts[1];
        parts = cleanedText.split(',');
    }

    // Process each part
    for (var i = 0; i < parts.length; i++) {
        var num = parts[i].trim();

        if (num === '' || num === '-' || num.match(/^-?\d*\.?\d*$/)) {
            parts[i] = num;
            continue;
        }

        var dots = (num.match(/\./g) || []).length;
        if (dots > 1) {
            var firstDotIndex = num.indexOf('.');
            num = num.substring(0, firstDotIndex + 1) + num.substring(firstDotIndex + 1).replace(/\./g, '');
        }

        var value = parseFloat(num);
        if (isNaN(value)) {
            num = num.replace(/[^0-9-.]/g, '');
        } else if (value < -1000000) {
            num = '';
        } else if (value > 1000000) {
            num = '';
        } else {
            num = value.toString();
        }
        parts[i] = num;
    }

    // Reconstruct the text
    cleanedText = parts[0] || '';
    if (parts.length > 1) {
        cleanedText += ', ' + (parts[1] || '');
    }

    // Update the text box if the text has changed
    if (textBox.text !== cleanedText) {
        textBox.isProgrammaticUpdate = true;
        textBox.text = cleanedText;
    }
}

function getIGFromXY(x, y) {
 // Check if x or y is greater than 0
 if (x >= 0 && y >= 0 && x < 1000000 && y <1000000) {
 // Step 1: Determine the grid letter
 var firstIndex = Math.floor(x / 100000); // Get the index for the first dimension
 var secondIndex = Math.floor(y / 100000); // Get the index for the second dimension

 // Find the letter corresponding to the indices
 var letter = Object.keys(igletterMatrix).find(function(key) {
 return igletterMatrix[key].first === firstIndex && igletterMatrix[key].second === secondIndex;
 });

 // Step 2: Calculate the 5-digit numbers
 var X5 = Math.round(x % 100000); // Remainder of x divided by 100000
 var Y5 = Math.round(y % 100000); // Remainder of y divided by 100000

 // Step 3: Format the result as "L XXXXX YYYYY"
 if (letter) {
 return letter + ' ' + String(X5).padStart(5, '0') + ' ' + String(Y5).padStart(5, '0');
 } else {
 return ""; // Return an empty string if no letter is found
 }
 } else {
 // Return an empty string if the condition fails
 return "";
 }
}

function getUKFromXY(x, y) {
 // Check if x and y are within the valid range
 if (x >= 0 && y >= 0 && x < 10000000 && y < 10000000) {
 // Step 1: Determine the grid letters
 var firstIndex = Math.floor(x / 100000); // Get the index for the first dimension
 var secondIndex = Math.floor(y / 100000); // Get the index for the second dimension

 // Find the 2-letter grid reference corresponding to the indices
 var gridLetters = Object.keys(ukletterMatrix).find(function(key) {
 return ukletterMatrix[key].first === firstIndex && ukletterMatrix[key].second === secondIndex;
 });

 // Step 2: Calculate the 5-digit numbers
 var X5 = Math.round(x % 100000); // Remainder of x divided by 100000
 var Y5 = Math.round(y % 100000); // Remainder of y divided by 100000

 // Step 3: Format the result as "LL XXXXX YYYYY"
 if (gridLetters) {
 return gridLetters + ' ' + String(X5).padStart(5, '0') + ' ' + String(Y5).padStart(5, '0');
 } else {
 return ""; // Return an empty string if no grid letters are found
 }
 } else {
 // Return an empty string if the condition fails
 return "";
 }
}

// Convert DDM to decimal degrees
 function ddmToDecimal(coord) {
 if (!coord) return ''
 var parts = coord.split(/°|\s+/).filter(Boolean)
 var degrees = parseInt(parts[0], 10)
 var minutes = parts.length > 1 ? parseFloat(parts[1].replace("'", "")) : 0
 var decimal = degrees + (minutes / 60)
 return decimal.toFixed(6)
 }

function decimalToDDM(decimal) {
 if (typeof decimal !== 'number' || isNaN(decimal)) return ''
 
 var sign = decimal < 0 ? '-' : ''
 var absDecimal = Math.abs(decimal)
 
 var degrees = Math.floor(absDecimal)
 var minutes = (absDecimal - degrees) * 60
 
 return `${sign}${degrees}° ${minutes.toFixed(3)}'`

}
 


function decTODeg(decimal) {
if (typeof decimal !== 'number' || isNaN(decimal)) {
 return ''
 }
 
 const sign = decimal < 0 ? -1 : 1
 const absDecimal = Math.abs(decimal)
 return Math.floor(absDecimal) * sign
}



function degtoSeconds(decimal) {
 if (typeof decimal !== 'number' || isNaN(decimal)) {
 return ''
 }
 
 const absDecimal = Math.abs(decimal)
 const degrees = Math.floor(absDecimal)
 const minutes = (absDecimal - degrees) * 60
 return ((minutes - Math.floor(minutes)) * 60).toFixed(2)
}

// should loop through and update coordinates in all OTHER textfields
 function updateCoordinates(x, y, sourceEPSG, targetEPSG1, targetEPSG2, inputDialog) {
 var sourceCrs = CoordinateReferenceSystemUtils.fromDescription("EPSG:" + parseFloat(sourceEPSG))
 var targetCrs1 = CoordinateReferenceSystemUtils.fromDescription("EPSG:" + parseFloat(targetEPSG1))
 var targetCrs2 = CoordinateReferenceSystemUtils.fromDescription("EPSG:" + parseFloat(targetEPSG2))

 if (inputDialog !== 1) { // Update IG
 var igPoint = GeometryUtils.reprojectPoint(GeometryUtils.point(x, y), sourceCrs, CoordinateReferenceSystemUtils.fromDescription("EPSG:29903"))
 igInputBox.isProgrammaticUpdate = true
 igInputBox.text = getIGFromXY(igPoint.x, igPoint.y)
 }

 if (inputDialog !== 2) { // Update UK
 var ukPoint = GeometryUtils.reprojectPoint(GeometryUtils.point(x, y), sourceCrs, CoordinateReferenceSystemUtils.fromDescription("EPSG:27700"))
 ukInputBox.isProgrammaticUpdate = true
 ukInputBox.text = getUKFromXY(ukPoint.x, ukPoint.y)
 }

 if (inputDialog !== 3) { // Update Custom1
 var custom1Point = GeometryUtils.reprojectPoint(GeometryUtils.point(x, y), sourceCrs, targetCrs1)
 custom1BoxXY.isProgrammaticUpdate = true
 custom1BoxXY.text = formatPoint(custom1Point, targetCrs1)
 }

 if (inputDialog !== 4) { // Update Custom2
 var custom2Point = GeometryUtils.reprojectPoint(GeometryUtils.point(x, y), sourceCrs, targetCrs2)
 custom2BoxXY.isProgrammaticUpdate = true
 custom2BoxXY.text = formatPoint(custom2Point, targetCrs2)
 }

 if (inputDialog !== 5) { // Update WGS84
 var wgs84Point = GeometryUtils.reprojectPoint(GeometryUtils.point(x, y), sourceCrs, CoordinateReferenceSystemUtils.fromDescription("EPSG:4326"))
 wgs84Box.isProgrammaticUpdate = true
 wgs84Box.text = parseFloat(wgs84Point.y.toFixed(decimalsd.text)) + ", " + parseFloat(wgs84Point.x.toFixed(decimalsd.text))
 }

 if (inputDialog !== 6) { // Update WGS84 DDM
 var wgs84dmPoint = GeometryUtils.reprojectPoint(GeometryUtils.point(x, y), sourceCrs, CoordinateReferenceSystemUtils.fromDescription("EPSG:4326")) 
 wgs84DMBox.isProgrammaticUpdate = true
 wgs84DMBox.text = decimalToDDM(wgs84dmPoint.y) + ", " + decimalToDDM(wgs84dmPoint.x)
 
 wgs84DMSBox.text = decimalToDMss(wgs84dmPoint.y) + ", " + decimalToDMss(wgs84dmPoint.x)

 // Update d m s boxes
 latDegrees.text = decTODeg(wgs84dmPoint.y)
 latMinutes.text = decimalToMinutes(wgs84dmPoint.y)
 latSeconds.text = degtoSeconds(wgs84dmPoint.y)
 lonDegrees.text = decTODeg(wgs84dmPoint.x)
 lonMinutes.text = decimalToMinutes(wgs84dmPoint.x)
 lonSeconds.text = degtoSeconds(wgs84dmPoint.x) 

 } 
 }

function justIG(source,crs){ 
var point = GeometryUtils.reprojectPoint(GeometryUtils.point(source.x, source.y),  CoordinateReferenceSystemUtils.fromDescription("EPSG:"+crs) , CoordinateReferenceSystemUtils.fromDescription("EPSG:29903"))
 return getIGFromXY(point.x, point.y)
 }


function justUKG(source,crs){ 
var point = GeometryUtils.reprojectPoint(GeometryUtils.point(source.x, source.y),  CoordinateReferenceSystemUtils.fromDescription("EPSG:"+crs) , CoordinateReferenceSystemUtils.fromDescription("EPSG:27700"))
 return getUKFromXY(point.x, point.y)
 }


function justLL(source,crs){ 
var point = GeometryUtils.reprojectPoint(GeometryUtils.point(source.x, source.y),  CoordinateReferenceSystemUtils.fromDescription("EPSG:"+crs) , CoordinateReferenceSystemUtils.fromDescription("EPSG:4326"))
return ( point.y.toFixed(decimalsd.text)+", "+ point.x.toFixed(decimalsd.text) )

 }

 
 function formatPoint(point, crs) {
 if (!crs.isGeographic) {
 return parseFloat(point.x.toFixed(decimalsm.text)) + ", " + parseFloat(point.y.toFixed(decimalsm.text))
 } else {
 return parseFloat(point.x.toFixed(decimalsd.text)) + ", " + parseFloat(point.y.toFixed(decimalsd.text))
 }
 }


 function decimalToMinutes(decimal) {

if (typeof decimal !== 'number' || isNaN(decimal)) return ''

    var sign = decimal < 0 ? '-' : '';
    var absDecimal = Math.abs(decimal);

    var degrees = Math.floor(absDecimal);
    var minutes = Math.floor((absDecimal - degrees) * 60);
    var seconds = ((absDecimal - degrees - minutes / 60) * 3600).toFixed(2);

    return minutes;
}

 function decimalToDMss(decimal) {

if (typeof decimal !== 'number' || isNaN(decimal)) return ''

    var sign = decimal < 0 ? '-' : '';
    var absDecimal = Math.abs(decimal);

    var degrees = Math.floor(absDecimal);
    var minutes = Math.floor((absDecimal - degrees) * 60);
    var seconds = ((absDecimal - degrees - minutes / 60) * 3600).toFixed(2);

    return `${sign}${degrees}° ${minutes}' ${seconds}"`;
}
 

}
