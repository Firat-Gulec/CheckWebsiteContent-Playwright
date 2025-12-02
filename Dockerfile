# FROM mcr.microsoft.com/playwright:v1.56.1-jammy
# AMD64 Mimaride Playwright imaj
FROM --platform=linux/amd64 mcr.microsoft.com/playwright:v1.56.1-jammy
WORKDIR /tests
# Package.json
COPY product/tests/package.json .
# Install Dependencies
RUN npm install
# Copy test files
COPY product/tests ./tests
# Copy and set permissions for the test runner script
COPY run-tests.sh .
RUN chmod +x run-tests.sh
ENTRYPOINT ["./run-tests.sh"]
##
## To build the Docker image, use:  docker build -t playwright-runner .
## for x86_64 ## docker build --platform=linux/amd64 -t playwright-runner .
