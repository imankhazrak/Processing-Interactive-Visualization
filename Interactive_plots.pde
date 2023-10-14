/*
 *---------------------------------------------------------------------------
 * Interactive Visualization in Processing:
 *            Car.data
 *---------------------------------------------------------------------------
 * Description:
 *   This code offers multiple visualization methods for data exploration 
 *   using Processing. Features include:
 *     - Interactive scatter plot with hover capability
 *     - Menu to select:
 *          - Histogram for yearly data distribution
 *          - Bar chart illustrating data counts based on origin
 *     - Dashboard to select variables for scatter plots with a Legend and utility functions to support the visualizations
 *     - Outlier detection based on z-scores
 *
 * Note:
 *   This code assumes the presence of a table with data on various car 
 *   attributes including model, MPG, cylinders, horsepower, weight, 
 *   acceleration, year, and origin.
 *
 * Authors: Iman Khazrak, Ujjwal Kuikel
 * Course : CS 6260
 * Instructor: Dr. Lee
 * Date: 10/15/2023
 *---------------------------------------------------------------------------
 */


// Constants and Global Variables
final float minEllipseSize = 5;  // Minimum ellipse size
final float maxEllipseSize = 20; // Maximum ellipse size

// Import statements
import g4p_controls.*;
import java.util.HashSet;

// Constants and Configurations
String[] menuOptions = {"Histogram: Count vs Year", "Bar Chart: Count vs Origin"};
String[] columns = {"Displacement", "Horsepower", "Weight", "Acceleration"};
float outlierThreshold = 2.5;  // Threshold for outliers

// GUI Components
GDropList dropdownX, dropdownY;
GButton button;

// Variables for Visualization
Table table;
int selectedOption = 0;
color[] barColors1;  // Color array for the first bar chart
color[] barColors2;  // Color array for the second bar chart
float[] outliers;    // Store indices of outlier data points
String[] variableXOptions = {"Acceleration", "Displacement", "Horsepower", "Weight", "Origin", "Year"};
String[] variableYOptions = {"MPG", "Acceleration", "Displacement", "Horsepower", "Weight"};
String[] variableYOptions_2 = {"Acceleration", "Horsepower", "Displacement", "Weight"};
Boolean drawPlot;
float collinearityResult;


// --------------------------- Event Handlers ---------------------------

void mousePressed() {
    for (int i = 0; i < menuOptions.length; i++) {
        float optionX = 10 + i * 210; 
        float optionY = 50; 
        if (isMouseOver(optionX, optionY, 200, 25)) {
            selectedOption = i;
        }
    }
}


void displayMenu() {
  for (int i = 0; i < menuOptions.length; i++) {
    fill(i == selectedOption ? color(200, 0, 0) : 200);
    float x = 10 + i * 210; // Adjust the spacing as needed
    float y = 50; // Move the menu down by 100 pixels
    rect(x, y, 200, 25); // Set the Y-coordinate to the new position
    fill(0);
    text(menuOptions[i], x + 10, y + 15); // Adjust the X and Y position of the text
  }
}

// --------------------------- GUI Creation ---------------------------

void createGUI() {
    dropdownX = new GDropList(this, 1300, 200, 150, 200);
    dropdownX.setItems(variableXOptions, 0);

    dropdownY = new GDropList(this, 1300, 250, 150, 200);
    dropdownY.setItems(variableYOptions, 0);
}

// --------------------------- Setup Creation --------------------------
void setup() {
  // Setup Window
  size(1850, 1080, JAVA2D);

  // Initialize Table and Columns
  table = new Table();
  table.addColumn("Model");
  table.addColumn("MPG");
  table.addColumn("Cylinders");
  table.addColumn("Displacement");
  table.addColumn("Horsepower");
  table.addColumn("Weight");
  table.addColumn("Acceleration");
  table.addColumn("Year");
  table.addColumn("Origin");

  // Load Data and Populate Table
  String[] names = loadStrings("cars.names");
  String[] dataLines = loadStrings("cars.data");
  
  for (String name : names) {
    String modelName = name.substring(1, name.length() - 1);  // Remove quotes
    String[] dataFields = dataLines[table.getRowCount()].split("\\s+");
    
    TableRow newRow = table.addRow();
    newRow.setString("Model", modelName);
    newRow.setFloat("MPG", parseFloat(dataFields[0]));
    newRow.setInt("Cylinders", int(dataFields[1]));
    newRow.setFloat("Displacement", parseFloat(dataFields[2]));
    newRow.setFloat("Horsepower", parseFloat(dataFields[3]));
    newRow.setFloat("Weight", parseFloat(dataFields[4]));
    newRow.setFloat("Acceleration", parseFloat(dataFields[5]));
    newRow.setInt("Year", int(dataFields[6]));
    newRow.setInt("Origin", int(dataFields[7]));
  }

  // Post Load Configurations
  println("Loaded " + table.getRowCount() + " rows into the table.");

  // Setup Visualization Properties
  barColors1 = generateRandomColors(20);
  barColors2 = generateRandomColors(20);
  drawPlot = true;
  createGUI();

}
// --------------------------- Draw creation ---------------------------
void draw() {
  // Set the background and display the menu
  background(255);
  pushStyle();  // Save the current drawing style
  displayMenu();
  popStyle();  // Restore the saved drawing style

  // Handle selected menu option
  switch (selectedOption) {
    case 0:
      pushStyle();  // Save the current drawing style
      histogram(100,150,200,200);
      popStyle();  // Restore the saved drawing style
      break;
    case 1:
      pushStyle();  // Save the current drawing style
      barChart();
      popStyle();  // Restore the saved drawing style
      break;
  }

  // Display the main weighted scatter plot based on dropdown selections
  String selectedVariableX = dropdownX.getSelectedText();
  String selectedVariableY = dropdownY.getSelectedText();
  weightedScatterPlot(selectedVariableX, selectedVariableY, 750, 20, 500, 500); 
  
  // Display a row of smaller scatter plots based on variableYOptions_2
  int xOffset = 80;
  int yOffset = 400;
  int plotWidth = 300; // Adjust the width as needed
  int plotHeight = 300; // Adjust the height as needed
  int spacing = 50;

  for (String variableX : variableYOptions_2) {
    ScatterPlotwithOutliers( variableX, "MPG", xOffset, yOffset, plotWidth, plotHeight);
    xOffset += plotWidth + spacing; // Move the x offset for the next plot
  }
}

// --------------------------- Visualization Functions ---------------------------

void ScatterPlotwithOutliers(String varX, String varY, int xPosition, int yPosition, int plotWidth, int plotHeight) {
    pushStyle();   
  // Get data
    String variableNameX = varX;
    String variableNameY = "MPG";
    float[] valuesX = table.getFloatColumn(variableNameX);
    float[] valuesY = table.getFloatColumn(variableNameY);

    // Calculate minimum and maximum values for X and Y axes
    float minX = min(valuesX);
    float maxX = max(valuesX);
    float minY = min(valuesY);
    float maxY = max(valuesY);

    // Define plot margins
    float leftMargin = xPosition;
    float rightMargin = xPosition + plotWidth;
    float topMargin = yPosition + 200;
    float bottomMargin = yPosition + plotHeight + 200;

    // Detect outliers
    float[] outlier = detectOutliers(varX);

    // Draw axes
    stroke(0);
    fill(0);
    line(leftMargin, bottomMargin, rightMargin, bottomMargin); // X-axis
    line(leftMargin, topMargin, leftMargin, bottomMargin); // Y-axis
    text("MPG", leftMargin - 40, (topMargin + bottomMargin) / 2);
    text(variableNameX, (leftMargin + rightMargin) / 2, bottomMargin + 10);

    int selectedPoint = -1; // Keep track of the selected point

    // Draw data points and check for selected point
    noFill();
    for (int i = 0; i < valuesX.length; i++) {
        if (Float.isNaN(valuesX[i]) || Float.isNaN(valuesY[i])) {
        // Handle the case when the value is NaN
        continue;
        }
        float x = map(valuesX[i], minX, maxX, leftMargin, rightMargin);
        float y = map(valuesY[i], minY, maxY, bottomMargin, topMargin);
        float d = dist(x, y, mouseX, mouseY); // Distance between mouse and data point
        
        // Check for hover after drawing the point to ensure hover effect is visible
        if (d < 5) { // Increased the threshold to 5
            selectedPoint = i;
            fill(0, 255, 0); // Changed color to yellow for distinction
            ellipse(x, y, 10, 10);
        }else {
        if (outlier[i] == 1) {
          stroke(255, 0, 0);
          ellipse(x, y, 10, 10);
        } else {
          stroke(50, 100, 200);
          ellipse(x, y, 5, 5);
        }
        }
    
        
  

    // Title of the scatter plot
    stroke(0);
    fill(100, 0, 0); 
    textSize(16); 
    text("Scatter Plot with Outliers", 600, 950);
    }
    // If a point is selected, display its details
    if (selectedPoint != -1) {
        fill(0);
        textAlign(LEFT);
        String info = "Car Name: " + table.getString(selectedPoint, "Model") + "\n" +
                      "MPG: " + table.getString(selectedPoint, "MPG") + "\n" +
                      "Cylinders: " + table.getString(selectedPoint, "Cylinders") + "\n" +
                      "Displacement: " + table.getString(selectedPoint, "Displacement") + "\n" +
                      "Horsepower: " + table.getString(selectedPoint, "Horsepower") + "\n" +
                      "Weight: " + table.getString(selectedPoint, "Weight") + "\n" +
                      "Acceleration: " + table.getString(selectedPoint, "Acceleration") + "\n" +
                      "Year: " + table.getString(selectedPoint, "Year") + "\n" +
                      "Origin: " + table.getString(selectedPoint, "Origin");
        
        float x1 = map(valuesX[selectedPoint], minX, maxX, leftMargin, rightMargin);
        float y1 = map(valuesY[selectedPoint], minY, maxY, bottomMargin, topMargin);
        rect(x1 + 10, y1 - 65, 250, 150); // Background for the text
        fill(255);
        text(info, x1 + 10, y1 - 50);
    }
    popStyle();
}



void weightedScatterPlot(String varX,String varY, int xPosition, int yPosition, int width1, int height1) {
  pushStyle();
  String variableNameX = varX;
  String variableNameY = varY;

  float[] valuesX = table.getFloatColumn(variableNameX);
  float[] valuesY = table.getFloatColumn(variableNameY);
  float minX = min(valuesX);
  float maxX = max(valuesX);
  float minY = min(valuesY);
  float maxY = max(valuesY);

  float minWeight = min(table.getFloatColumn("Weight"));
  float maxWeight = max(table.getFloatColumn("Weight"));
  //final float minEllipseSize = 5;  // Minimum ellipse size
  //final float maxEllipseSize = 20; // Maximum ellipse size

  stroke(0);
  line(xPosition, height1 + yPosition, width1 + xPosition, height1 + yPosition); // X-axis
  line(xPosition,  yPosition, xPosition, height1 + yPosition); // Y-axis

  noFill();
  int selectedPoint = -1; // Keep track of the selected point

  for (int i = 0; i < valuesX.length; i++) {
    if (Float.isNaN(valuesX[i]) || Float.isNaN(valuesY[i])) {
      // Handle the case when the value is NaN
      continue;
    }

    float x = map(valuesX[i], minX, maxX,  xPosition, width1 + xPosition);
    float y = map(valuesY[i], minY, maxY, height1 + yPosition, yPosition);

    float d = dist(x, y, mouseX, mouseY); // Calculate the distance between mouse and data point

    float weight = table.getFloat(i, "Weight");
      float ellipseSize = map(weight, minWeight, maxWeight, 8, 8); //minEllipseSize, maxEllipseSize
      String origin = table.getString(i, "Origin");
    if (d < 5) { // Adjust the threshold as needed for proper hovering
      // Mouse is over this data point
      selectedPoint = i;
      fill(255, 0, 0); // Red
       
       ellipse(x, y, ellipseSize, ellipseSize);
    } else {
     
      // Draw regular data points with different colors based on the "Origin" value
      
      if (origin.equals("1")) {
        fill(255, 0, 0); // Red  before: (255, 180, 40)
      } else if (origin.equals("2")) {
        fill(0, 255, 0); // Green (150, 255, 150)
      } else if (origin.equals("3")) {
        fill(0, 0, 255); // Blue (150, 150, 255)
      } 
     ellipse(x, y, ellipseSize, ellipseSize);
    }

    
  }

  if (selectedPoint != -1) {
    // Display data for the selected point
    fill(0);
    textAlign(LEFT);
    String info = "Car Name: " + table.getString(selectedPoint, "Model") + "\n" +
              "MPG: " + table.getString(selectedPoint, "MPG") + "\n" +
              "Cylinders: " + table.getString(selectedPoint, "Cylinders") + "\n" +
              "Displacement: " + table.getString(selectedPoint, "Displacement") + "\n" +
              "Horsepower: " + table.getString(selectedPoint, "Horsepower") + "\n" +
              "Weight: " + table.getString(selectedPoint, "Weight") + "\n" +
              "Acceleration: " + table.getString(selectedPoint, "Acceleration") + "\n" +
              "Year: " + table.getString(selectedPoint, "Year") + "\n" +
              "Origin: " + table.getString(selectedPoint, "Origin");
    float x = map(valuesX[selectedPoint], minX, maxX, xPosition, width1 + xPosition);
    float y = map(valuesY[selectedPoint], minY, maxY, height1+ yPosition,yPosition);
    rect(x + 10, y - 65, 250, 150); // Draw a rectangle as the text background
    fill(255); // Set the background color for the text
    text(info, x + 10, y - 50);
  }

  fill(0);
  textAlign(CENTER, CENTER);
  text(variableNameX, 50+xPosition + width1 / 2, height1 + 10 + yPosition); // X-axis label
  text(variableNameY, xPosition-20, (height1) / 2 + yPosition); // Y-axis label
  textSize(18);
  text("Interactive scatterplot", xPosition + width1 / 2, yPosition);
  
  // Draw the legend
  int legendX = xPosition +550; // Adjust the X position as needed
  int legendY = yPosition +100 ; // Adjust the Y position as needed
  int legendCircleSize  = 15;
  float spacing = 10;

  String[] originLabels = {"American", "European", "Japanese"};
  int[] originColors = {color(255, 0, 0), color(0, 255, 0), color(0, 0, 255)};

  for (int i = 0; i < originLabels.length; i++) {
    fill(originColors[i]);
    ellipse(legendX + legendCircleSize / 2, legendY + i * (legendCircleSize + spacing) + legendCircleSize / 2, legendCircleSize, legendCircleSize);
    fill(0);
    textAlign(LEFT, CENTER);
    text(originLabels[i], legendX + legendCircleSize + 5, legendY + i * (legendCircleSize + spacing) + legendCircleSize / 2);
  }

 popStyle();
}


void histogram(int xPosition, int yPosition, int width1, int height1) {
  pushStyle();
  stroke(0);
  fill(255);
  int[] bins = new int[13]; // Assuming years from 1970 to 1982 inclusive
  for (TableRow row : table.rows()) {
    int year = row.getInt("Year");
    bins[year - 70]++;
  }
  textSize(12);
  for (int i = 0; i < bins.length; i++) {
    
    fill(barColors1[i]);
    float barHeight = -bins[i] * 4;
     float x = xPosition + i * 40;
    float y = yPosition + height1;
    rect(x, y, 30, barHeight);
    
    // Display the height of the bar on top of it
    textSize(14);
    fill(0);  // Set text color to black
     if (mouseX > x && mouseX < x + 30 && mouseY > y + barHeight && mouseY < y) {
      // Mouse is over the bar
      text(bins[i], x + 15, min(y, y + barHeight) - 10);
       stroke(0, 0, 60); // Darker stroke color
       strokeWeight(2); // Adjust stroke thickness
      rect(x, y, 30, barHeight);
      
    }
   // Reset stroke settings outside of the hover condition
  stroke(0); // Reset stroke color
  strokeWeight(1); // Reset stroke thickness
    
    // Display the year label at the bottom of each bar
    textSize(12);
    text(1970 + i, xPosition + i * 40 + 2, yPosition + height1+10);
  }
  textSize(14);
  // Axes and labels
  line(xPosition, yPosition + height1, xPosition + width1+320, yPosition + height1); // X-axis
  line(xPosition, yPosition, xPosition, yPosition + height1); // Y-axis
  text("Year",(2*xPosition + width1+320)/2, yPosition + height1 + 25);
  text("Count", xPosition/2, yPosition*1.5);
  popStyle();
}


void barChart() {
  pushStyle();
  int[] origins = new int[3]; // Assuming 3 origins
  String[] originLabels = {"American", "European", "Japanese"}; // Labels for the origins
  for (TableRow row : table.rows()) {
    int origin = row.getInt("Origin");
    origins[origin - 1]++;
  }
  for (int i = 0; i < origins.length; i++) {
    fill(100, 0, 100);
    float barHeight = -origins[i] * 0.75;
    rect(100 + i * 150, height / 4 + 100, 100, barHeight);
    
    // Add x-axis labels
    textAlign(CENTER);
    text(originLabels[i], 100 + i * 150 + 50, height / 4 + 120);
    
    // Add bar height on top of the bar
    textAlign(CENTER, BOTTOM); // Align text to the bottom-center
    text(Integer.toString(origins[i]), 100 + i * 150 + 50, height / 4 + 90 + barHeight);
  }
  // Axes and labels
  line(100, height / 4 + 100, 600, height / 4 + 100); // X-axis
  line(100, 100, 100, height / 4 + 100); // Y-axis
  fill(0);
  text("Origin", 300, height / 4 + 150);
  text("Frequency", 50, height / 8 + 100);
  popStyle();
}



void drawLegend(int xPosition, int yPosition) {
    int legendX = xPosition ; 
    int legendY = yPosition;
    int legendCircleSize = 15;
    float spacing = 10;

    String[] originLabels = {"American", "European", "Japanese"};
    int[] originColors = {color(255, 0, 0), color(0, 255, 0), color(0, 0, 255)};

    for (int i = 0; i < originLabels.length; i++) {
        fill(originColors[i]);
        ellipse(legendX + legendCircleSize / 2, legendY + i * (legendCircleSize + spacing) + legendCircleSize / 2, legendCircleSize, legendCircleSize);
        fill(0);
        textAlign(LEFT, CENTER);
        text(originLabels[i], legendX + legendCircleSize + 5, legendY + i * (legendCircleSize + spacing) + legendCircleSize / 2);
    }
}

// --------------------------- Utility Functions ---------------------------

boolean isMouseOver(float x, float y, float w, float h) {
    return mouseX >= x && mouseX <= x + w && mouseY >= y && mouseY <= y + h;
}

color[] generateRandomColors(int numColors) {
    color[] colors = new color[numColors];
    for (int i = 0; i < numColors; i++) {
        colors[i] = color(random(255), random(255), random(255));
    }
    return colors;
}

float[] detectOutliers(String varX) {
  String variableNameX = varX;
  float[] valuesX = table.getFloatColumn(variableNameX);
  float meanX = mean(valuesX);
  float stdDevX = standardDeviation(valuesX);
  outliers = new float[valuesX.length];
  for (int i = 0; i < valuesX.length; i++) {
    float zScore = (valuesX[i] - meanX) / stdDevX;
    if (abs(zScore) > outlierThreshold) {
      outliers[i] = 1;
    } else {
      outliers[i] = 0;
    }
  }
  return outliers;
}

float mean(float[] data) {
    float sum = 0;
    for (float value : data) {
        sum += value;
    }
    return sum / data.length;
}

float standardDeviation(float[] data) {
    float avg = mean(data);
    float sum = 0;
    for (float value : data) {
        sum += pow(value - avg, 2);
    }
    return sqrt(sum / (data.length - 1));
}

float median(float[] data) {
    int middle = data.length / 2;
    if (data.length % 2 == 0) {
        return (data[middle - 1] + data[middle]) / 2.0;
    }
    return data[middle];
}
