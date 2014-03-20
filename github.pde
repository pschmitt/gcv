import java.util.Properties;


JSONArray json;

Properties loadCommandLine() {
  Properties props = new Properties();
  props.setProperty("repo", args[0]);
  return props;
}

void setup() {
  size(400, 400);

  // Get CLI parameters
  Properties props = loadCommandLine();
  String repository = props.getProperty("repo", "No repository specified.");

  json = loadJSONArray("https://api.github.com/repos/" + repository +  "/stats/contributors");

  for (int i = 0; i < json.size(); i++) {
      JSONObject current = json.getJSONObject(i);

      JSONObject author = current.getJSONObject("author");
      String login = author.getString("login");
      int contributions = current.getInt("total");

      println("Author " + login + " made "  + contributions + " contributions");

  }
}

// vim: set et ts=2 :
