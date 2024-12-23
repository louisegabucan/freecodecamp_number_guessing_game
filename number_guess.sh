#!/bin/bash
# script should randomly generate a number that users have to guess
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"
NUMBER_OF_GUESSES=0
SECRET_NUMBER=0
USER_ID=0

WARNING() {
  echo Oops! Something went wrong. This game will not be recorded.
}

SET_USER_ID() {
  USERNAME="$1"
  USER_ID=$($PSQL "SELECT user_id FROM users WHERE username = '$USERNAME'")
}

GUESS_SECRET_NUMBER() {
  read GUESS
  (( NUMBER_OF_GUESSES++ ))

  # if integer
  if [[ $GUESS =~ ^[0-9]+$ ]]
  then
    # if guess is right
    if [[ $GUESS -eq $SECRET_NUMBER ]]
    then
      INSERT_GAME=$($PSQL "INSERT INTO games(user_id, number_of_guesses) VALUES($USER_ID, $NUMBER_OF_GUESSES)")
      if [[ $INSERT_GAME != 'INSERT 0 1' ]]
      then
        WARNING
      fi
      echo You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!
    else
      if [[ $GUESS -gt $SECRET_NUMBER ]]
      then
        echo "It's lower than that, guess again:"
      else
        echo "It's higher than that, guess again:"
      fi
      GUESS_SECRET_NUMBER
    fi
  else
    echo That is not an integer, guess again:
    GUESS_SECRET_NUMBER
  fi
}

# prompt the user for a username 
echo Enter your username:
read USERNAME

if [[ -z "$USERNAME" ]]
then
  echo No username entered. Goodbye!
else
  SET_USER_ID "$USERNAME"

  # if username has not been used before, 
  if [[ -z $USER_ID ]]
  then
    echo Welcome, "$USERNAME"! It looks like this is your first time here.
    INSERT_USER_RESULT=$($PSQL "INSERT INTO users(username) VALUES('$USERNAME')")
    if [[ $INSERT_USER_RESULT == 'INSERT 0 1' ]]
    then
      SET_USER_ID "$USERNAME"
    else
      WARNING
    fi
  else
    # else, print welcome back message, total games played, best game info
    GAMES_PLAYED=$($PSQL "SELECT COUNT(user_id) AS games_played FROM games WHERE user_id = $USER_ID")
    BEST_GAME=$($PSQL "SELECT COALESCE(MIN(number_of_guesses), 0) AS best_game FROM games WHERE user_id = $USER_ID")
    echo Welcome back, "$USERNAME"! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses.
  fi
  
  SECRET_NUMBER=$(echo $(( RANDOM % 1000 + 1 )))

  # prompt user to guess and read input
  echo Guess the secret number between 1 and 1000:
  GUESS_SECRET_NUMBER
fi