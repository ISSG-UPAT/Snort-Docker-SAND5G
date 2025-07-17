# Use the existing image as the base image
FROM ciscotalos/snort3


USER root 
# Install inotify-tools
RUN apt-get update --allow-releaseinfo-change && apt-get install -y inotify-tools sudo 

# Set capabilities for snort binary 
RUN setcap cap_net_raw,cap_net_admin=eip /home/snorty/snort3/bin/snort

# Set a default password for the snorty user
RUN echo "snorty:password" | chpasswd
# Add snorty to the sudoers file
RUN echo "snorty ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Assigning default values to environment variables
ENV RULES_FILE=/home/snorty/custom/local.rules
ENV SNORT_CONF_FILE=/home/snorty/custom/custom_snort.lua
ENV SNORT_ALERTS=/home/snorty/alerts
ENV VERBOSE=0



# Copy the default custom rules and configuration files into the container
COPY volumes/scripts /home/snorty/scripts

RUN chmod +x /home/snorty/scripts/entrypoint.sh
RUN chmod +x /home/snorty/scripts/run_snort.sh
RUN chmod +x /home/snorty/scripts/run_snort_notify.sh

USER snorty
WORKDIR /home/snorty

ENTRYPOINT [  "/home/snorty/scripts/entrypoint.sh" ]


