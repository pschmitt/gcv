import java.util.Properties;
import java.util.Date;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.text.ParseException;
import java.util.GregorianCalendar;

String repository;
JSONArray json;
color[] colors;
int weeksSinceCreation;
int maxContributions;
float rotationAngle;
float customRotationAngle;

PFont normalFont;
PFont titleFont;

Properties loadCommandLine() {
  Properties props = new Properties();
  props.setProperty("repo", args[0]);
  return props;
}

void setup() {
  size(400, 400);
  if (frame != null) {
    frame.setResizable(true);
  }

  titleFont = createFont("Sans", 40, true);
  normalFont = createFont("Sans", 12, true);
  textFont(normalFont);

  smooth();


  // Get CLI parameters
  Properties props = loadCommandLine();
  repository = props.getProperty("repo", "No repository specified.");

  String githubApi = "https://api.github.com/repos/" + repository;
  JSONObject repoStats = loadJSONObject(githubApi);

  try {
    SimpleDateFormat df = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'");
    Date d = df.parse(repoStats.getString("created_at"));
    Date n = new Date();

    long now = n.getTime();
    long then = d.getTime();

    weeksSinceCreation = (int)Math.abs((now-then)/(1000*60*60*24*7));

    println("Created at: " + d);
  } catch (ParseException e) {
    println("Couldn't parse date..");
  }

  json = loadJSONArray(githubApi + "/stats/contributors");

  int contributors = json.size();
  rotationAngle = TWO_PI / contributors;

  println("# Contributors: " + contributors);
  println("rotationAngle: " + rotationAngle);

  // Randomly reorganize the data
  JSONArray randomArray = new JSONArray();

  while (json.size() > 0) {
    int randomIndex = (int)random(0, json.size());
    JSONObject j = json.getJSONObject(randomIndex);

    int contributions = j.getInt("total");
    JSONObject author = j.getJSONObject("author");
    String login = author.getString("login");

    if (contributions > maxContributions) {
      maxContributions = contributions;
    }
    randomArray.append(j);
    json.remove(randomIndex);
    println("Author " + login + " made "  + contributions + " contributions");
  }
  json = randomArray;

  colors = new color[json.size()];
  for (int i = 0; i < json.size(); ++i) {
    colors[i] = color((int)random(0, 255), (int)random(0, 255), (int)random(0, 255));
  }
}

double zoomFactor = 1.0;

void mouseWheel(MouseEvent event) {
  float e = event.getAmount();
  zoomFactor += e * -0.5;
  if (zoomFactor < 1.0)
    zoomFactor = 1.0;
  // println(e);
}

void keyPressed() {
  switch (key) {
    case '+':
      // rotationAngle += 0.001;
      customRotationAngle += 0.01;
      break;
    case '-':
      // rotationAngle -= 0.001;
      customRotationAngle -= 0.01;
      break;
    case 'q':
      exit();
      break;
    default:
      println("Pressed: " + key);
      break;
  }
}

void drawTitle(double maxSized) {
  float r = (float)(maxContributions * maxSized);
  // We must keep track of our position along the curve
  float arclength = 0;

  textFont(titleFont);
  // For every box
  for (int i = 0; i < repository.length(); i++)
  {
    // Instead of a constant width, we check the width of each character.
    StringBuilder b = new StringBuilder();
    char c = repository.charAt(i);
    b.append(c);
    float w = textWidth(b.toString());

    // Each box is centered so we move half the width
    arclength += w/2;
    // Angle in radians is the arclength divided by the radius
    // Starting on the left side of the circle by adding PI
    float theta = PI + arclength / r;

    pushMatrix();
    // Polar to cartesian coordinate conversion
    translate(r*cos(theta), r*sin(theta));
    // Rotate the box
    rotate(theta+PI/2); // rotation is offset by 90 degrees
    // Display the character
    fill(127);
    text(b.toString(),0,0);
    popMatrix();
    // Move halfway again
    arclength += w/2;
  }

  textFont(normalFont);
}

void drawData(double maxSized) {
  for (int i = 0; i < json.size(); i++) {
      JSONObject current = json.getJSONObject(i);
      JSONObject author = current.getJSONObject("author");
      String login = author.getString("login");
      int contributions = current.getInt("total");
      /* int weeks = current.getJSONArray("weeks").size(); */
      JSONArray weeksAr =  current.getJSONArray("weeks");

      // Actual drawing
      int alphaValue = 255;
      for (int j = 0; j < weeksAr.size(); ++j) {
        if (weeksAr.getJSONObject(j).getInt("c") <= 0)
          alphaValue -= 10;
      }

      fill(color(red(colors[i]), green(colors[i]), blue(colors[i]), alphaValue));
      rotate(rotationAngle);
      rect(0, 0, 10, (int)(contributions * maxSized));
      //noFill();
      /* float t = (TWO_PI / weeksSinceCreation) * weeks; */
      /* println("weeks: "  + weeks + (TWO_PI / weeksSinceCreation) + " - " +  t); */
      /* arc(0, 0, (int)(contributions * maxSized * 2), (int)(contributions * maxSized * 2), 0, t); */
      pushMatrix();
      {
        translate(10, (int)(contributions * maxSized));
        rotate(HALF_PI);
        fill(colors[i]);
        text(author.getString("login"), 3, 10);
      }
      popMatrix();
  }
}

void draw() {
  clear();
  translate(width/2, height/2);

  int maxSize = min(width/2, height/2) - 40;
  double maxSized = ((double)maxSize / maxContributions) * zoomFactor;

  // Draw background
  fill(255);
  ellipse(0, 0, (int)(maxContributions * maxSized * 2), (int)(maxContributions * maxSized * 2));

  drawTitle(maxSized);
  rotate(customRotationAngle);
  drawData(maxSized);
}

// vim: set ft=processing et ts=2 :
