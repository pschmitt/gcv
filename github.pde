// The following short JSON file called "data.json" is parsed
// in the code below. It must be in the project's "data" folder.
//
// {
//   "id": 0,
//   "species": "Panthera leo",
//   "name": "Lion"
// }

JSONArray json;

void setup() {
  size(400, 400);
  json = loadJSONArray("https://api.github.com/repos/twbs/bootstrap/stats/contributors");

  for (int i = 0; i < json.size(); i++) {
      JSONObject current = json.getJSONObject(i);

      JSONObject author = current.getJSONObject("author");
      String login = author.getString("login");
      int contributions = current.getInt("total");

      println("Author " + login + " made "  + contributions + " contributions");

  }


}
