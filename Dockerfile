# pull down the pode image
FROM badgerati/pode:latest

# or use the following for GitHub
# FROM docker.pkg.github.com/badgerati/pode/pode:latest

# copy over the local files to the container
COPY . /usr/src/app/

# expose the port
EXPOSE 5030

# run the server
CMD [ "pwsh", "-c", "cd /usr/src/app; ./server.ps1" ]