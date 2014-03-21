import java.util.Properties;
import java.util.Date;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.text.ParseException;
import java.util.GregorianCalendar;

String repository;
JSONArray json;
JSONArray origData;
color[] colors;

int weeksSinceCreation;
int maxContributions;
float rotationAngle;
float customRotationAngle;
double zoomFactor = 1.0;
boolean hideHelp = false;
boolean randomize = false;

int minContributions = 1;

PFont normalFont;
PFont titleFont;

private static final int MAX_ZOOM_FACTOR = 350;

Properties loadCommandLine() {
  Properties props = new Properties();
  // Default to self
  String r = "pschmitt/github-contributions-visualisation";
  if (args.length > 0 && args[0] != null) {
    r = args[0];
  }
  props.setProperty("repo", r);

  if (args.length > 1 && args[1] != null) {
    props.setProperty("token", args[1]);
  }

  return props;
}

void getData() {
  json = new JSONArray();
  for (int i = 0; i < origData.size(); ++i) {
    json.append(origData.getJSONObject(i));
  }

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
  json = randomize ? randomArray : origData;
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
  JSONObject repoStats = null;
  try {
    repoStats = loadJSONObject(token != null ? githubApi + "?access_token=" + token : githubApi);
  } catch (Exception e) {
    println("Caught an exception, exiting.");
    e.printStackTrace();
    exit();
  }

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

  try {
    origData = loadJSONArray(token != null ? githubApi + "/stats/contributors?access_token=" + token : githubApi + "/stats/contributors");
  } catch (Exception e) {
    println("Caught an exception, exiting.");
    e.printStackTrace();
    exit();
  }

  int contributors = origData.size();
  rotationAngle = TWO_PI / contributors;

  println("# Contributors: " + contributors);
  println("rotationAngle: " + rotationAngle);

  getData();

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
  if (zoomFactor > MAX_ZOOM_FACTOR)
    zoomFactor = MAX_ZOOM_FACTOR;
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
    case 'h':
      hideHelp = !hideHelp;
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
        case UP:
          if (zoomFactor + 20.0 < MAX_ZOOM_FACTOR) {
            zoomFactor += 20.0;
          } else {
            zoomFactor = MAX_ZOOM_FACTOR;
          }
          break;
        case DOWN:
          if (zoomFactor - 20.0 > 1.0) {
            zoomFactor -= 20.0;
          } else {
            zoomFactor = 1.0;
          }
          break;
        case 34: // PAGE_DOWN
          if (minContributions - 50 > 0) {
            minContributions -= 50;
          } else {
            minContributions = 0;
          }
          break;
        case 33: // PAGE_UP
         if (minContributions + 50 < maxContributions) {
            minContributions += 50;
          } else {
            minContributions = maxContributions;
          }
          break;
        default:
          println("Special key Pressed: " + keyCode);
          break;
      }
      break;
    case 'r':
      zoomFactor = 1.0;
      break;
    case 's':
      randomize = !randomize;
      getData();
      break;
    case 'q':
    case 'Q':
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
    {
      // Polar to cartesian coordinate conversion
      translate(r*cos(theta), r*sin(theta));
      // Rotate the box
      rotate(theta+HALF_PI); // rotation is offset by 90 degrees
      // Display the character
      fill(127);
      text(b.toString(),0,0);
    }
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
        rect(-5, (int)maxSized / 2, 10, (int)(contributions * maxSized) - (int)maxSized / 2);
        //noFill();
        /* float t = (TWO_PI / weeksSinceCreation) * weeks; */
        /* println("weeks: "  + weeks + (TWO_PI / weeksSinceCreation) + " - " +  t); */
        /* arc(0, 0, (int)(contributions * maxSized * 2), (int)(contributions * maxSized * 2), 0, t); */
        pushMatrix();
        {
          translate(5, (int)(contributions * maxSized));
          rotate(HALF_PI);
          fill(colors[i]);
          text(author.getString("login"), 3, 10);
        }
        popMatrix();
      }
  }
}

void drawKeyboardHelp() {
  String help = "h: Toggle help\n"
              + "s: Sort data (by contributions)\n"
              + "LEFT: Decrease min. contrib\n"
              + "RIGHT: Increase min. contrib\n"
              + "PAGE_DOWN: Decrease min. contrib (-50)\n"
              + "PAGE_UP: Increas min. contrib (+50)\n"
              + "+: Rotate\n"
              + "-: Rotate (counter clockwise)\n"
              + "MOUSE_WHELL: Zoom\n"
              + "r: Reset zoom\n"
              + "q: Quit";
  fill(255);
  text(help, width - textWidth(help), height / 2);
}

void drawBarExplanation() {
  pushMatrix();
  {
    fill(100);
    rect(50, 100, 15, height - 140);
    translate(50, 100);
    rotate(-HALF_PI);
    text("Username", 8, 12);
  }
  popMatrix();
  for (int i = 0; i <= 100; i += 10) {
    text(Integer.toString(i), 75, height - 40 - (10 * i));
  }
}

void drawTransparencyExplanation() {
  fill(100);

  // Description
  int descTextHeight = 22;
  String desc = "Code regularity";
  text(desc, width / 2 - textWidth(desc) / 2, descTextHeight + 2);

  text("Less", width / 4 - textWidth("Less") - 10, 16 + descTextHeight + 15);
  text("More", 3 * width / 4 + 10, 16 + descTextHeight + 15);

  // Background
  noFill();
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

void drawCenter(double maxSized) {
  fill(0);
  noStroke();
  ellipse(0, 0, (int)maxSized, (int)maxSized);
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
    drawCenter(maxSized);
  }
  popMatrix();
  if (!hideHelp) {
    drawKeyboardHelp();
    drawBarExplanation();
    drawTransparencyExplanation();
    drawMinContributions();
  }
}

// vim: set ft=processing et ts=2 :
