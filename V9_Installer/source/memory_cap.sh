#!/bin/bash
## By Daniel ##
## ASK FOR MEMORY CAP
memoryCap(){

  memCap=""
  memGB=0
  answering="true"
  while [ "$answering" == "true" ]
  do
      #Ask for user input and read the input into $answer
      echo -e "Is there a Memory Cap to be implemented? y(yes) n(no)"
      read memCap
      #verify if the user entered a string
      if [ "$memCap" != "y" ] && [ "$memCap" != "n" ]
      then 
          echo "please enter y for (yes) or n for (no)"
      elif [ "$memCap" == "y" ]
      then
          while [[ $memGB != @(2|3|4|5|6|7|8|9|10|11|12|13|14|15|16) ]]
          do
            echo -e "Please enter the GB limit between 2 - 16"
            read memGB
          done
          answering="false"
      else 
          answering="false"
      fi
      ### Add more gaurds ###
  done
  
  if [[ "$memGB" != 0 ]]
  then
    touch /home/vcs/configuration/compose.vcs.override.yml
    echo "services:
    vcs:
      deploy:
        resources:
          limits:
            memory: ${memGB}gb" > /home/vcs/configuration/compose.vcs.override.yml
  fi
}
