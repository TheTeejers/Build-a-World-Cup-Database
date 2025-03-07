#! /bin/bash
echo -e "\nHere we be, testing the testing\n"

if [[ $1 == "test" ]]
then
  PSQL="psql --username=postgres --dbname=worldcuptest -t --no-align -c"
else
  echo -e "\nYAY!\n"
  PSQL="psql --username=freecodecamp --dbname=worldcup -t --no-align -c"
fi

# Create tables if they don't exist
echo "$($PSQL "CREATE TABLE IF NOT EXISTS teams(team_id SERIAL PRIMARY KEY, name VARCHAR UNIQUE);")"
echo "$($PSQL "CREATE TABLE IF NOT EXISTS games(game_id SERIAL PRIMARY KEY, year INT, round VARCHAR, winner_id INT REFERENCES teams(team_id), opponent_id INT REFERENCES teams(team_id), winner_goals INT, opponent_goals INT);")"

# Clear existing data
echo "$($PSQL "TRUNCATE TABLE games, teams CASCADE;")"

# Insert teams data
echo "Inserting teams data..."

# Get unique teams from games.csv, skipping the header row
unique_teams=$(tail -n +2 games.csv | cut -d ',' -f 3 | sort -u; tail -n +2 games.csv | cut -d ',' -f 4 | sort -u | uniq)

# Replace spaces with underscores in team names
sed 's/,\([^,]*\) \([^,]*\),/,\1_\2,/g' games.csv > temp.csv

# Extract unique winner and opponent names using awk
all_teams=$(awk -F',' 'NR>1{print $3; print $4}' temp.csv | sort -u)

#Insert each team into the teams table.
for team in $all_teams; do
team=$(echo "$team" | sed 's/_/ /g')
  if [[ -n "$team" ]]; then
    if  $($PSQL "SELECT name FROM teams WHERE name = '$team'")
    then
      echo "$($PSQL "INSERT INTO teams (name) VALUES ('$team');")"
    fi
  fi
done

#Insert game data
echo "Inserting game data..."
#read csv and get team IDs.
tail -n +2 games.csv | while IFS=',' read year round winner opponent winner_goals opponent_goals
do
  if [[ "$year" != "year" ]] ; then
    winner_id=$($PSQL "SELECT team_id FROM teams WHERE name = '$winner'")
    opponent_id=$($PSQL "SELECT team_id FROM teams WHERE name = '$opponent'")
    #Check if the winner and opponent IDs are empty.
if [[ -z "$winner_id" ]] || [[ -z "$opponent_id" ]]; then
  echo "Error: Could not find team ID for winner: '$winner' or opponent: '$opponent'"
else
  echo "$($PSQL "INSERT INTO games (year, round, winner_id, opponent_id, winner_goals, opponent_goals) VALUES ($year, '$round', $winner_id, $opponent_id, $winner_goals, $opponent_goals);")"
fi
  fi
done
echo "Data insertion complete."
# Remove temporary file
rm temp.csv