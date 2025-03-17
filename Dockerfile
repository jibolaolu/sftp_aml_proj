FROM ubuntu:20.04

# Install dependencies and AWS CLI v2
RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    python3 \
    python3-pip \
    nginx \
    && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm -rf awscliv2.zip ./aws

# Verify installation
RUN aws --version

 #Start both NGINX and keep the container running
CMD ["sh", "-c", "service nginx start && tail -f /dev/null"]
