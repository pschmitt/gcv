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
double zoomFactor = 1.0;

int minContributions = 1;

PFont normalFont;
PFont titleFont;

Properties loadCommandLine() {
  Properties props = new Properties();
  // Default to self
  String r = "pschmitt/github-contributions-visualisation";
  if (args[0] != null) {
    r = args[0];
  }
  props.setProperty("repo", r);

  if (args.length > 1 && args[1] != null) {
    props.setProperty("token", args[1]);
  }

  return props;
}

void setup() {
  size(400, 400);
  if (frame != null) {
    frame.setResizable(true);
  }

  // Default font settings
  titleFont = createFont("Sans", 40, true);
  normalFont = createFont("Sans", 12, true);
  textFont(normalFont);

  smooth();


  // Get CLI parameters
  Properties props = loadCommandLine();
  repository = props.getProperty("repo", "No repository specified.");
  String token = props.getProperty("token", null);

  String githubApi = "https://api.github.com/repos/" + repository;
  JSONObject repoStats = loadJSONObject(token != null ? githubApi + "?access_token=" + token : githubApi);

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

  json = loadJSONArray(token != null ? githubApi + "/stats/contributors?access_token=" + token : githubApi + "/stats/contributors");

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

  // Random colors
  colors = new color[json.size()];
  for (int i = 0; i < json.size(); ++i) {
    colors[i] = color((int)random(0, 255), (int)random(0, 255), (int)random(0, 255));
  }
}

void mouseWheel(MouseEvent event) {
  float e = event.getAmount();
  zoomFactor += e * -0.5;
  if (zoomFactor < 1.0)
    zoomFactor = 1.0;
  if (zoomFactor > 250)
    zoomFactor = 250;
  println(zoomFactor);

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
    case CODED:
      println("Min Contributions:" + minContributions);
      switch(keyCode) {
        case LEFT:
          if (minContributions > 0) {
            minContributions--;
          }
          break;
        case RIGHT:
          if (minContributions < maxContributions) {
            minContributions++;
          }
          break;
        case 34: // PAGE_DOWN
         if (minContributions - 50 > 0) {
            minContributions -= 50;
          }
          break;
        case 33: // PAGE_UP
         if (minContributions + 50 < maxContributions) {
            minContributions += 50;
          }
          break;
        default:
          println("Special key Pressed: " + keyCode);
          break;
      }
      break;
    case 'q':
      exit();
      break;
    default:
      println("Pressed: " + key);
      break;
  }
}

void drawTextAroundElipse(String msg, float r) {
  // We must keep track of our position along the curve
  float arclength = 0;

  // For every box
  for (int i = 0; i < msg.length(); i++)
  {
    // Instead of a constant width, we check the width of each character.
    StringBuilder b = new StringBuilder();
    char c = msg.charAt(i);
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
    rotate(theta+HALF_PI); // rotation is offset by 90 degrees
    // Display the character
    fill(127);
    text(b.toString(),0,0);
    popMatrix();
    // Move halfway again
    arclength += w/2;
  }
}

void drawTitle(double maxSized) {
  textFont(titleFont);
  drawTextAroundElipse(repository, (float )(maxContributions * maxSized));
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

      rotate(rotationAngle);
      if (contributions >= minContributions) {
        // Actual drawing
        int alphaValue = 255;
        for (int j = 0; j < weeksAr.size(); ++j) {
          if (weeksAr.getJSONObject(j).getInt("c") <= 0)
            alphaValue -= 1;
        }

        fill(color(red(colors[i]), green(colors[i]), blue(colors[i]), alphaValue));
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
}

void drawTransparencyExplanation() {
  fill(100);
  // Description
  int descTextHeight = 22;
  String desc = "Code regularity";
  text(desc, width / 2 - textWidth(desc) / 2, descTextHeight + 2);

  rect(width / 4, 20 + descTextHeight, width / 2, 15);

  float step = (float)width / 2 / 255;
  //println("Step: " + step);
  noStroke();
  for (int i = 0; i < 255; i++) {
    fill(color(255, 0, 0, i));
    // println("Draw rect at: " + (width / 4 + step * i) + "x" + (20 + descTextHeight));
    rect(width / 4 + step * i, 20 + descTextHeight, step, 15);
  }
}

void drawMinContributions() {
  int diff = maxContributions - minContributions;
  float step = (width / 2) / (float)maxContributions;
  // println("diff: " + diff + " step: " + step);

  fill(100);
  // Description
  String desc = "Min. contributions";
  text(desc, width / 2 - textWidth(desc) / 2, height - 2);
  // FIXME
  // translate(0, height - 22);
  int descTextHeight = 22;

  // Background rect
  stroke(100);
  // Graduations
  text("0", width / 4 - textWidth("0") - 10, height - 8 - descTextHeight);
  text(Integer.toString(maxContributions), 3 * width / 4 + 10, height - 8 - descTextHeight);

  rect(width / 4, height - 20 - descTextHeight, width / 2, 15);

  // Fake slider
  fill(0);
  // Graduation
  rect(width / 4, height - 20 - descTextHeight, (width / 2) - (diff * step), 15);
  fill(100);
  text(Integer.toString(minContributions), (3 * width / 4) - (diff * step) - textWidth(Integer.toString(minContributions)) / 2, height - 24 - descTextHeight);
  // Reset
  stroke(0);
}

void drawGraduations(double maxSized) {
  int[] graduations = new int[] { 1, 10, 25, 50, 100, 250, 500, 1000, 2000, 50000, 10000};
  for (int g : graduations) {
    if (g < maxContributions) {
      noFill();
      stroke(100);
      ellipse(0, 0, (int)(g * maxSized * 2), (int)(g * maxSized * 2));
      drawTextAroundElipse(Integer.toString(g), (float)(g*maxSized));
      stroke(0);
    }
  }
}

void drawBackgroundElipse(double maxSized) {
  fill(color(22, 22, 22));
  ellipse(0, 0, (int)(maxContributions * maxSized * 2), (int)(maxContributions * maxSized * 2));
}

void drawCenter() {
  fill(37);
  ellipse(0, 0, 20, 20);
}

void draw() {
  fill(20);
  clear();
  pushMatrix();
  {
    translate(width/2, height/2);

    int maxSize = min(width/2, height/2) - 40;
    double maxSized = ((double)maxSize / maxContributions) * zoomFactor;

    // Draw background
    drawBackgroundElipse(maxSized);

    drawGraduations(maxSized);

    drawTitle(maxSized);
    rotate(customRotationAngle);
    drawData(maxSized);
    drawCenter();
  }
  popMatrix();
  drawTransparencyExplanation();
  drawMinContributions();
}

// vim: set ft=processing et ts=2 :
