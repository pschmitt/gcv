import java.util.Properties;

JSONArray json;
int maxContributions;
float rotationAngle;

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

  // Get CLI parameters
  Properties props = loadCommandLine();
  String repository = props.getProperty("repo", "No repository specified.");

  json = loadJSONArray("https://api.github.com/repos/" + repository + "/stats/contributors");

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
}

void draw() {

  translate(width/2, height/2);

  for (int i = 0; i < json.size(); i++) {
      JSONObject current = json.getJSONObject(i);

      JSONObject author = current.getJSONObject("author");
      String login = author.getString("login");
      int contributions = current.getInt("total");

      rotate(rotationAngle);
      rect(0, 0, 3, contributions);
  }

}

// vim: set ft=processing et ts=2 :
