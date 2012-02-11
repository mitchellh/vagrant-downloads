# 3 appears to be the ideal amount for a single dyno on Heroku
worker_processes 3

# Restart workers that hang for 30 or more seconds
timeout 30
