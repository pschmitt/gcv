import java.util.Properties;
import java.util.Date;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.text.ParseException;
import java.util.GregorianCalendar;
import java.util.List;
import joptsimple.OptionParser;
import joptsimple.OptionSet;
import javax.swing.JOptionPane;

private static final String DEFAULT_REPO = "pschmitt/github-contributions-visualisation";
private static final String GITHUB_API_PREFIX = "https://api.github.com/repos/";

private static final float CUSTOM_ROTATION_STEP = 0.01;
private static final float ZOOM_FACTOR_STEP = 0.5;
private static final float ZOOM_FACTOR_STEP_BIG = 20.0;
private static final int   MAX_ZOOM_FACTOR = 350;
private static final int   MIN_CONTRIB_STEP_BIG = 50;

String repository;
String token;
JSONArray currentDataSet;
JSONArray origData;
color[] colors;

int weeksSinceCreation;
int minContributions = 1;
int maxContributions;
float rotationAngle;
float customRotationAngle;
double zoomFactor = 1.0;
boolean hideHelp = false;
boolean randomize = true;
boolean research = false;
boolean hideAllButMatching = false;
String searchName = "";

int lastMousePosX = -1;

/* {{{ CLI options */

void usage() {
  String usage = "Usage: github [-t TOKEN] REPO\n"
               + "REPO: username/repository\n"
               + "TOKEN: Optional GitHub token";
  println(usage);
}

void loadCommandLine() {
  // Default to self
  String r = DEFAULT_REPO;
  String t = null;

  OptionParser parser = new OptionParser("t:h");
  OptionSet options = parser.parse(args);

  if (options.has("h")) {
    usage();
    System.exit(0);
  }

  t = (String)options.valueOf("t");

  List nonOptArg = options.nonOptionArguments();
  if (!nonOptArg.isEmpty()) {
    String arg = (String)nonOptArg.get(0);
    if (arg.length() > 0) {
      if (checkRepo(arg)) {
        println("Valid repo");
        r  = arg;
      } else {
        println("Invalid repo.");
        usage();
        System.exit(1);
      }
    }
  }

  println("Repo: " + r + " Token: " + t);

  repository = r;

  if (t != null && t.length() > 0) {
    token = t;
  }
}

/* }}} End of CLI options */

/* {{{ Data related functions */

boolean checkRepo(String repo) {
  boolean valid = false;
  if (repo != null && repo.length() > 0) {
    valid = repo.matches("^[a-zA-Z0-9\\\\-]+/[a-zA-Z0-9\\\\-]+$");
  }
  return valid;
}

void getData() {
  currentDataSet = new JSONArray();
  // Clone array
  for (int i = 0; i < origData.size(); ++i) {
    currentDataSet.append(origData.getJSONObject(i));
  }

  // Randomly reorganize the data
  JSONArray randomArray = new JSONArray();

  while (currentDataSet.size() > 0) {
    int randomIndex = (int)random(0, currentDataSet.size());
    JSONObject j = currentDataSet.getJSONObject(randomIndex);

    int contributions = j.getInt("total");
    JSONObject author = j.getJSONObject("author");
    String login = author.getString("login");

    if (contributions > maxContributions) {
      maxContributions = contributions;
    }
    randomArray.append(j);
    currentDataSet.remove(randomIndex);
    println("Author " + login + " made "  + contributions + " contributions");
  }
  currentDataSet = randomize ? randomArray : origData;
}

void getRepoStats() {
  try {
    String url = GITHUB_API_PREFIX + repository
                 + (token != null ? "?access_token=" + token : "");
    println("Stats URL: " + url);
    JSONObject repoStats = loadJSONObject(url);
    SimpleDateFormat df = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'");
    Date d = df.parse(repoStats.getString("created_at"));
    Date n = new Date();

    long now = n.getTime();
    long then = d.getTime();

    weeksSinceCreation = (int)Math.abs((now - then) / (1000 * 60 * 60 * 24 * 7));

    println("Created at: " + d);
  } catch (ParseException e) {
    println("Couldn't parse date..");
  } catch (Exception e) {
      println("Caught an exception, exiting.");
      e.printStackTrace();
      exit();
  }
}

void getContributorStats() {
  try {
    String url = GITHUB_API_PREFIX + repository + "/stats/contributors"
                 + (token != null ? "?access_token=" + token : "");
    println("Contributors URL: " + url);
    origData = loadJSONArray(url);
  } catch (RuntimeException e) {
    println("Caught an exception, exiting.");
    e.printStackTrace();
    super.exit();
  }

  int contributors = origData.size();
  rotationAngle = TWO_PI / contributors;

  println("Contributors: " + contributors);
  println("rotationAngle: " + rotationAngle);
}

void randomColors() {
  // Random colors
  colors = new color[currentDataSet.size()];
  for (int i = 0; i < currentDataSet.size(); ++i) {
    colors[i] = color((int)random(0, 255), (int)random(0, 255), (int)random(0, 255));
  }
}

/* }}} End of data related functions */

/* {{{ Input functions */

/* {{{ Mouse functions */

void mouseDragged(MouseEvent event) {
  boolean withinSlider = false;
  if (mouseX > width / 4 && mouseX < 3 * width / 4) {
    if (mouseY < height - 22 && mouseY > height - 59) {
      withinSlider = true;
    }
  }
  if (withinSlider) {
    if (lastMousePosX < mouseX) {
      if(minContributions < maxContributions)
      {
        minContributions++;
      }
    } else {
      if(minContributions > 0)
      {
        minContributions--;
      }
    }
    println("Within slider");
  } else {
    if (mouseX >= 0 && mouseX <width)
    {
      if (lastMousePosX < mouseX) {
        customRotationAngle -= 0.01;
      } else {
        customRotationAngle += 0.01;
      }
    }
    println("NOT within slider");
  }

  println("Mouse X " + mouseX + "Mouse Y " + mouseY );
  lastMousePosX = mouseX;
}

void mouseWheel(MouseEvent event) {
  float e = event.getAmount();
  zoomFactor += e * - ZOOM_FACTOR_STEP;
  if (zoomFactor < 1.0) {
    zoomFactor = 1.0;
  }
  if (zoomFactor > MAX_ZOOM_FACTOR) {
    zoomFactor = MAX_ZOOM_FACTOR;
  }
}

/* }}} End of mouse functions */

void searchKeyPressed() {
  switch (key) {
    case ESC:
      key = 0; //idem
      searchName = "";
    case ENTER:
      research = false;
      break;
    case BACKSPACE:
      if (searchName.length() > 0) {
        searchName = searchName.substring(0, searchName.length()-1);
      }
      break;
    default:
      if (Character.isLetterOrDigit(key)) {
        searchName += key;
      }
  }
}

/* {{{ Normal key press */

void normalKeyPressed() {
  switch (key) {
    case 'f':
    case '/':
      research = !research;
      break;
    case '+':
     customRotationAngle += CUSTOM_ROTATION_STEP;
      break;
    case '-':
      customRotationAngle -= CUSTOM_ROTATION_STEP;
      break;
    case 'h':
      hideHelp = !hideHelp;
      break;
    case 'm':
      hideAllButMatching = !hideAllButMatching;
      break;
    case 'o':
      String response = JOptionPane.showInputDialog(frame,
        "Enter REPO (username/password):",
        "Change repository",
        JOptionPane.QUESTION_MESSAGE);
      if (checkRepo(response)) {
        repository = response;
        updateRepo();
      } else { // Invalid input or cancelled
        // Invalid input
        if (response != null && response.length() > 0) {
          JOptionPane.showMessageDialog(frame,
           "Not a valid repo: " + response,
           "Input error",
           JOptionPane.ERROR_MESSAGE);
        }
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
      key = ESC; //ask to Papplet to exit
      break;
    case CODED:
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
          if (zoomFactor + ZOOM_FACTOR_STEP_BIG < MAX_ZOOM_FACTOR) {
            zoomFactor += ZOOM_FACTOR_STEP_BIG;
          } else {
            zoomFactor = MAX_ZOOM_FACTOR;
          }
          break;
        case DOWN:
          if (zoomFactor - ZOOM_FACTOR_STEP_BIG > 1.0) {
            zoomFactor -= ZOOM_FACTOR_STEP_BIG;
          } else {
            zoomFactor = 1.0;
          }
          break;
        case 36: // HOME
          minContributions = 0;
          break;
        case 35: // END
          minContributions = maxContributions;
          break;
        case 34: // PAGE_DOWN
          if (minContributions - MIN_CONTRIB_STEP_BIG > 0) {
            minContributions -= MIN_CONTRIB_STEP_BIG;
          } else {
            minContributions = 0;
          }
          break;
        case 33: // PAGE_UP
          if (minContributions + MIN_CONTRIB_STEP_BIG < maxContributions) {
            minContributions += MIN_CONTRIB_STEP_BIG;
          } else {
            minContributions = maxContributions;
          }
          break;
        default:
          println("Special key Pressed: " + keyCode);
          break;
      }
      break;
    default:
      println("Pressed: " + key);
      break;
  }
}

/* }}} End of normal key press */

void keyPressed() {
  if (research){
    searchKeyPressed();
  } else {
    normalKeyPressed();
  }
}

/* }}} End of input functions */

/* {{{ Drawing functions */

void drawTextAroundElipse(String msg, float r) {
  // We must keep track of our position along the curve
  float arclength = 0;

  // For every box
  for (int i = 0; i < msg.length(); i++) {
    // Instead of a constant width, we check the width of each character.
    StringBuilder b = new StringBuilder();
    char c = msg.charAt(i);
    b.append(c);
    float w = textWidth(b.toString());

    // Each box is centered so we move half the width
    arclength += w / 2;
    // Angle in radians is the arclength divided by the radius
    // Starting on the left side of the circle by adding PI
    float theta = PI + arclength / r;

    pushMatrix();
    {
      // Polar to cartesian coordinate conversion
      translate(r * cos(theta), r * sin(theta));
      // Rotate the box
      rotate(theta + HALF_PI); // rotation is offset by 90 degrees
      // Display the character
      fill(127);
      text(b.toString(), 0, 0);
    }
    popMatrix();

    // Move halfway again
    arclength += w / 2;
  }
}

void drawTitle(double maxSized) {
  pushStyle();
  {
    textFont(createFont("Sans", 40, true));
    drawTextAroundElipse(repository, (float )(maxContributions * maxSized));
  }
  popStyle();
}

void drawData(double maxSized) {
  for (int i = 0; i < currentDataSet.size(); i++) {
      JSONObject current = currentDataSet.getJSONObject(i);
      JSONObject author = current.getJSONObject("author");
      String login = author.getString("login");
      int contributions = current.getInt("total");
      JSONArray weeksAr =  current.getJSONArray("weeks");
      boolean matches = searchName.length() > 0 && login.matches(".*" + searchName + ".*");

      rotate(rotationAngle);

      if (hideAllButMatching && searchName.length() > 0 && !matches) {
        continue;
      }

      if (contributions >= minContributions) {
        // Actual drawing
        int alphaValue = 255;
        for (int j = 0; j < weeksAr.size(); ++j) {
          // Decrease alpha for each week with no commit
          if (weeksAr.getJSONObject(j).getInt("c") <= 0)
            alphaValue -= 1;
        }

        pushStyle();
        {
          fill(color(red(colors[i]), green(colors[i]), blue(colors[i]), alphaValue));
          if (matches) {
            stroke(color(255, 0, 0));
          } else {
            stroke(0);
          }
          rect(-5, (int)maxSized / 2, 10, (int)(contributions * maxSized) - (int)maxSized / 2);
          pushMatrix();
          {
            translate(5, (int)(contributions * maxSized));
            rotate(HALF_PI);
            if (matches) {
              fill(color(255, 0, 0));
            } else {
              fill(colors[i]);
            }
            text(login, 3, 10);
          }
          popMatrix();
        }
        popStyle();
      }
  }
}

void drawKeyboardHelp() {
  String help = "h: Toggle help\n"
              + "s: Sort data (by contributions)\n"
              + "f: Search Name (ESC: quit, ENTER: validate)\n"
              + "m: Toggle hide all but matching\n"
              + "LEFT: Decrease min. contrib\n"
              + "RIGHT: Increase min. contrib\n"
              + "PAGE_DOWN: Decrease min. contrib (-50)\n"
              + "PAGE_UP: Increas min. contrib (+50)\n"
              + "+: Rotate\n"
              + "-: Rotate (counter clockwise)\n"
              + "MOUSE_WHELL: Zoom\n"
              + "r: Reset zoom\n"
              + "q: Quit";
  pushStyle();
  {
    fill(255);
    text(help, width - textWidth(help), height / 2);
  }
  popStyle();
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
  pushStyle();
  {
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
  popStyle();
}

void drawResearch() {
  fill(100);
  text("Reseach : " + searchName, 100, height - 40);
}

void drawMinContributions() {
  int diff = maxContributions - minContributions;
  float step = (width / 2) / (float)maxContributions;
  // println("diff: " + diff + " step: " + step);

  pushStyle();
  {
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
    text(Integer.toString(minContributions),
         (3 * width / 4) - (diff * step) - textWidth(Integer.toString(minContributions)) / 2,
         height - 24 - descTextHeight);
  }
  // Reset
  popStyle();
}

void drawGraduations(double maxSized) {
  int[] graduations = new int[] { 1, 10, 25, 50, 100, 250, 500, 1000, 2000, 50000, 10000};
  for (int g : graduations) {
    if (g < maxContributions) {
      noFill();

      pushStyle();
      {
        stroke(100);
        ellipse(0, 0, (int)(g * maxSized * 2), (int)(g * maxSized * 2));
        drawTextAroundElipse(Integer.toString(g), (float)(g*maxSized));
      }
      popStyle();
    }
  }
}

void drawBackgroundElipse(double maxSized) {
  fill(color(22, 22, 22));
  ellipse(0, 0, (int)(maxContributions * maxSized * 2), (int)(maxContributions * maxSized * 2));
}

void drawCenter(double maxSized) {
  pushStyle();
  {
    fill(0);
    noStroke();
    ellipse(0, 0, (int)maxSized, (int)maxSized);
  }
  popStyle();
}

/* }}} End of drawing functions */

void draw() {
  fill(20);
  clear();

  pushMatrix();
  {
    translate(width / 2, height / 2);

    int maxSize = min(width / 2, height / 2) - 40;
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

  if (research) {
    drawResearch();
  }
  if (!hideHelp) {
    drawKeyboardHelp();
    drawBarExplanation();
    drawTransparencyExplanation();
    drawMinContributions();
  }
}

void updateRepo() {
  getRepoStats();
  getContributorStats();
  getData();
  randomColors();
}

void setup() {
  size(800, 600);
  if (frame != null) {
    frame.setResizable(true);
  }

  // Default font settings
  textFont(createFont("Sans", 12, true));
  smooth();

  // Get CLI parameters
  loadCommandLine();
  updateRepo();
}

// vim: set ft=processing et ts=2 :
