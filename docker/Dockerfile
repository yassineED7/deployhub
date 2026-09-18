# Step 1: Set the base image
FROM node:20-alpine

# Step 2: Set the working directory inside the container
WORKDIR /usr/src/app

# Step 3: Copy dependency definitions first for build caching optimization
COPY app/package*.json ./ 

# Step 4: Install dependencies
RUN npm ci --only=production

# Step 5: Copy the rest of the application code (respecting .dockerignore)
COPY app/ .

# Step 6: Expose the application port
EXPOSE 3000

# Step 7: Specify the default command to run the application
CMD [ "node", "server.js" ]

