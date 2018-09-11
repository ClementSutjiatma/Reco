import pandas as pd
import os
twitter_handles = pd.read_csv("Top-1000-Celebrity-Twitter-Accounts.csv", usecols = ["twitter"])



for index, row in twitter_handles.iterrows():
    print row[0]
    command = "twitterscraper " + row[0] + " -l 50 -u -o tweets_" + row[0] + ".json"
    os.system(command)

    command = str("firebase-import --database_url https://reco-1f94b.firebaseio.com/ --path /tweets/" + row[0] + " --id id --json tweets_" + row[0] + ".json --service_account /Users/Clemsut/reco/reco_ios/reco-1f94b-firebase-adminsdk-ikgsw-75fafe3a2d.json --merge")
    os.system(command)
